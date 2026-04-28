namespace Sheetstorm.Domain.Music;

/// <summary>
/// Markierung eines Users, dass ein Werk offline verfügbar sein soll.
/// Die App lädt dann beim nächsten Online-Sync alle PartFiles in den Browser-Cache.
/// </summary>
public sealed class OfflineWish
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid UserId { get; private set; }
    public Guid PieceId { get; private set; }
    public DateTimeOffset MarkedAt { get; private set; } = DateTimeOffset.UtcNow;

    private OfflineWish() { }

    public static OfflineWish Create(Guid userId, Guid pieceId)
        => new() { UserId = userId, PieceId = pieceId };
}
