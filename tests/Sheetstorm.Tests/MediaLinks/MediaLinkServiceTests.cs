using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.MediaLinks;
using Sheetstorm.Infrastructure.MediaLinks;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.MediaLinks;

public class MediaLinkServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly MediaLinkService _sut;

    public MediaLinkServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new MediaLinkService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId, Guid pieceId)> SeedMemberWithPieceAsync(MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, IsActive = true, Role = role };
        var piece = new Piece { BandId = band.Id, Title = "Test Piece" };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id, piece.Id);
    }

    // ── GetAllForPieceAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task GetAllForPieceAsync_ReturnsAllLinksForPiece()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync();
        var musician = await _db.Musicians.FindAsync(musicianId);

        var link1 = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://youtube.com/watch?v=abc",
            Type = MediaLinkType.YouTube,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        var link2 = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://spotify.com/track/xyz",
            Type = MediaLinkType.Spotify,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        _db.MediaLinks.AddRange(link1, link2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllForPieceAsync(bandId, pieceId, musicianId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Contains(result, l => l.Type == MediaLinkType.YouTube);
        Assert.Contains(result, l => l.Type == MediaLinkType.Spotify);
    }

    [Fact]
    public async Task GetAllForPieceAsync_PieceNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId, _) = await SeedMemberWithPieceAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAllForPieceAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetAllForPieceAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId, pieceId) = await SeedMemberWithPieceAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAllForPieceAsync(bandId, pieceId, Guid.NewGuid(), CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── CreateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_YouTubeUrl_DetectsYouTubeLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "Rick Roll", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.YouTube, result.Type);
        Assert.Contains("youtube.com", result.Url.ToLowerInvariant());
    }

    [Fact]
    public async Task CreateAsync_YouTubeShortUrl_DetectsYouTubeLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://youtu.be/dQw4w9WgXcQ", "Rick Roll", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.YouTube, result.Type);
    }

    [Fact]
    public async Task CreateAsync_SpotifyUrl_DetectsSpotifyLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://open.spotify.com/track/abc123", "Spotify Track", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.Spotify, result.Type);
    }

    [Fact]
    public async Task CreateAsync_SoundCloudUrl_DetectsSoundCloudLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://soundcloud.com/artist/track", "SoundCloud Track", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.SoundCloud, result.Type);
    }

    [Fact]
    public async Task CreateAsync_AppleMusicUrl_DetectsAppleMusicLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://music.apple.com/us/album/song/123456", "Apple Music", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.AppleMusic, result.Type);
    }

    [Fact]
    public async Task CreateAsync_OtherUrl_DetectsOtherLinkType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://example.com/music/track", "Other Link", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.Other, result.Type);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesLink()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Administrator);
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test Video", "Test Description");

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Test Video", result.Title);
        Assert.Equal("Test Description", result.Description);
        Assert.Equal(musicianId, result.AddedByMusicianId);
    }

    [Fact]
    public async Task CreateAsync_DuplicateUrl_ThrowsConflict()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var url = "https://youtube.com/watch?v=test";
        var musician = await _db.Musicians.FindAsync(musicianId);

        _db.MediaLinks.Add(new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = url,
            Type = MediaLinkType.YouTube,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        });
        await _db.SaveChangesAsync();

        var request = new CreateMediaLinkRequest(url, "Duplicate", null);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
        Assert.Contains("already exists", ex.Message);
    }

    [Fact]
    public async Task CreateAsync_NotAuthorizedRole_ThrowsForbidden()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Musician);
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task CreateAsync_SheetMusicManager_CanCreate()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.SheetMusicManager);
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.NotEqual(Guid.Empty, result.Id);
    }

    [Fact]
    public async Task CreateAsync_PieceNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId, _) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateAsync(bandId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── UpdateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateAsync_ValidUpdate_UpdatesFields()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var link = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://youtube.com/watch?v=test",
            Type = MediaLinkType.YouTube,
            Title = "Old Title",
            Description = "Old Description",
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        _db.MediaLinks.Add(link);
        await _db.SaveChangesAsync();

        var request = new UpdateMediaLinkRequest("New Title", "New Description");
        var result = await _sut.UpdateAsync(bandId, pieceId, link.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("New Title", result.Title);
        Assert.Equal("New Description", result.Description);
        Assert.Equal(link.Url, result.Url);
    }

    [Fact]
    public async Task UpdateAsync_NotAuthorizedRole_ThrowsForbidden()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var link = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://youtube.com/watch?v=test",
            Type = MediaLinkType.YouTube,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        _db.MediaLinks.Add(link);
        await _db.SaveChangesAsync();

        var request = new UpdateMediaLinkRequest("New Title", null);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateAsync(bandId, pieceId, link.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateAsync_LinkNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new UpdateMediaLinkRequest("Title", null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateAsync(bandId, pieceId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_ValidDelete_DeletesLink()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var link = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://youtube.com/watch?v=test",
            Type = MediaLinkType.YouTube,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        _db.MediaLinks.Add(link);
        await _db.SaveChangesAsync();

        await _sut.DeleteAsync(bandId, pieceId, link.Id, musicianId, CancellationToken.None);

        var deleted = await _db.MediaLinks.FindAsync(link.Id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task DeleteAsync_NotAuthorizedRole_ThrowsForbidden()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var link = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = "https://youtube.com/watch?v=test",
            Type = MediaLinkType.YouTube,
            AddedByMusicianId = musicianId,
            AddedByMusician = musician!
        };
        _db.MediaLinks.Add(link);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteAsync(bandId, pieceId, link.Id, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task DeleteAsync_LinkNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteAsync(bandId, pieceId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── URL Validation Edge Cases ────────────────────────────────────────────

    [Theory]
    [InlineData("https://youtube.com/watch?v=test", MediaLinkType.YouTube)]
    [InlineData("https://www.youtube.com/watch?v=test", MediaLinkType.YouTube)]
    [InlineData("https://youtu.be/test", MediaLinkType.YouTube)]
    [InlineData("https://open.spotify.com/track/test", MediaLinkType.Spotify)]
    [InlineData("https://www.spotify.com/artist/test", MediaLinkType.Spotify)]
    [InlineData("https://soundcloud.com/artist/track", MediaLinkType.SoundCloud)]
    [InlineData("https://www.soundcloud.com/test", MediaLinkType.SoundCloud)]
    [InlineData("https://music.apple.com/us/album/test", MediaLinkType.AppleMusic)]
    [InlineData("https://example.com/test", MediaLinkType.Other)]
    [InlineData("https://vimeo.com/test", MediaLinkType.Other)]
    public async Task CreateAsync_UrlValidation_DetectsCorrectType(string url, MediaLinkType expectedType)
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest(url, "Test", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(expectedType, result.Type);
    }

    [Fact]
    public async Task CreateAsync_UrlCaseInsensitive_DetectsCorrectType()
    {
        var (musicianId, bandId, pieceId) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var request = new CreateMediaLinkRequest("https://YOUTUBE.COM/watch?v=test", "Test", null);

        var result = await _sut.CreateAsync(bandId, pieceId, request, musicianId, CancellationToken.None);

        Assert.Equal(MediaLinkType.YouTube, result.Type);
    }

    // ── Band-scoped access ────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_DifferentBandPiece_ThrowsNotFound()
    {
        var (musicianId, bandId, _) = await SeedMemberWithPieceAsync(MemberRole.Conductor);
        var otherBand = new Band { Name = "Other Band" };
        var otherPiece = new Piece { BandId = otherBand.Id, Title = "Other Piece" };
        _db.Bands.Add(otherBand);
        _db.Pieces.Add(otherPiece);
        await _db.SaveChangesAsync();

        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateAsync(bandId, otherPiece.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }
}
