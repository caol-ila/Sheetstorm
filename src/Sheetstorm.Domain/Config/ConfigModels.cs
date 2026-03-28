using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace Sheetstorm.Domain.Config;

// ── Requests ──────────────────────────────────────────────────────────────────

public record SetConfigValueRequest(
    [Required] JsonElement Value
);

public record ConfigSyncRequest(
    [Required] IReadOnlyList<ConfigSyncEntry> Changes
);

public record ConfigSyncEntry(
    [Required] string Key,
    [Required] JsonElement Value,
    long Version,
    DateTime Timestamp
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record ConfigEntryResponse(
    string Key,
    JsonElement Value,
    DateTime UpdatedAt
);

public record ConfigUserEntryResponse(
    string Key,
    JsonElement Value,
    long Version,
    DateTime UpdatedAt
);

public record ConfigPolicyEntryResponse(
    string Key,
    JsonElement Value,
    DateTime UpdatedAt
);

public record ConfigChangeResponse(
    bool Success,
    JsonElement? OldValue,
    JsonElement NewValue,
    DateTime Timestamp
);

public record ConfigResolvedEntry(
    string Key,
    JsonElement Value,
    string Level,
    bool PolicyEnforced
);

public record ConfigSyncResponse(
    IReadOnlyList<ConfigSyncApplied> Applied,
    IReadOnlyList<ConfigUserEntryResponse> ServerChanges,
    IReadOnlyList<ConfigSyncConflict> Conflicts
);

public record ConfigSyncApplied(
    string Key,
    long NewVersion
);

public record ConfigSyncConflict(
    string Key,
    JsonElement ServerValue,
    long ServerVersion,
    string Grund
);

public record ConfigAuditEntryResponse(
    Guid Id,
    string Level,
    string Key,
    JsonElement? OldValue,
    JsonElement? NewValue,
    Guid? MusicianId,
    DateTime Timestamp
);
