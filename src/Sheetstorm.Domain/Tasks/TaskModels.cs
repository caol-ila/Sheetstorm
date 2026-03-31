using System.ComponentModel.DataAnnotations;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Tasks;

// ── Requests ──────────────────────────────────────────────────────────────────

public record CreateTaskRequest(
    [Required][StringLength(200, MinimumLength = 1)] string Title,
    [StringLength(2000)] string? Description,
    DateTime? DueDate,
    TaskPriority Priority = TaskPriority.Medium,
    Guid? EventId = null,
    List<Guid>? AssigneeIds = null
);

public record UpdateTaskRequest(
    [Required][StringLength(200, MinimumLength = 1)] string Title,
    [StringLength(2000)] string? Description,
    DateTime? DueDate,
    TaskPriority Priority = TaskPriority.Medium,
    Guid? EventId = null
);

public record UpdateTaskStatusRequest(
    [Required] BandTaskStatus Status
);

public record AssignTaskRequest(
    [Required] List<Guid> AssigneeIds
);

// ── Query parameters ──────────────────────────────────────────────────────────

public record TaskQueryParams(
    BandTaskStatus? Status = null,
    Guid? AssigneeId = null,
    string? SortBy = "dueDate",   // dueDate | createdAt
    string? SortDir = "asc"       // asc | desc
);

// ── Responses ─────────────────────────────────────────────────────────────────

public record BandTaskDto(
    Guid Id,
    Guid BandId,
    string Title,
    string? Description,
    BandTaskStatus Status,
    TaskPriority Priority,
    DateTime? DueDate,
    Guid? EventId,
    Guid CreatedByMusicianId,
    string CreatedByName,
    IReadOnlyList<TaskAssigneeDto> Assignees,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record TaskAssigneeDto(
    Guid MusicianId,
    string Name
);
