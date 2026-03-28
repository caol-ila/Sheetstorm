using Sheetstorm.Domain.Import;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// Stub AI metadata service returning placeholder data.
/// Swap with a real AI implementation (e.g., OpenAI Vision) when ready.
/// </summary>
public class StubAiMetadataService : IAiMetadataService
{
    public Task<PieceMetadataDto> ExtractMetadataAsync(
        Stream stream, string fileName, CancellationToken ct = default)
    {
        var titleGuess = Path.GetFileNameWithoutExtension(fileName);

        var metadata = new PieceMetadataDto(
            Title: titleGuess,
            Composer: null,
            MusicalKey: null,
            TimeSignature: null,
            Tempo: null
        );

        return Task.FromResult(metadata);
    }
}
