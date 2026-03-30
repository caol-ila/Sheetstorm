using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Tasks;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Tasks;

public class TaskService(AppDbContext db) : ITaskService
{
    public async Task<BandTaskDto> CreateTaskAsync(Guid bandId, CreateTaskRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorAdminOrSectionLeaderAsync(bandId, musicianId, ct);

        var task = new BandTask
        {
            BandId = bandId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            Status = BandTaskStatus.Open,
            Priority = request.Priority,
            DueDate = request.DueDate,
            EventId = request.EventId,
            CreatedByMusicianId = musicianId
        };

        db.Set<BandTask>().Add(task);

        if (request.AssigneeIds is { Count: > 0 })
        {
            await ValidateAssigneesAsync(bandId, request.AssigneeIds, ct);
            foreach (var assigneeId in request.AssigneeIds)
            {
                db.Set<BandTaskAssignment>().Add(new BandTaskAssignment
                {
                    BandTaskId = task.Id,
                    MusicianId = assigneeId
                });
            }
        }

        await db.SaveChangesAsync(ct);

        return await GetTaskAsync(bandId, task.Id, musicianId, ct);
    }

    public async Task<IReadOnlyList<BandTaskDto>> GetTasksAsync(Guid bandId, Guid musicianId, TaskQueryParams query, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var q = db.Set<BandTask>()
            .Where(t => t.BandId == bandId)
            .Include(t => t.CreatedByMusician)
            .Include(t => t.Assignments)
                .ThenInclude(a => a.Musician)
            .AsQueryable();

        if (query.Status.HasValue)
            q = q.Where(t => t.Status == query.Status.Value);

        if (query.AssigneeId.HasValue)
            q = q.Where(t => t.Assignments.Any(a => a.MusicianId == query.AssigneeId.Value));

        q = (query.SortBy?.ToLower(), query.SortDir?.ToLower()) switch
        {
            ("duedate", "desc") => q.OrderByDescending(t => t.DueDate),
            ("duedate", _)      => q.OrderBy(t => t.DueDate),
            ("createdat", "desc") => q.OrderByDescending(t => t.CreatedAt),
            ("createdat", _)      => q.OrderBy(t => t.CreatedAt),
            _                     => q.OrderBy(t => t.DueDate)
        };

        var tasks = await q.ToListAsync(ct);
        return tasks.Select(MapToDto).ToList();
    }

    public async Task<BandTaskDto> GetTaskAsync(Guid bandId, Guid taskId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var task = await db.Set<BandTask>()
            .Where(t => t.BandId == bandId && t.Id == taskId)
            .Include(t => t.CreatedByMusician)
            .Include(t => t.Assignments)
                .ThenInclude(a => a.Musician)
            .FirstOrDefaultAsync(ct);

        if (task is null)
            throw new DomainException("NOT_FOUND", "Task not found.", 404);

        return MapToDto(task);
    }

    public async Task<BandTaskDto> UpdateTaskAsync(Guid bandId, Guid taskId, UpdateTaskRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorAdminOrSectionLeaderAsync(bandId, musicianId, ct);

        var task = await RequireTaskInBandAsync(bandId, taskId, ct);

        task.Title = request.Title.Trim();
        task.Description = request.Description?.Trim();
        task.DueDate = request.DueDate;
        task.Priority = request.Priority;
        task.EventId = request.EventId;

        await db.SaveChangesAsync(ct);

        return await GetTaskAsync(bandId, taskId, musicianId, ct);
    }

    public async Task DeleteTaskAsync(Guid bandId, Guid taskId, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorAdminOrSectionLeaderAsync(bandId, musicianId, ct);

        var task = await RequireTaskInBandAsync(bandId, taskId, ct);

        var assignments = await db.Set<BandTaskAssignment>()
            .Where(a => a.BandTaskId == taskId)
            .ToListAsync(ct);

        db.Set<BandTaskAssignment>().RemoveRange(assignments);
        db.Set<BandTask>().Remove(task);

        await db.SaveChangesAsync(ct);
    }

    public async Task<BandTaskDto> UpdateStatusAsync(Guid bandId, Guid taskId, UpdateTaskStatusRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var task = await db.Set<BandTask>()
            .Where(t => t.BandId == bandId && t.Id == taskId)
            .Include(t => t.Assignments)
            .FirstOrDefaultAsync(ct)
            ?? throw new DomainException("NOT_FOUND", "Task not found.", 404);

        var isCreator = task.CreatedByMusicianId == musicianId;
        var isAssignee = task.Assignments.Any(a => a.MusicianId == musicianId);

        if (!isCreator && !isAssignee)
            throw new DomainException("FORBIDDEN", "Only the creator or assigned members can change the status.", 403);

        task.Status = request.Status;

        await db.SaveChangesAsync(ct);

        return await GetTaskAsync(bandId, taskId, musicianId, ct);
    }

    public async Task<BandTaskDto> AssignTaskAsync(Guid bandId, Guid taskId, AssignTaskRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorAdminOrSectionLeaderAsync(bandId, musicianId, ct);

        await RequireTaskInBandAsync(bandId, taskId, ct);

        await ValidateAssigneesAsync(bandId, request.AssigneeIds, ct);

        var existing = await db.Set<BandTaskAssignment>()
            .Where(a => a.BandTaskId == taskId)
            .ToListAsync(ct);

        db.Set<BandTaskAssignment>().RemoveRange(existing);

        foreach (var assigneeId in request.AssigneeIds)
        {
            db.Set<BandTaskAssignment>().Add(new BandTaskAssignment
            {
                BandTaskId = taskId,
                MusicianId = assigneeId
            });
        }

        await db.SaveChangesAsync(ct);

        return await GetTaskAsync(bandId, taskId, musicianId, ct);
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    private async Task RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var exists = await db.Memberships
            .AnyAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        if (!exists)
            throw new DomainException("FORBIDDEN", "Band not found or no access.", 403);
    }

    private async Task RequireConductorAdminOrSectionLeaderAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var membership = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        if (membership is null)
            throw new DomainException("FORBIDDEN", "Band not found or no access.", 403);

        if (membership.Role is not (MemberRole.Administrator or MemberRole.Conductor or MemberRole.SectionLeader))
            throw new DomainException("FORBIDDEN", "Only conductors, admins, or section leaders can perform this action.", 403);
    }

    private async Task<BandTask> RequireTaskInBandAsync(Guid bandId, Guid taskId, CancellationToken ct)
    {
        var task = await db.Set<BandTask>()
            .FirstOrDefaultAsync(t => t.BandId == bandId && t.Id == taskId, ct);

        return task ?? throw new DomainException("NOT_FOUND", "Task not found.", 404);
    }

    private async Task ValidateAssigneesAsync(Guid bandId, List<Guid> assigneeIds, CancellationToken ct)
    {
        var memberIds = await db.Memberships
            .Where(m => m.BandId == bandId && m.IsActive && assigneeIds.Contains(m.MusicianId))
            .Select(m => m.MusicianId)
            .ToListAsync(ct);

        var missing = assigneeIds.Except(memberIds).ToList();
        if (missing.Count > 0)
            throw new DomainException("VALIDATION_ERROR", "One or more assignees are not band members.", 400);
    }

    private static BandTaskDto MapToDto(BandTask task) => new(
        task.Id,
        task.BandId,
        task.Title,
        task.Description,
        task.Status,
        task.Priority,
        task.DueDate,
        task.EventId,
        task.CreatedByMusicianId,
        task.CreatedByMusician.Name,
        task.Assignments.Select(a => new TaskAssigneeDto(a.MusicianId, a.Musician.Name)).ToList(),
        task.CreatedAt,
        task.UpdatedAt
    );
}
