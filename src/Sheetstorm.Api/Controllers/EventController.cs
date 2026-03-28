using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Events;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/events")]
[Authorize]
public class EventController(IEventService eventService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands/{bandId}/events
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<EventDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetEvents(Guid bandId, CancellationToken ct)
    {
        var result = await eventService.GetEventsAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/events/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetEvent(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await eventService.GetEventAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/events
    [HttpPost]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateEvent(
        Guid bandId,
        [FromBody] CreateEventRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await eventService.CreateEventAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/events/{id}
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateEvent(
        Guid bandId,
        Guid id,
        [FromBody] UpdateEventRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await eventService.UpdateEventAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/events/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteEvent(Guid bandId, Guid id, CancellationToken ct)
    {
        await eventService.DeleteEventAsync(bandId, id, CurrentUserId, ct);
        return NoContent();
    }

    // POST /api/bands/{bandId}/events/{id}/rsvp
    [HttpPost("{id:guid}/rsvp")]
    [ProducesResponseType(typeof(EventRsvpDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetRsvp(
        Guid bandId,
        Guid id,
        [FromBody] SetRsvpRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await eventService.SetRsvpAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/events/{id}/rsvps
    [HttpGet("{id:guid}/rsvps")]
    [ProducesResponseType(typeof(IReadOnlyList<EventRsvpDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRsvps(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await eventService.GetRsvpsAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/events/{eventId}/substitutes/{musicianId}
    [HttpGet("{eventId:guid}/substitutes/{musicianId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<SubstituteSuggestionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetSubstituteSuggestions(
        Guid bandId,
        Guid eventId,
        Guid musicianId,
        CancellationToken ct)
    {
        var result = await eventService.GetSubstituteSuggestionsAsync(bandId, eventId, musicianId, CurrentUserId, ct);
        return Ok(result);
    }
}
