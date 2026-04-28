using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed record EventDayView(Guid Id, DateOnly Date, string? Theme, TimeOnly? OpenAt, TimeOnly? CloseAt);
public sealed record EventStationView(Guid Id, string Name, string? Description, string? IconKey);

public sealed record ShiftView(
    Guid Id,
    Guid EventId,
    Guid? EventDayId,
    Guid? StationId,
    string? StationName,
    string Title,
    DateTimeOffset StartUtc,
    DateTimeOffset EndUtc,
    int RequiredCount,
    int AssignedCount,
    bool IsAssignedToMe,
    bool IsTentative,
    string? Notes);

public sealed record ContributionView(
    Guid Id,
    string Title,
    string? Description,
    ContributionUnit Unit,
    int? Wanted,
    int Pledged,
    IReadOnlyList<PledgeView> Pledges);

public sealed record PledgeView(Guid Id, Guid UserId, string? UserDisplayName, int Quantity, string? What);

public sealed class EventOrgaService(SheetstormDbContext db)
{
    /* ───────── Tage ───────── */
    public async Task<List<EventDayView>> GetDaysAsync(Guid eventId, CancellationToken ct = default) =>
        await db.EventDays.Where(d => d.EventId == eventId).OrderBy(d => d.Date)
            .Select(d => new EventDayView(d.Id, d.Date, d.Theme, d.OpenAt, d.CloseAt)).ToListAsync(ct);

    public async Task<EventDay> AddDayAsync(Guid eventId, DateOnly date, string? theme, TimeOnly? openAt, TimeOnly? closeAt, CancellationToken ct = default)
    {
        var d = EventDay.Create(eventId, date, theme, openAt, closeAt);
        db.EventDays.Add(d);
        await db.SaveChangesAsync(ct);
        return d;
    }

    public async Task DeleteDayAsync(Guid dayId, CancellationToken ct = default)
    {
        var d = await db.EventDays.FirstOrDefaultAsync(x => x.Id == dayId, ct);
        if (d is null) return;
        db.EventDays.Remove(d);
        await db.SaveChangesAsync(ct);
    }

    /* ───────── Stationen ───────── */
    public async Task<List<EventStationView>> GetStationsAsync(Guid eventId, CancellationToken ct = default) =>
        await db.EventStations.Where(s => s.EventId == eventId).OrderBy(s => s.Name)
            .Select(s => new EventStationView(s.Id, s.Name, s.Description, s.IconKey)).ToListAsync(ct);

    public async Task<EventStation> AddStationAsync(Guid eventId, string name, string? description, string? iconKey, CancellationToken ct = default)
    {
        var s = EventStation.Create(eventId, name, description, iconKey);
        db.EventStations.Add(s);
        await db.SaveChangesAsync(ct);
        return s;
    }

    public async Task DeleteStationAsync(Guid stationId, CancellationToken ct = default)
    {
        var s = await db.EventStations.FirstOrDefaultAsync(x => x.Id == stationId, ct);
        if (s is null) return;
        db.EventStations.Remove(s);
        await db.SaveChangesAsync(ct);
    }

    /* ───────── Schichten ───────── */
    public async Task<List<ShiftView>> GetShiftsAsync(Guid eventId, Guid currentUserId, CancellationToken ct = default)
    {
        return await db.EventShifts
            .Where(s => s.EventId == eventId)
            .OrderBy(s => s.StartUtc)
            .Select(s => new ShiftView(
                s.Id, s.EventId, s.EventDayId, s.StationId,
                s.StationId.HasValue
                    ? db.EventStations.Where(x => x.Id == s.StationId).Select(x => x.Name).FirstOrDefault()
                    : null,
                s.Title, s.StartUtc, s.EndUtc, s.RequiredCount,
                s.Assignments.Count(),
                s.Assignments.Any(a => a.UserId == currentUserId),
                s.Assignments.Any(a => a.UserId == currentUserId && a.IsTentative),
                s.Notes))
            .ToListAsync(ct);
    }

    public async Task<EventShift> AddShiftAsync(Guid eventId, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, int requiredCount, Guid? stationId, Guid? eventDayId, string? notes, CancellationToken ct = default)
    {
        var s = EventShift.Create(eventId, title, startUtc, endUtc, requiredCount, stationId, eventDayId, notes);
        db.EventShifts.Add(s);
        await db.SaveChangesAsync(ct);
        return s;
    }

    /// <summary>Erzeugt mehrere Schichten in einem Schritt: alle <paramref name="durationHours"/>-Stunden-Slots zwischen Start und Ende.</summary>
    public async Task<int> GenerateShiftsAsync(Guid eventId, Guid? eventDayId, Guid? stationId, string titlePattern, DateTimeOffset blockStartUtc, DateTimeOffset blockEndUtc, double durationHours, int requiredPerSlot, CancellationToken ct = default)
    {
        if (durationHours <= 0) throw new ArgumentException("Dauer > 0", nameof(durationHours));
        if (blockEndUtc <= blockStartUtc) throw new ArgumentException("Ende vor Start");
        var step = TimeSpan.FromHours(durationHours);
        var count = 0;
        for (var s = blockStartUtc; s < blockEndUtc; s += step)
        {
            var e = s + step > blockEndUtc ? blockEndUtc : s + step;
            var label = titlePattern.Replace("{start}", s.ToLocalTime().ToString("HH:mm")).Replace("{end}", e.ToLocalTime().ToString("HH:mm"));
            db.EventShifts.Add(EventShift.Create(eventId, label, s, e, requiredPerSlot, stationId, eventDayId));
            count++;
        }
        await db.SaveChangesAsync(ct);
        return count;
    }

    public async Task DeleteShiftAsync(Guid shiftId, CancellationToken ct = default)
    {
        var s = await db.EventShifts.FirstOrDefaultAsync(x => x.Id == shiftId, ct);
        if (s is null) return;
        db.EventShifts.Remove(s);
        await db.SaveChangesAsync(ct);
    }

    public async Task<bool> ToggleAssignAsync(Guid shiftId, Guid userId, bool tentative = false, CancellationToken ct = default)
    {
        var existing = await db.ShiftAssignments.FirstOrDefaultAsync(x => x.ShiftId == shiftId && x.UserId == userId, ct);
        if (existing is null)
        {
            db.ShiftAssignments.Add(ShiftAssignment.Create(shiftId, userId, tentative));
            await db.SaveChangesAsync(ct);
            return true;
        }
        db.ShiftAssignments.Remove(existing);
        await db.SaveChangesAsync(ct);
        return false;
    }

    /* ───────── Bring-Listen ───────── */
    public async Task<List<ContributionView>> GetContributionsAsync(Guid eventId, CancellationToken ct = default)
    {
        var raw = await db.EventContributions.Where(c => c.EventId == eventId).Include(c => c.Pledges).ToListAsync(ct);
        var userIds = raw.SelectMany(c => c.Pledges.Select(p => p.UserId)).Distinct().ToList();
        var userMap = await db.Users.Where(u => userIds.Contains(u.Id))
            .Select(u => new { u.Id, u.DisplayName }).ToDictionaryAsync(u => u.Id, u => u.DisplayName, ct);
        return raw.OrderBy(c => c.Title)
            .Select(c => new ContributionView(c.Id, c.Title, c.Description, c.Unit, c.Wanted,
                c.Pledges.Sum(p => p.Quantity),
                c.Pledges.Select(p => new PledgeView(p.Id, p.UserId, userMap.GetValueOrDefault(p.UserId), p.Quantity, p.What)).ToList()))
            .ToList();
    }

    public async Task<EventContribution> AddContributionAsync(Guid eventId, string title, ContributionUnit unit, int? wanted, string? description, CancellationToken ct = default)
    {
        var c = EventContribution.Create(eventId, title, unit, wanted, description);
        db.EventContributions.Add(c);
        await db.SaveChangesAsync(ct);
        return c;
    }

    public async Task DeleteContributionAsync(Guid contributionId, CancellationToken ct = default)
    {
        var c = await db.EventContributions.FirstOrDefaultAsync(x => x.Id == contributionId, ct);
        if (c is null) return;
        db.EventContributions.Remove(c);
        await db.SaveChangesAsync(ct);
    }

    public async Task PledgeAsync(Guid contributionId, Guid userId, int quantity, string? what, CancellationToken ct = default)
    {
        var existing = await db.EventContributionPledges.FirstOrDefaultAsync(p => p.ContributionId == contributionId && p.UserId == userId, ct);
        if (quantity <= 0)
        {
            if (existing is not null) db.EventContributionPledges.Remove(existing);
        }
        else if (existing is null)
        {
            db.EventContributionPledges.Add(EventContributionPledge.Create(contributionId, userId, quantity, what));
        }
        else
        {
            existing.Update(quantity, what);
        }
        await db.SaveChangesAsync(ct);
    }
}
