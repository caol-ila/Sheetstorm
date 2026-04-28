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
