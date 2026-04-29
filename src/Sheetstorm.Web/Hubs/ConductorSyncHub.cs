using Microsoft.AspNetCore.SignalR;

namespace Sheetstorm.Web.Hubs;

public sealed record NowPlayingPayload(Guid EventId, Guid PieceId, string Title, DateTimeOffset SinceUtc);

public sealed class ConductorSyncHub : Hub
{
    public Task JoinEvent(Guid eventId) => Groups.AddToGroupAsync(Context.ConnectionId, $"event-{eventId}");
    public Task LeaveEvent(Guid eventId) => Groups.RemoveFromGroupAsync(Context.ConnectionId, $"event-{eventId}");
}
