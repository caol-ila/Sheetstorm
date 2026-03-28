using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Voices;
using Sheetstorm.Infrastructure.Voices;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Authorize]
public class VoicesController(IVoiceService voiceService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // ── Stück Voices ───────────────────────────────────────────────────────

    /// <summary>
    /// List all available Voices for a Stück, with the fallback-resolved preselection for the current user.
    /// </summary>
    [HttpGet("api/pieces/{pieceId:guid}/voices")]
    [ProducesResponseType(typeof(VoiceListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVoices(Guid pieceId)
    {
        var result = await voiceService.GetVoicesAsync(pieceId, CurrentUserId);
        return Ok(result);
    }

    /// <summary>
    /// Get the resolved Voice for the current user on a specific Stück (runs the 6-step fallback algorithm).
    /// </summary>
    [HttpGet("api/pieces/{pieceId:guid}/voice/resolved")]
    [ProducesResponseType(typeof(ResolvedVoiceResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ResolveVoice(Guid pieceId)
    {
        var result = await voiceService.ResolveVoiceAsync(pieceId, CurrentUserId);
        return Ok(result);
    }

    // ── Nutzer Voices-Profil ───────────────────────────────────────────────

    /// <summary>
    /// Get the current user's instrument profile (instruments + per-Band Voices defaults).
    /// </summary>
    [HttpGet("api/users/voice-profile")]
    [ProducesResponseType(typeof(VoiceProfileResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetVoiceProfile()
    {
        var result = await voiceService.GetVoiceProfileAsync(CurrentUserId);
        return Ok(result);
    }

    /// <summary>
    /// Set the current user's instrument profile (replace all instruments + Voices defaults).
    /// </summary>
    [HttpPut("api/users/voice-profile")]
    [ProducesResponseType(typeof(VoiceProfileResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SetVoiceProfile([FromBody] SetVoiceProfileRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await voiceService.SetVoiceProfileAsync(CurrentUserId, request);
        return Ok(result);
    }
}
