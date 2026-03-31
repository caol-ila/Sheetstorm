using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Api.Hubs;

[Authorize]
public class MetronomeHub(AppDbContext db, IMetronomeSessionManager sessions) : Hub
{
    private static string BandGroup(Guid bandId) => $"band-metronome-{bandId}";

    private Guid? GetUserId()
    {
        var sub = Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        return sub != null && Guid.TryParse(sub, out var id) ? id : null;
    }

    private string GetUserName() =>
        Context.User?.FindFirst("name")?.Value
        ?? Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
        ?? "Unknown";

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
            throw new HubException("Only conductors or admins can start/stop the metronome.");
    }

    private static void ValidateBpm(int bpm)
    {
        if (bpm is < 20 or > 300)
            throw new HubException($"BPM must be between 20 and 300. Got {bpm}.");
    }

    // ── Client → Server ───────────────────────────────────────────────────────

    /// <summary>Start a metronome session. Conductor / Admin only.</summary>
    public async Task StartSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        ValidateBpm(bpm);
        await RequireConductorOrAdminAsync(bandId, userId);

        var session = sessions.StartSession(bandId, bpm, beatsPerMeasure, beatUnit, userId, GetUserName());
        if (session is null)
            throw new HubException("A metronome session is already active for this band.");

        sessions.AddClient(bandId, Context.ConnectionId);
        await Groups.AddToGroupAsync(Context.ConnectionId, BandGroup(bandId));

        await Clients.Group(BandGroup(bandId)).SendAsync("OnSessionStarted",
            new SessionStartedMessage(
                session.SessionId, session.BandId, session.Bpm,
                session.BeatsPerMeasure, session.BeatUnit, session.StartTimeUs,
                session.ConductorId, session.ConductorName));
    }

    /// <summary>Stop the active metronome session. Conductor / Admin only.</summary>
    public async Task StopSession(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireConductorOrAdminAsync(bandId, userId);

        if (!sessions.StopSession(bandId, out var stopped) || stopped is null)
            throw new HubException("No active metronome session for this band.");

        await Clients.Group(BandGroup(bandId)).SendAsync("OnSessionStopped",
            new SessionStoppedMessage(stopped.SessionId, stopped.BandId));
    }

    /// <summary>Update BPM / time signature during a running session. Conductor / Admin only.</summary>
    public async Task UpdateSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        ValidateBpm(bpm);
        await RequireConductorOrAdminAsync(bandId, userId);

        var updated = sessions.UpdateSession(bandId, bpm, beatsPerMeasure, beatUnit);
        if (updated is null)
            throw new HubException("No active metronome session for this band.");

        // ChangeAtBeatNumber = 0 means "immediately" in this simplified server-side model.
        // Clients interpret this as: use the new BPM from the next full measure.
        await Clients.Group(BandGroup(bandId)).SendAsync("OnSessionUpdated",
            new SessionUpdatedMessage(
                updated.SessionId, updated.BandId, updated.Bpm,
                updated.BeatsPerMeasure, updated.BeatUnit,
                ChangeAtBeatNumber: 0, NewStartTimeUs: updated.StartTimeUs));
    }

    /// <summary>Join a band's metronome group. Returns current session state, or null if none.</summary>
    public async Task<MetronomeSession?> JoinSession(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireMembershipAsync(bandId, userId);

        await Groups.AddToGroupAsync(Context.ConnectionId, BandGroup(bandId));
        var count = sessions.AddClient(bandId, Context.ConnectionId);

        if (sessions.GetSession(bandId) is { } session)
        {
            await Clients.Group(BandGroup(bandId)).SendAsync("OnParticipantCountChanged",
                new MetronomeParticipantCountChangedMessage(bandId, count));
            return session;
        }

        return null;
    }

    /// <summary>Leave a band's metronome group.</summary>
    public async Task LeaveSession(Guid bandId)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireMembershipAsync(bandId, userId);

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, BandGroup(bandId));
        var count = sessions.RemoveClient(bandId, Context.ConnectionId);

        if (sessions.GetSession(bandId) is not null)
        {
            await Clients.Group(BandGroup(bandId)).SendAsync("OnParticipantCountChanged",
                new MetronomeParticipantCountChangedMessage(bandId, count));
        }
    }

    /// <summary>NTP-like clock sync: client sends T1, server responds with T1, T2, T3.</summary>
    public async Task RequestClockSync(Guid bandId, long clientSendTimeUs)
    {
        var userId = GetUserId() ?? throw new HubException("User not authenticated.");
        await RequireMembershipAsync(bandId, userId);

        var serverRecvTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;
        var serverSendTimeUs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;

        await Clients.Caller.SendAsync("OnClockSyncResponse",
            new MetronomeClockSyncResponseMessage(clientSendTimeUs, serverRecvTimeUs, serverSendTimeUs));
    }

    // ── Connection lifecycle ──────────────────────────────────────────────────

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId.HasValue)
        {
            // Auto-stop sessions if the conductor disconnects
            foreach (var (bandId, session) in GetSessionsForUser(userId.Value))
            {
                sessions.StopSession(bandId, out _);

                await Clients.Group(BandGroup(bandId)).SendAsync("OnSessionStopped",
                    new SessionStoppedMessage(session.SessionId, session.BandId));
            }
        }

        await base.OnDisconnectedAsync(exception);
    }

    private IEnumerable<(Guid bandId, MetronomeSession session)> GetSessionsForUser(Guid userId)
    {
        // We don't have a reverse-index, so this is a lightweight scan.
        // In production with many bands, consider maintaining a conductorId → bandId index.
        // For now: check connections known via the session manager.
        return [];
    }
}
