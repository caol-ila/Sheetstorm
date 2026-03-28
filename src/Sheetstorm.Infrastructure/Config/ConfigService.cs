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
    // ── Kapelle Config ────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigEintragResponse>> GetKapelleConfigAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        var entries = await db.ConfigKapelle
            .Where(c => c.KapelleId == kapelleId)
            .Select(c => new ConfigEintragResponse(
                c.Schluessel,
                JsonDocument.Parse(c.Wert).RootElement,
                c.UpdatedAt))
            .ToListAsync();

        return entries;
    }

    public async Task<ConfigAenderungResponse> SetKapelleConfigAsync(
        Guid kapelleId, string schluessel, ConfigWertSetzenRequest request, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Ebene != ConfigKeyRegistry.ConfigEbene.Kapelle)
            throw new DomainException("INVALID_CONFIG_KEY",
                $"Ungültiger Konfigurationsschlüssel für Kapelle-Ebene: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Wert);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var wertJson = request.Wert.GetRawText();
        var existing = await db.ConfigKapelle
            .FirstOrDefaultAsync(c => c.KapelleId == kapelleId && c.Schluessel == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Wert).RootElement;
            existing.Wert = wertJson;
            existing.AktualisiertVonId = musikerId;
        }
        else
        {
            db.ConfigKapelle.Add(new ConfigKapelle
            {
                KapelleId = kapelleId,
                Schluessel = schluessel,
                Wert = wertJson,
                AktualisiertVonId = musikerId
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            KapelleId = kapelleId,
            MusikerId = musikerId,
            Ebene = "kapelle",
            Schluessel = schluessel,
            AlterWert = alterWert?.GetRawText(),
            NeuerWert = wertJson
        });

        await db.SaveChangesAsync();

        return new ConfigAenderungResponse(true, alterWert, request.Wert, DateTime.UtcNow);
    }

    public async Task DeleteKapelleConfigAsync(Guid kapelleId, string schluessel, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var existing = await db.ConfigKapelle
            .FirstOrDefaultAsync(c => c.KapelleId == kapelleId && c.Schluessel == schluessel);

        if (existing is null)
            throw new DomainException("CONFIG_NOT_FOUND", $"Konfiguration '{schluessel}' nicht gefunden.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            KapelleId = kapelleId,
            MusikerId = musikerId,
            Ebene = "kapelle",
            Schluessel = schluessel,
            AlterWert = existing.Wert,
            NeuerWert = null
        });

        db.ConfigKapelle.Remove(existing);
        await db.SaveChangesAsync();
    }

    // ── Policies ──────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigPolicyEintragResponse>> GetPoliciesAsync(Guid kapelleId, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        return await db.ConfigPolicies
            .Where(p => p.KapelleId == kapelleId)
            .Select(p => new ConfigPolicyEintragResponse(
                p.Schluessel,
                JsonDocument.Parse(p.Wert).RootElement,
                p.UpdatedAt))
            .ToListAsync();
    }

    public async Task<ConfigAenderungResponse> SetPolicyAsync(
        Guid kapelleId, string schluessel, ConfigWertSetzenRequest request, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Ebene != ConfigKeyRegistry.ConfigEbene.Policy)
            throw new DomainException("INVALID_POLICY_KEY",
                $"Ungültiger Policy-Schlüssel: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Wert);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var wertJson = request.Wert.GetRawText();
        var existing = await db.ConfigPolicies
            .FirstOrDefaultAsync(p => p.KapelleId == kapelleId && p.Schluessel == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Wert).RootElement;
            existing.Wert = wertJson;
            existing.AktualisiertVonId = musikerId;
        }
        else
        {
            db.ConfigPolicies.Add(new ConfigPolicy
            {
                KapelleId = kapelleId,
                Schluessel = schluessel,
                Wert = wertJson,
                AktualisiertVonId = musikerId
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            KapelleId = kapelleId,
            MusikerId = musikerId,
            Ebene = "policy",
            Schluessel = schluessel,
            AlterWert = alterWert?.GetRawText(),
            NeuerWert = wertJson
        });

        await db.SaveChangesAsync();

        return new ConfigAenderungResponse(true, alterWert, request.Wert, DateTime.UtcNow);
    }

    public async Task DeletePolicyAsync(Guid kapelleId, string schluessel, Guid musikerId)
    {
        await RequireAdminAsync(kapelleId, musikerId);

        var existing = await db.ConfigPolicies
            .FirstOrDefaultAsync(p => p.KapelleId == kapelleId && p.Schluessel == schluessel);

        if (existing is null)
            throw new DomainException("POLICY_NOT_FOUND", $"Policy '{schluessel}' nicht gefunden.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            KapelleId = kapelleId,
            MusikerId = musikerId,
            Ebene = "policy",
            Schluessel = schluessel,
            AlterWert = existing.Wert,
            NeuerWert = null
        });

        db.ConfigPolicies.Remove(existing);
        await db.SaveChangesAsync();
    }

    // ── Nutzer Config ─────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigNutzerEintragResponse>> GetNutzerConfigAsync(Guid musikerId)
    {
        return await db.ConfigNutzer
            .Where(c => c.MusikerId == musikerId)
            .Select(c => new ConfigNutzerEintragResponse(
                c.Schluessel,
                JsonDocument.Parse(c.Wert).RootElement,
                c.Version,
                c.UpdatedAt))
            .ToListAsync();
    }

    public async Task<ConfigAenderungResponse> SetNutzerConfigAsync(
        Guid musikerId, string schluessel, ConfigWertSetzenRequest request)
    {
        var def = ConfigKeyRegistry.Get(schluessel);
        if (def is null || def.Ebene != ConfigKeyRegistry.ConfigEbene.Nutzer)
            throw new DomainException("INVALID_CONFIG_KEY",
                $"Ungültiger Konfigurationsschlüssel für Nutzer-Ebene: {schluessel}", 400);

        var validationError = ConfigKeyRegistry.Validate(schluessel, request.Wert);
        if (validationError is not null)
            throw new DomainException("VALIDATION_ERROR", validationError, 422);

        var wertJson = request.Wert.GetRawText();
        var existing = await db.ConfigNutzer
            .FirstOrDefaultAsync(c => c.MusikerId == musikerId && c.Schluessel == schluessel);

        JsonElement? alterWert = null;

        if (existing is not null)
        {
            alterWert = JsonDocument.Parse(existing.Wert).RootElement;
            existing.Wert = wertJson;
            existing.Version++;
        }
        else
        {
            db.ConfigNutzer.Add(new ConfigNutzer
            {
                MusikerId = musikerId,
                Schluessel = schluessel,
                Wert = wertJson,
                Version = 1
            });
        }

        db.ConfigAudit.Add(new ConfigAudit
        {
            MusikerId = musikerId,
            Ebene = "nutzer",
            Schluessel = schluessel,
            AlterWert = alterWert?.GetRawText(),
            NeuerWert = wertJson
        });

        await db.SaveChangesAsync();

        return new ConfigAenderungResponse(true, alterWert, request.Wert, DateTime.UtcNow);
    }

    public async Task DeleteNutzerConfigAsync(Guid musikerId, string schluessel)
    {
        var existing = await db.ConfigNutzer
            .FirstOrDefaultAsync(c => c.MusikerId == musikerId && c.Schluessel == schluessel);

        if (existing is null)
            throw new DomainException("CONFIG_NOT_FOUND", $"Konfiguration '{schluessel}' nicht gefunden.", 404);

        db.ConfigAudit.Add(new ConfigAudit
        {
            MusikerId = musikerId,
            Ebene = "nutzer",
            Schluessel = schluessel,
            AlterWert = existing.Wert,
            NeuerWert = null
        });

        db.ConfigNutzer.Remove(existing);
        await db.SaveChangesAsync();
    }

    public async Task<ConfigSyncResponse> SyncNutzerConfigAsync(Guid musikerId, ConfigSyncRequest request)
    {
        var applied = new List<ConfigSyncApplied>();
        var conflicts = new List<ConfigSyncConflict>();

        var existingEntries = await db.ConfigNutzer
            .Where(c => c.MusikerId == musikerId)
            .ToDictionaryAsync(c => c.Schluessel);

        foreach (var change in request.Changes)
        {
            var def = ConfigKeyRegistry.Get(change.Schluessel);
            if (def is null || def.Ebene != ConfigKeyRegistry.ConfigEbene.Nutzer)
                continue; // Skip unknown keys silently

            var validationError = ConfigKeyRegistry.Validate(change.Schluessel, change.Wert);
            if (validationError is not null)
                continue; // Skip invalid values

            var wertJson = change.Wert.GetRawText();

            if (existingEntries.TryGetValue(change.Schluessel, out var existing))
            {
                if (change.Version > existing.Version)
                {
                    // Client version is newer — client wins
                    existing.Wert = wertJson;
                    existing.Version = change.Version;
                    applied.Add(new ConfigSyncApplied(change.Schluessel, existing.Version));
                }
                else if (change.Version < existing.Version)
                {
                    // Server version is newer — conflict, server wins
                    conflicts.Add(new ConfigSyncConflict(
                        change.Schluessel,
                        JsonDocument.Parse(existing.Wert).RootElement,
                        existing.Version,
                        "Server hat neuere Version"));
                }
                else
                {
                    // Same version — use timestamp as tiebreaker (Last-Write-Wins)
                    if (change.Zeitstempel > existing.UpdatedAt)
                    {
                        existing.Wert = wertJson;
                        existing.Version++;
                        applied.Add(new ConfigSyncApplied(change.Schluessel, existing.Version));
                    }
                    else
                    {
                        conflicts.Add(new ConfigSyncConflict(
                            change.Schluessel,
                            JsonDocument.Parse(existing.Wert).RootElement,
                            existing.Version,
                            "Server-Timestamp ist neuer"));
                    }
                }
            }
            else
            {
                // New entry from client
                var newEntry = new ConfigNutzer
                {
                    MusikerId = musikerId,
                    Schluessel = change.Schluessel,
                    Wert = wertJson,
                    Version = Math.Max(change.Version, 1)
                };
                db.ConfigNutzer.Add(newEntry);
                applied.Add(new ConfigSyncApplied(change.Schluessel, newEntry.Version));
            }
        }

        await db.SaveChangesAsync();

        // Return all server-side entries as server changes for full sync
        var serverEntries = await db.ConfigNutzer
            .Where(c => c.MusikerId == musikerId)
            .Select(c => new ConfigNutzerEintragResponse(
                c.Schluessel,
                JsonDocument.Parse(c.Wert).RootElement,
                c.Version,
                c.UpdatedAt))
            .ToListAsync();

        return new ConfigSyncResponse(applied, serverEntries, conflicts);
    }

    // ── Resolved Config ───────────────────────────────────────────────────────

    public async Task<IReadOnlyList<ConfigResolvedEintrag>> GetResolvedConfigAsync(
        Guid kapelleId, Guid musikerId)
    {
        await RequireMitgliedschaftAsync(kapelleId, musikerId);

        // Load all 3 levels in parallel
        var kapelleConfigTask = db.ConfigKapelle
            .Where(c => c.KapelleId == kapelleId)
            .ToDictionaryAsync(c => c.Schluessel, c => c.Wert);

        var nutzerConfigTask = db.ConfigNutzer
            .Where(c => c.MusikerId == musikerId)
            .ToDictionaryAsync(c => c.Schluessel, c => c.Wert);

        var policiesTask = db.ConfigPolicies
            .Where(p => p.KapelleId == kapelleId)
            .ToDictionaryAsync(p => p.Schluessel, p => p.Wert);

        await Task.WhenAll(kapelleConfigTask, nutzerConfigTask, policiesTask);

        var kapelleConfig = kapelleConfigTask.Result;
        var nutzerConfig = nutzerConfigTask.Result;
        var policies = policiesTask.Result;

        // Build set of enforced nutzer keys from active policies
        var enforcedNutzerKeys = new HashSet<string>();
        foreach (var (policyKey, policyWert) in policies)
        {
            if (!IsPolicyEnforced(policyKey, policyWert))
                continue;

            if (ConfigKeyRegistry.PolicyAffectedKeys.TryGetValue(policyKey, out var affected))
            {
                foreach (var key in affected)
                    enforcedNutzerKeys.Add(key);
            }
        }

        var result = new List<ConfigResolvedEintrag>();

        // Resolve all known keys
        foreach (var def in ConfigKeyRegistry.AllKeys.Values)
        {
            if (def.Ebene == ConfigKeyRegistry.ConfigEbene.Policy)
                continue; // Policies are not part of resolved config directly

            var (wert, ebene, policyEnforced) = ResolveKey(
                def, kapelleConfig, nutzerConfig, enforcedNutzerKeys);

            result.Add(new ConfigResolvedEintrag(def.Schluessel, wert, ebene, policyEnforced));
        }

        // Include policies as separate entries for client awareness
        foreach (var def in ConfigKeyRegistry.GetByEbene(ConfigKeyRegistry.ConfigEbene.Policy))
        {
            var wert = policies.TryGetValue(def.Schluessel, out var policyWert)
                ? JsonDocument.Parse(policyWert).RootElement
                : def.DefaultWert;

            result.Add(new ConfigResolvedEintrag(def.Schluessel, wert, "policy", false));
        }

        return result;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static (JsonElement Wert, string Ebene, bool PolicyEnforced) ResolveKey(
        ConfigKeyRegistry.ConfigKeyDefinition def,
        Dictionary<string, string> kapelleConfig,
        Dictionary<string, string> nutzerConfig,
        HashSet<string> enforcedNutzerKeys)
    {
        bool policyEnforced = enforcedNutzerKeys.Contains(def.Schluessel);

        // If policy enforces this key, only use Kapelle value or default
        if (policyEnforced)
        {
            if (def.Ebene == ConfigKeyRegistry.ConfigEbene.Kapelle && kapelleConfig.TryGetValue(def.Schluessel, out var kapVal))
                return (JsonDocument.Parse(kapVal).RootElement, "kapelle", true);

            return (def.DefaultWert, "default", true);
        }

        // Override chain: Nutzer > Kapelle > Default (no Gerät on server side)
        if (def.Ebene == ConfigKeyRegistry.ConfigEbene.Nutzer && nutzerConfig.TryGetValue(def.Schluessel, out var nutzerVal))
            return (JsonDocument.Parse(nutzerVal).RootElement, "nutzer", false);

        if (def.Ebene == ConfigKeyRegistry.ConfigEbene.Kapelle && kapelleConfig.TryGetValue(def.Schluessel, out var kapelleVal))
            return (JsonDocument.Parse(kapelleVal).RootElement, "kapelle", false);

        // For nutzer keys, also check kapelle (e.g. nutzer.sprache falls back to kapelle.sprache)
        if (def.Ebene == ConfigKeyRegistry.ConfigEbene.Nutzer)
        {
            var kapelleEquivalent = def.Schluessel.Replace("nutzer.", "kapelle.");
            if (kapelleConfig.TryGetValue(kapelleEquivalent, out var kapelleFallback))
                return (JsonDocument.Parse(kapelleFallback).RootElement, "kapelle", false);
        }

        return (def.DefaultWert, "default", false);
    }

    private static bool IsPolicyEnforced(string policyKey, string policyWertJson)
    {
        try
        {
            using var doc = JsonDocument.Parse(policyWertJson);
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

    private async Task<Mitgliedschaft> RequireMitgliedschaftAsync(Guid kapelleId, Guid musikerId)
    {
        var m = await db.Mitgliedschaften
            .FirstOrDefaultAsync(m => m.KapelleID == kapelleId && m.MusikerID == musikerId && m.IstAktiv);

        return m ?? throw new DomainException("KAPELLE_NOT_FOUND", "Kapelle nicht gefunden oder kein Zugriff.", 404);
    }

    private async Task<Mitgliedschaft> RequireAdminAsync(Guid kapelleId, Guid musikerId)
    {
        var m = await RequireMitgliedschaftAsync(kapelleId, musikerId);

        if (m.Rolle != MitgliedRolle.Administrator)
            throw new AuthException("FORBIDDEN", "Nur Admins dürfen diese Aktion ausführen.", 403);

        return m;
    }
}
