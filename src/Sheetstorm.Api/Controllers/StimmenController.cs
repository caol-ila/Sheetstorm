using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Stimmen;
using Sheetstorm.Infrastructure.Stimmen;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Authorize]
public class StimmenController(IStimmenService stimmenService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // ── Stück Stimmen ───────────────────────────────────────────────────────

    /// <summary>
    /// List all available Stimmen for a Stück, with the fallback-resolved preselection for the current user.
    /// </summary>
    [HttpGet("api/stuecke/{stueckId:guid}/stimmen")]
    [ProducesResponseType(typeof(StimmenListeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStimmen(Guid stueckId)
    {
        var result = await stimmenService.GetStimmenAsync(stueckId, CurrentUserId);
        return Ok(result);
    }

    /// <summary>
    /// Get the resolved Stimme for the current user on a specific Stück (runs the 6-step fallback algorithm).
    /// </summary>
    [HttpGet("api/stuecke/{stueckId:guid}/stimme/resolved")]
    [ProducesResponseType(typeof(ResolvedStimmeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ResolveStimme(Guid stueckId)
    {
        var result = await stimmenService.ResolveStimmeAsync(stueckId, CurrentUserId);
        return Ok(result);
    }

    // ── Nutzer Stimmen-Profil ───────────────────────────────────────────────

    /// <summary>
    /// Get the current user's instrument profile (instruments + per-Kapelle Stimmen defaults).
    /// </summary>
    [HttpGet("api/nutzer/stimmen-profil")]
    [ProducesResponseType(typeof(StimmenProfilResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStimmenProfil()
    {
        var result = await stimmenService.GetStimmenProfilAsync(CurrentUserId);
        return Ok(result);
    }

    /// <summary>
    /// Set the current user's instrument profile (replace all instruments + Stimmen defaults).
    /// </summary>
    [HttpPut("api/nutzer/stimmen-profil")]
    [ProducesResponseType(typeof(StimmenProfilResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SetStimmenProfil([FromBody] StimmenProfilSetzenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await stimmenService.SetStimmenProfilAsync(CurrentUserId, request);
        return Ok(result);
    }
}
