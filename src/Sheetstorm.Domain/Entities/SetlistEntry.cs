namespace Sheetstorm.Domain.Entities;

/// <summary>
/// An entry in a setlist, can reference a piece or be a placeholder.
/// </summary>
public class SetlistEntry : BaseEntity
{
    public Guid SetlistId { get; set; }
    public Setlist Setlist { get; set; } = null!;

    public Guid? PieceId { get; set; }
    public Piece? Piece { get; set; }

    public int Position { get; set; }
    public bool IsPlaceholder { get; set; }
    
    public string? PlaceholderTitle { get; set; }
    public string? PlaceholderComposer { get; set; }
    public string? Notes { get; set; }
    public int? DurationSeconds { get; set; }
}
