using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Seeding;

/// <summary>
/// Seeds a demo user for local development testing.
/// Only runs in Development environment — never in Production.
/// </summary>
public class DemoDataSeeder(AppDbContext db, IHostEnvironment env, ILogger<DemoDataSeeder> logger)
{
    private const string DemoEmail = "demo@test.local";
    private const string DemoPassword = "demo";
    private const string DemoDisplayName = "Demo User";

    public async Task SeedAsync()
    {
        if (!env.IsDevelopment())
        {
            logger.LogWarning("DemoDataSeeder wird nur im Development-Modus ausgeführt. Übersprungen.");
            return;
        }

        if (await db.Musicians.AnyAsync(m => m.Email == DemoEmail))
        {
            logger.LogInformation("Demo-User '{Email}' existiert bereits. Übersprungen.", DemoEmail);
            return;
        }

        var musician = new Musician
        {
            Name = DemoDisplayName,
            Email = DemoEmail,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(DemoPassword),
            EmailVerified = true,
            OnboardingCompleted = false
        };

        db.Musicians.Add(musician);
        await db.SaveChangesAsync();

        logger.LogInformation("Demo-User '{Email}' (Passwort: '{Password}') erfolgreich erstellt.", DemoEmail, DemoPassword);
    }
}
