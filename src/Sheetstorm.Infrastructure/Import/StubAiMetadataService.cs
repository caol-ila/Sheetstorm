using Sheetstorm.Domain.Import;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// Stub AI metadata service returning placeholder data.
/// Swap with a real AI implementation (e.g., OpenAI Vision) when ready.
/// </summary>
public class StubAiMetadataService : IAiMetadataService
{
    public Task<StueckMetadataDto> ExtractMetadataAsync(
        Stream stream, string fileName, CancellationToken ct = default)
    {
        var titleGuess = Path.GetFileNameWithoutExtension(fileName);

        var metadata = new StueckMetadataDto(
            Titel: titleGuess,
            Komponist: null,
            Tonart: null,
            Taktart: null,
            Tempo: null
        );

        return Task.FromResult(metadata);
    }
}
