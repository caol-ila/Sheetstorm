using Sheetstorm.Domain.Shifts;
using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Infrastructure.Shifts;

public interface IShiftService
{
    // ShiftPlan CRUD
    Task<ShiftPlanDto> CreateShiftPlanAsync(Guid bandId, CreateShiftPlanRequest request, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<ShiftPlanDto>> GetShiftPlansAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<ShiftPlanDto> GetShiftPlanAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct);
    Task<ShiftPlanDto> UpdateShiftPlanAsync(Guid bandId, Guid planId, UpdateShiftPlanRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteShiftPlanAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct);

    // Shift CRUD
    Task<ShiftDto> CreateShiftAsync(Guid bandId, Guid planId, CreateShiftRequest request, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<ShiftSummaryDto>> GetShiftsAsync(Guid bandId, Guid planId, Guid musicianId, CancellationToken ct);
    Task<ShiftDto> GetShiftAsync(Guid bandId, Guid planId, Guid shiftId, Guid musicianId, CancellationToken ct);
    Task<ShiftDto> UpdateShiftAsync(Guid bandId, Guid planId, Guid shiftId, UpdateShiftRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteShiftAsync(Guid bandId, Guid planId, Guid shiftId, Guid musicianId, CancellationToken ct);

    // Assignments
    Task<ShiftAssignmentDto> CreateAssignmentAsync(Guid bandId, Guid planId, Guid shiftId, CreateShiftAssignmentRequest request, Guid musicianId, CancellationToken ct);
    Task DeleteAssignmentAsync(Guid bandId, Guid planId, Guid shiftId, Guid assignmentId, Guid musicianId, CancellationToken ct);
    Task<ShiftAssignmentDto> UpdateAssignmentStatusAsync(Guid bandId, Guid planId, Guid shiftId, Guid assignmentId, UpdateShiftAssignmentStatusRequest request, Guid musicianId, CancellationToken ct);

    // My shifts
    Task<IReadOnlyList<MyShiftDto>> GetMyShiftsAsync(Guid bandId, Guid musicianId, CancellationToken ct);
}
