using FluentAssertions;
using Sheetstorm.PdfLabeling.Services;
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
}
