using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Kapellenverwaltung;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.KapelleManagement;

public class KapelleService(AppDbContext db) : IKapelleService
{
    private static readonly char[] CodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray();

    public async Task<IReadOnlyList<KapelleDto>> GetMeineKapellenAsync(Guid musikerId)
    {
        return await db.Mitgliedschaften
            .Where(m => m.MusikerID == musikerId && m.IstAktiv)
            .Select(m => new KapelleDto(
                m.Kapelle.Id,
                m.Kapelle.Name,
                m.Kapelle.Beschreibung,
                m.Kapelle.Ort,
                m.Kapelle.Mitglieder.Count(mm => mm.IstAktiv),
                m.Rolle,
                m.Kapelle.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<KapelleDetailDto> GetKapelleAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var kapelle = await db.Kapellen
            .Include(k => k.Mitglieder.Where(m => m.IstAktiv))
            .ThenInclude(m => m.Musiker)
            .FirstOrDefaultAsync(k => k.Id == kapelleId)
            ?? throw new AuthException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden.", 404);

        var mitglieder = kapelle.Mitglieder
            .Select(m => new MitgliedDto(
                m.MusikerID,
                m.Musiker.Name,
                m.Musiker.Email,
                m.Musiker.Instrument,
                m.Rolle,
                m.CreatedAt
            ))
            .ToList();

        return new KapelleDetailDto(
            kapelle.Id,
            kapelle.Name,
            kapelle.Beschreibung,
            kapelle.Ort,
            mitglieder,
            kapelle.CreatedAt
        );
    }

    public async Task<KapelleDto> KapelleErstellenAsync(KapelleErstellenRequest request, Guid musikerId)
    {
        var kapelle = new Kapelle
        {
            Name = request.Name.Trim(),
            Beschreibung = request.Beschreibung?.Trim(),
            Ort = request.Ort?.Trim()
        };

        db.Kapellen.Add(kapelle);

        db.Mitgliedschaften.Add(new Mitgliedschaft
        {
            KapelleID = kapelle.Id,
            MusikerID = musikerId,
            Rolle = MitgliedRolle.Administrator,
            IstAktiv = true
        });

        await db.SaveChangesAsync();

        return new KapelleDto(
            kapelle.Id,
            kapelle.Name,
            kapelle.Beschreibung,
            kapelle.Ort,
            1,
            MitgliedRolle.Administrator,
            kapelle.CreatedAt
        );
    }

    public async Task<KapelleDto> KapelleBearbeitenAsync(
        Guid kapelleId,
        KapelleBearbeitenRequest request,
        Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var kapelle = await db.Kapellen.FindAsync(kapelleId)
            ?? throw new AuthException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden.", 404);

        kapelle.Name = request.Name.Trim();
        kapelle.Beschreibung = request.Beschreibung?.Trim();
        kapelle.Ort = request.Ort?.Trim();

        await db.SaveChangesAsync();

        var mitgliederAnzahl = await db.Mitgliedschaften
            .CountAsync(m => m.KapelleID == kapelleId && m.IstAktiv);

        return new KapelleDto(
            kapelle.Id,
            kapelle.Name,
            kapelle.Beschreibung,
            kapelle.Ort,
            mitgliederAnzahl,
            MitgliedRolle.Administrator,
            kapelle.CreatedAt
        );
    }

    public async Task KapelleLoeschenAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var kapelle = await db.Kapellen.FindAsync(kapelleId)
            ?? throw new AuthException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden.", 404);

        db.Kapellen.Remove(kapelle);
        await db.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<MitgliedDto>> GetMitgliederAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        return await db.Mitgliedschaften
            .Where(m => m.KapelleID == kapelleId && m.IstAktiv)
            .Select(m => new MitgliedDto(
                m.MusikerID,
                m.Musiker.Name,
                m.Musiker.Email,
                m.Musiker.Instrument,
                m.Rolle,
                m.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<EinladungDto> EinladungErstellenAsync(
        Guid kapelleId,
        EinladungErstellenRequest request,
        Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var code = GenerateCode();
        var expiresAt = DateTime.UtcNow.AddDays(request.GueltigkeitTage);

        db.Einladungen.Add(new Einladung
        {
            Code = code,
            KapelleID = kapelleId,
            VorgeseheRolle = request.Rolle,
            ExpiresAt = expiresAt,
            ErstelltVonMusikerID = musikerId
        });

        await db.SaveChangesAsync();

        return new EinladungDto(code, request.Rolle, expiresAt);
    }

    public async Task<KapelleDto> BeitretenAsync(BeitretenRequest request, Guid musikerId)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var now = DateTime.UtcNow;

        var einladung = await db.Einladungen
            .Include(e => e.Kapelle)
            .FirstOrDefaultAsync(e => e.Code == code)
            ?? throw new AuthException("INVALID_CODE", "Ungültiger oder abgelaufener Einladungscode.", 400);

        if (einladung.IsUsed)
            throw new AuthException("CODE_ALREADY_USED", "Dieser Einladungscode wurde bereits verwendet.", 400);

        if (einladung.ExpiresAt < now)
            throw new AuthException("CODE_EXPIRED", "Der Einladungscode ist abgelaufen.", 400);

        var existing = await db.Mitgliedschaften
            .FirstOrDefaultAsync(m => m.KapelleID == einladung.KapelleID && m.MusikerID == musikerId);

        if (existing is { IstAktiv: true })
            throw new AuthException("ALREADY_MEMBER", "Du bist bereits Mitglied dieser Kapelle.", 409);

        if (existing is not null)
        {
            // Re-activate a former member
            existing.IstAktiv = true;
            existing.Rolle = einladung.VorgeseheRolle;
        }
        else
        {
            db.Mitgliedschaften.Add(new Mitgliedschaft
            {
                KapelleID = einladung.KapelleID,
                MusikerID = musikerId,
                Rolle = einladung.VorgeseheRolle,
                IstAktiv = true
            });
        }

        einladung.IsUsed = true;
        einladung.EingeloestVonMusikerID = musikerId;

        await db.SaveChangesAsync();

        var mitgliederAnzahl = await db.Mitgliedschaften
            .CountAsync(m => m.KapelleID == einladung.KapelleID && m.IstAktiv);

        return new KapelleDto(
            einladung.Kapelle.Id,
            einladung.Kapelle.Name,
            einladung.Kapelle.Beschreibung,
            einladung.Kapelle.Ort,
            mitgliederAnzahl,
            einladung.VorgeseheRolle,
            einladung.Kapelle.CreatedAt
        );
    }

    public async Task RolleAendernAsync(
        Guid kapelleId,
        Guid userId,
        RolleAendernRequest request,
        Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        if (userId == musikerId)
            throw new AuthException("CANNOT_CHANGE_OWN_ROLE", "Du kannst deine eigene Rolle nicht ändern.", 400);

        var mitgliedschaft = await db.Mitgliedschaften
            .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == userId && m.IstAktiv)
            ?? throw new AuthException("MEMBER_NOT_FOUND", "Mitglied nicht gefunden.", 404);

        mitgliedschaft.Rolle = request.Rolle;
        await db.SaveChangesAsync();
    }

    public async Task MitgliedEntfernenAsync(Guid kapelleId, Guid userId, Guid musikerId)
    {
        var requester = await db.Mitgliedschaften
            .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == musikerId && m.IstAktiv)
            ?? throw new AuthException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden oder kein Zugriff.", 404);

        // Only admins can remove others; any member can remove themselves (leave)
        if (userId != musikerId && requester.Rolle != MitgliedRolle.Administrator)
            throw new AuthException("FORBIDDEN", "Nur Admins dürfen Mitglieder entfernen.", 403);

        // Prevent the last admin from leaving
        if (userId == musikerId && requester.Rolle == MitgliedRolle.Administrator)
        {
            var adminCount = await db.Mitgliedschaften
                .CountAsync(m => m.KapelleID == kapelleId && m.IstAktiv && m.Rolle == MitgliedRolle.Administrator);
            if (adminCount <= 1)
                throw new AuthException(
                    "LAST_ADMIN",
                    "Der letzte Admin kann die Kapelle nicht verlassen. Ernenne zuerst einen anderen Admin.",
                    400);
        }

        var target = userId == musikerId
            ? requester
            : await db.Mitgliedschaften
                .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == userId && m.IstAktiv)
                ?? throw new AuthException("MEMBER_NOT_FOUND", "Mitglied nicht gefunden.", 404);

        target.IstAktiv = false;
        await db.SaveChangesAsync();
    }

    // ── Stimmen-Mapping ───────────────────────────────────────────────────────

    public async Task<StimmenMappingResponse> GetStimmenMappingAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var eintraege = await db.KapelleStimmenMappings
            .Where(m => m.KapelleId == kapelleId)
            .OrderBy(m => m.Instrument)
            .Select(m => new StimmenMappingEintrag(m.Instrument, m.Stimme))
            .ToListAsync();

        return new StimmenMappingResponse(eintraege);
    }

    public async Task<StimmenMappingResponse> SetStimmenMappingAsync(
        Guid kapelleId,
        StimmenMappingSetzenRequest request,
        Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        // Replace all existing mappings for this Kapelle atomically
        var existing = await db.KapelleStimmenMappings
            .Where(m => m.KapelleId == kapelleId)
            .ToListAsync();
        db.KapelleStimmenMappings.RemoveRange(existing);

        var newMappings = request.Eintraege.Select(e => new KapelleStimmenMapping
        {
            KapelleId = kapelleId,
            Instrument = e.Instrument.Trim(),
            Stimme = e.Stimme.Trim()
        }).ToList();
        db.KapelleStimmenMappings.AddRange(newMappings);

        await db.SaveChangesAsync();

        return new StimmenMappingResponse(
            newMappings.OrderBy(m => m.Instrument)
                .Select(m => new StimmenMappingEintrag(m.Instrument, m.Stimme))
                .ToList());
    }

    public async Task SetNutzerStimmenAsync(
        Guid kapelleId,
        Guid userId,
        NutzerStimmenRequest request,
        Guid musikerId)
    {
        // Admins may set any member's override; members may only set their own
        var requester = await RequireMitgliedschaftAsync(kapelleId, musikerId);

        if (userId != musikerId && requester.Rolle != MitgliedRolle.Administrator)
            throw new AuthException("FORBIDDEN", "Nur Admins dürfen die Stimme anderer Mitglieder setzen.", 403);

        var target = userId == musikerId
            ? requester
            : await db.Mitgliedschaften
                .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == userId && m.IstAktiv)
                ?? throw new AuthException("MEMBER_NOT_FOUND", "Mitglied nicht gefunden.", 404);

        target.StimmenOverride = string.IsNullOrWhiteSpace(request.StimmenOverride)
            ? null
            : request.StimmenOverride.Trim();

        await db.SaveChangesAsync();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<Mitgliedschaft> RequireMitgliedschaftAsync(Guid kapelleId, Guid musikerId)
    {
        var m = await db.Mitgliedschaften
            .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == musikerId && m.IstAktiv);

        return m ?? throw new AuthException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden oder kein Zugriff.", 404);
    }

    private async Task<Mitgliedschaft> RequireAdminAsync(Guid kapelleId, Guid musikerId)
    {
        var m = await RequireMitgliedschaftAsync(kapelleId, musikerId);

        if (m.Rolle != MitgliedRolle.Administrator)
            throw new AuthException("FORBIDDEN", "Nur Admins dürfen diese Aktion ausführen.", 403);

        return m;
    }

    private static string GenerateCode()
    {
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        return new string(bytes.Select(b => CodeChars[b % CodeChars.Length]).ToArray());
    }
}
