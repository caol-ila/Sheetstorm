using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Communication;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Communication;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Communication;

public class PostServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly PostService _sut;

    public PostServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new PostService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId, Guid postId)> SeedPostAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = role, IsActive = true };
        var post = new Post { Band = band, AuthorMusician = musician, Title = "Test Post", Content = "Test Content" };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        _db.Posts.Add(post);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id, post.Id);
    }

    private async Task<Guid> SeedMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Member" };
        var membership = new Membership { MusicianId = musician.Id, BandId = bandId, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    // ── GetAllAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllAsync_ValidMember_ReturnsAllPosts()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(postId, result[0].Id);
    }

    [Fact]
    public async Task GetAllAsync_OrdersByPinnedThenDate()
    {
        var (musicianId, bandId, _) = await SeedPostAsync();
        var post1 = new Post { BandId = bandId, AuthorMusicianId = musicianId, Title = "Old", Content = "Old", CreatedAt = DateTime.UtcNow.AddDays(-2) };
        var post2 = new Post { BandId = bandId, AuthorMusicianId = musicianId, Title = "Pinned", Content = "Pinned", IsPinned = true, PinnedAt = DateTime.UtcNow };
        _db.Posts.Add(post1);
        _db.Posts.Add(post2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Equal("Pinned", result[0].Title);
    }

    [Fact]
    public async Task GetAllAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId, _) = await SeedPostAsync();
        var stranger = Guid.NewGuid();

        await Assert.ThrowsAsync<DomainException>(() => _sut.GetAllAsync(bandId, stranger, CancellationToken.None));
    }

    // ── GetByIdAsync ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetByIdAsync_ValidPost_ReturnsDetailWithComments()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();
        var comment = new PostComment { PostId = postId, AuthorMusicianId = musicianId, Content = "Comment" };
        _db.PostComments.Add(comment);
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, postId, musicianId, CancellationToken.None);

        Assert.Equal(postId, result.Id);
        Assert.Single(result.Comments);
    }

    [Fact]
    public async Task GetByIdAsync_PostNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId, _) = await SeedPostAsync();

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));
    }

    // ── CreateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_AdminRole_CreatesPost()
    {
        var musician = new Musician { Email = "admin@test.com", Name = "Admin" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.Administrator, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePostRequest("Title", "Content", null);
        var result = await _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None);

        Assert.Equal("Title", result.Title);
        Assert.Equal("Content", result.Content);
    }

    [Fact]
    public async Task CreateAsync_ConductorRole_CreatesPost()
    {
        var (musicianId, bandId, _) = await SeedPostAsync(MemberRole.Conductor);

        var request = new CreatePostRequest("New Post", "New Content", "Announcements");
        var result = await _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("New Post", result.Title);
        Assert.Equal("Announcements", result.Category);
    }

    [Fact]
    public async Task CreateAsync_SectionLeaderRole_CreatesPost()
    {
        var musician = new Musician { Email = "leader@test.com", Name = "Leader" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.SectionLeader, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePostRequest("Title", "Content", null);
        var result = await _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None);

        Assert.Equal("Title", result.Title);
    }

    [Fact]
    public async Task CreateAsync_RegularMusicianRole_ThrowsForbidden()
    {
        var musician = new Musician { Email = "member@test.com", Name = "Member" };
        var band = new Band { Name = "Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = MemberRole.Musician, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();

        var request = new CreatePostRequest("Title", "Content", null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(band.Id, request, musician.Id, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    // ── UpdateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateAsync_Author_UpdatesPost()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        var request = new UpdatePostRequest("Updated Title", "Updated Content", "Updated Category");
        var result = await _sut.UpdateAsync(bandId, postId, request, musicianId, CancellationToken.None);

        Assert.Equal("Updated Title", result.Title);
        Assert.Equal("Updated Content", result.Content);
        Assert.Equal("Updated Category", result.Category);
    }

    [Fact]
    public async Task UpdateAsync_NotAuthor_ThrowsForbidden()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var otherId = await SeedMemberAsync(bandId);

        var request = new UpdatePostRequest("Title", "Content", null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateAsync(bandId, postId, request, otherId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── DeleteAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_Author_DeletesPost()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        await _sut.DeleteAsync(bandId, postId, musicianId, CancellationToken.None);

        var exists = await _db.Posts.AnyAsync(p => p.Id == postId);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_Admin_DeletesAnyPost()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);

        await _sut.DeleteAsync(bandId, postId, adminId, CancellationToken.None);

        var exists = await _db.Posts.AnyAsync(p => p.Id == postId);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_NotAuthorNotAdmin_ThrowsForbidden()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var otherId = await SeedMemberAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAsync(bandId, postId, otherId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── PinAsync ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task PinAsync_Admin_PinsPost()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);

        await _sut.PinAsync(bandId, postId, adminId, CancellationToken.None);

        var post = await _db.Posts.FindAsync(postId);
        Assert.True(post!.IsPinned);
        Assert.NotNull(post.PinnedAt);
    }

    [Fact]
    public async Task PinAsync_Conductor_PinsPost()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync(MemberRole.Conductor);

        await _sut.PinAsync(bandId, postId, musicianId, CancellationToken.None);

        var post = await _db.Posts.FindAsync(postId);
        Assert.True(post!.IsPinned);
    }

    [Fact]
    public async Task PinAsync_RegularMember_ThrowsForbidden()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var memberId = await SeedMemberAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.PinAsync(bandId, postId, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task PinAsync_MaxThreePinned_ThrowsConflict()
    {
        var (musicianId, bandId, _) = await SeedPostAsync(MemberRole.Administrator);
        for (int i = 0; i < 3; i++)
        {
            var post = new Post { BandId = bandId, AuthorMusicianId = musicianId, Title = $"Pinned {i}", Content = "Content", IsPinned = true };
            _db.Posts.Add(post);
        }
        var newPost = new Post { BandId = bandId, AuthorMusicianId = musicianId, Title = "New", Content = "New" };
        _db.Posts.Add(newPost);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.PinAsync(bandId, newPost.Id, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task PinAsync_AlreadyPinned_Idempotent()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync(MemberRole.Administrator);
        await _sut.PinAsync(bandId, postId, musicianId, CancellationToken.None);

        await _sut.PinAsync(bandId, postId, musicianId, CancellationToken.None);

        var post = await _db.Posts.FindAsync(postId);
        Assert.True(post!.IsPinned);
    }

    // ── UnpinAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task UnpinAsync_Admin_UnpinsPost()
    {
        var (_, bandId, postId) = await SeedPostAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);
        var post = await _db.Posts.FindAsync(postId);
        post!.IsPinned = true;
        post.PinnedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await _sut.UnpinAsync(bandId, postId, adminId, CancellationToken.None);

        post = await _db.Posts.FindAsync(postId);
        Assert.False(post!.IsPinned);
        Assert.Null(post.PinnedAt);
    }

    // ── AddCommentAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task AddCommentAsync_ValidMember_AddsComment()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        var request = new CreatePostCommentRequest("My comment", null);
        var result = await _sut.AddCommentAsync(bandId, postId, request, musicianId, CancellationToken.None);

        Assert.Equal("My comment", result.Content);
        Assert.Equal(musicianId, result.AuthorMusicianId);
    }

    [Fact]
    public async Task AddCommentAsync_WithParent_CreatesThreaded()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();
        var parent = new PostComment { PostId = postId, AuthorMusicianId = musicianId, Content = "Parent" };
        _db.PostComments.Add(parent);
        await _db.SaveChangesAsync();

        var request = new CreatePostCommentRequest("Reply", parent.Id);
        var result = await _sut.AddCommentAsync(bandId, postId, request, musicianId, CancellationToken.None);

        Assert.Equal(parent.Id, result.ParentCommentId);
    }

    // ── DeleteCommentAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteCommentAsync_Author_MarksAsDeleted()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();
        var comment = new PostComment { PostId = postId, AuthorMusicianId = musicianId, Content = "Comment" };
        _db.PostComments.Add(comment);
        await _db.SaveChangesAsync();

        await _sut.DeleteCommentAsync(bandId, postId, comment.Id, musicianId, CancellationToken.None);

        var updated = await _db.PostComments.FindAsync(comment.Id);
        Assert.True(updated!.IsDeleted);
        Assert.Equal("[Deleted]", updated.Content);
    }

    [Fact]
    public async Task DeleteCommentAsync_Admin_DeletesAnyComment()
    {
        var (authorId, bandId, postId) = await SeedPostAsync();
        var adminId = await SeedMemberAsync(bandId, MemberRole.Administrator);
        var comment = new PostComment { PostId = postId, AuthorMusicianId = authorId, Content = "Comment" };
        _db.PostComments.Add(comment);
        await _db.SaveChangesAsync();

        await _sut.DeleteCommentAsync(bandId, postId, comment.Id, adminId, CancellationToken.None);

        var updated = await _db.PostComments.FindAsync(comment.Id);
        Assert.True(updated!.IsDeleted);
    }

    [Fact]
    public async Task DeleteCommentAsync_NotAuthorNotAdmin_ThrowsForbidden()
    {
        var (authorId, bandId, postId) = await SeedPostAsync();
        var otherId = await SeedMemberAsync(bandId);
        var comment = new PostComment { PostId = postId, AuthorMusicianId = authorId, Content = "Comment" };
        _db.PostComments.Add(comment);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteCommentAsync(bandId, postId, comment.Id, otherId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── AddReactionAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task AddReactionAsync_NewReaction_AddsReaction()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        var request = new AddPostReactionRequest("👍");
        await _sut.AddReactionAsync(bandId, postId, request, musicianId, CancellationToken.None);

        var reaction = await _db.PostReactions.FirstOrDefaultAsync(r => r.PostId == postId && r.MusicianId == musicianId);
        Assert.NotNull(reaction);
        Assert.Equal("👍", reaction.ReactionType);
    }

    [Fact]
    public async Task AddReactionAsync_ExistingReaction_UpdatesType()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();
        var reaction = new PostReaction { PostId = postId, MusicianId = musicianId, ReactionType = "👍" };
        _db.PostReactions.Add(reaction);
        await _db.SaveChangesAsync();

        var request = new AddPostReactionRequest("❤️");
        await _sut.AddReactionAsync(bandId, postId, request, musicianId, CancellationToken.None);

        var updated = await _db.PostReactions.FindAsync(reaction.Id);
        Assert.Equal("❤️", updated!.ReactionType);
    }

    // ── RemoveReactionAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task RemoveReactionAsync_ExistingReaction_RemovesIt()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();
        var reaction = new PostReaction { PostId = postId, MusicianId = musicianId, ReactionType = "👍" };
        _db.PostReactions.Add(reaction);
        await _db.SaveChangesAsync();

        await _sut.RemoveReactionAsync(bandId, postId, musicianId, CancellationToken.None);

        var exists = await _db.PostReactions.AnyAsync(r => r.Id == reaction.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task RemoveReactionAsync_NoReaction_DoesNothing()
    {
        var (musicianId, bandId, postId) = await SeedPostAsync();

        await _sut.RemoveReactionAsync(bandId, postId, musicianId, CancellationToken.None);
    }
}
