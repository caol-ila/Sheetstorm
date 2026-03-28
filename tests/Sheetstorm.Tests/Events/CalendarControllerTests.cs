using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Events;

namespace Sheetstorm.Tests.Events;

public class CalendarControllerTests
{
    private readonly IEventService _service;
    private readonly CalendarController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public CalendarControllerTests()
    {
        _service = Substitute.For<IEventService>();
        _sut = new CalendarController(_service);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static CalendarEventDto MakeCalendarEventDto(Guid id, string title = "Test Event") =>
        new(id, title, EventType.Concert, DateTime.UtcNow, null, null, RsvpStatus.Pending, Guid.NewGuid(), "Test Band", null);

    // ── GetCalendar ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetCalendar_ReturnsOkWithList()
    {
        var events = new List<CalendarEventDto>
        {
            MakeCalendarEventDto(Guid.NewGuid(), "Event A"),
            MakeCalendarEventDto(Guid.NewGuid(), "Event B")
        };
        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(events);

        var result = await _sut.GetCalendar(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetCalendar_DelegatesCurrentUserIdToService()
    {
        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        await _sut.GetCalendar(null, null, CancellationToken.None);

        await _service.Received(1).GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetCalendar_PassesDateRangeToService()
    {
        var fromDate = DateTime.UtcNow.AddDays(-7);
        var toDate = DateTime.UtcNow.AddDays(30);
        _service.GetCalendarEventsAsync(_musicianId, fromDate, toDate, Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        await _sut.GetCalendar(fromDate, toDate, CancellationToken.None);

        await _service.Received(1).GetCalendarEventsAsync(_musicianId, fromDate, toDate, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetCalendar_NullDateRange_PassesNullToService()
    {
        _service.GetCalendarEventsAsync(_musicianId, null, null, Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        await _sut.GetCalendar(null, null, CancellationToken.None);

        await _service.Received(1).GetCalendarEventsAsync(_musicianId, null, null, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetCalendar_AggregatesAcrossAllBands()
    {
        var band1Event = MakeCalendarEventDto(Guid.NewGuid(), "Band 1 Event");
        var band2Event = MakeCalendarEventDto(Guid.NewGuid(), "Band 2 Event");
        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto> { band1Event, band2Event });

        var result = await _sut.GetCalendar(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    // ── GetBandCalendar ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetBandCalendar_ReturnsOkWithList()
    {
        var events = new List<CalendarEventDto>
        {
            MakeCalendarEventDto(Guid.NewGuid(), "Band Event A"),
            MakeCalendarEventDto(Guid.NewGuid(), "Band Event B")
        };
        _service.GetBandCalendarEventsAsync(_bandId, _musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(events);

        var result = await _sut.GetBandCalendar(_bandId, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetBandCalendar_PassesBandIdAndUserIdToService()
    {
        _service.GetBandCalendarEventsAsync(_bandId, _musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        await _sut.GetBandCalendar(_bandId, null, null, CancellationToken.None);

        await _service.Received(1).GetBandCalendarEventsAsync(_bandId, _musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetBandCalendar_PassesDateRangeToService()
    {
        var fromDate = DateTime.UtcNow.AddDays(-7);
        var toDate = DateTime.UtcNow.AddDays(30);
        _service.GetBandCalendarEventsAsync(_bandId, _musicianId, fromDate, toDate, Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        await _sut.GetBandCalendar(_bandId, fromDate, toDate, CancellationToken.None);

        await _service.Received(1).GetBandCalendarEventsAsync(_bandId, _musicianId, fromDate, toDate, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetBandCalendar_NotMember_DomainExceptionPropagates()
    {
        _service.GetBandCalendarEventsAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Band not found or no access.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetBandCalendar(_bandId, null, null, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    // ── Date Filtering ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetCalendar_SpecificDateRange_FiltersCorrectly()
    {
        var fromDate = new DateTime(2025, 1, 1);
        var toDate = new DateTime(2025, 12, 31);
        var event1 = MakeCalendarEventDto(Guid.NewGuid(), "Event in Range");
        var filteredEvents = new List<CalendarEventDto> { event1 };

        _service.GetCalendarEventsAsync(_musicianId, fromDate, toDate, Arg.Any<CancellationToken>())
            .Returns(filteredEvents);

        var result = await _sut.GetCalendar(fromDate, toDate, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Single(returned);
        Assert.Equal("Event in Range", returned[0].Title);
    }

    [Fact]
    public async Task GetBandCalendar_SpecificDateRange_FiltersCorrectly()
    {
        var fromDate = new DateTime(2025, 1, 1);
        var toDate = new DateTime(2025, 12, 31);
        var event1 = MakeCalendarEventDto(Guid.NewGuid(), "Band Event in Range");
        var filteredEvents = new List<CalendarEventDto> { event1 };

        _service.GetBandCalendarEventsAsync(_bandId, _musicianId, fromDate, toDate, Arg.Any<CancellationToken>())
            .Returns(filteredEvents);

        var result = await _sut.GetBandCalendar(_bandId, fromDate, toDate, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Single(returned);
        Assert.Equal("Band Event in Range", returned[0].Title);
    }

    // ── Multi-Band Aggregation ───────────────────────────────────────────────────

    [Fact]
    public async Task GetCalendar_IncludesBandNameForEachEvent()
    {
        var band1Event = new CalendarEventDto(Guid.NewGuid(), "Concert", EventType.Concert, DateTime.UtcNow, null, null, RsvpStatus.Accepted, Guid.NewGuid(), "Band A", null);
        var band2Event = new CalendarEventDto(Guid.NewGuid(), "Rehearsal", EventType.Rehearsal, DateTime.UtcNow, null, null, RsvpStatus.Pending, Guid.NewGuid(), "Band B", null);

        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto> { band1Event, band2Event });

        var result = await _sut.GetCalendar(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
        Assert.Contains(returned, e => e.BandName == "Band A");
        Assert.Contains(returned, e => e.BandName == "Band B");
    }

    [Fact]
    public async Task GetCalendar_IncludesMyRsvpStatus()
    {
        var acceptedEvent = new CalendarEventDto(Guid.NewGuid(), "Accepted Event", EventType.Concert, DateTime.UtcNow, null, null, RsvpStatus.Accepted, Guid.NewGuid(), "Band A", null);
        var declinedEvent = new CalendarEventDto(Guid.NewGuid(), "Declined Event", EventType.Rehearsal, DateTime.UtcNow, null, null, RsvpStatus.Declined, Guid.NewGuid(), "Band B", null);

        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto> { acceptedEvent, declinedEvent });

        var result = await _sut.GetCalendar(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
        Assert.Contains(returned, e => e.MyStatus == RsvpStatus.Accepted);
        Assert.Contains(returned, e => e.MyStatus == RsvpStatus.Declined);
    }

    // ── Empty Results ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetCalendar_NoEvents_ReturnsEmptyList()
    {
        _service.GetCalendarEventsAsync(_musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        var result = await _sut.GetCalendar(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Empty(returned);
    }

    [Fact]
    public async Task GetBandCalendar_NoEvents_ReturnsEmptyList()
    {
        _service.GetBandCalendarEventsAsync(_bandId, _musicianId, Arg.Any<DateTime?>(), Arg.Any<DateTime?>(), Arg.Any<CancellationToken>())
            .Returns(new List<CalendarEventDto>());

        var result = await _sut.GetBandCalendar(_bandId, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<CalendarEventDto>>(ok.Value);
        Assert.Empty(returned);
    }
}
