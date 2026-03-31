using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Pagination;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Pagination;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Events;

public class EventService(AppDbContext db, IBandAuthorizationService bandAuth) : IEventService
{
    public async Task<EventDto> CreateEventAsync(Guid bandId, CreateEventRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        if (request.EndDate.HasValue && request.EndDate < request.StartDate)
            throw new DomainException("VALIDATION_ERROR", "End date must be after start date.", 400);

        if (request.SetlistId.HasValue)
        {
            var setlist = await db.Set<Setlist>()
                .FirstOrDefaultAsync(s => s.Id == request.SetlistId.Value && s.BandId == bandId, ct);
            if (setlist == null)
                throw new DomainException("VALIDATION_ERROR", "Setlist does not belong to this band.", 400);
        }

        var ev = new Event
        {
            BandId = bandId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            EventType = request.EventType,
            Location = request.Location?.Trim(),
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            IsAllDay = request.IsAllDay,
            RepeatRule = request.RepeatRule,
            SetlistId = request.SetlistId,
            Notes = request.Notes?.Trim(),
            DressCode = request.DressCode?.Trim(),
            MeetingPoint = request.MeetingPoint?.Trim(),
            RsvpDeadline = request.RsvpDeadline,
            CreatedByMusicianId = musicianId
        };

        db.Set<Event>().Add(ev);

        // Create pending RSVPs for all active band members
        var members = await db.Memberships
            .Where(m => m.BandId == bandId && m.IsActive)
            .Select(m => m.MusicianId)
            .ToListAsync(ct);

        foreach (var memberId in members)
        {
            db.Set<EventRsvp>().Add(new EventRsvp
            {
                EventId = ev.Id,
                MusicianId = memberId,
                Status = RsvpStatus.Pending
            });
        }

        await db.SaveChangesAsync(ct);

        return await GetEventAsync(bandId, ev.Id, musicianId, ct);
    }

    public async Task<IReadOnlyList<EventDto>> GetEventsAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var events = await db.Set<Event>()
            .Where(e => e.BandId == bandId)
            .Include(e => e.CreatedByMusician)
            .Include(e => e.Rsvps)
            .OrderBy(e => e.StartDate)
            .ToListAsync(ct);

        return events.Select(MapToDto).ToList();
    }

    public async Task<PagedResult<EventDto>> GetEventsPaginatedAsync(
        Guid bandId, Guid musicianId, PaginationRequest pagination, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var pageSize = pagination.EffectivePageSize;

        var query = db.Set<Event>()
            .Where(e => e.BandId == bandId)
            .Include(e => e.CreatedByMusician)
            .Include(e => e.Rsvps);

        IQueryable<Event> filtered = query;

        if (pagination.Cursor is not null)
        {
            var (cursorDate, cursorId) = CursorHelper.Decode(pagination.Cursor);
            filtered = filtered.Where(e =>
                e.CreatedAt < cursorDate ||
                (e.CreatedAt == cursorDate && e.Id.CompareTo(cursorId) < 0));
        }

        return await filtered
            .OrderByDescending(e => e.CreatedAt)
            .ThenByDescending(e => e.Id)
            .ToPaginatedAsync(
                pageSize,
                MapToDto,
                e => e.CreatedAt,
                e => e.Id,
                ct);
    }

    public async Task<EventDto> GetEventAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .Include(e => e.CreatedByMusician)
            .Include(e => e.Rsvps)
            .FirstOrDefaultAsync(e => e.Id == eventId && e.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Event not found.", 404);

        return MapToDto(ev);
    }

    public async Task<EventDto> UpdateEventAsync(Guid bandId, Guid eventId, UpdateEventRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .FirstOrDefaultAsync(e => e.Id == eventId && e.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Event not found.", 404);

        if (request.EndDate.HasValue && request.EndDate < request.StartDate)
            throw new DomainException("VALIDATION_ERROR", "End date must be after start date.", 400);

        if (request.SetlistId.HasValue)
        {
            var setlist = await db.Set<Setlist>()
                .FirstOrDefaultAsync(s => s.Id == request.SetlistId.Value && s.BandId == bandId, ct);
            if (setlist == null)
                throw new DomainException("VALIDATION_ERROR", "Setlist does not belong to this band.", 400);
        }

        ev.Title = request.Title.Trim();
        ev.Description = request.Description?.Trim();
        ev.EventType = request.EventType;
        ev.Location = request.Location?.Trim();
        ev.StartDate = request.StartDate;
        ev.EndDate = request.EndDate;
        ev.IsAllDay = request.IsAllDay;
        ev.RepeatRule = request.RepeatRule;
        ev.SetlistId = request.SetlistId;
        ev.Notes = request.Notes?.Trim();
        ev.DressCode = request.DressCode?.Trim();
        ev.MeetingPoint = request.MeetingPoint?.Trim();
        ev.RsvpDeadline = request.RsvpDeadline;

        await db.SaveChangesAsync(ct);

        return await GetEventAsync(bandId, eventId, musicianId, ct);
    }

    public async Task DeleteEventAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .FirstOrDefaultAsync(e => e.Id == eventId && e.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Event not found.", 404);

        db.Set<Event>().Remove(ev);
        await db.SaveChangesAsync(ct);
    }

    public async Task<EventRsvpDto> SetRsvpAsync(Guid bandId, Guid eventId, SetRsvpRequest request, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .AnyAsync(e => e.Id == eventId && e.BandId == bandId, ct);
        if (!ev)
            throw new DomainException("NOT_FOUND", "Event not found.", 404);

        var rsvp = await db.Set<EventRsvp>()
            .Include(r => r.Musician)
            .FirstOrDefaultAsync(r => r.EventId == eventId && r.MusicianId == musicianId, ct);

        if (rsvp == null)
        {
            rsvp = new EventRsvp
            {
                EventId = eventId,
                MusicianId = musicianId,
                Status = request.Status,
                Comment = request.Comment?.Trim(),
                RespondedAt = DateTime.UtcNow
            };
            db.Set<EventRsvp>().Add(rsvp);
        }
        else
        {
            rsvp.Status = request.Status;
            rsvp.Comment = request.Comment?.Trim();
            rsvp.RespondedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync(ct);

        // Reload with navigation
        rsvp = await db.Set<EventRsvp>()
            .Include(r => r.Musician)
            .FirstAsync(r => r.Id == rsvp.Id, ct);

        return MapRsvpToDto(rsvp);
    }

    public async Task<IReadOnlyList<EventRsvpDto>> GetRsvpsAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .AnyAsync(e => e.Id == eventId && e.BandId == bandId, ct);
        if (!ev)
            throw new DomainException("NOT_FOUND", "Event not found.", 404);

        var rsvps = await db.Set<EventRsvp>()
            .Where(r => r.EventId == eventId)
            .Include(r => r.Musician)
            .OrderBy(r => r.Musician.Name)
            .ToListAsync(ct);

        return rsvps.Select(MapRsvpToDto).ToList();
    }

    public async Task<IReadOnlyList<SubstituteSuggestionDto>> GetSubstituteSuggestionsAsync(
        Guid bandId, Guid eventId, Guid declinedMusicianId, Guid musicianId, CancellationToken ct)
    {
        await bandAuth.RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var ev = await db.Set<Event>()
            .AnyAsync(e => e.Id == eventId && e.BandId == bandId, ct);
        if (!ev)
            throw new DomainException("NOT_FOUND", "Event not found.", 404);

        var declinedMusician = await db.Musicians
            .FirstOrDefaultAsync(m => m.Id == declinedMusicianId, ct)
            ?? throw new DomainException("NOT_FOUND", "Musician not found.", 404);

        // Get all active members who haven't declined this event
        var rsvps = await db.Set<EventRsvp>()
            .Where(r => r.EventId == eventId)
            .ToDictionaryAsync(r => r.MusicianId, r => r.Status, ct);

        var members = await db.Memberships
            .Where(m => m.BandId == bandId && m.IsActive && m.MusicianId != declinedMusicianId)
            .Include(m => m.Musician)
            .ToListAsync(ct);

        var suggestions = new List<SubstituteSuggestionDto>();

        foreach (var member in members)
        {
            var status = rsvps.GetValueOrDefault(member.MusicianId, RsvpStatus.Pending);
            if (status == RsvpStatus.Declined) continue;

            var score = 0;
            var reason = "";

            // Same instrument = highest match
            if (member.Musician.Instrument != null &&
                declinedMusician.Instrument != null &&
                member.Musician.Instrument.Equals(declinedMusician.Instrument, StringComparison.OrdinalIgnoreCase))
            {
                score += 100;
                reason = "Same instrument";
            }
            else
            {
                score += 50;
                reason = "Available member";
            }

            // Already accepted = bonus
            if (status == RsvpStatus.Accepted)
            {
                score += 50;
                reason += ", already accepted";
            }
            else if (status == RsvpStatus.Pending)
            {
                score += 25;
                reason += ", no response yet";
            }

            suggestions.Add(new SubstituteSuggestionDto(
                member.MusicianId,
                member.Musician.Name,
                member.Musician.Instrument,
                status,
                score,
                reason
            ));
        }

        return suggestions.OrderByDescending(s => s.MatchScore).ToList();
    }

    public async Task<IReadOnlyList<CalendarEventDto>> GetCalendarEventsAsync(
        Guid musicianId, DateTime? from, DateTime? to, CancellationToken ct)
    {
        var fromDate = from ?? DateTime.UtcNow.AddMonths(-1);
        var toDate = to ?? DateTime.UtcNow.AddMonths(3);

        var bandIds = await db.Memberships
            .Where(m => m.MusicianId == musicianId && m.IsActive)
            .Select(m => m.BandId)
            .ToListAsync(ct);

        var events = await db.Set<Event>()
            .Where(e => bandIds.Contains(e.BandId) && e.StartDate >= fromDate && e.StartDate <= toDate)
            .Include(e => e.Band)
            .Include(e => e.Rsvps)
            .OrderBy(e => e.StartDate)
            .ToListAsync(ct);

        return events.Select(e => MapToCalendarDto(e, musicianId)).ToList();
    }

    public async Task<IReadOnlyList<CalendarEventDto>> GetBandCalendarEventsAsync(
        Guid bandId, Guid musicianId, DateTime? from, DateTime? to, CancellationToken ct)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId, ct);

        var fromDate = from ?? DateTime.UtcNow.AddMonths(-1);
        var toDate = to ?? DateTime.UtcNow.AddMonths(3);

        var events = await db.Set<Event>()
            .Where(e => e.BandId == bandId && e.StartDate >= fromDate && e.StartDate <= toDate)
            .Include(e => e.Band)
            .Include(e => e.Rsvps)
            .OrderBy(e => e.StartDate)
            .ToListAsync(ct);

        return events.Select(e => MapToCalendarDto(e, musicianId)).ToList();
    }

    // ── Private Helpers ──────────────────────────────────────────────────────

    private static EventDto MapToDto(Event ev) => new(
        ev.Id,
        ev.BandId,
        ev.Title,
        ev.Description,
        ev.EventType,
        ev.Location,
        ev.StartDate,
        ev.EndDate,
        ev.IsAllDay,
        ev.RepeatRule,
        ev.SetlistId,
        ev.Notes,
        ev.DressCode,
        ev.MeetingPoint,
        ev.RsvpDeadline,
        ev.CreatedByMusicianId,
        ev.CreatedByMusician.Name,
        new RsvpStatsDto(
            ev.Rsvps.Count(r => r.Status == RsvpStatus.Accepted),
            ev.Rsvps.Count(r => r.Status == RsvpStatus.Declined),
            ev.Rsvps.Count(r => r.Status == RsvpStatus.Tentative),
            ev.Rsvps.Count(r => r.Status == RsvpStatus.Pending)
        ),
        ev.CreatedAt
    );

    private static EventRsvpDto MapRsvpToDto(EventRsvp rsvp) => new(
        rsvp.Id,
        rsvp.EventId,
        rsvp.MusicianId,
        rsvp.Musician.Name,
        rsvp.Musician.Instrument,
        rsvp.Status,
        rsvp.Comment,
        rsvp.RespondedAt
    );

    private static CalendarEventDto MapToCalendarDto(Event ev, Guid musicianId)
    {
        var myRsvp = ev.Rsvps.FirstOrDefault(r => r.MusicianId == musicianId);
        return new CalendarEventDto(
            ev.Id,
            ev.Title,
            ev.EventType,
            ev.StartDate,
            ev.EndDate,
            ev.Location,
            myRsvp?.Status ?? RsvpStatus.Pending,
            ev.BandId,
            ev.Band.Name,
            ev.SetlistId
        );
    }

}
