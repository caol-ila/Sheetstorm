using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.KapelleManagement;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/kapellen/{kapelleId:guid}")]
[Authorize]
public class MitgliederController(IKapelleService kapelleService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/kapellen/{kapelleId}/mitglieder
    [HttpGet("mitglieder")]
    [ProducesResponseType(typeof(IReadOnlyList<MitgliedDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMitglieder(Guid kapelleId)
    {
        var result = await kapelleService.GetMitgliederAsync(kapelleId, CurrentUserId);
        return Ok(result);
    }

    // POST /api/kapellen/{kapelleId}/einladungen  — Admin only (enforced in service)
    [HttpPost("einladungen")]
    [ProducesResponseType(typeof(EinladungDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> EinladungErstellen(
        Guid kapelleId,
        [FromBody] EinladungErstellenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await kapelleService.EinladungErstellenAsync(kapelleId, request, CurrentUserId);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/kapellen/{kapelleId}/mitglieder/{userId}/stimmen
    // Admin can set anyone's stimme; members can set their own
    [HttpPut("mitglieder/{userId:guid}/stimmen")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetNutzerStimmen(
        Guid kapelleId,
        Guid userId,
        [FromBody] NutzerStimmenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Stimmen-Eingabe."));

        await kapelleService.SetNutzerStimmenAsync(kapelleId, userId, request, CurrentUserId);
        return NoContent();
    }

    // PUT /api/kapellen/{kapelleId}/mitglieder/{userId}/rolle  — Admin only (enforced in service)
    [HttpPut("mitglieder/{userId:guid}/rolle")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RolleAendern(
        Guid kapelleId,
        Guid userId,
        [FromBody] RolleAendernRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Rolle."));

        await kapelleService.RolleAendernAsync(kapelleId, userId, request, CurrentUserId);
        return NoContent();
    }

    // DELETE /api/kapellen/{kapelleId}/mitglieder/{userId}
    // Admin can remove anyone; any member can remove themselves (leave)
    [HttpDelete("mitglieder/{userId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MitgliedEntfernen(Guid kapelleId, Guid userId)
    {
        await kapelleService.MitgliedEntfernenAsync(kapelleId, userId, CurrentUserId);
        return NoContent();
    }
}
