using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Substitutes;
using Sheetstorm.Infrastructure.Substitutes;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/substitutes")]
[Authorize]
public class SubstituteAccessController(ISubstituteService substituteService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // POST /api/bands/{bandId}/substitutes
    [HttpPost]
    [ProducesResponseType(typeof(SubstituteAccessCreatedDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateAccess(
        Guid bandId,
        [FromBody] CreateSubstituteAccessRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await substituteService.CreateAccessAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // GET /api/bands/{bandId}/substitutes
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SubstituteAccessDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActiveAccesses(Guid bandId, CancellationToken ct)
    {
        var result = await substituteService.GetActiveAccessesAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/substitutes/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> RevokeAccess(Guid bandId, Guid id, CancellationToken ct)
    {
        await substituteService.RevokeAccessAsync(bandId, id, CurrentUserId, ct);
        return NoContent();
    }

    // PATCH /api/bands/{bandId}/substitutes/{id}
    [HttpPatch("{id:guid}")]
    [ProducesResponseType(typeof(SubstituteAccessDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ExtendAccess(
        Guid bandId,
        Guid id,
        [FromBody] ExtendSubstituteAccessRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await substituteService.ExtendAccessAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/substitute/{token} — Public endpoint (no auth)
    [HttpGet("/api/substitute/{token}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(SubstituteValidationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ValidateToken(string token, CancellationToken ct)
    {
        var result = await substituteService.ValidateTokenAsync(token, ct);
        return Ok(result);
    }
}
