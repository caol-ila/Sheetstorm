using Sheetstorm.Domain.Entities;

namespace Sheetstorm.Infrastructure.Auth;

/// <summary>
/// Shared service for band-level authorization checks.
/// Replaces duplicated RequireMembershipAsync / RequireConductorOrAdminAsync / RequireAdminAsync
/// private helpers across all services.
/// </summary>
public interface IBandAuthorizationService
{
    /// <summary>Verify the musician is an active member of the band. Returns the membership.</summary>
    Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct = default);

    /// <summary>Verify the musician is a Conductor or Administrator. Returns the membership.</summary>
    Task<Membership> RequireConductorOrAdminAsync(Guid bandId, Guid musicianId, CancellationToken ct = default);

    /// <summary>Verify the musician is an Administrator. Returns the membership.</summary>
    Task<Membership> RequireAdminAsync(Guid bandId, Guid musicianId, CancellationToken ct = default);

    /// <summary>Verify the musician has one of the specified roles. Returns the membership.</summary>
    Task<Membership> RequireRoleAsync(Guid bandId, Guid musicianId, CancellationToken ct, params MemberRole[] allowedRoles);
}
