using Sheetstorm.Domain.Sync;

namespace Sheetstorm.Infrastructure.Sync;

public interface ISyncService
{
    Task<SyncStateResponse> GetStateAsync(Guid musicianId, CancellationToken ct);
    Task<PullResponse> PullAsync(Guid musicianId, PullRequest request, CancellationToken ct);
    Task<PushResponse> PushAsync(Guid musicianId, PushRequest request, CancellationToken ct);
    Task ResolveAsync(Guid musicianId, ResolveRequest request, CancellationToken ct);
}
