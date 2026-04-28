using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Domain.Music;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web;

/// <summary>
/// Erstellt Demo-Vereine, -Accounts und -Werke für Development.
/// Passwort für alle Demo-User: "demo".
/// </summary>
public static class DemoSeed
{
    public const string DemoPassword = "demo";

    private static readonly Guid DemoBandId = new("dddd0001-0000-0000-0000-000000000001");

    private static readonly (string Email, string Display, BandRole Roles, Guid? PreferredInstrumentId)[] DemoUsers =
    {
        ("dirigent@demo.local", "Thomas Dirigent",
            BandRole.Mitglied | BandRole.Dirigent | BandRole.Admin | BandRole.Owner,
            null),
        ("admin@demo.local", "Andrea Admin",
            BandRole.Mitglied | BandRole.Admin,
            null),
        ("maria@demo.local", "Maria Klarinette",
            BandRole.Mitglied,
            new Guid("11111111-0005-0000-0000-000000000002")), // Klarinette in B
        ("peter@demo.local", "Peter Trompete",
            BandRole.Mitglied,
            new Guid("22222222-0001-0000-0000-000000000001")), // Trompete in B
        ("schorsch@demo.local", "Schorsch Schlagzeuger",
            BandRole.Mitglied,
            new Guid("33333333-0001-0000-0000-000000000001")), // Schlagzeug-Set
    };

    public static async Task RunAsync(
        SheetstormDbContext db,
        UserManager<ApplicationUser> userManager,
        LocalFileStore fileStore,
        ILogger logger,
        CancellationToken ct = default)
    {
        // Idempotent: nur seeden wenn Demo-Verein noch nicht existiert
        if (await db.Bands.AnyAsync(b => b.Id == DemoBandId, ct))
        {
            logger.LogInformation("Demo-Daten bereits vorhanden, überspringe Seed.");
            return;
        }

        logger.LogInformation("Erstelle Demo-Daten…");

        // 1. Users anlegen
        var userIds = new Dictionary<string, Guid>();
        foreach (var (email, display, _, _) in DemoUsers)
        {
            var existing = await userManager.FindByEmailAsync(email);
            if (existing is not null)
            {
                userIds[email] = existing.Id;
                continue;
            }
            var user = new ApplicationUser
            {
                UserName = email,
                Email = email,
                EmailConfirmed = true,
                DisplayName = display,
            };
            var result = await userManager.CreateAsync(user, DemoPassword);
            if (!result.Succeeded)
            {
                logger.LogError("Konnte Demo-User {Email} nicht anlegen: {Errors}",
                    email, string.Join(", ", result.Errors.Select(e => e.Description)));
                return;
            }
            userIds[email] = user.Id;
        }

        // 2. Demo-Verein
        var ownerId = userIds["dirigent@demo.local"];
        var band = Band.Create("Musikverein Demo", "demo", ownerId, "Demo-Verein zum Ausprobieren");
        // Reflection-frei: BandId per privatem Setter geht nicht — wir nehmen die generierte Id.
        // Damit der Demo-Verein einen festen Slug hat, reicht das. Die DemoBandId-Konstante dient
        // primär dem Idempotenz-Check oben — wir prüfen über Slug auch:
        if (await db.Bands.AnyAsync(b => b.Slug == "demo", ct))
        {
            logger.LogInformation("Demo-Verein 'demo' existiert bereits, breche ab.");
            return;
        }
        // Setze Demo-Id über Backing-Field-Trick: einfacher Workaround via SaveChanges + Update der Id ist heikel.
        // Stattdessen: Band einfach speichern und die generierte Id für Membership/Pieces nutzen.
        db.Bands.Add(band);
        await db.SaveChangesAsync(ct);

        // 3. Mitgliedschaften
        foreach (var (email, _, roles, prefInstrument) in DemoUsers)
        {
            var membership = Membership.Create(band.Id, userIds[email], roles);
            db.Memberships.Add(membership);
            if (prefInstrument is not null)
            {
                var instr = await db.Instruments.FirstOrDefaultAsync(i => i.Id == prefInstrument, ct);
                if (instr is not null)
                {
                    db.MembershipInstruments.Add(MembershipInstrument.Create(
                        membership.Id, instr.Id, instr.DefaultTransposition, 0, isPrimary: true));
                }
            }
        }
        await db.SaveChangesAsync(ct);

        // 4. Demo-Werke mit jeweils 3 Stimmen + winzigem PDF
        var instruments = await db.Instruments.ToDictionaryAsync(i => i.Id, ct);
        var partFamilies = new[]
        {
            (new Guid("11111111-0005-0000-0000-000000000002"), "Klarinette 1 in B", "B"),
            (new Guid("22222222-0001-0000-0000-000000000001"), "Trompete 1 in B", "B"),
            (new Guid("33333333-0001-0000-0000-000000000001"), "Schlagzeug-Set", null),
        };

        var demoWorks = new[]
        {
            ("Marsch der Bayerischen Volkspartei", "Anonym", "Marsch", 3),
            ("Florentiner Marsch", "Julius Fučík", "Marsch", 4),
            ("Festliche Eröffnung", "Hermann Pallhuber", "Konzert", 5),
        };

        var pdfBytes = MakeTinyPdf();

        foreach (var (title, composer, genre, difficulty) in demoWorks)
        {
            var piece = Piece.Create(band.Id, title);
            piece.UpdateMetadata(title, null, composer, null, null, null, null, null, null, null, difficulty, genre, null, null);
            db.Pieces.Add(piece);
            await db.SaveChangesAsync(ct);

            foreach (var (instrumentId, displayName, transposition) in partFamilies)
            {
                var part = Part.Create(piece.Id, instrumentId, displayName, transposition);
                db.Parts.Add(part);
                await db.SaveChangesAsync(ct);

                using var ms = new MemoryStream(pdfBytes);
                var blobKey = await fileStore.SaveAsync(ms, $"parts/{part.Id}", $"{title}-{displayName}.pdf", ct);
                db.PartFiles.Add(PartFile.Create(part.Id, PartFileKind.Pdf, blobKey,
                    $"{title} - {displayName}.pdf", pdfBytes.Length));
            }
            await db.SaveChangesAsync(ct);
        }

        logger.LogInformation("Demo-Daten angelegt: Verein 'demo', {UserCount} User, 3 Werke mit je 3 Stimmen.",
            DemoUsers.Length);
    }

    private static byte[] MakeTinyPdf()
    {
        // Minimales valides PDF mit "Demo" als Inhalt
        const string pdf =
            "%PDF-1.4\n" +
            "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n" +
            "2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n" +
            "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]/Resources<<>>/Contents 4 0 R>>endobj\n" +
            "4 0 obj<</Length 38>>stream\nBT /F1 12 Tf 50 100 Td (Demo Stimme) Tj ET\nendstream\nendobj\n" +
            "xref\n0 5\n0000000000 65535 f\n0000000010 00000 n\n0000000053 00000 n\n0000000100 00000 n\n0000000175 00000 n\n" +
            "trailer<</Size 5/Root 1 0 R>>\nstartxref\n245\n%%EOF";
        return System.Text.Encoding.ASCII.GetBytes(pdf);
    }
}
