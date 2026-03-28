using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Events;

namespace Sheetstorm.Tests.Events;

public class EventControllerTests
{
    private readonly IEventService _service;
    private readonly EventController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public EventControllerTests()
    {
        _service = Substitute.For<IEventService>();
        _sut = new EventController(_service);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static EventDto MakeEventDto(Guid id, string title = "Test Event") =>
        new(id, Guid.NewGuid(), title, null, EventType.Concert, null, DateTime.UtcNow, null, false, null, null, null, null, null, null, Guid.NewGuid(), "Creator", new RsvpStatsDto(0, 0, 0, 0), DateTime.UtcNow);

    private static EventRsvpDto MakeEventRsvpDto(Guid id, Guid eventId, Guid musicianId, string name = "Musician") =>
        new(id, eventId, musicianId, name, null, RsvpStatus.Pending, null, null);

    private static SubstituteSuggestionDto MakeSubstituteSuggestionDto(Guid musicianId, string name = "Substitute") =>
        new(musicianId, name, "Trumpet", RsvpStatus.Pending, 100, "Available");

    // ── GetEvents ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetEvents_ReturnsOkWithList()
    {
        var events = new List<EventDto>
        {
            MakeEventDto(Guid.NewGuid(), "Event A"),
            MakeEventDto(Guid.NewGuid(), "Event B")
        };
        _service.GetEventsAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(events);

        var result = await _sut.GetEvents(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<EventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetEvents_DelegatesCurrentUserIdToService()
    {
        _service.GetEventsAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<EventDto>());

        await _sut.GetEvents(_bandId, CancellationToken.None);

        await _service.Received(1).GetEventsAsync(_bandId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetEvents_ServiceThrowsDomainException_Propagates()
    {
        _service.GetEventsAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetEvents(_bandId, CancellationToken.None));
    }

    // ── GetEvent ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetEvent_ReturnsOkWithEvent()
    {
        var eventId = Guid.NewGuid();
        var dto = MakeEventDto(eventId, "Concert 2025");
        _service.GetEventAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetEvent(_bandId, eventId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<EventDto>(ok.Value);
        Assert.Equal(eventId, returned.Id);
        Assert.Equal("Concert 2025", returned.Title);
    }

    [Fact]
    public async Task GetEvent_PassesCorrectIdsToService()
    {
        var eventId = Guid.NewGuid();
        _service.GetEventAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(MakeEventDto(eventId));

        await _sut.GetEvent(_bandId, eventId, CancellationToken.None);

        await _service.Received(1).GetEventAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetEvent_NotFound_DomainExceptionPropagates()
    {
        _service.GetEventAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Event not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetEvent(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── CreateEvent ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateEvent_ValidRequest_Returns201WithEvent()
    {
        var eventId = Guid.NewGuid();
        var request = new CreateEventRequest("New Concert", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);
        var dto = MakeEventDto(eventId, "New Concert");
        _service.CreateEventAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateEvent(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<EventDto>(created.Value);
        Assert.Equal("New Concert", returned.Title);
    }

    [Fact]
    public async Task CreateEvent_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new CreateEventRequest("", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);

        var result = await _sut.CreateEvent(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task CreateEvent_NotConductor_DomainExceptionPropagates()
    {
        var request = new CreateEventRequest("Event", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);
        _service.CreateEventAsync(Arg.Any<Guid>(), Arg.Any<CreateEventRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateEvent(_bandId, request, CancellationToken.None));
    }

    // ── UpdateEvent ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateEvent_ValidRequest_ReturnsOkWithUpdatedEvent()
    {
        var eventId = Guid.NewGuid();
        var request = new UpdateEventRequest("Updated Title", null, EventType.Meeting, null, DateTime.UtcNow.AddDays(1), null);
        var dto = MakeEventDto(eventId, "Updated Title");
        _service.UpdateEventAsync(_bandId, eventId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateEvent(_bandId, eventId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<EventDto>(ok.Value);
        Assert.Equal("Updated Title", returned.Title);
    }

    [Fact]
    public async Task UpdateEvent_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new UpdateEventRequest("", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);

        var result = await _sut.UpdateEvent(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task UpdateEvent_EventNotFound_DomainExceptionPropagates()
    {
        var request = new UpdateEventRequest("Event", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);
        _service.UpdateEventAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateEventRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateEvent(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── DeleteEvent ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteEvent_ValidRequest_Returns204NoContent()
    {
        var eventId = Guid.NewGuid();
        _service.DeleteEventAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteEvent(_bandId, eventId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteEvent_PassesCorrectIdsToService()
    {
        var eventId = Guid.NewGuid();
        _service.DeleteEventAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.DeleteEvent(_bandId, eventId, CancellationToken.None);

        await _service.Received(1).DeleteEventAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteEvent_EventNotFound_DomainExceptionPropagates()
    {
        _service.DeleteEventAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteEvent(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── SetRsvp ──────────────────────────────────────────────────────────────────

    [Fact]
    public async Task SetRsvp_ValidRequest_ReturnsOkWithRsvp()
    {
        var eventId = Guid.NewGuid();
        var rsvpId = Guid.NewGuid();
        var request = new SetRsvpRequest(RsvpStatus.Accepted, "I'll be there");
        var dto = MakeEventRsvpDto(rsvpId, eventId, _musicianId);
        _service.SetRsvpAsync(_bandId, eventId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.SetRsvp(_bandId, eventId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<EventRsvpDto>(ok.Value);
        Assert.Equal(rsvpId, returned.Id);
    }

    [Fact]
    public async Task SetRsvp_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Status", "Required");
        var request = new SetRsvpRequest(RsvpStatus.Pending, null);

        var result = await _sut.SetRsvp(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task SetRsvp_EventNotFound_DomainExceptionPropagates()
    {
        var request = new SetRsvpRequest(RsvpStatus.Accepted, null);
        _service.SetRsvpAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<SetRsvpRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.SetRsvp(_bandId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── GetRsvps ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetRsvps_ReturnsOkWithList()
    {
        var eventId = Guid.NewGuid();
        var rsvps = new List<EventRsvpDto>
        {
            MakeEventRsvpDto(Guid.NewGuid(), eventId, Guid.NewGuid(), "Alice"),
            MakeEventRsvpDto(Guid.NewGuid(), eventId, Guid.NewGuid(), "Bob")
        };
        _service.GetRsvpsAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(rsvps);

        var result = await _sut.GetRsvps(_bandId, eventId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<EventRsvpDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetRsvps_PassesCorrectIdsToService()
    {
        var eventId = Guid.NewGuid();
        _service.GetRsvpsAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<EventRsvpDto>());

        await _sut.GetRsvps(_bandId, eventId, CancellationToken.None);

        await _service.Received(1).GetRsvpsAsync(_bandId, eventId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetRsvps_EventNotFound_DomainExceptionPropagates()
    {
        _service.GetRsvpsAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetRsvps(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── GetSubstituteSuggestions ─────────────────────────────────────────────────

    [Fact]
    public async Task GetSubstituteSuggestions_ReturnsOkWithList()
    {
        var eventId = Guid.NewGuid();
        var declinedMusicianId = Guid.NewGuid();
        var suggestions = new List<SubstituteSuggestionDto>
        {
            MakeSubstituteSuggestionDto(Guid.NewGuid(), "Substitute A"),
            MakeSubstituteSuggestionDto(Guid.NewGuid(), "Substitute B")
        };
        _service.GetSubstituteSuggestionsAsync(_bandId, eventId, declinedMusicianId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(suggestions);

        var result = await _sut.GetSubstituteSuggestions(_bandId, eventId, declinedMusicianId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<SubstituteSuggestionDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetSubstituteSuggestions_PassesCorrectIdsToService()
    {
        var eventId = Guid.NewGuid();
        var declinedMusicianId = Guid.NewGuid();
        _service.GetSubstituteSuggestionsAsync(_bandId, eventId, declinedMusicianId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<SubstituteSuggestionDto>());

        await _sut.GetSubstituteSuggestions(_bandId, eventId, declinedMusicianId, CancellationToken.None);

        await _service.Received(1).GetSubstituteSuggestionsAsync(_bandId, eventId, declinedMusicianId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetSubstituteSuggestions_NotConductor_DomainExceptionPropagates()
    {
        _service.GetSubstituteSuggestionsAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Forbidden.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetSubstituteSuggestions(_bandId, Guid.NewGuid(), Guid.NewGuid(), CancellationToken.None));
    }

    // ── Band-scoped access ───────────────────────────────────────────────────────

    [Fact]
    public async Task BandScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        var foreignBandId = Guid.NewGuid();
        _service.GetEventsAsync(foreignBandId, _musicianId, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Band not found or no access.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetEvents(foreignBandId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }
}
