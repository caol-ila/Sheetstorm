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
    // KAPELLE CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/kapelle/{kapelleId}
    [HttpGet("kapelle/{kapelleId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigEintragResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetKapelleConfig(Guid kapelleId)
    {
        var result = await configService.GetKapelleConfigAsync(kapelleId, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/kapelle/{kapelleId}/{key}
    [HttpPut("kapelle/{kapelleId:guid}/{**key}")]
    [ProducesResponseType(typeof(ConfigAenderungResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SetKapelleConfig(
        Guid kapelleId, string key, [FromBody] ConfigWertSetzenRequest request)
    {
        var result = await configService.SetKapelleConfigAsync(kapelleId, key, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/config/kapelle/{kapelleId}/{key}
    [HttpDelete("kapelle/{kapelleId:guid}/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteKapelleConfig(Guid kapelleId, string key)
    {
        await configService.DeleteKapelleConfigAsync(kapelleId, key, CurrentUserId);
        return NoContent();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // POLICIES
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/kapelle/{kapelleId}/policies
    [HttpGet("kapelle/{kapelleId:guid}/policies")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigPolicyEintragResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetPolicies(Guid kapelleId)
    {
        var result = await configService.GetPoliciesAsync(kapelleId, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/kapelle/{kapelleId}/policies/{key}
    [HttpPut("kapelle/{kapelleId:guid}/policies/{**key}")]
    [ProducesResponseType(typeof(ConfigAenderungResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SetPolicy(
        Guid kapelleId, string key, [FromBody] ConfigWertSetzenRequest request)
    {
        var result = await configService.SetPolicyAsync(kapelleId, key, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/config/kapelle/{kapelleId}/policies/{key}
    [HttpDelete("kapelle/{kapelleId:guid}/policies/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePolicy(Guid kapelleId, string key)
    {
        await configService.DeletePolicyAsync(kapelleId, key, CurrentUserId);
        return NoContent();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NUTZER CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/nutzer
    [HttpGet("nutzer")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigNutzerEintragResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNutzerConfig()
    {
        var result = await configService.GetNutzerConfigAsync(CurrentUserId);
        return Ok(result);
    }

    // PUT /api/config/nutzer/{key}
    [HttpPut("nutzer/{**key}")]
    [ProducesResponseType(typeof(ConfigAenderungResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> SetNutzerConfig(string key, [FromBody] ConfigWertSetzenRequest request)
    {
        var result = await configService.SetNutzerConfigAsync(CurrentUserId, key, request);
        return Ok(result);
    }

    // DELETE /api/config/nutzer/{key}
    [HttpDelete("nutzer/{**key}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteNutzerConfig(string key)
    {
        await configService.DeleteNutzerConfigAsync(CurrentUserId, key);
        return NoContent();
    }

    // POST /api/config/nutzer/sync
    [HttpPost("nutzer/sync")]
    [ProducesResponseType(typeof(ConfigSyncResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SyncNutzerConfig([FromBody] ConfigSyncRequest request)
    {
        var result = await configService.SyncNutzerConfigAsync(CurrentUserId, request);
        return Ok(result);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // RESOLVED CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    // GET /api/config/resolved?kapelleId={id}
    [HttpGet("resolved")]
    [ProducesResponseType(typeof(IReadOnlyList<ConfigResolvedEintrag>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetResolvedConfig([FromQuery] Guid kapelleId)
    {
        var result = await configService.GetResolvedConfigAsync(kapelleId, CurrentUserId);
        return Ok(result);
    }
}
