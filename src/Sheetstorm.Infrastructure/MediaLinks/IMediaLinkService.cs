using Sheetstorm.Domain.MediaLinks;

namespace Sheetstorm.Infrastructure.MediaLinks;

public interface IMediaLinkService
{
    Task<IReadOnlyList<MediaLinkDto>> GetAllForPieceAsync(Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct);
    Task<MediaLinkDto> CreateAsync(Guid bandId, Guid pieceId, CreateMediaLinkRequest request, Guid musicianId, CancellationToken ct);
    Task<MediaLinkDto> UpdateAsync(Guid bandId, Guid pieceId, Guid linkId, UpdateMediaLinkRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAsync(Guid bandId, Guid pieceId, Guid linkId, Guid musicianId, CancellationToken ct);
}
