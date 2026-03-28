namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A concrete PDF/image file for a Stimme.
/// </summary>
public class Notenblatt : BaseEntity
{
    public Guid StimmeID { get; set; }
    public Stimme Stimme { get; set; } = null!;

    public string BlobUrl { get; set; } = string.Empty;
    public string? ContentType { get; set; }
    public long? FileSizeBytes { get; set; }
}
