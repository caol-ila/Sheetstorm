using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Api.Hubs;

[Authorize]
public class AnnotationSyncHub(AppDbContext db) : Hub
{
    // connectionId → set of group names (for cleanup on disconnect)
    private static readonly ConcurrentDictionary<string, HashSet<string>> ConnectionGroups = new();

    private Guid? GetUserId()
    {
        var sub = Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        return sub != null && Guid.TryParse(sub, out var id) ? id : null;
    }

    /// <summary>Join an annotation sync group (Voice or Orchestra level).</summary>
    public async Task JoinAnnotationGroup(Guid bandId, Guid piecePageId, string level, Guid? voiceId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireMembershipAsync(bandId, userId);

        var groupName = BuildGroupName(bandId, piecePageId, level, voiceId);
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        TrackGroup(Context.ConnectionId, groupName);
    }

    /// <summary>Leave an annotation sync group.</summary>
    public async Task LeaveAnnotationGroup(Guid bandId, Guid piecePageId, string level, Guid? voiceId)
    {
        var groupName = BuildGroupName(bandId, piecePageId, level, voiceId);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
        UntrackGroup(Context.ConnectionId, groupName);
    }

    /// <summary>Notify other clients about an element change (real-time shortcut).</summary>
    public async Task NotifyElementChange(string groupName, ElementChangeNotification notification)
    {
        var clientProxy = Clients.OthersInGroup(groupName);

        switch (notification.ChangeType)
        {
            case "added":
                await clientProxy.SendAsync("OnElementAdded", notification.Element);
                break;

            case "updated":
                await clientProxy.SendAsync("OnElementUpdated", notification.Element);
                break;

            case "deleted":
                await clientProxy.SendAsync("OnElementDeleted", notification.ElementId, notification.AnnotationId);
                break;
        }
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (ConnectionGroups.TryRemove(Context.ConnectionId, out var groups))
        {
            foreach (var group in groups)
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, group);
        }

        await base.OnDisconnectedAsync(exception);
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private static string BuildGroupName(Guid bandId, Guid piecePageId, string level, Guid? voiceId) =>
        level switch
        {
            "Voice" => $"annotation-voice-{bandId}-{voiceId}-{piecePageId}",
            "Orchestra" => $"annotation-orchestra-{bandId}-{piecePageId}",
            _ => throw new HubException($"Invalid annotation level: {level}")
        };

    private static void TrackGroup(string connectionId, string groupName)
    {
        var groups = ConnectionGroups.GetOrAdd(connectionId, _ => []);
        lock (groups) { groups.Add(groupName); }
    }

    private static void UntrackGroup(string connectionId, string groupName)
    {
        if (ConnectionGroups.TryGetValue(connectionId, out var groups))
            lock (groups) { groups.Remove(groupName); }
    }

    private async Task RequireMembershipAsync(Guid bandId, Guid musicianId)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive);

        if (m == null)
            throw new HubException("Not a member of this band.");
    }
}
