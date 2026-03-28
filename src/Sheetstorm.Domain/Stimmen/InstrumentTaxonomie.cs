using System.Collections.Frozen;

namespace Sheetstorm.Domain.Stimmen;

/// <summary>
/// Static instrument taxonomy for the 6-step Stimmen fallback algorithm.
/// Defines instrument types, families, and matching priorities.
/// </summary>
public static class InstrumentTaxonomie
{
    // ── Instrument families ──────────────────────────────────────────────────

    public const string FamilieHolzblaeser = "holzblaeser";
    public const string FamilieBlechblaeser = "blechblaeser";
    public const string FamilieSchlagwerk = "schlagwerk";
    public const string FamilieTasten = "tasten";
    public const string FamilieSonstige = "sonstige";

    // ── Instrument type → family mapping with priority within family ─────────

    private static readonly (string Typ, string Familie, int Prioritaet)[] RawTaxonomie =
    [
        // Holzbläser (priority = sort order for fallback step 4)
        ("floete",            FamilieHolzblaeser, 1),
        ("piccolo",           FamilieHolzblaeser, 2),
        ("oboe",              FamilieHolzblaeser, 3),
        ("klarinette",        FamilieHolzblaeser, 4),
        ("bassklarinette",    FamilieHolzblaeser, 5),
        ("fagott",            FamilieHolzblaeser, 6),
        ("kontrafagott",      FamilieHolzblaeser, 7),
        ("saxophon_sopran",   FamilieHolzblaeser, 8),
        ("saxophon_alt",      FamilieHolzblaeser, 9),
        ("saxophon_tenor",    FamilieHolzblaeser, 10),
        ("saxophon_bariton",  FamilieHolzblaeser, 11),

        // Blechbläser
        ("trompete",          FamilieBlechblaeser, 1),
        ("fluegelhorn",       FamilieBlechblaeser, 2),
        ("horn",              FamilieBlechblaeser, 3),
        ("tenorhorn",         FamilieBlechblaeser, 4),
        ("posaune",           FamilieBlechblaeser, 5),
        ("bassposaune",       FamilieBlechblaeser, 6),
        ("euphonium",         FamilieBlechblaeser, 7),
        ("tuba",              FamilieBlechblaeser, 8),
        ("kontrabass_tuba",   FamilieBlechblaeser, 9),

        // Schlagwerk
        ("kleine_trommel",    FamilieSchlagwerk, 1),
        ("grosse_trommel",    FamilieSchlagwerk, 2),
        ("becken",            FamilieSchlagwerk, 3),
        ("pauken",            FamilieSchlagwerk, 4),
        ("xylophon",          FamilieSchlagwerk, 5),
        ("marimba",           FamilieSchlagwerk, 6),
        ("vibraphon",         FamilieSchlagwerk, 7),
        ("schlagzeug",        FamilieSchlagwerk, 8),

        // Tasten / Sonstige
        ("klavier",           FamilieTasten, 1),
        ("orgel",             FamilieTasten, 2),
        ("akkordeon",         FamilieTasten, 3),
        ("harfe",             FamilieTasten, 4),
    ];

    /// <summary>Instrument type → (Familie, Priorität).</summary>
    public static readonly FrozenDictionary<string, (string Familie, int Prioritaet)> TypZuFamilie =
        RawTaxonomie.ToFrozenDictionary(
            x => x.Typ,
            x => (x.Familie, x.Prioritaet));

    /// <summary>All known instrument types.</summary>
    public static readonly FrozenSet<string> AlleTypen =
        RawTaxonomie.Select(x => x.Typ).ToFrozenSet();

    /// <summary>All families.</summary>
    public static readonly string[] AlleFamilien =
        [FamilieHolzblaeser, FamilieBlechblaeser, FamilieSchlagwerk, FamilieTasten];

    // ── Common abbreviations for normalization (Klar. → Klarinette, etc.) ───

    public static readonly FrozenDictionary<string, string> Abkuerzungen = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        ["klar."]  = "klarinette",
        ["klar"]   = "klarinette",
        ["trp."]   = "trompete",
        ["trp"]    = "trompete",
        ["pos."]   = "posaune",
        ["pos"]    = "posaune",
        ["fl."]    = "floete",
        ["fl"]     = "floete",
        ["ob."]    = "oboe",
        ["ob"]     = "oboe",
        ["fg."]    = "fagott",
        ["fg"]     = "fagott",
        ["hr."]    = "horn",
        ["hr"]     = "horn",
        ["sax."]   = "saxophon",
        ["sax"]    = "saxophon",
        ["euph."]  = "euphonium",
        ["euph"]   = "euphonium",
        ["tb."]    = "tuba",
        ["tb"]     = "tuba",
        ["flgh."]  = "fluegelhorn",
        ["flgh"]   = "fluegelhorn",
        ["th."]    = "tenorhorn",
        ["th"]     = "tenorhorn",
    }.ToFrozenDictionary(StringComparer.OrdinalIgnoreCase);

    // ── Typ → display name ──────────────────────────────────────────────────

    public static readonly FrozenDictionary<string, string> TypBezeichnung = new Dictionary<string, string>
    {
        ["floete"]           = "Flöte",
        ["piccolo"]          = "Piccolo",
        ["oboe"]             = "Oboe",
        ["klarinette"]       = "Klarinette",
        ["bassklarinette"]   = "Bassklarinette",
        ["fagott"]           = "Fagott",
        ["kontrafagott"]     = "Kontrafagott",
        ["saxophon_sopran"]  = "Sopransaxophon",
        ["saxophon_alt"]     = "Altsaxophon",
        ["saxophon_tenor"]   = "Tenorsaxophon",
        ["saxophon_bariton"] = "Baritonsaxophon",
        ["trompete"]         = "Trompete",
        ["fluegelhorn"]      = "Flügelhorn",
        ["horn"]             = "Horn",
        ["tenorhorn"]        = "Tenorhorn",
        ["posaune"]          = "Posaune",
        ["bassposaune"]      = "Bassposaune",
        ["euphonium"]        = "Euphonium",
        ["tuba"]             = "Tuba",
        ["kontrabass_tuba"]  = "Kontrabass-Tuba",
        ["kleine_trommel"]   = "Kleine Trommel",
        ["grosse_trommel"]   = "Große Trommel",
        ["becken"]           = "Becken",
        ["pauken"]           = "Pauken",
        ["xylophon"]         = "Xylophon",
        ["marimba"]          = "Marimba",
        ["vibraphon"]        = "Vibraphon",
        ["schlagzeug"]       = "Schlagzeug",
        ["klavier"]          = "Klavier",
        ["orgel"]            = "Orgel",
        ["akkordeon"]        = "Akkordeon",
        ["harfe"]            = "Harfe",
    }.ToFrozenDictionary();

    /// <summary>Get the family for an instrument type. Returns "sonstige" for unknown types.</summary>
    public static string GetFamilie(string instrumentTyp)
        => TypZuFamilie.TryGetValue(instrumentTyp, out var info) ? info.Familie : FamilieSonstige;

    /// <summary>Get the priority within its family. Higher = less preferred. Returns int.MaxValue for unknown.</summary>
    public static int GetPrioritaet(string instrumentTyp)
        => TypZuFamilie.TryGetValue(instrumentTyp, out var info) ? info.Prioritaet : int.MaxValue;

    /// <summary>Check if the given type is a known instrument.</summary>
    public static bool IstBekannterTyp(string instrumentTyp)
        => AlleTypen.Contains(instrumentTyp);
}
