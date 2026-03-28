using Sheetstorm.Domain.Polls;

namespace Sheetstorm.Infrastructure.Polls;

public interface IPollService
{
    Task<IReadOnlyList<PollDto>> GetAllAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<PollDetailDto> GetByIdAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct);
    Task<PollDetailDto> CreateAsync(Guid bandId, CreatePollRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct);
    Task VoteAsync(Guid bandId, Guid pollId, VotePollRequest request, Guid musicianId, CancellationToken ct);
    Task CloseAsync(Guid bandId, Guid pollId, Guid musicianId, CancellationToken ct);
}
