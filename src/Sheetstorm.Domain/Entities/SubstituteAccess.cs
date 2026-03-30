namespace Sheetstorm.Domain.Entities;

/// <summary>
/// Temporary access token for a substitute musician to view sheet music for a specific event.
/// The Token field stores the SHA-256 hash — the raw token is returned only once at creation.
/// </summary>
public class SubstituteAccess : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    /// <summary>SHA-256 hash of the access token. Raw token is never stored.</summary>
    public string Token { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
    public string? Email { get; set; }

    public Guid? VoiceId { get; set; }
    public Voice? Voice { get; set; }

    public Guid? EventId { get; set; }
    public Event? Event { get; set; }

    public Guid GrantedByMusicianId { get; set; }
    public Musician GrantedByMusician { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastAccessedAt { get; set; }

    public string? Instrument { get; set; }
    public string? Note { get; set; }
}
