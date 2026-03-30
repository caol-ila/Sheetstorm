using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Setlists;
using Sheetstorm.Infrastructure.Setlists;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/setlists")]
[Authorize]
public class SetlistController(ISetlistService service) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SetlistDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(Guid bandId, CancellationToken ct)
    {
        var result = await service.GetAllAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpGet("{setlistId:guid}")]
    [ProducesResponseType(typeof(SetlistDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid bandId, Guid setlistId, CancellationToken ct)
    {
        var result = await service.GetByIdAsync(bandId, setlistId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(SetlistDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Create(Guid bandId, [FromBody] CreateSetlistRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.CreateAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{setlistId:guid}")]
    [ProducesResponseType(typeof(SetlistDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid bandId, Guid setlistId, [FromBody] UpdateSetlistRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.UpdateAsync(bandId, setlistId, request, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpDelete("{setlistId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid bandId, Guid setlistId, CancellationToken ct)
    {
        await service.DeleteAsync(bandId, setlistId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{setlistId:guid}/entries")]
    [ProducesResponseType(typeof(SetlistEntryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddEntry(Guid bandId, Guid setlistId, [FromBody] AddSetlistEntryRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.AddEntryAsync(bandId, setlistId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{setlistId:guid}/entries/{entryId:guid}")]
    [ProducesResponseType(typeof(SetlistEntryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateEntry(Guid bandId, Guid setlistId, Guid entryId, [FromBody] UpdateSetlistEntryRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.UpdateEntryAsync(bandId, setlistId, entryId, request, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpDelete("{setlistId:guid}/entries/{entryId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteEntry(Guid bandId, Guid setlistId, Guid entryId, CancellationToken ct)
    {
        await service.DeleteEntryAsync(bandId, setlistId, entryId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{setlistId:guid}/entries/reorder")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ReorderEntries(Guid bandId, Guid setlistId, [FromBody] ReorderEntriesRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        await service.ReorderEntriesAsync(bandId, setlistId, request, CurrentUserId, ct);
        return NoContent();
    }

    [HttpPost("{setlistId:guid}/duplicate")]
    [ProducesResponseType(typeof(SetlistDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Duplicate(Guid bandId, Guid setlistId, CancellationToken ct)
    {
        var result = await service.DuplicateAsync(bandId, setlistId, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }
}
