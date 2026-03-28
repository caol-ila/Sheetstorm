namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A concrete PDF/image file for a Voice.
/// </summary>
public class SheetMusic : BaseEntity
{
    public Guid VoiceId { get; set; }
    public Voice Voice { get; set; } = null!;

    public string BlobUrl { get; set; } = string.Empty;
    public string? ContentType { get; set; }
    public long? FileSizeBytes { get; set; }
}
