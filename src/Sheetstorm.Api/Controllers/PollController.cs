using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Polls;
using Sheetstorm.Infrastructure.Polls;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/polls")]
[Authorize]
public class PollController(IPollService service) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<PollDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(Guid bandId, CancellationToken ct)
    {
        var result = await service.GetAllAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpGet("{pollId:guid}")]
    [ProducesResponseType(typeof(PollDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid bandId, Guid pollId, CancellationToken ct)
    {
        var result = await service.GetByIdAsync(bandId, pollId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(PollDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Create(Guid bandId, [FromBody] CreatePollRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.CreateAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpDelete("{pollId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid bandId, Guid pollId, CancellationToken ct)
    {
        await service.DeleteAsync(bandId, pollId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{pollId:guid}/vote")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Vote(Guid bandId, Guid pollId, [FromBody] VotePollRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        await service.VoteAsync(bandId, pollId, request, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{pollId:guid}/close")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Close(Guid bandId, Guid pollId, CancellationToken ct)
    {
        await service.CloseAsync(bandId, pollId, CurrentUserId, ct);
        return NoContent();
    }
}
