using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.MediaLinks;
using Sheetstorm.Infrastructure.MediaLinks;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/pieces/{pieceId:guid}/media-links")]
[Authorize]
public class MediaLinkController(IMediaLinkService service) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<MediaLinkDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(Guid bandId, Guid pieceId, CancellationToken ct)
    {
        var result = await service.GetAllForPieceAsync(bandId, pieceId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(MediaLinkDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(Guid bandId, Guid pieceId, [FromBody] CreateMediaLinkRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.CreateAsync(bandId, pieceId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{linkId:guid}")]
    [ProducesResponseType(typeof(MediaLinkDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid bandId, Guid pieceId, Guid linkId, [FromBody] UpdateMediaLinkRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.UpdateAsync(bandId, pieceId, linkId, request, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpDelete("{linkId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid bandId, Guid pieceId, Guid linkId, CancellationToken ct)
    {
        await service.DeleteAsync(bandId, pieceId, linkId, CurrentUserId, ct);
        return NoContent();
    }
}
