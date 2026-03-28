using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Voices;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Voices;

public partial class VoiceService(AppDbContext db) : IVoiceService
{
    // ── Public API ──────────────────────────────────────────────────────────

    public async Task<VoiceListResponse> GetVoicesAsync(Guid pieceId, Guid musicianId)
    {
        var piece = await db.Pieces
            .Include(s => s.Voices)
            .FirstOrDefaultAsync(s => s.Id == pieceId)
            ?? throw new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404);

        var voiceDtos = piece.Voices
            .OrderBy(s => s.VoiceNumber ?? int.MaxValue)
            .ThenBy(s => s.Label)
            .Select(s => new VoiceDto(
                s.Id,
                s.Label,
                s.InstrumentType,
                s.InstrumentFamily,
                s.VoiceNumber,
                s.SheetMusicFiles.Count))
            .ToList();

        var fallback = await ResolveFallbackAsync(piece.Voices.ToList(), musicianId, piece.BandId);

        return new VoiceListResponse(pieceId, voiceDtos, fallback);
    }

    public async Task<ResolvedVoiceResponse> ResolveVoiceAsync(Guid pieceId, Guid musicianId)
    {
        var piece = await db.Pieces
            .Include(s => s.Voices)
            .FirstOrDefaultAsync(s => s.Id == pieceId)
            ?? throw new DomainException("PIECE_NOT_FOUND", "Piece not found.", 404);

        var fallback = await ResolveFallbackAsync(piece.Voices.ToList(), musicianId, piece.BandId);
        return new ResolvedVoiceResponse(pieceId, fallback);
    }

    public async Task<VoiceProfileResponse> GetVoiceProfileAsync(Guid musicianId)
    {
        var musician = await db.Musicians.FindAsync(musicianId)
            ?? throw new DomainException("USER_NOT_FOUND", "User not found.", 404);

        var instruments = await db.UserInstruments
            .Where(ni => ni.MusicianId == musicianId)
            .Include(ni => ni.Preselections)
                .ThenInclude(v => v.Band)
            .OrderBy(ni => ni.SortOrder)
            .ToListAsync();

        return MapToProfileResponse(musicianId, instruments);
    }

    public async Task<VoiceProfileResponse> SetVoiceProfileAsync(Guid musicianId, SetVoiceProfileRequest request)
    {
        var musician = await db.Musicians.FindAsync(musicianId)
            ?? throw new DomainException("USER_NOT_FOUND", "User not found.", 404);

        // Validate: all BandIds must be bands the user belongs to
        var myBandIds = await db.Memberships
            .Where(m => m.MusicianId == musicianId && m.IsActive)
            .Select(m => m.BandId)
            .ToHashSetAsync();

        foreach (var instrument in request.Instruments)
        {
            if (instrument.DefaultVoices is null) continue;
            foreach (var preselection in instrument.DefaultVoices)
            {
                if (!myBandIds.Contains(preselection.BandId))
                    throw new DomainException("BAND_NOT_MEMBER",
                        $"You are not a member of band {preselection.BandId}.", 400);
            }
        }

        // Remove existing instruments + preselections (replace strategy)
        var existing = await db.UserInstruments
            .Where(ni => ni.MusicianId == musicianId)
            .Include(ni => ni.Preselections)
            .ToListAsync();
        db.UserInstruments.RemoveRange(existing);

        // Create new instruments
        var sortOrder = 0;
        foreach (var entry in request.Instruments)
        {
            var ni = new UserInstrument
            {
                MusicianId = musicianId,
                InstrumentType = entry.InstrumentType.ToLowerInvariant().Trim(),
                InstrumentLabel = entry.InstrumentLabel.Trim(),
                SortOrder = sortOrder++,
            };

            if (entry.DefaultVoices is not null)
            {
                foreach (var v in entry.DefaultVoices)
                {
                    ni.Preselections.Add(new VoicePreselection
                    {
                        MusicianId = musicianId,
                        BandId = v.BandId,
                        UserInstrumentID = ni.Id,
                        VoiceLabel = v.VoiceLabel.Trim(),
                    });
                }
            }

            db.UserInstruments.Add(ni);
        }

        await db.SaveChangesAsync();

        // Return updated profile
        var updated = await db.UserInstruments
            .Where(ni => ni.MusicianId == musicianId)
            .Include(ni => ni.Preselections)
                .ThenInclude(v => v.Band)
            .OrderBy(ni => ni.SortOrder)
            .ToListAsync();

        return MapToProfileResponse(musicianId, updated);
    }

    // ── 6-Step Fallback Algorithm ───────────────────────────────────────────

    private async Task<VoiceFallbackResult> ResolveFallbackAsync(
        List<Voice> voices, Guid musicianId, Guid? bandId)
    {
        // Step 6: no voices at all
        if (voices.Count == 0)
            return new VoiceFallbackResult(null, null, null, "no_voices");

        // Load the user's instrument profile + band-specific preselection
        var userInstruments = await db.UserInstruments
            .Where(ni => ni.MusicianId == musicianId)
            .Include(ni => ni.Preselections)
            .OrderBy(ni => ni.SortOrder)
            .ToListAsync();

        // Also check: BandVoiceMapping (band-level override)
        BandVoiceMapping? bandMapping = null;
        if (bandId.HasValue && userInstruments.Count > 0)
        {
            var primaryInstrument = userInstruments[0].InstrumentType;
            bandMapping = await db.BandVoiceMappings
                .FirstOrDefaultAsync(m => m.BandId == bandId.Value
                    && m.Instrument.ToLower() == primaryInstrument);
        }

        // Also check Membership.VoiceOverride (user-level override)
        string? userOverride = null;
        if (bandId.HasValue)
        {
            userOverride = await db.Memberships
                .Where(m => m.MusicianId == musicianId && m.BandId == bandId.Value && m.IsActive)
                .Select(m => m.VoiceOverride)
                .FirstOrDefaultAsync();
        }

        // Determine the target Voice label to search for (3-level override: User > Band > Profile)
        string? targetLabel = null;
        string? targetInstrumentType = null;

        // Level 1: User override (from Membership.VoiceOverride)
        if (!string.IsNullOrWhiteSpace(userOverride))
        {
            targetLabel = userOverride;
        }
        // Level 2: Band mapping
        else if (bandMapping is not null)
        {
            targetLabel = bandMapping.Voice;
        }
        // Level 3: User profile preselection for this band + primary instrument
        else if (userInstruments.Count > 0)
        {
            if (bandId.HasValue)
            {
                // Find preselection for this band (any instrument, sorted by instrument priority)
                foreach (var ni in userInstruments)
                {
                    var preselection = ni.Preselections
                        .FirstOrDefault(v => v.BandId == bandId.Value);
                    if (preselection is not null)
                    {
                        targetLabel = preselection.VoiceLabel;
                        targetInstrumentType = ni.InstrumentType;
                        break;
                    }
                }
            }

            // No band-specific preselection — use primary instrument type
            targetInstrumentType ??= userInstruments[0].InstrumentType;
        }

        // If no instruments configured at all, fall through to step 5
        if (userInstruments.Count == 0 && string.IsNullOrWhiteSpace(targetLabel))
            return FallbackStep5(voices);

        // ── Step 1: Exact match ─────────────────────────────────────────────
        if (!string.IsNullOrWhiteSpace(targetLabel))
        {
            var normalized = NormalizeLabel(targetLabel);
            var match = voices.FirstOrDefault(s =>
                NormalizeLabel(s.Label) == normalized);

            if (match is not null)
                return new VoiceFallbackResult(match.Id, match.Label, 1, null);
        }

        // ── Step 2: Same instrument family + lowest number ──────────────────
        targetInstrumentType ??= userInstruments.FirstOrDefault()?.InstrumentType;

        if (!string.IsNullOrWhiteSpace(targetInstrumentType))
        {
            var sameType = voices
                .Where(s => string.Equals(s.InstrumentType, targetInstrumentType, StringComparison.OrdinalIgnoreCase))
                .OrderBy(s => s.VoiceNumber ?? int.MaxValue)
                .ThenBy(s => s.Label, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();

            if (sameType is not null)
                return new VoiceFallbackResult(sameType.Id, sameType.Label, 2, "same_family_lowest_number");
        }

        // ── Step 3: Generic match (instrument name without number) ──────────
        if (!string.IsNullOrWhiteSpace(targetInstrumentType))
        {
            var displayName = InstrumentTaxonomy.TypeLabel
                .GetValueOrDefault(targetInstrumentType, targetInstrumentType);
            var normalizedType = NormalizeLabel(displayName);

            var generic = voices.FirstOrDefault(s =>
                NormalizeLabel(s.Label) == normalizedType);

            if (generic is not null)
                return new VoiceFallbackResult(generic.Id, generic.Label, 3, "generic_same_instrument");
        }

        // ── Step 4: Related family match ────────────────────────────────────
        if (!string.IsNullOrWhiteSpace(targetInstrumentType))
        {
            var family = InstrumentTaxonomy.GetFamily(targetInstrumentType);
            if (family != InstrumentTaxonomy.FamilyOther)
            {
                var familyMatch = voices
                    .Where(s => string.Equals(s.InstrumentFamily, family, StringComparison.OrdinalIgnoreCase))
                    .OrderBy(s => s.InstrumentType is not null
                        ? InstrumentTaxonomy.GetPriority(s.InstrumentType)
                        : int.MaxValue)
                    .ThenBy(s => s.VoiceNumber ?? int.MaxValue)
                    .ThenBy(s => s.Label, StringComparer.OrdinalIgnoreCase)
                    .FirstOrDefault();

                if (familyMatch is not null)
                    return new VoiceFallbackResult(familyMatch.Id, familyMatch.Label, 4, "related_family");
            }
        }

        // Also try other instruments in the user's profile (step 2-4 for secondary instruments)
        foreach (var ni in userInstruments.Skip(1))
        {
            var sameType = voices
                .Where(s => string.Equals(s.InstrumentType, ni.InstrumentType, StringComparison.OrdinalIgnoreCase))
                .OrderBy(s => s.VoiceNumber ?? int.MaxValue)
                .FirstOrDefault();

            if (sameType is not null)
                return new VoiceFallbackResult(sameType.Id, sameType.Label, 4, "related_family");
        }

        // ── Step 5: First available voice ──────────────────────────────────
        return FallbackStep5(voices);
    }

    private static VoiceFallbackResult FallbackStep5(List<Voice> voices)
    {
        var first = voices
            .OrderBy(s => s.VoiceNumber ?? int.MaxValue)
            .ThenBy(s => s.Label, StringComparer.OrdinalIgnoreCase)
            .First();
        return new VoiceFallbackResult(first.Id, first.Label, 5, "first_available");
    }

    // ── Normalization ───────────────────────────────────────────────────────

    /// <summary>
    /// Normalize a Voice label for matching:
    /// - Trim, lowercase
    /// - Roman numeral → arabic (II → 2)
    /// - Common abbreviations (Klar. → Klarinette)
    /// - Strip ordinal dots ("2." → "2")
    /// </summary>
    internal static string NormalizeLabel(string label)
    {
        var s = label.Trim().ToLowerInvariant();

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
            if (InstrumentTaxonomy.Abbreviations.TryGetValue(parts[i], out var expanded))
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

    private static VoiceProfileResponse MapToProfileResponse(Guid musicianId, List<UserInstrument> instruments)
    {
        return new VoiceProfileResponse(
            musicianId,
            instruments.Select(ni => new UserInstrumentDto(
                ni.Id,
                ni.InstrumentType,
                ni.InstrumentLabel,
                ni.SortOrder,
                ni.Preselections.Select(v => new VoicePreselectionDto(
                    v.BandId,
                    v.Band?.Name ?? "",
                    v.VoiceLabel
                )).ToList()
            )).ToList()
        );
    }
}
