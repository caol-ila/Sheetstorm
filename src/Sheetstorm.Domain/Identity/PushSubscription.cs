namespace Sheetstorm.Domain.Identity;

/// <summary>
/// Web-Push-Subscription eines User-Geräts. Speichert die Endpoint-URL
/// und die public/auth-Keys, die der Browser bei pushManager.subscribe()
/// liefert.
/// </summary>
public sealed class PushSubscription
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid UserId { get; private set; }
    public string Endpoint { get; private set; } = default!;
    public string P256dhKey { get; private set; } = default!;
    public string AuthKey { get; private set; } = default!;
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LastUsedAt { get; private set; }

    private PushSubscription() { }

    public static PushSubscription Create(Guid userId, string endpoint, string p256dh, string auth)
        => new() { UserId = userId, Endpoint = endpoint, P256dhKey = p256dh, AuthKey = auth };

    public void Touch() => LastUsedAt = DateTimeOffset.UtcNow;
}
