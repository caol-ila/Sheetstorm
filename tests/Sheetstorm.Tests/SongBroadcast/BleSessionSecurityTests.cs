using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.SongBroadcast;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.SongBroadcast;

public class BleSessionSecurityTests : IDisposable
{
    private readonly SongBroadcastHub _sut;
    private readonly IHubCallerClients _mockClients;
    private readonly HubCallerContext _mockContext;
    private readonly IGroupManager _mockGroups;
    private readonly IClientProxy _mockClientProxy;
    private readonly AppDbContext _db;
    private readonly Guid _userId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly string _connectionId = "ble-test-connection";

    public BleSessionSecurityTests()
    {
        _mockClients = Substitute.For<IHubCallerClients>();
        _mockContext = Substitute.For<HubCallerContext>();
        _mockGroups = Substitute.For<IGroupManager>();
        _mockClientProxy = Substitute.For<IClientProxy>();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new AppDbContext(options);

        _db.Musicians.Add(new Musician { Id = _userId, Email = "conductor@test.com", Name = "Test Conductor" });
        _db.Bands.Add(new Band { Id = _bandId, Name = "Test Band" });
        _db.Memberships.Add(new Membership { MusicianId = _userId, BandId = _bandId, Role = MemberRole.Conductor, IsActive = true });
        _db.SaveChanges();

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _userId.ToString()),
            new Claim("name", "Test Conductor")
        ]));

        _mockContext.ConnectionId.Returns(_connectionId);
        _mockContext.User.Returns(claims);
        _mockClients.Group(Arg.Any<string>()).Returns(_mockClientProxy);

        _sut = new SongBroadcastHub(_db)
        {
            Clients = _mockClients,
            Context = _mockContext,
            Groups = _mockGroups
        };
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Session Key Generation ────────────────────────────────────────────────

    [Fact]
    public async Task StartBroadcast_GeneratesSessionKey_With32Bytes()
    {
        var bleInfo = await _sut.StartBroadcast(_bandId);

        Assert.NotNull(bleInfo);
        var keyBytes = Convert.FromBase64String(bleInfo.SessionKey);
        Assert.Equal(32, keyBytes.Length);
    }

    [Fact]
    public async Task StartBroadcast_ReturnsBleSessionInfo()
    {
        var bleInfo = await _sut.StartBroadcast(_bandId);

        Assert.NotNull(bleInfo);
        Assert.NotNull(bleInfo.SessionKey);
        Assert.NotNull(bleInfo.LeaderDeviceId);
        Assert.True(bleInfo.ExpiresAt > DateTime.UtcNow);
        Assert.True(bleInfo.ExpiresAt <= DateTime.UtcNow.AddHours(4).AddSeconds(5));
    }

    [Fact]
    public async Task JoinBroadcast_IncludesBleSessionInfo()
    {
        await _sut.StartBroadcast(_bandId);

        var memberId = SeedMember(_bandId);
        var memberHub = CreateHubForUser(memberId, "member-connection");

        var state = await memberHub.JoinBroadcast(_bandId);

        Assert.NotNull(state);
        Assert.NotNull(state!.BleSession);
        Assert.NotNull(state.BleSession!.SessionKey);
        Assert.NotNull(state.BleSession.LeaderDeviceId);
    }

    [Fact]
    public async Task StartBroadcast_TwoSessions_ProduceUniqueKeys()
    {
        var bleInfo1 = await _sut.StartBroadcast(_bandId);

        // Stop first session so we can start a new one
        await _sut.StopBroadcast(_bandId);

        var bleInfo2 = await _sut.StartBroadcast(_bandId);

        Assert.NotEqual(bleInfo1.SessionKey, bleInfo2.SessionKey);
    }

    [Fact]
    public async Task StartBroadcast_ResponseIncludesLeaderDeviceId()
    {
        var bleInfo = await _sut.StartBroadcast(_bandId);

        Assert.NotNull(bleInfo.LeaderDeviceId);
        Assert.True(Guid.TryParse(bleInfo.LeaderDeviceId, out _),
            "LeaderDeviceId should be a valid GUID");
    }

    // ── GetBleSessionInfo Hub Method ──────────────────────────────────────────

    [Fact]
    public async Task GetBleSessionInfo_ActiveBroadcast_ReturnsInfo()
    {
        await _sut.StartBroadcast(_bandId);

        var bleInfo = await _sut.GetBleSessionInfo(_bandId);

        Assert.NotNull(bleInfo);
        Assert.NotNull(bleInfo!.SessionKey);
    }

    [Fact]
    public async Task GetBleSessionInfo_NoBroadcast_ReturnsNull()
    {
        var bleInfo = await _sut.GetBleSessionInfo(_bandId);

        Assert.Null(bleInfo);
    }

    [Fact]
    public async Task GetBleSessionInfo_NonMember_ThrowsHubException()
    {
        await _sut.StartBroadcast(_bandId);

        var outsiderId = Guid.NewGuid();
        _db.Musicians.Add(new Musician { Id = outsiderId, Email = "outsider@test.com", Name = "Outsider" });
        _db.SaveChanges();

        var outsiderHub = CreateHubForUser(outsiderId, "outsider-connection");

        await Assert.ThrowsAsync<HubException>(
            () => outsiderHub.GetBleSessionInfo(_bandId));
    }

    // ── Cleanup on Stop ───────────────────────────────────────────────────────

    [Fact]
    public async Task StopBroadcast_CleansUpBleSessionInfo()
    {
        await _sut.StartBroadcast(_bandId);
        await _sut.StopBroadcast(_bandId);

        var bleInfo = await _sut.GetBleSessionInfo(_bandId);

        Assert.Null(bleInfo);
    }

    [Fact]
    public async Task SessionKey_ExpiresInFourHours()
    {
        var bleInfo = await _sut.StartBroadcast(_bandId);

        var expectedExpiry = DateTime.UtcNow.AddHours(4);
        var drift = Math.Abs((bleInfo.ExpiresAt - expectedExpiry).TotalSeconds);
        Assert.True(drift < 5, $"Expiry should be ~4 hours from now, drift was {drift}s");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Guid SeedMember(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var userId = Guid.NewGuid();
        _db.Musicians.Add(new Musician { Id = userId, Email = $"m{userId}@test.com", Name = "Test Member" });
        _db.Memberships.Add(new Membership { MusicianId = userId, BandId = bandId, Role = role, IsActive = true });
        _db.SaveChanges();
        return userId;
    }

    private SongBroadcastHub CreateHubForUser(Guid userId, string connectionId)
    {
        var context = Substitute.For<HubCallerContext>();
        context.ConnectionId.Returns(connectionId);
        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim("name", "Test User")
        ]));
        context.User.Returns(claims);

        return new SongBroadcastHub(_db)
        {
            Clients = _mockClients,
            Context = context,
            Groups = _mockGroups
        };
    }
}
