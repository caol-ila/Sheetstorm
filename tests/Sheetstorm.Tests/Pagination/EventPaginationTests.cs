using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Pagination;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Events;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Pagination;

public class EventPaginationTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly EventService _sut;

    public EventPaginationTests()
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

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedBandWithEventsAsync(int eventCount)
    {
        var musician = new Musician { Email = "test@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership
        {
            Musician = musician,
            Band = band,
            Role = MemberRole.Conductor,
            IsActive = true
        };

        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);

        for (var i = 0; i < eventCount; i++)
        {
            _db.Set<Event>().Add(new Event
            {
                Band = band,
                CreatedByMusician = musician,
                Title = $"Event {i}",
                EventType = EventType.Rehearsal,
                StartDate = DateTime.UtcNow.AddDays(i + 1),
                CreatedAt = DateTime.UtcNow.AddMinutes(-eventCount + i)
            });
        }

        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    // ── GetEventsPaginatedAsync Tests ─────────────────────────────────────────

    [Fact]
    public async Task GetEvents_NoCursor_ReturnsFirstPage()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(25);
        var request = new PaginationRequest();

        var result = await _sut.GetEventsPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(20, result.Items.Count);
        Assert.True(result.HasMore);
        Assert.NotNull(result.Cursor);
        Assert.Equal(20, result.PageSize);
    }

    [Fact]
    public async Task GetEvents_WithCursor_ReturnsNextPage()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(25);

        var firstPage = await _sut.GetEventsPaginatedAsync(
            bandId, musicianId, new PaginationRequest(), CancellationToken.None);

        var secondPage = await _sut.GetEventsPaginatedAsync(
            bandId, musicianId, new PaginationRequest(Cursor: firstPage.Cursor), CancellationToken.None);

        Assert.Equal(5, secondPage.Items.Count);
        Assert.False(secondPage.HasMore);
        Assert.Null(secondPage.Cursor);

        var firstIds = firstPage.Items.Select(e => e.Id).ToHashSet();
        var secondIds = secondPage.Items.Select(e => e.Id).ToHashSet();
        Assert.Empty(firstIds.Intersect(secondIds));
    }

    [Fact]
    public async Task GetEvents_LastPage_HasMoreIsFalse()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(10);
        var request = new PaginationRequest();

        var result = await _sut.GetEventsPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(10, result.Items.Count);
        Assert.False(result.HasMore);
        Assert.Null(result.Cursor);
    }

    [Fact]
    public async Task GetEvents_InvalidCursor_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(5);
        var request = new PaginationRequest(Cursor: "garbage");

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetEventsPaginatedAsync(bandId, musicianId, request, CancellationToken.None));

        Assert.Equal("INVALID_CURSOR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task GetEvents_PageSizeExceedsMax_CapsAt100()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(5);
        var request = new PaginationRequest(PageSize: 999);

        var result = await _sut.GetEventsPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(100, result.PageSize);
    }

    [Fact]
    public async Task GetEvents_FullTraversal_ReturnsAllItems()
    {
        var (musicianId, bandId) = await SeedBandWithEventsAsync(45);
        var allItems = new List<EventDto>();
        string? cursor = null;

        do
        {
            var request = new PaginationRequest(Cursor: cursor, PageSize: 20);
            var page = await _sut.GetEventsPaginatedAsync(bandId, musicianId, request, CancellationToken.None);
            allItems.AddRange(page.Items);
            cursor = page.Cursor;
        }
        while (cursor != null);

        Assert.Equal(45, allItems.Count);
        Assert.Equal(45, allItems.Select(e => e.Id).Distinct().Count());
    }

    [Fact]
    public async Task GetEvents_NotMember_ThrowsDomainException()
    {
        var (_, bandId) = await SeedBandWithEventsAsync(5);
        var stranger = Guid.NewGuid();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetEventsPaginatedAsync(bandId, stranger, new PaginationRequest(), CancellationToken.None));
    }
}
