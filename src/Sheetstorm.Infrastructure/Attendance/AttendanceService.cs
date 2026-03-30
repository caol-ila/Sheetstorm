using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Attendance;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Attendance;

public class AttendanceService(AppDbContext db) : IAttendanceService
{
    public async Task<IReadOnlyList<AttendanceRecordDto>> GetAllAsync(Guid bandId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        var query = db.Set<AttendanceRecord>()
            .Include(a => a.Musician)
            .Include(a => a.RecordedByMusician)
            .Where(a => a.BandId == bandId);

        if (membership.Role == MemberRole.Musician)
            query = query.Where(a => a.MusicianId == musicianId);

        if (startDate.HasValue)
            query = query.Where(a => a.Date >= startDate.Value);

        if (endDate.HasValue)
            query = query.Where(a => a.Date <= endDate.Value);

        var records = await query
            .OrderByDescending(a => a.Date)
            .ToListAsync(ct);

        return records.Select(a => new AttendanceRecordDto(
            a.Id,
            a.MusicianId,
            a.Musician.Name,
            a.Date,
            a.Status,
            a.EventId,
            a.Notes,
            a.RecordedByMusicianId,
            a.RecordedByMusician.Name,
            a.CreatedAt
        )).ToList();
    }

    public async Task<AttendanceRecordDto> GetByIdAsync(Guid bandId, Guid recordId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        var record = await db.Set<AttendanceRecord>()
            .Include(a => a.Musician)
            .Include(a => a.RecordedByMusician)
            .FirstOrDefaultAsync(a => a.Id == recordId && a.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Attendance record not found.", 404);

        if (membership.Role == MemberRole.Musician && record.MusicianId != musicianId)
            throw new DomainException("FORBIDDEN", "You can only view your own attendance records.", 403);

        return new AttendanceRecordDto(
            record.Id,
            record.MusicianId,
            record.Musician.Name,
            record.Date,
            record.Status,
            record.EventId,
            record.Notes,
            record.RecordedByMusicianId,
            record.RecordedByMusician.Name,
            record.CreatedAt
        );
    }

    public async Task<AttendanceRecordDto> CreateAsync(Guid bandId, CreateAttendanceRecordRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SectionLeader)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and section leaders can record attendance.", 403);

        var targetMusician = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == request.MusicianId && m.IsActive, ct)
            ?? throw new DomainException("NOT_FOUND", "Musician not found in this band.", 404);

        if (request.EventId.HasValue)
        {
            var ev = await db.Set<Event>()
                .FirstOrDefaultAsync(e => e.Id == request.EventId.Value && e.BandId == bandId, ct);
            if (ev == null)
                throw new DomainException("VALIDATION_ERROR", "Event does not belong to this band.", 400);
        }

        var existingRecord = await db.Set<AttendanceRecord>()
            .FirstOrDefaultAsync(a => a.BandId == bandId && a.MusicianId == request.MusicianId && a.Date == request.Date, ct);

        if (existingRecord != null)
            throw new DomainException("CONFLICT", "Attendance record already exists for this musician on this date.", 409);

        var record = new AttendanceRecord
        {
            BandId = bandId,
            MusicianId = request.MusicianId,
            Date = request.Date,
            Status = request.Status,
            EventId = request.EventId,
            Notes = request.Notes?.Trim(),
            RecordedByMusicianId = musicianId
        };

        db.Set<AttendanceRecord>().Add(record);
        await db.SaveChangesAsync(ct);

        var musician = await db.Set<Musician>().FindAsync(new object[] { request.MusicianId }, ct);
        var recordedBy = await db.Set<Musician>().FindAsync(new object[] { musicianId }, ct);

        return new AttendanceRecordDto(
            record.Id,
            request.MusicianId,
            musician!.Name,
            record.Date,
            record.Status,
            record.EventId,
            record.Notes,
            musicianId,
            recordedBy!.Name,
            record.CreatedAt
        );
    }

    public async Task<AttendanceRecordDto> UpdateAsync(Guid bandId, Guid recordId, UpdateAttendanceRecordRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SectionLeader)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and section leaders can update attendance.", 403);

        var record = await db.Set<AttendanceRecord>()
            .Include(a => a.Musician)
            .Include(a => a.RecordedByMusician)
            .FirstOrDefaultAsync(a => a.Id == recordId && a.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Attendance record not found.", 404);

        record.Status = request.Status;
        record.Notes = request.Notes?.Trim();

        await db.SaveChangesAsync(ct);

        return new AttendanceRecordDto(
            record.Id,
            record.MusicianId,
            record.Musician.Name,
            record.Date,
            record.Status,
            record.EventId,
            record.Notes,
            record.RecordedByMusicianId,
            record.RecordedByMusician.Name,
            record.CreatedAt
        );
    }

    public async Task DeleteAsync(Guid bandId, Guid recordId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && membership.Role != MemberRole.Conductor)
            throw new DomainException("FORBIDDEN", "Only admins and conductors can delete attendance records.", 403);

        var record = await db.Set<AttendanceRecord>()
            .FirstOrDefaultAsync(a => a.Id == recordId && a.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Attendance record not found.", 404);

        db.Set<AttendanceRecord>().Remove(record);
        await db.SaveChangesAsync(ct);
    }

    public async Task<BandAttendanceStatsDto> GetStatsAsync(Guid bandId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SectionLeader)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and section leaders can view band statistics.", 403);

        var query = db.Set<AttendanceRecord>()
            .Include(a => a.Musician)
            .Where(a => a.BandId == bandId);

        if (startDate.HasValue)
            query = query.Where(a => a.Date >= startDate.Value);

        if (endDate.HasValue)
            query = query.Where(a => a.Date <= endDate.Value);

        var records = await query.ToListAsync(ct);

        var actualStart = records.Any() ? records.Min(r => r.Date) : DateOnly.FromDateTime(DateTime.UtcNow);
        var actualEnd = records.Any() ? records.Max(r => r.Date) : DateOnly.FromDateTime(DateTime.UtcNow);

        var uniqueDates = records.Select(r => r.Date).Distinct().Count();

        var musicianStats = records
            .GroupBy(r => new { r.MusicianId, r.Musician.Name })
            .Select(g =>
            {
                var total = g.Count();
                var present = g.Count(r => r.Status == AttendanceStatus.Present);
                var absent = g.Count(r => r.Status == AttendanceStatus.Absent);
                var excused = g.Count(r => r.Status == AttendanceStatus.Excused);
                var late = g.Count(r => r.Status == AttendanceStatus.Late);

                return new AttendanceStatsDto(
                    g.Key.MusicianId,
                    g.Key.Name,
                    total,
                    present,
                    absent,
                    excused,
                    late,
                    total > 0 ? (double)present / total * 100 : 0
                );
            })
            .OrderByDescending(s => s.AttendanceRate)
            .ToList();

        var avgRate = musicianStats.Any() ? musicianStats.Average(s => s.AttendanceRate) : 0;

        return new BandAttendanceStatsDto(
            actualStart,
            actualEnd,
            uniqueDates,
            avgRate,
            musicianStats
        );
    }

    public async Task<AttendanceStatsDto> GetMusicianStatsAsync(Guid bandId, Guid targetMusicianId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role == MemberRole.Musician && targetMusicianId != musicianId)
            throw new DomainException("FORBIDDEN", "You can only view your own statistics.", 403);

        var targetMusician = await db.Set<Musician>()
            .FirstOrDefaultAsync(m => m.Id == targetMusicianId, ct)
            ?? throw new DomainException("NOT_FOUND", "Musician not found.", 404);

        var query = db.Set<AttendanceRecord>()
            .Where(a => a.BandId == bandId && a.MusicianId == targetMusicianId);

        if (startDate.HasValue)
            query = query.Where(a => a.Date >= startDate.Value);

        if (endDate.HasValue)
            query = query.Where(a => a.Date <= endDate.Value);

        var records = await query.ToListAsync(ct);

        var total = records.Count;
        var present = records.Count(r => r.Status == AttendanceStatus.Present);
        var absent = records.Count(r => r.Status == AttendanceStatus.Absent);
        var excused = records.Count(r => r.Status == AttendanceStatus.Excused);
        var late = records.Count(r => r.Status == AttendanceStatus.Late);

        return new AttendanceStatsDto(
            targetMusicianId,
            targetMusician.Name,
            total,
            present,
            absent,
            excused,
            late,
            total > 0 ? (double)present / total * 100 : 0
        );
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }
}
