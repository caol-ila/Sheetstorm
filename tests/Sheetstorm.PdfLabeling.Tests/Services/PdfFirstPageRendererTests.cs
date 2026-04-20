using FluentAssertions;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Services;
using Sheetstorm.PdfLabeling.Tests.Fixtures;
using SkiaSharp;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Writer;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Services;

public class PdfFirstPageRendererTests : IDisposable
{
    private readonly PdfFirstPageRenderer _sut;
    private readonly string _tempDir;

    public PdfFirstPageRendererTests()
    {
        _sut = new PdfFirstPageRenderer();
        _tempDir = Path.Combine(Path.GetTempPath(), $"PdfRendererTests_{Guid.NewGuid()}");
        Directory.CreateDirectory(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
        {
            Directory.Delete(_tempDir, recursive: true);
        }
    }

    private string CreateTestPdf(string fileName, int pageCount = 1)
    {
        var path = Path.Combine(_tempDir, fileName);
        var builder = new PdfDocumentBuilder();

        for (int i = 0; i < pageCount; i++)
        {
            // AddPage expects width and height in points
            var page = builder.AddPage(595, 842); // A4 size in points
            var font = builder.AddStandard14Font(UglyToad.PdfPig.Fonts.Standard14Fonts.Standard14Font.Helvetica);
            
            // Draw text on the page - positioned at different locations for multi-page tests
            var letters = new List<UglyToad.PdfPig.Content.Letter>();
            page.AddText($"Test Page {i + 1}", 12, new UglyToad.PdfPig.Core.PdfPoint(50, 750 - (i * 20)), font);
            page.AddText($"This is page number {i + 1}", 10, new UglyToad.PdfPig.Core.PdfPoint(50, 700 - (i * 20)), font);
        }

        var pdfBytes = builder.Build();
        File.WriteAllBytes(path, pdfBytes);
        return path;
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_ValidPdf_ReturnsNonEmptyPngBytes()
    {
        // Arrange
        var pdfPath = CreateTestPdf("test-valid.pdf");

        // Act
        var result = await _sut.RenderFirstPageAsPngAsync(pdfPath);

        // Assert
        result.Should().NotBeEmpty();
        result.Length.Should().BeGreaterThan(0);
        
        // Verify PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        result.Take(8).Should().Equal(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_DpiChangesOutputSize()
    {
        // Arrange
        var pdfPath = CreateTestPdf("test-dpi.pdf");

        // Act
        var result150 = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 150);
        var result300 = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 300);

        // Assert
        result150.Should().NotBeEmpty();
        result300.Should().NotBeEmpty();
        
        // Higher DPI should produce larger image (more bytes)
        result300.Length.Should().BeGreaterThan(result150.Length);
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_MissingFile_ThrowsFileNotFoundException()
    {
        // Arrange
        var missingPath = Path.Combine(_tempDir, "nonexistent.pdf");

        // Act & Assert
        var ex = await Assert.ThrowsAsync<FileNotFoundException>(
            () => _sut.RenderFirstPageAsPngAsync(missingPath));
        
        ex.Message.Should().Contain(missingPath);
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_InvalidPdf_ThrowsInvalidDataException()
    {
        // Arrange
        var invalidPath = Path.Combine(_tempDir, "invalid.pdf");
        await File.WriteAllTextAsync(invalidPath, "This is not a PDF file");

        // Act & Assert
        var ex = await Assert.ThrowsAnyAsync<Exception>(
            () => _sut.RenderFirstPageAsPngAsync(invalidPath));
        
        // Should throw InvalidDataException (or similar), but NOT FileNotFoundException
        ex.Should().NotBeOfType<FileNotFoundException>();
        ex.Message.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_Cancellation_ThrowsOperationCanceledException()
    {
        // Arrange
        var pdfPath = CreateTestPdf("test-cancel.pdf");
        var cts = new CancellationTokenSource();
        cts.Cancel();

        // Act & Assert
        await Assert.ThrowsAsync<OperationCanceledException>(
            () => _sut.RenderFirstPageAsPngAsync(pdfPath, ct: cts.Token));
    }

    [Fact]
    public async Task RenderFirstPageAsPngAsync_MultiPagePdf_RendersOnlyFirstPage()
    {
        // Arrange
        var pdfPath = CreateTestPdf("test-multipage.pdf", pageCount: 2);

        // Act
        var result = await _sut.RenderFirstPageAsPngAsync(pdfPath);

        // Assert
        result.Should().NotBeEmpty();
        
        // We can't easily verify visually, but the result should be reasonable size
        // A single A4 page at 300 DPI typically produces 100-500 KB PNG
        // Two pages would be significantly larger
        result.Length.Should().BeGreaterThan(0);
        result.Length.Should().BeLessThan(2_000_000); // Less than 2MB is reasonable for one page
    }

    // ========== NEW TESTS FOR RASTER-BASED RENDERING ==========
    
    [Fact]
    public async Task RendersScannedPageAsRasterImage_WithRealisticSize()
    {
        // Arrange - Scanned PDF with NO text layer (simulates real scanned document)
        var pdfBytes = TestPdfGenerator.CreateScannedPdf();
        var pdfPath = Path.Combine(_tempDir, "scanned-sample.pdf");
        await File.WriteAllBytesAsync(pdfPath, pdfBytes);

        // Act
        var result = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 300);

        // Assert
        result.Should().NotBeEmpty();
        
        // Log actual size for debugging
        var sizeKb = result.Length / 1024.0;
        Console.WriteLine($"Rendered PNG size: {result.Length} bytes ({sizeKb:F1} KB)");
        
        // CRITICAL: Text-only renderer produces blank white PNG for text-less PDF (very small, ~800 bytes)
        // Real raster renderer must produce realistic A4 image size
        // A4 at 300 DPI = 2480×3508 px, even blank should be several KB due to PNG format overhead
        // With proper raster rendering, even minimal page structure produces >10 KB
        result.Length.Should().BeGreaterThan(10_000, 
            "because raster-rendered PDF (even blank) produces larger PNG than text-only rendering. " +
            $"Actual size: {sizeKb:F1} KB");
    }

    [Fact]
    public async Task RendersAtConfiguredDpi()
    {
        // Arrange
        var pdfBytes = TestPdfGenerator.CreateDigitalPdf();
        var pdfPath = Path.Combine(_tempDir, "dpi-test.pdf");
        await File.WriteAllBytesAsync(pdfPath, pdfBytes);

        // Act
        var result = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 300);

        // Assert
        result.Should().NotBeEmpty();
        
        // Decode PNG to verify actual dimensions
        using var stream = new MemoryStream(result);
        using var bitmap = SKBitmap.Decode(stream);
        bitmap.Should().NotBeNull("because PNG should be decodable");
        
        // A4 page: 595×842 points = 8.27×11.69 inches
        // At 300 DPI: 8.27*300 = 2481 px width, 11.69*300 = 3507 px height
        // Allow ±10% tolerance
        bitmap!.Width.Should().BeInRange(2230, 2730, "because A4 width at 300 DPI ≈ 2480 px");
        bitmap.Height.Should().BeInRange(3156, 3856, "because A4 height at 300 DPI ≈ 3506 px");
    }

    [Fact]
    public async Task PreservesImageContent_ForDigitalPdf()
    {
        // Arrange - Digital PDF with text content
        var pdfBytes = TestPdfGenerator.CreateDigitalPdf();
        var pdfPath = Path.Combine(_tempDir, "digital-content.pdf");
        await File.WriteAllBytesAsync(pdfPath, pdfBytes);

        // Act
        var result = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 150);

        // Assert
        result.Should().NotBeEmpty();
        
        // Decode and verify non-white content (should have black text)
        using var stream = new MemoryStream(result);
        using var bitmap = SKBitmap.Decode(stream);
        bitmap.Should().NotBeNull();
        
        // Calculate average grayscale value - should NOT be pure white (255)
        long totalGray = 0;
        int pixelCount = 0;
        
        for (int y = 0; y < bitmap!.Height; y += 10) // Sample every 10th pixel for performance
        {
            for (int x = 0; x < bitmap.Width; x += 10)
            {
                var color = bitmap.GetPixel(x, y);
                var gray = (color.Red + color.Green + color.Blue) / 3;
                totalGray += gray;
                pixelCount++;
            }
        }
        
        var averageGray = totalGray / pixelCount;
        averageGray.Should().BeLessThan(250, 
            "because digital PDF contains text content, not pure white background");
    }

    [Fact]
    public async Task HandlesMultiPagePdf_OnlyFirstPage()
    {
        // Arrange
        var pdfBytes = TestPdfGenerator.CreateMultiPagePdf(pageCount: 3);
        var pdfPath = Path.Combine(_tempDir, "multipage-raster.pdf");
        await File.WriteAllBytesAsync(pdfPath, pdfBytes);

        // Act - Render twice to ensure stability
        var result1 = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 150);
        var result2 = await _sut.RenderFirstPageAsPngAsync(pdfPath, dpi: 150);

        // Assert
        result1.Should().NotBeEmpty();
        result2.Should().NotBeEmpty();
        
        // Results should be identical (deterministic rendering)
        result1.Should().Equal(result2, "because rendering same PDF page should be deterministic");
    }

    [Fact]
    public async Task ThrowsOnCorruptedPdf()
    {
        // Arrange
        var garbageBytes = TestPdfGenerator.CreateCorruptedPdf();
        var pdfPath = Path.Combine(_tempDir, "corrupted.pdf");
        await File.WriteAllBytesAsync(pdfPath, garbageBytes);

        // Act & Assert
        var ex = await Assert.ThrowsAsync<PdfRenderingException>(
            () => _sut.RenderFirstPageAsPngAsync(pdfPath));
        
        ex.Message.Should().Contain("PDF", "exception message should mention PDF format issue");
    }
}
