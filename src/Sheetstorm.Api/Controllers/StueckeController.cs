using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/kapellen/{kapelleId:guid}/stuecke")]
[Authorize]
public class StueckeController(IImportService importService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/kapellen/{kapelleId}/stuecke
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<StueckDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStuecke(Guid kapelleId, CancellationToken ct)
    {
        var result = await importService.GetStueckeAsync(kapelleId, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/kapellen/{kapelleId}/stuecke/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(StueckDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStueck(Guid kapelleId, Guid id, CancellationToken ct)
    {
        var result = await importService.GetStueckAsync(kapelleId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/kapellen/{kapelleId}/stuecke
    [HttpPost]
    [ProducesResponseType(typeof(StueckDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreateStueck(
        Guid kapelleId,
        [FromBody] StueckCreateDto request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await importService.CreateStueckAsync(kapelleId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/kapellen/{kapelleId}/stuecke/{id}
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(StueckDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateStueck(
        Guid kapelleId,
        Guid id,
        [FromBody] StueckUpdateDto request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Ungültige Eingabe."));

        var result = await importService.UpdateStueckAsync(kapelleId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/kapellen/{kapelleId}/stuecke/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteStueck(Guid kapelleId, Guid id, CancellationToken ct)
    {
        await importService.DeleteStueckAsync(kapelleId, id, CurrentUserId, ct);
        return NoContent();
    }
}
