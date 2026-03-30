using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Pagination;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Communication;
using Sheetstorm.Infrastructure.Pagination;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Pagination;

public class PostPaginationTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly PostService _sut;

    public PostPaginationTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new PostService(_db, new BandAuthorizationService(_db));
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedBandWithPostsAsync(int postCount)
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

        for (var i = 0; i < postCount; i++)
        {
            _db.Posts.Add(new Post
            {
                Band = band,
                AuthorMusician = musician,
                Title = $"Post {i}",
                Content = $"Content {i}",
                CreatedAt = DateTime.UtcNow.AddMinutes(-postCount + i)
            });
        }

        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    // ── GetAllPaginatedAsync Tests ────────────────────────────────────────────

    [Fact]
    public async Task GetPosts_NoCursor_ReturnsFirstPage()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(25);
        var request = new PaginationRequest();

        var result = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(20, result.Items.Count);
        Assert.True(result.HasMore);
        Assert.NotNull(result.Cursor);
        Assert.Equal(20, result.PageSize);
    }

    [Fact]
    public async Task GetPosts_WithCursor_ReturnsNextPage()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(25);
        var request = new PaginationRequest();

        var firstPage = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        var secondPageRequest = new PaginationRequest(Cursor: firstPage.Cursor);
        var secondPage = await _sut.GetAllPaginatedAsync(bandId, musicianId, secondPageRequest, CancellationToken.None);

        Assert.Equal(5, secondPage.Items.Count);
        Assert.False(secondPage.HasMore);
        Assert.Null(secondPage.Cursor);

        // No overlap between pages
        var firstIds = firstPage.Items.Select(p => p.Id).ToHashSet();
        var secondIds = secondPage.Items.Select(p => p.Id).ToHashSet();
        Assert.Empty(firstIds.Intersect(secondIds));
    }

    [Fact]
    public async Task GetPosts_LastPage_HasMoreIsFalse()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(10);
        var request = new PaginationRequest();

        var result = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(10, result.Items.Count);
        Assert.False(result.HasMore);
        Assert.Null(result.Cursor);
    }

    [Fact]
    public async Task GetPosts_InvalidCursor_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(5);
        var request = new PaginationRequest(Cursor: "invalid-cursor");

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None));

        Assert.Equal("INVALID_CURSOR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task GetPosts_PageSizeExceedsMax_CapsAt100()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(5);
        var request = new PaginationRequest(PageSize: 500);

        var result = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(100, result.PageSize);
        Assert.Equal(5, result.Items.Count);
    }

    [Fact]
    public async Task GetPosts_CustomPageSize_RespectsSize()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(15);
        var request = new PaginationRequest(PageSize: 5);

        var result = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        Assert.Equal(5, result.Items.Count);
        Assert.True(result.HasMore);
        Assert.Equal(5, result.PageSize);
    }

    [Fact]
    public async Task GetPosts_CursorStability_NewItemsDontCauseDrift()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(25);
        var request = new PaginationRequest(PageSize: 10);

        // Get first page
        var firstPage = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);
        var lastItemFirstPage = firstPage.Items[^1];

        // Add new posts (simulating real-time data insertion)
        for (var i = 0; i < 5; i++)
        {
            _db.Posts.Add(new Post
            {
                BandId = bandId,
                AuthorMusicianId = musicianId,
                Title = $"New Post {i}",
                Content = $"New Content {i}",
                CreatedAt = DateTime.UtcNow.AddMinutes(10 + i)
            });
        }
        await _db.SaveChangesAsync();

        // Get second page using cursor from first page
        var secondPageRequest = new PaginationRequest(Cursor: firstPage.Cursor, PageSize: 10);
        var secondPage = await _sut.GetAllPaginatedAsync(bandId, musicianId, secondPageRequest, CancellationToken.None);

        // Second page should NOT contain items from first page (no drift)
        var firstIds = firstPage.Items.Select(p => p.Id).ToHashSet();
        var secondIds = secondPage.Items.Select(p => p.Id).ToHashSet();
        Assert.Empty(firstIds.Intersect(secondIds));

        // Second page items should be OLDER than last item of first page
        foreach (var item in secondPage.Items)
        {
            Assert.True(
                item.CreatedAt < lastItemFirstPage.CreatedAt ||
                (item.CreatedAt == lastItemFirstPage.CreatedAt && item.Id.CompareTo(lastItemFirstPage.Id) < 0),
                "Second page items must be older than cursor position");
        }
    }

    [Fact]
    public async Task GetPosts_EmptyBand_ReturnsEmptyPage()
    {
        var musician = new Musician { Email = "test@test.com", Name = "Test" };
        var band = new Band { Name = "Empty Band" };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(new Membership
        {
            Musician = musician, Band = band, Role = MemberRole.Conductor, IsActive = true
        });
        await _db.SaveChangesAsync();

        var request = new PaginationRequest();
        var result = await _sut.GetAllPaginatedAsync(band.Id, musician.Id, request, CancellationToken.None);

        Assert.Empty(result.Items);
        Assert.False(result.HasMore);
        Assert.Null(result.Cursor);
    }

    [Fact]
    public async Task GetPosts_OrderedNewestFirst()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(5);
        var request = new PaginationRequest();

        var result = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);

        for (var i = 0; i < result.Items.Count - 1; i++)
        {
            Assert.True(result.Items[i].CreatedAt >= result.Items[i + 1].CreatedAt,
                "Posts should be ordered newest first");
        }
    }

    [Fact]
    public async Task GetPosts_NotMember_ThrowsDomainException()
    {
        var (_, bandId) = await SeedBandWithPostsAsync(5);
        var stranger = Guid.NewGuid();
        var request = new PaginationRequest();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAllPaginatedAsync(bandId, stranger, request, CancellationToken.None));
    }

    [Fact]
    public async Task GetPosts_FullTraversal_ReturnsAllItems()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(55);
        var allItems = new List<PostDto>();
        string? cursor = null;

        do
        {
            var request = new PaginationRequest(Cursor: cursor, PageSize: 20);
            var page = await _sut.GetAllPaginatedAsync(bandId, musicianId, request, CancellationToken.None);
            allItems.AddRange(page.Items);
            cursor = page.Cursor;

            if (page.HasMore)
                Assert.NotNull(page.Cursor);
            else
                Assert.Null(page.Cursor);
        }
        while (cursor != null);

        Assert.Equal(55, allItems.Count);
        Assert.Equal(55, allItems.Select(p => p.Id).Distinct().Count());
    }

    // ── GetCommentsPaginatedAsync Tests ──────────────────────────────────────

    [Fact]
    public async Task GetComments_NoCursor_ReturnsFirstPage()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(1);
        var postId = (await _db.Posts.FirstAsync()).Id;

        // Add 25 comments
        for (var i = 0; i < 25; i++)
        {
            _db.PostComments.Add(new PostComment
            {
                PostId = postId,
                AuthorMusicianId = musicianId,
                Content = $"Comment {i}",
                CreatedAt = DateTime.UtcNow.AddMinutes(i)
            });
        }
        await _db.SaveChangesAsync();

        var request = new PaginationRequest();
        var result = await _sut.GetCommentsPaginatedAsync(bandId, postId, musicianId, request, CancellationToken.None);

        Assert.Equal(20, result.Items.Count);
        Assert.True(result.HasMore);
        Assert.NotNull(result.Cursor);
    }

    [Fact]
    public async Task GetComments_WithCursor_ReturnsRemainingComments()
    {
        var (musicianId, bandId) = await SeedBandWithPostsAsync(1);
        var postId = (await _db.Posts.FirstAsync()).Id;

        for (var i = 0; i < 25; i++)
        {
            _db.PostComments.Add(new PostComment
            {
                PostId = postId,
                AuthorMusicianId = musicianId,
                Content = $"Comment {i}",
                CreatedAt = DateTime.UtcNow.AddMinutes(i)
            });
        }
        await _db.SaveChangesAsync();

        var firstPage = await _sut.GetCommentsPaginatedAsync(
            bandId, postId, musicianId, new PaginationRequest(), CancellationToken.None);

        var secondPage = await _sut.GetCommentsPaginatedAsync(
            bandId, postId, musicianId, new PaginationRequest(Cursor: firstPage.Cursor), CancellationToken.None);

        Assert.Equal(5, secondPage.Items.Count);
        Assert.False(secondPage.HasMore);

        var firstIds = firstPage.Items.Select(c => c.Id).ToHashSet();
        var secondIds = secondPage.Items.Select(c => c.Id).ToHashSet();
        Assert.Empty(firstIds.Intersect(secondIds));
    }
}
