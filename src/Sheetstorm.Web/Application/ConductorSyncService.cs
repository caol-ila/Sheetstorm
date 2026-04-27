using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Hubs;

namespace Sheetstorm.Web.Application;

public sealed record SyncSessionState(Guid SessionId, Guid EventId, Guid ConductorUserId, Guid? CurrentPieceId, string? CurrentPieceTitle, DateTimeOffset? CurrentSinceUtc, bool Active);

public sealed class ConductorSyncService(SheetstormDbContext db, IHubContext<ConductorSyncHub> hub)
{
    public async Task<SyncSessionState> StartAsync(Guid eventId, Guid conductorUserId, CancellationToken ct = default)
    {
        var existing = await db.EventSyncSessions
            .Where(s => s.EventId == eventId && s.EndedAt == null)
            .FirstOrDefaultAsync(ct);
        if (existing is not null) return Map(existing);

        var s = EventSyncSession.Start(eventId, conductorUserId);
        db.EventSyncSessions.Add(s);
        await db.SaveChangesAsync(ct);
        return Map(s);
    }

    public async Task<SyncSessionState?> GetActiveAsync(Guid eventId, CancellationToken ct = default)
    {
        var s = await db.EventSyncSessions
            .Where(x => x.EventId == eventId && x.EndedAt == null)
            .OrderByDescending(x => x.StartedAt)
            .FirstOrDefaultAsync(ct);
        return s is null ? null : Map(s);
    }

    public async Task<SyncSessionState?> OpenPieceAsync(Guid eventId, Guid pieceId, string title, CancellationToken ct = default)
    {
        var s = await db.EventSyncSessions
            .Where(x => x.EventId == eventId && x.EndedAt == null)
            .OrderByDescending(x => x.StartedAt)
            .FirstOrDefaultAsync(ct);
        if (s is null) return null;
        s.OpenPiece(pieceId, title);
        await db.SaveChangesAsync(ct);

        await hub.Clients.Group($"event-{eventId}")
            .SendAsync("NowPlayingChanged", new NowPlayingPayload(eventId, pieceId, title, s.CurrentSinceUtc!.Value), ct);
        return Map(s);
    }

    public async Task StopAsync(Guid eventId, CancellationToken ct = default)
    {
        var s = await db.EventSyncSessions
            .Where(x => x.EventId == eventId && x.EndedAt == null)
            .FirstOrDefaultAsync(ct);
        if (s is null) return;
        s.Stop();
        await db.SaveChangesAsync(ct);
        await hub.Clients.Group($"event-{eventId}").SendAsync("SessionStopped", eventId, ct);
    }

    private static SyncSessionState Map(EventSyncSession s)
        => new(s.Id, s.EventId, s.ConductorUserId,
            s.CurrentPieceId is null ? null : Guid.Parse(s.CurrentPieceId),
            s.CurrentPieceTitle, s.CurrentSinceUtc, s.EndedAt is null);
}
