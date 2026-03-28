using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Events;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/calendar")]
[Authorize]
public class CalendarController(IEventService eventService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/calendar — All events across all bands for the current user
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<CalendarEventDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCalendar(
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        CancellationToken ct)
    {
        var result = await eventService.GetCalendarEventsAsync(CurrentUserId, from, to, ct);
        return Ok(result);
    }

    // GET /api/calendar/bands/{bandId} — Events for a specific band
    [HttpGet("bands/{bandId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<CalendarEventDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBandCalendar(
        Guid bandId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        CancellationToken ct)
    {
        var result = await eventService.GetBandCalendarEventsAsync(bandId, CurrentUserId, from, to, ct);
        return Ok(result);
    }
}
