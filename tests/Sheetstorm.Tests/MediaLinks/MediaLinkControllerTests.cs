using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.MediaLinks;
using Sheetstorm.Infrastructure.MediaLinks;

namespace Sheetstorm.Tests.MediaLinks;

public class MediaLinkControllerTests
{
    private readonly IMediaLinkService _mediaLinkService;
    private readonly MediaLinkController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly Guid _pieceId = Guid.NewGuid();

    public MediaLinkControllerTests()
    {
        _mediaLinkService = Substitute.For<IMediaLinkService>();
        _sut = new MediaLinkController(_mediaLinkService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static MediaLinkDto MakeLinkDto(Guid id, string url, MediaLinkType type = MediaLinkType.YouTube) =>
        new(id, url, type, "Test Title", "Test Description", null, null, Guid.NewGuid(), "Test User", DateTime.UtcNow);

    // ── GET /api/bands/{bandId}/pieces/{pieceId}/media-links ─────────────────

    [Fact]
    public async Task GetAll_ReturnsOkWithList()
    {
        var links = new List<MediaLinkDto>
        {
            MakeLinkDto(Guid.NewGuid(), "https://youtube.com/1", MediaLinkType.YouTube),
            MakeLinkDto(Guid.NewGuid(), "https://spotify.com/2", MediaLinkType.Spotify)
        };
        _mediaLinkService.GetAllForPieceAsync(_bandId, _pieceId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(links);

        var result = await _sut.GetAll(_bandId, _pieceId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<MediaLinkDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetAll_DelegatesCurrentUserIdToService()
    {
        _mediaLinkService.GetAllForPieceAsync(_bandId, _pieceId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(new List<MediaLinkDto>());

        await _sut.GetAll(_bandId, _pieceId, CancellationToken.None);

        await _mediaLinkService.Received(1).GetAllForPieceAsync(_bandId, _pieceId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetAll_ServiceThrowsDomainException_Propagates()
    {
        _mediaLinkService.GetAllForPieceAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Piece not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAll(_bandId, _pieceId, CancellationToken.None));
    }

    // ── POST /api/bands/{bandId}/pieces/{pieceId}/media-links ────────────────

    [Fact]
    public async Task Create_ValidRequest_Returns201WithDto()
    {
        var linkId = Guid.NewGuid();
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test Video", "Test Desc");
        var expected = MakeLinkDto(linkId, "https://youtube.com/watch?v=test");
        _mediaLinkService.CreateAsync(_bandId, _pieceId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.Create(_bandId, _pieceId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<MediaLinkDto>(created.Value);
        Assert.Equal(linkId, returned.Id);
    }

    [Fact]
    public async Task Create_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Url", "Required");
        var request = new CreateMediaLinkRequest("", null, null);

        var result = await _sut.Create(_bandId, _pieceId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Create_DuplicateUrl_DomainExceptionPropagates()
    {
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);
        _mediaLinkService.CreateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CreateMediaLinkRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Link already exists.", 409));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Create(_bandId, _pieceId, request, CancellationToken.None));
    }

    [Fact]
    public async Task Create_NotAuthorized_DomainExceptionPropagates()
    {
        var request = new CreateMediaLinkRequest("https://youtube.com/watch?v=test", "Test", null);
        _mediaLinkService.CreateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CreateMediaLinkRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Not authorized.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Create(_bandId, _pieceId, request, CancellationToken.None));
    }

    // ── PUT /api/bands/{bandId}/pieces/{pieceId}/media-links/{linkId} ────────

    [Fact]
    public async Task Update_ValidRequest_ReturnsOkWithUpdatedDto()
    {
        var linkId = Guid.NewGuid();
        var request = new UpdateMediaLinkRequest("Updated Title", "Updated Description");
        var expected = MakeLinkDto(linkId, "https://youtube.com/watch?v=test");
        _mediaLinkService.UpdateAsync(_bandId, _pieceId, linkId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.Update(_bandId, _pieceId, linkId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<MediaLinkDto>(ok.Value);
        Assert.Equal(linkId, returned.Id);
    }

    [Fact]
    public async Task Update_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Too long");
        var request = new UpdateMediaLinkRequest("Too long title that exceeds the maximum length allowed", null);

        var result = await _sut.Update(_bandId, _pieceId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Update_LinkNotFound_DomainExceptionPropagates()
    {
        var request = new UpdateMediaLinkRequest("Title", null);
        _mediaLinkService.UpdateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateMediaLinkRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Media link not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Update(_bandId, _pieceId, Guid.NewGuid(), request, CancellationToken.None));
    }

    [Fact]
    public async Task Update_NotAuthorized_DomainExceptionPropagates()
    {
        var request = new UpdateMediaLinkRequest("Title", null);
        _mediaLinkService.UpdateAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateMediaLinkRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Not authorized.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Update(_bandId, _pieceId, Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── DELETE /api/bands/{bandId}/pieces/{pieceId}/media-links/{linkId} ─────

    [Fact]
    public async Task Delete_ValidRequest_Returns204NoContent()
    {
        var linkId = Guid.NewGuid();
        _mediaLinkService.DeleteAsync(_bandId, _pieceId, linkId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Delete(_bandId, _pieceId, linkId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_PassesCorrectIdsToService()
    {
        var linkId = Guid.NewGuid();
        _mediaLinkService.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        await _sut.Delete(_bandId, _pieceId, linkId, CancellationToken.None);

        await _mediaLinkService.Received(1).DeleteAsync(_bandId, _pieceId, linkId, _musicianId, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Delete_LinkNotFound_DomainExceptionPropagates()
    {
        _mediaLinkService.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Media link not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Delete(_bandId, _pieceId, Guid.NewGuid(), CancellationToken.None));
    }

    [Fact]
    public async Task Delete_NotAuthorized_DomainExceptionPropagates()
    {
        _mediaLinkService.DeleteAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Not authorized.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.Delete(_bandId, _pieceId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── Band-scoped access ────────────────────────────────────────────────────

    [Fact]
    public async Task BandScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        var foreignBandId = Guid.NewGuid();
        _mediaLinkService.GetAllForPieceAsync(foreignBandId, _pieceId, _musicianId, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Piece not found or no access.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetAll(foreignBandId, _pieceId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }
}
