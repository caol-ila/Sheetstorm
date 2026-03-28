using Sheetstorm.Domain.Events;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Infrastructure.Events;

public interface IEventService
{
    // Events CRUD
    Task<EventDto> CreateEventAsync(Guid bandId, CreateEventRequest request, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<EventDto>> GetEventsAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<EventDto> GetEventAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct);
    Task<EventDto> UpdateEventAsync(Guid bandId, Guid eventId, UpdateEventRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteEventAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct);

    // RSVP
    Task<EventRsvpDto> SetRsvpAsync(Guid bandId, Guid eventId, SetRsvpRequest request, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<EventRsvpDto>> GetRsvpsAsync(Guid bandId, Guid eventId, Guid musicianId, CancellationToken ct);

    // Substitute suggestions
    Task<IReadOnlyList<SubstituteSuggestionDto>> GetSubstituteSuggestionsAsync(Guid bandId, Guid eventId, Guid declinedMusicianId, Guid musicianId, CancellationToken ct);

    // Calendar
    Task<IReadOnlyList<CalendarEventDto>> GetCalendarEventsAsync(Guid musicianId, DateTime? from, DateTime? to, CancellationToken ct);
    Task<IReadOnlyList<CalendarEventDto>> GetBandCalendarEventsAsync(Guid bandId, Guid musicianId, DateTime? from, DateTime? to, CancellationToken ct);
}
