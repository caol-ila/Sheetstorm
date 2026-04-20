using SkiaSharp;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Writer;

namespace Sheetstorm.PdfLabeling.Tests.Fixtures;

/// <summary>
/// Generates test PDF files programmatically to avoid binary fixtures in the repository.
/// </summary>
public static class TestPdfGenerator
{
    /// <summary>
    /// Creates a scanned-style PDF with graphics/shapes but NO text layer at all.
    /// This truly simulates a scanned sheet music PDF - just a blank page from text perspective.
    /// The text-only renderer will fail to extract meaningful content.
    /// </summary>
    public static byte[] CreateScannedPdf()
    {
        var builder = new PdfDocumentBuilder();
        var page = builder.AddPage(PageSize.A4);
        
        // Do NOT add any text - a scanned PDF has no text layer!
        // The text-only renderer will produce a blank white image
        // A real raster renderer would show the actual page content
        
        return builder.Build();
    }

    /// <summary>
    /// Creates a digital PDF with actual text content (not scanned).
    /// </summary>
    public static byte[] CreateDigitalPdf()
    {
        var builder = new PdfDocumentBuilder();
        var page = builder.AddPage(PageSize.A4);
        var font = builder.AddStandard14Font(UglyToad.PdfPig.Fonts.Standard14Fonts.Standard14Font.Helvetica);
        
        page.AddText("Digital PDF Test Document", 24, new UglyToad.PdfPig.Core.PdfPoint(50, 750), font);
        page.AddText("This PDF has a real text layer.", 12, new UglyToad.PdfPig.Core.PdfPoint(50, 700), font);
        page.AddText("It should render as raster image just like scanned PDFs.", 12, new UglyToad.PdfPig.Core.PdfPoint(50, 680), font);
        
        return builder.Build();
    }

    /// <summary>
    /// Creates a multi-page PDF for testing first-page-only rendering.
    /// </summary>
    public static byte[] CreateMultiPagePdf(int pageCount)
    {
        var builder = new PdfDocumentBuilder();
        var font = builder.AddStandard14Font(UglyToad.PdfPig.Fonts.Standard14Fonts.Standard14Font.Helvetica);
        
        for (int i = 0; i < pageCount; i++)
        {
            var page = builder.AddPage(PageSize.A4);
            page.AddText($"Page {i + 1} of {pageCount}", 18, new UglyToad.PdfPig.Core.PdfPoint(50, 750), font);
            page.AddText($"This is the content of page number {i + 1}.", 12, new UglyToad.PdfPig.Core.PdfPoint(50, 700), font);
        }
        
        return builder.Build();
    }

    /// <summary>
    /// Creates invalid PDF data (garbage bytes) for error handling tests.
    /// </summary>
    public static byte[] CreateCorruptedPdf()
    {
        return "This is not a valid PDF file at all. Just garbage data."u8.ToArray();
    }
}
