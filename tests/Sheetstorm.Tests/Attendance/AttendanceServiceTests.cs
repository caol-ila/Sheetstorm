using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Attendance;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Attendance;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Attendance;

public class AttendanceServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly AttendanceService _sut;

    public AttendanceServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new AttendanceService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMemberAsync(MemberRole role = MemberRole.Conductor)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Guid> SeedAdditionalMemberAsync(Guid bandId, MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Additional Member" };
        var membership = new Membership { MusicianId = musician.Id, BandId = bandId, Role = role, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return musician.Id;
    }

    // ── GetAllAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllAsync_RegularMember_ReturnsOwnRecordsOnly()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var otherId = await SeedAdditionalMemberAsync(bandId);
        var record1 = new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = otherId };
        var record2 = new AttendanceRecord { BandId = bandId, MusicianId = otherId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = otherId };
        _db.AttendanceRecords.Add(record1);
        _db.AttendanceRecords.Add(record2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, null, null, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(musicianId, result[0].MusicianId);
    }

    [Fact]
    public async Task GetAllAsync_AdminRole_ReturnsAllRecords()
    {
        var (adminId, bandId) = await SeedMemberAsync(MemberRole.Administrator);
        var otherId = await SeedAdditionalMemberAsync(bandId);
        var record1 = new AttendanceRecord { BandId = bandId, MusicianId = adminId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = adminId };
        var record2 = new AttendanceRecord { BandId = bandId, MusicianId = otherId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = adminId };
        _db.AttendanceRecords.Add(record1);
        _db.AttendanceRecords.Add(record2);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, adminId, null, null, CancellationToken.None);

        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task GetAllAsync_WithDateRange_FiltersCorrectly()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var record1 = new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 1, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId };
        var record2 = new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 2, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId };
        var record3 = new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 3, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId };
        _db.AttendanceRecords.AddRange(record1, record2, record3);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAllAsync(bandId, musicianId, new DateOnly(2024, 1, 15), new DateOnly(2024, 2, 15), CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(new DateOnly(2024, 2, 1), result[0].Date);
    }

    [Fact]
    public async Task GetAllAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId) = await SeedMemberAsync();
        var stranger = Guid.NewGuid();

        await Assert.ThrowsAsync<DomainException>(() => 
            _sut.GetAllAsync(bandId, stranger, null, null, CancellationToken.None));
    }

    // ── GetByIdAsync ──────────────────────────────────────────────────────────

    [Fact]
    public async Task GetByIdAsync_ValidRecord_ReturnsDto()
    {
        var (musicianId, bandId) = await SeedMemberAsync();
        var record = new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var result = await _sut.GetByIdAsync(bandId, record.Id, musicianId, CancellationToken.None);

        Assert.Equal(record.Id, result.Id);
        Assert.Equal(AttendanceStatus.Present, result.Status);
    }

    [Fact]
    public async Task GetByIdAsync_RegularMemberOthersRecord_ThrowsForbidden()
    {
        var (_, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var otherId = await SeedAdditionalMemberAsync(bandId, MemberRole.Musician);
        var memberId = await SeedAdditionalMemberAsync(bandId, MemberRole.Musician);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = otherId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = otherId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(bandId, record.Id, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task GetByIdAsync_RecordNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMemberAsync();

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetByIdAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));
    }

    // ── CreateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_Conductor_CreatesRecord()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId);

        var request = new CreateAttendanceRecordRequest(memberId, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);
        var result = await _sut.CreateAsync(bandId, request, conductorId, CancellationToken.None);

        Assert.Equal(memberId, result.MusicianId);
        Assert.Equal(AttendanceStatus.Present, result.Status);
    }

    [Fact]
    public async Task CreateAsync_Admin_CreatesRecord()
    {
        var (adminId, bandId) = await SeedMemberAsync(MemberRole.Administrator);
        var memberId = await SeedAdditionalMemberAsync(bandId);

        var request = new CreateAttendanceRecordRequest(memberId, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Absent, null, "Sick");
        var result = await _sut.CreateAsync(bandId, request, adminId, CancellationToken.None);

        Assert.Equal(AttendanceStatus.Absent, result.Status);
        Assert.Equal("Sick", result.Notes);
    }

    [Fact]
    public async Task CreateAsync_SectionLeader_CreatesRecord()
    {
        var (leaderId, bandId) = await SeedMemberAsync(MemberRole.SectionLeader);
        var memberId = await SeedAdditionalMemberAsync(bandId);

        var request = new CreateAttendanceRecordRequest(memberId, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Late, null, null);
        var result = await _sut.CreateAsync(bandId, request, leaderId, CancellationToken.None);

        Assert.Equal(AttendanceStatus.Late, result.Status);
    }

    [Fact]
    public async Task CreateAsync_RegularMember_ThrowsForbidden()
    {
        var (memberId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var otherId = await SeedAdditionalMemberAsync(bandId);

        var request = new CreateAttendanceRecordRequest(otherId, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateAsync_DuplicateRecord_ThrowsConflict()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var date = DateOnly.FromDateTime(DateTime.UtcNow);
        var existing = new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = date, Status = AttendanceStatus.Present, RecordedByMusicianId = conductorId };
        _db.AttendanceRecords.Add(existing);
        await _db.SaveChangesAsync();

        var request = new CreateAttendanceRecordRequest(memberId, date, AttendanceStatus.Absent, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, conductorId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task CreateAsync_MusicianNotInBand_ThrowsNotFound()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var strangerMs = new Musician { Email = "stranger@test.com", Name = "Stranger" };
        _db.Musicians.Add(strangerMs);
        await _db.SaveChangesAsync();

        var request = new CreateAttendanceRecordRequest(strangerMs.Id, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAsync(bandId, request, conductorId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── UpdateAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateAsync_Conductor_UpdatesRecord()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = conductorId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var request = new UpdateAttendanceRecordRequest(AttendanceStatus.Absent, "Changed status");
        var result = await _sut.UpdateAsync(bandId, record.Id, request, conductorId, CancellationToken.None);

        Assert.Equal(AttendanceStatus.Absent, result.Status);
        Assert.Equal("Changed status", result.Notes);
    }

    [Fact]
    public async Task UpdateAsync_RegularMember_ThrowsForbidden()
    {
        var (_, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId, MemberRole.Musician);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = memberId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var request = new UpdateAttendanceRecordRequest(AttendanceStatus.Absent, null);
        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateAsync(bandId, record.Id, request, memberId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── DeleteAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_Admin_DeletesRecord()
    {
        var (adminId, bandId) = await SeedMemberAsync(MemberRole.Administrator);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = adminId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        await _sut.DeleteAsync(bandId, record.Id, adminId, CancellationToken.None);

        var exists = await _db.AttendanceRecords.AnyAsync(r => r.Id == record.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_Conductor_DeletesRecord()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = conductorId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        await _sut.DeleteAsync(bandId, record.Id, conductorId, CancellationToken.None);

        var exists = await _db.AttendanceRecords.AnyAsync(r => r.Id == record.Id);
        Assert.False(exists);
    }

    [Fact]
    public async Task DeleteAsync_SectionLeader_ThrowsForbidden()
    {
        var (leaderId, bandId) = await SeedMemberAsync(MemberRole.SectionLeader);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = leaderId, Date = DateOnly.FromDateTime(DateTime.UtcNow), Status = AttendanceStatus.Present, RecordedByMusicianId = leaderId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteAsync(bandId, record.Id, leaderId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── GetStatsAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task GetStatsAsync_CalculatesPercentages()
    {
        var (conductorId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var memberId = await SeedAdditionalMemberAsync(bandId);
        var records = new[]
        {
            new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = new DateOnly(2024, 1, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = conductorId },
            new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = new DateOnly(2024, 1, 2), Status = AttendanceStatus.Present, RecordedByMusicianId = conductorId },
            new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = new DateOnly(2024, 1, 3), Status = AttendanceStatus.Absent, RecordedByMusicianId = conductorId },
            new AttendanceRecord { BandId = bandId, MusicianId = memberId, Date = new DateOnly(2024, 1, 4), Status = AttendanceStatus.Late, RecordedByMusicianId = conductorId }
        };
        _db.AttendanceRecords.AddRange(records);
        await _db.SaveChangesAsync();

        var result = await _sut.GetStatsAsync(bandId, conductorId, null, null, CancellationToken.None);

        Assert.Single(result.MusicianStats);
        var stats = result.MusicianStats[0];
        Assert.Equal(4, stats.TotalEvents);
        Assert.Equal(2, stats.PresentCount);
        Assert.Equal(1, stats.AbsentCount);
        Assert.Equal(1, stats.LateCount);
        Assert.Equal(50.0, stats.AttendanceRate);
    }

    [Fact]
    public async Task GetStatsAsync_RegularMember_ThrowsForbidden()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetStatsAsync(bandId, musicianId, null, null, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── GetMusicianStatsAsync ─────────────────────────────────────────────────

    [Fact]
    public async Task GetMusicianStatsAsync_OwnStats_ReturnsStats()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var records = new[]
        {
            new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 1, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId },
            new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 1, 2), Status = AttendanceStatus.Present, RecordedByMusicianId = musicianId },
            new AttendanceRecord { BandId = bandId, MusicianId = musicianId, Date = new DateOnly(2024, 1, 3), Status = AttendanceStatus.Absent, RecordedByMusicianId = musicianId }
        };
        _db.AttendanceRecords.AddRange(records);
        await _db.SaveChangesAsync();

        var result = await _sut.GetMusicianStatsAsync(bandId, musicianId, musicianId, null, null, CancellationToken.None);

        Assert.Equal(3, result.TotalEvents);
        Assert.Equal(2, result.PresentCount);
        Assert.Equal(1, result.AbsentCount);
        Assert.InRange(result.AttendanceRate, 66.0, 67.0);
    }

    [Fact]
    public async Task GetMusicianStatsAsync_RegularMemberViewingOther_ThrowsForbidden()
    {
        var (memberId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var otherId = await SeedAdditionalMemberAsync(bandId);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetMusicianStatsAsync(bandId, otherId, memberId, null, null, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task GetMusicianStatsAsync_AdminViewingOther_ReturnsStats()
    {
        var (adminId, bandId) = await SeedMemberAsync(MemberRole.Administrator);
        var otherId = await SeedAdditionalMemberAsync(bandId);
        var record = new AttendanceRecord { BandId = bandId, MusicianId = otherId, Date = new DateOnly(2024, 1, 1), Status = AttendanceStatus.Present, RecordedByMusicianId = adminId };
        _db.AttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        var result = await _sut.GetMusicianStatsAsync(bandId, otherId, adminId, null, null, CancellationToken.None);

        Assert.Equal(1, result.TotalEvents);
        Assert.Equal(otherId, result.MusicianId);
    }
}
