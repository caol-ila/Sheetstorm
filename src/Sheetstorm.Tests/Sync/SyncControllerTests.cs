using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using Moq;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Sync;
using Sheetstorm.Infrastructure.Sync;
using Xunit;

namespace Sheetstorm.Tests.Sync;

public class SyncControllerTests
{
    private readonly Mock<ISyncService> _mockService;
    private readonly SyncController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();

    public SyncControllerTests()
    {
        _mockService = new Mock<ISyncService>();
        _sut = new SyncController(_mockService.Object);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    // ── GET /api/sync/state ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetState_ReturnsOkWithSyncState()
    {
        var state = new SyncStateResponse(42, DateTime.UtcNow, 3);
        _mockService.Setup(s => s.GetStateAsync(_musicianId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(state);

        var result = await _sut.GetState(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(state, ok.Value);
    }

    // ── POST /api/sync/pull ───────────────────────────────────────────────────────

    [Fact]
    public async Task Pull_ValidRequest_ReturnsOkWithChanges()
    {
        var response = new PullResponse([], 42, false);
        _mockService.Setup(s => s.PullAsync(_musicianId, It.IsAny<PullRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(response);

        var result = await _sut.Pull(new PullRequest(38), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(response, ok.Value);
    }

    [Fact]
    public async Task Pull_PassesSinceVersionToService()
    {
        _mockService.Setup(s => s.PullAsync(It.IsAny<Guid>(), It.IsAny<PullRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PullResponse([], 5, false));

        await _sut.Pull(new PullRequest(5), CancellationToken.None);

        _mockService.Verify(s => s.PullAsync(
            _musicianId,
            It.Is<PullRequest>(r => r.SinceVersion == 5),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    // ── POST /api/sync/push ───────────────────────────────────────────────────────

    [Fact]
    public async Task Push_ValidRequest_ReturnsOkWithPushResponse()
    {
        var response = new PushResponse([], [], 10);
        _mockService.Setup(s => s.PushAsync(_musicianId, It.IsAny<PushRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(response);

        var result = await _sut.Push(new PushRequest(9, []), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(response, ok.Value);
    }

    [Fact]
    public async Task Push_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("changes", "Required");

        var result = await _sut.Push(new PushRequest(0, []), CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Push_PassesRequestToService()
    {
        var changes = new List<PushChangeEntry>
        {
            new(Guid.NewGuid().ToString(), "Piece", Guid.NewGuid(), "Update", "title", "New Title", null, DateTime.UtcNow)
        };
        _mockService.Setup(s => s.PushAsync(It.IsAny<Guid>(), It.IsAny<PushRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PushResponse([], [], 1));

        await _sut.Push(new PushRequest(0, changes), CancellationToken.None);

        _mockService.Verify(s => s.PushAsync(
            _musicianId,
            It.Is<PushRequest>(r => r.Changes.Count == 1),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    // ── POST /api/sync/resolve ────────────────────────────────────────────────────

    [Fact]
    public async Task Resolve_ValidRequest_ReturnsNoContent()
    {
        _mockService.Setup(s => s.ResolveAsync(_musicianId, It.IsAny<ResolveRequest>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await _sut.Resolve(new ResolveRequest([]), CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
