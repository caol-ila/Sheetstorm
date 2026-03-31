using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Tasks;
using Sheetstorm.Infrastructure.Tasks;

namespace Sheetstorm.Api.Controllers;

[ApiController]
[Route("api/bands/{bandId:guid}/tasks")]
[Authorize]
public class TaskController(ITaskService taskService) : ControllerBase
{
    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(JwtRegisteredClaimNames.Sub)!);

    // GET /api/bands/{bandId}/tasks
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BandTaskDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetTasks(
        Guid bandId,
        [FromQuery] BandTaskStatus? status,
        [FromQuery] Guid? assigneeId,
        [FromQuery] string? sortBy,
        [FromQuery] string? sortDir,
        CancellationToken ct)
    {
        var query = new TaskQueryParams(status, assigneeId, sortBy ?? "dueDate", sortDir ?? "asc");
        var result = await taskService.GetTasksAsync(bandId, CurrentUserId, query, ct);
        return Ok(result);
    }

    // GET /api/bands/{bandId}/tasks/{id}
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(BandTaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTask(Guid bandId, Guid id, CancellationToken ct)
    {
        var result = await taskService.GetTaskAsync(bandId, id, CurrentUserId, ct);
        return Ok(result);
    }

    // POST /api/bands/{bandId}/tasks
    [HttpPost]
    [ProducesResponseType(typeof(BandTaskDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreateTask(
        Guid bandId,
        [FromBody] CreateTaskRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await taskService.CreateTaskAsync(bandId, request, CurrentUserId, ct);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // PUT /api/bands/{bandId}/tasks/{id}
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(BandTaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateTask(
        Guid bandId,
        Guid id,
        [FromBody] UpdateTaskRequest request,
        CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ErrorResponse("VALIDATION_ERROR", "Invalid input."));

        var result = await taskService.UpdateTaskAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // DELETE /api/bands/{bandId}/tasks/{id}
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteTask(Guid bandId, Guid id, CancellationToken ct)
    {
        await taskService.DeleteTaskAsync(bandId, id, CurrentUserId, ct);
        return NoContent();
    }

    // PATCH /api/bands/{bandId}/tasks/{id}/status
    [HttpPatch("{id:guid}/status")]
    [ProducesResponseType(typeof(BandTaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateStatus(
        Guid bandId,
        Guid id,
        [FromBody] UpdateTaskStatusRequest request,
        CancellationToken ct)
    {
        var result = await taskService.UpdateStatusAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }

    // PUT /api/bands/{bandId}/tasks/{id}/assignees
    [HttpPut("{id:guid}/assignees")]
    [ProducesResponseType(typeof(BandTaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AssignTask(
        Guid bandId,
        Guid id,
        [FromBody] AssignTaskRequest request,
        CancellationToken ct)
    {
        var result = await taskService.AssignTaskAsync(bandId, id, request, CurrentUserId, ct);
        return Ok(result);
    }
}
