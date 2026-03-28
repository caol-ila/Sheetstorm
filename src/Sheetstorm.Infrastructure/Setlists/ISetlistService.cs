using Sheetstorm.Domain.Setlists;

namespace Sheetstorm.Infrastructure.Setlists;

public interface ISetlistService
{
    Task<IReadOnlyList<SetlistDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<SetlistDetailDto> GetByIdAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct);
    Task<SetlistDetailDto> CreateAsync(Guid bandId, CreateSetlistRequest request, Guid musicianId, CancellationToken ct);
    Task<SetlistDetailDto> UpdateAsync(Guid bandId, Guid setlistId, UpdateSetlistRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct);
    Task<SetlistEntryDto> AddEntryAsync(Guid bandId, Guid setlistId, AddSetlistEntryRequest request, Guid musicianId, CancellationToken ct);
    Task<SetlistEntryDto> UpdateEntryAsync(Guid bandId, Guid setlistId, Guid entryId, UpdateSetlistEntryRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteEntryAsync(Guid bandId, Guid setlistId, Guid entryId, Guid musicianId, CancellationToken ct);
    Task ReorderEntriesAsync(Guid bandId, Guid setlistId, ReorderEntriesRequest request, Guid musicianId, CancellationToken ct);
    Task<SetlistDetailDto> DuplicateAsync(Guid bandId, Guid setlistId, Guid musicianId, CancellationToken ct);
}
