using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Shifts;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Shifts;

public class ShiftService(AppDbContext db, IBandAuthorizationService bandAuth) : IShiftService
{
    // ── ShiftPlan CRUD ───────────────────────────────────────────────────────

    public async Task<ShiftPlanDto> CreateShiftPlanAsync(Guid bandId, CreateShiftPlanRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = new ShiftPlan
        {
            BandId = bandId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            EventId = request.EventId,
            CreatedByMusicianId = musicianId
        };

        db.Set<ShiftPlan>().Add(plan);
        await db.SaveChangesAsync(ct);

        return await GetShiftPlanAsync(bandId, plan.Id, musicianId, ct);
    }

    public async Task<IReadOnlyList<ShiftPlanDto>> GetShiftPlansAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plans = await db.Set<ShiftPlan>()
            .Where(p => p.BandId == bandId)
            .Include(p => p.CreatedByMusician)
            .Include(p => p.Shifts)
                .ThenInclude(s => s.Assignments)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return plans.Select(MapPlanToDto).ToList();
    }

    public async Task<ShiftPlanDto> GetShiftPlanAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .Include(p => p.CreatedByMusician)
            .Include(p => p.Shifts)
                .ThenInclude(s => s.Assignments)
            .FirstOrDefaultAsync(p => p.Id == planId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        return MapPlanToDto(plan);
    }

    public async Task<ShiftPlanDto> UpdateShiftPlanAsync(Guid bandId, Guid planId, UpdateShiftPlanRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .FirstOrDefaultAsync(p => p.Id == planId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        plan.Title = request.Title.Trim();
        plan.Description = request.Description?.Trim();
        plan.EventId = request.EventId;

        await db.SaveChangesAsync(ct);

        return await GetShiftPlanAsync(bandId, planId, musicianId, ct);
    }

    public async Task DeleteShiftPlanAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .FirstOrDefaultAsync(p => p.Id == planId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        db.Set<ShiftPlan>().Remove(plan);
        await db.SaveChangesAsync(ct);
    }

    // ── Shift CRUD ───────────────────────────────────────────────────────────

    public async Task<ShiftDto> CreateShiftAsync(Guid bandId, Guid planId, CreateShiftRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        if (request.EndTime <= request.StartTime)
            throw new DomainException("VALIDATION_ERROR", "End time must be after start time.", 400);

        var shift = new Shift
        {
            ShiftPlanId = planId,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            RequiredCount = request.RequiredCount,
            VoiceId = request.VoiceId
        };

        db.Set<Shift>().Add(shift);
        await db.SaveChangesAsync(ct);

        return await GetShiftAsync(bandId, planId, shift.Id, musicianId, ct);
    }

    public async Task<IReadOnlyList<ShiftSummaryDto>> GetShiftsAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var shifts = await db.Set<Shift>()
            .Where(s => s.ShiftPlanId == planId)
            .Include(s => s.Assignments)
            .OrderBy(s => s.StartTime)
            .ToListAsync(ct);

        return shifts.Select(s => new ShiftSummaryDto(
            s.Id,
            s.ShiftPlanId,
            s.Name,
            s.StartTime,
            s.EndTime,
            s.RequiredCount,
            s.Assignments.Count,
            Math.Max(0, s.RequiredCount - s.Assignments.Count)
        )).ToList();
    }

    public async Task<ShiftDto> GetShiftAsync(Guid bandId, Guid planId, Guid shiftId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var shift = await db.Set<Shift>()
            .Include(s => s.Assignments)
                .ThenInclude(a => a.Musician)
            .Include(s => s.Assignments)
                .ThenInclude(a => a.AssignedByMusician)
            .FirstOrDefaultAsync(s => s.Id == shiftId && s.ShiftPlanId == planId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift not found.", 404);

        return MapShiftToDto(shift);
    }

    public async Task<ShiftDto> UpdateShiftAsync(Guid bandId, Guid planId, Guid shiftId, UpdateShiftRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var shift = await db.Set<Shift>()
            .FirstOrDefaultAsync(s => s.Id == shiftId && s.ShiftPlanId == planId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift not found.", 404);

        if (request.EndTime <= request.StartTime)
            throw new DomainException("VALIDATION_ERROR", "End time must be after start time.", 400);

        shift.Name = request.Name.Trim();
        shift.Description = request.Description?.Trim();
        shift.StartTime = request.StartTime;
        shift.EndTime = request.EndTime;
        shift.RequiredCount = request.RequiredCount;
        shift.VoiceId = request.VoiceId;

        await db.SaveChangesAsync(ct);

        return await GetShiftAsync(bandId, planId, shiftId, musicianId, ct);
    }

    public async Task DeleteShiftAsync(Guid bandId, Guid planId, Guid shiftId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var shift = await db.Set<Shift>()
            .Include(s => s.Assignments)
            .FirstOrDefaultAsync(s => s.Id == shiftId && s.ShiftPlanId == planId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift not found.", 404);

        db.Set<Shift>().Remove(shift);
        await db.SaveChangesAsync(ct);
    }

    // ── Assignments ──────────────────────────────────────────────────────────

    public async Task<ShiftAssignmentDto> CreateAssignmentAsync(Guid bandId, Guid planId, Guid shiftId, CreateShiftAssignmentRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var shift = await db.Set<Shift>()
            .Include(s => s.Assignments)
            .FirstOrDefaultAsync(s => s.Id == shiftId && s.ShiftPlanId == planId, ct)
            ?? throw new DomainException("NOT_FOUND", "Shift not found.", 404);

        // Determine target musician (self-signup vs admin assignment)
        var targetMusicianId = request.MusicianId ?? musicianId;

        if (request.MusicianId.HasValue && request.MusicianId != musicianId)
        {
            // Admin assignment — require conductor/admin role
            var membership = await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);
        }

        // Check if already assigned
        if (shift.Assignments.Any(a => a.MusicianId == targetMusicianId))
            throw new DomainException("CONFLICT", "Musician is already assigned to this shift.", 409);

        // Check capacity
        if (shift.Assignments.Count >= shift.RequiredCount)
            throw new DomainException("CONFLICT", "Shift is already full.", 409);

        var assignment = new ShiftAssignment
        {
            ShiftId = shiftId,
            MusicianId = targetMusicianId,
            AssignedByMusicianId = request.MusicianId.HasValue ? musicianId : null,
            Status = ShiftAssignmentStatus.Assigned
        };

        db.Set<ShiftAssignment>().Add(assignment);
        await db.SaveChangesAsync(ct);

        // Reload with navigation
        assignment = await db.Set<ShiftAssignment>()
            .Include(a => a.Musician)
            .Include(a => a.AssignedByMusician)
            .FirstAsync(a => a.Id == assignment.Id, ct);

        return MapAssignmentToDto(assignment);
    }

    public async Task DeleteAssignmentAsync(Guid bandId, Guid planId, Guid shiftId, Guid assignmentId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var assignment = await db.Set<ShiftAssignment>()
            .FirstOrDefaultAsync(a => a.Id == assignmentId && a.ShiftId == shiftId, ct)
            ?? throw new DomainException("NOT_FOUND", "Assignment not found.", 404);

        // Self-removal: only own self-signups; admins can remove any
        if (assignment.MusicianId != musicianId)
            await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        db.Set<ShiftAssignment>().Remove(assignment);
        await db.SaveChangesAsync(ct);
    }

    public async Task<ShiftAssignmentDto> UpdateAssignmentStatusAsync(Guid bandId, Guid planId, Guid shiftId, Guid assignmentId, UpdateShiftAssignmentStatusRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var plan = await db.Set<ShiftPlan>()
            .AnyAsync(p => p.Id == planId && p.BandId == bandId, ct);
        if (!plan)
            throw new DomainException("NOT_FOUND", "Shift plan not found.", 404);

        var assignment = await db.Set<ShiftAssignment>()
            .Include(a => a.Musician)
            .Include(a => a.AssignedByMusician)
            .FirstOrDefaultAsync(a => a.Id == assignmentId && a.ShiftId == shiftId, ct)
            ?? throw new DomainException("NOT_FOUND", "Assignment not found.", 404);

        // Only the assigned musician or an admin can update status
        if (assignment.MusicianId != musicianId)
            await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        assignment.Status = request.Status;
        assignment.Notes = request.Notes?.Trim();

        await db.SaveChangesAsync(ct);

        return MapAssignmentToDto(assignment);
    }

    public async Task<IReadOnlyList<MyShiftDto>> GetMyShiftsAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var assignments = await db.Set<ShiftAssignment>()
            .Where(a => a.MusicianId == musicianId)
            .Include(a => a.Shift)
                .ThenInclude(s => s.ShiftPlan)
            .Where(a => a.Shift.ShiftPlan.BandId == bandId)
            .OrderBy(a => a.Shift.StartTime)
            .ToListAsync(ct);

        return assignments.Select(a => new MyShiftDto(
            a.Shift.ShiftPlanId,
            a.Shift.ShiftPlan.Title,
            a.ShiftId,
            a.Shift.Name,
            a.Shift.StartTime,
            a.Shift.EndTime,
            a.Status,
            a.CreatedAt
        )).ToList();
    }

    // ── Private Helpers ──────────────────────────────────────────────────────

    private static ShiftPlanDto MapPlanToDto(ShiftPlan plan)
    {
        var totalAssignments = plan.Shifts.Sum(s => s.Assignments.Count);
        var totalRequired = plan.Shifts.Sum(s => s.RequiredCount);

        return new ShiftPlanDto(
            plan.Id,
            plan.BandId,
            plan.EventId,
            plan.Title,
            plan.Description,
            plan.CreatedByMusicianId,
            plan.CreatedByMusician.Name,
            plan.Shifts.Count,
            totalAssignments,
            Math.Max(0, totalRequired - totalAssignments),
            plan.CreatedAt
        );
    }

    private static ShiftDto MapShiftToDto(Shift shift) => new(
        shift.Id,
        shift.ShiftPlanId,
        shift.Name,
        shift.Description,
        shift.StartTime,
        shift.EndTime,
        shift.RequiredCount,
        shift.VoiceId,
        shift.Assignments.Count,
        Math.Max(0, shift.RequiredCount - shift.Assignments.Count),
        shift.Assignments.Select(MapAssignmentToDto).ToList(),
        shift.CreatedAt
    );

    private static ShiftAssignmentDto MapAssignmentToDto(ShiftAssignment assignment) => new(
        assignment.Id,
        assignment.ShiftId,
        assignment.MusicianId,
        assignment.Musician.Name,
        assignment.AssignedByMusicianId,
        assignment.AssignedByMusician?.Name,
        assignment.Status,
        assignment.Notes,
        assignment.CreatedAt
    );

}
