using Sheetstorm.Domain.Stimmen;

namespace Sheetstorm.Infrastructure.Stimmen;

public interface IStimmenService
{
    /// <summary>
    /// Get all Stimmen for a Stück, including the fallback-resolved preselection for the current user.
    /// </summary>
    Task<StimmenListeResponse> GetStimmenAsync(Guid stueckId, Guid musikerId);

    /// <summary>
    /// Resolve which Stimme a user should see for a given Stück (runs the 6-step fallback).
    /// </summary>
    Task<ResolvedStimmeResponse> ResolveStimmeAsync(Guid stueckId, Guid musikerId);

    /// <summary>
    /// Get the user's instrument profile (all instruments + per-Kapelle default Stimmen).
    /// </summary>
    Task<StimmenProfilResponse> GetStimmenProfilAsync(Guid musikerId);

    /// <summary>
    /// Set/replace the user's instrument profile.
    /// </summary>
    Task<StimmenProfilResponse> SetStimmenProfilAsync(Guid musikerId, StimmenProfilSetzenRequest request);
}
