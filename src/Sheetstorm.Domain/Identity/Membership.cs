namespace Sheetstorm.Domain.Identity;

public sealed class Membership
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public Band Band { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public BandRole Roles { get; private set; }
    public MembershipStatus Status { get; private set; }
    public DateTimeOffset? JoinedAt { get; private set; }

    public ICollection<MembershipInstrument> Instruments { get; private set; } = new List<MembershipInstrument>();

    private Membership() { }

    public static Membership Create(Guid bandId, Guid userId, BandRole roles, MembershipStatus status = MembershipStatus.Active)
    {
        return new Membership
        {
            BandId = bandId,
            UserId = userId,
            Roles = roles == BandRole.None ? BandRole.Mitglied : roles,
            Status = status,
            JoinedAt = status == MembershipStatus.Active ? DateTimeOffset.UtcNow : null,
        };
    }

    public bool HasRole(BandRole role) => (Roles & role) == role;
    public void GrantRole(BandRole role) => Roles |= role;
    public void RevokeRole(BandRole role) => Roles &= ~role;

    public void Activate()
    {
        if (Status != MembershipStatus.Active)
        {
            Status = MembershipStatus.Active;
            JoinedAt ??= DateTimeOffset.UtcNow;
        }
    }

    public void Suspend() => Status = MembershipStatus.Suspended;
}

public sealed class MembershipInstrument
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid MembershipId { get; private set; }
    public Guid InstrumentId { get; private set; }
    public Instrument Instrument { get; private set; } = default!;
    public string? Transposition { get; private set; }
    public int RegisterPreference { get; private set; }
    public bool IsPrimary { get; private set; }

    private MembershipInstrument() { }

    public static MembershipInstrument Create(Guid membershipId, Guid instrumentId, string? transposition, int registerPreference, bool isPrimary)
        => new()
        {
            MembershipId = membershipId,
            InstrumentId = instrumentId,
            Transposition = transposition,
            RegisterPreference = registerPreference,
            IsPrimary = isPrimary,
        };

    public void SetPrimary(bool isPrimary) => IsPrimary = isPrimary;
}

public sealed class Instrument
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public InstrumentFamily Family { get; private set; }
    public string Name { get; private set; } = default!;
    public string? DefaultTransposition { get; private set; }

    private Instrument() { }

    public static Instrument Create(InstrumentFamily family, string name, string? defaultTransposition = null)
        => new() { Family = family, Name = name, DefaultTransposition = defaultTransposition };

    public static Instrument CreateWithId(Guid id, InstrumentFamily family, string name, string? defaultTransposition = null)
        => new() { Id = id, Family = family, Name = name, DefaultTransposition = defaultTransposition };
}
