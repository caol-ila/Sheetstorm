using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Stimmen;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Stimmen;

public partial class StimmenService(AppDbContext db) : IStimmenService
{
    // ── Public API ──────────────────────────────────────────────────────────

    public async Task<StimmenListeResponse> GetStimmenAsync(Guid stueckId, Guid musikerId)
    {
        var stueck = await db.Stuecke
            .Include(s => s.Stimmen)
            .FirstOrDefaultAsync(s => s.Id == stueckId)
            ?? throw new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404);

        var stimmenDtos = stueck.Stimmen
            .OrderBy(s => s.StimmenNummer ?? int.MaxValue)
            .ThenBy(s => s.Bezeichnung)
            .Select(s => new StimmeDto(
                s.Id,
                s.Bezeichnung,
                s.InstrumentTyp,
                s.InstrumentFamilie,
                s.StimmenNummer,
                s.Notenblaetter.Count))
            .ToList();

        var fallback = await ResolveFallbackAsync(stueck.Stimmen.ToList(), musikerId, stueck.KapelleID);

        return new StimmenListeResponse(stueckId, stimmenDtos, fallback);
    }

    public async Task<ResolvedStimmeResponse> ResolveStimmeAsync(Guid stueckId, Guid musikerId)
    {
        var stueck = await db.Stuecke
            .Include(s => s.Stimmen)
            .FirstOrDefaultAsync(s => s.Id == stueckId)
            ?? throw new DomainException("STUECK_NOT_FOUND", "Stück nicht gefunden.", 404);

        var fallback = await ResolveFallbackAsync(stueck.Stimmen.ToList(), musikerId, stueck.KapelleID);
        return new ResolvedStimmeResponse(stueckId, fallback);
    }

    public async Task<StimmenProfilResponse> GetStimmenProfilAsync(Guid musikerId)
    {
        var musiker = await db.Musiker.FindAsync(musikerId)
            ?? throw new DomainException("NUTZER_NOT_FOUND", "Nutzer nicht gefunden.", 404);

        var instrumente = await db.NutzerInstrumente
            .Where(ni => ni.MusikerID == musikerId)
            .Include(ni => ni.Vorauswahlen)
                .ThenInclude(v => v.Kapelle)
            .OrderBy(ni => ni.Sortierung)
            .ToListAsync();

        return MapToProfilResponse(musikerId, instrumente);
    }

    public async Task<StimmenProfilResponse> SetStimmenProfilAsync(Guid musikerId, StimmenProfilSetzenRequest request)
    {
        var musiker = await db.Musiker.FindAsync(musikerId)
            ?? throw new DomainException("NUTZER_NOT_FOUND", "Nutzer nicht gefunden.", 404);

        // Validate: all KapelleIds must be Kapellen the user belongs to
        var meineKapelleIds = await db.Mitgliedschaften
            .Where(m => m.MusikerID == musikerId && m.IstAktiv)
            .Select(m => m.KapelleID)
            .ToHashSetAsync();

        foreach (var instrument in request.Instrumente)
        {
            if (instrument.StandardStimmen is null) continue;
            foreach (var vorauswahl in instrument.StandardStimmen)
            {
                if (!meineKapelleIds.Contains(vorauswahl.KapelleId))
                    throw new DomainException("KAPELLE_NOT_MEMBER",
                        $"Du bist kein Mitglied der Kapelle {vorauswahl.KapelleId}.", 400);
            }
        }

        // Remove existing instruments + vorauswahlen (replace strategy)
        var existing = await db.NutzerInstrumente
            .Where(ni => ni.MusikerID == musikerId)
            .Include(ni => ni.Vorauswahlen)
            .ToListAsync();
        db.NutzerInstrumente.RemoveRange(existing);

        // Create new instruments
        var sortierung = 0;
        foreach (var eintrag in request.Instrumente)
        {
            var ni = new NutzerInstrument
            {
                MusikerID = musikerId,
                InstrumentTyp = eintrag.InstrumentTyp.ToLowerInvariant().Trim(),
                InstrumentBezeichnung = eintrag.InstrumentBezeichnung.Trim(),
                Sortierung = sortierung++,
            };

            if (eintrag.StandardStimmen is not null)
            {
                foreach (var v in eintrag.StandardStimmen)
                {
                    ni.Vorauswahlen.Add(new StimmeVorauswahl
                    {
                        MusikerID = musikerId,
                        KapelleID = v.KapelleId,
                        NutzerInstrumentID = ni.Id,
                        StimmeBezeichnung = v.StimmeBezeichnung.Trim(),
                    });
                }
            }

            db.NutzerInstrumente.Add(ni);
        }

        await db.SaveChangesAsync();

        // Return updated profile
        var updated = await db.NutzerInstrumente
            .Where(ni => ni.MusikerID == musikerId)
            .Include(ni => ni.Vorauswahlen)
                .ThenInclude(v => v.Kapelle)
            .OrderBy(ni => ni.Sortierung)
            .ToListAsync();

        return MapToProfilResponse(musikerId, updated);
    }

    // ── 6-Step Fallback Algorithm ───────────────────────────────────────────

    private async Task<StimmenFallbackResult> ResolveFallbackAsync(
        List<Stimme> stimmen, Guid musikerId, Guid? kapelleId)
    {
        // Step 6: no Stimmen at all
        if (stimmen.Count == 0)
            return new StimmenFallbackResult(null, null, null, "keine_stimmen");

        // Load the user's instrument profile + Kapelle-specific Vorauswahl
        var nutzerInstrumente = await db.NutzerInstrumente
            .Where(ni => ni.MusikerID == musikerId)
            .Include(ni => ni.Vorauswahlen)
            .OrderBy(ni => ni.Sortierung)
            .ToListAsync();

        // Also check: KapelleStimmenMapping (Kapelle-level override)
        KapelleStimmenMapping? kapelleMapping = null;
        if (kapelleId.HasValue && nutzerInstrumente.Count > 0)
        {
            var primaryInstrument = nutzerInstrumente[0].InstrumentTyp;
            kapelleMapping = await db.KapelleStimmenMappings
                .FirstOrDefaultAsync(m => m.KapelleId == kapelleId.Value
                    && m.Instrument.ToLower() == primaryInstrument);
        }

        // Also check Mitgliedschaft.StimmenOverride (user-level override)
        string? nutzerOverride = null;
        if (kapelleId.HasValue)
        {
            nutzerOverride = await db.Mitgliedschaften
                .Where(m => m.MusikerID == musikerId && m.KapelleID == kapelleId.Value && m.IstAktiv)
                .Select(m => m.StimmenOverride)
                .FirstOrDefaultAsync();
        }

        // Determine the target Stimme label to search for (3-level override: Nutzer > Kapelle > Profile)
        string? targetBezeichnung = null;
        string? targetInstrumentTyp = null;

        // Level 1: Nutzer override (from Mitgliedschaft.StimmenOverride)
        if (!string.IsNullOrWhiteSpace(nutzerOverride))
        {
            targetBezeichnung = nutzerOverride;
        }
        // Level 2: Kapelle mapping
        else if (kapelleMapping is not null)
        {
            targetBezeichnung = kapelleMapping.Stimme;
        }
        // Level 3: User profile Vorauswahl for this Kapelle + primary instrument
        else if (nutzerInstrumente.Count > 0)
        {
            if (kapelleId.HasValue)
            {
                // Find Vorauswahl for this Kapelle (any instrument, sorted by instrument priority)
                foreach (var ni in nutzerInstrumente)
                {
                    var vorauswahl = ni.Vorauswahlen
                        .FirstOrDefault(v => v.KapelleID == kapelleId.Value);
                    if (vorauswahl is not null)
                    {
                        targetBezeichnung = vorauswahl.StimmeBezeichnung;
                        targetInstrumentTyp = ni.InstrumentTyp;
                        break;
                    }
                }
            }

            // No Kapelle-specific vorauswahl — use primary instrument type
            targetInstrumentTyp ??= nutzerInstrumente[0].InstrumentTyp;
        }

        // If no instruments configured at all, fall through to step 5
        if (nutzerInstrumente.Count == 0 && string.IsNullOrWhiteSpace(targetBezeichnung))
            return FallbackSchritt5(stimmen);

        // ── Step 1: Exact match ─────────────────────────────────────────────
        if (!string.IsNullOrWhiteSpace(targetBezeichnung))
        {
            var normalized = NormalizeBezeichnung(targetBezeichnung);
            var match = stimmen.FirstOrDefault(s =>
                NormalizeBezeichnung(s.Bezeichnung) == normalized);

            if (match is not null)
                return new StimmenFallbackResult(match.Id, match.Bezeichnung, 1, null);
        }

        // ── Step 2: Same instrument family + lowest number ──────────────────
        targetInstrumentTyp ??= nutzerInstrumente.FirstOrDefault()?.InstrumentTyp;

        if (!string.IsNullOrWhiteSpace(targetInstrumentTyp))
        {
            var sameTyp = stimmen
                .Where(s => string.Equals(s.InstrumentTyp, targetInstrumentTyp, StringComparison.OrdinalIgnoreCase))
                .OrderBy(s => s.StimmenNummer ?? int.MaxValue)
                .ThenBy(s => s.Bezeichnung, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();

            if (sameTyp is not null)
                return new StimmenFallbackResult(sameTyp.Id, sameTyp.Bezeichnung, 2, "gleiche_familie_niedrigste_nr");
        }

        // ── Step 3: Generic match (instrument name without number) ──────────
        if (!string.IsNullOrWhiteSpace(targetInstrumentTyp))
        {
            var displayName = InstrumentTaxonomie.TypBezeichnung
                .GetValueOrDefault(targetInstrumentTyp, targetInstrumentTyp);
            var normalizedTyp = NormalizeBezeichnung(displayName);

            var generic = stimmen.FirstOrDefault(s =>
                NormalizeBezeichnung(s.Bezeichnung) == normalizedTyp);

            if (generic is not null)
                return new StimmenFallbackResult(generic.Id, generic.Bezeichnung, 3, "generisch_selbes_instrument");
        }

        // ── Step 4: Related family match ────────────────────────────────────
        if (!string.IsNullOrWhiteSpace(targetInstrumentTyp))
        {
            var familie = InstrumentTaxonomie.GetFamilie(targetInstrumentTyp);
            if (familie != InstrumentTaxonomie.FamilieSonstige)
            {
                var familyMatch = stimmen
                    .Where(s => string.Equals(s.InstrumentFamilie, familie, StringComparison.OrdinalIgnoreCase))
                    .OrderBy(s => s.InstrumentTyp is not null
                        ? InstrumentTaxonomie.GetPrioritaet(s.InstrumentTyp)
                        : int.MaxValue)
                    .ThenBy(s => s.StimmenNummer ?? int.MaxValue)
                    .ThenBy(s => s.Bezeichnung, StringComparer.OrdinalIgnoreCase)
                    .FirstOrDefault();

                if (familyMatch is not null)
                    return new StimmenFallbackResult(familyMatch.Id, familyMatch.Bezeichnung, 4, "verwandte_familie");
            }
        }

        // Also try other instruments in the user's profile (step 2-4 for secondary instruments)
        foreach (var ni in nutzerInstrumente.Skip(1))
        {
            var sameTyp = stimmen
                .Where(s => string.Equals(s.InstrumentTyp, ni.InstrumentTyp, StringComparison.OrdinalIgnoreCase))
                .OrderBy(s => s.StimmenNummer ?? int.MaxValue)
                .FirstOrDefault();

            if (sameTyp is not null)
                return new StimmenFallbackResult(sameTyp.Id, sameTyp.Bezeichnung, 4, "verwandte_familie");
        }

        // ── Step 5: First available Stimme ──────────────────────────────────
        return FallbackSchritt5(stimmen);
    }

    private static StimmenFallbackResult FallbackSchritt5(List<Stimme> stimmen)
    {
        var first = stimmen
            .OrderBy(s => s.StimmenNummer ?? int.MaxValue)
            .ThenBy(s => s.Bezeichnung, StringComparer.OrdinalIgnoreCase)
            .First();
        return new StimmenFallbackResult(first.Id, first.Bezeichnung, 5, "erste_verfuegbare");
    }

    // ── Normalization ───────────────────────────────────────────────────────

    /// <summary>
    /// Normalize a Stimme label for matching:
    /// - Trim, lowercase
    /// - Roman numeral → arabic (II → 2)
    /// - Common abbreviations (Klar. → Klarinette)
    /// - Strip ordinal dots ("2." → "2")
    /// </summary>
    internal static string NormalizeBezeichnung(string bezeichnung)
    {
        var s = bezeichnung.Trim().ToLowerInvariant();

        // Replace roman numerals with arabic
        s = RomanNumeralRegex().Replace(s, m => RomanToArabic(m.Value));

        // Normalize ordinal markers: "2." → "2", "zweite" → "2", "erste" → "1", "dritte" → "3"
        s = s.Replace("erste", "1").Replace("zweite", "2").Replace("dritte", "3")
             .Replace("vierte", "4").Replace("fünfte", "5");

        // Remove ordinal dot after number: "2." → "2"
        s = OrdinalDotRegex().Replace(s, "$1");

        // Expand abbreviations
        var parts = s.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        for (var i = 0; i < parts.Length; i++)
        {
            if (InstrumentTaxonomie.Abkuerzungen.TryGetValue(parts[i], out var expanded))
                parts[i] = expanded;
        }

        // Rejoin, collapse spaces
        return string.Join(' ', parts);
    }

    private static string RomanToArabic(string roman) => roman.Trim().ToUpperInvariant() switch
    {
        "I" => "1",
        "II" => "2",
        "III" => "3",
        "IV" => "4",
        "V" => "5",
        "VI" => "6",
        _ => roman
    };

    // Match standalone roman numerals (I, II, III, IV, V, VI)
    [GeneratedRegex(@"\b(VI|IV|V|III|II|I)\b", RegexOptions.IgnoreCase)]
    private static partial Regex RomanNumeralRegex();

    // Match "2." (number followed by dot) → just the number
    [GeneratedRegex(@"(\d+)\.", RegexOptions.None)]
    private static partial Regex OrdinalDotRegex();

    // ── Mapping helpers ─────────────────────────────────────────────────────

    private static StimmenProfilResponse MapToProfilResponse(Guid musikerId, List<NutzerInstrument> instrumente)
    {
        return new StimmenProfilResponse(
            musikerId,
            instrumente.Select(ni => new NutzerInstrumentDto(
                ni.Id,
                ni.InstrumentTyp,
                ni.InstrumentBezeichnung,
                ni.Sortierung,
                ni.Vorauswahlen.Select(v => new StimmeVorauswahlDto(
                    v.KapelleID,
                    v.Kapelle?.Name ?? "",
                    v.StimmeBezeichnung
                )).ToList()
            )).ToList()
        );
    }
}
