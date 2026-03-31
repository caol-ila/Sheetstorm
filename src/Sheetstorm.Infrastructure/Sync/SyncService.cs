using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Sync;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Sync;

public class SyncService(AppDbContext db) : ISyncService
{
    private const int PageSize = 200;

    // ── GET /api/sync/state ───────────────────────────────────────────────────────

    public async Task<SyncStateResponse> GetStateAsync(Guid musicianId, CancellationToken ct)
    {
        var sv = await db.SyncVersions.FindAsync([musicianId], ct);
        var pendingCount = await db.SyncChangelogs
            .CountAsync(c => c.MusicianId == musicianId, ct);

        return new SyncStateResponse(
            CurrentVersion: sv?.CurrentVersion ?? 0,
            LastSyncAt: sv?.LastSyncAt,
            PendingServerChanges: pendingCount);
    }

    // ── POST /api/sync/pull ───────────────────────────────────────────────────────

    public async Task<PullResponse> PullAsync(Guid musicianId, PullRequest request, CancellationToken ct)
    {
        var entries = await db.SyncChangelogs
            .Where(c => c.MusicianId == musicianId && c.Version > request.SinceVersion)
            .OrderBy(c => c.Version)
            .Take(PageSize + 1)
            .ToListAsync(ct);

        var hasMore = entries.Count > PageSize;
        var page = entries.Take(PageSize).Select(MapToEntry).ToList();

        var sv = await db.SyncVersions.FindAsync([musicianId], ct);

        return new PullResponse(page, sv?.CurrentVersion ?? 0, hasMore);
    }

    // ── POST /api/sync/push ───────────────────────────────────────────────────────

    public async Task<PushResponse> PushAsync(Guid musicianId, PushRequest request, CancellationToken ct)
    {
        var sv = await GetOrCreateSyncVersionAsync(musicianId, ct);

        var accepted = new List<AcceptedChange>();
        var conflicts = new List<ConflictEntry>();

        // Batch-load existing changelogs for conflict detection (avoid N+1 per change)
        var updateChanges = request.Changes
            .Where(c => c.Operation == "Update" && c.FieldName is not null && c.EntityId is not null)
            .ToList();

        var relevantEntityIds = updateChanges.Select(c => c.EntityId!.Value).Distinct().ToList();
        var relevantFieldNames = updateChanges.Select(c => c.FieldName!).Distinct().ToList();

        var existingChangelogs = relevantEntityIds.Count > 0
            ? await db.SyncChangelogs
                .Where(c => c.MusicianId == musicianId
                          && relevantEntityIds.Contains(c.EntityId)
                          && c.FieldName != null && relevantFieldNames.Contains(c.FieldName)
                          && c.Operation == "Update")
                .GroupBy(c => new { c.EntityId, c.FieldName })
                .Select(g => g.OrderByDescending(c => c.ChangedAt).First())
                .ToListAsync(ct)
            : [];

        var changelogLookup = existingChangelogs.ToDictionary(
            c => (c.EntityId, c.FieldName!),
            c => c);

        var now = DateTime.UtcNow;

        foreach (var change in request.Changes)
        {
            // Conflict check only applies to Update operations on a specific field
            if (change.Operation == "Update"
                && change.FieldName is not null
                && change.EntityId is not null)
            {
                if (changelogLookup.TryGetValue((change.EntityId.Value, change.FieldName), out var existingChange)
                    && existingChange.ChangedAt > now)
                {
                    // Server has a newer change — ServerWins
                    conflicts.Add(new ConflictEntry(
                        ClientChangeId: change.ClientChangeId,
                        EntityType: change.EntityType,
                        EntityId: change.EntityId.Value,
                        FieldName: change.FieldName,
                        ClientValue: change.NewValue,
                        ServerValue: existingChange.NewValue,
                        ServerChangedAt: existingChange.ChangedAt,
                        Resolution: "ServerWins"));
                    continue;
                }
            }

            // Accept the change — server sets the authoritative timestamp
            sv.CurrentVersion++;
            var entityId = change.EntityId ?? Guid.NewGuid();

            var storedValue = change.NewValue
                ?? (change.Fields is not null ? JsonSerializer.Serialize(change.Fields) : null);

            db.SyncChangelogs.Add(new SyncChangelog
            {
                MusicianId = musicianId,
                EntityType = change.EntityType,
                EntityId = entityId,
                Operation = change.Operation,
                FieldName = change.FieldName,
                NewValue = storedValue,
                ChangedAt = now,
                Version = sv.CurrentVersion
            });

            accepted.Add(new AcceptedChange(change.ClientChangeId, sv.CurrentVersion, entityId));
        }

        sv.LastSyncAt = now;
        await db.SaveChangesAsync(ct);

        return new PushResponse(accepted, conflicts, sv.CurrentVersion);
    }

    // ── POST /api/sync/resolve ────────────────────────────────────────────────────

    public async Task ResolveAsync(Guid musicianId, ResolveRequest request, CancellationToken ct)
    {
        var sv = await GetOrCreateSyncVersionAsync(musicianId, ct);

        foreach (var resolution in request.Resolutions)
        {
            sv.CurrentVersion++;

            db.SyncChangelogs.Add(new SyncChangelog
            {
                MusicianId = musicianId,
                EntityType = "Resolved",
                EntityId = resolution.EntityId,
                Operation = "Update",
                FieldName = resolution.FieldName,
                NewValue = resolution.ChosenValue,
                ChangedAt = resolution.ChosenAt,
                Version = sv.CurrentVersion
            });
        }

        sv.LastSyncAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────────

    private async Task<SyncVersion> GetOrCreateSyncVersionAsync(Guid musicianId, CancellationToken ct)
    {
        var sv = await db.SyncVersions.FindAsync([musicianId], ct);
        if (sv is null)
        {
            sv = new SyncVersion { MusicianId = musicianId };
            db.SyncVersions.Add(sv);
        }
        return sv;
    }

    private static SyncChangeEntry MapToEntry(SyncChangelog c)
    {
        Dictionary<string, string>? fields = null;
        if (c.Operation == "Create" && c.NewValue is not null)
        {
            try
            {
                fields = JsonSerializer.Deserialize<Dictionary<string, string>>(c.NewValue);
            }
            catch (JsonException)
            {
                // Not JSON — leave fields null
            }
        }

        return new SyncChangeEntry(
            Version: c.Version,
            EntityType: c.EntityType,
            EntityId: c.EntityId,
            Operation: c.Operation,
            FieldName: c.FieldName,
            NewValue: c.Operation != "Create" ? c.NewValue : null,
            Fields: fields,
            ChangedAt: c.ChangedAt);
    }
}
