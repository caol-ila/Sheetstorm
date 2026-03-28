using Sheetstorm.Domain.Import;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// Orchestrates the import pipeline: upload → store → AI extract → create Stück.
/// </summary>
public interface IImportService
{
    Task<ImportResultDto> ImportAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        Guid? kapelleId,
        Guid musikerId,
        CancellationToken ct = default);

    Task<IReadOnlyList<StueckDto>> GetStueckeAsync(Guid kapelleId, Guid musikerId, CancellationToken ct = default);
    Task<StueckDto> GetStueckAsync(Guid kapelleId, Guid stueckId, Guid musikerId, CancellationToken ct = default);
    Task<StueckDto> CreateStueckAsync(Guid kapelleId, StueckCreateDto dto, Guid musikerId, CancellationToken ct = default);
    Task<StueckDto> UpdateStueckAsync(Guid kapelleId, Guid stueckId, StueckUpdateDto dto, Guid musikerId, CancellationToken ct = default);
    Task DeleteStueckAsync(Guid kapelleId, Guid stueckId, Guid musikerId, CancellationToken ct = default);
}
