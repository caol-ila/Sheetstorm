using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Entities;

/// <summary>
/// A GEMA compliance report for a band's performance, generated from a setlist.
/// </summary>
public class GemaReport : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public Guid? EventId { get; set; }
    public Event? Event { get; set; }

    public DateTime ReportDate { get; set; }
    public GemaReportStatus Status { get; set; } = GemaReportStatus.Draft;

    public Guid GeneratedByMusicianId { get; set; }
    public Musician GeneratedByMusician { get; set; } = null!;

    public string? ExportFormat { get; set; }

    public string? EventLocation { get; set; }
    public string? EventCategory { get; set; }
    public string? Organizer { get; set; }

    public Guid? SetlistId { get; set; }
    public Setlist? Setlist { get; set; }

    public DateTime? ExportedAt { get; set; }

    public ICollection<GemaReportEntry> Entries { get; set; } = [];
}
