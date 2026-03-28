using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.KapelleManagement;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/kapellen")]
[Authorize]
public class KapelleController(IKapelleService kapelleService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/kapellen
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<KapelleDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMeineKapellen()
    {
        var result = await kapelleService.GetMeineKapellenAsync(CurrentUserId);
        return Ok(result);
    }

    // POST /api/kapellen
    [HttpPost]
    [ProducesResponseType(typeof(KapelleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> KapelleErstellen([FromBody] KapelleErstellenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await kapelleService.KapelleErstellenAsync(request, CurrentUserId);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // GET /api/kapellen/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(KapelleDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetKapelle(Guid id)
    {
        var result = await kapelleService.GetKapelleAsync(id, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/kapellen/{id}  — Admin only (enforced in service)
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(KapelleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> KapelleBearbeiten(Guid id, [FromBody] KapelleBearbeitenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await kapelleService.KapelleBearbeitenAsync(id, request, CurrentUserId);
        return Ok(result);
    }

    // DELETE /api/kapellen/{id}  — Admin only (enforced in service)
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> KapelleLoeschen(Guid id)
    {
        await kapelleService.KapelleLoeschenAsync(id, CurrentUserId);
        return NoContent();
    }

    // GET /api/kapellen/{id}/stimmen-mapping — any member
    [HttpGet("{id:guid}/stimmen-mapping")]
    [ProducesResponseType(typeof(StimmenMappingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStimmenMapping(Guid id)
    {
        var result = await kapelleService.GetStimmenMappingAsync(id, CurrentUserId);
        return Ok(result);
    }

    // PUT /api/kapellen/{id}/stimmen-mapping — Admin only
    [HttpPut("{id:guid}/stimmen-mapping")]
    [ProducesResponseType(typeof(StimmenMappingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetStimmenMapping(Guid id, [FromBody] StimmenMappingSetzenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Stimmen-Mapping-Daten."));

        var result = await kapelleService.SetStimmenMappingAsync(id, request, CurrentUserId);
        return Ok(result);
    }

    // POST /api/kapellen/beitreten
    [HttpPost("beitreten")]
    [ProducesResponseType(typeof(KapelleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Beitreten([FromBody] BeitretenRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültiger Einladungscode."));

        var result = await kapelleService.BeitretenAsync(request, CurrentUserId);
        return Ok(result);
    }
}
