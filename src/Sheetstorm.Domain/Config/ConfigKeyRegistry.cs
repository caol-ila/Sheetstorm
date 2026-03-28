using System.Text.Json;

namespace Sheetstorm.Domain.Config;

/// <summary>
/// Registry of all predefined config keys with type, default value, and validation rules.
/// Single source of truth for the 3-level config system.
/// </summary>
public static class ConfigKeyRegistry
{
    public enum ConfigValueType
    {
        String,
        Int,
        Float,
        Bool,
        Enum,
        StringArray,
        RoleArray,
        Map,
        Color,
        Locale,
        Url,
        Encrypted
    }

    public enum ConfigEbene
    {
        Kapelle,
        Nutzer,
        Policy
    }

    public record ConfigKeyDefinition(
        string Schluessel,
        ConfigValueType Typ,
        ConfigEbene Ebene,
        JsonElement DefaultWert,
        string? Beschreibung = null,
        string[]? AllowedValues = null,
        int? MinValue = null,
        int? MaxValue = null,
        double? MinFloat = null,
        double? MaxFloat = null
    );

    private static readonly JsonElement NullJson = JsonDocument.Parse("null").RootElement.Clone();
    private static readonly JsonElement TrueJson = JsonDocument.Parse("true").RootElement.Clone();
    private static readonly JsonElement FalseJson = JsonDocument.Parse("false").RootElement.Clone();

    private static JsonElement Json(string raw) => JsonDocument.Parse(raw).RootElement.Clone();

    private static readonly Dictionary<string, ConfigKeyDefinition> _keys = BuildRegistry();

    public static IReadOnlyDictionary<string, ConfigKeyDefinition> AllKeys => _keys;

    public static ConfigKeyDefinition? Get(string schluessel)
        => _keys.GetValueOrDefault(schluessel);

    public static bool Exists(string schluessel) => _keys.ContainsKey(schluessel);

    public static IEnumerable<ConfigKeyDefinition> GetByEbene(ConfigEbene ebene)
        => _keys.Values.Where(k => k.Ebene == ebene);

    /// <summary>
    /// Maps policy keys to the config keys they enforce.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, string[]> PolicyAffectedKeys = new Dictionary<string, string[]>
    {
        ["policy.force_locale"] = ["nutzer.sprache"],
        ["policy.force_dark_mode"] = ["nutzer.theme"],
        ["policy.allow_user_ai_keys"] = ["nutzer.ai.provider", "nutzer.ai.api_key"],
        ["policy.force_kammerton"] = ["geraet.tuner.kammerton"],
        ["policy.min_annotation_layer"] = [],
    };

    /// <summary>
    /// Validates a JSON value against a key definition.
    /// Returns null if valid, or an error message if invalid.
    /// </summary>
    public static string? Validate(string schluessel, JsonElement wert)
    {
        var def = Get(schluessel);
        if (def is null)
            return $"Unbekannter Konfigurationsschlüssel: {schluessel}";

        return def.Typ switch
        {
            ConfigValueType.String or ConfigValueType.Url or ConfigValueType.Locale or ConfigValueType.Color
                => wert.ValueKind == JsonValueKind.String ? null : "Wert muss ein String sein.",

            ConfigValueType.Encrypted
                => wert.ValueKind == JsonValueKind.String ? null : "Wert muss ein String sein.",

            ConfigValueType.Int => ValidateInt(wert, def),
            ConfigValueType.Float => ValidateFloat(wert, def),

            ConfigValueType.Bool
                => wert.ValueKind is JsonValueKind.True or JsonValueKind.False ? null : "Wert muss ein Boolean sein.",

            ConfigValueType.Enum => ValidateEnum(wert, def),

            ConfigValueType.StringArray or ConfigValueType.RoleArray
                => wert.ValueKind == JsonValueKind.Array ? null : "Wert muss ein Array sein.",

            ConfigValueType.Map
                => wert.ValueKind == JsonValueKind.Object ? null : "Wert muss ein Objekt sein.",

            _ => null
        };
    }

    private static string? ValidateInt(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind != JsonValueKind.Number || !wert.TryGetInt32(out var intVal))
            return "Wert muss eine Ganzzahl sein.";
        if (def.MinValue.HasValue && intVal < def.MinValue.Value)
            return $"Wert muss mindestens {def.MinValue.Value} sein.";
        if (def.MaxValue.HasValue && intVal > def.MaxValue.Value)
            return $"Wert darf maximal {def.MaxValue.Value} sein.";
        return null;
    }

    private static string? ValidateFloat(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind != JsonValueKind.Number || !wert.TryGetDouble(out var dblVal))
            return "Wert muss eine Zahl sein.";
        if (def.MinFloat.HasValue && dblVal < def.MinFloat.Value)
            return $"Wert muss mindestens {def.MinFloat.Value} sein.";
        if (def.MaxFloat.HasValue && dblVal > def.MaxFloat.Value)
            return $"Wert darf maximal {def.MaxFloat.Value} sein.";
        return null;
    }

    private static string? ValidateEnum(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind == JsonValueKind.Null && def.AllowedValues?.Contains("null") == true)
            return null;
        if (wert.ValueKind != JsonValueKind.String)
            return "Wert muss ein String sein.";
        if (def.AllowedValues is not null && !def.AllowedValues.Contains(wert.GetString()))
            return $"Wert muss einer von [{string.Join(", ", def.AllowedValues)}] sein.";
        return null;
    }

    private static Dictionary<string, ConfigKeyDefinition> BuildRegistry()
    {
        var keys = new List<ConfigKeyDefinition>
        {
            // ── Kapelle-Ebene ─────────────────────────────────────────────
            new("kapelle.name", ConfigValueType.String, ConfigEbene.Kapelle, Json("\"\""), "Name der Kapelle"),
            new("kapelle.ort", ConfigValueType.String, ConfigEbene.Kapelle, Json("\"\""), "Standort"),
            new("kapelle.logo", ConfigValueType.Url, ConfigEbene.Kapelle, NullJson, "Logo-URL"),
            new("kapelle.sprache", ConfigValueType.Locale, ConfigEbene.Kapelle, Json("\"de\""), "Standard-Sprache"),
            new("kapelle.ai.provider", ConfigValueType.Enum, ConfigEbene.Kapelle, NullJson, "AI-Provider",
                ["azure_vision", "openai_vision", "google_vision", "null"]),
            new("kapelle.ai.api_key", ConfigValueType.Encrypted, ConfigEbene.Kapelle, NullJson, "AI-API-Key"),
            new("kapelle.ai.enabled", ConfigValueType.Bool, ConfigEbene.Kapelle, FalseJson, "AI-Features aktiviert"),
            new("kapelle.berechtigungen.noten_upload", ConfigValueType.RoleArray, ConfigEbene.Kapelle,
                Json("[\"Administrator\",\"Dirigent\",\"Notenwart\"]"), "Noten-Upload-Berechtigungen"),
            new("kapelle.berechtigungen.setlist_erstellen", ConfigValueType.RoleArray, ConfigEbene.Kapelle,
                Json("[\"Administrator\",\"Dirigent\",\"Notenwart\"]"), "Setlist-Erstellen-Berechtigungen"),
            new("kapelle.berechtigungen.termine_erstellen", ConfigValueType.RoleArray, ConfigEbene.Kapelle,
                Json("[\"Administrator\",\"Dirigent\"]"), "Termin-Erstellen-Berechtigungen"),
            new("kapelle.berechtigungen.annotation_stimme", ConfigValueType.RoleArray, ConfigEbene.Kapelle,
                Json("[\"Administrator\",\"Dirigent\",\"Registerführer\"]"), "Stimmen-Annotation-Berechtigungen"),
            new("kapelle.berechtigungen.annotation_orchester", ConfigValueType.RoleArray, ConfigEbene.Kapelle,
                Json("[\"Administrator\",\"Dirigent\"]"), "Orchester-Annotation-Berechtigungen"),
            new("kapelle.kammerton", ConfigValueType.Int, ConfigEbene.Kapelle, Json("442"), "Kammerton in Hz",
                MinValue: 415, MaxValue: 466),
            new("kapelle.metronom.default_bpm", ConfigValueType.Int, ConfigEbene.Kapelle, Json("120"), "Standard-BPM",
                MinValue: 20, MaxValue: 300),
            new("kapelle.aushilfe.default_ablauf_tage", ConfigValueType.Int, ConfigEbene.Kapelle, Json("7"),
                "Gültigkeit Aushilfe-Links in Tagen", MinValue: 1, MaxValue: 30),

            // ── Policy-Ebene ──────────────────────────────────────────────
            new("policy.force_locale", ConfigValueType.Bool, ConfigEbene.Policy, FalseJson,
                "Sprache kann nicht pro Nutzer überschrieben werden"),
            new("policy.force_dark_mode", ConfigValueType.Enum, ConfigEbene.Policy, NullJson,
                "null=frei, true=dark erzwungen, false=light erzwungen",
                ["true", "false", "null"]),
            new("policy.allow_user_ai_keys", ConfigValueType.Bool, ConfigEbene.Policy, TrueJson,
                "Ob Nutzer eigene AI-Keys verwenden dürfen"),
            new("policy.force_kammerton", ConfigValueType.Bool, ConfigEbene.Policy, FalseJson,
                "Kammerton kann nicht pro Gerät überschrieben werden"),
            new("policy.min_annotation_layer", ConfigValueType.Enum, ConfigEbene.Policy, Json("\"privat\""),
                "Mindest-Sichtbarkeit", ["privat", "stimme", "orchester"]),

            // ── Nutzer-Ebene ──────────────────────────────────────────────
            new("nutzer.sprache", ConfigValueType.Locale, ConfigEbene.Nutzer, Json("\"de\""), "Bevorzugte Sprache"),
            new("nutzer.theme", ConfigValueType.Enum, ConfigEbene.Nutzer, Json("\"system\""), "Theme",
                ["dark", "light", "system"]),
            new("nutzer.instrumente", ConfigValueType.StringArray, ConfigEbene.Nutzer, Json("[]"),
                "Gespielte Instrumente"),
            new("nutzer.std_stimme", ConfigValueType.Map, ConfigEbene.Nutzer, Json("{}"),
                "Standard-Stimme pro Kapelle"),
            new("nutzer.ai.provider", ConfigValueType.Enum, ConfigEbene.Nutzer, NullJson, "Persönlicher AI-Provider",
                ["azure_vision", "openai_vision", "google_vision", "null"]),
            new("nutzer.ai.api_key", ConfigValueType.Encrypted, ConfigEbene.Nutzer, NullJson,
                "Persönlicher AI-API-Key"),
            new("nutzer.benachrichtigungen.termine", ConfigValueType.Bool, ConfigEbene.Nutzer, TrueJson,
                "Push für Termine"),
            new("nutzer.benachrichtigungen.noten_neu", ConfigValueType.Bool, ConfigEbene.Nutzer, TrueJson,
                "Push für neue Noten"),
            new("nutzer.benachrichtigungen.annotation_update", ConfigValueType.Bool, ConfigEbene.Nutzer, TrueJson,
                "Push für Orchester-Annotationen"),
            new("nutzer.spielmodus.half_page_turn", ConfigValueType.Bool, ConfigEbene.Nutzer, TrueJson,
                "Half-Page-Turn aktiviert"),
            new("nutzer.spielmodus.half_page_ratio", ConfigValueType.Float, ConfigEbene.Nutzer, Json("0.5"),
                "Teilungsverhältnis", MinFloat: 0.3, MaxFloat: 0.7),
            new("nutzer.spielmodus.swipe_richtung", ConfigValueType.Enum, ConfigEbene.Nutzer,
                Json("\"horizontal\""), "Swipe-Richtung", ["horizontal", "vertikal"]),
            new("nutzer.annotation.default_farbe", ConfigValueType.Color, ConfigEbene.Nutzer,
                Json("\"#FF0000\""), "Standard-Stiftfarbe"),
            new("nutzer.annotation.default_dicke", ConfigValueType.Int, ConfigEbene.Nutzer, Json("3"),
                "Standard-Stiftstärke in px", MinValue: 1, MaxValue: 20),
            new("nutzer.cloud_sync.aktiv", ConfigValueType.Bool, ConfigEbene.Nutzer, FalseJson,
                "Persönliche Sammlung synchronisieren"),
        };

        return keys.ToDictionary(k => k.Schluessel);
    }
}
