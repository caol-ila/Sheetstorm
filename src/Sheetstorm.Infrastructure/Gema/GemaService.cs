using System.Globalization;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Gema;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Gema;

public class GemaService(AppDbContext db) : IGemaService
{
    public async Task<GemaReportDto> CreateReportAsync(Guid bandId, CreateGemaReportRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = new GemaReport
        {
            BandId = bandId,
            Title = request.Title.Trim(),
            EventId = request.EventId,
            ReportDate = request.ReportDate,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            SetlistId = request.SetlistId,
            EventLocation = request.EventLocation?.Trim(),
            EventCategory = request.EventCategory?.Trim(),
            Organizer = request.Organizer?.Trim()
        };

        db.Set<GemaReport>().Add(report);
        await db.SaveChangesAsync(ct);

        return await GetReportAsync(bandId, report.Id, musicianId, ct);
    }

    public async Task<GemaReportDto> GetReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .Include(r => r.GeneratedByMusician)
            .Include(r => r.Entries.OrderBy(e => e.Position))
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        return MapToDto(report);
    }

    public async Task<IReadOnlyList<GemaReportSummaryDto>> GetReportsAsync(Guid bandId, Guid musicianId, GemaReportStatus? status, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var query = db.Set<GemaReport>()
            .Where(r => r.BandId == bandId)
            .Include(r => r.Entries);

        if (status.HasValue)
            query = query.Where(r => r.Status == status.Value).Include(r => r.Entries);

        var reports = await query
            .OrderByDescending(r => r.ReportDate)
            .ToListAsync(ct);

        return reports.Select(r => new GemaReportSummaryDto(
            r.Id,
            r.Title,
            r.ReportDate,
            r.Status,
            r.EventLocation,
            r.EventCategory,
            r.Entries.Count,
            r.ExportedAt,
            r.CreatedAt
        )).ToList();
    }

    public async Task<GemaReportDto> UpdateReportAsync(Guid bandId, Guid reportId, UpdateGemaReportRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status is GemaReportStatus.Finalized or GemaReportStatus.Submitted)
            throw new DomainException("CONFLICT", "Cannot edit a finalized or submitted report.", 409);

        if (request.Title != null) report.Title = request.Title.Trim();
        if (request.EventLocation != null) report.EventLocation = request.EventLocation.Trim();
        if (request.EventCategory != null) report.EventCategory = request.EventCategory.Trim();
        if (request.Organizer != null) report.Organizer = request.Organizer.Trim();

        await db.SaveChangesAsync(ct);

        return await GetReportAsync(bandId, reportId, musicianId, ct);
    }

    public async Task DeleteReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status is GemaReportStatus.Submitted)
            throw new DomainException("CONFLICT", "Cannot delete a submitted report.", 409);

        db.Set<GemaReport>().Remove(report);
        await db.SaveChangesAsync(ct);
    }

    public async Task<GemaReportEntryDto> AddEntryAsync(Guid bandId, Guid reportId, AddGemaReportEntryRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .Include(r => r.Entries)
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status is GemaReportStatus.Finalized or GemaReportStatus.Submitted)
            throw new DomainException("CONFLICT", "Cannot modify a finalized or submitted report.", 409);

        var maxPosition = report.Entries.Any() ? report.Entries.Max(e => e.Position) : 0;

        var entry = new GemaReportEntry
        {
            GemaReportId = reportId,
            Title = request.Title.Trim(),
            Composer = request.Composer.Trim(),
            Arranger = request.Arranger?.Trim(),
            Publisher = request.Publisher?.Trim(),
            DurationSeconds = request.DurationSeconds,
            WorkNumber = request.WorkNumber?.Trim(),
            PieceId = request.PieceId,
            Position = maxPosition + 1
        };

        db.Set<GemaReportEntry>().Add(entry);
        await db.SaveChangesAsync(ct);

        return MapEntryToDto(entry);
    }

    public async Task<GemaReportEntryDto> UpdateEntryAsync(Guid bandId, Guid reportId, Guid entryId, UpdateGemaReportEntryRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status is GemaReportStatus.Finalized or GemaReportStatus.Submitted)
            throw new DomainException("CONFLICT", "Cannot modify a finalized or submitted report.", 409);

        var entry = await db.Set<GemaReportEntry>()
            .FirstOrDefaultAsync(e => e.Id == entryId && e.GemaReportId == reportId, ct)
            ?? throw new DomainException("NOT_FOUND", "Report entry not found.", 404);

        if (request.Title != null) entry.Title = request.Title.Trim();
        if (request.Composer != null) entry.Composer = request.Composer.Trim();
        if (request.Arranger != null) entry.Arranger = request.Arranger.Trim();
        if (request.Publisher != null) entry.Publisher = request.Publisher.Trim();
        if (request.DurationSeconds.HasValue) entry.DurationSeconds = request.DurationSeconds;
        if (request.WorkNumber != null) entry.WorkNumber = request.WorkNumber.Trim();

        await db.SaveChangesAsync(ct);

        return MapEntryToDto(entry);
    }

    public async Task DeleteEntryAsync(Guid bandId, Guid reportId, Guid entryId, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status is GemaReportStatus.Finalized or GemaReportStatus.Submitted)
            throw new DomainException("CONFLICT", "Cannot modify a finalized or submitted report.", 409);

        var entry = await db.Set<GemaReportEntry>()
            .FirstOrDefaultAsync(e => e.Id == entryId && e.GemaReportId == reportId, ct)
            ?? throw new DomainException("NOT_FOUND", "Report entry not found.", 404);

        db.Set<GemaReportEntry>().Remove(entry);
        await db.SaveChangesAsync(ct);
    }

    public async Task<GemaReportDto> FinalizeReportAsync(Guid bandId, Guid reportId, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .Include(r => r.Entries)
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        if (report.Status != GemaReportStatus.Draft)
            throw new DomainException("CONFLICT", "Only draft reports can be finalized.", 409);

        if (!report.Entries.Any())
            throw new DomainException("VALIDATION_ERROR", "Cannot finalize an empty report.", 400);

        report.Status = GemaReportStatus.Finalized;
        await db.SaveChangesAsync(ct);

        return await GetReportAsync(bandId, reportId, musicianId, ct);
    }

    public async Task<byte[]> ExportReportAsync(Guid bandId, Guid reportId, string format, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var report = await db.Set<GemaReport>()
            .Include(r => r.Entries.OrderBy(e => e.Position))
            .Include(r => r.GeneratedByMusician)
            .FirstOrDefaultAsync(r => r.Id == reportId && r.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "GEMA report not found.", 404);

        report.ExportedAt = DateTime.UtcNow;
        report.ExportFormat = format;
        await db.SaveChangesAsync(ct);

        return format.ToLowerInvariant() switch
        {
            "csv" => GenerateCsvExport(report),
            "xml" => GenerateXmlExport(report),
            _ => throw new DomainException("VALIDATION_ERROR", $"Unsupported export format: {format}.", 400)
        };
    }

    public async Task<GemaReportDto> GenerateFromSetlistAsync(Guid bandId, Guid setlistId, CreateGemaReportRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var setlist = await db.Set<Setlist>()
            .Include(s => s.Entries.OrderBy(e => e.Position))
                .ThenInclude(e => e.Piece)
            .FirstOrDefaultAsync(s => s.Id == setlistId && s.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Setlist not found.", 404);

        var report = new GemaReport
        {
            BandId = bandId,
            Title = request.Title.Trim(),
            EventId = request.EventId,
            ReportDate = request.ReportDate,
            Status = GemaReportStatus.Draft,
            GeneratedByMusicianId = musicianId,
            SetlistId = setlistId,
            EventLocation = request.EventLocation?.Trim(),
            EventCategory = request.EventCategory?.Trim(),
            Organizer = request.Organizer?.Trim()
        };

        db.Set<GemaReport>().Add(report);

        var position = 1;
        foreach (var entry in setlist.Entries.Where(e => e.Piece != null))
        {
            db.Set<GemaReportEntry>().Add(new GemaReportEntry
            {
                GemaReportId = report.Id,
                PieceId = entry.PieceId,
                Title = entry.Piece!.Title,
                Composer = entry.Piece.Composer ?? "Unknown",
                Arranger = entry.Piece.Arranger,
                DurationSeconds = entry.DurationSeconds,
                Position = position++
            });
        }

        await db.SaveChangesAsync(ct);

        return await GetReportAsync(bandId, report.Id, musicianId, ct);
    }

    // ── Private Helpers ──────────────────────────────────────────────────────

    private static GemaReportDto MapToDto(GemaReport report) => new(
        report.Id,
        report.BandId,
        report.Title,
        report.EventId,
        report.ReportDate,
        report.Status,
        report.GeneratedByMusicianId,
        report.GeneratedByMusician.Name,
        report.ExportFormat,
        report.EventLocation,
        report.EventCategory,
        report.Organizer,
        report.SetlistId,
        report.ExportedAt,
        report.Entries.Select(MapEntryToDto).ToList(),
        report.CreatedAt
    );

    private static GemaReportEntryDto MapEntryToDto(GemaReportEntry entry) => new(
        entry.Id,
        entry.PieceId,
        entry.Composer,
        entry.Title,
        entry.Arranger,
        entry.Publisher,
        entry.DurationSeconds,
        entry.WorkNumber,
        entry.Position
    );

    private static byte[] GenerateCsvExport(GemaReport report)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Position;Werktitel;Komponist;Bearbeiter;Verlag;GEMA-Werknummer;Dauer (Sek.)");

        foreach (var entry in report.Entries)
        {
            sb.AppendLine(string.Join(';',
                entry.Position.ToString(CultureInfo.InvariantCulture),
                EscapeCsv(entry.Title),
                EscapeCsv(entry.Composer),
                EscapeCsv(entry.Arranger ?? ""),
                EscapeCsv(entry.Publisher ?? ""),
                EscapeCsv(entry.WorkNumber ?? ""),
                entry.DurationSeconds?.ToString(CultureInfo.InvariantCulture) ?? ""
            ));
        }

        return Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
    }

    private static byte[] GenerateXmlExport(GemaReport report)
    {
        var sb = new StringBuilder();
        sb.AppendLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sb.AppendLine("<GEMAMeldung>");
        sb.AppendLine($"  <Veranstaltung>");
        sb.AppendLine($"    <Datum>{report.ReportDate:yyyy-MM-dd}</Datum>");
        sb.AppendLine($"    <Ort>{EscapeXml(report.EventLocation ?? "")}</Ort>");
        sb.AppendLine($"    <Art>{EscapeXml(report.EventCategory ?? "")}</Art>");
        sb.AppendLine($"    <Veranstalter>{EscapeXml(report.Organizer ?? "")}</Veranstalter>");
        sb.AppendLine($"  </Veranstaltung>");
        sb.AppendLine("  <Werkliste>");

        foreach (var entry in report.Entries)
        {
            sb.AppendLine("    <Werk>");
            sb.AppendLine($"      <Position>{entry.Position}</Position>");
            sb.AppendLine($"      <Werktitel>{EscapeXml(entry.Title)}</Werktitel>");
            sb.AppendLine($"      <Komponist>{EscapeXml(entry.Composer)}</Komponist>");
            if (entry.Arranger != null)
                sb.AppendLine($"      <Bearbeiter>{EscapeXml(entry.Arranger)}</Bearbeiter>");
            if (entry.Publisher != null)
                sb.AppendLine($"      <Verlag>{EscapeXml(entry.Publisher)}</Verlag>");
            if (entry.WorkNumber != null)
                sb.AppendLine($"      <GEMAWerknummer>{EscapeXml(entry.WorkNumber)}</GEMAWerknummer>");
            if (entry.DurationSeconds.HasValue)
                sb.AppendLine($"      <Dauer>PT{entry.DurationSeconds / 60}M{entry.DurationSeconds % 60}S</Dauer>");
            sb.AppendLine("    </Werk>");
        }

        sb.AppendLine("  </Werkliste>");
        sb.AppendLine("</GEMAMeldung>");

        return Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
    }

    private static string EscapeCsv(string value)
    {
        if (value.Contains(';') || value.Contains('"') || value.Contains('\n'))
            return $"\"{value.Replace("\"", "\"\"")}\"";
        return value;
    }

    private static string EscapeXml(string value) =>
        value.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;");

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("NOT_FOUND", "Band not found or no access.", 404);
    }

    private async Task<Membership> RequireConductorOrAdminAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await RequireMembershipAsync(bandId, musicianId, ct);

        if (m.Role is not (MemberRole.Administrator or MemberRole.Conductor))
            throw new DomainException("FORBIDDEN", "Only conductors or admins can perform this action.", 403);

        return m;
    }
}
