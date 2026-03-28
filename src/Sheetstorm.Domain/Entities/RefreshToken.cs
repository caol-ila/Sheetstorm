namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Refresh token with rotation and reuse-detection support.
/// Each token belongs to a family; reuse of a spent token revokes the entire family.
/// </summary>
public class RefreshToken : BaseEntity
{
    public string Token { get; set; } = string.Empty;

    /// <summary>Family ID groups tokens from the same refresh chain for reuse detection.</summary>
    public Guid FamilyId { get; set; } = Guid.NewGuid();

    public bool IsUsed { get; set; }
    public bool IsRevoked { get; set; }
    public DateTime ExpiresAt { get; set; }

    public Guid MusikerId { get; set; }
    public Musiker Musiker { get; set; } = null!;
}
