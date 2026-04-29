using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed record ShiftWithCount(Guid Id, string Title, DateTimeOffset StartUtc, DateTimeOffset EndUtc, int RequiredCount, int AssignedCount, bool IsAssignedToMe);

public sealed class ShiftService(SheetstormDbContext db)
{
    public async Task<List<ShiftWithCount>> GetForEventAsync(Guid eventId, Guid currentUserId, CancellationToken ct = default)
    {
        return await db.EventShifts
            .Where(s => s.EventId == eventId)
            .OrderBy(s => s.StartUtc)
            .Select(s => new ShiftWithCount(s.Id, s.Title, s.StartUtc, s.EndUtc, s.RequiredCount,
                s.Assignments.Count(),
                s.Assignments.Any(a => a.UserId == currentUserId)))
            .ToListAsync(ct);
    }

    public async Task<EventShift> CreateAsync(Guid eventId, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, int requiredCount, CancellationToken ct = default)
    {
        var s = EventShift.Create(eventId, title, startUtc, endUtc, requiredCount);
        db.EventShifts.Add(s);
        await db.SaveChangesAsync(ct);
        return s;
    }

    public async Task DeleteAsync(Guid shiftId, CancellationToken ct = default)
    {
        var s = await db.EventShifts.FirstOrDefaultAsync(x => x.Id == shiftId, ct);
        if (s is null) return;
        db.EventShifts.Remove(s);
        await db.SaveChangesAsync(ct);
    }

    public async Task<bool> ToggleAssignAsync(Guid shiftId, Guid userId, CancellationToken ct = default)
    {
        var existing = await db.ShiftAssignments.FirstOrDefaultAsync(x => x.ShiftId == shiftId && x.UserId == userId, ct);
        if (existing is null)
        {
            db.ShiftAssignments.Add(ShiftAssignment.Create(shiftId, userId));
            await db.SaveChangesAsync(ct);
            return true;
        }
        else
        {
            db.ShiftAssignments.Remove(existing);
            await db.SaveChangesAsync(ct);
            return false;
        }
    }

    public async Task<List<Guid>> GetAssignedUsersAsync(Guid shiftId, CancellationToken ct = default)
        => await db.ShiftAssignments.Where(x => x.ShiftId == shiftId).Select(x => x.UserId).ToListAsync(ct);
}
