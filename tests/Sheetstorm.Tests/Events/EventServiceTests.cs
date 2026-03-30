using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Events;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Events;

public class EventServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly EventService _sut;

    public EventServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new EventService(_db, new BandAuthorizationService(_db));
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMembershipAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test User" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, IsActive = true, Role = role };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Event> SeedEventAsync(Guid bandId, Guid creatorId, string title = "Test Event", EventType type = EventType.Concert)
    {
        var ev = new Event
        {
            BandId = bandId,
            CreatedByMusicianId = creatorId,
            Title = title,
            EventType = type,
            StartDate = DateTime.UtcNow.AddDays(7),
            IsAllDay = false
        };
        _db.Set<Event>().Add(ev);
        await _db.SaveChangesAsync();
        return ev;
    }

    // ── CreateEventAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateEventAsync_ValidRequest_CreatesEvent()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var request = new CreateEventRequest(
            "Concert 2025",
            "Description",
            EventType.Concert,
            "Main Hall",
            DateTime.UtcNow.AddDays(10),
            null,
            false,
            null,
            null,
            "Notes",
            "Black Tie",
            "Entrance",
            DateTime.UtcNow.AddDays(3));

        var result = await _sut.CreateEventAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("Concert 2025", result.Title);
        Assert.Equal("Description", result.Description);
        Assert.Equal(EventType.Concert, result.EventType);
        Assert.Equal("Main Hall", result.Location);
        Assert.Equal(musicianId, result.CreatedByMusicianId);
    }

    [Fact]
    public async Task CreateEventAsync_CreatesRsvpsForAllMembers()
    {
        var (conductor, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var member1 = new Musician { Email = "m1@test.com", Name = "Member 1" };
        var member2 = new Musician { Email = "m2@test.com", Name = "Member 2" };
        _db.Musicians.AddRange(member1, member2);
        _db.Memberships.Add(new Membership { MusicianId = member1.Id, BandId = bandId, IsActive = true, Role = MemberRole.Musician });
        _db.Memberships.Add(new Membership { MusicianId = member2.Id, BandId = bandId, IsActive = true, Role = MemberRole.Musician });
        await _db.SaveChangesAsync();

        var request = new CreateEventRequest("Rehearsal", null, EventType.Rehearsal, null, DateTime.UtcNow.AddDays(1), null);

        var result = await _sut.CreateEventAsync(bandId, request, conductor, CancellationToken.None);

        Assert.Equal(3, result.Stats.Pending);
        Assert.Equal(0, result.Stats.Accepted);
    }

    [Fact]
    public async Task CreateEventAsync_TrimsWhitespace()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var request = new CreateEventRequest("  Title  ", "  Desc  ", EventType.Meeting, "  Location  ", DateTime.UtcNow.AddDays(1), null);

        var result = await _sut.CreateEventAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("Title", result.Title);
        Assert.Equal("Desc", result.Description);
        Assert.Equal("Location", result.Location);
    }

    [Fact]
    public async Task CreateEventAsync_EndBeforeStart_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var startDate = DateTime.UtcNow.AddDays(10);
        var endDate = startDate.AddDays(-1);
        var request = new CreateEventRequest("Event", null, EventType.Concert, null, startDate, endDate);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateEventAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("End date", ex.Message);
    }

    [Fact]
    public async Task CreateEventAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var request = new CreateEventRequest("Event", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateEventAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── GetEventsAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetEventsAsync_ReturnsEventsForBand_OrderedByStartDate()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var later = await SeedEventAsync(bandId, musicianId, "Later Event");
        later.StartDate = DateTime.UtcNow.AddDays(10);
        var earlier = await SeedEventAsync(bandId, musicianId, "Earlier Event");
        earlier.StartDate = DateTime.UtcNow.AddDays(5);
        await _db.SaveChangesAsync();

        var result = await _sut.GetEventsAsync(bandId, musicianId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Equal("Earlier Event", result[0].Title);
        Assert.Equal("Later Event", result[1].Title);
    }

    [Fact]
    public async Task GetEventsAsync_OnlyReturnsEventsForSpecifiedBand()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        await _db.SaveChangesAsync();

        await SeedEventAsync(bandId, musicianId, "My Event");
        await SeedEventAsync(otherBand.Id, musicianId, "Other Event");

        var result = await _sut.GetEventsAsync(bandId, musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("My Event", result[0].Title);
    }

    [Fact]
    public async Task GetEventsAsync_NotMember_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var nonMember = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetEventsAsync(bandId, nonMember, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── GetEventAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetEventAsync_ReturnsEventWithStats()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, musicianId, "Test Event");
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = musicianId, Status = RsvpStatus.Accepted });
        await _db.SaveChangesAsync();

        var result = await _sut.GetEventAsync(bandId, ev.Id, musicianId, CancellationToken.None);

        Assert.Equal("Test Event", result.Title);
        Assert.Equal(1, result.Stats.Accepted);
    }

    [Fact]
    public async Task GetEventAsync_EventNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetEventAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task GetEventAsync_WrongBand_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, musicianId);
        var otherBandId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetEventAsync(otherBandId, ev.Id, musicianId, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── UpdateEventAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateEventAsync_ValidRequest_UpdatesEvent()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var ev = await SeedEventAsync(bandId, musicianId, "Original");
        var request = new UpdateEventRequest(
            "Updated Title",
            "Updated Description",
            EventType.Meeting,
            "New Location",
            DateTime.UtcNow.AddDays(15),
            null);

        var result = await _sut.UpdateEventAsync(bandId, ev.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Updated Title", result.Title);
        Assert.Equal("Updated Description", result.Description);
        Assert.Equal(EventType.Meeting, result.EventType);
        Assert.Equal("New Location", result.Location);
    }

    [Fact]
    public async Task UpdateEventAsync_EndBeforeStart_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var ev = await SeedEventAsync(bandId, musicianId);
        var startDate = DateTime.UtcNow.AddDays(10);
        var endDate = startDate.AddDays(-1);
        var request = new UpdateEventRequest("Event", null, EventType.Concert, null, startDate, endDate);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateEventAsync(bandId, ev.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateEventAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SectionLeader);
        var ev = await SeedEventAsync(bandId, musicianId);
        var request = new UpdateEventRequest("Updated", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateEventAsync(bandId, ev.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateEventAsync_EventNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var request = new UpdateEventRequest("Test", null, EventType.Concert, null, DateTime.UtcNow.AddDays(1), null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateEventAsync(bandId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteEventAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteEventAsync_ValidRequest_RemovesEvent()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var ev = await SeedEventAsync(bandId, musicianId);

        await _sut.DeleteEventAsync(bandId, ev.Id, musicianId, CancellationToken.None);

        var exists = await _db.Set<Event>().AnyAsync(e => e.Id == ev.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteEventAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var ev = await SeedEventAsync(bandId, musicianId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteEventAsync(bandId, ev.Id, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task DeleteEventAsync_EventNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteEventAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── SetRsvpAsync ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task SetRsvpAsync_CreatesNewRsvp_WhenNotExists()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, musicianId);
        var request = new SetRsvpRequest(RsvpStatus.Accepted, "I'll be there");

        var result = await _sut.SetRsvpAsync(bandId, ev.Id, request, musicianId, CancellationToken.None);

        Assert.Equal(RsvpStatus.Accepted, result.Status);
        Assert.Equal("I'll be there", result.Comment);
        Assert.NotNull(result.RespondedAt);
    }

    [Fact]
    public async Task SetRsvpAsync_UpdatesExistingRsvp()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, musicianId);
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = musicianId, Status = RsvpStatus.Pending });
        await _db.SaveChangesAsync();

        var request = new SetRsvpRequest(RsvpStatus.Declined, "Cannot attend");

        var result = await _sut.SetRsvpAsync(bandId, ev.Id, request, musicianId, CancellationToken.None);

        Assert.Equal(RsvpStatus.Declined, result.Status);
        Assert.Equal("Cannot attend", result.Comment);
    }

    [Fact]
    public async Task SetRsvpAsync_EventNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var request = new SetRsvpRequest(RsvpStatus.Accepted, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.SetRsvpAsync(bandId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task SetRsvpAsync_NotMember_ThrowsNotFound()
    {
        var (creatorId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, creatorId);
        var nonMember = Guid.NewGuid();
        var request = new SetRsvpRequest(RsvpStatus.Accepted, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.SetRsvpAsync(bandId, ev.Id, request, nonMember, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── GetRsvpsAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetRsvpsAsync_ReturnsAllRsvps_OrderedByMusicianName()
    {
        var (conductorId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, conductorId);

        var musicianA = new Musician { Email = "a@test.com", Name = "Alice" };
        var musicianB = new Musician { Email = "b@test.com", Name = "Bob" };
        _db.Musicians.AddRange(musicianA, musicianB);
        _db.Memberships.Add(new Membership { MusicianId = musicianA.Id, BandId = bandId, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = musicianB.Id, BandId = bandId, IsActive = true });
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = musicianB.Id, Status = RsvpStatus.Accepted });
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = musicianA.Id, Status = RsvpStatus.Declined });
        await _db.SaveChangesAsync();

        var result = await _sut.GetRsvpsAsync(bandId, ev.Id, conductorId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Equal("Alice", result[0].MusicianName);
        Assert.Equal("Bob", result[1].MusicianName);
    }

    [Fact]
    public async Task GetRsvpsAsync_EventNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetRsvpsAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task GetRsvpsAsync_NotMember_ThrowsNotFound()
    {
        var (creatorId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, creatorId);
        var nonMember = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetRsvpsAsync(bandId, ev.Id, nonMember, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── GetSubstituteSuggestionsAsync ────────────────────────────────────────────

    [Fact]
    public async Task GetSubstituteSuggestionsAsync_RanksSubstitutesBySameInstrument()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var ev = await SeedEventAsync(bandId, conductorId);

        var declinedMusician = new Musician { Email = "declined@test.com", Name = "Declined", Instrument = "Trumpet" };
        var sameInstrument = new Musician { Email = "same@test.com", Name = "Same Instrument", Instrument = "Trumpet" };
        var otherInstrument = new Musician { Email = "other@test.com", Name = "Other Instrument", Instrument = "Trombone" };

        _db.Musicians.AddRange(declinedMusician, sameInstrument, otherInstrument);
        _db.Memberships.Add(new Membership { MusicianId = declinedMusician.Id, BandId = bandId, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = sameInstrument.Id, BandId = bandId, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = otherInstrument.Id, BandId = bandId, IsActive = true });
        await _db.SaveChangesAsync();

        var result = await _sut.GetSubstituteSuggestionsAsync(bandId, ev.Id, declinedMusician.Id, conductorId, CancellationToken.None);

        Assert.Equal(3, result.Count);
        Assert.Equal("Same Instrument", result[0].Name);
        Assert.True(result[0].MatchScore > result[1].MatchScore);
    }

    [Fact]
    public async Task GetSubstituteSuggestionsAsync_ExcludesDeclinedMusicians()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var ev = await SeedEventAsync(bandId, conductorId);

        var declinedMusician = new Musician { Email = "declined@test.com", Name = "Declined", Instrument = "Trumpet" };
        var acceptedMusician = new Musician { Email = "accepted@test.com", Name = "Accepted", Instrument = "Trumpet" };
        var declinedSubstitute = new Musician { Email = "declined2@test.com", Name = "Declined Substitute", Instrument = "Trumpet" };

        _db.Musicians.AddRange(declinedMusician, acceptedMusician, declinedSubstitute);
        _db.Memberships.Add(new Membership { MusicianId = declinedMusician.Id, BandId = bandId, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = acceptedMusician.Id, BandId = bandId, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = declinedSubstitute.Id, BandId = bandId, IsActive = true });

        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = acceptedMusician.Id, Status = RsvpStatus.Accepted });
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = declinedSubstitute.Id, Status = RsvpStatus.Declined });
        await _db.SaveChangesAsync();

        var result = await _sut.GetSubstituteSuggestionsAsync(bandId, ev.Id, declinedMusician.Id, conductorId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Contains(result, r => r.Name == "Accepted");
    }

    [Fact]
    public async Task GetSubstituteSuggestionsAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var ev = await SeedEventAsync(bandId, musicianId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetSubstituteSuggestionsAsync(bandId, ev.Id, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task GetSubstituteSuggestionsAsync_EventNotFound_ThrowsNotFound()
    {
        var (conductorId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetSubstituteSuggestionsAsync(bandId, Guid.NewGuid(), Guid.NewGuid(), conductorId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── GetCalendarEventsAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task GetCalendarEventsAsync_ReturnsEventsAcrossAllBands()
    {
        var musician = new Musician { Email = "m@test.com", Name = "Musician" };
        var band1 = new Band { Name = "Band 1" };
        var band2 = new Band { Name = "Band 2" };
        _db.Musicians.Add(musician);
        _db.Bands.AddRange(band1, band2);
        _db.Memberships.Add(new Membership { MusicianId = musician.Id, BandId = band1.Id, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = musician.Id, BandId = band2.Id, IsActive = true });
        await _db.SaveChangesAsync();

        await SeedEventAsync(band1.Id, musician.Id, "Band 1 Event");
        await SeedEventAsync(band2.Id, musician.Id, "Band 2 Event");

        var result = await _sut.GetCalendarEventsAsync(musician.Id, null, null, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Contains(result, e => e.Title == "Band 1 Event" && e.BandName == "Band 1");
        Assert.Contains(result, e => e.Title == "Band 2 Event" && e.BandName == "Band 2");
    }

    [Fact]
    public async Task GetCalendarEventsAsync_FiltersDateRange()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var pastEvent = await SeedEventAsync(bandId, musicianId, "Past Event");
        pastEvent.StartDate = DateTime.UtcNow.AddDays(-10);
        var futureEvent = await SeedEventAsync(bandId, musicianId, "Future Event");
        futureEvent.StartDate = DateTime.UtcNow.AddDays(10);
        await _db.SaveChangesAsync();

        var fromDate = DateTime.UtcNow.AddDays(-5);
        var toDate = DateTime.UtcNow.AddDays(5);

        var result = await _sut.GetCalendarEventsAsync(musicianId, fromDate, toDate, CancellationToken.None);

        Assert.Empty(result);
    }

    [Fact]
    public async Task GetCalendarEventsAsync_IncludesMyRsvpStatus()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var ev = await SeedEventAsync(bandId, musicianId, "Test Event");
        _db.Set<EventRsvp>().Add(new EventRsvp { EventId = ev.Id, MusicianId = musicianId, Status = RsvpStatus.Accepted });
        await _db.SaveChangesAsync();

        var result = await _sut.GetCalendarEventsAsync(musicianId, null, null, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(RsvpStatus.Accepted, result[0].MyStatus);
    }

    // ── GetBandCalendarEventsAsync ───────────────────────────────────────────────

    [Fact]
    public async Task GetBandCalendarEventsAsync_ReturnsEventsForSpecificBand()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        await _db.SaveChangesAsync();

        await SeedEventAsync(bandId, musicianId, "My Band Event");
        await SeedEventAsync(otherBand.Id, musicianId, "Other Band Event");

        var result = await _sut.GetBandCalendarEventsAsync(bandId, musicianId, null, null, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("My Band Event", result[0].Title);
    }

    [Fact]
    public async Task GetBandCalendarEventsAsync_FiltersDateRange()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var pastEvent = await SeedEventAsync(bandId, musicianId, "Past");
        pastEvent.StartDate = DateTime.UtcNow.AddDays(-10);
        var futureEvent = await SeedEventAsync(bandId, musicianId, "Future");
        futureEvent.StartDate = DateTime.UtcNow.AddDays(10);
        await _db.SaveChangesAsync();

        var fromDate = DateTime.UtcNow.AddDays(5);
        var toDate = DateTime.UtcNow.AddDays(15);

        var result = await _sut.GetBandCalendarEventsAsync(bandId, musicianId, fromDate, toDate, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("Future", result[0].Title);
    }

    [Fact]
    public async Task GetBandCalendarEventsAsync_NotMember_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var nonMember = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetBandCalendarEventsAsync(bandId, nonMember, null, null, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }
}
