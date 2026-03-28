using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Domain.SongBroadcast;

namespace Sheetstorm.Tests.SongBroadcast;

public class SongBroadcastHubTests
{
    private readonly SongBroadcastHub _sut;
    private readonly IHubCallerClients _mockClients;
    private readonly HubCallerContext _mockContext;
    private readonly IGroupManager _mockGroups;
    private readonly IClientProxy _mockClientProxy;
    private readonly Guid _userId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly string _connectionId = "test-connection-id";

    public SongBroadcastHubTests()
    {
        _mockClients = Substitute.For<IHubCallerClients>();
        _mockContext = Substitute.For<HubCallerContext>();
        _mockGroups = Substitute.For<IGroupManager>();
        _mockClientProxy = Substitute.For<IClientProxy>();

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _userId.ToString()),
            new Claim("name", "Test User")
        ]));

        _mockContext.ConnectionId.Returns(_connectionId);
        _mockContext.User.Returns(claims);
        _mockClients.Group(Arg.Any<string>()).Returns(_mockClientProxy);

        _sut = new SongBroadcastHub
        {
            Clients = _mockClients,
            Context = _mockContext,
            Groups = _mockGroups
        };
    }

    // ── StartBroadcast ────────────────────────────────────────────────────────

    [Fact]
    public async Task StartBroadcast_FirstBroadcast_CreatesActiveBroadcast()
    {
        await _sut.StartBroadcast(_bandId);

        await _mockGroups.Received(1).AddToGroupAsync(_connectionId, $"band-broadcast-{_bandId}", Arg.Any<CancellationToken>());
        await _mockClientProxy.Received(1).SendCoreAsync(
            "OnBroadcastStarted",
            Arg.Is<object[]>(args => args.Length == 1 && args[0] is BroadcastStartedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task StartBroadcast_AlreadyActiveBroadcast_ThrowsHubException()
    {
        await _sut.StartBroadcast(_bandId);

        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.StartBroadcast(_bandId));

        Assert.Contains("already active", ex.Message);
    }

    [Fact]
    public async Task StartBroadcast_SendsCorrectMessageToGroup()
    {
        BroadcastStartedMessage? capturedMessage = null;
        await _mockClientProxy.SendCoreAsync(
            Arg.Any<string>(),
            Arg.Do<object[]>(args => capturedMessage = args[0] as BroadcastStartedMessage),
            Arg.Any<CancellationToken>());

        await _sut.StartBroadcast(_bandId);

        Assert.NotNull(capturedMessage);
        Assert.Equal(_bandId, capturedMessage!.BandId);
        Assert.Equal(_userId, capturedMessage.ConductorId);
        Assert.Equal("Test User", capturedMessage.ConductorName);
    }

    // ── StopBroadcast ─────────────────────────────────────────────────────────

    [Fact]
    public async Task StopBroadcast_ActiveBroadcast_StopsBroadcast()
    {
        await _sut.StartBroadcast(_bandId);

        await _sut.StopBroadcast(_bandId);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnBroadcastStopped",
            Arg.Is<object[]>(args => args.Length == 1 && args[0] is BroadcastStoppedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task StopBroadcast_NoActiveBroadcast_ThrowsHubException()
    {
        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.StopBroadcast(_bandId));

        Assert.Contains("No active broadcast", ex.Message);
    }

    [Fact]
    public async Task StopBroadcast_SendsCorrectMessageToGroup()
    {
        await _sut.StartBroadcast(_bandId);

        BroadcastStoppedMessage? capturedMessage = null;
        await _mockClientProxy.SendCoreAsync(
            Arg.Any<string>(),
            Arg.Do<object[]>(args =>
            {
                if (args[0] is BroadcastStoppedMessage msg)
                    capturedMessage = msg;
            }),
            Arg.Any<CancellationToken>());

        await _sut.StopBroadcast(_bandId);

        Assert.NotNull(capturedMessage);
        Assert.Equal(_bandId, capturedMessage!.BandId);
        Assert.Equal(_userId, capturedMessage.StoppedById);
    }

    // ── SetCurrentSong ────────────────────────────────────────────────────────

    [Fact]
    public async Task SetCurrentSong_ActiveBroadcast_UpdatesCurrentSong()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();

        await _sut.SetCurrentSong(_bandId, pieceId, "Test Song");

        await _mockClientProxy.Received().SendCoreAsync(
            "OnSongChanged",
            Arg.Is<object[]>(args => args.Length == 1 && args[0] is SongChangedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SetCurrentSong_NoActiveBroadcast_ThrowsHubException()
    {
        var pieceId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.SetCurrentSong(_bandId, pieceId, "Test Song"));

        Assert.Contains("No active broadcast", ex.Message);
    }

    [Fact]
    public async Task SetCurrentSong_SendsCorrectMessageToGroup()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();

        SongChangedMessage? capturedMessage = null;
        await _mockClientProxy.SendCoreAsync(
            Arg.Any<string>(),
            Arg.Do<object[]>(args =>
            {
                if (args[0] is SongChangedMessage msg)
                    capturedMessage = msg;
            }),
            Arg.Any<CancellationToken>());

        await _sut.SetCurrentSong(_bandId, pieceId, "Test Song");

        Assert.NotNull(capturedMessage);
        Assert.Equal(_bandId, capturedMessage!.BandId);
        Assert.Equal(pieceId, capturedMessage.PieceId);
        Assert.Equal("Test Song", capturedMessage.Title);
    }

    // ── NextSong ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task NextSong_ActiveBroadcast_UpdatesSong()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();

        await _sut.NextSong(_bandId, pieceId, "Next Song");

        await _mockClientProxy.Received().SendCoreAsync(
            "OnSongChanged",
            Arg.Is<object[]>(args =>
                args.Length == 1 &&
                args[0] is SongChangedMessage),
            Arg.Any<CancellationToken>());
    }

    // ── PreviousSong ──────────────────────────────────────────────────────────

    [Fact]
    public async Task PreviousSong_ActiveBroadcast_UpdatesSong()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();

        await _sut.PreviousSong(_bandId, pieceId, "Previous Song");

        await _mockClientProxy.Received().SendCoreAsync(
            "OnSongChanged",
            Arg.Is<object[]>(args =>
                args.Length == 1 &&
                args[0] is SongChangedMessage),
            Arg.Any<CancellationToken>());
    }

    // ── JoinBroadcast ─────────────────────────────────────────────────────────

    [Fact]
    public async Task JoinBroadcast_ActiveBroadcast_ReturnsCurrentState()
    {
        await _sut.StartBroadcast(_bandId);

        var state = await _sut.JoinBroadcast(_bandId);

        Assert.NotNull(state);
        Assert.Equal(_bandId, state!.BandId);
        Assert.True(state.IsActive);
        await _mockGroups.Received().AddToGroupAsync(_connectionId, $"band-broadcast-{_bandId}", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task JoinBroadcast_NoActiveBroadcast_ReturnsNull()
    {
        var state = await _sut.JoinBroadcast(_bandId);

        Assert.Null(state);
        await _mockGroups.Received(1).AddToGroupAsync(_connectionId, $"band-broadcast-{_bandId}", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task JoinBroadcast_UpdatesParticipantCount()
    {
        await _sut.StartBroadcast(_bandId);

        await _sut.JoinBroadcast(_bandId);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnParticipantCountChanged",
            Arg.Is<object[]>(args => args[0] is ParticipantCountChangedMessage),
            Arg.Any<CancellationToken>());
    }

    // ── LeaveBroadcast ────────────────────────────────────────────────────────

    [Fact]
    public async Task LeaveBroadcast_RemovesFromGroup()
    {
        await _sut.StartBroadcast(_bandId);
        await _sut.JoinBroadcast(_bandId);

        await _sut.LeaveBroadcast(_bandId);

        await _mockGroups.Received(1).RemoveFromGroupAsync(_connectionId, $"band-broadcast-{_bandId}", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task LeaveBroadcast_UpdatesParticipantCount()
    {
        await _sut.StartBroadcast(_bandId);
        await _sut.JoinBroadcast(_bandId);

        await _sut.LeaveBroadcast(_bandId);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnParticipantCountChanged",
            Arg.Is<object[]>(args => args[0] is ParticipantCountChangedMessage),
            Arg.Any<CancellationToken>());
    }

    // ── OnDisconnectedAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task OnDisconnectedAsync_RemovesFromAllGroups()
    {
        await _sut.StartBroadcast(_bandId);
        await _sut.JoinBroadcast(_bandId);

        await _sut.OnDisconnectedAsync(null);

        await _mockGroups.Received().RemoveFromGroupAsync(_connectionId, $"band-broadcast-{_bandId}", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task OnDisconnectedAsync_UpdatesParticipantCount()
    {
        await _sut.StartBroadcast(_bandId);
        await _sut.JoinBroadcast(_bandId);

        await _sut.OnDisconnectedAsync(null);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnParticipantCountChanged",
            Arg.Is<object[]>(args => args[0] is ParticipantCountChangedMessage),
            Arg.Any<CancellationToken>());
    }

    // ── Concurrent Access ─────────────────────────────────────────────────────

    [Fact]
    public async Task ConcurrentJoins_UpdatesParticipantCountCorrectly()
    {
        await _sut.StartBroadcast(_bandId);

        var otherHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(Guid.NewGuid(), "other-connection")
        };

        await _sut.JoinBroadcast(_bandId);
        await otherHub.JoinBroadcast(_bandId);

        await _mockClientProxy.Received().SendCoreAsync(
            "OnParticipantCountChanged",
            Arg.Is<object[]>(args =>
                args.Length == 1 &&
                args[0] is ParticipantCountChangedMessage),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task MultipleBands_IsolatesBroadcasts()
    {
        var band1 = Guid.NewGuid();
        var band2 = Guid.NewGuid();

        await _sut.StartBroadcast(band1);

        var otherHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(Guid.NewGuid(), "other-connection")
        };

        await otherHub.StartBroadcast(band2);

        await _mockGroups.Received(1).AddToGroupAsync(_connectionId, $"band-broadcast-{band1}", Arg.Any<CancellationToken>());
        await _mockGroups.Received(1).AddToGroupAsync("other-connection", $"band-broadcast-{band2}", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SongChange_OnlyAffectsActiveBroadcast()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();

        await _sut.SetCurrentSong(_bandId, pieceId, "Song 1");

        var otherBandId = Guid.NewGuid();
        var ex = await Assert.ThrowsAsync<HubException>(
            () => _sut.SetCurrentSong(otherBandId, Guid.NewGuid(), "Song 2"));

        Assert.Contains("No active broadcast", ex.Message);
    }

    // ── State Preservation ────────────────────────────────────────────────────

    [Fact]
    public async Task BroadcastState_PreservesCurrentSong()
    {
        await _sut.StartBroadcast(_bandId);
        var pieceId = Guid.NewGuid();
        await _sut.SetCurrentSong(_bandId, pieceId, "Test Song");

        var otherHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(Guid.NewGuid(), "other-connection")
        };

        var state = await otherHub.JoinBroadcast(_bandId);

        Assert.NotNull(state);
        Assert.NotNull(state!.CurrentSong);
        Assert.Equal(pieceId, state.CurrentSong!.PieceId);
        Assert.Equal("Test Song", state.CurrentSong.Title);
    }

    [Fact]
    public async Task BroadcastState_TracksParticipantCount()
    {
        await _sut.StartBroadcast(_bandId);
        var state1 = await _sut.JoinBroadcast(_bandId);

        var otherHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(Guid.NewGuid(), "other-connection")
        };
        var state2 = await otherHub.JoinBroadcast(_bandId);

        Assert.NotNull(state2);
        Assert.True(state2!.ParticipantCount >= 1);
    }

    // ── User Authentication ───────────────────────────────────────────────────

    [Fact]
    public async Task StartBroadcast_UnauthenticatedUser_ThrowsHubException()
    {
        var unauthHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(null, _connectionId)
        };

        var ex = await Assert.ThrowsAsync<HubException>(
            () => unauthHub.StartBroadcast(_bandId));

        Assert.Contains("not authenticated", ex.Message);
    }

    [Fact]
    public async Task SetCurrentSong_UnauthenticatedUser_ThrowsHubException()
    {
        var unauthHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(null, _connectionId)
        };

        var ex = await Assert.ThrowsAsync<HubException>(
            () => unauthHub.SetCurrentSong(_bandId, Guid.NewGuid(), "Song"));

        Assert.Contains("not authenticated", ex.Message);
    }

    [Fact]
    public async Task JoinBroadcast_UnauthenticatedUser_ThrowsHubException()
    {
        var unauthHub = new SongBroadcastHub
        {
            Clients = _mockClients,
            Groups = _mockGroups,
            Context = CreateMockContext(null, _connectionId)
        };

        var ex = await Assert.ThrowsAsync<HubException>(
            () => unauthHub.JoinBroadcast(_bandId));

        Assert.Contains("not authenticated", ex.Message);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private HubCallerContext CreateMockContext(Guid? userId, string connectionId)
    {
        var context = Substitute.For<HubCallerContext>();
        context.ConnectionId.Returns(connectionId);

        if (userId.HasValue)
        {
            var claims = new ClaimsPrincipal(new ClaimsIdentity([
                new Claim(JwtRegisteredClaimNames.Sub, userId.Value.ToString()),
                new Claim("name", "Test User")
            ]));
            context.User.Returns(claims);
        }
        else
        {
            context.User.Returns((ClaimsPrincipal?)null);
        }

        return context;
    }
}
