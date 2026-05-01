using System.Diagnostics;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

public sealed record DetectedPart(string DisplayName, string InstrumentFamily, Guid InstrumentId, string? Transposition, int FromPage, int ToPage, double Confidence, string? MusicXmlBlobKey = null);

public sealed record OmrResult(string? SuggestedTitle, string? SuggestedComposer, IReadOnlyList<DetectedPart> Parts, bool IsStub = false);

public interface IOmrEngine
{
    Task<OmrResult> RecognizeAsync(string blobKey, string originalFileName, IReadOnlyList<Instrument> availableInstruments, CancellationToken ct = default);

    /// <summary>
    /// Roh-MusicXML eines PDFs zurueckgeben (fuer "Audiveris auf einer einzelnen Stimme nachtraeglich ausfuehren").
    /// Liefert null wenn die Engine das nicht unterstuetzt (z.B. Stub).
    /// </summary>
    Task<string?> RecognizeRawMusicXmlAsync(string blobKey, string originalFileName, CancellationToken ct = default) => Task.FromResult<string?>(null);

    /// <summary>
    /// Detection-Bboxes für Annotation-/Trainings-Tool. Schema:
    /// <c>omr_pipeline::detections::DetectionsResult</c> (siehe Rust-Code).
    /// Liefert <c>null</c> wenn die Engine das nicht unterstützt (Stub, Audiveris).
    /// </summary>
    Task<string?> RecognizeDetectionsJsonAsync(string blobKey, string originalFileName, CancellationToken ct = default) => Task.FromResult<string?>(null);
}

/// <summary>
/// Stub-Implementation: liefert plausible Stimm-Vorschläge basierend auf Heuristik
/// (Dateiname, Standard-Blasmusik-Stimmen). Echter Audiveris-Adapter swap-in.
/// </summary>
public sealed class StubOmrEngine(LocalFileStore store, ILogger<StubOmrEngine> log) : IOmrEngine
{
    public async Task<OmrResult> RecognizeAsync(string blobKey, string originalFileName, IReadOnlyList<Instrument> availableInstruments, CancellationToken ct = default)
    {
        // Simuliert Verarbeitungs­zeit
        await Task.Delay(800, ct);

        // Heuristik: Titel aus Dateiname extrahieren
        var name = Path.GetFileNameWithoutExtension(originalFileName);
        string? title = name;
        string? composer = null;

        // Pattern: "Komponist - Titel" oder "Titel (Komponist)"
        if (name.Contains(" - "))
        {
            var parts = name.Split(" - ", 2);
            composer = parts[0].Trim();
            title = parts[1].Trim();
        }
        else if (name.Contains('(') && name.EndsWith(')'))
        {
            var open = name.LastIndexOf('(');
            composer = name.Substring(open + 1).TrimEnd(')').Trim();
            title = name.Substring(0, open).Trim();
        }

        // Standard-Blasmusik-Stimmen vorschlagen
        var suggestedInstrumentNames = new[]
        {
            "Klarinette in B", "Trompete in B", "Posaune", "Tenorhorn", "Tuba in B", "Schlagzeug-Set",
        };

        var detectedParts = new List<DetectedPart>();
        var pageOffset = 1;
        foreach (var nameWanted in suggestedInstrumentNames)
        {
            var instr = availableInstruments.FirstOrDefault(i => i.Name == nameWanted);
            if (instr is null) continue;
            detectedParts.Add(new DetectedPart(
                DisplayName: instr.DefaultTransposition is null ? instr.Name : $"{instr.Name} ({instr.DefaultTransposition})",
                InstrumentFamily: instr.Family.ToString(),
                InstrumentId: instr.Id,
                Transposition: instr.DefaultTransposition,
                FromPage: pageOffset,
                ToPage: pageOffset,
                Confidence: 0.70));
            pageOffset++;
        }

        log.LogInformation("Stub-OMR fuer {File}: {PartCount} Stimmen vorgeschlagen (DEMO!)", originalFileName, detectedParts.Count);
        return new OmrResult(title, composer, detectedParts, IsStub: true);
    }
}

public sealed class OmrService(SheetstormDbContext db, LocalFileStore store, IWebHostEnvironment env)
{
    public async Task<OmrJob> CreateJobAsync(Guid bandId, Guid userId, Stream content, string fileName, CancellationToken ct = default)
    {
        var blobKey = await store.SaveAsync(content, $"omr/{bandId}", fileName, ct);
        var job = OmrJob.Create(bandId, userId, fileName, blobKey);
        db.OmrJobs.Add(job);
        await db.SaveChangesAsync(ct);
        return job;
    }

    public async Task<OmrJob?> GetAsync(Guid jobId, CancellationToken ct = default)
        => await db.OmrJobs.FirstOrDefaultAsync(j => j.Id == jobId, ct);

    public async Task<List<OmrJob>> GetForBandAsync(Guid bandId, CancellationToken ct = default)
        => await db.OmrJobs.Where(j => j.BandId == bandId).OrderByDescending(j => j.CreatedAt).Take(50).ToListAsync(ct);

    /// <summary>
    /// Startet Audiveris im Hintergrund auf dem PDF einer existierenden Stimme.
    /// Returnt sofort. Status / Fertigstellung kann ueber HasMusicXmlAsync gepollt werden.
    /// </summary>
    public Task StartAudiverisOnPartAsync(Guid partId, IServiceScopeFactory scopeFactory, ILogger logger)
    {
        // Idempotent: wenn schon laufend, nicht erneut starten.
        if (RunningAudiverisParts.ContainsKey(partId))
        {
            logger.LogInformation("Audiveris-on-Part {PartId}: schon laufend — kein neuer Job", partId);
            return Task.CompletedTask;
        }
        RunningAudiverisParts[partId] = DateTimeOffset.UtcNow;
        FailedAudiverisParts.TryRemove(partId, out _);
        SheetstormTelemetry.AudiverisStarted.Add(1, new KeyValuePair<string, object?>("part.id", partId.ToString()));

        _ = Task.Run(async () =>
        {
            using var activity = SheetstormTelemetry.Activity.StartActivity("audiveris.recognize", ActivityKind.Internal);
            activity?.SetTag("part.id", partId.ToString());

            await using var scope = scopeFactory.CreateAsyncScope();
            var freshDb = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
            var freshStore = scope.ServiceProvider.GetRequiredService<LocalFileStore>();
            var freshEngine = scope.ServiceProvider.GetRequiredService<IOmrEngine>();
            var freshSvc = new OmrService(freshDb, freshStore, scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>());

            var sw = System.Diagnostics.Stopwatch.StartNew();
            try
            {
                logger.LogInformation("Audiveris-on-Part {PartId}: START", partId);
                var ok = await freshSvc.RunAudiverisOnPartAsync(partId, freshEngine);
                sw.Stop();
                activity?.SetTag("audiveris.result", ok ? "success" : "failed");
                activity?.SetStatus(ok ? ActivityStatusCode.Ok : ActivityStatusCode.Error);
                logger.LogInformation("Audiveris-on-Part {PartId}: {Result} nach {ElapsedSec:F1}s",
                    partId, ok ? "SUCCESS" : "FAILED", sw.Elapsed.TotalSeconds);
                if (ok) SheetstormTelemetry.AudiverisCompleted.Add(1, new KeyValuePair<string, object?>("part.id", partId.ToString()));
                else { SheetstormTelemetry.AudiverisFailed.Add(1, new KeyValuePair<string, object?>("part.id", partId.ToString())); FailedAudiverisParts[partId] = DateTimeOffset.UtcNow; }
            }
            catch (Exception ex)
            {
                sw.Stop();
                activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
                activity?.AddException(ex);
                logger.LogError(ex, "Audiveris-on-Part {PartId} CRASHED nach {ElapsedSec:F1}s", partId, sw.Elapsed.TotalSeconds);
                SheetstormTelemetry.AudiverisFailed.Add(1, new KeyValuePair<string, object?>("part.id", partId.ToString()), new KeyValuePair<string, object?>("error", ex.GetType().Name));
                FailedAudiverisParts[partId] = DateTimeOffset.UtcNow;
            }
            finally
            {
                SheetstormTelemetry.AudiverisDurationSeconds.Record(sw.Elapsed.TotalSeconds, new KeyValuePair<string, object?>("part.id", partId.ToString()));
                RunningAudiverisParts.TryRemove(partId, out _);
            }
        });
        return Task.CompletedTask;
    }

    public bool IsAudiverisRunning(Guid partId) => RunningAudiverisParts.ContainsKey(partId);
    public bool LastAudiverisFailed(Guid partId) => FailedAudiverisParts.ContainsKey(partId);
    public void ClearAudiverisFailedFlag(Guid partId) => FailedAudiverisParts.TryRemove(partId, out _);

    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTimeOffset> RunningAudiverisParts = new();
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTimeOffset> FailedAudiverisParts = new();

    /// <summary>
    /// Laeuft Audiveris auf dem PDF einer existierenden Stimme und haengt das
    /// Ergebnis als PartFile.MusicXml an.
    /// Idempotent: wenn bereits ein MusicXml-File existiert, wird es ersetzt.
    /// </summary>
    public async Task<bool> RunAudiverisOnPartAsync(Guid partId, IOmrEngine engine, CancellationToken ct = default)
    {
        using var activity = SheetstormTelemetry.Activity.StartActivity("audiveris.recognize.inner", ActivityKind.Internal);
        activity?.SetTag("part.id", partId.ToString());

        var part = await db.Parts.Include(p => p.Files).FirstOrDefaultAsync(p => p.Id == partId, ct);
        if (part is null)
        {
            activity?.SetStatus(ActivityStatusCode.Error, "part-not-found");
            return false;
        }
        var pdf = part.Files.FirstOrDefault(f => f.Kind == PartFileKind.Pdf);
        if (pdf is null)
        {
            activity?.SetStatus(ActivityStatusCode.Error, "no-pdf");
            return false;
        }
        activity?.SetTag("pdf.size_bytes", pdf.SizeBytes);
        activity?.SetTag("pdf.filename", pdf.OriginalFileName);

        var xml = await engine.RecognizeRawMusicXmlAsync(pdf.BlobKey, pdf.OriginalFileName, ct);
        if (string.IsNullOrEmpty(xml))
        {
            activity?.SetStatus(ActivityStatusCode.Error, "engine-returned-empty");
            return false;
        }
        activity?.SetTag("musicxml.size_bytes", xml.Length);

        // Alte MusicXml-Dateien dieser Stimme entfernen
        foreach (var old in part.Files.Where(f => f.Kind == PartFileKind.MusicXml).ToList())
        {
            db.PartFiles.Remove(old);
        }
        await db.SaveChangesAsync(ct);

        var bytes = System.Text.Encoding.UTF8.GetBytes(xml);
        using var ms = new MemoryStream(bytes);
        var name = $"{Path.GetFileNameWithoutExtension(pdf.OriginalFileName)}.musicxml";
        var blobKey = await store.SaveAsync(ms, $"parts/{partId}", name, ct);
        db.PartFiles.Add(PartFile.Create(partId, PartFileKind.MusicXml, blobKey, name, bytes.Length));
        await db.SaveChangesAsync(ct);
        activity?.SetStatus(ActivityStatusCode.Ok);
        return true;
    }

    public async Task<Guid> ConfirmAsync(Guid jobId, string title, string? composer, IReadOnlyList<DetectedPart> partsToCreate, CancellationToken ct = default)
    {
        var job = await db.OmrJobs.FirstOrDefaultAsync(j => j.Id == jobId, ct)
            ?? throw new InvalidOperationException("Job nicht gefunden");
        if (job.Status != OmrJobStatus.Done)
            throw new InvalidOperationException("Job ist noch nicht abgeschlossen");

        var piece = Piece.Create(job.BandId, title);
        piece.UpdateMetadata(title, null, composer, null, null, null, null, null, null, null, null, null, null, null);
        db.Pieces.Add(piece);
        await db.SaveChangesAsync(ct);

        // WICHTIG: An User-Uploads haengen wir KEINE Demo-MusicXML mehr an.
        // Frueher hatten Stub-Erkennung + Auto-Anhang dazu gefuehrt, dass
        // bestaetigte Werke immer dieselbe Demo-Tonleiter zeigten — das war
        // der gemeldete "Dummy-Eintrag-statt-Lied"-Bug. Das Original-PDF
        // bleibt pro Stimme verlinkt; echte MusicXML kommt nur via Audiveris.
        foreach (var p in partsToCreate)
        {
            var part = Part.Create(piece.Id, p.InstrumentId, p.DisplayName, p.Transposition);
            db.Parts.Add(part);
            await db.SaveChangesAsync(ct);

            using var pdfStream = store.OpenRead(job.InputBlobKey);
            var partBlobKey = await store.SaveAsync(pdfStream, $"parts/{part.Id}", $"{title}-{p.DisplayName}.pdf", ct);
            db.PartFiles.Add(PartFile.Create(part.Id, PartFileKind.Pdf, partBlobKey, $"{title} - {p.DisplayName}.pdf", store.GetSize(partBlobKey)));

            if (!string.IsNullOrEmpty(p.MusicXmlBlobKey) && store.Exists(p.MusicXmlBlobKey))
            {
                using var mxlStream = store.OpenRead(p.MusicXmlBlobKey);
                var mxlBlobKey = await store.SaveAsync(mxlStream, $"parts/{part.Id}", $"{title}-{p.DisplayName}.musicxml", ct);
                db.PartFiles.Add(PartFile.Create(part.Id, PartFileKind.MusicXml, mxlBlobKey, $"{title} - {p.DisplayName}.musicxml", store.GetSize(mxlBlobKey)));
            }
        }
        await db.SaveChangesAsync(ct);

        job.MarkConfirmed(piece.Id);
        await db.SaveChangesAsync(ct);
        return piece.Id;
    }
}

/// <summary>
/// Verarbeitet OmrJobs sequentiell im Hintergrund — leichtgewichtige Alternative zu Hangfire.
/// Pollt alle 2s nach neuen Queued-Jobs.
/// </summary>
public sealed class OmrBackgroundWorker(IServiceScopeFactory scopeFactory, ILogger<OmrBackgroundWorker> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        log.LogInformation("OMR-Worker gestartet");
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOnceAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "OMR-Worker-Fehler");
            }
            try { await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken); } catch { }
        }
    }

    private async Task ProcessOnceAsync(CancellationToken ct)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
        var engine = scope.ServiceProvider.GetRequiredService<IOmrEngine>();

        var job = await db.OmrJobs
            .Where(j => j.Status == OmrJobStatus.Queued)
            .OrderBy(j => j.CreatedAt)
            .FirstOrDefaultAsync(ct);
        if (job is null) return;

        log.LogInformation("OMR-Job {Id} startet ({File})", job.Id, job.OriginalFileName);
        job.MarkRunning();
        await db.SaveChangesAsync(ct);

        try
        {
            var instruments = await db.Instruments.ToListAsync(ct);
            var result = await engine.RecognizeAsync(job.InputBlobKey, job.OriginalFileName, instruments, ct);
            var json = JsonSerializer.Serialize(result.Parts);
            job.MarkDone(json, result.SuggestedTitle, result.SuggestedComposer, result.IsStub);
            await db.SaveChangesAsync(ct);
            log.LogInformation("OMR-Job {Id} fertig — {Parts} Stimmen{Stub}", job.Id, result.Parts.Count, result.IsStub ? " (STUB!)" : "");
        }
        catch (Exception ex)
        {
            log.LogError(ex, "OMR-Job {Id} fehlgeschlagen", job.Id);
            job.MarkFailed(ex.Message);
            await db.SaveChangesAsync(ct);
        }
    }
}
