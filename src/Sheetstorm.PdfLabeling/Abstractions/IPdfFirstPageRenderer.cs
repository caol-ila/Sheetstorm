namespace Sheetstorm.PdfLabeling.Abstractions;

public interface IPdfFirstPageRenderer
{
    Task<byte[]> RenderFirstPageAsPngAsync(string pdfPath, int dpi = 300, CancellationToken ct = default);
}
