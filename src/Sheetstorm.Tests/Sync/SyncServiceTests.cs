using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Sync;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Sync;
using Xunit;

namespace Sheetstorm.Tests.Sync;

public class SyncServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly SyncService _sut;

    public SyncServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new SyncService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private async Task<Guid> SeedMusicianAsync()
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test User" };
        _db.Musicians.Add(musician);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    private PushChangeEntry MakePushUpdate(
        Guid entityId,
        string fieldName,
        string newValue,
        DateTime? changedAt = null) =>
        new(
            ClientChangeId: Guid.NewGuid().ToString(),
            EntityType: "Piece",
            EntityId: entityId,
            Operation: "Update",
            FieldName: fieldName,
            NewValue: newValue,
            Fields: null,
            ChangedAt: changedAt ?? DateTime.UtcNow);

    private PushChangeEntry MakePushCreate(string title, DateTime? changedAt = null) =>
        new(
            ClientChangeId: Guid.NewGuid().ToString(),
            EntityType: "Piece",
            EntityId: null,
            Operation: "Create",
            FieldName: null,
            NewValue: null,
            Fields: new Dictionary<string, string> { ["title"] = title, ["composer"] = "Unknown" },
            ChangedAt: changedAt ?? DateTime.UtcNow);

    // ── GetStateAsync ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetState_NewMusician_ReturnsVersionZeroAndNullLastSync()
    {
        var musicianId = await SeedMusicianAsync();

        var result = await _sut.GetStateAsync(musicianId, CancellationToken.None);

        Assert.Equal(0, result.CurrentVersion);
        Assert.Null(result.LastSyncAt);
    }

    [Fact]
    public async Task GetState_AfterPush_ReturnsIncrementedVersion()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();
        var pushRequest = new PushRequest(0, [MakePushUpdate(entityId, "title", "New Title")]);

        await _sut.PushAsync(musicianId, pushRequest, CancellationToken.None);
        var state = await _sut.GetStateAsync(musicianId, CancellationToken.None);

        Assert.Equal(1, state.CurrentVersion);
        Assert.NotNull(state.LastSyncAt);
    }

    // ── PullAsync ─────────────────────────────────────────────────────────────────

    [Fact]
    public async Task Pull_NoChanges_ReturnsEmptyList()
    {
        var musicianId = await SeedMusicianAsync();

        var result = await _sut.PullAsync(musicianId, new PullRequest(0), CancellationToken.None);

        Assert.Empty(result.Changes);
        Assert.Equal(0, result.CurrentVersion);
        Assert.False(result.HasMore);
    }

    [Fact]
    public async Task Pull_SinceVersion0_ReturnsAllChanges()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();
        var push = new PushRequest(0, [
            MakePushUpdate(entityId, "title", "Polka"),
            MakePushUpdate(entityId, "composer", "Lehár")
        ]);

        await _sut.PushAsync(musicianId, push, CancellationToken.None);
        var result = await _sut.PullAsync(musicianId, new PullRequest(0), CancellationToken.None);

        Assert.Equal(2, result.Changes.Count);
        Assert.Equal(2, result.CurrentVersion);
    }

    [Fact]
    public async Task Pull_SinceVersion1_ReturnsOnlyNewerChanges()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        // Push 3 changes
        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "V1"),
            MakePushUpdate(entityId, "composer", "V2"),
            MakePushUpdate(entityId, "arranger", "V3")
        ]), CancellationToken.None);

        // Pull since version 1 — should return only v2 and v3
        var result = await _sut.PullAsync(musicianId, new PullRequest(1), CancellationToken.None);

        Assert.Equal(2, result.Changes.Count);
        Assert.All(result.Changes, c => Assert.True(c.Version > 1));
    }

    [Fact]
    public async Task Pull_ChangesAreSortedByVersionAscending()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "A"),
            MakePushUpdate(entityId, "composer", "B"),
            MakePushUpdate(entityId, "arranger", "C")
        ]), CancellationToken.None);

        var result = await _sut.PullAsync(musicianId, new PullRequest(0), CancellationToken.None);

        var versions = result.Changes.Select(c => c.Version).ToList();
        Assert.Equal(versions.OrderBy(v => v).ToList(), versions);
    }

    [Fact]
    public async Task Pull_DoesNotReturnOtherUsersChanges()
    {
        var musician1 = await SeedMusicianAsync();
        var musician2 = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        await _sut.PushAsync(musician1, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "User1 Title")
        ]), CancellationToken.None);

        var result = await _sut.PullAsync(musician2, new PullRequest(0), CancellationToken.None);

        Assert.Empty(result.Changes);
    }

    // ── PushAsync — basic acceptance ──────────────────────────────────────────────

    [Fact]
    public async Task Push_SingleUpdate_AcceptsAndReturnsVersion1()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();
        var change = MakePushUpdate(entityId, "title", "Böhmischer Wind");

        var result = await _sut.PushAsync(musicianId, new PushRequest(0, [change]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.Empty(result.Conflicts);
        Assert.Equal(1, result.NewVersion);
        Assert.Equal(change.ClientChangeId, result.Accepted[0].ClientChangeId);
        Assert.Equal(entityId, result.Accepted[0].ServerEntityId);
    }

    [Fact]
    public async Task Push_MultipleChanges_AssignsMonotonicallyIncreasingVersions()
    {
        var musicianId = await SeedMusicianAsync();
        var entity1 = Guid.NewGuid();
        var entity2 = Guid.NewGuid();

        var result = await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entity1, "title", "First"),
            MakePushUpdate(entity2, "title", "Second"),
            MakePushUpdate(entity1, "composer", "Third")
        ]), CancellationToken.None);

        Assert.Equal(3, result.Accepted.Count);
        Assert.Equal(3, result.NewVersion);
        var versions = result.Accepted.Select(a => a.ServerVersion).ToList();
        Assert.Equal(new[] { 1L, 2L, 3L }, versions);
    }

    [Fact]
    public async Task Push_CreateOperation_NullEntityId_GetsNewServerEntityId()
    {
        var musicianId = await SeedMusicianAsync();
        var change = MakePushCreate("Neuer Marsch");

        var result = await _sut.PushAsync(musicianId, new PushRequest(0, [change]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.NotEqual(Guid.Empty, result.Accepted[0].ServerEntityId);
    }

    // ── PushAsync — LWW conflict detection ───────────────────────────────────────

    [Fact]
    public async Task Push_UpdateSameField_LastPushWins_WithServerTimestamps()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        // First push sets a value
        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "First Title")
        ]), CancellationToken.None);

        // Second push for same field — always accepted (server sets authoritative timestamp)
        var clientChange = MakePushUpdate(entityId, "title", "Second Title");
        var result = await _sut.PushAsync(musicianId, new PushRequest(1, [clientChange]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.Empty(result.Conflicts);
        Assert.Equal(clientChange.ClientChangeId, result.Accepted[0].ClientChangeId);
    }

    [Fact]
    public async Task Push_UpdateSameField_AlwaysAccepted_ServerTimestampsAuthoritative()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        // Server has an existing change
        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "Server Title (old)")
        ]), CancellationToken.None);

        // Client pushes a change for the same field — always accepted with server timestamps
        var clientChange = MakePushUpdate(entityId, "title", "Client Title (newer)");
        var result = await _sut.PushAsync(musicianId, new PushRequest(1, [clientChange]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.Empty(result.Conflicts);
    }

    [Fact]
    public async Task Push_DifferentFields_SameEntity_NoConflict()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();
        var baseTime = new DateTime(2026, 3, 30, 10, 0, 0, DateTimeKind.Utc);

        // Server has change on "title"
        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "Server Title", baseTime)
        ]), CancellationToken.None);

        // Client pushes change on "composer" (different field — no conflict)
        var result = await _sut.PushAsync(musicianId, new PushRequest(1, [
            MakePushUpdate(entityId, "composer", "Franz Lehár", baseTime.AddMinutes(-10))
        ]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.Empty(result.Conflicts);
    }

    [Fact]
    public async Task Push_MixedChanges_AllAcceptedWithServerTimestamps()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        // Server has an existing title change
        await _sut.PushAsync(musicianId, new PushRequest(0, [
            MakePushUpdate(entityId, "title", "Server Title")
        ]), CancellationToken.None);

        // Client pushes title update + composer update — both accepted with server-authoritative timestamps
        var titleChange = MakePushUpdate(entityId, "title", "New Title");
        var composerChange = MakePushUpdate(entityId, "composer", "Beethoven");

        var result = await _sut.PushAsync(musicianId, new PushRequest(1, [titleChange, composerChange]), CancellationToken.None);

        Assert.Equal(2, result.Accepted.Count);
        Assert.Empty(result.Conflicts);
    }

    [Fact]
    public async Task Push_DeleteOperation_NoConflictCheck_AlwaysAccepted()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();

        var deleteChange = new PushChangeEntry(
            ClientChangeId: Guid.NewGuid().ToString(),
            EntityType: "Piece",
            EntityId: entityId,
            Operation: "Delete",
            FieldName: null,
            NewValue: null,
            Fields: null,
            ChangedAt: DateTime.UtcNow);

        var result = await _sut.PushAsync(musicianId, new PushRequest(0, [deleteChange]), CancellationToken.None);

        Assert.Single(result.Accepted);
        Assert.Empty(result.Conflicts);
    }

    // ── Changelog persistence ────────────────────────────────────────────────────

    [Fact]
    public async Task Push_AcceptedChange_IsPersistedInChangelog_WithServerTimestamp()
    {
        var musicianId = await SeedMusicianAsync();
        var entityId = Guid.NewGuid();
        var change = MakePushUpdate(entityId, "title", "Marsch der Jugend");
        var beforePush = DateTime.UtcNow;

        await _sut.PushAsync(musicianId, new PushRequest(0, [change]), CancellationToken.None);

        var stored = await _db.SyncChangelogs
            .Where(c => c.MusicianId == musicianId && c.EntityId == entityId)
            .SingleAsync();

        Assert.Equal("Piece", stored.EntityType);
        Assert.Equal("title", stored.FieldName);
        Assert.Equal("Marsch der Jugend", stored.NewValue);
        // Server sets the timestamp — it must be >= the time before push
        Assert.True(stored.ChangedAt >= beforePush, "Server should set ChangedAt, not trust client timestamp.");
        Assert.Equal(1, stored.Version);
    }
}
