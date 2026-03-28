using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Config;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Config;

public class ConfigService(AppDbContext db) : IConfigService
{
    // ── Band Config ────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigEntryResponse>> GetBandConfigAsync(Guid bandId, Guid musicianId)
    {
        await RequireMembershipAsync(bandId, musicianId);

        var entries = await db.ConfigBand
            .Where(c => c.BandId == bandId)
            .Select(c => new ConfigEntryResponse(
                c.Key,
                JsonDocument.Parse(c.Value).RootElement,
                c.UpdatedAt))
            .ToListAsync();

        return entries;
    }

    public async Task<ConfigChangeResponse> SetBandConfigAsync(
        Guid bandId, string schluessel, SetConfigValueRequest request, Guid musicianId)
    {
        await RequireAdminAsync(bandId, musicianId);

        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Level != ConfigKeyRegistry.ConfigLevel.Band)
            throw new DomainException("INVALID_CONFIG_KEY",
                $"Ungültiger Konfigurationsschlüssel für Band-Level: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Value);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var valueJson = request.Value.GetRawText();
        var existing = await db.ConfigBand
            .FirstOrDefaultAsync(c => c.BandId == bandId && c.Key == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Value).RootElement;
            existing.Value = valueJson;
            existing.UpdatedById = musicianId;
        }
        else
        {
            db.ConfigBand.Add(new ConfigBand
            {
                BandId = bandId,
                Key = schluessel,
                Value = valueJson,
                UpdatedById = musicianId
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            BandId = bandId,
            MusicianId = musicianId,
            Level = "band",
            Key = schluessel,
            OldValue = alterWert?.GetRawText(),
            NewValue = valueJson
        });

        await db.SaveChangesAsync();

        return new ConfigChangeResponse(true, alterWert, request.Value, DateTime.UtcNow);
    }

    public async Task DeleteBandConfigAsync(Guid bandId, string schluessel, Guid musicianId)
    {
        await RequireAdminAsync(bandId, musicianId);

        var existing = await db.ConfigBand
            .FirstOrDefaultAsync(c => c.BandId == bandId && c.Key == schluessel);

        if (existing is null)
            throw new DomainException("CONFIG_NOT_FOUND", $"Configuration '{schluessel}' not found.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            BandId = bandId,
            MusicianId = musicianId,
            Level = "band",
            Key = schluessel,
            OldValue = existing.Value,
            NewValue = null
        });

        db.ConfigBand.Remove(existing);
        await db.SaveChangesAsync();
    }

    // ── Policies ──────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigPolicyEntryResponse>> GetPoliciesAsync(Guid bandId, Guid musicianId)
    {
        await RequireAdminAsync(bandId, musicianId);

        return await db.ConfigPolicies
            .Where(p => p.BandId == bandId)
            .Select(p => new ConfigPolicyEntryResponse(
                p.Key,
                JsonDocument.Parse(p.Value).RootElement,
                p.UpdatedAt))
            .ToListAsync();
    }

    public async Task<ConfigChangeResponse> SetPolicyAsync(
        Guid bandId, string schluessel, SetConfigValueRequest request, Guid musicianId)
    {
        await RequireAdminAsync(bandId, musicianId);

        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Level != ConfigKeyRegistry.ConfigLevel.Policy)
            throw new DomainException("INVALID_POLICY_KEY",
                $"Invalid policy key: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Value);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var valueJson = request.Value.GetRawText();
        var existing = await db.ConfigPolicies
            .FirstOrDefaultAsync(p => p.BandId == bandId && p.Key == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Value).RootElement;
            existing.Value = valueJson;
            existing.UpdatedById = musicianId;
        }
        else
        {
            db.ConfigPolicies.Add(new ConfigPolicy
            {
                BandId = bandId,
                Key = schluessel,
                Value = valueJson,
                UpdatedById = musicianId
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            BandId = bandId,
            MusicianId = musicianId,
            Level = "policy",
            Key = schluessel,
            OldValue = alterWert?.GetRawText(),
            NewValue = valueJson
        });

        await db.SaveChangesAsync();

        return new ConfigChangeResponse(true, alterWert, request.Value, DateTime.UtcNow);
    }

    public async Task DeletePolicyAsync(Guid bandId, string schluessel, Guid musicianId)
    {
        await RequireAdminAsync(bandId, musicianId);

        var existing = await db.ConfigPolicies
            .FirstOrDefaultAsync(p => p.BandId == bandId && p.Key == schluessel);

        if (existing is null)
            throw new DomainException("POLICY_NOT_FOUND", $"Policy '{schluessel}' not found.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            BandId = bandId,
            MusicianId = musicianId,
            Level = "policy",
            Key = schluessel,
            OldValue = existing.Value,
            NewValue = null
        });

        db.ConfigPolicies.Remove(existing);
        await db.SaveChangesAsync();
    }

    // ── Nutzer Config ─────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigUserEntryResponse>> GetUserConfigAsync(Guid musicianId)
    {
        return await db.ConfigUser
            .Where(c => c.MusicianId == musicianId)
            .Select(c => new ConfigUserEntryResponse(
                c.Key,
                JsonDocument.Parse(c.Value).RootElement,
                c.Version,
                c.UpdatedAt))
            .ToListAsync();
    }

    public async Task<ConfigChangeResponse> SetUserConfigAsync(
        Guid musicianId, string schluessel, SetConfigValueRequest request)
    {
        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Level != ConfigKeyRegistry.ConfigLevel.Nutzer)
            throw new DomainException("INVALID_CONFIG_KEY",
                $"Ungültiger Konfigurationsschlüssel für Nutzer-Level: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Value);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var valueJson = request.Value.GetRawText();
        var existing = await db.ConfigUser
            .FirstOrDefaultAsync(c => c.MusicianId == musicianId && c.Key == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Value).RootElement;
            existing.Value = valueJson;
            existing.Version++;
        }
        else
        {
            db.ConfigUser.Add(new ConfigUser
            {
                MusicianId = musicianId,
                Key = schluessel,
                Value = valueJson,
                Version = 1
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            MusicianId = musicianId,
            Level = "user",
            Key = schluessel,
            OldValue = alterWert?.GetRawText(),
            NewValue = valueJson
        });

        await db.SaveChangesAsync();

        return new ConfigChangeResponse(true, alterWert, request.Value, DateTime.UtcNow);
    }

    public async Task DeleteUserConfigAsync(Guid musicianId, string schluessel)
    {
        var existing = await db.ConfigUser
            .FirstOrDefaultAsync(c => c.MusicianId == musicianId && c.Key == schluessel);

        if (existing is null)
            throw new DomainException("CONFIG_NOT_FOUND", $"Configuration '{schluessel}' not found.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            MusicianId = musicianId,
            Level = "user",
            Key = schluessel,
            OldValue = existing.Value,
            NewValue = null
        });

        db.ConfigUser.Remove(existing);
        await db.SaveChangesAsync();
    }

    public async Task<ConfigSyncResponse> SyncUserConfigAsync(Guid musicianId, ConfigSyncRequest request)
    {
        var applied = new List<ConfigSyncApplied>();
        var conflicts = new List<ConfigSyncConflict>();

        var existingEntries = await db.ConfigUser
            .Where(c => c.MusicianId == musicianId)
            .ToDictionaryAsync(c => c.Key);

        foreach (var change in request.Changes)
        {
            var def = ConfigKeyRegistry.Get(change.Key);
            if (def is null || def.Level != ConfigKeyRegistry.ConfigLevel.Nutzer)
                continue; // Skip unknown keys silently

            var validationError = ConfigKeyRegistry.Validate(change.Key, change.Value);
            if (validationError is not null)
                continue; // Skip invalid values

            var valueJson = change.Value.GetRawText();

            if (existingEntries.TryGetValue(change.Key, out var existing))
            {
                if (change.Version > existing.Version)
                {
                    // Client version is newer — client wins
                    existing.Value = valueJson;
                    existing.Version = change.Version;
                    applied.Add(new ConfigSyncApplied(change.Key, existing.Version));
                }
                else if (change.Version < existing.Version)
                {
                    // Server version is newer — conflict, server wins
                    conflicts.Add(new ConfigSyncConflict(
                        change.Key,
                        JsonDocument.Parse(existing.Value).RootElement,
                        existing.Version,
                        "Server has newer version"));
                }
                else
                {
                    // Same version — use timestamp as tiebreaker (Last-Write-Wins)
                    if (change.Timestamp > existing.UpdatedAt)
                    {
                        existing.Value = valueJson;
                        existing.Version++;
                        applied.Add(new ConfigSyncApplied(change.Key, existing.Version));
                    }
                    else
                    {
                        conflicts.Add(new ConfigSyncConflict(
                            change.Key,
                            JsonDocument.Parse(existing.Value).RootElement,
                            existing.Version,
                            "Server timestamp is newer"));
                    }
                }
            }
            else
            {
                // New entry from client
                var newEntry = new ConfigUser
                {
                    MusicianId = musicianId,
                    Key = change.Key,
                    Value = valueJson,
                    Version = Math.Max(change.Version, 1)
                };
                db.ConfigUser.Add(newEntry);
                applied.Add(new ConfigSyncApplied(change.Key, newEntry.Version));
            }
        }

        await db.SaveChangesAsync();

        // Return all server-side entries as server changes for full sync
        var serverEntries = await db.ConfigUser
            .Where(c => c.MusicianId == musicianId)
            .Select(c => new ConfigUserEntryResponse(
                c.Key,
                JsonDocument.Parse(c.Value).RootElement,
                c.Version,
                c.UpdatedAt))
            .ToListAsync();

        return new ConfigSyncResponse(applied, serverEntries, conflicts);
    }

    // ── Resolved Config ───────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigResolvedEntry>> GetResolvedConfigAsync(
        Guid bandId, Guid musicianId)
    {
        await RequireMembershipAsync(bandId, musicianId);

        // Load all 3 levels in parallel
        var bandConfigTask = db.ConfigBand
            .Where(c => c.BandId == bandId)
            .ToDictionaryAsync(c => c.Key, c => c.Value);

        var userConfigTask = db.ConfigUser
            .Where(c => c.MusicianId == musicianId)
            .ToDictionaryAsync(c => c.Key, c => c.Value);

        var policiesTask = db.ConfigPolicies
            .Where(p => p.BandId == bandId)
            .ToDictionaryAsync(p => p.Key, p => p.Value);

        await Task.WhenAll(bandConfigTask, userConfigTask, policiesTask);

        var bandConfig = bandConfigTask.Result;
        var userConfig = userConfigTask.Result;
        var policies = policiesTask.Result;

        // Build set of enforced nutzer keys from active policies
        var enforcedUserKeys = new HashSet<string>();
        foreach (var (policyKey, policyValue) in policies)
        {
            if (!IsPolicyEnforced(policyKey, policyValue))
                continue;

            if (ConfigKeyRegistry.PolicyAffectedKeys.TryGetValue(policyKey, out var affected))
            {
                foreach (var key in affected)
                    enforcedUserKeys.Add(key);
            }
        }

        var result = new List<ConfigResolvedEntry>();

        // Resolve all known keys
        foreach (var def in ConfigKeyRegistry.AllKeys.Values)
        {
            if (def.Level == ConfigKeyRegistry.ConfigLevel.Policy)
                continue; // Policies are not part of resolved config directly

            var (wert, ebene, policyEnforced) = ResolveKey(
                def, bandConfig, userConfig, enforcedUserKeys);

            result.Add(new ConfigResolvedEntry(def.Key, wert, ebene, policyEnforced));
        }

        // Include policies as separate entries for client awareness
        foreach (var def in ConfigKeyRegistry.GetByEbene(ConfigKeyRegistry.ConfigLevel.Policy))
        {
            var wert = policies.TryGetValue(def.Key, out var policyValue)
                ? JsonDocument.Parse(policyValue).RootElement
                : def.DefaultValue;

            result.Add(new ConfigResolvedEntry(def.Key, wert, "policy", false));
        }

        return result;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static (JsonElement Value, string Level, bool PolicyEnforced) ResolveKey(
        ConfigKeyRegistry.ConfigKeyDefinition def,
        Dictionary<string, string> bandConfig,
        Dictionary<string, string> userConfig,
        HashSet<string> enforcedUserKeys)
    {
        bool policyEnforced = enforcedUserKeys.Contains(def.Key);

        // If policy enforces this key, only use Band value or default
        if (policyEnforced)
        {
            if (def.Level == ConfigKeyRegistry.ConfigLevel.Band && bandConfig.TryGetValue(def.Key, out var bandVal))
                return (JsonDocument.Parse(bandVal).RootElement, "Band", true);

            return (def.DefaultValue, "default", true);
        }

        // Override chain: Nutzer > Band > Default (no Gerät on server side)
        if (def.Level == ConfigKeyRegistry.ConfigLevel.Nutzer && userConfig.TryGetValue(def.Key, out var nutzerVal))
            return (JsonDocument.Parse(nutzerVal).RootElement, "user", false);

        if (def.Level == ConfigKeyRegistry.ConfigLevel.Band && bandConfig.TryGetValue(def.Key, out var kapelleVal))
            return (JsonDocument.Parse(kapelleVal).RootElement, "Band", false);

        // For nutzer keys, also check Band (e.g. nutzer.sprache falls back to Band.sprache)
        if (def.Level == ConfigKeyRegistry.ConfigLevel.Nutzer)
        {
            var kapelleEquivalent = def.Key.Replace("user.", "band.");
            if (bandConfig.TryGetValue(kapelleEquivalent, out var kapelleFallback))
                return (JsonDocument.Parse(kapelleFallback).RootElement, "Band", false);
        }

        return (def.DefaultValue, "default", false);
    }

    private static bool IsPolicyEnforced(string policyKey, string policyValueJson)
    {
        try
        {
            using var doc = JsonDocument.Parse(policyValueJson);
            var el = doc.RootElement;

            return policyKey switch
            {
                // Bool policies: enforced when true
                "policy.force_locale" or "policy.force_kammerton" => el.ValueKind == JsonValueKind.True,

                // force_dark_mode: enforced when NOT null (true or false means forced)
                "policy.force_dark_mode" => el.ValueKind != JsonValueKind.Null,

                // allow_user_ai_keys: enforced when FALSE (blocks user keys)
                "policy.allow_user_ai_keys" => el.ValueKind == JsonValueKind.False,

                // min_annotation_layer: enforced when not "privat" (the default/least restrictive)
                "policy.min_annotation_layer" => el.ValueKind == JsonValueKind.String && el.GetString() != "privat",

                _ => false
            };
        }
        catch
        {
            return false;
        }
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId)
    {
        var m = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }

    private async Task<Membership> RequireAdminAsync(Guid bandId, Guid musicianId)
    {
        var m = await RequireMembershipAsync(bandId, musicianId);

        if (m.Role != MemberRole.Administrator)
            throw new AuthException("FORBIDDEN", "Only admins can perform this action.", 403);

        return m;
    }
}
