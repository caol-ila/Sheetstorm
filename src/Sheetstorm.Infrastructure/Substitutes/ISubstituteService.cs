using Sheetstorm.Domain.Substitutes;

namespace Sheetstorm.Infrastructure.Substitutes;

public interface ISubstituteService
{
    Task<SubstituteAccessCreatedDto> CreateAccessAsync(Guid bandId, CreateSubstituteAccessRequest request, Guid musicianId, CancellationToken ct);
    Task<SubstituteValidationDto> ValidateTokenAsync(string rawToken, CancellationToken ct);
    Task RevokeAccessAsync(Guid bandId, Guid accessId, Guid musicianId, CancellationToken ct);
    Task<IReadOnlyList<SubstituteAccessDto>> GetActiveAccessesAsync(Guid bandId, Guid musicianId, CancellationToken ct);
    Task<SubstituteAccessDto> ExtendAccessAsync(Guid bandId, Guid accessId, ExtendSubstituteAccessRequest request, Guid musicianId, CancellationToken ct);
}
