using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Sync;
using Sheetstorm.Infrastructure.Sync;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/sync")]
[Authorize]
public class SyncController(ISyncService syncService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/sync/state
    [HttpGet("state")]
    [ProducesResponseType(typeof(SyncStateResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetState(CancellationToken ct)
    {
        var result = await syncService.GetStateAsync(CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/sync/pull
    [HttpPost("pull")]
    [ProducesResponseType(typeof(PullResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Pull([FromBody] PullRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await syncService.PullAsync(CurrentUserId, request, ct);
        return Ok(result);
    }

    // POST /api/sync/push
    [HttpPost("push")]
    [ProducesResponseType(typeof(PushResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Push([FromBody] PushRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await syncService.PushAsync(CurrentUserId, request, ct);
        return Ok(result);
    }

    // POST /api/sync/resolve
    [HttpPost("resolve")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Resolve([FromBody] ResolveRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        await syncService.ResolveAsync(CurrentUserId, request, ct);
        return NoContent();
    }
}
