namespace Sheetstorm.Domain.Sync;

// ── Sync State ────────────────────────────────────────────────────────────────

/// <summary>Response for GET /api/sync/state</summary>
public record SyncStateResponse(
    long CurrentVersion,
    DateTime? LastSyncAt,
    int PendingServerChanges);

// ── Pull ──────────────────────────────────────────────────────────────────────

/// <summary>Request body for POST /api/sync/pull</summary>
public record PullRequest(long SinceVersion);

/// <summary>A single change entry returned in a pull response.</summary>
public record SyncChangeEntry(
    long Version,
    string EntityType,
    Guid EntityId,
    string Operation,
    string? FieldName,
    string? NewValue,
    Dictionary<string, string>? Fields,
    DateTime ChangedAt);

/// <summary>Response for POST /api/sync/pull</summary>
public record PullResponse(
    IReadOnlyList<SyncChangeEntry> Changes,
    long CurrentVersion,
    bool HasMore);

// ── Push ──────────────────────────────────────────────────────────────────────

/// <summary>A single change in a push request.</summary>
public record PushChangeEntry(
    string ClientChangeId,
    string EntityType,
    Guid? EntityId,
    string Operation,
    string? FieldName,
    string? NewValue,
    Dictionary<string, string>? Fields,
    DateTime ChangedAt);

/// <summary>Request body for POST /api/sync/push</summary>
public record PushRequest(long BaseVersion, IReadOnlyList<PushChangeEntry> Changes);

/// <summary>An accepted change returned in a push response.</summary>
public record AcceptedChange(
    string ClientChangeId,
    long ServerVersion,
    Guid ServerEntityId);

/// <summary>A conflict returned when a push change loses LWW resolution.</summary>
public record ConflictEntry(
    string ClientChangeId,
    string EntityType,
    Guid EntityId,
    string? FieldName,
    string? ClientValue,
    string? ServerValue,
    DateTime ServerChangedAt,
    string Resolution);  // "ServerWins" | "ClientWins"

/// <summary>Response for POST /api/sync/push</summary>
public record PushResponse(
    IReadOnlyList<AcceptedChange> Accepted,
    IReadOnlyList<ConflictEntry> Conflicts,
    long NewVersion);

// ── Resolve ───────────────────────────────────────────────────────────────────

/// <summary>Request body for POST /api/sync/resolve (explicit conflict resolution).</summary>
public record ResolveRequest(IReadOnlyList<ResolveEntry> Resolutions);

public record ResolveEntry(
    Guid EntityId,
    string FieldName,
    string ChosenValue,
    DateTime ChosenAt);
