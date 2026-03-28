using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace Sheetstorm.Domain.Config;

// ── Requests ──────────────────────────────────────────────────────────────────

public record ConfigWertSetzenRequest(
    [Required] JsonElement Wert
);

public record ConfigSyncRequest(
    [Required] IReadOnlyList<ConfigSyncEintrag> Changes
);

public record ConfigSyncEintrag(
    [Required] string Schluessel,
    [Required] JsonElement Wert,
    long Version,
    DateTime Zeitstempel
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record ConfigEintragResponse(
    string Schluessel,
    JsonElement Wert,
    DateTime AktualisiertAm
);

public record ConfigNutzerEintragResponse(
    string Schluessel,
    JsonElement Wert,
    long Version,
    DateTime AktualisiertAm
);

public record ConfigPolicyEintragResponse(
    string Schluessel,
    JsonElement Wert,
    DateTime AktualisiertAm
);

public record ConfigAenderungResponse(
    bool Success,
    JsonElement? AlterWert,
    JsonElement NeuerWert,
    DateTime Zeitstempel
);

public record ConfigResolvedEintrag(
    string Schluessel,
    JsonElement Wert,
    string Ebene,
    bool PolicyEnforced
);

public record ConfigSyncResponse(
    IReadOnlyList<ConfigSyncApplied> Applied,
    IReadOnlyList<ConfigNutzerEintragResponse> ServerChanges,
    IReadOnlyList<ConfigSyncConflict> Conflicts
);

public record ConfigSyncApplied(
    string Schluessel,
    long NeueVersion
);

public record ConfigSyncConflict(
    string Schluessel,
    JsonElement ServerWert,
    long ServerVersion,
    string Grund
);

public record ConfigAuditEintragResponse(
    Guid Id,
    string Ebene,
    string Schluessel,
    JsonElement? AlterWert,
    JsonElement? NeuerWert,
    Guid? MusikerId,
    DateTime Zeitstempel
);
