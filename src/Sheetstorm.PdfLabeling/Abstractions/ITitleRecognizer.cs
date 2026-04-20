using Sheetstorm.PdfLabeling.Domain;

namespace Sheetstorm.PdfLabeling.Abstractions;

public interface ITitleRecognizer
{
    Task<TitleRecognition> RecognizeTitleAsync(byte[] pngBytes, CancellationToken ct = default);
}
