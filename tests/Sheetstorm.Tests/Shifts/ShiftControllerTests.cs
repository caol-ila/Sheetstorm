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
using Sheetstorm.Domain.Shifts;
using Sheetstorm.Infrastructure.Shifts;

namespace Sheetstorm.Tests.Shifts;

public class ShiftControllerTests
{
    private readonly IShiftService _shiftService;
    private readonly ShiftController _sut;
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _bandId = Guid.NewGuid();

    public ShiftControllerTests()
    {
        _shiftService = Substitute.For<IShiftService>();
        _sut = new ShiftController(_shiftService);

        var claims = new ClaimsPrincipal(new ClaimsIdentity([
            new Claim(JwtRegisteredClaimNames.Sub, _musicianId.ToString())
        ]));
        _sut.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claims }
        };
    }

    private static ShiftPlanDto MakePlanDto(Guid id) =>
        new(id, Guid.NewGuid(), null, "Plan", null, Guid.NewGuid(), "Creator", 0, 0, 0, DateTime.UtcNow);

    private static ShiftDto MakeShiftDto(Guid id, Guid planId) =>
        new(id, planId, "Shift", null, new TimeOnly(10, 0), new TimeOnly(12, 0), 2, null, 0, 2, Array.Empty<ShiftAssignmentDto>(), DateTime.UtcNow);

    private static ShiftSummaryDto MakeShiftSummaryDto(Guid id, Guid planId) =>
        new(id, planId, "Shift", new TimeOnly(10, 0), new TimeOnly(12, 0), 2, 0, 2);

    private static ShiftAssignmentDto MakeAssignmentDto(Guid id, Guid shiftId) =>
        new(id, shiftId, Guid.NewGuid(), "Musician", null, null, ShiftAssignmentStatus.Assigned, null, DateTime.UtcNow);

    // ── GET /ShiftPlans ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetShiftPlans_ReturnsOkWithList()
    {
        var plans = new List<ShiftPlanDto> { MakePlanDto(Guid.NewGuid()) };
        _shiftService.GetShiftPlansAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(plans);

        var result = await _sut.GetShiftPlans(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<ShiftPlanDto>>(ok.Value);
        Assert.Single(returned);
    }

    // ── GET /ShiftPlans/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task GetShiftPlan_ReturnsOkWithDto()
    {
        var planId = Guid.NewGuid();
        var dto = MakePlanDto(planId);
        _shiftService.GetShiftPlanAsync(_bandId, planId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetShiftPlan(_bandId, planId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<ShiftPlanDto>(ok.Value);
        Assert.Equal(planId, returned.Id);
    }

    [Fact]
    public async Task GetShiftPlan_NotFound_PropagatesDomainException()
    {
        _shiftService.GetShiftPlanAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("NOT_FOUND", "Not found.", 404));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetShiftPlan(_bandId, Guid.NewGuid(), CancellationToken.None));
    }

    // ── POST /ShiftPlans ──────────────────────────────────────────────────────

    [Fact]
    public async Task CreateShiftPlan_ValidRequest_Returns201()
    {
        var request = new CreateShiftPlanRequest("Plan Title", "Description", null);
        var dto = MakePlanDto(Guid.NewGuid());
        _shiftService.CreateShiftPlanAsync(_bandId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateShiftPlan(_bandId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<ShiftPlanDto>(created.Value);
    }

    [Fact]
    public async Task CreateShiftPlan_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Title", "Required");
        var request = new CreateShiftPlanRequest("", null, null);

        var result = await _sut.CreateShiftPlan(_bandId, request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── PUT /ShiftPlans/{id} ──────────────────────────────────────────────────

    [Fact]
    public async Task UpdateShiftPlan_ValidRequest_ReturnsOk()
    {
        var planId = Guid.NewGuid();
        var request = new UpdateShiftPlanRequest("Updated", "New desc", null);
        var dto = MakePlanDto(planId);
        _shiftService.UpdateShiftPlanAsync(_bandId, planId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateShiftPlan(_bandId, planId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<ShiftPlanDto>(ok.Value);
    }

    // ── DELETE /ShiftPlans/{id} ───────────────────────────────────────────────

    [Fact]
    public async Task DeleteShiftPlan_ValidRequest_Returns204()
    {
        var planId = Guid.NewGuid();
        _shiftService.DeleteShiftPlanAsync(_bandId, planId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteShiftPlan(_bandId, planId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── GET /ShiftPlans/{planId}/shifts ───────────────────────────────────────

    [Fact]
    public async Task GetShifts_ReturnsOkWithList()
    {
        var planId = Guid.NewGuid();
        var shifts = new List<ShiftSummaryDto> { MakeShiftSummaryDto(Guid.NewGuid(), planId) };
        _shiftService.GetShiftsAsync(_bandId, planId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(shifts);

        var result = await _sut.GetShifts(_bandId, planId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<ShiftSummaryDto>>(ok.Value);
        Assert.Single(returned);
    }

    // ── GET /ShiftPlans/{planId}/shifts/{shiftId} ─────────────────────────────

    [Fact]
    public async Task GetShift_ReturnsOkWithDto()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        var dto = MakeShiftDto(shiftId, planId);
        _shiftService.GetShiftAsync(_bandId, planId, shiftId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.GetShift(_bandId, planId, shiftId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsType<ShiftDto>(ok.Value);
        Assert.Equal(shiftId, returned.Id);
    }

    // ── POST /ShiftPlans/{planId}/shifts ──────────────────────────────────────

    [Fact]
    public async Task CreateShift_ValidRequest_Returns201()
    {
        var planId = Guid.NewGuid();
        var request = new CreateShiftRequest("Bar Duty", null, new TimeOnly(14, 0), new TimeOnly(18, 0), 3, null);
        var dto = MakeShiftDto(Guid.NewGuid(), planId);
        _shiftService.CreateShiftAsync(_bandId, planId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateShift(_bandId, planId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<ShiftDto>(created.Value);
    }

    [Fact]
    public async Task CreateShift_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Name", "Required");
        var request = new CreateShiftRequest("", null, new TimeOnly(10, 0), new TimeOnly(12, 0), 1, null);

        var result = await _sut.CreateShift(_bandId, Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── PUT /ShiftPlans/{planId}/shifts/{shiftId} ─────────────────────────────

    [Fact]
    public async Task UpdateShift_ValidRequest_ReturnsOk()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        var request = new UpdateShiftRequest("Updated", null, new TimeOnly(10, 0), new TimeOnly(12, 0), 2, null);
        var dto = MakeShiftDto(shiftId, planId);
        _shiftService.UpdateShiftAsync(_bandId, planId, shiftId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateShift(_bandId, planId, shiftId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<ShiftDto>(ok.Value);
    }

    // ── DELETE /ShiftPlans/{planId}/shifts/{shiftId} ──────────────────────────

    [Fact]
    public async Task DeleteShift_ValidRequest_Returns204()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        _shiftService.DeleteShiftAsync(_bandId, planId, shiftId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteShift(_bandId, planId, shiftId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── POST /ShiftPlans/{planId}/shifts/{shiftId}/assignments ────────────────

    [Fact]
    public async Task CreateAssignment_ValidRequest_Returns201()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        var request = new CreateShiftAssignmentRequest(null);
        var dto = MakeAssignmentDto(Guid.NewGuid(), shiftId);
        _shiftService.CreateAssignmentAsync(_bandId, planId, shiftId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.CreateAssignment(_bandId, planId, shiftId, request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        Assert.IsType<ShiftAssignmentDto>(created.Value);
    }

    [Fact]
    public async Task CreateAssignment_Conflict_PropagatesDomainException()
    {
        var request = new CreateShiftAssignmentRequest(null);
        _shiftService.CreateAssignmentAsync(Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<Guid>(), Arg.Any<CreateShiftAssignmentRequest>(), Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new DomainException("CONFLICT", "Shift full.", 409));

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateAssignment(_bandId, Guid.NewGuid(), Guid.NewGuid(), request, CancellationToken.None));
    }

    // ── DELETE /ShiftPlans/{planId}/shifts/{shiftId}/assignments/{assignmentId}

    [Fact]
    public async Task DeleteAssignment_ValidRequest_Returns204()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        var assignmentId = Guid.NewGuid();
        _shiftService.DeleteAssignmentAsync(_bandId, planId, shiftId, assignmentId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _sut.DeleteAssignment(_bandId, planId, shiftId, assignmentId, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    // ── PUT /ShiftPlans/{planId}/shifts/{shiftId}/assignments/{assignmentId}/status

    [Fact]
    public async Task UpdateAssignmentStatus_ValidRequest_ReturnsOk()
    {
        var planId = Guid.NewGuid();
        var shiftId = Guid.NewGuid();
        var assignmentId = Guid.NewGuid();
        var request = new UpdateShiftAssignmentStatusRequest(ShiftAssignmentStatus.Confirmed, "Will attend");
        var dto = MakeAssignmentDto(assignmentId, shiftId);
        _shiftService.UpdateAssignmentStatusAsync(_bandId, planId, shiftId, assignmentId, request, _musicianId, Arg.Any<CancellationToken>())
            .Returns(dto);

        var result = await _sut.UpdateAssignmentStatus(_bandId, planId, shiftId, assignmentId, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.IsType<ShiftAssignmentDto>(ok.Value);
    }

    [Fact]
    public async Task UpdateAssignmentStatus_InvalidModelState_ReturnsBadRequest()
    {
        _sut.ModelState.AddModelError("Status", "Required");
        var request = new UpdateShiftAssignmentStatusRequest(ShiftAssignmentStatus.Assigned, null);

        var result = await _sut.UpdateAssignmentStatus(_bandId, Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), request, CancellationToken.None);

        var bad = Assert.IsType<BadRequestObjectResult>(result);
        var err = Assert.IsType<ErrorResponse>(bad.Value);
        Assert.Equal("VALIDATION_ERROR", err.Error);
    }

    // ── GET /ShiftPlans/my-shifts ─────────────────────────────────────────────

    [Fact]
    public async Task GetMyShifts_ReturnsOkWithList()
    {
        var shifts = new List<MyShiftDto>
        {
            new(Guid.NewGuid(), "Plan", Guid.NewGuid(), "Shift", new TimeOnly(10, 0), new TimeOnly(12, 0), ShiftAssignmentStatus.Assigned, DateTime.UtcNow)
        };
        _shiftService.GetMyShiftsAsync(_bandId, _musicianId, Arg.Any<CancellationToken>())
            .Returns(shifts);

        var result = await _sut.GetMyShifts(_bandId, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var returned = Assert.IsAssignableFrom<IReadOnlyList<MyShiftDto>>(ok.Value);
        Assert.Single(returned);
    }
}
