using System.Diagnostics;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Verwaltet Detection-Runs (Pipeline → JSON-Bbox-Dump) und User-Annotations
/// für das Trainings-/Korrektur-Tool.
///
/// Workflow:
///   1) Nach OmrJob-Confirm wird pro Stimme <see cref="StartDetectionsOnPartAsync"/>
///      gestartet (idempotent).
///   2) Pipeline schreibt PartFile mit <see cref="PartFileKind.Detections"/> ab.
///   3) UI lädt Detections + zeigt Bbox-Overlays auf den PageImages.
///   4) Notenverwalter klickt → erzeugt PartAnnotation via <see cref="AddAnnotationAsync"/>.
/// </summary>
public sealed class PartDetectionService(
    SheetstormDbContext db,
    LocalFileStore store,
    ILogger<PartDetectionService> log)
{
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTimeOffset> RunningParts = new();
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTimeOffset> FailedParts = new();

    public bool IsDetectionsRunning(Guid partId) => RunningParts.ContainsKey(partId);
    public bool LastDetectionsFailed(Guid partId) => FailedParts.ContainsKey(partId);
    public void ClearDetectionsFailedFlag(Guid partId) => FailedParts.TryRemove(partId, out _);

    /// <summary>
    /// Startet die OMR-Pipeline für eine Stimme im Hintergrund. Schreibt
    /// das Ergebnis als <see cref="PartFileKind.Detections"/> JSON-Blob.
    /// Idempotent: wenn schon laufend, kein neuer Job.
    /// </summary>
    public Task StartDetectionsOnPartAsync(
        Guid partId,
        IServiceScopeFactory scopeFactory,
        ILogger logger)
    {
        if (RunningParts.ContainsKey(partId))
        {
            logger.LogInformation("Detections-on-Part {PartId}: schon laufend — kein neuer Job", partId);
            return Task.CompletedTask;
        }
        RunningParts[partId] = DateTimeOffset.UtcNow;
        FailedParts.TryRemove(partId, out _);

        _ = Task.Run(async () =>
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var freshDb = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
            var freshStore = scope.ServiceProvider.GetRequiredService<LocalFileStore>();
            var freshEngine = scope.ServiceProvider.GetRequiredService<IOmrEngine>();
            var freshSvc = new PartDetectionService(freshDb, freshStore, logger as ILogger<PartDetectionService> ?? scope.ServiceProvider.GetRequiredService<ILogger<PartDetectionService>>());

            var sw = Stopwatch.StartNew();
            try
            {
                logger.LogInformation("Detections-on-Part {PartId}: START", partId);
                var ok = await freshSvc.RunDetectionsOnPartAsync(partId, freshEngine);
                sw.Stop();
                logger.LogInformation("Detections-on-Part {PartId}: {Result} nach {ElapsedSec:F1}s",
                    partId, ok ? "SUCCESS" : "FAILED", sw.Elapsed.TotalSeconds);
                if (!ok) FailedParts[partId] = DateTimeOffset.UtcNow;
            }
            catch (Exception ex)
            {
                sw.Stop();
                logger.LogError(ex, "Detections-on-Part {PartId} CRASHED nach {ElapsedSec:F1}s", partId, sw.Elapsed.TotalSeconds);
                FailedParts[partId] = DateTimeOffset.UtcNow;
            }
            finally
            {
                RunningParts.TryRemove(partId, out _);
            }
        });
        return Task.CompletedTask;
    }

    /// <summary>
    /// Inner-Worker: läuft Pipeline auf der Stimme + speichert JSON.
    /// Idempotent: alte Detections-PartFiles werden ersetzt.
    /// </summary>
    public async Task<bool> RunDetectionsOnPartAsync(Guid partId, IOmrEngine engine, CancellationToken ct = default)
    {
        var part = await db.Parts.Include(p => p.Files).FirstOrDefaultAsync(p => p.Id == partId, ct);
        if (part is null) return false;

        var pdf = part.Files.FirstOrDefault(f => f.Kind == PartFileKind.Pdf);
        if (pdf is null)
        {
            log.LogWarning("Detections-on-Part {PartId}: kein PDF angehängt", partId);
            return false;
        }

        var json = await engine.RecognizeDetectionsJsonAsync(pdf.BlobKey, pdf.OriginalFileName, ct);
        if (string.IsNullOrEmpty(json))
        {
            log.LogWarning("Detections-on-Part {PartId}: Engine lieferte kein JSON (Engine unterstützt /detections nicht?)", partId);
            return false;
        }

        // Alte Detections-Files entfernen
        foreach (var old in part.Files.Where(f => f.Kind == PartFileKind.Detections).ToList())
        {
            db.PartFiles.Remove(old);
        }
        await db.SaveChangesAsync(ct);

        var bytes = System.Text.Encoding.UTF8.GetBytes(json);
        using var ms = new MemoryStream(bytes);
        var name = $"{Path.GetFileNameWithoutExtension(pdf.OriginalFileName)}.detections.json";
        var blobKey = await store.SaveAsync(ms, $"parts/{partId}", name, ct);
        db.PartFiles.Add(PartFile.Create(partId, PartFileKind.Detections, blobKey, name, bytes.Length));
        await db.SaveChangesAsync(ct);

        log.LogInformation("Detections-on-Part {PartId}: {Bytes} byte JSON gespeichert", partId, bytes.Length);
        return true;
    }

    /// <summary>
    /// Liefert das Detections-JSON einer Stimme oder null wenn nicht vorhanden.
    /// </summary>
    public async Task<string?> GetDetectionsJsonAsync(Guid partId, CancellationToken ct = default)
    {
        var pf = await db.PartFiles
            .Where(f => f.PartId == partId && f.Kind == PartFileKind.Detections)
            .OrderByDescending(f => f.CreatedAt)
            .FirstOrDefaultAsync(ct);
        if (pf is null || !store.Exists(pf.BlobKey)) return null;
        await using var stream = store.OpenRead(pf.BlobKey);
        using var reader = new StreamReader(stream);
        return await reader.ReadToEndAsync(ct);
    }

    /// <summary>
    /// Liefert die persistierte MusicXML einer Stimme (Pipeline-Output) — wird
    /// vom Annotation-Tool für die "Notenansicht" verwendet (Verovio-Render).
    /// pageIndex ignored aktuell (wir haben pro Part nur EINE MusicXML, die alle
    /// Pages enthält); kann später erweitert werden.
    /// </summary>
    public async Task<string?> GetMusicXmlAsync(Guid partId, int pageIndex = 0, CancellationToken ct = default)
    {
        _ = pageIndex; // reserved für künftige per-page MusicXML
        var pf = await db.PartFiles
            .Where(f => f.PartId == partId && f.Kind == PartFileKind.MusicXml)
            .OrderByDescending(f => f.CreatedAt)
            .FirstOrDefaultAsync(ct);
        if (pf is null || !store.Exists(pf.BlobKey)) return null;
        await using var stream = store.OpenRead(pf.BlobKey);
        using var reader = new StreamReader(stream);
        return await reader.ReadToEndAsync(ct);
    }

    /// <summary>
    /// True wenn für die Stimme bereits Detections persistiert sind.
    /// </summary>
    public Task<bool> HasDetectionsAsync(Guid partId, CancellationToken ct = default)
        => db.PartFiles.AnyAsync(f => f.PartId == partId && f.Kind == PartFileKind.Detections, ct);

    /// <summary>
    /// Holt alle PartAnnotations einer Stimme + Seite.
    /// </summary>
    public Task<List<PartAnnotation>> GetAnnotationsAsync(Guid partId, int? pageIndex = null, CancellationToken ct = default)
    {
        var q = db.PartAnnotations.Where(a => a.PartId == partId);
        if (pageIndex.HasValue) q = q.Where(a => a.PageIndex == pageIndex.Value);
        return q.OrderBy(a => a.PageIndex).ThenBy(a => a.BboxY).ThenBy(a => a.BboxX).ToListAsync(ct);
    }

    public async Task<PartAnnotation> AddAnnotationAsync(
        Guid partId,
        Guid userId,
        int pageIndex,
        int x, int y, int w, int h,
        PartAnnotationKind kind,
        string? correctionJson = null,
        string? comment = null,
        CancellationToken ct = default)
    {
        var ann = PartAnnotation.Create(partId, userId, pageIndex, x, y, w, h, kind, correctionJson, comment);
        db.PartAnnotations.Add(ann);
        await db.SaveChangesAsync(ct);
        return ann;
    }

    public async Task<bool> UpdateAnnotationAsync(
        Guid annotationId,
        Guid userId,
        PartAnnotationKind kind,
        string? correctionJson,
        string? comment,
        CancellationToken ct = default)
    {
        var ann = await db.PartAnnotations.FirstOrDefaultAsync(a => a.Id == annotationId, ct);
        if (ann is null) return false;
        // Nur der Author oder ein anderer Notenverwalter darf editieren — Berechtigungs-Check
        // erfolgt auf API-Layer, hier nur Existenz-Check.
        ann.Update(kind, correctionJson, comment);
        await db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<bool> DeleteAnnotationAsync(Guid annotationId, CancellationToken ct = default)
    {
        var ann = await db.PartAnnotations.FirstOrDefaultAsync(a => a.Id == annotationId, ct);
        if (ann is null) return false;
        db.PartAnnotations.Remove(ann);
        await db.SaveChangesAsync(ct);
        return true;
    }

    /// <summary>
    /// Export-Format für externes Training: Detections + Annotations + PageImage-URLs
    /// gebündelt als JSON. Kann an einen ML-Pipeline-Trainings-Job geliefert werden.
    /// </summary>
    public sealed record TrainingExport(
        Guid PartId,
        string PartName,
        List<TrainingPage> Pages,
        List<PartAnnotation> Annotations,
        TrainingScope Scope);

    public sealed record TrainingPage(
        int PageIndex,
        string ImageBlobKey,
        string DetectionsJson);

    /// <summary>
    /// Steuert welche Detection-Bereiche in den Trainings-Export einfließen.
    /// </summary>
    public enum TrainingScope
    {
        /// Komplettes Bild + alle Detections (auch unbestätigte) — nur sinnvoll
        /// für vollständig durchgelabelte Stimmen.
        Full = 0,
        /// Nur Detections in confirmed/corrected Bereichen — andere Detections
        /// werden gestrichelt (uncertain) und vom Training ignoriert.
        /// Empfohlen für teilweise gelabelte Stimmen — keine schlechten
        /// Trainingsdaten durch unbestätigte Bereiche.
        ConfirmedOnly = 1,
    }

    public async Task<TrainingExport?> ExportForTrainingAsync(
        Guid partId, TrainingScope scope = TrainingScope.ConfirmedOnly, CancellationToken ct = default)
    {
        var part = await db.Parts.Include(p => p.Files).FirstOrDefaultAsync(p => p.Id == partId, ct);
        if (part is null) return null;
        // E2E-Test-Daten ausschliessen: Pieces mit Title-Prefix [E2E-TEST] werden
        // niemals exportiert. Marker dient als sichere Trennung zwischen
        // Test-Daten und produktiven Trainings-Daten.
        var piece = await db.Pieces.FirstOrDefaultAsync(p => p.Id == part.PieceId, ct);
        if (piece is not null && (piece.Title?.StartsWith("[E2E-TEST]", StringComparison.Ordinal) ?? false))
        {
            log.LogInformation("Training-Export fuer {PartId} uebersprungen (Test-Marker im Piece-Title)", partId);
            return null;
        }
        var detJson = await GetDetectionsJsonAsync(partId, ct);
        if (string.IsNullOrEmpty(detJson)) return null;
        var pages = part.Files.Where(f => f.Kind == PartFileKind.PageImage)
            .OrderBy(f => f.PageNumber)
            .Select(f => new TrainingPage((f.PageNumber ?? 1) - 1, f.BlobKey, detJson))
            .ToList();
        var anns = await GetAnnotationsAsync(partId, null, ct);
        return new TrainingExport(partId, part.DisplayName, pages, anns, scope);
    }

    /// <summary>
    /// Liefert eine kompakte Übersicht: wie viele Detections sind bestätigt/korrigiert
    /// vs unbestätigt (für UI-Progress + Training-Eligibility-Hinweis).
    /// </summary>
    public async Task<(int total, int confirmed, int corrected, int uncertain)> GetCoverageAsync(
        Guid partId, CancellationToken ct = default)
    {
        var detJson = await GetDetectionsJsonAsync(partId, ct);
        if (string.IsNullOrEmpty(detJson)) return (0, 0, 0, 0);
        var anns = await GetAnnotationsAsync(partId, null, ct);
        // Confirmed: PartAnnotationKind.Confirmed (6) + RegionConfirmed (7)
        // Corrected: WrongPitch/WrongDuration/WrongKind/NotANote (1,2,3,0)
        var confirmed = anns.Count(a => a.Kind == PartAnnotationKind.Confirmed);
        var regions = anns.Count(a => a.Kind == PartAnnotationKind.RegionConfirmed);
        var corrected = anns.Count(a => a.Kind == PartAnnotationKind.WrongPitch
            || a.Kind == PartAnnotationKind.WrongDuration
            || a.Kind == PartAnnotationKind.WrongKind
            || a.Kind == PartAnnotationKind.NotANote
            || a.Kind == PartAnnotationKind.MissedNote);
        // total: NHs aus DetectionsJson zaehlen
        var total = 0;
        try
        {
            using var doc = System.Text.Json.JsonDocument.Parse(detJson);
            if (doc.RootElement.TryGetProperty("pages", out var pages))
            {
                foreach (var p in pages.EnumerateArray())
                {
                    if (p.TryGetProperty("noteheads", out var nhs)) total += nhs.GetArrayLength();
                }
            }
        }
        catch { }
        var uncertain = Math.Max(0, total - confirmed - corrected);
        return (total, confirmed + regions, corrected, uncertain);
    }
}
