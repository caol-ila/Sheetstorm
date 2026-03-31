using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Metronome;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Metronome;

public class MetronomeControllerTests : IDisposable
{
    private readonly MetronomeController _sut;
    private readonly AppDbContext _db;
    private readonly IMetronomeSessionManager _sessionManager;

    private readonly Guid _conductorId = Guid.NewGuid();
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public MetronomeControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new AppDbContext(options);

        _db.Musicians.Add(new Musician { Id = _conductorId, Email = "conductor@test.com", Name = "Hans Dirigent" });
        _db.Musicians.Add(new Musician { Id = _musicianId, Email = "musician@test.com", Name = "Max Musiker" });
        _db.Bands.Add(new Band { Id = _bandId, Name = "Testkapelle" });
        _db.Memberships.Add(new Membership { MusicianId = _conductorId, BandId = _bandId, Role = MemberRole.Conductor, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = _musicianId, BandId = _bandId, Role = MemberRole.Musician, IsActive = true });
        _db.SaveChanges();

        _sessionManager = new MetronomeSessionManager();

        _sut = CreateControllerForUser(_conductorId, "Hans Dirigent");
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    private MetronomeController CreateControllerForUser(Guid userId, string name)
    {
        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim("name", name)
        ]));

        var controller = new MetronomeController(_db, _sessionManager)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = claims }
            }
        };
        return controller;
    }

    // ── GET /status ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetStatus_NoActiveSession_ReturnsIsRunningFalse()
    {
        var result = await _sut.GetStatus(_bandId, CancellationToken.None) as OkObjectResult;

        Assert.NotNull(result);
        var response = result!.Value as MetronomeStatusResponse;
        Assert.NotNull(response);
        Assert.False(response!.IsRunning);
    }

    [Fact]
    public async Task GetStatus_ActiveSession_ReturnsSessionInfo()
    {
        _sessionManager.StartSession(_bandId, 120, 4, 4, _conductorId, "Hans Dirigent");

        var result = await _sut.GetStatus(_bandId, CancellationToken.None) as OkObjectResult;

        var response = result!.Value as MetronomeStatusResponse;
        Assert.NotNull(response);
        Assert.True(response!.IsRunning);
        Assert.Equal(120, response.Bpm);
        Assert.Equal("Hans Dirigent", response.ConductorName);
    }

    // ── POST /start ───────────────────────────────────────────────────────

    [Fact]
    public async Task Start_Conductor_ReturnsOk()
    {
        var request = new StartMetronomeRequest(120, 4, 4);

        var result = await _sut.Start(_bandId, request, CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
    }

    [Fact]
    public async Task Start_SessionAlreadyActive_ReturnsConflict()
    {
        _sessionManager.StartSession(_bandId, 120, 4, 4, _conductorId, "Hans Dirigent");

        var result = await _sut.Start(_bandId, new StartMetronomeRequest(100, 3, 4), CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
    }

    [Fact]
    public async Task Start_Musician_ReturnsForbidden()
    {
        var musicianController = CreateControllerForUser(_musicianId, "Max Musiker");

        var result = await musicianController.Start(_bandId, new StartMetronomeRequest(120, 4, 4), CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public async Task Start_InvalidBpm_ReturnsBadRequest()
    {
        var result = await _sut.Start(_bandId, new StartMetronomeRequest(5, 4, 4), CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    // ── POST /stop ────────────────────────────────────────────────────────

    [Fact]
    public async Task Stop_ActiveSession_ReturnsNoContent()
    {
        _sessionManager.StartSession(_bandId, 120, 4, 4, _conductorId, "Hans Dirigent");

        var result = await _sut.Stop(_bandId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Stop_NoActiveSession_ReturnsNotFound()
    {
        var result = await _sut.Stop(_bandId, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Stop_Musician_ReturnsForbidden()
    {
        _sessionManager.StartSession(_bandId, 120, 4, 4, _conductorId, "Hans Dirigent");
        var musicianController = CreateControllerForUser(_musicianId, "Max Musiker");

        var result = await musicianController.Stop(_bandId, CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }

    // ── POST /sync ────────────────────────────────────────────────────────

    [Fact]
    public async Task Sync_Member_ReturnsClockSyncResponse()
    {
        var musicianController = CreateControllerForUser(_musicianId, "Max Musiker");
        var clientTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;

        var result = await musicianController.Sync(_bandId, new ClockSyncRequest(clientTime), CancellationToken.None) as OkObjectResult;

        Assert.NotNull(result);
        var response = result!.Value as ClockSyncResponse;
        Assert.NotNull(response);
        Assert.Equal(clientTime, response!.ClientSendTimeUs);
        Assert.True(response.ServerRecvTimeUs > 0);
    }

    [Fact]
    public async Task Sync_NonMember_ReturnsForbidden()
    {
        var outsiderId = Guid.NewGuid();
        var outsiderController = CreateControllerForUser(outsiderId, "Outsider");

        var result = await outsiderController.Sync(_bandId, new ClockSyncRequest(12345L), CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }
}
