using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/pieces")]
[Authorize]
public class PiecesController(IImportService importService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands/{bandId}/Pieces
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<PieceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPieces(Guid bandId, CancellationToken ct)
    {
        var result = await importService.GetPiecesAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/Pieces/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PieceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPiece(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await importService.GetPieceAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/Pieces
    [HttpPost]
    [ProducesResponseType(typeof(PieceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreatePiece(
        Guid bandId,
        [FromBody] PieceCreateDto request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await importService.CreatePieceAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/Pieces/{id}
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(PieceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePiece(
        Guid bandId,
        Guid id,
        [FromBody] PieceUpdateDto request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await importService.UpdatePieceAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/Pieces/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePiece(Guid bandId, Guid id, CancellationToken ct)
    {
        await importService.DeletePieceAsync(bandId, id, CurrentUserId, ct);
        return NoContent();
    }
}
