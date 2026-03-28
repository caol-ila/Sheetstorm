using System.Security.Cryptography;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Substitutes;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Substitutes;

public class SubstituteService(AppDbContext db) : ISubstituteService
{
    public async Task<SubstituteAccessCreatedDto> CreateAccessAsync(Guid bandId, CreateSubstituteAccessRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        // Generate a cryptographically secure token
        var rawTokenBytes = RandomNumberGenerator.GetBytes(32);
        var rawToken = WebEncoders.Base64UrlEncode(rawTokenBytes);

        // Store only the SHA-256 hash
        var tokenHash = HashToken(rawToken);

        var expiresAt = request.ExpiresAt ?? DateTime.UtcNow.AddDays(2);
        if (expiresAt <= DateTime.UtcNow)
            throw new DomainException("VALIDATION_ERROR", "Expiry date must be in the future.", 400);

        var access = new SubstituteAccess
        {
            BandId = bandId,
            Token = tokenHash,
            Name = request.Name.Trim(),
            Email = request.Email?.Trim(),
            VoiceId = request.VoiceId,
            EventId = request.EventId,
            GrantedByMusicianId = musicianId,
            ExpiresAt = expiresAt,
            IsActive = true,
            Instrument = request.Instrument?.Trim(),
            Note = request.Note?.Trim()
        };

        db.Set<SubstituteAccess>().Add(access);
        await db.SaveChangesAsync(ct);

        var link = $"https://app.sheetstorm.io/aushilfe/{rawToken}";
        var qrCodeData = $"data:text/plain;base64,{Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(link))}";

        return new SubstituteAccessCreatedDto(
            access.Id,
            access.BandId,
            access.Name,
            access.Email,
            access.VoiceId,
            access.EventId,
            rawToken,
            link,
            qrCodeData,
            access.ExpiresAt,
            access.IsActive,
            access.Instrument,
            access.Note,
            access.CreatedAt
        );
    }

    public async Task<SubstituteValidationDto> ValidateTokenAsync(string rawToken, CancellationToken ct)
    {
        var tokenHash = HashToken(rawToken);

        var access = await db.Set<SubstituteAccess>()
            .Include(a => a.Band)
            .Include(a => a.Voice)
            .Include(a => a.Event)
            .FirstOrDefaultAsync(a => a.Token == tokenHash, ct)
            ?? throw new DomainException("NOT_FOUND", "Invalid or unknown access token.", 404);

        if (access.RevokedAt.HasValue)
            throw new DomainException("FORBIDDEN", "This access has been revoked.", 403);

        if (access.ExpiresAt < DateTime.UtcNow)
            throw new DomainException("FORBIDDEN", "This access has expired.", 410);

        if (!access.IsActive)
            throw new DomainException("FORBIDDEN", "This access is no longer active.", 403);

        // Update last accessed
        access.LastAccessedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return new SubstituteValidationDto(
            access.Id,
            access.Name,
            access.Instrument,
            access.BandId,
            access.Band.Name,
            access.VoiceId,
            access.Voice?.Label,
            access.EventId,
            access.Event?.Title,
            access.Event?.StartDate,
            access.Note,
            access.ExpiresAt
        );
    }

    public async Task RevokeAccessAsync(Guid bandId, Guid accessId, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var access = await db.Set<SubstituteAccess>()
            .FirstOrDefaultAsync(a => a.Id == accessId && a.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Substitute access not found.", 404);

        if (access.RevokedAt.HasValue)
            throw new DomainException("CONFLICT", "Access has already been revoked.", 409);

        access.RevokedAt = DateTime.UtcNow;
        access.IsActive = false;
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<SubstituteAccessDto>> GetActiveAccessesAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var accesses = await db.Set<SubstituteAccess>()
            .Where(a => a.BandId == bandId)
            .Include(a => a.Voice)
            .Include(a => a.Event)
            .Include(a => a.GrantedByMusician)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(ct);

        return accesses.Select(a => new SubstituteAccessDto(
            a.Id,
            a.BandId,
            a.Name,
            a.Email,
            a.VoiceId,
            a.Voice?.Label,
            a.EventId,
            a.Event?.Title,
            a.GrantedByMusicianId,
            a.GrantedByMusician.Name,
            a.ExpiresAt,
            a.RevokedAt,
            a.IsActive && !a.RevokedAt.HasValue && a.ExpiresAt > DateTime.UtcNow,
            a.LastAccessedAt,
            a.Instrument,
            a.Note,
            a.CreatedAt
        )).ToList();
    }

    public async Task<SubstituteAccessDto> ExtendAccessAsync(Guid bandId, Guid accessId, ExtendSubstituteAccessRequest request, Guid musicianId, CancellationToken ct)
    {
        await RequireConductorOrAdminAsync(bandId, musicianId, ct);

        var access = await db.Set<SubstituteAccess>()
            .Include(a => a.Voice)
            .Include(a => a.Event)
            .Include(a => a.GrantedByMusician)
            .FirstOrDefaultAsync(a => a.Id == accessId && a.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Substitute access not found.", 404);

        if (access.RevokedAt.HasValue)
            throw new DomainException("CONFLICT", "Cannot extend a revoked access.", 409);

        if (request.ExpiresAt <= DateTime.UtcNow)
            throw new DomainException("VALIDATION_ERROR", "New expiry date must be in the future.", 400);

        access.ExpiresAt = request.ExpiresAt;
        access.IsActive = true;
        await db.SaveChangesAsync(ct);

        return new SubstituteAccessDto(
            access.Id,
            access.BandId,
            access.Name,
            access.Email,
            access.VoiceId,
            access.Voice?.Label,
            access.EventId,
            access.Event?.Title,
            access.GrantedByMusicianId,
            access.GrantedByMusician.Name,
            access.ExpiresAt,
            access.RevokedAt,
            access.IsActive,
            access.LastAccessedAt,
            access.Instrument,
            access.Note,
            access.CreatedAt
        );
    }

    // ── Private Helpers ──────────────────────────────────────────────────────

    private static string HashToken(string rawToken)
    {
        var bytes = System.Text.Encoding.UTF8.GetBytes(rawToken);
        var hash = SHA256.HashData(bytes);
        return Convert.ToBase64String(hash);
    }

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
