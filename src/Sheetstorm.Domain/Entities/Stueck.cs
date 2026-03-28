namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A musical piece in the library. Belongs to a Kapelle (or personal collection when KapelleID is null).
/// </summary>
public class Stueck : BaseEntity
{
    public Guid? KapelleID { get; set; }
    public Kapelle? Kapelle { get; set; }

    /// <summary>Owner for personal pieces (KapelleID = null).</summary>
    public Guid? MusikerID { get; set; }
    public Musiker? Musiker { get; set; }

    public string Titel { get; set; } = string.Empty;
    public string? Komponist { get; set; }
    public string? Arrangeur { get; set; }
    public int? VeroeffentlichungsJahr { get; set; }

    public ICollection<Stimme> Stimmen { get; set; } = [];
}
