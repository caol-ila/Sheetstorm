using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Gema;
using Sheetstorm.Infrastructure.Gema;

namespace Sheetstorm.Tests.Gema;

public class GemaControllerTests
{
    private readonly IGemaService _gemaService;
    private readonly GemaController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public GemaControllerTests()
    {
        _gemaService = Substitute.For<IGemaService>();
        _sut = new GemaController(_gemaService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static GemaReportDto MakeReportDto(Guid id, Guid bandId, string title = "Test Report") =>
        new(id, bandId, title, null, DateTime.UtcNow, GemaReportStatus.Draft, Guid.NewGuid(), "Test User",
            null, "Vienna", "Concert", "Organizer", null, null, [], DateTime.UtcNow);

    private static GemaReportSummaryDto MakeReportSummaryDto(Guid id, string title = "Test Report") =>
        new(id, title, DateTime.UtcNow, GemaReportStatus.Draft, "Vienna", "Concert", 0, null, DateTime.UtcNow);

    private static GemaReportEntryDto MakeEntryDto(Guid id) =>
        new(id, null, "Composer", "Title", null, null, 180, null, 1);

    // ── GET /api/bands/{bandId}/gema-reports ──────────────────────────────────

    [Fact]
    public async Task GetReports_ReturnsOkWithList()
    {
        var reports = new List<GemaReportSummaryDto>
        {
            MakeReportSummaryDto(Guid.NewGuid(), "Report A"),
            MakeReportSummaryDto(Guid.NewGuid(), "Report B")
        };
        _gemaService.GetReportsAsync(_bandId, _musicianId, null, Arg.Any<CancellationToken>())
            .Returns(reports);

        var result = await _sut.GetReports(_bandId, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<GemaReportSummaryDto>>(ok.Value);
        Assert.Equal(2, returned.Count);
    }

    [Fact]
    public async Task GetReports_WithStatusFilter_PassesFilterToService()
    {
        _gemaService.GetReportsAsync(_bandId, _musicianId, GemaReportStatus.Finalized, Arg.Any<CancellationToken>())
            .Returns(new List<GemaReportSummaryDto>());

        await _sut.GetReports(_bandId, GemaReportStatus.Finalized, CancellationToken.None);

        await _gemaService.Received(1).GetReportsAsync(_bandId, _musicianId, GemaReportStatus.Finalized, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetReports_ServiceThrowsDomainException_Propagates()
    {
        _gemaService.GetReportsAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<GemaReportStatus?>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Band not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetReports(_bandId, null, CancellationToken.None));
    }

    // ── GET /api/bands/{bandId}/gema-reports/{id} ─────────────────────────────

    [Fact]
    public async Task GetReport_ReturnsOkWithDto()
    {
        var reportId = Guid.NewGuid();
        var dto = MakeReportDto(reportId, _bandId, "Concert Report");
        _gemaService.GetReportAsync(_bandId, reportId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetReport(_bandId, reportId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<GemaReportDto>(ok.Value);
        Assert.Equal(reportId, returned.Id);
        Assert.Equal("Concert Report", returned.Title);
    }

    [Fact]
    public async Task GetReport_NotFound_DomainExceptionPropagates()
    {
        _gemaService.GetReportAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Report not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetReport(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /api/bands/{bandId}/gema-reports ─────────────────────────────────

    [Fact]
    public async Task CreateReport_ValidRequest_Returns201WithDto()
    {
        var reportId = Guid.NewGuid();
        var request = new CreateGemaReportRequest("New Report", null, DateTime.UtcNow, null, "Vienna");
        var expected = MakeReportDto(reportId, _bandId, "New Report");
        _gemaService.CreateReportAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.CreateReport(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<GemaReportDto>(created.Value);
        Assert.Equal("New Report", returned.Title);
    }

    [Fact]
    public async Task CreateReport_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new CreateGemaReportRequest("", null, DateTime.UtcNow);

        var result = await _sut.CreateReport(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task CreateReport_NotConductorOrAdmin_DomainExceptionPropagates()
    {
        var request = new CreateGemaReportRequest("Report", null, DateTime.UtcNow);
        _gemaService.CreateReportAsync(Arg.Any<Guid>(), Arg.Any<CreateGemaReportRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("FORBIDDEN", "Not authorized.", 403));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateReport(_bandId, request, CancellationToken.None));
    }

    // ── POST /api/bands/{bandId}/gema-reports/from-setlist/{setlistId} ────────

    [Fact]
    public async Task GenerateFromSetlist_ValidRequest_Returns201WithDto()
    {
        var setlistId = Guid.NewGuid();
        var reportId = Guid.NewGuid();
        var request = new CreateGemaReportRequest("Setlist Report", null, DateTime.UtcNow, setlistId);
        var expected = MakeReportDto(reportId, _bandId, "Setlist Report");
        _gemaService.GenerateFromSetlistAsync(_bandId, setlistId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.GenerateFromSetlist(_bandId, setlistId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<GemaReportDto>(created.Value);
        Assert.Equal("Setlist Report", returned.Title);
    }

    [Fact]
    public async Task GenerateFromSetlist_SetlistNotFound_DomainExceptionPropagates()
    {
        var setlistId = Guid.NewGuid();
        var request = new CreateGemaReportRequest("Report", null, DateTime.UtcNow, setlistId);
        _gemaService.GenerateFromSetlistAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CreateGemaReportRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Setlist not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GenerateFromSetlist(_bandId, setlistId, request, CancellationToken.None));
    }

    // ── PUT /api/bands/{bandId}/gema-reports/{id} ─────────────────────────────

    [Fact]
    public async Task UpdateReport_ValidRequest_ReturnsOkWithUpdatedDto()
    {
        var reportId = Guid.NewGuid();
        var request = new UpdateGemaReportRequest("Updated Title", "New Location");
        var expected = MakeReportDto(reportId, _bandId, "Updated Title");
        _gemaService.UpdateReportAsync(_bandId, reportId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.UpdateReport(_bandId, reportId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<GemaReportDto>(ok.Value);
        Assert.Equal("Updated Title", returned.Title);
    }

    [Fact]
    public async Task UpdateReport_FinalizedReport_DomainExceptionPropagates()
    {
        var reportId = Guid.NewGuid();
        var request = new UpdateGemaReportRequest("New Title");
        _gemaService.UpdateReportAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateGemaReportRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Cannot edit finalized report.", 409));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateReport(_bandId, reportId, request, CancellationToken.None));
    }

    // ── DELETE /api/bands/{bandId}/gema-reports/{id} ──────────────────────────

    [Fact]
    public async Task DeleteReport_ValidRequest_Returns204NoContent()
    {
        var reportId = Guid.NewGuid();
        _gemaService.DeleteReportAsync(_bandId, reportId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteReport(_bandId, reportId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteReport_SubmittedReport_DomainExceptionPropagates()
    {
        var reportId = Guid.NewGuid();
        _gemaService.DeleteReportAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Cannot delete submitted report.", 409));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteReport(_bandId, reportId, CancellationToken.None));
    }

    // ── POST /api/bands/{bandId}/gema-reports/{id}/entries ────────────────────

    [Fact]
    public async Task AddEntry_ValidRequest_Returns201WithDto()
    {
        var reportId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        var request = new AddGemaReportEntryRequest("Piece Title", "Composer Name");
        var expected = MakeEntryDto(entryId);
        _gemaService.AddEntryAsync(_bandId, reportId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.AddEntry(_bandId, reportId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var returned = Assert.IsType<GemaReportEntryDto>(created.Value);
        Assert.Equal(entryId, returned.Id);
    }

    [Fact]
    public async Task AddEntry_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new AddGemaReportEntryRequest("", "");

        var result = await _sut.AddEntry(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── PUT /api/bands/{bandId}/gema-reports/{reportId}/entries/{entryId} ─────

    [Fact]
    public async Task UpdateEntry_ValidRequest_ReturnsOkWithUpdatedDto()
    {
        var reportId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        var request = new UpdateGemaReportEntryRequest("Updated Title", "Updated Composer");
        var expected = MakeEntryDto(entryId);
        _gemaService.UpdateEntryAsync(_bandId, reportId, entryId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.UpdateEntry(_bandId, reportId, entryId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<GemaReportEntryDto>(ok.Value);
        Assert.Equal(entryId, returned.Id);
    }

    [Fact]
    public async Task UpdateEntry_EntryNotFound_DomainExceptionPropagates()
    {
        var request = new UpdateGemaReportEntryRequest("Title");
        _gemaService.UpdateEntryAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<UpdateGemaReportEntryRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Entry not found.", 404));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateEntry(_bandId, Guid.NewGuid(), Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── DELETE /api/bands/{bandId}/gema-reports/{reportId}/entries/{entryId} ──

    [Fact]
    public async Task DeleteEntry_ValidRequest_Returns204NoContent()
    {
        var reportId = Guid.NewGuid();
        var entryId = Guid.NewGuid();
        _gemaService.DeleteEntryAsync(_bandId, reportId, entryId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteEntry(_bandId, reportId, entryId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── POST /api/bands/{bandId}/gema-reports/{id}/finalize ───────────────────

    [Fact]
    public async Task FinalizeReport_ValidRequest_ReturnsOkWithDto()
    {
        var reportId = Guid.NewGuid();
        var expected = MakeReportDto(reportId, _bandId);
        _gemaService.FinalizeReportAsync(_bandId, reportId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(expected);

        var result = await _sut.FinalizeReport(_bandId, reportId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<GemaReportDto>(ok.Value);
        Assert.Equal(reportId, returned.Id);
    }

    [Fact]
    public async Task FinalizeReport_EmptyReport_DomainExceptionPropagates()
    {
        _gemaService.FinalizeReportAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("VALIDATION_ERROR", "Cannot finalize empty report.", 400));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.FinalizeReport(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── GET /api/bands/{bandId}/gema-reports/{id}/export ──────────────────────

    [Fact]
    public async Task ExportReport_CsvFormat_ReturnsFileResult()
    {
        var reportId = Guid.NewGuid();
        var csvData = System.Text.Encoding.UTF8.GetBytes("Position;Werktitel\n1;Test Song");
        _gemaService.ExportReportAsync(_bandId, reportId, "csv", _musicianId, Arg.Any<CancellationToken>())
            .Returns(csvData);

        var result = await _sut.ExportReport(_bandId, reportId, "csv", CancellationToken.None);

        var file = Assert.IsType<FileContentResult>(result);
        Assert.Equal("text/csv", file.ContentType);
        Assert.Contains("GEMA_Report_", file.FileDownloadName);
        Assert.Contains(".csv", file.FileDownloadName);
    }

    [Fact]
    public async Task ExportReport_XmlFormat_ReturnsFileResult()
    {
        var reportId = Guid.NewGuid();
        var xmlData = System.Text.Encoding.UTF8.GetBytes("<?xml version=\"1.0\"?><GEMAMeldung></GEMAMeldung>");
        _gemaService.ExportReportAsync(_bandId, reportId, "xml", _musicianId, Arg.Any<CancellationToken>())
            .Returns(xmlData);

        var result = await _sut.ExportReport(_bandId, reportId, "xml", CancellationToken.None);

        var file = Assert.IsType<FileContentResult>(result);
        Assert.Equal("application/xml", file.ContentType);
        Assert.Contains(".xml", file.FileDownloadName);
    }

    [Fact]
    public async Task ExportReport_UnsupportedFormat_DomainExceptionPropagates()
    {
        _gemaService.ExportReportAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("VALIDATION_ERROR", "Unsupported format.", 400));

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.ExportReport(_bandId, Guid.NewGuid(), "pdf", CancellationToken.None));
    }

    // ── Band-scoped access ────────────────────────────────────────────────────

    [Fact]
    public async Task BandScopedAccess_ServiceEnforcesIsolation_ControllerPropagatesException()
    {
        var foreignBandId = Guid.NewGuid();
        _gemaService.GetReportsAsync(foreignBandId, _musicianId, null, Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Band not found or no access.", 404));

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetReports(foreignBandId, null, CancellationToken.None));

        Assert.Equal("NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }
}
