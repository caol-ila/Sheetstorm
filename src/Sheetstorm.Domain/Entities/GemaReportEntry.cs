namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A single work entry within a GEMA compliance report.
/// </summary>
public class GemaReportEntry : BaseEntity
{
    public Guid GemaReportId { get; set; }
    public GemaReport GemaReport { get; set; } = null!;

    public Guid? PieceId { get; set; }
    public Piece? Piece { get; set; }

    public string Composer { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Arranger { get; set; }
    public string? Publisher { get; set; }
    public int? DurationSeconds { get; set; }
    public string? WorkNumber { get; set; }
    public int Position { get; set; }
}
