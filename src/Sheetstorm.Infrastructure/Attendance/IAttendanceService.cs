using Sheetstorm.Domain.Attendance;

namespace Sheetstorm.Infrastructure.Attendance;

public interface IAttendanceService
{
    Task<IReadOnlyList<AttendanceRecordDto>> GetAllAsync(Guid bandId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct);
    Task<AttendanceRecordDto> GetByIdAsync(Guid bandId, Guid recordId, Guid musicianId, CancellationToken ct);
    Task<AttendanceRecordDto> CreateAsync(Guid bandId, CreateAttendanceRecordRequest request, Guid musicianId, CancellationToken ct);
    Task<AttendanceRecordDto> UpdateAsync(Guid bandId, Guid recordId, UpdateAttendanceRecordRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAsync(Guid bandId, Guid recordId, Guid musicianId, CancellationToken ct);
    Task<BandAttendanceStatsDto> GetStatsAsync(Guid bandId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct);
    Task<AttendanceStatsDto> GetMusicianStatsAsync(Guid bandId, Guid targetMusicianId, Guid musicianId, DateOnly? startDate, DateOnly? endDate, CancellationToken ct);
}
