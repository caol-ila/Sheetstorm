namespace Sheetstorm.Domain.Identity;

public sealed class BandInvitation
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public Band Band { get; private set; } = default!;
    public string Email { get; private set; } = default!;
    public string TokenHash { get; private set; } = default!;
    public DateTimeOffset ExpiresAt { get; private set; }
    public BandRole RolesToGrant { get; private set; }
    public Guid CreatedById { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? AcceptedAt { get; private set; }
    public Guid? AcceptedById { get; private set; }

    private BandInvitation() { }

    public static BandInvitation Create(Guid bandId, string email, string tokenHash, DateTimeOffset expiresAt, BandRole rolesToGrant, Guid createdById)
        => new()
        {
            BandId = bandId,
            Email = email.Trim().ToLowerInvariant(),
            TokenHash = tokenHash,
            ExpiresAt = expiresAt,
            RolesToGrant = rolesToGrant == BandRole.None ? BandRole.Mitglied : rolesToGrant,
            CreatedById = createdById,
        };

    public bool IsValidNow(DateTimeOffset now) => AcceptedAt is null && ExpiresAt > now;

    public void MarkAccepted(Guid byUserId, DateTimeOffset at)
    {
        AcceptedAt = at;
        AcceptedById = byUserId;
    }
}

public sealed class BandJoinCode
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public Band Band { get; private set; } = default!;
    public string CodeHash { get; private set; } = default!;
    public int? MaxUses { get; private set; }
    public int UsesCount { get; private set; }
    public DateTimeOffset? ExpiresAt { get; private set; }
    public Guid CreatedById { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; } = DateTimeOffset.UtcNow;
    public bool Active { get; private set; } = true;

    private BandJoinCode() { }

    public static BandJoinCode Create(Guid bandId, string codeHash, Guid createdById, int? maxUses = null, DateTimeOffset? expiresAt = null)
        => new()
        {
            BandId = bandId,
            CodeHash = codeHash,
            CreatedById = createdById,
            MaxUses = maxUses,
            ExpiresAt = expiresAt,
        };

    public bool IsUsable(DateTimeOffset now)
        => Active
        && (ExpiresAt is null || ExpiresAt > now)
        && (MaxUses is null || UsesCount < MaxUses);

    public void RegisterUse()
    {
        UsesCount++;
        if (MaxUses is not null && UsesCount >= MaxUses) Active = false;
    }

    public void Deactivate() => Active = false;
}

/// <summary>
/// Pending Beitrittsanfrage über JoinCode — wartet auf Admin-Approval.
/// </summary>
public sealed class BandJoinRequest
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid BandId { get; private set; }
    public Band Band { get; private set; } = default!;
    public Guid UserId { get; private set; }
    public Guid JoinCodeId { get; private set; }
    public DateTimeOffset RequestedAt { get; private set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? DecidedAt { get; private set; }
    public Guid? DecidedById { get; private set; }
    public bool? Approved { get; private set; }

    private BandJoinRequest() { }

    public static BandJoinRequest Create(Guid bandId, Guid userId, Guid joinCodeId)
        => new() { BandId = bandId, UserId = userId, JoinCodeId = joinCodeId };

    public void Decide(bool approved, Guid byUserId, DateTimeOffset at)
    {
        Approved = approved;
        DecidedById = byUserId;
        DecidedAt = at;
    }
}
