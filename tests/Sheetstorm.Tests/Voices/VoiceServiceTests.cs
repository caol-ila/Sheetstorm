using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Voices;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Voices;

namespace Sheetstorm.Tests.Voices;

public class VoiceServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly VoiceService _sut;

    public VoiceServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new VoiceService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private async Task<(Musician musician, Band band, Piece piece)> SetupAsync()
    {
        var band = new Band { Name = "Testkapelle" };
        var musician = new Musician { Name = "Max Mustermann", Email = "max@test.de", PasswordHash = "hash" };
        var piece = new Piece { Title = "Teststück", BandId = band.Id };

        _db.Bands.Add(band);
        _db.Musicians.Add(musician);
        _db.Pieces.Add(piece);
        _db.Memberships.Add(new Membership
        {
            MusicianId = musician.Id,
            BandId = band.Id,
            IsActive = true,
        });

        await _db.SaveChangesAsync();
        return (musician, band, piece);
    }

    private static Voice MakeStimme(Guid pieceId, string bezeichnung,
        string? typ = null, string? familie = null, int? nummer = null)
        => new()
        {
            PieceId = pieceId,
            Label = bezeichnung,
            InstrumentType = typ,
            InstrumentFamily = familie,
            VoiceNumber = nummer,
        };

    // ── Step 6: No Voices ────────────────────────────────────────────────────

    [Fact]
    public async Task Step6_EmptyStimmen_ReturnsKeineStimmen()
    {
        var (musician, _, piece) = await SetupAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal("no_voices", result.Ergebnis.FallbackGrund);
        Assert.Null(result.Ergebnis.VoiceId);
        Assert.Null(result.Ergebnis.FallbackSchritt);
    }

    [Fact]
    public async Task Step6_EmptyStimmen_GetVoices_ReturnsEmptyListAndKeineStimmen()
    {
        var (musician, _, piece) = await SetupAsync();

        var result = await _sut.GetVoicesAsync(piece.Id, musician.Id);

        Assert.Empty(result.Voices);
        Assert.Equal("no_voices", result.Preselected.FallbackGrund);
    }

    // ── Step 5: First available ───────────────────────────────────────────────

    [Fact]
    public async Task Step5_NoInstrumentProfile_ReturnsFirstAvailable()
    {
        var (musician, _, piece) = await SetupAsync();

        var s2 = MakeStimme(piece.Id, "2. Trompete", "trompete", "blechblaeser", 2);
        var s1 = MakeStimme(piece.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        _db.Voices.AddRange(s2, s1);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal("first_available", result.Ergebnis.FallbackGrund);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId); // lowest VoiceNumber wins
    }

    [Fact]
    public async Task Step5_MultipleUnnumberedStimmen_PicksAlphabetically()
    {
        var (musician, _, piece) = await SetupAsync();

        var sB = MakeStimme(piece.Id, "Bariton Saxophon");
        var sA = MakeStimme(piece.Id, "Alto Saxophon");
        _db.Voices.AddRange(sB, sA);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // null VoiceNumber → int.MaxValue, then sort alphabetically → "Alto Saxophon" first
        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal(sA.Id, result.Ergebnis.VoiceId);
    }

    // ── Step 1: Exact match ───────────────────────────────────────────────────

    [Fact]
    public async Task Step1_NutzerOverride_ExactMatch_ReturnsStep1()
    {
        var (musician, _, piece) = await SetupAsync();

        var voice = MakeStimme(piece.Id, "Bb Klarinette 1", "klarinette", "holzblaeser", 1);
        _db.Voices.Add(voice);

        var membership = await _db.Memberships.FirstAsync(m => m.MusicianId == musician.Id);
        membership.VoiceOverride = "Bb Klarinette 1";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(voice.Id, result.Ergebnis.VoiceId);
        Assert.Equal("Bb Klarinette 1", result.Ergebnis.Label);
    }

    [Fact]
    public async Task Step1_RomanNumeralNormalization_MatchesEquivalentArabicLabel()
    {
        var (musician, _, piece) = await SetupAsync();

        // Voice has "2. Klarinette", override uses roman numeral "II. Klarinette"
        // Both normalize to "2 klarinette" → step 1 match
        var voice = MakeStimme(piece.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Voices.Add(voice);

        var membership = await _db.Memberships.FirstAsync(m => m.MusicianId == musician.Id);
        membership.VoiceOverride = "II. Klarinette";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(voice.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Step1_AbbreviationNormalization_MatchesFullLabel()
    {
        var (musician, _, piece) = await SetupAsync();

        // Voice has "Klarinette 1", override uses abbreviation "Klar. 1"
        var voice = MakeStimme(piece.Id, "Klarinette 1", "klarinette", "holzblaeser", 1);
        _db.Voices.Add(voice);

        var membership = await _db.Memberships.FirstAsync(m => m.MusicianId == musician.Id);
        membership.VoiceOverride = "Klar. 1";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(voice.Id, result.Ergebnis.VoiceId);
    }

    // ── Step 2: Same instrument type ─────────────────────────────────────────

    [Fact]
    public async Task Step2_SameInstrumentType_PicksLowestVoiceNumber()
    {
        var (musician, _, piece) = await SetupAsync();

        // User plays "A Klarinette" but piece only has "Bb Klarinette" (different label, same type key)
        var s1 = MakeStimme(piece.Id, "Bb Klarinette 1", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(piece.Id, "Bb Klarinette 2", "klarinette", "holzblaeser", 2);
        _db.Voices.AddRange(s1, s2);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "A Klarinette",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal("same_family_lowest_number", result.Ergebnis.FallbackGrund);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId); // Nummer 1 wins
    }

    [Fact]
    public async Task Step2_SameTyp_NoNumber_PicksAlphabetically()
    {
        var (musician, _, piece) = await SetupAsync();

        var sB = MakeStimme(piece.Id, "Trompete B", "trompete", "blechblaeser");
        var sA = MakeStimme(piece.Id, "Trompete A", "trompete", "blechblaeser");
        _db.Voices.AddRange(sB, sA);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "trompete",
            InstrumentLabel = "Trompete",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(sA.Id, result.Ergebnis.VoiceId); // "Trompete A" before "Trompete B"
    }

    // ── Step 3: Generic display-name match ────────────────────────────────────

    [Fact]
    public async Task Step3_GenericDisplayName_MatchesWhenNoTypSet()
    {
        var (musician, _, piece) = await SetupAsync();

        // Voice has no InstrumentType but Label = "Klarinette" (generic label)
        // Step 2 won't match (InstrumentType = null), step 3 matches via display name
        var genericStimme = MakeStimme(piece.Id, "Klarinette", typ: null, familie: null);
        _db.Voices.Add(genericStimme);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "Klarinette",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(3, result.Ergebnis.FallbackSchritt);
        Assert.Equal("generic_same_instrument", result.Ergebnis.FallbackGrund);
        Assert.Equal(genericStimme.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Step3_GenericFloetenLabel_MatchesFloetenSpieler()
    {
        var (musician, _, piece) = await SetupAsync();

        var floeteStimme = MakeStimme(piece.Id, "Flöte", typ: null);
        _db.Voices.Add(floeteStimme);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "floete",
            InstrumentLabel = "Flöte",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(3, result.Ergebnis.FallbackSchritt);
        Assert.Equal(floeteStimme.Id, result.Ergebnis.VoiceId);
    }

    // ── Step 4: Related family match ──────────────────────────────────────────

    [Fact]
    public async Task Step4_KlarnetteToOboe_SameHolzblaeserFamily_ReturnsStep4()
    {
        var (musician, _, piece) = await SetupAsync();

        // Piece has no Klarinette, only Oboe — same Holzblaeser family
        var oboeStimme = MakeStimme(piece.Id, "Oboe", "oboe", InstrumentTaxonomy.FamilyWoodwind);
        _db.Voices.Add(oboeStimme);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "Klarinette",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        Assert.Equal("related_family", result.Ergebnis.FallbackGrund);
        Assert.Equal(oboeStimme.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Step4_TrompeteToPosaune_SameBlechblaeserFamily_ReturnsStep4()
    {
        var (musician, _, piece) = await SetupAsync();

        // Piece only has Posaune — Trompete can fall back within Blechblaeser
        var posauneStimme = MakeStimme(piece.Id, "Posaune", "posaune", InstrumentTaxonomy.FamilyBrass);
        _db.Voices.Add(posauneStimme);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "trompete",
            InstrumentLabel = "Trompete",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        Assert.Equal("related_family", result.Ergebnis.FallbackGrund);
        Assert.Equal(posauneStimme.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Step4_FamilyMatch_PicksByPrioritaetThenNumber()
    {
        var (musician, _, piece) = await SetupAsync();

        // Piece has Posaune (prio 5) and Flügelhorn (prio 2) — both Blechblaeser
        // Trompete player should fall back to Flügelhorn (higher priority = lower number)
        var posauneStimme = MakeStimme(piece.Id, "Posaune", "posaune", InstrumentTaxonomy.FamilyBrass, 1);
        var fluegelhornStimme = MakeStimme(piece.Id, "Flügelhorn", "fluegelhorn", InstrumentTaxonomy.FamilyBrass, 1);
        _db.Voices.AddRange(posauneStimme, fluegelhornStimme);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "trompete",
            InstrumentLabel = "Trompete",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        // Flügelhorn has lower Priorität value (2) than Posaune (5) → preferred
        Assert.Equal(fluegelhornStimme.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Step4_UnknownInstrumentTypee_SonstigeFamily_FallsToStep5()
    {
        var (musician, _, piece) = await SetupAsync();

        // "gitarre" is not in InstrumentTaxonomy → GetFamily returns "sonstige" → no family match
        var voice = MakeStimme(piece.Id, "Harfe", "harfe", InstrumentTaxonomy.FamilyKeyboard);
        _db.Voices.Add(voice);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "gitarre", // unknown → sonstige
            InstrumentLabel = "Gitarre",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // Cannot match by family (sonstige excluded) → falls to step 5
        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal("first_available", result.Ergebnis.FallbackGrund);
    }

    // ── 3-Level Override Resolution ───────────────────────────────────────────

    [Fact]
    public async Task Override_NutzerOverride_WinsOverKapelleMapping()
    {
        var (musician, band, piece) = await SetupAsync();

        var s1 = MakeStimme(piece.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(piece.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Voices.AddRange(s1, s2);

        // Band mapping says: klarinette → "2. Klarinette"
        _db.BandVoiceMappings.Add(new BandVoiceMapping
        {
            BandId = band.Id,
            Instrument = "klarinette",
            Voice = "2. Klarinette",
        });

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "Klarinette",
            SortOrder = 0,
        });

        // Nutzer override says "1. Klarinette" — should win over Band mapping
        var membership = await _db.Memberships.FirstAsync(m => m.MusicianId == musician.Id);
        membership.VoiceOverride = "1. Klarinette";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId); // Nutzer override wins
    }

    [Fact]
    public async Task Override_KapelleMapping_WinsOverProfileVorauswahl()
    {
        var (musician, band, piece) = await SetupAsync();

        var s1 = MakeStimme(piece.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(piece.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Voices.AddRange(s1, s2);

        // Band mapping says: klarinette → "2. Klarinette"
        _db.BandVoiceMappings.Add(new BandVoiceMapping
        {
            BandId = band.Id,
            Instrument = "klarinette",
            Voice = "2. Klarinette",
        });

        // User profile Vorauswahl says: prefer "1. Klarinette" in this Band
        var ni = new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "Klarinette",
            SortOrder = 0,
        };
        ni.Preselections.Add(new VoicePreselection
        {
            MusicianId = musician.Id,
            BandId = band.Id,
            UserInstrumentID = ni.Id,
            VoiceLabel = "1. Klarinette",
        });
        _db.UserInstruments.Add(ni);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // Band mapping (level 2) wins over profile Vorauswahl (level 3)
        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s2.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Override_ProfileVorauswahl_UsedWhenNoOtherOverrideSet()
    {
        var (musician, band, piece) = await SetupAsync();

        var s1 = MakeStimme(piece.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(piece.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Voices.AddRange(s1, s2);

        // No Nutzer override, no Band mapping — only profile Vorauswahl
        var ni = new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "klarinette",
            InstrumentLabel = "Klarinette",
            SortOrder = 0,
        };
        ni.Preselections.Add(new VoicePreselection
        {
            MusicianId = musician.Id,
            BandId = band.Id,
            UserInstrumentID = ni.Id,
            VoiceLabel = "1. Klarinette",
        });
        _db.UserInstruments.Add(ni);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // Profile Vorauswahl used as level 3 fallback
        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Override_NoOverridesSet_FallsToInstrumentTypeMatching()
    {
        var (musician, _, piece) = await SetupAsync();

        var s1 = MakeStimme(piece.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        _db.Voices.Add(s1);

        // User has instrument but no Vorauswahl, no Band mapping, no Nutzer override
        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "trompete",
            InstrumentLabel = "Trompete",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // No override exists → uses InstrumentType matching (step 2)
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId);
    }

    // ── Edge Cases ────────────────────────────────────────────────────────────

    [Fact]
    public async Task Edge_StueckNotFound_ThrowsDomainException()
    {
        var musician = new Musician { Name = "Test", Email = "t@test.de", PasswordHash = "x" };
        _db.Musicians.Add(musician);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ResolveVoiceAsync(Guid.NewGuid(), musician.Id));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task Edge_NoBandId_PersonalPiece_UsesInstrumentTypeFallback()
    {
        // Personal piece (no BandId) — no Band-level overrides apply
        var musician = new Musician { Name = "Solo", Email = "solo@test.de", PasswordHash = "x" };
        var piece = new Piece { Title = "Solostück", BandId = null, MusicianId = musician.Id };
        _db.Musicians.Add(musician);
        _db.Pieces.Add(piece);

        var voice = MakeStimme(piece.Id, "Flöte", "floete", InstrumentTaxonomy.FamilyWoodwind);
        _db.Voices.Add(voice);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "floete",
            InstrumentLabel = "Flöte",
            SortOrder = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // Step 2: same InstrumentType "floete" matches
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(voice.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task Edge_InactiveKapelleMembership_NutzerOverrideIgnored()
    {
        var (musician, band, piece) = await SetupAsync();

        var s1 = MakeStimme(piece.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        var s2 = MakeStimme(piece.Id, "2. Trompete", "trompete", "blechblaeser", 2);
        _db.Voices.AddRange(s1, s2);

        _db.UserInstruments.Add(new UserInstrument
        {
            MusicianId = musician.Id,
            InstrumentType = "trompete",
            InstrumentLabel = "Trompete",
            SortOrder = 0,
        });

        // Mark membership as inactive → override should not apply
        var membership = await _db.Memberships.FirstAsync(m => m.MusicianId == musician.Id);
        membership.IsActive = false;
        membership.VoiceOverride = "2. Trompete";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveVoiceAsync(piece.Id, musician.Id);

        // Inactive membership → override ignored → step 2 picks lowest Trompete
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.VoiceId);
    }

    [Fact]
    public async Task GetVoices_ReturnsAllStimmenSortedByNumberThenAlpha()
    {
        var (musician, _, piece) = await SetupAsync();

        var s3 = MakeStimme(piece.Id, "3. Voice", nummer: 3);
        var s1 = MakeStimme(piece.Id, "1. Voice", nummer: 1);
        var s2 = MakeStimme(piece.Id, "2. Voice", nummer: 2);
        _db.Voices.AddRange(s3, s1, s2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetVoicesAsync(piece.Id, musician.Id);

        Assert.Equal(3, result.Voices.Count);
        Assert.Equal(s1.Id, result.Voices[0].Id);
        Assert.Equal(s2.Id, result.Voices[1].Id);
        Assert.Equal(s3.Id, result.Voices[2].Id);
        Assert.Equal(piece.Id, result.PieceId);
    }
}
