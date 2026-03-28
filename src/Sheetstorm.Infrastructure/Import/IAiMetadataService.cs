using Sheetstorm.Domain.Import;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// AI adapter for extracting metadata from uploaded sheet music files.
/// Adapter pattern: swap implementations without changing the pipeline.
/// </summary>
public interface IAiMetadataService
{
    /// <summary>Extract metadata (title, composer, key, etc.) from a file stream.</summary>
    Task<StueckMetadataDto> ExtractMetadataAsync(Stream stream, string fileName, CancellationToken ct = default);
}
