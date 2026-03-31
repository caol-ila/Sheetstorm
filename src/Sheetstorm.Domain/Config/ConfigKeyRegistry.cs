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

    public enum ConfigLevel
    {
        Band,
        Nutzer,
        Policy
    }

    public record ConfigKeyDefinition(
        string Key,
        ConfigValueType Typ,
        ConfigLevel Level,
        JsonElement DefaultValue,
        string? Description = null,
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

    public static IEnumerable<ConfigKeyDefinition> GetByEbene(ConfigLevel ebene)
        => _keys.Values.Where(k => k.Level == ebene);

    /// <summary>
    /// Maps policy keys to the config keys they enforce.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, string[]> PolicyAffectedKeys = new Dictionary<string, string[]>
    {
        ["policy.force_locale"] = ["user.language"],
        ["policy.force_dark_mode"] = ["user.theme"],
        ["policy.allow_user_ai_keys"] = ["user.ai.provider", "user.ai.api_key"],
        ["policy.force_kammerton"] = ["device.tuner.concert_pitch"],
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
            return $"Unknown configuration key: {schluessel}";

        return def.Typ switch
        {
            ConfigValueType.String or ConfigValueType.Url or ConfigValueType.Locale or ConfigValueType.Color
                => wert.ValueKind == JsonValueKind.String ? null : "Value must be a string.",

            ConfigValueType.Encrypted
                => wert.ValueKind == JsonValueKind.String ? null : "Value must be a string.",

            ConfigValueType.Int => ValidateInt(wert, def),
            ConfigValueType.Float => ValidateFloat(wert, def),

            ConfigValueType.Bool
                => wert.ValueKind is JsonValueKind.True or JsonValueKind.False ? null : "Value must be a boolean.",

            ConfigValueType.Enum => ValidateEnum(wert, def),

            ConfigValueType.StringArray or ConfigValueType.RoleArray
                => wert.ValueKind == JsonValueKind.Array ? null : "Value must be an array.",

            ConfigValueType.Map
                => wert.ValueKind == JsonValueKind.Object ? null : "Value must be an object.",

            _ => null
        };
    }

    private static string? ValidateInt(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind != JsonValueKind.Number || !wert.TryGetInt32(out var intVal))
            return "Value must be an integer.";
        if (def.MinValue.HasValue && intVal < def.MinValue.Value)
            return $"Value muss mindestens {def.MinValue.Value} sein.";
        if (def.MaxValue.HasValue && intVal > def.MaxValue.Value)
            return $"Value darf maximal {def.MaxValue.Value} sein.";
        return null;
    }

    private static string? ValidateFloat(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind != JsonValueKind.Number || !wert.TryGetDouble(out var dblVal))
            return "Value must be a number.";
        if (def.MinFloat.HasValue && dblVal < def.MinFloat.Value)
            return $"Value muss mindestens {def.MinFloat.Value} sein.";
        if (def.MaxFloat.HasValue && dblVal > def.MaxFloat.Value)
            return $"Value darf maximal {def.MaxFloat.Value} sein.";
        return null;
    }

    private static string? ValidateEnum(JsonElement wert, ConfigKeyDefinition def)
    {
        if (wert.ValueKind == JsonValueKind.Null && def.AllowedValues?.Contains("null") == true)
            return null;
        if (wert.ValueKind != JsonValueKind.String)
            return "Value must be a string.";
        if (def.AllowedValues is not null && !def.AllowedValues.Contains(wert.GetString()))
            return $"Value muss einer von [{string.Join(", ", def.AllowedValues)}] sein.";
        return null;
    }

    private static Dictionary<string, ConfigKeyDefinition> BuildRegistry()
    {
        var keys = new List<ConfigKeyDefinition>
        {
            // ── Band-Level ─────────────────────────────────────────────
            new("band.name", ConfigValueType.String, ConfigLevel.Band, Json("\"\""), "Band name"),
            new("band.location", ConfigValueType.String, ConfigLevel.Band, Json("\"\""), "Location"),
            new("band.logo", ConfigValueType.Url, ConfigLevel.Band, NullJson, "Logo URL"),
            new("band.language", ConfigValueType.Locale, ConfigLevel.Band, Json("\"de\""), "Default language"),
            new("band.ai.provider", ConfigValueType.Enum, ConfigLevel.Band, NullJson, "AI provider",
                ["azure_vision", "openai_vision", "google_vision", "null"]),
            new("band.ai.api_key", ConfigValueType.Encrypted, ConfigLevel.Band, NullJson, "AI API key"),
            new("band.ai.enabled", ConfigValueType.Bool, ConfigLevel.Band, FalseJson, "AI features enabled"),
            new("band.permissions.sheet_music_upload", ConfigValueType.RoleArray, ConfigLevel.Band,
                Json("[\"Administrator\",\"Dirigent\",\"Notenwart\"]"), "Sheet music upload permissions"),
            new("band.permissions.setlist_create", ConfigValueType.RoleArray, ConfigLevel.Band,
                Json("[\"Administrator\",\"Dirigent\",\"Notenwart\"]"), "Setlist creation permissions"),
            new("band.permissions.events_create", ConfigValueType.RoleArray, ConfigLevel.Band,
                Json("[\"Administrator\",\"Dirigent\"]"), "Event creation permissions"),
            new("band.permissions.annotation_voice", ConfigValueType.RoleArray, ConfigLevel.Band,
                Json("[\"Administrator\",\"Dirigent\",\"Registerführer\"]"), "Voice annotation permissions"),
            new("band.permissions.annotation_orchestra", ConfigValueType.RoleArray, ConfigLevel.Band,
                Json("[\"Administrator\",\"Dirigent\"]"), "Orchestra annotation permissions"),
            new("band.concert_pitch", ConfigValueType.Int, ConfigLevel.Band, Json("442"), "Concert pitch in Hz",
                MinValue: 415, MaxValue: 466),
            new("band.substitute.default_expiry_days", ConfigValueType.Int, ConfigLevel.Band, Json("7"),
                "Substitute link validity in days", MinValue: 1, MaxValue: 30),

            // ── Policy-Level ──────────────────────────────────────────────
            new("policy.force_locale", ConfigValueType.Bool, ConfigLevel.Policy, FalseJson,
                "Language cannot be overridden per user"),
            new("policy.force_dark_mode", ConfigValueType.Enum, ConfigLevel.Policy, NullJson,
                "null=free, true=dark forced, false=light forced",
                ["true", "false", "null"]),
            new("policy.allow_user_ai_keys", ConfigValueType.Bool, ConfigLevel.Policy, TrueJson,
                "Whether users can use their own AI keys"),
            new("policy.force_kammerton", ConfigValueType.Bool, ConfigLevel.Policy, FalseJson,
                "Concert pitch cannot be overridden per device"),
            new("policy.min_annotation_layer", ConfigValueType.Enum, ConfigLevel.Policy, Json("\"privat\""),
                "Minimum visibility", ["privat", "Voice", "orchester"]),

            // ── Nutzer-Level ──────────────────────────────────────────────
            new("user.language", ConfigValueType.Locale, ConfigLevel.Nutzer, Json("\"de\""), "Preferred language"),
            new("user.theme", ConfigValueType.Enum, ConfigLevel.Nutzer, Json("\"system\""), "Theme",
                ["dark", "light", "system"]),
            new("user.instruments", ConfigValueType.StringArray, ConfigLevel.Nutzer, Json("[]"),
                "Gespielte Instruments"),
            new("user.default_voice", ConfigValueType.Map, ConfigLevel.Nutzer, Json("{}"),
                "Default voice per band"),
            new("user.ai.provider", ConfigValueType.Enum, ConfigLevel.Nutzer, NullJson, "Personal AI provider",
                ["azure_vision", "openai_vision", "google_vision", "null"]),
            new("user.ai.api_key", ConfigValueType.Encrypted, ConfigLevel.Nutzer, NullJson,
                "Personal AI API key"),
            new("user.notifications.events", ConfigValueType.Bool, ConfigLevel.Nutzer, TrueJson,
                "Push for events"),
            new("user.notifications.new_sheet_music", ConfigValueType.Bool, ConfigLevel.Nutzer, TrueJson,
                "Push for new sheet music"),
            new("user.notifications.annotation_update", ConfigValueType.Bool, ConfigLevel.Nutzer, TrueJson,
                "Push for orchestra annotations"),
            new("user.performance_mode.half_page_turn", ConfigValueType.Bool, ConfigLevel.Nutzer, TrueJson,
                "Half-page-turn enabled"),
            new("user.performance_mode.half_page_ratio", ConfigValueType.Float, ConfigLevel.Nutzer, Json("0.5"),
                "Split ratio", MinFloat: 0.3, MaxFloat: 0.7),
            new("user.performance_mode.swipe_direction", ConfigValueType.Enum, ConfigLevel.Nutzer,
                Json("\"horizontal\""), "Swipe direction", ["horizontal", "vertikal"]),
            new("user.annotation.default_color", ConfigValueType.Color, ConfigLevel.Nutzer,
                Json("\"#FF0000\""), "Default pen color"),
            new("user.annotation.default_thickness", ConfigValueType.Int, ConfigLevel.Nutzer, Json("3"),
                "Default pen thickness in px", MinValue: 1, MaxValue: 20),
            new("user.cloud_sync.active", ConfigValueType.Bool, ConfigLevel.Nutzer, FalseJson,
                "Sync personal collection"),
        };

        return keys.ToDictionary(k => k.Key);
    }
}
