using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Shifts;
using Sheetstorm.Infrastructure.Shifts;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/shift-plans")]
[Authorize]
public class ShiftController(IShiftService shiftService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // ── ShiftPlan CRUD ───────────────────────────────────────────────────────

    // GET /api/bands/{bandId}/shift-plans
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<ShiftPlanDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetShiftPlans(Guid bandId, CancellationToken ct)
    {
        var result = await shiftService.GetShiftPlansAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/shift-plans/{planId}
    [HttpGet("{planId:guid}")]
    [ProducesResponseType(typeof(ShiftPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetShiftPlan(Guid bandId, Guid planId, CancellationToken ct)
    {
        var result = await shiftService.GetShiftPlanAsync(bandId, planId, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/shift-plans
    [HttpPost]
    [ProducesResponseType(typeof(ShiftPlanDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateShiftPlan(
        Guid bandId,
        [FromBody] CreateShiftPlanRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await shiftService.CreateShiftPlanAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/shift-plans/{planId}
    [HttpPut("{planId:guid}")]
    [ProducesResponseType(typeof(ShiftPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateShiftPlan(
        Guid bandId,
        Guid planId,
        [FromBody] UpdateShiftPlanRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await shiftService.UpdateShiftPlanAsync(bandId, planId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/shift-plans/{planId}
    [HttpDelete("{planId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteShiftPlan(Guid bandId, Guid planId, CancellationToken ct)
    {
        await shiftService.DeleteShiftPlanAsync(bandId, planId, CurrentUserId, ct);
        return NoContent();
    }

    // ── Shift CRUD ───────────────────────────────────────────────────────────

    // GET /api/bands/{bandId}/shift-plans/{planId}/shifts
    [HttpGet("{planId:guid}/shifts")]
    [ProducesResponseType(typeof(IReadOnlyList<ShiftSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetShifts(Guid bandId, Guid planId, CancellationToken ct)
    {
        var result = await shiftService.GetShiftsAsync(bandId, planId, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}
    [HttpGet("{planId:guid}/shifts/{shiftId:guid}")]
    [ProducesResponseType(typeof(ShiftDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetShift(Guid bandId, Guid planId, Guid shiftId, CancellationToken ct)
    {
        var result = await shiftService.GetShiftAsync(bandId, planId, shiftId, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/shift-plans/{planId}/shifts
    [HttpPost("{planId:guid}/shifts")]
    [ProducesResponseType(typeof(ShiftDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateShift(
        Guid bandId,
        Guid planId,
        [FromBody] CreateShiftRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await shiftService.CreateShiftAsync(bandId, planId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}
    [HttpPut("{planId:guid}/shifts/{shiftId:guid}")]
    [ProducesResponseType(typeof(ShiftDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateShift(
        Guid bandId,
        Guid planId,
        Guid shiftId,
        [FromBody] UpdateShiftRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await shiftService.UpdateShiftAsync(bandId, planId, shiftId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}
    [HttpDelete("{planId:guid}/shifts/{shiftId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteShift(Guid bandId, Guid planId, Guid shiftId, CancellationToken ct)
    {
        await shiftService.DeleteShiftAsync(bandId, planId, shiftId, CurrentUserId, ct);
        return NoContent();
    }

    // ── Assignments ──────────────────────────────────────────────────────────

    // POST /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}/assignments
    [HttpPost("{planId:guid}/shifts/{shiftId:guid}/assignments")]
    [ProducesResponseType(typeof(ShiftAssignmentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateAssignment(
        Guid bandId,
        Guid planId,
        Guid shiftId,
        [FromBody] CreateShiftAssignmentRequest request,
        CancellationToken ct)
    {
        var result = await shiftService.CreateAssignmentAsync(bandId, planId, shiftId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // DELETE /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}/assignments/{assignmentId}
    [HttpDelete("{planId:guid}/shifts/{shiftId:guid}/assignments/{assignmentId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteAssignment(
        Guid bandId,
        Guid planId,
        Guid shiftId,
        Guid assignmentId,
        CancellationToken ct)
    {
        await shiftService.DeleteAssignmentAsync(bandId, planId, shiftId, assignmentId, CurrentUserId, ct);
        return NoContent();
    }

    // PUT /api/bands/{bandId}/shift-plans/{planId}/shifts/{shiftId}/assignments/{assignmentId}/status
    [HttpPut("{planId:guid}/shifts/{shiftId:guid}/assignments/{assignmentId:guid}/status")]
    [ProducesResponseType(typeof(ShiftAssignmentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateAssignmentStatus(
        Guid bandId,
        Guid planId,
        Guid shiftId,
        Guid assignmentId,
        [FromBody] UpdateShiftAssignmentStatusRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await shiftService.UpdateAssignmentStatusAsync(bandId, planId, shiftId, assignmentId, request, CurrentUserId, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/shift-plans/my-shifts
    [HttpGet("my-shifts")]
    [ProducesResponseType(typeof(IReadOnlyList<MyShiftDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyShifts(Guid bandId, CancellationToken ct)
    {
        var result = await shiftService.GetMyShiftsAsync(bandId, CurrentUserId, ct);
        return Ok(result);
    }
}
