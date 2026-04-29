using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Infrastructure.Persistence;
using WebPush;

namespace Sheetstorm.Web.Application;

public sealed class VapidOptions
{
    public string Subject { get; set; } = "mailto:noreply@sheetstorm.local";
    public string PublicKey { get; set; } = "";
    public string PrivateKey { get; set; } = "";
}

/// <summary>
/// Versendet Web-Push-Notifications via VAPID. Beim Start werden Schlüssel
/// aus IOptions gelesen; falls leer, wird einmalig ein Paar generiert
/// und in den Logs ausgegeben (für Dev-Setup).
/// </summary>
public sealed class PushNotificationService(
    SheetstormDbContext db,
    IOptions<VapidOptions> options,
    ILogger<PushNotificationService> log)
{
    private readonly VapidOptions _opt = options.Value;

    public string? PublicKey => string.IsNullOrEmpty(_opt.PublicKey) ? null : _opt.PublicKey;

    public bool IsConfigured => !string.IsNullOrEmpty(_opt.PublicKey) && !string.IsNullOrEmpty(_opt.PrivateKey);

    public async Task SendToUserAsync(Guid userId, string title, string body, string? url = null, CancellationToken ct = default)
    {
        if (!IsConfigured)
        {
            log.LogWarning("VAPID nicht konfiguriert — Push wird nicht gesendet.");
            return;
        }

        var subs = await db.PushSubscriptions.Where(p => p.UserId == userId).ToListAsync(ct);
        if (subs.Count == 0) return;

        var client = new WebPushClient();
        var vapid = new VapidDetails(_opt.Subject, _opt.PublicKey, _opt.PrivateKey);
        var payload = System.Text.Json.JsonSerializer.Serialize(new { title, body, url });

        foreach (var sub in subs)
        {
            try
            {
                var pushSub = new global::WebPush.PushSubscription(sub.Endpoint, sub.P256dhKey, sub.AuthKey);
                await client.SendNotificationAsync(pushSub, payload, vapid);
                sub.Touch();
            }
            catch (WebPushException ex) when (ex.StatusCode == System.Net.HttpStatusCode.Gone || ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                log.LogInformation("Subscription {Id} ist tot, entferne", sub.Id);
                db.PushSubscriptions.Remove(sub);
            }
            catch (Exception ex)
            {
                log.LogWarning(ex, "Push an {Endpoint} fehlgeschlagen", sub.Endpoint);
            }
        }
        await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// Gibt einen Helfer-Text aus, falls VAPID nicht konfiguriert ist.
    /// </summary>
    public static (string PublicKey, string PrivateKey) GenerateKeys()
    {
        var keys = VapidHelper.GenerateVapidKeys();
        return (keys.PublicKey, keys.PrivateKey);
    }
}

/// <summary>
/// Hintergrund-Worker, der täglich Erinnerungen für am nächsten Tag startende
/// Termine an alle Mitglieder verschickt.
/// </summary>
public sealed class EventReminderWorker(IServiceScopeFactory scopes, ILogger<EventReminderWorker> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Beim Start einmal warten, dann alle 6h prüfen (Idempotenz via Annotation am Termin könnte später hinzu)
        await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<SheetstormDbContext>();
                var push = scope.ServiceProvider.GetRequiredService<PushNotificationService>();
                if (!push.IsConfigured) { await Task.Delay(TimeSpan.FromHours(6), stoppingToken); continue; }

                var from = DateTimeOffset.UtcNow;
                var to = from.AddHours(28); // Termine die in 24-28h starten -> 1-Tag-Erinnerung
                var due = await db.Events
                    .Where(e => !e.Cancelled && e.StartUtc >= from.AddHours(20) && e.StartUtc <= to)
                    .ToListAsync(stoppingToken);
                foreach (var ev in due)
                {
                    var members = await db.Memberships.Where(m => m.BandId == ev.BandId).Select(m => m.UserId).ToListAsync(stoppingToken);
                    foreach (var uid in members)
                    {
                        await push.SendToUserAsync(uid,
                            $"Erinnerung: {ev.Title}",
                            $"Morgen {ev.StartUtc.LocalDateTime:HH:mm} {(ev.Location is null ? "" : "@" + ev.Location)}",
                            $"/Bands/_/events", stoppingToken);
                    }
                }
            }
            catch (Exception ex)
            {
                log.LogWarning(ex, "EventReminder-Fehler");
            }
            try { await Task.Delay(TimeSpan.FromHours(6), stoppingToken); } catch { }
        }
    }
}
