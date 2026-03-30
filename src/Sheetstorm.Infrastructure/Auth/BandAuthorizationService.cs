using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Auth;

/// <summary>
/// Centralized band-level authorization checks.
/// Throws DomainException for membership / role violations.
/// </summary>
public class BandAuthorizationService(AppDbContext db) : IBandAuthorizationService
{
    public async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct = default)
    {
        var m = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }

    public async Task<Membership> RequireConductorOrAdminAsync(Guid bandId, Guid musicianId, CancellationToken ct = default)
    {
        var m = await RequireMembershipAsync(bandId, musicianId, ct);

        if (m.Role is not (MemberRole.Administrator or MemberRole.Conductor))
            throw new DomainException("FORBIDDEN", "Only conductors or admins can perform this action.", 403);

        return m;
    }

    public async Task<Membership> RequireAdminAsync(Guid bandId, Guid musicianId, CancellationToken ct = default)
    {
        var m = await RequireMembershipAsync(bandId, musicianId, ct);

        if (m.Role != MemberRole.Administrator)
            throw new DomainException("FORBIDDEN", "Only admins can perform this action.", 403);

        return m;
    }

    public async Task<Membership> RequireRoleAsync(Guid bandId, Guid musicianId, CancellationToken ct, params MemberRole[] allowedRoles)
    {
        var m = await RequireMembershipAsync(bandId, musicianId, ct);

        if (!allowedRoles.Contains(m.Role))
            throw new DomainException("FORBIDDEN", $"Required role: {string.Join(" or ", allowedRoles)}.", 403);

        return m;
    }
}
