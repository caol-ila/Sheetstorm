namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A single page of an uploaded Stück document (for OCR and page-level storage).
/// </summary>
public class StueckSeite : BaseEntity
{
    public Guid StueckID { get; set; }
    public Stueck Stueck { get; set; } = null!;

    public int Seitennummer { get; set; }
    public string StorageKey { get; set; } = string.Empty;
    public string? OcrText { get; set; }
}
