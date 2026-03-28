namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A specific instrumental part (Stimme) for a piece.
/// </summary>
public class Stimme : BaseEntity
{
    public Guid StueckID { get; set; }
    public Stueck Stueck { get; set; } = null!;

    public string Bezeichnung { get; set; } = string.Empty;
    public string? Instrument { get; set; }

    public ICollection<Notenblatt> Notenblaetter { get; set; } = [];
}
