using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Attendance;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Infrastructure.Attendance;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/attendance")]
[Authorize]
public class AttendanceController(IAttendanceService service) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<AttendanceRecordDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(Guid bandId, [FromQuery] DateOnly? startDate, [FromQuery] DateOnly? endDate, CancellationToken ct)
    {
        var result = await service.GetAllAsync(bandId, CurrentUserId, startDate, endDate, ct);
        return Ok(result);
    }

    [HttpGet("{recordId:guid}")]
    [ProducesResponseType(typeof(AttendanceRecordDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid bandId, Guid recordId, CancellationToken ct)
    {
        var result = await service.GetByIdAsync(bandId, recordId, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(AttendanceRecordDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(Guid bandId, [FromBody] CreateAttendanceRecordRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.CreateAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{recordId:guid}")]
    [ProducesResponseType(typeof(AttendanceRecordDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid bandId, Guid recordId, [FromBody] UpdateAttendanceRecordRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await service.UpdateAsync(bandId, recordId, request, CurrentUserId, ct);
        return Ok(result);
    }

    [HttpDelete("{recordId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid bandId, Guid recordId, CancellationToken ct)
    {
        await service.DeleteAsync(bandId, recordId, CurrentUserId, ct);
        return NoContent();
    }

    [HttpGet("stats")]
    [ProducesResponseType(typeof(BandAttendanceStatsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetStats(Guid bandId, [FromQuery] DateOnly? startDate, [FromQuery] DateOnly? endDate, CancellationToken ct)
    {
        var result = await service.GetStatsAsync(bandId, CurrentUserId, startDate, endDate, ct);
        return Ok(result);
    }

    [HttpGet("musicians/{musicianId:guid}/stats")]
    [ProducesResponseType(typeof(AttendanceStatsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMusicianStats(Guid bandId, Guid musicianId, [FromQuery] DateOnly? startDate, [FromQuery] DateOnly? endDate, CancellationToken ct)
    {
        var result = await service.GetMusicianStatsAsync(bandId, musicianId, CurrentUserId, startDate, endDate, ct);
        return Ok(result);
    }
}
