using Sheetstorm.Domain.Gema;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Infrastructure.Gema;

public interface IGemaService
{
    Task<GemaReportDto> CreateReportAsync(Guid bandId, CreateGemaReportRequest request, Guid musicianId, CancellationToken ct);
    Task<GemaReportDto> GetReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<GemaReportSummaryDto>> GetReportsAsync(Guid bandId, Guid musicianId, GemaReportStatus? status, CancellationToken ct);
    Task<GemaReportDto> UpdateReportAsync(Guid bandId, Guid reportId, UpdateGemaReportRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct);

    // Entries
    Task<GemaReportEntryDto> AddEntryAsync(Guid bandId, Guid reportId, AddGemaReportEntryRequest request, Guid musicianId, CancellationToken ct);
    Task<GemaReportEntryDto> UpdateEntryAsync(Guid bandId, Guid reportId, Guid entryId, UpdateGemaReportEntryRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteEntryAsync(Guid bandId, Guid reportId, Guid entryId, Guid musicianId, CancellationToken ct);

    // Report actions
    Task<GemaReportDto> FinalizeReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct);
    Task<byte[]> ExportReportAsync(Guid bandId, Guid reportId, string format, Guid musicianId, CancellationToken ct);

    // Generate from setlist
    Task<GemaReportDto> GenerateFromSetlistAsync(Guid bandId, Guid setlistId, CreateGemaReportRequest request, Guid musicianId, CancellationToken ct);
}
