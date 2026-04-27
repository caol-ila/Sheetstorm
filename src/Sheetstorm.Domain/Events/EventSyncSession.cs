namespace Sheetstorm.Domain.Events;

public sealed class EventSyncSession
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public Event Event { get; private set; } = default!;
    public Guid ConductorUserId { get; private set; }
    public string? CurrentPieceId { get; private set; } // GUID-String oder null
    public string? CurrentPieceTitle { get; private set; }
    public DateTimeOffset StartedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? EndedAt { get; private set; }
    public DateTimeOffset? CurrentSinceUtc { get; private set; }

    private EventSyncSession() { }

    public static EventSyncSession Start(Guid eventId, Guid conductorUserId)
        => new() { EventId = eventId, ConductorUserId = conductorUserId };

    public void OpenPiece(Guid pieceId, string title)
    {
        CurrentPieceId = pieceId.ToString();
        CurrentPieceTitle = title;
        CurrentSinceUtc = DateTimeOffset.UtcNow;
    }

    public void Stop()
    {
        EndedAt = DateTimeOffset.UtcNow;
        CurrentPieceId = null;
        CurrentPieceTitle = null;
    }
}
