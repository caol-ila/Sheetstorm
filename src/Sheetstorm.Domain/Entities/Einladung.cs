namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An invitation code granting a Musiker access to a Kapelle with a predefined role.
/// </summary>
public class Einladung : BaseEntity
{
    public string Code { get; set; } = string.Empty;

    public Guid KapelleID { get; set; }
    public Kapelle Kapelle { get; set; } = null!;

    public MitgliedRolle VorgeseheRolle { get; set; } = MitgliedRolle.Musiker;

    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }

    public Guid ErstelltVonMusikerID { get; set; }
    public Musiker ErstelltVon { get; set; } = null!;

    public Guid? EingeloestVonMusikerID { get; set; }
    public Musiker? EingeloestVon { get; set; }
}
