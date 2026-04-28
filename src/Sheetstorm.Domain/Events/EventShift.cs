namespace Sheetstorm.Domain.Events;

public sealed class EventShift
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public Event Event { get; private set; } = default!;
    public string Title { get; private set; } = default!;
    public DateTimeOffset StartUtc { get; private set; }
    public DateTimeOffset EndUtc { get; private set; }
    public int RequiredCount { get; private set; }
    public ICollection<ShiftAssignment> Assignments { get; private set; } = new List<ShiftAssignment>();

    private EventShift() { }

    public static EventShift Create(Guid eventId, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, int requiredCount)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht");
        return new EventShift { EventId = eventId, Title = title.Trim(), StartUtc = startUtc, EndUtc = endUtc, RequiredCount = Math.Max(0, requiredCount) };
    }
}

public sealed class ShiftAssignment
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid ShiftId { get; private set; }
    public EventShift Shift { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public DateTimeOffset AssignedAt { get; private set; } = DateTimeOffset.UtcNow;

    private ShiftAssignment() { }

    public static ShiftAssignment Create(Guid shiftId, Guid userId)
        => new() { ShiftId = shiftId, UserId = userId };
}
