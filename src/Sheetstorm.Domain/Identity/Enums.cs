namespace Sheetstorm.Domain.Identity;

/// <summary>
/// Vereinsrolle. Mehrere Rollen pro Mitgliedschaft sind möglich (Flags).
/// </summary>
[Flags]
public enum BandRole
{
    None = 0,
    Mitglied = 1 << 0,
    Dirigent = 1 << 1,
    Lehrer = 1 << 2,
    Admin = 1 << 3,
    Owner = 1 << 4,
}

public enum MembershipStatus
{
    Pending = 0,
    Active = 1,
    Suspended = 2,
}

public enum InstrumentFamily
{
    Holz = 0,
    Blech = 1,
    Schlagwerk = 2,
    Sonstige = 3,
}
