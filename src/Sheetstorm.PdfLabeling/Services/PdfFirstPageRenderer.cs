using Sheetstorm.PdfLabeling.Abstractions;
using SkiaSharp;
using UglyToad.PdfPig;

namespace Sheetstorm.PdfLabeling.Services;

/// <summary>
/// Renders the first page of a PDF as a PNG image.
/// Uses PdfPig for PDF parsing and SkiaSharp for rasterization.
/// </summary>
/// <remarks>
/// PRAGMATIC RENDERING APPROACH:
/// This implementation creates a white bitmap at the target DPI dimensions and renders
/// extracted text content onto it. While not a full PDF→raster renderer (which would
/// require vector graphics, images, etc.), it's sufficient for AI title recognition
/// where the model needs to see text as pixels. For MVP purposes, this approach balances
/// complexity with functionality.
/// </remarks>
public sealed class PdfFirstPageRenderer : IPdfFirstPageRenderer
{
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

        // Wrap synchronous PdfPig/SkiaSharp work in Task.Run to avoid blocking
        return await Task.Run(() =>
        {
            ct.ThrowIfCancellationRequested();

            try
            {
                using var document = PdfDocument.Open(pdfPath);
                
                if (document.NumberOfPages == 0)
                {
                    throw new InvalidDataException($"PDF file contains no pages: {pdfPath}");
                }

                var page = document.GetPage(1);
                
                // Get page size in points (1 point = 1/72 inch)
                var pageWidth = page.Width;
                var pageHeight = page.Height;

                // Convert to pixels: pixels = points * dpi / 72
                var pixelWidth = (int)Math.Ceiling(pageWidth * dpi / 72.0);
                var pixelHeight = (int)Math.Ceiling(pageHeight * dpi / 72.0);

                ct.ThrowIfCancellationRequested();

                // Create bitmap with white background
                using var bitmap = new SKBitmap(pixelWidth, pixelHeight);
                using var canvas = new SKCanvas(bitmap);
                
                // Fill with white background
                canvas.Clear(SKColors.White);

                // Extract and render text content
                var letters = page.Letters;
                if (letters.Any())
                {
                    using var paint = new SKPaint
                    {
                        Color = SKColors.Black,
                        IsAntialias = true,
                        TextSize = 12 * dpi / 72f, // Scale text size with DPI
                        Typeface = SKTypeface.FromFamilyName("Arial")
                    };

                    // Render letters at their positions
                    // PdfPig coordinates: origin at bottom-left
                    // SkiaSharp coordinates: origin at top-left
                    foreach (var letter in letters)
                    {
                        var x = (float)(letter.Location.X * dpi / 72.0);
                        // Flip Y coordinate (PDF origin is bottom-left, SKCanvas is top-left)
                        var y = (float)((pageHeight - letter.Location.Y) * dpi / 72.0);
                        
                        canvas.DrawText(letter.Value, x, y, paint);
                    }
                }

                ct.ThrowIfCancellationRequested();

                // Encode to PNG
                using var image = SKImage.FromBitmap(bitmap);
                using var data = image.Encode(SKEncodedImageFormat.Png, 100);
                return data.ToArray();
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (FileNotFoundException)
            {
                throw;
            }
            catch (Exception ex) when (ex is not InvalidDataException)
            {
                // Wrap PdfPig exceptions (or any other unexpected exceptions) as InvalidDataException
                throw new InvalidDataException($"File is not a valid PDF or could not be processed: {pdfPath}", ex);
            }
        }, ct);
    }
}
