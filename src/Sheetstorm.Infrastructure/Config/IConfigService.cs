using Sheetstorm.Domain.Config;

namespace Sheetstorm.Infrastructure.Config;

public interface IConfigService
{
    // ── Band Config ────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigEntryResponse>> GetBandConfigAsync(Guid bandId, Guid musicianId);

    Task<ConfigChangeResponse> SetBandConfigAsync(
        Guid bandId, string schluessel, SetConfigValueRequest request, Guid musicianId);

    Task DeleteBandConfigAsync(Guid bandId, string schluessel, Guid musicianId);

    // ── Policies ──────────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigPolicyEntryResponse>> GetPoliciesAsync(Guid bandId, Guid musicianId);

    Task<ConfigChangeResponse> SetPolicyAsync(
        Guid bandId, string schluessel, SetConfigValueRequest request, Guid musicianId);

    Task DeletePolicyAsync(Guid bandId, string schluessel, Guid musicianId);

    // ── Nutzer Config ─────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigUserEntryResponse>> GetUserConfigAsync(Guid musicianId);

    Task<ConfigChangeResponse> SetUserConfigAsync(
        Guid musicianId, string schluessel, SetConfigValueRequest request);

    Task DeleteUserConfigAsync(Guid musicianId, string schluessel);

    Task<ConfigSyncResponse> SyncUserConfigAsync(Guid musicianId, ConfigSyncRequest request);

    // ── Resolved Config ───────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigResolvedEntry>> GetResolvedConfigAsync(Guid bandId, Guid musicianId);
}
