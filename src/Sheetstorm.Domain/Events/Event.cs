using Sheetstorm.Domain.Music;

namespace Sheetstorm.Domain.Events;

public enum EventType
{
    Konzert = 0,
    Probe = 1,
    Arbeitseinsatz = 2,
    Sonstiges = 3,
}

public enum AttendanceStatus
{
    Unknown = 0,
    Yes = 1,
    No = 2,
    Maybe = 3,
}

public sealed class Event
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public EventType Type { get; private set; }
    public string Title { get; private set; } = default!;
    public string? Description { get; private set; }
    public string? Location { get; private set; }
    public DateTimeOffset StartUtc { get; private set; }
    public DateTimeOffset EndUtc { get; private set; }
    public DateTimeOffset? MeetUtc { get; private set; }
    public string? DressCode { get; private set; }
    public Guid? SetListId { get; private set; }
    public SetList? SetList { get; private set; }
    public Guid CreatedById { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public bool Cancelled { get; private set; }

    public ICollection<EventAttendance> Attendances { get; private set; } = new List<EventAttendance>();

    private Event() { }

    public static Event Create(Guid bandId, EventType type, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, Guid createdById, string? location = null)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        if (endUtc < startUtc) throw new ArgumentException("Ende vor Start", nameof(endUtc));
        return new Event
        {
            BandId = bandId,
            Type = type,
            Title = title.Trim(),
            StartUtc = startUtc,
            EndUtc = endUtc,
            CreatedById = createdById,
            Location = location,
        };
    }

    public void Update(string title, string? description, string? location, DateTimeOffset startUtc, DateTimeOffset endUtc, DateTimeOffset? meetUtc, string? dressCode, Guid? setListId)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        Title = title.Trim();
        Description = description;
        Location = location;
        StartUtc = startUtc;
        EndUtc = endUtc;
        MeetUtc = meetUtc;
        DressCode = dressCode;
        SetListId = setListId;
    }

    public void Cancel() => Cancelled = true;
    public void Reactivate() => Cancelled = false;
}

public sealed class EventAttendance
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public Event Event { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public AttendanceStatus Status { get; private set; }
    public string? Reason { get; private set; }
    public DateTimeOffset? RespondedAt { get; private set; }

    private EventAttendance() { }

    public static EventAttendance Create(Guid eventId, Guid userId, AttendanceStatus status, string? reason = null)
        => new()
        {
            EventId = eventId,
            UserId = userId,
            Status = status,
            Reason = reason,
            RespondedAt = DateTimeOffset.UtcNow,
        };

    public void UpdateStatus(AttendanceStatus status, string? reason)
    {
        Status = status;
        Reason = reason;
        RespondedAt = DateTimeOffset.UtcNow;
    }
}

public sealed class SetList
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public string Name { get; private set; } = default!;
    public string? Description { get; private set; }
    public Guid CreatedById { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;

    public ICollection<SetListItem> Items { get; private set; } = new List<SetListItem>();

    private SetList() { }

    public static SetList Create(Guid bandId, string name, Guid createdById)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name ist Pflicht", nameof(name));
        return new SetList { BandId = bandId, Name = name.Trim(), CreatedById = createdById };
    }
}

public sealed class SetListItem
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid SetListId { get; private set; }
    public Guid PieceId { get; private set; }
    public Piece Piece { get; private set; } = default!;
    public int Position { get; private set; }
    public string? TransitionNote { get; private set; }

    private SetListItem() { }

    public static SetListItem Create(Guid setListId, Guid pieceId, int position, string? transitionNote = null)
        => new() { SetListId = setListId, PieceId = pieceId, Position = position, TransitionNote = transitionNote };

    public void SetPosition(int p) => Position = p;
    public void SetNote(string? n) => TransitionNote = n;
}
