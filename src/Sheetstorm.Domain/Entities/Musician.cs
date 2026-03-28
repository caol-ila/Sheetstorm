namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A registered user / musician in the system.
/// </summary>
public class Musician : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? Instrument { get; set; }
    public bool OnboardingCompleted { get; set; }

    // Email verification
    public bool EmailVerified { get; set; }
    public string? EmailVerificationToken { get; set; }
    public DateTime? EmailVerificationTokenExpiresAt { get; set; }

    // Password reset
    public string? PasswordResetToken { get; set; }
    public DateTime? PasswordResetTokenExpiresAt { get; set; }
    public DateTime? PasswordResetRequestedAt { get; set; }

    public ICollection<Membership> Membershipen { get; set; } = [];
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<UserInstrument> UserInstruments { get; set; } = [];
}
