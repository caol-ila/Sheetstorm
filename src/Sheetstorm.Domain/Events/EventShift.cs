namespace Sheetstorm.Domain.Events;

public sealed class EventShift
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public Event Event { get; private set; } = default!;
    public Guid? EventDayId { get; private set; }
    public Guid? StationId { get; private set; }
    public string Title { get; private set; } = default!;
    public DateTimeOffset StartUtc { get; private set; }
    public DateTimeOffset EndUtc { get; private set; }
    public int RequiredCount { get; private set; }
    public string? Notes { get; private set; }
    public ICollection<ShiftAssignment> Assignments { get; private set; } = new List<ShiftAssignment>();

    private EventShift() { }

    public static EventShift Create(Guid eventId, string title, DateTimeOffset startUtc, DateTimeOffset endUtc, int requiredCount, Guid? stationId = null, Guid? eventDayId = null, string? notes = null)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht");
        return new EventShift
        {
            EventId = eventId,
            EventDayId = eventDayId,
            StationId = stationId,
            Title = title.Trim(),
            StartUtc = startUtc,
            EndUtc = endUtc,
            RequiredCount = Math.Max(0, requiredCount),
            Notes = notes,
        };
    }

    public void Update(string title, DateTimeOffset startUtc, DateTimeOffset endUtc, int requiredCount, Guid? stationId, Guid? eventDayId, string? notes)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht");
        Title = title.Trim();
        StartUtc = startUtc;
        EndUtc = endUtc;
        RequiredCount = Math.Max(0, requiredCount);
        StationId = stationId;
        EventDayId = eventDayId;
        Notes = notes;
    }
}

public sealed class ShiftAssignment
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid ShiftId { get; private set; }
    public EventShift Shift { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public DateTimeOffset AssignedAt { get; private set; } = DateTimeOffset.UtcNow;
    public bool IsTentative { get; private set; }

    private ShiftAssignment() { }

    public static ShiftAssignment Create(Guid shiftId, Guid userId, bool isTentative = false)
        => new() { ShiftId = shiftId, UserId = userId, IsTentative = isTentative };

    public void SetTentative(bool isTentative) => IsTentative = isTentative;
}

public sealed class EventDay
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public DateOnly Date { get; private set; }
    public string? Theme { get; private set; }
    public TimeOnly? OpenAt { get; private set; }
    public TimeOnly? CloseAt { get; private set; }

    private EventDay() { }

    public static EventDay Create(Guid eventId, DateOnly date, string? theme = null, TimeOnly? openAt = null, TimeOnly? closeAt = null)
        => new() { EventId = eventId, Date = date, Theme = theme, OpenAt = openAt, CloseAt = closeAt };

    public void Update(DateOnly date, string? theme, TimeOnly? openAt, TimeOnly? closeAt)
    {
        Date = date; Theme = theme; OpenAt = openAt; CloseAt = closeAt;
    }
}

public sealed class EventStation
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public string Name { get; private set; } = default!;
    public string? Description { get; private set; }
    public string? IconKey { get; private set; }

    private EventStation() { }

    public static EventStation Create(Guid eventId, string name, string? description = null, string? iconKey = null)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Name ist Pflicht", nameof(name));
        return new EventStation { EventId = eventId, Name = name.Trim(), Description = description, IconKey = iconKey };
    }
}

public enum ContributionUnit { Item = 0, Liter = 1, Piece = 2, Other = 3 }

public sealed class EventContribution
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid EventId { get; private set; }
    public string Title { get; private set; } = default!;
    public string? Description { get; private set; }
    public ContributionUnit Unit { get; private set; }
    public int? Wanted { get; private set; }
    public ICollection<EventContributionPledge> Pledges { get; private set; } = new List<EventContributionPledge>();

    private EventContribution() { }

    public static EventContribution Create(Guid eventId, string title, ContributionUnit unit, int? wanted = null, string? description = null)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        return new EventContribution { EventId = eventId, Title = title.Trim(), Unit = unit, Wanted = wanted, Description = description };
    }
}

public sealed class EventContributionPledge
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid ContributionId { get; private set; }
    public EventContribution Contribution { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public string? What { get; private set; }
    public int Quantity { get; private set; }
    public DateTimeOffset PledgedAt { get; private set; } = DateTimeOffset.UtcNow;

    private EventContributionPledge() { }

    public static EventContributionPledge Create(Guid contributionId, Guid userId, int quantity, string? what = null)
        => new()
        {
            ContributionId = contributionId,
            UserId = userId,
            Quantity = Math.Max(0, quantity),
            What = what,
        };

    public void Update(int quantity, string? what)
    {
        Quantity = Math.Max(0, quantity);
        What = what;
    }
}

public enum PollKind
{
    DateFinder = 0,
    Vote = 1,
    DemandSurvey = 2,
}

public enum PollAnswer
{
    No = 0,
    Maybe = 1,
    Yes = 2,
}

public sealed class EventPoll
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid? EventId { get; private set; }
    public Guid? BandId { get; private set; }
    public PollKind Kind { get; private set; }
    public string Title { get; private set; } = default!;
    public string? Description { get; private set; }
    public DateTimeOffset? ClosesAt { get; private set; }
    public Guid CreatedByUserId { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public bool AllowMultiple { get; private set; }
    public bool AnonymousResults { get; private set; }
    public ICollection<PollOption> Options { get; private set; } = new List<PollOption>();
    public ICollection<PollResponse> Responses { get; private set; } = new List<PollResponse>();

    private EventPoll() { }

    public static EventPoll Create(PollKind kind, string title, Guid createdByUserId, Guid? eventId = null, Guid? bandId = null, string? description = null, DateTimeOffset? closesAt = null, bool allowMultiple = false, bool anonymousResults = false)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Titel ist Pflicht", nameof(title));
        if (eventId is null && bandId is null) throw new ArgumentException("Poll braucht entweder Event- oder Band-Kontext");
        return new EventPoll
        {
            Kind = kind,
            Title = title.Trim(),
            EventId = eventId,
            BandId = bandId,
            CreatedByUserId = createdByUserId,
            Description = description,
            ClosesAt = closesAt,
            AllowMultiple = allowMultiple,
            AnonymousResults = anonymousResults,
        };
    }

    public bool IsClosed => ClosesAt.HasValue && ClosesAt.Value < DateTimeOffset.UtcNow;
}

public sealed class PollOption
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PollId { get; private set; }
    public EventPoll Poll { get; private set; } = default!;
    public string Label { get; private set; } = default!;
    public DateTimeOffset? AsDateTime { get; private set; }
    public int Order { get; private set; }

    private PollOption() { }

    public static PollOption Create(Guid pollId, string label, int order, DateTimeOffset? asDateTime = null)
    {
        if (string.IsNullOrWhiteSpace(label)) throw new ArgumentException("Label ist Pflicht", nameof(label));
        return new PollOption { PollId = pollId, Label = label.Trim(), Order = order, AsDateTime = asDateTime };
    }

    public void Update(string label, int order, DateTimeOffset? asDateTime)
    {
        Label = label.Trim(); Order = order; AsDateTime = asDateTime;
    }
}

public sealed class PollResponse
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid PollId { get; private set; }
    public EventPoll Poll { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public Guid? OptionId { get; private set; }
    public PollOption? Option { get; private set; }
    public PollAnswer Answer { get; private set; }
    public string? FreeTextAnswer { get; private set; }
    public string? Size { get; private set; }
    public int? Quantity { get; private set; }
    public DateTimeOffset RespondedAt { get; private set; } = DateTimeOffset.UtcNow;

    private PollResponse() { }

    public static PollResponse Create(Guid pollId, Guid userId, Guid? optionId = null, PollAnswer answer = PollAnswer.Yes, string? freeTextAnswer = null, string? size = null, int? quantity = null)
        => new()
        {
            PollId = pollId,
            UserId = userId,
            OptionId = optionId,
            Answer = answer,
            FreeTextAnswer = freeTextAnswer,
            Size = size,
            Quantity = quantity,
        };

    public void Update(PollAnswer answer, string? freeTextAnswer, string? size, int? quantity)
    {
        Answer = answer;
        FreeTextAnswer = freeTextAnswer;
        Size = size;
        Quantity = quantity;
        RespondedAt = DateTimeOffset.UtcNow;
    }
}
