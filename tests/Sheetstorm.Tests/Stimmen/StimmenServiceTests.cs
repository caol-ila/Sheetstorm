using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Stimmen;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Stimmen;

namespace Sheetstorm.Tests.Stimmen;

public class StimmenServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly StimmenService _sut;

    public StimmenServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new StimmenService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private async Task<(Musiker musiker, Kapelle kapelle, Stueck stueck)> SetupAsync()
    {
        var kapelle = new Kapelle { Name = "Testkapelle" };
        var musiker = new Musiker { Name = "Max Mustermann", Email = "max@test.de", PasswordHash = "hash" };
        var stueck = new Stueck { Titel = "Teststück", KapelleID = kapelle.Id };

        _db.Kapellen.Add(kapelle);
        _db.Musiker.Add(musiker);
        _db.Stuecke.Add(stueck);
        _db.Mitgliedschaften.Add(new Mitgliedschaft
        {
            MusikerID = musiker.Id,
            KapelleID = kapelle.Id,
            IstAktiv = true,
        });

        await _db.SaveChangesAsync();
        return (musiker, kapelle, stueck);
    }

    private static Stimme MakeStimme(Guid stueckId, string bezeichnung,
        string? typ = null, string? familie = null, int? nummer = null)
        => new()
        {
            StueckID = stueckId,
            Bezeichnung = bezeichnung,
            InstrumentTyp = typ,
            InstrumentFamilie = familie,
            StimmenNummer = nummer,
        };

    // ── Step 6: No Stimmen ────────────────────────────────────────────────────

    [Fact]
    public async Task Step6_EmptyStimmen_ReturnsKeineStimmen()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal("keine_stimmen", result.Ergebnis.FallbackGrund);
        Assert.Null(result.Ergebnis.StimmeId);
        Assert.Null(result.Ergebnis.FallbackSchritt);
    }

    [Fact]
    public async Task Step6_EmptyStimmen_GetStimmen_ReturnsEmptyListAndKeineStimmen()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var result = await _sut.GetStimmenAsync(stueck.Id, musiker.Id);

        Assert.Empty(result.Stimmen);
        Assert.Equal("keine_stimmen", result.Vorausgewaehlt.FallbackGrund);
    }

    // ── Step 5: First available ───────────────────────────────────────────────

    [Fact]
    public async Task Step5_NoInstrumentProfile_ReturnsFirstAvailable()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var s2 = MakeStimme(stueck.Id, "2. Trompete", "trompete", "blechblaeser", 2);
        var s1 = MakeStimme(stueck.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        _db.Stimmen.AddRange(s2, s1);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal("erste_verfuegbare", result.Ergebnis.FallbackGrund);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId); // lowest StimmenNummer wins
    }

    [Fact]
    public async Task Step5_MultipleUnnumberedStimmen_PicksAlphabetically()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var sB = MakeStimme(stueck.Id, "Bariton Saxophon");
        var sA = MakeStimme(stueck.Id, "Alto Saxophon");
        _db.Stimmen.AddRange(sB, sA);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // null StimmenNummer → int.MaxValue, then sort alphabetically → "Alto Saxophon" first
        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal(sA.Id, result.Ergebnis.StimmeId);
    }

    // ── Step 1: Exact match ───────────────────────────────────────────────────

    [Fact]
    public async Task Step1_NutzerOverride_ExactMatch_ReturnsStep1()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var stimme = MakeStimme(stueck.Id, "Bb Klarinette 1", "klarinette", "holzblaeser", 1);
        _db.Stimmen.Add(stimme);

        var mitgliedschaft = await _db.Mitgliedschaften.FirstAsync(m => m.MusikerID == musiker.Id);
        mitgliedschaft.StimmenOverride = "Bb Klarinette 1";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(stimme.Id, result.Ergebnis.StimmeId);
        Assert.Equal("Bb Klarinette 1", result.Ergebnis.Bezeichnung);
    }

    [Fact]
    public async Task Step1_RomanNumeralNormalization_MatchesEquivalentArabicLabel()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Stimme has "2. Klarinette", override uses roman numeral "II. Klarinette"
        // Both normalize to "2 klarinette" → step 1 match
        var stimme = MakeStimme(stueck.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Stimmen.Add(stimme);

        var mitgliedschaft = await _db.Mitgliedschaften.FirstAsync(m => m.MusikerID == musiker.Id);
        mitgliedschaft.StimmenOverride = "II. Klarinette";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(stimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Step1_AbbreviationNormalization_MatchesFullLabel()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Stimme has "Klarinette 1", override uses abbreviation "Klar. 1"
        var stimme = MakeStimme(stueck.Id, "Klarinette 1", "klarinette", "holzblaeser", 1);
        _db.Stimmen.Add(stimme);

        var mitgliedschaft = await _db.Mitgliedschaften.FirstAsync(m => m.MusikerID == musiker.Id);
        mitgliedschaft.StimmenOverride = "Klar. 1";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(stimme.Id, result.Ergebnis.StimmeId);
    }

    // ── Step 2: Same instrument type ─────────────────────────────────────────

    [Fact]
    public async Task Step2_SameInstrumentTyp_PicksLowestStimmenNummer()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // User plays "A Klarinette" but piece only has "Bb Klarinette" (different label, same type key)
        var s1 = MakeStimme(stueck.Id, "Bb Klarinette 1", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(stueck.Id, "Bb Klarinette 2", "klarinette", "holzblaeser", 2);
        _db.Stimmen.AddRange(s1, s2);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "A Klarinette",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal("gleiche_familie_niedrigste_nr", result.Ergebnis.FallbackGrund);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId); // Nummer 1 wins
    }

    [Fact]
    public async Task Step2_SameTyp_NoNumber_PicksAlphabetically()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var sB = MakeStimme(stueck.Id, "Trompete B", "trompete", "blechblaeser");
        var sA = MakeStimme(stueck.Id, "Trompete A", "trompete", "blechblaeser");
        _db.Stimmen.AddRange(sB, sA);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "trompete",
            InstrumentBezeichnung = "Trompete",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(sA.Id, result.Ergebnis.StimmeId); // "Trompete A" before "Trompete B"
    }

    // ── Step 3: Generic display-name match ────────────────────────────────────

    [Fact]
    public async Task Step3_GenericDisplayName_MatchesWhenNoTypSet()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Stimme has no InstrumentTyp but Bezeichnung = "Klarinette" (generic label)
        // Step 2 won't match (InstrumentTyp = null), step 3 matches via display name
        var genericStimme = MakeStimme(stueck.Id, "Klarinette", typ: null, familie: null);
        _db.Stimmen.Add(genericStimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "Klarinette",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(3, result.Ergebnis.FallbackSchritt);
        Assert.Equal("generisch_selbes_instrument", result.Ergebnis.FallbackGrund);
        Assert.Equal(genericStimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Step3_GenericFloetenLabel_MatchesFloetenSpieler()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var floeteStimme = MakeStimme(stueck.Id, "Flöte", typ: null);
        _db.Stimmen.Add(floeteStimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "floete",
            InstrumentBezeichnung = "Flöte",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(3, result.Ergebnis.FallbackSchritt);
        Assert.Equal(floeteStimme.Id, result.Ergebnis.StimmeId);
    }

    // ── Step 4: Related family match ──────────────────────────────────────────

    [Fact]
    public async Task Step4_KlarnetteToOboe_SameHolzblaeserFamily_ReturnsStep4()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Piece has no Klarinette, only Oboe — same Holzblaeser family
        var oboeStimme = MakeStimme(stueck.Id, "Oboe", "oboe", InstrumentTaxonomie.FamilieHolzblaeser);
        _db.Stimmen.Add(oboeStimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "Klarinette",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        Assert.Equal("verwandte_familie", result.Ergebnis.FallbackGrund);
        Assert.Equal(oboeStimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Step4_TrompeteToPosaune_SameBlechblaeserFamily_ReturnsStep4()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Piece only has Posaune — Trompete can fall back within Blechblaeser
        var posauneStimme = MakeStimme(stueck.Id, "Posaune", "posaune", InstrumentTaxonomie.FamilieBlechblaeser);
        _db.Stimmen.Add(posauneStimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "trompete",
            InstrumentBezeichnung = "Trompete",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        Assert.Equal("verwandte_familie", result.Ergebnis.FallbackGrund);
        Assert.Equal(posauneStimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Step4_FamilyMatch_PicksByPrioritaetThenNumber()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // Piece has Posaune (prio 5) and Flügelhorn (prio 2) — both Blechblaeser
        // Trompete player should fall back to Flügelhorn (higher priority = lower number)
        var posauneStimme = MakeStimme(stueck.Id, "Posaune", "posaune", InstrumentTaxonomie.FamilieBlechblaeser, 1);
        var fluegelhornStimme = MakeStimme(stueck.Id, "Flügelhorn", "fluegelhorn", InstrumentTaxonomie.FamilieBlechblaeser, 1);
        _db.Stimmen.AddRange(posauneStimme, fluegelhornStimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "trompete",
            InstrumentBezeichnung = "Trompete",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(4, result.Ergebnis.FallbackSchritt);
        // Flügelhorn has lower Priorität value (2) than Posaune (5) → preferred
        Assert.Equal(fluegelhornStimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Step4_UnknownInstrumentType_SonstigeFamily_FallsToStep5()
    {
        var (musiker, _, stueck) = await SetupAsync();

        // "gitarre" is not in InstrumentTaxonomie → GetFamilie returns "sonstige" → no family match
        var stimme = MakeStimme(stueck.Id, "Harfe", "harfe", InstrumentTaxonomie.FamilieTasten);
        _db.Stimmen.Add(stimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "gitarre", // unknown → sonstige
            InstrumentBezeichnung = "Gitarre",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // Cannot match by family (sonstige excluded) → falls to step 5
        Assert.Equal(5, result.Ergebnis.FallbackSchritt);
        Assert.Equal("erste_verfuegbare", result.Ergebnis.FallbackGrund);
    }

    // ── 3-Level Override Resolution ───────────────────────────────────────────

    [Fact]
    public async Task Override_NutzerOverride_WinsOverKapelleMapping()
    {
        var (musiker, kapelle, stueck) = await SetupAsync();

        var s1 = MakeStimme(stueck.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(stueck.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Stimmen.AddRange(s1, s2);

        // Kapelle mapping says: klarinette → "2. Klarinette"
        _db.KapelleStimmenMappings.Add(new KapelleStimmenMapping
        {
            KapelleId = kapelle.Id,
            Instrument = "klarinette",
            Stimme = "2. Klarinette",
        });

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "Klarinette",
            Sortierung = 0,
        });

        // Nutzer override says "1. Klarinette" — should win over Kapelle mapping
        var mitgliedschaft = await _db.Mitgliedschaften.FirstAsync(m => m.MusikerID == musiker.Id);
        mitgliedschaft.StimmenOverride = "1. Klarinette";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId); // Nutzer override wins
    }

    [Fact]
    public async Task Override_KapelleMapping_WinsOverProfileVorauswahl()
    {
        var (musiker, kapelle, stueck) = await SetupAsync();

        var s1 = MakeStimme(stueck.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(stueck.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Stimmen.AddRange(s1, s2);

        // Kapelle mapping says: klarinette → "2. Klarinette"
        _db.KapelleStimmenMappings.Add(new KapelleStimmenMapping
        {
            KapelleId = kapelle.Id,
            Instrument = "klarinette",
            Stimme = "2. Klarinette",
        });

        // User profile Vorauswahl says: prefer "1. Klarinette" in this Kapelle
        var ni = new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "Klarinette",
            Sortierung = 0,
        };
        ni.Vorauswahlen.Add(new StimmeVorauswahl
        {
            MusikerID = musiker.Id,
            KapelleID = kapelle.Id,
            NutzerInstrumentID = ni.Id,
            StimmeBezeichnung = "1. Klarinette",
        });
        _db.NutzerInstrumente.Add(ni);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // Kapelle mapping (level 2) wins over profile Vorauswahl (level 3)
        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s2.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Override_ProfileVorauswahl_UsedWhenNoOtherOverrideSet()
    {
        var (musiker, kapelle, stueck) = await SetupAsync();

        var s1 = MakeStimme(stueck.Id, "1. Klarinette", "klarinette", "holzblaeser", 1);
        var s2 = MakeStimme(stueck.Id, "2. Klarinette", "klarinette", "holzblaeser", 2);
        _db.Stimmen.AddRange(s1, s2);

        // No Nutzer override, no Kapelle mapping — only profile Vorauswahl
        var ni = new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "klarinette",
            InstrumentBezeichnung = "Klarinette",
            Sortierung = 0,
        };
        ni.Vorauswahlen.Add(new StimmeVorauswahl
        {
            MusikerID = musiker.Id,
            KapelleID = kapelle.Id,
            NutzerInstrumentID = ni.Id,
            StimmeBezeichnung = "1. Klarinette",
        });
        _db.NutzerInstrumente.Add(ni);
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // Profile Vorauswahl used as level 3 fallback
        Assert.Equal(1, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Override_NoOverridesSet_FallsToInstrumentTypMatching()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var s1 = MakeStimme(stueck.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        _db.Stimmen.Add(s1);

        // User has instrument but no Vorauswahl, no Kapelle mapping, no Nutzer override
        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "trompete",
            InstrumentBezeichnung = "Trompete",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // No override exists → uses InstrumentTyp matching (step 2)
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId);
    }

    // ── Edge Cases ────────────────────────────────────────────────────────────

    [Fact]
    public async Task Edge_StueckNotFound_ThrowsDomainException()
    {
        var musiker = new Musiker { Name = "Test", Email = "t@test.de", PasswordHash = "x" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ResolveStimmeAsync(Guid.NewGuid(), musiker.Id));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task Edge_NoKapelleId_PersonalPiece_UsesInstrumentTypFallback()
    {
        // Personal piece (no KapelleID) — no Kapelle-level overrides apply
        var musiker = new Musiker { Name = "Solo", Email = "solo@test.de", PasswordHash = "x" };
        var stueck = new Stueck { Titel = "Solostück", KapelleID = null, MusikerID = musiker.Id };
        _db.Musiker.Add(musiker);
        _db.Stuecke.Add(stueck);

        var stimme = MakeStimme(stueck.Id, "Flöte", "floete", InstrumentTaxonomie.FamilieHolzblaeser);
        _db.Stimmen.Add(stimme);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "floete",
            InstrumentBezeichnung = "Flöte",
            Sortierung = 0,
        });
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // Step 2: same InstrumentTyp "floete" matches
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(stimme.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task Edge_InactiveKapelleMitgliedschaft_NutzerOverrideIgnored()
    {
        var (musiker, kapelle, stueck) = await SetupAsync();

        var s1 = MakeStimme(stueck.Id, "1. Trompete", "trompete", "blechblaeser", 1);
        var s2 = MakeStimme(stueck.Id, "2. Trompete", "trompete", "blechblaeser", 2);
        _db.Stimmen.AddRange(s1, s2);

        _db.NutzerInstrumente.Add(new NutzerInstrument
        {
            MusikerID = musiker.Id,
            InstrumentTyp = "trompete",
            InstrumentBezeichnung = "Trompete",
            Sortierung = 0,
        });

        // Mark membership as inactive → override should not apply
        var mitgliedschaft = await _db.Mitgliedschaften.FirstAsync(m => m.MusikerID == musiker.Id);
        mitgliedschaft.IstAktiv = false;
        mitgliedschaft.StimmenOverride = "2. Trompete";
        await _db.SaveChangesAsync();

        var result = await _sut.ResolveStimmeAsync(stueck.Id, musiker.Id);

        // Inactive membership → override ignored → step 2 picks lowest Trompete
        Assert.Equal(2, result.Ergebnis.FallbackSchritt);
        Assert.Equal(s1.Id, result.Ergebnis.StimmeId);
    }

    [Fact]
    public async Task GetStimmen_ReturnsAllStimmenSortedByNumberThenAlpha()
    {
        var (musiker, _, stueck) = await SetupAsync();

        var s3 = MakeStimme(stueck.Id, "3. Stimme", nummer: 3);
        var s1 = MakeStimme(stueck.Id, "1. Stimme", nummer: 1);
        var s2 = MakeStimme(stueck.Id, "2. Stimme", nummer: 2);
        _db.Stimmen.AddRange(s3, s1, s2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetStimmenAsync(stueck.Id, musiker.Id);

        Assert.Equal(3, result.Stimmen.Count);
        Assert.Equal(s1.Id, result.Stimmen[0].Id);
        Assert.Equal(s2.Id, result.Stimmen[1].Id);
        Assert.Equal(s3.Id, result.Stimmen[2].Id);
        Assert.Equal(stueck.Id, result.StueckId);
    }
}
