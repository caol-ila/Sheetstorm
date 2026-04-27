using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Events;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Web.Application;

public sealed record EventListItem(Guid Id, EventType Type, string Title, DateTimeOffset StartUtc, DateTimeOffset EndUtc, string? Location, Guid? SetListId, AttendanceStatus MyStatus, int YesCount, int NoCount, int MaybeCount);

public sealed class EventService(SheetstormDbContext db)
{
    public async Task<List<EventListItem>> GetUpcomingAsync(Guid bandId, Guid currentUserId, CancellationToken ct = default)
    {
        var now = DateTimeOffset.UtcNow.AddHours(-12);
        var rows = await db.Events
            .Where(e => e.BandId == bandId && e.StartUtc >= now && !e.Cancelled)
            .OrderBy(e => e.StartUtc)
            .Select(e => new EventListItem(
                e.Id, e.Type, e.Title, e.StartUtc, e.EndUtc, e.Location, e.SetListId,
                e.Attendances.Where(a => a.UserId == currentUserId).Select(a => a.Status).FirstOrDefault(),
                e.Attendances.Count(a => a.Status == AttendanceStatus.Yes),
                e.Attendances.Count(a => a.Status == AttendanceStatus.No),
                e.Attendances.Count(a => a.Status == AttendanceStatus.Maybe)
            ))
            .ToListAsync(ct);
        return rows;
    }

    public async Task<Event?> GetAsync(Guid id, CancellationToken ct = default)
        => await db.Events
            .Include(e => e.Attendances)
            .Include(e => e.SetList)
                .ThenInclude(s => s!.Items)
                    .ThenInclude(i => i.Piece)
            .FirstOrDefaultAsync(e => e.Id == id, ct);

    public async Task<Event> CreateAsync(Guid bandId, EventType type, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, Guid createdById, string? location, Guid? setListId, CancellationToken ct = default)
    {
        var ev = Event.Create(bandId, type, title, startUtc, endUtc, createdById, location);
        if (setListId is not null) ev.Update(title, null, location, startUtc, endUtc, null, null, setListId);
        db.Events.Add(ev);
        await db.SaveChangesAsync(ct);
        return ev;
    }

    public async Task RespondAsync(Guid eventId, Guid userId, AttendanceStatus status, string? reason, CancellationToken ct = default)
    {
        var existing = await db.EventAttendances.FirstOrDefaultAsync(a => a.EventId == eventId && a.UserId == userId, ct);
        if (existing is null)
        {
            db.EventAttendances.Add(EventAttendance.Create(eventId, userId, status, reason));
        }
        else
        {
            existing.UpdateStatus(status, reason);
        }
        await db.SaveChangesAsync(ct);
    }
}

public sealed record SetListSummary(Guid Id, string Name, int ItemCount);

public sealed class SetListService(SheetstormDbContext db)
{
    public async Task<List<SetListSummary>> GetForBandAsync(Guid bandId, CancellationToken ct = default)
        => await db.SetLists
            .Where(s => s.BandId == bandId)
            .OrderBy(s => s.Name)
            .Select(s => new SetListSummary(s.Id, s.Name, s.Items.Count))
            .ToListAsync(ct);

    public async Task<SetList?> GetAsync(Guid id, CancellationToken ct = default)
        => await db.SetLists
            .Include(s => s.Items.OrderBy(i => i.Position))
                .ThenInclude(i => i.Piece)
            .FirstOrDefaultAsync(s => s.Id == id, ct);

    public async Task<SetList> CreateAsync(Guid bandId, string name, Guid createdById, CancellationToken ct = default)
    {
        var s = SetList.Create(bandId, name, createdById);
        db.SetLists.Add(s);
        await db.SaveChangesAsync(ct);
        return s;
    }

    public async Task AddPieceAsync(Guid setListId, Guid pieceId, CancellationToken ct = default)
    {
        var maxPos = await db.SetListItems.Where(i => i.SetListId == setListId).Select(i => (int?)i.Position).MaxAsync(ct) ?? 0;
        db.SetListItems.Add(SetListItem.Create(setListId, pieceId, maxPos + 1));
        await db.SaveChangesAsync(ct);
    }

    public async Task RemoveItemAsync(Guid itemId, CancellationToken ct = default)
    {
        var item = await db.SetListItems.FirstOrDefaultAsync(i => i.Id == itemId, ct);
        if (item is null) return;
        db.SetListItems.Remove(item);
        await db.SaveChangesAsync(ct);
    }
}
