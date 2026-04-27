using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

public sealed record BandSummary(Guid Id, string Slug, string Name, BandRole Roles, MembershipStatus Status, bool IsOwner);

public sealed record InvitationCreated(string Token, DateTimeOffset ExpiresAt);
public sealed record JoinCodeCreated(string Code, DateTimeOffset? ExpiresAt);

public sealed class BandService(SheetstormDbContext db)
{
    public async Task<List<BandSummary>> GetBandsForUserAsync(Guid userId, CancellationToken ct = default)
    {
        return await db.Memberships
            .Where(m => m.UserId == userId && m.Status == MembershipStatus.Active)
            .OrderBy(m => m.Band.Name)
            .Select(m => new BandSummary(m.Band.Id, m.Band.Slug, m.Band.Name, m.Roles, m.Status, m.Band.OwnerId == userId))
            .ToListAsync(ct);
    }

    public async Task<Band> CreateBandAsync(Guid ownerId, string name, string slug, string? description, CancellationToken ct = default)
    {
        slug = slug.Trim().ToLowerInvariant();
        if (await db.Bands.AnyAsync(b => b.Slug == slug, ct))
            throw new InvalidOperationException("Slug ist bereits vergeben.");

        var band = Band.Create(name, slug, ownerId, description);
        db.Bands.Add(band);

        var owner = Membership.Create(band.Id, ownerId,
            BandRole.Mitglied | BandRole.Dirigent | BandRole.Admin | BandRole.Owner);
        db.Memberships.Add(owner);

        await db.SaveChangesAsync(ct);
        return band;
    }

    public async Task<List<Membership>> GetMembershipsAsync(Guid bandId, CancellationToken ct = default)
        => await db.Memberships.Where(m => m.BandId == bandId).ToListAsync(ct);

    public async Task<Membership?> GetMembershipAsync(Guid bandId, Guid userId, CancellationToken ct = default)
        => await db.Memberships.FirstOrDefaultAsync(m => m.BandId == bandId && m.UserId == userId, ct);

    public async Task<InvitationCreated> CreateInvitationAsync(Guid bandId, string email, BandRole roles, Guid createdById, TimeSpan? lifetime = null, CancellationToken ct = default)
    {
        var token = TokenHasher.GenerateUrlToken();
        var hash = TokenHasher.Hash(token);
        var expires = DateTimeOffset.UtcNow.Add(lifetime ?? TimeSpan.FromDays(7));
        var inv = BandInvitation.Create(bandId, email, hash, expires, roles, createdById);
        db.BandInvitations.Add(inv);
        await db.SaveChangesAsync(ct);
        return new InvitationCreated(token, expires);
    }

    public async Task<Guid?> AcceptInvitationAsync(string token, Guid acceptingUserId, string acceptingEmail, CancellationToken ct = default)
    {
        var hash = TokenHasher.Hash(token);
        var inv = await db.BandInvitations.FirstOrDefaultAsync(i => i.TokenHash == hash, ct);
        if (inv is null || !inv.IsValidNow(DateTimeOffset.UtcNow)) return null;
        if (!string.Equals(inv.Email, acceptingEmail.Trim().ToLowerInvariant(), StringComparison.Ordinal)) return null;

        var existing = await db.Memberships.FirstOrDefaultAsync(m => m.BandId == inv.BandId && m.UserId == acceptingUserId, ct);
        if (existing is null)
        {
            db.Memberships.Add(Membership.Create(inv.BandId, acceptingUserId, inv.RolesToGrant));
        }
        else
        {
            existing.Activate();
            existing.GrantRole(inv.RolesToGrant);
        }
        inv.MarkAccepted(acceptingUserId, DateTimeOffset.UtcNow);
        await db.SaveChangesAsync(ct);
        return inv.BandId;
    }

    public async Task<JoinCodeCreated> CreateJoinCodeAsync(Guid bandId, Guid createdById, int? maxUses, TimeSpan? lifetime, CancellationToken ct = default)
    {
        var code = TokenHasher.GenerateJoinCode();
        var hash = TokenHasher.Hash(code);
        DateTimeOffset? expires = lifetime is null ? null : DateTimeOffset.UtcNow.Add(lifetime.Value);
        var jc = BandJoinCode.Create(bandId, hash, createdById, maxUses, expires);
        db.BandJoinCodes.Add(jc);
        await db.SaveChangesAsync(ct);
        return new JoinCodeCreated(code, expires);
    }

    /// <summary>
    /// Reicht eine Beitrittsanfrage über JoinCode ein. Anfrage muss durch Admin approved werden.
    /// </summary>
    public async Task<Guid?> RequestJoinByCodeAsync(string code, Guid userId, CancellationToken ct = default)
    {
        var hash = TokenHasher.Hash(code.Trim().ToUpperInvariant());
        var jc = await db.BandJoinCodes.FirstOrDefaultAsync(c => c.CodeHash == hash, ct);
        if (jc is null || !jc.IsUsable(DateTimeOffset.UtcNow)) return null;

        var existing = await db.Memberships.FirstOrDefaultAsync(m => m.BandId == jc.BandId && m.UserId == userId, ct);
        if (existing is { Status: MembershipStatus.Active }) return jc.BandId;

        var pendingDup = await db.BandJoinRequests
            .FirstOrDefaultAsync(r => r.BandId == jc.BandId && r.UserId == userId && r.DecidedAt == null, ct);
        if (pendingDup is not null) return jc.BandId;

        db.BandJoinRequests.Add(BandJoinRequest.Create(jc.BandId, userId, jc.Id));
        jc.RegisterUse();
        await db.SaveChangesAsync(ct);
        return jc.BandId;
    }

    public async Task<List<BandJoinRequest>> GetPendingJoinRequestsAsync(Guid bandId, CancellationToken ct = default)
        => await db.BandJoinRequests.Where(r => r.BandId == bandId && r.DecidedAt == null).ToListAsync(ct);

    public async Task<bool> DecideJoinRequestAsync(Guid requestId, bool approve, Guid byUserId, BandRole grantRoles = BandRole.Mitglied, CancellationToken ct = default)
    {
        var req = await db.BandJoinRequests.FirstOrDefaultAsync(r => r.Id == requestId, ct);
        if (req is null || req.DecidedAt is not null) return false;

        req.Decide(approve, byUserId, DateTimeOffset.UtcNow);

        if (approve)
        {
            var existing = await db.Memberships.FirstOrDefaultAsync(m => m.BandId == req.BandId && m.UserId == req.UserId, ct);
            if (existing is null)
            {
                db.Memberships.Add(Membership.Create(req.BandId, req.UserId, grantRoles));
            }
            else
            {
                existing.Activate();
                existing.GrantRole(grantRoles);
            }
        }
        await db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<bool> SetMemberRolesAsync(Guid bandId, Guid memberUserId, BandRole roles, CancellationToken ct = default)
    {
        var m = await db.Memberships.FirstOrDefaultAsync(x => x.BandId == bandId && x.UserId == memberUserId, ct);
        if (m is null) return false;
        // Owner-Schutz: kann nur durch Owner-Transfer entzogen werden — hier nicht anfassen.
        var preserveOwner = m.HasRole(BandRole.Owner) ? BandRole.Owner : BandRole.None;
        var newRoles = (roles == BandRole.None ? BandRole.Mitglied : roles) | preserveOwner;
        // schmutzig direkt überschreiben
        var grant = newRoles & ~m.Roles;
        var revoke = m.Roles & ~newRoles;
        if (grant != BandRole.None) m.GrantRole(grant);
        if (revoke != BandRole.None) m.RevokeRole(revoke);
        await db.SaveChangesAsync(ct);
        return true;
    }

    public async Task SetPreferredInstrumentAsync(Guid membershipId, Guid instrumentId, string? transposition, CancellationToken ct = default)
    {
        var existingForInstrument = await db.MembershipInstruments
            .FirstOrDefaultAsync(mi => mi.MembershipId == membershipId && mi.InstrumentId == instrumentId && mi.Transposition == transposition, ct);

        var others = await db.MembershipInstruments
            .Where(mi => mi.MembershipId == membershipId)
            .ToListAsync(ct);

        foreach (var o in others) o.SetPrimary(false);

        if (existingForInstrument is null)
        {
            db.MembershipInstruments.Add(MembershipInstrument.Create(membershipId, instrumentId, transposition, 0, true));
        }
        else
        {
            existingForInstrument.SetPrimary(true);
        }
        await db.SaveChangesAsync(ct);
    }
}
