using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Setlists;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Infrastructure.Setlists;

namespace Sheetstorm.Tests.Setlists;

public class SetlistServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly SetlistService _sut;

    public SetlistServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new SetlistService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMembershipAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test User" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, IsActive = true, Role = role };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Piece> SeedPieceAsync(Guid bandId, string title = "Test Piece")
    {
        var piece = new Piece { BandId = bandId, Title = title, Composer = "Composer", ImportStatus = ImportStatus.Completed };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();
        return piece;
    }

    private async Task<Setlist> SeedSetlistAsync(Guid bandId, string name = "Test Setlist", SetlistType type = SetlistType.Concert)
    {
        var setlist = new Setlist { BandId = bandId, Name = name, Type = type };
        _db.Set<Setlist>().Add(setlist);
        await _db.SaveChangesAsync();
        return setlist;
    }

    // ── GetAllAsync ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllAsync_ReturnsEmptyList_WhenNoSetlists()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Empty(result);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsSetlists_OrderedByCreatedAtDescending()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var older = await SeedSetlistAsync(bandId, "Older");
        await Task.Delay(10);
        var newer = await SeedSetlistAsync(bandId, "Newer");

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Equal(2, result.Count);
        Assert.Equal(newer.Id, result[0].Id);
        Assert.Equal(older.Id, result[1].Id);
    }

    [Fact]
    public async Task GetAllAsync_IncludesEntryCountAndTotalDuration()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var setlist = await SeedSetlistAsync(bandId, "With Entries");
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "Entry 1", DurationSeconds = 120 });
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 1, IsPlaceholder = true, PlaceholderTitle = "Entry 2", DurationSeconds = 180 });
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(2, result[0].EntryCount);
        Assert.Equal(300, result[0].TotalDurationSeconds);
    }

    [Fact]
    public async Task GetAllAsync_OnlyReturnsSetlistsForSpecifiedBand()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        await _db.SaveChangesAsync();

        await SeedSetlistAsync(bandId, "My Setlist");
        await SeedSetlistAsync(otherBand.Id, "Other Setlist");

        var result = await _sut.GetAllAsync(bandId, musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("My Setlist", result[0].Name);
    }

    [Fact]
    public async Task GetAllAsync_NotMember_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var nonMemberMusicianId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetAllAsync(bandId, nonMemberMusicianId, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    // ── GetByIdAsync ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task GetByIdAsync_ReturnsSetlistWithEntries_OrderedByPosition()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var piece1 = await SeedPieceAsync(bandId, "Piece A");
        var piece2 = await SeedPieceAsync(bandId, "Piece B");
        var setlist = await SeedSetlistAsync(bandId, "Concert Setlist");

        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 1, PieceId = piece2.Id, DurationSeconds = 180 });
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 0, PieceId = piece1.Id, DurationSeconds = 120 });
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        Assert.Equal("Concert Setlist", result.Name);
        Assert.Equal(2, result.Entries.Count);
        Assert.Equal(piece1.Id, result.Entries[0].PieceId);
        Assert.Equal(piece2.Id, result.Entries[1].PieceId);
        Assert.Equal(300, result.TotalDurationSeconds);
    }

    [Fact]
    public async Task GetByIdAsync_IncludesPlaceholderEntries()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var setlist = await SeedSetlistAsync(bandId);
        _db.Set<SetlistEntry>().Add(new SetlistEntry
        {
            SetlistId = setlist.Id,
            Position = 0,
            IsPlaceholder = true,
            PlaceholderTitle = "TBD Piece",
            PlaceholderComposer = "Unknown",
            DurationSeconds = 200
        });
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        Assert.Single(result.Entries);
        Assert.True(result.Entries[0].IsPlaceholder);
        Assert.Equal("TBD Piece", result.Entries[0].PlaceholderTitle);
        Assert.Equal("Unknown", result.Entries[0].PlaceholderComposer);
    }

    [Fact]
    public async Task GetByIdAsync_SetlistNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetByIdAsync_WrongBand_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var setlist = await SeedSetlistAsync(bandId);
        var otherBandId = Guid.NewGuid();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(otherBandId, setlist.Id, musicianId, CancellationToken.None));

        Assert.Equal("BAND_NOT_FOUND", ex.ErrorCode);
    }

    // ── CreateAsync ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesSetlist()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var request = new CreateSetlistRequest(
            "New Concert",
            "Description",
            SetlistType.Concert,
            new DateOnly(2025, 5, 1),
            new TimeOnly(19, 0),
            null);

        var result = await _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("New Concert", result.Name);
        Assert.Equal("Description", result.Description);
        Assert.Equal(SetlistType.Concert, result.Type);
        Assert.Equal(new DateOnly(2025, 5, 1), result.Date);
        Assert.Equal(new TimeOnly(19, 0), result.StartTime);
        Assert.Empty(result.Entries);
    }

    [Fact]
    public async Task CreateAsync_TrimsWhitespace()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var request = new CreateSetlistRequest("  Spaced Name  ", "  Desc  ", SetlistType.Rehearsal, null, null, null);

        var result = await _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.Equal("Spaced Name", result.Name);
        Assert.Equal("Desc", result.Description);
    }

    [Fact]
    public async Task CreateAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var request = new CreateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task CreateAsync_SectionLeader_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SectionLeader);
        var request = new CreateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── UpdateAsync ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateAsync_ValidRequest_UpdatesSetlist()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId, "Original");
        var request = new UpdateSetlistRequest(
            "Updated Name",
            "Updated Description",
            SetlistType.Rehearsal,
            new DateOnly(2025, 6, 1),
            new TimeOnly(18, 30),
            null);

        var result = await _sut.UpdateAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Updated Name", result.Name);
        Assert.Equal("Updated Description", result.Description);
        Assert.Equal(SetlistType.Rehearsal, result.Type);
        Assert.Equal(new DateOnly(2025, 6, 1), result.Date);
        Assert.Equal(new TimeOnly(18, 30), result.StartTime);
    }

    [Fact]
    public async Task UpdateAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new UpdateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateAsync_SetlistNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var request = new UpdateSetlistRequest("Test", null, SetlistType.Concert, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateAsync(bandId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteAsync ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_ValidRequest_RemovesSetlist()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);

        await _sut.DeleteAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        var exists = await _db.Set<Setlist>().AnyAsync(s => s.Id == setlist.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SheetMusicManager);
        var setlist = await SeedSetlistAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAsync(bandId, setlist.Id, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task DeleteAsync_SetlistNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── AddEntryAsync ────────────────────────────────────────────────────────────

    [Fact]
    public async Task AddEntryAsync_WithPiece_CreatesEntry()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var piece = await SeedPieceAsync(bandId, "Test Piece");
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(piece.Id, false, null, null, "Test notes", 240);

        var result = await _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        Assert.Equal(piece.Id, result.PieceId);
        Assert.Equal("Test Piece", result.PieceTitle);
        Assert.Equal("Composer", result.PieceComposer);
        Assert.Equal("Test notes", result.Notes);
        Assert.Equal(240, result.DurationSeconds);
        Assert.Equal(0, result.Position);
    }

    [Fact]
    public async Task AddEntryAsync_Placeholder_CreatesPlaceholderEntry()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(null, true, "Placeholder Title", "Placeholder Composer", null, 180);

        var result = await _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        Assert.True(result.IsPlaceholder);
        Assert.Equal("Placeholder Title", result.PlaceholderTitle);
        Assert.Equal("Placeholder Composer", result.PlaceholderComposer);
        Assert.Equal(180, result.DurationSeconds);
    }

    [Fact]
    public async Task AddEntryAsync_MultipleEntries_AssignsCorrectPositions()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(null, true, "Entry", null, null, null);

        var entry1 = await _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);
        var entry2 = await _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);
        var entry3 = await _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        Assert.Equal(0, entry1.Position);
        Assert.Equal(1, entry2.Position);
        Assert.Equal(2, entry3.Position);
    }

    [Fact]
    public async Task AddEntryAsync_PlaceholderWithoutTitle_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(null, true, null, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("Placeholder title", ex.Message);
    }

    [Fact]
    public async Task AddEntryAsync_NonPlaceholderWithoutPieceId_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(null, false, null, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("Piece ID", ex.Message);
    }

    [Fact]
    public async Task AddEntryAsync_PieceNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(Guid.NewGuid(), false, null, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Contains("Piece", ex.Message);
    }

    [Fact]
    public async Task AddEntryAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new AddSetlistEntryRequest(null, true, "Title", null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.AddEntryAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── UpdateEntryAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateEntryAsync_ValidRequest_UpdatesEntry()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var entry = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "Original", DurationSeconds = 100 };
        _db.Set<SetlistEntry>().Add(entry);
        await _db.SaveChangesAsync();

        var request = new UpdateSetlistEntryRequest("Updated notes", 200);

        var result = await _sut.UpdateEntryAsync(bandId, setlist.Id, entry.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Updated notes", result.Notes);
        Assert.Equal(200, result.DurationSeconds);
    }

    [Fact]
    public async Task UpdateEntryAsync_EntryNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new UpdateSetlistEntryRequest("Notes", 100);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateEntryAsync(bandId, setlist.Id, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateEntryAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SectionLeader);
        var setlist = await SeedSetlistAsync(bandId);
        var entry = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "Test" };
        _db.Set<SetlistEntry>().Add(entry);
        await _db.SaveChangesAsync();

        var request = new UpdateSetlistEntryRequest("Notes", 100);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateEntryAsync(bandId, setlist.Id, entry.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── DeleteEntryAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteEntryAsync_ValidRequest_RemovesEntry()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var setlist = await SeedSetlistAsync(bandId);
        var entry = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "Test" };
        _db.Set<SetlistEntry>().Add(entry);
        await _db.SaveChangesAsync();

        await _sut.DeleteEntryAsync(bandId, setlist.Id, entry.Id, musicianId, CancellationToken.None);

        var exists = await _db.Set<SetlistEntry>().AnyAsync(e => e.Id == entry.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteEntryAsync_EntryNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteEntryAsync(bandId, setlist.Id, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task DeleteEntryAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var setlist = await SeedSetlistAsync(bandId);
        var entry = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "Test" };
        _db.Set<SetlistEntry>().Add(entry);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteEntryAsync(bandId, setlist.Id, entry.Id, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── ReorderEntriesAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task ReorderEntriesAsync_ValidRequest_UpdatesPositions()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var entry1 = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "1" };
        var entry2 = new SetlistEntry { SetlistId = setlist.Id, Position = 1, IsPlaceholder = true, PlaceholderTitle = "2" };
        var entry3 = new SetlistEntry { SetlistId = setlist.Id, Position = 2, IsPlaceholder = true, PlaceholderTitle = "3" };
        _db.Set<SetlistEntry>().AddRange(entry1, entry2, entry3);
        await _db.SaveChangesAsync();

        var request = new ReorderEntriesRequest(new[] { entry3.Id, entry1.Id, entry2.Id });

        await _sut.ReorderEntriesAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        var reloaded = await _db.Set<SetlistEntry>().Where(e => e.SetlistId == setlist.Id).OrderBy(e => e.Position).ToListAsync();
        Assert.Equal(entry3.Id, reloaded[0].Id);
        Assert.Equal(entry1.Id, reloaded[1].Id);
        Assert.Equal(entry2.Id, reloaded[2].Id);
    }

    [Fact]
    public async Task ReorderEntriesAsync_MismatchedCount_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var entry1 = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "1" };
        _db.Set<SetlistEntry>().Add(entry1);
        await _db.SaveChangesAsync();

        var request = new ReorderEntriesRequest(new[] { entry1.Id, Guid.NewGuid() });

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ReorderEntriesAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("count mismatch", ex.Message);
    }

    [Fact]
    public async Task ReorderEntriesAsync_InvalidEntryId_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);
        var setlist = await SeedSetlistAsync(bandId);
        var entry1 = new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "1" };
        _db.Set<SetlistEntry>().Add(entry1);
        await _db.SaveChangesAsync();

        var request = new ReorderEntriesRequest(new[] { Guid.NewGuid() });

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ReorderEntriesAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("Invalid entry ID", ex.Message);
    }

    [Fact]
    public async Task ReorderEntriesAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.SheetMusicManager);
        var setlist = await SeedSetlistAsync(bandId);
        var request = new ReorderEntriesRequest(Array.Empty<Guid>());

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.ReorderEntriesAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── DuplicateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DuplicateAsync_CopiesSetlistWithEntries()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Administrator);
        var piece = await SeedPieceAsync(bandId, "Original Piece");
        var setlist = await SeedSetlistAsync(bandId, "Original Setlist");
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 0, PieceId = piece.Id, DurationSeconds = 120 });
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 1, IsPlaceholder = true, PlaceholderTitle = "Placeholder", DurationSeconds = 180 });
        await _db.SaveChangesAsync();

        var result = await _sut.DuplicateAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        Assert.Equal("Original Setlist (Copy)", result.Name);
        Assert.Equal(2, result.Entries.Count);
        Assert.Equal(piece.Id, result.Entries[0].PieceId);
        Assert.True(result.Entries[1].IsPlaceholder);
        Assert.Equal("Placeholder", result.Entries[1].PlaceholderTitle);
    }

    [Fact]
    public async Task DuplicateAsync_SetlistNotFound_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Conductor);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DuplicateAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task DuplicateAsync_NotConductorOrAdmin_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMembershipAsync(MemberRole.Musician);
        var setlist = await SeedSetlistAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DuplicateAsync(bandId, setlist.Id, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── Timing Calculations ──────────────────────────────────────────────────────

    [Fact]
    public async Task TotalDuration_NullForEntriesWithNoDuration()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var setlist = await SeedSetlistAsync(bandId);
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "No Duration", DurationSeconds = null });
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        Assert.Equal(0, result.TotalDurationSeconds);
    }

    [Fact]
    public async Task TotalDuration_SumsOnlyEntriesWithDuration()
    {
        var (musicianId, bandId) = await SeedMembershipAsync();
        var setlist = await SeedSetlistAsync(bandId);
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 0, IsPlaceholder = true, PlaceholderTitle = "With Duration", DurationSeconds = 100 });
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 1, IsPlaceholder = true, PlaceholderTitle = "No Duration", DurationSeconds = null });
        _db.Set<SetlistEntry>().Add(new SetlistEntry { SetlistId = setlist.Id, Position = 2, IsPlaceholder = true, PlaceholderTitle = "Another", DurationSeconds = 200 });
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, setlist.Id, musicianId, CancellationToken.None);

        Assert.Equal(300, result.TotalDurationSeconds);
    }
}
