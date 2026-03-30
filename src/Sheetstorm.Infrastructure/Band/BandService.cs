using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.BandManagement;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.BandManagement;

public class BandService(AppDbContext db, IBandAuthorizationService bandAuth) : IBandService
{
    private static readonly char[] CodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray();

    public async Task<IReadOnlyList<BandDto>> GetMyBandsAsync(Guid musicianId)
    {
        return await db.Memberships
            .Where(m => m.MusicianId == musicianId && m.IsActive)
            .Select(m => new BandDto(
                m.Band.Id,
                m.Band.Name,
                m.Band.Description,
                m.Band.Location,
                m.Band.Members.Count(mm => mm.IsActive),
                m.Role,
                m.Band.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<BandDetailDto> GetBandAsync(Guid bandId, Guid musicianId)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var band = await db.Bands
            .Include(k => k.Members.Where(m => m.IsActive))
            .ThenInclude(m => m.Musician)
            .FirstOrDefaultAsync(k => k.Id == bandId)
            ?? throw new DomainException("BAND_NOT_FOUND", "Band not found.", 404);

        var members = band.Members
            .Select(m => new MemberDto(
                m.MusicianId,
                m.Musician.Name,
                m.Musician.Email,
                m.Musician.Instrument,
                m.Role,
                m.VoiceOverride,
                m.CreatedAt
            ))
            .ToList();

        return new BandDetailDto(
            band.Id,
            band.Name,
            band.Description,
            band.Location,
            members,
            band.CreatedAt
        );
    }

    public async Task<BandDto> CreateBandAsync(CreateBandRequest request, Guid musicianId)
    {
        var band = new Band
        {
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Location = request.Location?.Trim()
        };

        db.Bands.Add(band);

        db.Memberships.Add(new Membership
        {
            BandId = band.Id,
            MusicianId = musicianId,
            Role = MemberRole.Administrator,
            IsActive = true
        });

        await db.SaveChangesAsync();

        return new BandDto(
            band.Id,
            band.Name,
            band.Description,
            band.Location,
            1,
            MemberRole.Administrator,
            band.CreatedAt
        );
    }

    public async Task<BandDto> UpdateBandAsync(
        Guid bandId,
        UpdateBandRequest request,
        Guid musicianId)
    {
        await bandAuth.RequireAdminAsync(bandId, musicianId);

        var band = await db.Bands.FindAsync(bandId)
            ?? throw new DomainException("BAND_NOT_FOUND", "Band not found.", 404);

        band.Name = request.Name.Trim();
        band.Description = request.Description?.Trim();
        band.Location = request.Location?.Trim();

        await db.SaveChangesAsync();

        var memberCount = await db.Memberships
            .CountAsync(m => m.BandId == bandId && m.IsActive);

        return new BandDto(
            band.Id,
            band.Name,
            band.Description,
            band.Location,
            memberCount,
            MemberRole.Administrator,
            band.CreatedAt
        );
    }

    public async Task DeleteBandAsync(Guid bandId, Guid musicianId)
    {
        await bandAuth.RequireAdminAsync(bandId, musicianId);

        var band = await db.Bands.FindAsync(bandId)
            ?? throw new DomainException("BAND_NOT_FOUND", "Band not found.", 404);

        db.Bands.Remove(band);
        await db.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<MemberDto>> GetMembersAsync(Guid bandId, Guid musicianId)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        return await db.Memberships
            .Where(m => m.BandId == bandId && m.IsActive)
            .Select(m => new MemberDto(
                m.MusicianId,
                m.Musician.Name,
                m.Musician.Email,
                m.Musician.Instrument,
                m.Role,
                m.VoiceOverride,
                m.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<InvitationDto> CreateInvitationAsync(
        Guid bandId,
        CreateInvitationRequest request,
        Guid musicianId)
    {
        await bandAuth.RequireAdminAsync(bandId, musicianId);

        var code = GenerateCode();
        var expiresAt = DateTime.UtcNow.AddDays(request.ValidityDays);

        db.Invitations.Add(new Invitation
        {
            Code = code,
            BandId = bandId,
            IntendedRole = request.Role,
            ExpiresAt = expiresAt,
            CreatedByMusicianId = musicianId
        });

        await db.SaveChangesAsync();

        return new InvitationDto(code, request.Role, expiresAt);
    }

    public async Task<BandDto> JoinAsync(JoinRequest request, Guid musicianId)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var now = DateTime.UtcNow;

        var invitation = await db.Invitations
            .Include(e => e.Band)
            .FirstOrDefaultAsync(e => e.Code == code)
            ?? throw new DomainException("INVALID_CODE", "Invalid or expired invitation code.", 400);

        if (invitation.IsUsed)
            throw new DomainException("CODE_ALREADY_USED", "This invitation code has already been used.", 400);

        if (invitation.ExpiresAt < now)
            throw new DomainException("CODE_EXPIRED", "The invitation code has expired.", 400);

        var existing = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == invitation.BandId && m.MusicianId == musicianId);

        if (existing is { IsActive: true })
            throw new DomainException("ALREADY_MEMBER", "You are already a member of this band.", 409);

        if (existing is not null)
        {
            // Re-activate a former member
            existing.IsActive = true;
            existing.Role = invitation.IntendedRole;
        }
        else
        {
            db.Memberships.Add(new Membership
            {
                BandId = invitation.BandId,
                MusicianId = musicianId,
                Role = invitation.IntendedRole,
                IsActive = true
            });
        }

        invitation.IsUsed = true;
        invitation.RedeemedByMusicianId = musicianId;

        await db.SaveChangesAsync();

        var memberCount = await db.Memberships
            .CountAsync(m => m.BandId == invitation.BandId && m.IsActive);

        return new BandDto(
            invitation.Band.Id,
            invitation.Band.Name,
            invitation.Band.Description,
            invitation.Band.Location,
            memberCount,
            invitation.IntendedRole,
            invitation.Band.CreatedAt
        );
    }

    public async Task ChangeRoleAsync(
        Guid bandId,
        Guid userId,
        ChangeRoleRequest request,
        Guid musicianId)
    {
        await bandAuth.RequireAdminAsync(bandId, musicianId);

        if (userId == musicianId)
            throw new DomainException("CANNOT_CHANGE_OWN_ROLE", "You cannot change your own role.", 400);

        var membership = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == userId && m.IsActive)
            ?? throw new DomainException("MEMBER_NOT_FOUND", "Member not found.", 404);

        // Prevent demoting the last admin
        if (membership.Role == MemberRole.Administrator && request.Role != MemberRole.Administrator)
        {
            var adminCount = await db.Memberships
                .CountAsync(m => m.BandId == bandId && m.IsActive && m.Role == MemberRole.Administrator);
            if (adminCount <= 1)
                throw new DomainException(
                    "LAST_ADMIN",
                    "The last admin cannot be demoted. Promote another admin first.",
                    400);
        }

        membership.Role = request.Role;
        await db.SaveChangesAsync();
    }

    public async Task RemoveMemberAsync(Guid bandId, Guid userId, Guid musicianId)
    {
        var requester = await db.Memberships
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive)
            ?? throw new DomainException("FORBIDDEN", "Band not found or no access.", 403);

        // Only admins can remove others; any member can remove themselves (leave)
        if (userId != musicianId && requester.Role != MemberRole.Administrator)
            throw new AuthException("FORBIDDEN", "Only admins can remove members.", 403);

        // Prevent the last admin from leaving
        if (userId == musicianId && requester.Role == MemberRole.Administrator)
        {
            var adminCount = await db.Memberships
                .CountAsync(m => m.BandId == bandId && m.IsActive && m.Role == MemberRole.Administrator);
            if (adminCount <= 1)
                throw new DomainException(
                    "LAST_ADMIN",
                    "The last admin cannot leave the band. Promote another admin first.",
                    400);
        }

        var target = userId == musicianId
            ? requester
            : await db.Memberships
                .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == userId && m.IsActive)
                ?? throw new DomainException("MEMBER_NOT_FOUND", "Member not found.", 404);

        target.IsActive = false;
        await db.SaveChangesAsync();
    }

    // ── Voices-Mapping ───────────────────────────────────────────────────────

    public async Task<VoiceMappingResponse> GetVoiceMappingAsync(Guid bandId, Guid musicianId)
    {
        await bandAuth.RequireMembershipAsync(bandId, musicianId);

        var entries = await db.BandVoiceMappings
            .Where(m => m.BandId == bandId)
            .OrderBy(m => m.Instrument)
            .Select(m => new VoiceMappingEntry(m.Instrument, m.Voice))
            .ToListAsync();

        return new VoiceMappingResponse(entries);
    }

    public async Task<VoiceMappingResponse> SetVoiceMappingAsync(
        Guid bandId,
        SetVoiceMappingRequest request,
        Guid musicianId)
    {
        await bandAuth.RequireAdminAsync(bandId, musicianId);

        // Replace all existing mappings for this Band atomically
        var existing = await db.BandVoiceMappings
            .Where(m => m.BandId == bandId)
            .ToListAsync();
        db.BandVoiceMappings.RemoveRange(existing);

        var newMappings = request.Entries.Select(e => new BandVoiceMapping
        {
            BandId = bandId,
            Instrument = e.Instrument.Trim(),
            Voice = e.Voice.Trim()
        }).ToList();
        db.BandVoiceMappings.AddRange(newMappings);

        await db.SaveChangesAsync();

        return new VoiceMappingResponse(
            newMappings.OrderBy(m => m.Instrument)
                .Select(m => new VoiceMappingEntry(m.Instrument, m.Voice))
                .ToList());
    }

    public async Task SetUserVoicesAsync(
        Guid bandId,
        Guid userId,
        UserVoicesRequest request,
        Guid musicianId)
    {
        // Admins may set any member's override; members may only set their own
        var requester = await bandAuth.RequireMembershipAsync(bandId, musicianId);

        if (userId != musicianId && requester.Role != MemberRole.Administrator)
            throw new AuthException("FORBIDDEN", "Only admins can set other members' voices.", 403);

        var target = userId == musicianId
            ? requester
            : await db.Memberships
                .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == userId && m.IsActive)
                ?? throw new DomainException("MEMBER_NOT_FOUND", "Member not found.", 404);

        target.VoiceOverride = string.IsNullOrWhiteSpace(request.VoiceOverride)
            ? null
            : request.VoiceOverride.Trim();

        await db.SaveChangesAsync();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static string GenerateCode()
    {
        var bytes = new byte[8];
        RandomNumberGenerator.Fill(bytes);
        return new string(bytes.Select(b => CodeChars[b % CodeChars.Length]).ToArray());
    }
}
