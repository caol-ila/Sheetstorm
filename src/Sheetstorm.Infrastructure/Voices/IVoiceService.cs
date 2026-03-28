using Sheetstorm.Domain.Voices;

namespace Sheetstorm.Infrastructure.Voices;

public interface IVoiceService
{
    /// <summary>
    /// Get all Voices for a Stück, including the fallback-resolved preselection for the current user.
    /// </summary>
    Task<VoiceListResponse> GetVoicesAsync(Guid pieceId, Guid musicianId);

    /// <summary>
    /// Resolve which Voice a user should see for a given Stück (runs the 6-step fallback).
    /// </summary>
    Task<ResolvedVoiceResponse> ResolveVoiceAsync(Guid pieceId, Guid musicianId);

    /// <summary>
    /// Get the user's instrument profile (all instruments + per-Band default Voices).
    /// </summary>
    Task<VoiceProfileResponse> GetVoiceProfileAsync(Guid musicianId);

    /// <summary>
    /// Set/replace the user's instrument profile.
    /// </summary>
    Task<VoiceProfileResponse> SetVoiceProfileAsync(Guid musicianId, SetVoiceProfileRequest request);
}
