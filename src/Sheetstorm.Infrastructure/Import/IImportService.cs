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
        Guid? bandId,
        Guid musicianId,
        CancellationToken ct = default);

    Task<IReadOnlyList<PieceDto>> GetPiecesAsync(Guid bandId, Guid musicianId, CancellationToken ct = default);
    Task<PieceDto> GetPieceAsync(Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct = default);
    Task<PieceDto> CreatePieceAsync(Guid bandId, PieceCreateDto dto, Guid musicianId, CancellationToken ct = default);
    Task<PieceDto> UpdatePieceAsync(Guid bandId, Guid pieceId, PieceUpdateDto dto, Guid musicianId, CancellationToken ct = default);
    Task DeletePieceAsync(Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct = default);
}
