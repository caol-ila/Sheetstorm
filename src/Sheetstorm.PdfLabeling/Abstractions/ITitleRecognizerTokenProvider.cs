namespace Sheetstorm.PdfLabeling.Abstractions;

public interface ITitleRecognizerTokenProvider
{
    ValueTask<string> GetTokenAsync(CancellationToken ct = default);
}
