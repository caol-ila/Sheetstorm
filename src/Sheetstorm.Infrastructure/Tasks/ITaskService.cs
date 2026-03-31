using Sheetstorm.Domain.Tasks;

namespace Sheetstorm.Infrastructure.Tasks;

public interface ITaskService
{
    Task<BandTaskDto> CreateTaskAsync(Guid bandId, CreateTaskRequest request, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<BandTaskDto>> GetTasksAsync(Guid bandId, Guid musicianId, TaskQueryParams query, CancellationToken ct);
    Task<BandTaskDto> GetTaskAsync(Guid bandId, Guid taskId, Guid musicianId, CancellationToken ct);
    Task<BandTaskDto> UpdateTaskAsync(Guid bandId, Guid taskId, UpdateTaskRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteTaskAsync(Guid bandId, Guid taskId, Guid musicianId, CancellationToken ct);
    Task<BandTaskDto> UpdateStatusAsync(Guid bandId, Guid taskId, UpdateTaskStatusRequest request, Guid musicianId, CancellationToken ct);
    Task<BandTaskDto> AssignTaskAsync(Guid bandId, Guid taskId, AssignTaskRequest request, Guid musicianId, CancellationToken ct);
}
