using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.SongBroadcast;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Api.Hubs;

[Authorize]
public class SongBroadcastHub(AppDbContext db) : Hub
{
    // bandId → BroadcastState
    private static readonly ConcurrentDictionary<Guid, BroadcastState> ActiveBroadcasts = new();

    // bandId → set of connectionIds
    private static readonly ConcurrentDictionary<Guid, ConcurrentDictionary<string, Guid>> BandConnections = new();

    private Guid? GetUserId()
    {
        var sub = Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        return sub != null && Guid.TryParse(sub, out var id) ? id : null;
    }

    private string GetUserName()
    {
        return Context.User?.FindFirst("name")?.Value
            ?? Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? "Unknown";
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive);

        return m ?? throw new HubException("Not a member of this band.");
    }

    private async Task RequireConductorOrAdminAsync(Guid bandId, Guid musicianId)
    {
        var m = await RequireMembershipAsync(bandId, musicianId);

        if (m.Role is not (MemberRole.Administrator or MemberRole.Conductor))
            throw new HubException("Only conductors or admins can perform this action.");
    }

    /// <summary>Start a broadcast session for a band. Only conductors/admins.</summary>
    public async Task StartBroadcast(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        var userName = GetUserName();

        await RequireConductorOrAdminAsync(bandId, userId);

        if (ActiveBroadcasts.TryGetValue(bandId, out var existing) && existing.IsActive)
            throw new HubException($"A broadcast is already active for this band, started by {existing.ConductorName}.");

        var state = new BroadcastState(
            bandId,
            userId,
            userName,
            IsActive: true,
            CurrentSong: null,
            ParticipantCount: 0,
            StartedAt: DateTime.UtcNow
        );

        ActiveBroadcasts[bandId] = state;

        await Groups.AddToGroupAsync(Context.ConnectionId, BandGroup(bandId));
        TrackConnection(bandId, Context.ConnectionId, userId);

        await Clients.Group(BandGroup(bandId)).SendAsync("OnBroadcastStarted",
            new BroadcastStartedMessage(bandId, userId, userName, DateTime.UtcNow));
    }

    /// <summary>Stop the broadcast session for a band.</summary>
    public async Task StopBroadcast(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        var userName = GetUserName();

        await RequireConductorOrAdminAsync(bandId, userId);

        if (!ActiveBroadcasts.TryRemove(bandId, out _))
            throw new HubException("No active broadcast for this band.");

        await Clients.Group(BandGroup(bandId)).SendAsync("OnBroadcastStopped",
            new BroadcastStoppedMessage(bandId, userId, userName, DateTime.UtcNow));

        // Clean up connections
        BandConnections.TryRemove(bandId, out _);
    }

    /// <summary>Set the current song for the broadcast.</summary>
    public async Task SetCurrentSong(Guid bandId, Guid pieceId, string title)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");

        await RequireConductorOrAdminAsync(bandId, userId);

        if (!ActiveBroadcasts.TryGetValue(bandId, out var state) || !state.IsActive)
            throw new HubException("No active broadcast for this band.");

        var song = new CurrentSongInfo(pieceId, title, DateTime.UtcNow);

        ActiveBroadcasts[bandId] = state with { CurrentSong = song };

        await Clients.Group(BandGroup(bandId)).SendAsync("OnSongChanged",
            new SongChangedMessage(bandId, pieceId, title, DateTime.UtcNow));
    }

    /// <summary>Advance to the next song (client must provide the next song info).</summary>
    public async Task NextSong(Guid bandId, Guid pieceId, string title)
    {
        await SetCurrentSong(bandId, pieceId, title);
    }

    /// <summary>Go back to the previous song (client must provide the previous song info).</summary>
    public async Task PreviousSong(Guid bandId, Guid pieceId, string title)
    {
        await SetCurrentSong(bandId, pieceId, title);
    }

    /// <summary>Join a band's broadcast group as a participant.</summary>
    public async Task<BroadcastState?> JoinBroadcast(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");

        await RequireMembershipAsync(bandId, userId);

        await Groups.AddToGroupAsync(Context.ConnectionId, BandGroup(bandId));
        TrackConnection(bandId, Context.ConnectionId, userId);

        ActiveBroadcasts.TryGetValue(bandId, out var state);

        if (state != null)
        {
            var count = GetParticipantCount(bandId);
            ActiveBroadcasts[bandId] = state with { ParticipantCount = count };

            await Clients.Group(BandGroup(bandId)).SendAsync("OnParticipantCountChanged",
                new ParticipantCountChangedMessage(bandId, count));
        }

        return state;
    }

    /// <summary>Leave a band's broadcast group.</summary>
    public async Task LeaveBroadcast(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireMembershipAsync(bandId, userId);

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, BandGroup(bandId));
        RemoveConnection(bandId, Context.ConnectionId);

        if (ActiveBroadcasts.TryGetValue(bandId, out var state))
        {
            var count = GetParticipantCount(bandId);
            ActiveBroadcasts[bandId] = state with { ParticipantCount = count };

            await Clients.Group(BandGroup(bandId)).SendAsync("OnParticipantCountChanged",
                new ParticipantCountChangedMessage(bandId, count));
        }
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        // Remove from all band groups
        foreach (var kvp in BandConnections)
        {
            if (kvp.Value.TryRemove(Context.ConnectionId, out var disconnectedUserId))
            {
                var bandId = kvp.Key;
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, BandGroup(bandId));

                if (ActiveBroadcasts.TryGetValue(bandId, out var state))
                {
                    if (state.ConductorId == disconnectedUserId)
                    {
                        // Conductor disconnected — auto-end the broadcast
                        ActiveBroadcasts.TryRemove(bandId, out _);

                        await Clients.Group(BandGroup(bandId)).SendAsync("OnBroadcastStopped",
                            new BroadcastStoppedMessage(bandId, disconnectedUserId, state.ConductorName, DateTime.UtcNow));
                    }
                    else
                    {
                        var count = GetParticipantCount(bandId);
                        ActiveBroadcasts[bandId] = state with { ParticipantCount = count };

                        await Clients.Group(BandGroup(bandId)).SendAsync("OnParticipantCountChanged",
                            new ParticipantCountChangedMessage(bandId, count));
                    }
                }
            }
        }

        await base.OnDisconnectedAsync(exception);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static string BandGroup(Guid bandId) => $"band-broadcast-{bandId}";

    private static void TrackConnection(Guid bandId, string connectionId, Guid userId)
    {
        var connections = BandConnections.GetOrAdd(bandId, _ => new ConcurrentDictionary<string, Guid>());
        connections[connectionId] = userId;
    }

    private static void RemoveConnection(Guid bandId, string connectionId)
    {
        if (BandConnections.TryGetValue(bandId, out var connections))
            connections.TryRemove(connectionId, out _);
    }

    private static int GetParticipantCount(Guid bandId)
    {
        return BandConnections.TryGetValue(bandId, out var connections) ? connections.Count : 0;
    }
}
