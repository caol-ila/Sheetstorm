using Microsoft.EntityFrameworkCore;
using NSubstitute;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Gema;
using Sheetstorm.Infrastructure.Gema;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Gema;

public class GemaServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly GemaService _sut;

    public GemaServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _sut = new GemaService(_db);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMemberAsync(MemberRole role = MemberRole.Musician)
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test Musician" };
        var band = new Band { Name = "Test Band" };
        var membership = new Membership { Musician = musician, Band = band, IsActive = true, Role = role };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(membership);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private async Task<Guid> SeedSetlistWithPiecesAsync(Guid bandId)
    {
        var setlist = new Setlist { BandId = bandId, Name = "Test Setlist", Date = DateOnly.FromDateTime(DateTime.UtcNow) };
        _db.Setlists.Add(setlist);

        var piece1 = new Piece { BandId = bandId, Title = "March No. 1", Composer = "Composer A", Arranger = "Arranger X" };
        var piece2 = new Piece { BandId = bandId, Title = "Waltz No. 2", Composer = "Composer B" };
        _db.Pieces.AddRange(piece1, piece2);

        _db.SetlistEntries.Add(new SetlistEntry { Setlist = setlist, Piece = piece1, Position = 1, DurationSeconds = 180 });
        _db.SetlistEntries.Add(new SetlistEntry { Setlist = setlist, Piece = piece2, Position = 2, DurationSeconds = 240 });

        await _db.SaveChangesAsync();
        return setlist.Id;
    }

    // ── CreateReportAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateReportAsync_ValidRequest_CreatesReport()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateGemaReportRequest(
            "Test Report",
            null,
            DateTime.UtcNow,
            null,
            "Vienna",
            "Concert",
            "City Council"
        );

        var result = await _sut.CreateReportAsync(bandId, request, musicianId, CancellationToken.None);

        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Test Report", result.Title);
        Assert.Equal(GemaReportStatus.Draft, result.Status);
        Assert.Equal("Vienna", result.EventLocation);
        Assert.Equal(musicianId, result.GeneratedByMusicianId);
    }

    [Fact]
    public async Task CreateReportAsync_NotConductorOrAdmin_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var request = new CreateGemaReportRequest("Test", null, DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateReportAsync(bandId, request, musicianId, CancellationToken.None));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task CreateReportAsync_NotMember_ThrowsDomainException()
    {
        var (_, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateGemaReportRequest("Test", null, DateTime.UtcNow);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateReportAsync(bandId, request, Guid.NewGuid(), CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    // ── GetReportAsync ────────────────────────────────────────────────────────

    [Fact]
    public async Task GetReportAsync_ExistingReport_ReturnsDto()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Concert Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = await _db.Musicians.FindAsync(musicianId) ?? throw new Exception()
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var result = await _sut.GetReportAsync(bandId, report.Id, musicianId, CancellationToken.None);

        Assert.Equal(report.Id, result.Id);
        Assert.Equal("Concert Report", result.Title);
    }

    [Fact]
    public async Task GetReportAsync_NonExistentReport_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetReportAsync(bandId, Guid.NewGuid(), musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetReportAsync_DifferentBand_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        var report = new GemaReport
        {
            BandId = otherBand.Id,
            Title = "Other Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = await _db.Musicians.FindAsync(musicianId) ?? throw new Exception()
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetReportAsync(bandId, report.Id, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── GetReportsAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetReportsAsync_ReturnsAllReportsForBand()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);

        _db.GemaReports.Add(new GemaReport
        {
            BandId = bandId,
            Title = "Report 1",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        });
        _db.GemaReports.Add(new GemaReport
        {
            BandId = bandId,
            Title = "Report 2",
            ReportDate = DateTime.UtcNow.AddDays(-1),
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        });
        await _db.SaveChangesAsync();

        var result = await _sut.GetReportsAsync(bandId, musicianId, null, CancellationToken.None);

        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task GetReportsAsync_StatusFilter_ReturnsOnlyMatchingStatus()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);

        _db.GemaReports.Add(new GemaReport
        {
            BandId = bandId,
            Title = "Draft",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        });
        _db.GemaReports.Add(new GemaReport
        {
            BandId = bandId,
            Title = "Finalized",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        });
        await _db.SaveChangesAsync();

        var result = await _sut.GetReportsAsync(bandId, musicianId, GemaReportStatus.Draft, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal("Draft", result[0].Title);
    }

    // ── UpdateReportAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateReportAsync_ValidUpdate_UpdatesFields()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Old Title",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!,
            EventLocation = "Old Location"
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new UpdateGemaReportRequest("New Title", "New Location", "Festival", "New Org");
        var result = await _sut.UpdateReportAsync(bandId, report.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("New Title", result.Title);
        Assert.Equal("New Location", result.EventLocation);
        Assert.Equal("Festival", result.EventCategory);
        Assert.Equal("New Org", result.Organizer);
    }

    [Fact]
    public async Task UpdateReportAsync_FinalizedReport_ThrowsConflict()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Finalized",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new UpdateGemaReportRequest("New Title");
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateReportAsync(bandId, report.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task UpdateReportAsync_SubmittedReport_ThrowsConflict()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Submitted",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Submitted,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new UpdateGemaReportRequest("New Title");
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateReportAsync(bandId, report.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
    }

    // ── DeleteReportAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteReportAsync_DraftReport_Deletes()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "To Delete",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        await _sut.DeleteReportAsync(bandId, report.Id, musicianId, CancellationToken.None);

        var deleted = await _db.GemaReports.FindAsync(report.Id);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task DeleteReportAsync_SubmittedReport_ThrowsConflict()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Submitted",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Submitted,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteReportAsync(bandId, report.Id, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    // ── AddEntryAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task AddEntryAsync_ValidEntry_AddsToReport()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new AddGemaReportEntryRequest("Test Piece", "Test Composer", "Arranger", "Publisher", 180, "WRK123");
        var result = await _sut.AddEntryAsync(bandId, report.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Test Piece", result.Title);
        Assert.Equal("Test Composer", result.Composer);
        Assert.Equal(1, result.Position);
        Assert.Equal("WRK123", result.WorkNumber);
    }

    [Fact]
    public async Task AddEntryAsync_MultipleEntries_IncrementsPosition()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var req1 = new AddGemaReportEntryRequest("Piece 1", "Composer 1");
        var req2 = new AddGemaReportEntryRequest("Piece 2", "Composer 2");

        await _sut.AddEntryAsync(bandId, report.Id, req1, musicianId, CancellationToken.None);
        var result2 = await _sut.AddEntryAsync(bandId, report.Id, req2, musicianId, CancellationToken.None);

        Assert.Equal(2, result2.Position);
    }

    [Fact]
    public async Task AddEntryAsync_FinalizedReport_ThrowsConflict()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Finalized",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new AddGemaReportEntryRequest("Piece", "Composer");
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.AddEntryAsync(bandId, report.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
    }

    // ── UpdateEntryAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateEntryAsync_ValidUpdate_UpdatesEntry()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        var entry = new GemaReportEntry
        {
            GemaReport = report,
            Title = "Old Title",
            Composer = "Old Composer",
            Position = 1
        };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        var request = new UpdateGemaReportEntryRequest("New Title", "New Composer", "New Arranger", "New Publisher", 240, "NEW123");
        var result = await _sut.UpdateEntryAsync(bandId, report.Id, entry.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("New Title", result.Title);
        Assert.Equal("New Composer", result.Composer);
        Assert.Equal("New Arranger", result.Arranger);
        Assert.Equal(240, result.DurationSeconds);
    }

    [Fact]
    public async Task UpdateEntryAsync_NonExistentEntry_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var request = new UpdateGemaReportEntryRequest("Title");
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateEntryAsync(bandId, report.Id, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteEntryAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteEntryAsync_ValidEntry_DeletesEntry()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        var entry = new GemaReportEntry { GemaReport = report, Title = "Entry", Composer = "Comp", Position = 1 };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        await _sut.DeleteEntryAsync(bandId, report.Id, entry.Id, musicianId, CancellationToken.None);

        var deleted = await _db.GemaReportEntries.FindAsync(entry.Id);
        Assert.Null(deleted);
    }

    // ── FinalizeReportAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task FinalizeReportAsync_DraftWithEntries_ChangeStatusToFinalized()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        var entry = new GemaReportEntry { GemaReport = report, Title = "Entry", Composer = "Comp", Position = 1 };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        var result = await _sut.FinalizeReportAsync(bandId, report.Id, musicianId, CancellationToken.None);

        Assert.Equal(GemaReportStatus.Finalized, result.Status);
    }

    [Fact]
    public async Task FinalizeReportAsync_EmptyReport_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Empty Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.FinalizeReportAsync(bandId, report.Id, musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Equal(400, ex.StatusCode);
    }

    [Fact]
    public async Task FinalizeReportAsync_AlreadyFinalized_ThrowsConflict()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.FinalizeReportAsync(bandId, report.Id, musicianId, CancellationToken.None));

        Assert.Equal("CONFLICT", ex.ErrorCode);
    }

    // ── ExportReportAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task ExportReportAsync_CsvFormat_GeneratesCsvData()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Export Test",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!,
            EventLocation = "Vienna",
            EventCategory = "Concert",
            Organizer = "City"
        };
        var entry = new GemaReportEntry
        {
            GemaReport = report,
            Title = "Test Song",
            Composer = "Composer A",
            Arranger = "Arranger B",
            Publisher = "Publisher C",
            DurationSeconds = 180,
            WorkNumber = "WRK123",
            Position = 1
        };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        var result = await _sut.ExportReportAsync(bandId, report.Id, "csv", musicianId, CancellationToken.None);

        Assert.NotEmpty(result);
        var csv = System.Text.Encoding.UTF8.GetString(result);
        Assert.Contains("Test Song", csv);
        Assert.Contains("Composer A", csv);
        Assert.Contains("WRK123", csv);
    }

    [Fact]
    public async Task ExportReportAsync_XmlFormat_GeneratesXmlData()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "XML Export",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!,
            EventLocation = "Salzburg",
            EventCategory = "Festival"
        };
        var entry = new GemaReportEntry
        {
            GemaReport = report,
            Title = "Symphony",
            Composer = "Mozart",
            Position = 1
        };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        var result = await _sut.ExportReportAsync(bandId, report.Id, "xml", musicianId, CancellationToken.None);

        var xml = System.Text.Encoding.UTF8.GetString(result);
        Assert.Contains("<?xml version", xml);
        Assert.Contains("<GEMAMeldung>", xml);
        Assert.Contains("<Werktitel>Symphony</Werktitel>", xml);
        Assert.Contains("<Komponist>Mozart</Komponist>", xml);
        Assert.Contains("<Ort>Salzburg</Ort>", xml);
    }

    [Fact]
    public async Task ExportReportAsync_UnsupportedFormat_ThrowsValidationError()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        _db.GemaReports.Add(report);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ExportReportAsync(bandId, report.Id, "pdf", musicianId, CancellationToken.None));

        Assert.Equal("VALIDATION_ERROR", ex.ErrorCode);
        Assert.Contains("Unsupported export format", ex.Message);
    }

    [Fact]
    public async Task ExportReportAsync_UpdatesExportedAtTimestamp()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Musician);
        var musician = await _db.Musicians.FindAsync(musicianId);
        var report = new GemaReport
        {
            BandId = bandId,
            Title = "Report",
            ReportDate = DateTime.UtcNow,
            Status = GemaReportStatus.Finalized,
            GeneratedByMusicianId = musicianId,
            GeneratedByMusician = musician!
        };
        var entry = new GemaReportEntry { GemaReport = report, Title = "Song", Composer = "Comp", Position = 1 };
        _db.GemaReports.Add(report);
        _db.GemaReportEntries.Add(entry);
        await _db.SaveChangesAsync();

        await _sut.ExportReportAsync(bandId, report.Id, "csv", musicianId, CancellationToken.None);

        var updated = await _db.GemaReports.FindAsync(report.Id);
        Assert.NotNull(updated!.ExportedAt);
        Assert.Equal("csv", updated.ExportFormat);
    }

    // ── GenerateFromSetlistAsync ──────────────────────────────────────────────

    [Fact]
    public async Task GenerateFromSetlistAsync_ValidSetlist_CreatesReportWithEntries()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var setlistId = await SeedSetlistWithPiecesAsync(bandId);
        var request = new CreateGemaReportRequest(
            "Setlist Report",
            null,
            DateTime.UtcNow,
            setlistId,
            "Munich",
            "Concert"
        );

        var result = await _sut.GenerateFromSetlistAsync(bandId, setlistId, request, musicianId, CancellationToken.None);

        Assert.Equal("Setlist Report", result.Title);
        Assert.Equal(setlistId, result.SetlistId);
        Assert.Equal(2, result.Entries.Count);
        Assert.Equal("March No. 1", result.Entries[0].Title);
        Assert.Equal("Composer A", result.Entries[0].Composer);
        Assert.Equal("Arranger X", result.Entries[0].Arranger);
        Assert.Equal(180, result.Entries[0].DurationSeconds);
        Assert.Equal("Waltz No. 2", result.Entries[1].Title);
    }

    [Fact]
    public async Task GenerateFromSetlistAsync_NonExistentSetlist_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var request = new CreateGemaReportRequest("Report", null, DateTime.UtcNow, Guid.NewGuid());

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GenerateFromSetlistAsync(bandId, Guid.NewGuid(), request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Contains("Setlist not found", ex.Message);
    }

    [Fact]
    public async Task GenerateFromSetlistAsync_DifferentBandSetlist_ThrowsNotFound()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var otherBand = new Band { Name = "Other Band" };
        _db.Bands.Add(otherBand);
        var setlist = new Setlist { BandId = otherBand.Id, Name = "Other Setlist", Date = DateOnly.FromDateTime(DateTime.UtcNow) };
        _db.Setlists.Add(setlist);
        await _db.SaveChangesAsync();

        var request = new CreateGemaReportRequest("Report", null, DateTime.UtcNow, setlist.Id);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GenerateFromSetlistAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task GenerateFromSetlistAsync_UnknownComposer_UsesDefaultValue()
    {
        var (musicianId, bandId) = await SeedMemberAsync(MemberRole.Conductor);
        var setlist = new Setlist { BandId = bandId, Name = "Test Setlist", Date = DateOnly.FromDateTime(DateTime.UtcNow) };
        var piece = new Piece { BandId = bandId, Title = "Mystery Song", Composer = null };
        _db.Setlists.Add(setlist);
        _db.Pieces.Add(piece);
        _db.SetlistEntries.Add(new SetlistEntry { Setlist = setlist, Piece = piece, Position = 1 });
        await _db.SaveChangesAsync();

        var request = new CreateGemaReportRequest("Report", null, DateTime.UtcNow, setlist.Id);
        var result = await _sut.GenerateFromSetlistAsync(bandId, setlist.Id, request, musicianId, CancellationToken.None);

        Assert.Equal("Komponist unbekannt", result.Entries[0].Composer);
    }
}
