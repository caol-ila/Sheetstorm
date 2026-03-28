using Sheetstorm.Domain.Config;

namespace Sheetstorm.Infrastructure.Config;

public interface IConfigService
{
    // ── Kapelle Config ────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigEintragResponse>> GetKapelleConfigAsync(Guid kapelleId, Guid musikerId);

    Task<ConfigAenderungResponse> SetKapelleConfigAsync(
        Guid kapelleId, string schluessel, ConfigWertSetzenRequest request, Guid musikerId);

    Task DeleteKapelleConfigAsync(Guid kapelleId, string schluessel, Guid musikerId);

    // ── Policies ──────────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigPolicyEintragResponse>> GetPoliciesAsync(Guid kapelleId, Guid musikerId);

    Task<ConfigAenderungResponse> SetPolicyAsync(
        Guid kapelleId, string schluessel, ConfigWertSetzenRequest request, Guid musikerId);

    Task DeletePolicyAsync(Guid kapelleId, string schluessel, Guid musikerId);

    // ── Nutzer Config ─────────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigNutzerEintragResponse>> GetNutzerConfigAsync(Guid musikerId);

    Task<ConfigAenderungResponse> SetNutzerConfigAsync(
        Guid musikerId, string schluessel, ConfigWertSetzenRequest request);

    Task DeleteNutzerConfigAsync(Guid musikerId, string schluessel);

    Task<ConfigSyncResponse> SyncNutzerConfigAsync(Guid musikerId, ConfigSyncRequest request);

    // ── Resolved Config ───────────────────────────────────────────────────────

    Task<IReadOnlyList<ConfigResolvedEintrag>> GetResolvedConfigAsync(Guid kapelleId, Guid musikerId);
}
