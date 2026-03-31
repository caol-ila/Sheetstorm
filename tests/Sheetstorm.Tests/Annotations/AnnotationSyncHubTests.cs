using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using Sheetstorm.Api.Hubs;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Annotations;

public class AnnotationSyncHubTests : IDisposable
{
    private readonly AnnotationSyncHub _sut;
    private readonly IHubCallerClients _mockClients;
    private readonly HubCallerContext _mockContext;
    private readonly IGroupManager _mockGroups;
    private readonly IClientProxy _mockClientProxy;
    private readonly ISingleClientProxy _mockCallerProxy;
    private readonly AppDbContext _db;
    private readonly Guid _userId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly Guid _piecePageId = Guid.NewGuid();
    private readonly Guid _pieceId = Guid.NewGuid();
    private readonly Guid _voiceId = Guid.NewGuid();
    private readonly string _connectionId = "test-hub-conn-id";

    public AnnotationSyncHubTests()
    {
        _mockClients = Substitute.For<IHubCallerClients>();
        _mockContext = Substitute.For<HubCallerContext>();
        _mockGroups = Substitute.For<IGroupManager>();
        _mockClientProxy = Substitute.For<IClientProxy>();
        _mockCallerProxy = Substitute.For<ISingleClientProxy>();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new AppDbContext(options);

        SeedData();

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _userId.ToString()),
            new Claim("name", "Test Musician")
        ]));

        _mockContext.ConnectionId.Returns(_connectionId);
        _mockContext.User.Returns(claims);
        _mockClients.Group(Arg.Any<string>()).Returns(_mockClientProxy);
        _mockClients.Caller.Returns(_mockCallerProxy);
        _mockClients.OthersInGroup(Arg.Any<string>()).Returns(_mockClientProxy);

        _sut = new AnnotationSyncHub(_db)
        {
            Clients = _mockClients,
            Context = _mockContext,
            Groups = _mockGroups
        };
    }

    private void SeedData()
    {
        _db.Musicians.Add(new Musician { Id = _userId, Email = "test@test.com", Name = "Test Musician" });
        _db.Bands.Add(new Band { Id = _bandId, Name = "Test Band" });
        _db.Memberships.Add(new Membership { MusicianId = _userId, BandId = _bandId, Role = MemberRole.Conductor, IsActive = true });
        _db.Pieces.Add(new Piece { Id = _pieceId, BandId = _bandId, Title = "Test Piece" });
        _db.PiecePages.Add(new PiecePage { Id = _piecePageId, PieceId = _pieceId, PageNumber = 1, StorageKey = "test" });
        _db.Voices.Add(new Voice { Id = _voiceId, PieceId = _pieceId, Label = "Klarinette 1" });
        _db.SaveChanges();
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── JoinAnnotationGroup ──────────────────────────────────────────────

    [Fact]
    public async Task JoinAnnotationGroup_VoiceLevel_JoinsCorrectGroup()
    {
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId);

        var expectedGroup = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await _mockGroups.Received(1).AddToGroupAsync(
            _connectionId, expectedGroup, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task JoinAnnotationGroup_OrchestraLevel_JoinsCorrectGroup()
    {
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Orchestra", null);

        var expectedGroup = $"annotation-orchestra-{_bandId}-{_piecePageId}";
        await _mockGroups.Received(1).AddToGroupAsync(
            _connectionId, expectedGroup, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task JoinAnnotationGroup_NonMember_ThrowsHubException()
    {
        var outsiderId = Guid.NewGuid();
        _db.Musicians.Add(new Musician { Id = outsiderId, Email = "out@test.com", Name = "Outsider" });
        await _db.SaveChangesAsync();

        var outsiderClaims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, outsiderId.ToString()),
        ]));
        _mockContext.User.Returns(outsiderClaims);

        await Assert.ThrowsAsync<HubException>(() =>
            _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId));
    }

    // ── LeaveAnnotationGroup ─────────────────────────────────────────────

    [Fact]
    public async Task LeaveAnnotationGroup_VoiceLevel_LeavesCorrectGroup()
    {
        await _sut.LeaveAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId);

        var expectedGroup = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await _mockGroups.Received(1).RemoveFromGroupAsync(
            _connectionId, expectedGroup, Arg.Any<CancellationToken>());
    }

    // ── NotifyElementChange ──────────────────────────────────────────────

    [Fact]
    public async Task NotifyElementChange_BroadcastsToOthersInGroup()
    {
        // First join a group (required for broadcast authorization)
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId);

        var notification = new ElementChangeNotification(
            AnnotationId: Guid.NewGuid(),
            ElementId: Guid.NewGuid(),
            ChangeType: "added",
            Element: new AnnotationElementDto(
                Guid.NewGuid(), Guid.NewGuid(), AnnotationTool.Pencil,
                "[{\"x\":0.1}]", 0.1, 0.2, 0.3, 0.4,
                null, null, null, 1.0, 3.0, 1, _userId, false,
                DateTime.UtcNow, DateTime.UtcNow
            )
        );

        var groupName = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await _sut.NotifyElementChange(groupName, notification);

        await _mockClientProxy.Received(1).SendCoreAsync(
            "OnElementAdded",
            Arg.Is<object[]>(args => args.Length == 1),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task NotifyElementChange_DeletedType_SendsOnElementDeleted()
    {
        // Must join the group first
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Orchestra", null);

        var notification = new ElementChangeNotification(
            AnnotationId: Guid.NewGuid(),
            ElementId: Guid.NewGuid(),
            ChangeType: "deleted",
            Element: null
        );

        var groupName = $"annotation-orchestra-{_bandId}-{_piecePageId}";
        await _sut.NotifyElementChange(groupName, notification);

        await _mockClientProxy.Received(1).SendCoreAsync(
            "OnElementDeleted",
            Arg.Is<object[]>(args => args.Length == 2),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task NotifyElementChange_UpdatedType_SendsOnElementUpdated()
    {
        // Must join the group first
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId);

        var notification = new ElementChangeNotification(
            AnnotationId: Guid.NewGuid(),
            ElementId: Guid.NewGuid(),
            ChangeType: "updated",
            Element: new AnnotationElementDto(
                Guid.NewGuid(), Guid.NewGuid(), AnnotationTool.Text,
                null, 0.1, 0.2, 0.3, 0.4,
                "Forte!", null, null, 1.0, 3.0, 2, _userId, false,
                DateTime.UtcNow, DateTime.UtcNow
            )
        );

        var groupName = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await _sut.NotifyElementChange(groupName, notification);

        await _mockClientProxy.Received(1).SendCoreAsync(
            "OnElementUpdated",
            Arg.Is<object[]>(args => args.Length == 1),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task NotifyElementChange_WithoutJoiningGroup_ThrowsHubException()
    {
        var notification = new ElementChangeNotification(
            AnnotationId: Guid.NewGuid(),
            ElementId: Guid.NewGuid(),
            ChangeType: "added",
            Element: null
        );

        var groupName = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await Assert.ThrowsAsync<HubException>(() =>
            _sut.NotifyElementChange(groupName, notification));
    }

    [Fact]
    public async Task NotifyElementChange_NonMember_ThrowsHubException()
    {
        var outsiderId = Guid.NewGuid();
        _db.Musicians.Add(new Musician { Id = outsiderId, Email = "out@test.com", Name = "Outsider" });
        await _db.SaveChangesAsync();

        var outsiderClaims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, outsiderId.ToString()),
        ]));
        _mockContext.User.Returns(outsiderClaims);

        var groupName = $"annotation-voice-{_bandId}-{_voiceId}-{_piecePageId}";
        await Assert.ThrowsAsync<HubException>(() =>
            _sut.NotifyElementChange(groupName, new ElementChangeNotification(
                Guid.NewGuid(), Guid.NewGuid(), "added", null)));
    }

    // ── OnDisconnectedAsync ──────────────────────────────────────────────

    [Fact]
    public async Task OnDisconnectedAsync_CompletesWithoutError()
    {
        await _sut.JoinAnnotationGroup(_bandId, _piecePageId, "Voice", _voiceId);
        await _sut.OnDisconnectedAsync(null);
        // Should not throw
    }
}
