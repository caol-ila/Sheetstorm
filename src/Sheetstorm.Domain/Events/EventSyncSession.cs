namespace Sheetstorm.Domain.Events;

public sealed class EventSyncSession
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public Event Event { get; private set; } = default!;
    public Guid ConductorUserId { get; private set; }
    public string? CurrentPieceId { get; private set; }
    public string? CurrentPieceTitle { get; private set; }
    /// <summary>Ed25519 Public Key des Dirigenten-Geräts, Base64-kodiert (32 Bytes raw → 44 chars).</summary>
    public string? PublicKeyBase64 { get; private set; }
    public DateTimeOffset StartedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? EndedAt { get; private set; }
    public DateTimeOffset? CurrentSinceUtc { get; private set; }
    public long CurrentCounter { get; private set; }

    private EventSyncSession() { }

    public static EventSyncSession Start(Guid eventId, Guid conductorUserId)
        => new() { EventId = eventId, ConductorUserId = conductorUserId };

    public void RegisterPublicKey(string publicKeyBase64)
    {
        if (string.IsNullOrWhiteSpace(publicKeyBase64)) throw new ArgumentException("PublicKey ist Pflicht");
        PublicKeyBase64 = publicKeyBase64;
    }

    public void OpenPiece(Guid pieceId, string title, long counter)
    {
        CurrentPieceId = pieceId.ToString();
        CurrentPieceTitle = title;
        CurrentSinceUtc = DateTimeOffset.UtcNow;
        if (counter > CurrentCounter) CurrentCounter = counter;
    }

    public void Stop()
    {
        EndedAt = DateTimeOffset.UtcNow;
        CurrentPieceId = null;
        CurrentPieceTitle = null;
    }
}

