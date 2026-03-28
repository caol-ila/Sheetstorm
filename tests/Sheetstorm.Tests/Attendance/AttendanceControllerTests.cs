using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Api.Controllers;
using Sheetstorm.Domain.Attendance;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Attendance;

namespace Sheetstorm.Tests.Attendance;

public class AttendanceControllerTests
{
    private readonly IAttendanceService _attendanceService;
    private readonly AttendanceController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public AttendanceControllerTests()
    {
        _attendanceService = Substitute.For<IAttendanceService>();
        _sut = new AttendanceController(_attendanceService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static AttendanceRecordDto MakeRecordDto(Guid id) =>
        new(id, Guid.NewGuid(), "Musician", DateOnly.FromDateTime(DateTime.UtcNow), 
            AttendanceStatus.Present, null, null, Guid.NewGuid(), "Recorder", DateTime.UtcNow);

    // ── GET /Attendance ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetAll_ReturnsOkWithList()
    {
        var records = new List<AttendanceRecordDto> { MakeRecordDto(Guid.NewGuid()) };
        _attendanceService.GetAllAsync(_bandId, _musicianId, null, null, Arg.Any<CancellationToken>())
            .Returns(records);

        var result = await _sut.GetAll(_bandId, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<AttendanceRecordDto>>(ok.Value);
        Assert.Single(returned);
    }

    [Fact]
    public async Task GetAll_WithDateRange_PassesToService()
    {
        var start = new DateOnly(2024, 1, 1);
        var end = new DateOnly(2024, 12, 31);
        _attendanceService.GetAllAsync(_bandId, _musicianId, start, end, Arg.Any<CancellationToken>())
            .Returns(new List<AttendanceRecordDto>());

        await _sut.GetAll(_bandId, start, end, CancellationToken.None);

        await _attendanceService.Received(1).GetAllAsync(_bandId, _musicianId, start, end, Arg.Any<CancellationToken>());
    }

    // ── GET /Attendance/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task GetById_ReturnsOkWithDto()
    {
        var recordId = Guid.NewGuid();
        var dto = MakeRecordDto(recordId);
        _attendanceService.GetByIdAsync(_bandId, recordId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetById(_bandId, recordId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<AttendanceRecordDto>(ok.Value);
        Assert.Equal(recordId, returned.Id);
    }

    [Fact]
    public async Task GetById_NotFound_PropagatesDomainException()
    {
        _attendanceService.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetById(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /Attendance ──────────────────────────────────────────────────────

    [Fact]
    public async Task Create_ValidRequest_Returns201()
    {
        var request = new CreateAttendanceRecordRequest(Guid.NewGuid(), DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);
        var dto = MakeRecordDto(Guid.NewGuid());
        _attendanceService.CreateAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<AttendanceRecordDto>(created.Value);
    }

    [Fact]
    public async Task Create_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("MusicianId", "Required");
        var request = new CreateAttendanceRecordRequest(Guid.Empty, DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);

        var result = await _sut.Create(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    [Fact]
    public async Task Create_Conflict_PropagatesDomainException()
    {
        var request = new CreateAttendanceRecordRequest(Guid.NewGuid(), DateOnly.FromDateTime(DateTime.UtcNow), AttendanceStatus.Present, null, null);
        _attendanceService.CreateAsync(Arg.Any<Guid>(), Arg.Any<CreateAttendanceRecordRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Duplicate.", 409));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.Create(_bandId, request, CancellationToken.None));
    }

    // ── PUT /Attendance/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task Update_ValidRequest_ReturnsOk()
    {
        var recordId = Guid.NewGuid();
        var request = new UpdateAttendanceRecordRequest(AttendanceStatus.Absent, "Notes");
        var dto = MakeRecordDto(recordId);
        _attendanceService.UpdateAsync(_bandId, recordId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.Update(_bandId, recordId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<AttendanceRecordDto>(ok.Value);
    }

    [Fact]
    public async Task Update_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Status", "Required");
        var request = new UpdateAttendanceRecordRequest(AttendanceStatus.Present, null);

        var result = await _sut.Update(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── DELETE /Attendance/{id} ───────────────────────────────────────────────

    [Fact]
    public async Task Delete_ValidRequest_Returns204()
    {
        var recordId = Guid.NewGuid();
        _attendanceService.DeleteAsync(_bandId, recordId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.Delete(_bandId, recordId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── GET /Attendance/stats ─────────────────────────────────────────────────

    [Fact]
    public async Task GetStats_ReturnsOkWithStats()
    {
        var stats = new BandAttendanceStatsDto(
            DateOnly.FromDateTime(DateTime.UtcNow),
            DateOnly.FromDateTime(DateTime.UtcNow),
            10,
            85.5,
            Array.Empty<AttendanceStatsDto>());
        _attendanceService.GetStatsAsync(_bandId, _musicianId, null, null, Arg.Any<CancellationToken>())
            .Returns(stats);

        var result = await _sut.GetStats(_bandId, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<BandAttendanceStatsDto>(ok.Value);
        Assert.Equal(85.5, returned.AverageAttendanceRate);
    }

    // ── GET /Attendance/musicians/{musicianId}/stats ──────────────────────────

    [Fact]
    public async Task GetMusicianStats_ReturnsOkWithStats()
    {
        var targetId = Guid.NewGuid();
        var stats = new AttendanceStatsDto(targetId, "Musician", 10, 8, 1, 1, 0, 80.0);
        _attendanceService.GetMusicianStatsAsync(_bandId, targetId, _musicianId, null, null, Arg.Any<CancellationToken>())
            .Returns(stats);

        var result = await _sut.GetMusicianStats(_bandId, targetId, null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<AttendanceStatsDto>(ok.Value);
        Assert.Equal(80.0, returned.AttendanceRate);
    }
}
