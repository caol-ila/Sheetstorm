namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A single page of an uploaded Stück document (for OCR and page-level storage).
/// </summary>
public class PiecePage : BaseEntity
{
    public Guid PieceId { get; set; }
    public Piece Piece { get; set; } = null!;

    public int PageNumber { get; set; }
    public string StorageKey { get; set; } = string.Empty;
    public string? OcrText { get; set; }
}
