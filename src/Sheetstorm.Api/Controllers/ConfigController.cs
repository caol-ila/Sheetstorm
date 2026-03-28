using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Config;
using Sheetstorm.Infrastructure.Config;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/config")]
[Authorize]
public class ConfigController(IConfigService configService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // ══════════════════════════════════════════════════════════════════════════
    // Band CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/Band/{bandId}
    [HttpGet("band/{bandId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigEntryResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBandConfig(Guid bandId)
    {
        var result = await configService.GetBandConfigAsync(bandId, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/Band/{bandId}/{key}
    [HttpPut("band/{bandId:guid}/{**key}")]
    [ProducesResponseType(typeof(ConfigChangeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SetBandConfig(
        Guid bandId, string key, [FromBody] SetConfigValueRequest request)
    {
        var result = await configService.SetBandConfigAsync(bandId, key, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/config/Band/{bandId}/{key}
    [HttpDelete("band/{bandId:guid}/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteBandConfig(Guid bandId, string key)
    {
        await configService.DeleteBandConfigAsync(bandId, key, CurrentUserId);
        return NoContent();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // POLICIES
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/Band/{bandId}/policies
    [HttpGet("band/{bandId:guid}/policies")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigPolicyEntryResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetPolicies(Guid bandId)
    {
        var result = await configService.GetPoliciesAsync(bandId, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/Band/{bandId}/policies/{key}
    [HttpPut("band/{bandId:guid}/policies/{**key}")]
    [ProducesResponseType(typeof(ConfigChangeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SetPolicy(
        Guid bandId, string key, [FromBody] SetConfigValueRequest request)
    {
        var result = await configService.SetPolicyAsync(bandId, key, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/config/Band/{bandId}/policies/{key}
    [HttpDelete("band/{bandId:guid}/policies/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePolicy(Guid bandId, string key)
    {
        await configService.DeletePolicyAsync(bandId, key, CurrentUserId);
        return NoContent();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NUTZER CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/nutzer
    [HttpGet("user")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigUserEntryResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUserConfig()
    {
        var result = await configService.GetUserConfigAsync(CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/nutzer/{key}
    [HttpPut("user/{**key}")]
    [ProducesResponseType(typeof(ConfigChangeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SetUserConfig(string key, [FromBody] SetConfigValueRequest request)
    {
        var result = await configService.SetUserConfigAsync(CurrentUserId, key, request);
        return Ok(result);
    }

    // DELETE /api/config/nutzer/{key}
    [HttpDelete("user/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteUserConfig(string key)
    {
        await configService.DeleteUserConfigAsync(CurrentUserId, key);
        return NoContent();
    }

    // POST /api/config/nutzer/sync
    [HttpPost("user/sync")]
    [ProducesResponseType(typeof(ConfigSyncResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SyncUserConfig([FromBody] ConfigSyncRequest request)
    {
        var result = await configService.SyncUserConfigAsync(CurrentUserId, request);
        return Ok(result);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // RESOLVED CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/resolved?bandId={id}
    [HttpGet("resolved")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigResolvedEntry>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetResolvedConfig([FromQuery] Guid bandId)
    {
        var result = await configService.GetResolvedConfigAsync(bandId, CurrentUserId);
        return Ok(result);
    }
}
