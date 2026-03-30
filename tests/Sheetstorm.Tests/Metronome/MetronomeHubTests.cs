using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Metronome;
using Sheetstorm.Infrastructure.Metronome;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Metronome;

public class MetronomeHubTests : IDisposable
{
    private readonly MetronomeHub _sut;
    private readonly IHubCallerClients _mockClients;
    private readonly HubCallerContext _mockContext;
    private readonly IGroupManager _mockGroups;
    private readonly IClientProxy _mockClientProxy;
    private readonly AppDbContext _db;
    private readonly IMetronomeSessionManager _sessionManager;

    private readonly Guid _conductorId = Guid.NewGuid();
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private const string ConnectionId = "test-conn";

    public MetronomeHubTests()
    {
        _mockClients = Substitute.For<IHubCallerClients>();
        _mockContext = Substitute.For<HubCallerContext>();
        _mockGroups = Substitute.For<IGroupManager>();
        _mockClientProxy = Substitute.For<IClientProxy>();

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

        _mockContext.ConnectionId.Returns(ConnectionId);
        _mockClients.Group(Arg.Any<string>()).Returns(_mockClientProxy);

        _sut = CreateHubForUser(_conductorId, "Hans Dirigent");
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    private MetronomeHub CreateHubForUser(Guid userId, string name)
    {
        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim("name", name)
        ]));
        _mockContext.User.Returns(claims);

        return new MetronomeHub(_db, _sessionManager)
        {
            Clients = _mockClients,
            Context = _mockContext,
            Groups = _mockGroups
        };
    }

    // ── StartSession ──────────────────────────────────────────────────────────

    [Fact]
    public async Task StartSession_Conductor_BroadcastsOnSessionStarted()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);

        await _mockClientProxy.Received(1).SendCoreAsync(
            "OnSessionStarted",
            Arg.Is<object[]>(a => a.Length == 1 && a[0] is SessionStartedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task StartSession_Conductor_SessionStartedMessageHasCorrectBpm()
    {
        SessionStartedMessage? captured = null;
        await _mockClientProxy.SendCoreAsync(
            Arg.Any<string>(),
            Arg.Do<object[]>(a => captured = a[0] as SessionStartedMessage),
            Arg.Any<CancellationToken>());

        await _sut.StartSession(_bandId, 120, 4, 4);

        Assert.NotNull(captured);
        Assert.Equal(_bandId, captured!.BandId);
        Assert.Equal(120, captured.Bpm);
        Assert.Equal(4, captured.BeatsPerMeasure);
        Assert.Equal(4, captured.BeatUnit);
        Assert.Equal(_conductorId, captured.ConductorId);
    }

    [Fact]
    public async Task StartSession_SessionAlreadyActive_ThrowsHubException()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);

        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.StartSession(_bandId, 100, 3, 4));

        Assert.Contains("already", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task StartSession_Musician_ThrowsHubException()
    {
        var musicianHub = CreateHubForUser(_musicianId, "Max Musiker");

        var ex = await Assert.ThrowsAsync<HubException>(
            () => musicianHub.StartSession(_bandId, 120, 4, 4));

        Assert.Contains("conductor", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task StartSession_BpmOutOfRange_ThrowsHubException()
    {
        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.StartSession(_bandId, 5, 4, 4)); // below min 20

        Assert.Contains("BPM", ex.Message);
    }

    // ── StopSession ───────────────────────────────────────────────────────────

    [Fact]
    public async Task StopSession_ActiveSession_BroadcastsOnSessionStopped()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);

        await _sut.StopSession(_bandId);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnSessionStopped",
            Arg.Is<object[]>(a => a.Length == 1 && a[0] is SessionStoppedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task StopSession_NoActiveSession_ThrowsHubException()
    {
        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.StopSession(_bandId));

        Assert.Contains("No active", ex.Message);
    }

    [Fact]
    public async Task StopSession_Musician_ThrowsHubException()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);
        var musicianHub = CreateHubForUser(_musicianId, "Max Musiker");

        var ex = await Assert.ThrowsAsync<HubException>(
            () => musicianHub.StopSession(_bandId));

        Assert.Contains("conductor", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    // ── UpdateSession ─────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateSession_ActiveSession_BroadcastsOnSessionUpdated()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);

        await _sut.UpdateSession(_bandId, 90, 3, 4);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnSessionUpdated",
            Arg.Is<object[]>(a => a.Length == 1 && a[0] is SessionUpdatedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateSession_NoActiveSession_ThrowsHubException()
    {
        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.UpdateSession(_bandId, 90, 3, 4));

        Assert.Contains("No active", ex.Message);
    }

    // ── JoinSession ───────────────────────────────────────────────────────────

    [Fact]
    public async Task JoinSession_Member_AddsToGroup()
    {
        await _sut.JoinSession(_bandId);

        await _mockGroups.Received(1).AddToGroupAsync(
            ConnectionId,
            Arg.Is<string>(s => s.Contains(_bandId.ToString())),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task JoinSession_WithActiveSession_ReturnsSessionState()
    {
        await _sut.StartSession(_bandId, 120, 4, 4);

        var result = await _sut.JoinSession(_bandId);

        Assert.NotNull(result);
        Assert.Equal(120, result!.Bpm);
    }

    [Fact]
    public async Task JoinSession_NoActiveSession_ReturnsNull()
    {
        var result = await _sut.JoinSession(_bandId);

        Assert.Null(result);
    }

    [Fact]
    public async Task JoinSession_NonMember_ThrowsHubException()
    {
        var outsiderId = Guid.NewGuid();
        var outsiderHub = CreateHubForUser(outsiderId, "Outsider");

        var ex = await Assert.ThrowsAsync<HubException>(
            () => outsiderHub.JoinSession(_bandId));

        Assert.Contains("member", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    // ── LeaveSession ──────────────────────────────────────────────────────────

    [Fact]
    public async Task LeaveSession_Member_RemovesFromGroup()
    {
        await _sut.JoinSession(_bandId);

        await _sut.LeaveSession(_bandId);

        await _mockGroups.Received(1).RemoveFromGroupAsync(
            ConnectionId,
            Arg.Is<string>(s => s.Contains(_bandId.ToString())),
            Arg.Any<CancellationToken>());
    }

    // ── RequestClockSync ──────────────────────────────────────────────────────

    [Fact]
    public async Task RequestClockSync_Member_ReturnsClockSyncResponse()
    {
        var clientSendTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L;

        await _sut.RequestClockSync(_bandId, clientSendTime);

        await _mockClients.Received().Caller.SendCoreAsync(
            "OnClockSyncResponse",
            Arg.Is<object[]>(a => a.Length == 1 && a[0] is MetronomeClockSyncResponseMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RequestClockSync_ResponseContainsClientSendTime()
    {
        var clientSendTime = 1234567890L;
        MetronomeClockSyncResponseMessage? captured = null;
        _mockClients.Caller.SendCoreAsync(
            Arg.Any<string>(),
            Arg.Do<object[]>(a => captured = a[0] as MetronomeClockSyncResponseMessage),
            Arg.Any<CancellationToken>());

        await _sut.RequestClockSync(_bandId, clientSendTime);

        Assert.NotNull(captured);
        Assert.Equal(clientSendTime, captured!.ClientSendTimeUs);
        Assert.True(captured.ServerRecvTimeUs > 0);
        Assert.True(captured.ServerSendTimeUs >= captured.ServerRecvTimeUs);
    }
}
