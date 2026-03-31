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

        Musician musician;
        if (await db.Musicians.AnyAsync(m => m.Email == DemoEmail))
        {
            logger.LogInformation("Demo-User '{Email}' existiert bereits. Übersprungen.", DemoEmail);
            musician = await db.Musicians.FirstAsync(m => m.Email == DemoEmail);
        }
        else
        {
            musician = new Musician
            {
                Name = DemoDisplayName,
                Email = DemoEmail,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(DemoPassword),
                EmailVerified = true,
                OnboardingCompleted = true
            };

            db.Musicians.Add(musician);
            await db.SaveChangesAsync();

            logger.LogInformation("Demo-User '{Email}' (Passwort: '{Password}') erfolgreich erstellt.", DemoEmail, DemoPassword);
        }

        // Seed a demo band so the import workflow works out of the box
        if (!await db.Bands.AnyAsync())
        {
            var band = new Band
            {
                Name = "Demo Kapelle",
                Description = "Demo-Kapelle für lokale Entwicklung",
                Location = "Teststadt"
            };
            db.Bands.Add(band);
            await db.SaveChangesAsync();

            var membership = new Membership
            {
                BandId = band.Id,
                MusicianId = musician.Id,
                Role = MemberRole.Administrator,
                IsActive = true
            };
            db.Memberships.Add(membership);
            await db.SaveChangesAsync();

            logger.LogInformation("Demo-Kapelle '{Name}' mit Admin-Mitgliedschaft erstellt.", band.Name);
        }
    }
}
