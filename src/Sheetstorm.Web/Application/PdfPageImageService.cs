using Microsoft.EntityFrameworkCore;
using PDFtoImage;
using SkiaSharp;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Wandelt ein PDF in PNG-Seitenbilder um. Nutzt PDFtoImage (PDFium + SkiaSharp).
/// Idempotent: erkennt vorhandene PageImage-Dateien und ueberspringt.
/// </summary>
public sealed class PdfPageImageService(SheetstormDbContext db, LocalFileStore store, ILogger<PdfPageImageService> log)
{
    public const int Dpi = 150;

    /// <summary>
    /// Stellt sicher, dass fuer die uebergebene Stimme PageImage-Dateien existieren.
    /// Wenn bereits welche existieren: kein Re-Render. Sonst: rendert das Original-PDF.
    /// </summary>
    public async Task<int> EnsurePageImagesAsync(Guid partId, CancellationToken ct = default)
    {
        var existingCount = await db.PartFiles.CountAsync(f => f.PartId == partId && f.Kind == PartFileKind.PageImage, ct);
        if (existingCount > 0) return existingCount;

        var pdf = await db.PartFiles.FirstOrDefaultAsync(f => f.PartId == partId && f.Kind == PartFileKind.Pdf, ct);
        if (pdf is null)
        {
            log.LogWarning("EnsurePageImages: Stimme {PartId} hat kein PDF", partId);
            return 0;
        }
        if (!store.Exists(pdf.BlobKey))
        {
            log.LogWarning("EnsurePageImages: PDF-Blob fehlt: {BlobKey}", pdf.BlobKey);
            return 0;
        }

        await using var pdfStream = store.OpenRead(pdf.BlobKey);
        using var ms = new MemoryStream();
        await pdfStream.CopyToAsync(ms, ct);
        var bytes = ms.ToArray();

        // PDFtoImage rendert alle Seiten als IEnumerable<SKBitmap>
        var pageNumber = 0;
        var added = 0;
        var pageCount = Conversion.GetPageCount(bytes);
        log.LogInformation("PdfPageImage: rendere {Pages} Seite(n) fuer Stimme {PartId}", pageCount, partId);
        for (var p = 0; p < pageCount; p++)
        {
            using var bmp = Conversion.ToImage(bytes, page: p, options: new RenderOptions(Dpi: Dpi));
            using var data = bmp.Encode(SKEncodedImageFormat.Png, 90);
            var pageBytes = data.ToArray();

            pageNumber = p + 1;
            using var pageStream = new MemoryStream(pageBytes);
            var blobKey = await store.SaveAsync(pageStream, $"parts/{partId}", $"page-{pageNumber:D3}.png", ct);
            db.PartFiles.Add(PartFile.Create(partId, PartFileKind.PageImage, blobKey, $"page-{pageNumber:D3}.png", pageBytes.Length, pages: pageCount, pageNumber: pageNumber));
            added++;
        }
        await db.SaveChangesAsync(ct);
        log.LogInformation("PdfPageImage: {Added} PNGs fuer Stimme {PartId} gespeichert", added, partId);
        return added;
    }

    /// <summary>Loescht alle PageImage-Eintraege einer Stimme (z. B. wenn PDF ersetzt wurde).</summary>
    public async Task InvalidateAsync(Guid partId, CancellationToken ct = default)
    {
        var pages = await db.PartFiles.Where(f => f.PartId == partId && f.Kind == PartFileKind.PageImage).ToListAsync(ct);
        foreach (var p in pages)
        {
            // Blob-File loeschen ist optional — wir loeschen es um Speicher zu sparen
            try { var path = Path.Combine(store.Root, p.BlobKey); if (File.Exists(path)) File.Delete(path); } catch { }
            db.PartFiles.Remove(p);
        }
        if (pages.Count > 0)
        {
            await db.SaveChangesAsync(ct);
            log.LogInformation("PdfPageImage: {Count} alte PNGs fuer Stimme {PartId} entfernt", pages.Count, partId);
        }
    }
}
