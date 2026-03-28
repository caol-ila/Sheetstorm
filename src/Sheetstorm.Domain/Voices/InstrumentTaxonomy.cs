using System.Collections.Frozen;

namespace Sheetstorm.Domain.Voices;

/// <summary>
/// Static instrument taxonomy for the 6-step Voices fallback algorithm.
/// Defines instrument types, families, and matching priorities.
/// </summary>
public static class InstrumentTaxonomy
{
    // ── Instrument families ──────────────────────────────────────────────────

    public const string FamilyWoodwind = "holzblaeser";
    public const string FamilyBrass = "blechblaeser";
    public const string FamilyPercussion = "schlagwerk";
    public const string FamilyKeyboard = "tasten";
    public const string FamilyOther = "sonstige";

    // ── Instrument type → family mapping with priority within family ─────────

    private static readonly (string Type, string Family, int Priority)[] RawTaxonomy =
    [
        // Holzbläser (priority = sort order for fallback step 4)
        ("floete",            FamilyWoodwind, 1),
        ("piccolo",           FamilyWoodwind, 2),
        ("oboe",              FamilyWoodwind, 3),
        ("klarinette",        FamilyWoodwind, 4),
        ("bassklarinette",    FamilyWoodwind, 5),
        ("fagott",            FamilyWoodwind, 6),
        ("kontrafagott",      FamilyWoodwind, 7),
        ("saxophon_sopran",   FamilyWoodwind, 8),
        ("saxophon_alt",      FamilyWoodwind, 9),
        ("saxophon_tenor",    FamilyWoodwind, 10),
        ("saxophon_bariton",  FamilyWoodwind, 11),

        // Blechbläser
        ("trompete",          FamilyBrass, 1),
        ("fluegelhorn",       FamilyBrass, 2),
        ("horn",              FamilyBrass, 3),
        ("tenorhorn",         FamilyBrass, 4),
        ("posaune",           FamilyBrass, 5),
        ("bassposaune",       FamilyBrass, 6),
        ("euphonium",         FamilyBrass, 7),
        ("tuba",              FamilyBrass, 8),
        ("kontrabass_tuba",   FamilyBrass, 9),

        // Schlagwerk
        ("kleine_trommel",    FamilyPercussion, 1),
        ("grosse_trommel",    FamilyPercussion, 2),
        ("becken",            FamilyPercussion, 3),
        ("pauken",            FamilyPercussion, 4),
        ("xylophon",          FamilyPercussion, 5),
        ("marimba",           FamilyPercussion, 6),
        ("vibraphon",         FamilyPercussion, 7),
        ("schlagzeug",        FamilyPercussion, 8),

        // Tasten / Other
        ("klavier",           FamilyKeyboard, 1),
        ("orgel",             FamilyKeyboard, 2),
        ("akkordeon",         FamilyKeyboard, 3),
        ("harfe",             FamilyKeyboard, 4),
    ];

    /// <summary>Instrument type → (Familie, Priorität).</summary>
    public static readonly FrozenDictionary<string, (string Family, int Priority)> TypeToFamily =
        RawTaxonomy.ToFrozenDictionary(
            x => x.Type,
            x => (x.Family, x.Priority));

    /// <summary>All known instrument types.</summary>
    public static readonly FrozenSet<string> AllTypes =
        RawTaxonomy.Select(x => x.Type).ToFrozenSet();

    /// <summary>All families.</summary>
    public static readonly string[] AllFamilies =
        [FamilyWoodwind, FamilyBrass, FamilyPercussion, FamilyKeyboard];

    // ── Common abbreviations for normalization (Klar. → Klarinette, etc.) ───

    public static readonly FrozenDictionary<string, string> Abbreviations = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
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

    public static readonly FrozenDictionary<string, string> TypeLabel = new Dictionary<string, string>
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
    public static string GetFamily(string instrumentTyp)
        => TypeToFamily.TryGetValue(instrumentTyp, out var info) ? info.Family : FamilyOther;

    /// <summary>Get the priority within its family. Higher = less preferred. Returns int.MaxValue for unknown.</summary>
    public static int GetPriority(string instrumentTyp)
        => TypeToFamily.TryGetValue(instrumentTyp, out var info) ? info.Priority : int.MaxValue;

    /// <summary>Check if the given type is a known instrument.</summary>
    public static bool IsKnownType(string instrumentTyp)
        => AllTypes.Contains(instrumentTyp);
}
