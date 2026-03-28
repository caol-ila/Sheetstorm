namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A policy entry that can lock/force config settings at the Band level.
/// When enforced, Nutzer and Gerät overrides for the affected key are blocked.
/// </summary>
public class ConfigPolicy : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty; // JSON string

    public Guid? UpdatedById { get; set; }
    public Musician? UpdatedBy { get; set; }
}
