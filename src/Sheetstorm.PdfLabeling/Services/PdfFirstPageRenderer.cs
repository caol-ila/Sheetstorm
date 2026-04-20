using Docnet.Core;
using Docnet.Core.Models;
using Sheetstorm.PdfLabeling.Abstractions;
using SkiaSharp;

namespace Sheetstorm.PdfLabeling.Services;

/// <summary>
/// Renders the first page of a PDF as a PNG image using raster rendering.
/// Uses Docnet.Core (PDFium) for true PDF rasterization and SkiaSharp for post-processing.
/// </summary>
/// <remarks>
/// RASTER RENDERING APPROACH:
/// This implementation uses PDFium (via Docnet.Core) to render PDFs as raster images.
/// This handles all PDF types: scanned documents (image-only), digital documents with
/// vector graphics and fonts, and mixed content. The output is optimized for AI vision
/// models with automatic resizing to reduce token costs while preserving readability.
/// </remarks>
public sealed class PdfFirstPageRenderer : IPdfFirstPageRenderer
{
    private const int MaxVisionDimension = 2000;

    public async Task<byte[]> RenderFirstPageAsPngAsync(
        string pdfPath,
        int dpi = 300,
        CancellationToken ct = default)
    {
        // Validate file exists
        if (!File.Exists(pdfPath))
        {
            throw new FileNotFoundException($"PDF file not found: {pdfPath}", pdfPath);
        }

        // Check cancellation at entry
        ct.ThrowIfCancellationRequested();

        // Wrap synchronous Docnet/SkiaSharp work in Task.Run to avoid blocking
        return await Task.Run(() =>
        {
            ct.ThrowIfCancellationRequested();

            try
            {
                // Calculate scaling factor from DPI
                // Standard PDF DPI is 72, so scaling = targetDPI / 72
                var scalingFactor = dpi / 72.0;
                
                using var docReader = DocLib.Instance.GetDocReader(
                    pdfPath,
                    new PageDimensions(scalingFactor));
                
                if (docReader.GetPageCount() == 0)
                {
                    throw new PdfRenderingException($"PDF file contains no pages: {pdfPath}");
                }

                using var pageReader = docReader.GetPageReader(0); // First page (0-indexed)
                
                var rawBytes = pageReader.GetImage(); // BGRA format
                var width = pageReader.GetPageWidth();
                var height = pageReader.GetPageHeight();

                ct.ThrowIfCancellationRequested();

                // Convert BGRA bytes to SKBitmap
                using var bitmap = new SKBitmap();
                var imageInfo = new SKImageInfo(
                    width,
                    height,
                    SKColorType.Bgra8888,
                    SKAlphaType.Unpremul);
                
                var handle = System.Runtime.InteropServices.GCHandle.Alloc(
                    rawBytes,
                    System.Runtime.InteropServices.GCHandleType.Pinned);
                
                try
                {
                    bitmap.InstallPixels(
                        imageInfo,
                        handle.AddrOfPinnedObject(),
                        imageInfo.RowBytes);

                    ct.ThrowIfCancellationRequested();

                    // Vision optimization: resize if too large
                    var finalBitmap = ApplyVisionResize(bitmap);
                    try
                    {
                        // Encode to PNG
                        using var image = SKImage.FromBitmap(finalBitmap);
                        using var data = image.Encode(SKEncodedImageFormat.Png, 100);
                        return data.ToArray();
                    }
                    finally
                    {
                        if (finalBitmap != bitmap)
                        {
                            finalBitmap.Dispose();
                        }
                    }
                }
                finally
                {
                    handle.Free();
                }
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (FileNotFoundException)
            {
                throw;
            }
            catch (PdfRenderingException)
            {
                throw;
            }
            catch (Exception ex)
            {
                // Wrap Docnet/PDFium exceptions as PdfRenderingException
                throw new PdfRenderingException(
                    $"Failed to render PDF: {pdfPath}. The file may be corrupted, encrypted, or invalid.",
                    ex);
            }
        }, ct);
    }

    /// <summary>
    /// Resizes image if longest edge exceeds MaxVisionDimension to reduce GPT-4o Vision costs.
    /// Preserves aspect ratio. Returns original bitmap if no resize needed.
    /// </summary>
    private static SKBitmap ApplyVisionResize(SKBitmap original)
    {
        var maxDimension = Math.Max(original.Width, original.Height);
        
        if (maxDimension <= MaxVisionDimension)
        {
            return original; // No resize needed
        }

        // Calculate new dimensions preserving aspect ratio
        var scale = (double)MaxVisionDimension / maxDimension;
        var newWidth = (int)(original.Width * scale);
        var newHeight = (int)(original.Height * scale);

        var resized = original.Resize(
            new SKImageInfo(newWidth, newHeight),
            SKSamplingOptions.Default);

        return resized ?? original;
    }
}