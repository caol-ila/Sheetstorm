namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A registered user / musician in the system.
/// </summary>
public class Musiker : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiresAt { get; set; }

    public ICollection<Mitgliedschaft> Mitgliedschaften { get; set; } = [];
}
