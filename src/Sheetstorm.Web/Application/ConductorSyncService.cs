using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Hubs;

namespace Sheetstorm.Web.Application;

public sealed record SyncSessionState(
    Guid SessionId,
    Guid EventId,
    Guid ConductorUserId,
    Guid? CurrentPieceId,
    string? CurrentPieceTitle,
    DateTimeOffset? CurrentSinceUtc,
    long CurrentCounter,
    string? PublicKeyBase64,
    bool Active);

public sealed record OpenPieceRequest(Guid PieceId, string Title, long Counter);

public sealed class ConductorSyncService(SheetstormDbContext db, IHubContext<ConductorSyncHub> hub)
{
    public async Task<SyncSessionState> StartAsync(Guid eventId, Guid conductorUserId, string? publicKeyBase64 = null, CancellationToken ct = default)
    {
        var existing = await db.EventSyncSessions
            .Where(s => s.EventId == eventId && s.EndedAt == null)
            .FirstOrDefaultAsync(ct);
        if (existing is not null)
        {
            if (publicKeyBase64 is not null && existing.PublicKeyBase64 != publicKeyBase64)
            {
                existing.RegisterPublicKey(publicKeyBase64);
                await db.SaveChangesAsync(ct);
            }
            return Map(existing);
        }

        var s = EventSyncSession.Start(eventId, conductorUserId);
        if (publicKeyBase64 is not null) s.RegisterPublicKey(publicKeyBase64);
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

    public async Task<SyncSessionState?> OpenPieceAsync(Guid eventId, Guid pieceId, string title, long counter = 0, CancellationToken ct = default)
    {
        var s = await db.EventSyncSessions
            .Where(x => x.EventId == eventId && x.EndedAt == null)
            .OrderByDescending(x => x.StartedAt)
            .FirstOrDefaultAsync(ct);
        if (s is null) return null;
        var actualCounter = counter > 0 ? counter : s.CurrentCounter + 1;
        s.OpenPiece(pieceId, title, actualCounter);
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
            s.CurrentPieceTitle, s.CurrentSinceUtc, s.CurrentCounter, s.PublicKeyBase64, s.EndedAt is null);
}
