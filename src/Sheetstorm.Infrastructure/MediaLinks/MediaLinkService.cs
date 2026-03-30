using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.MediaLinks;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.MediaLinks;

public class MediaLinkService(AppDbContext db) : IMediaLinkService
{
    public async Task<IReadOnlyList<MediaLinkDto>> GetAllForPieceAsync(Guid bandId, Guid pieceId, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var piece = await db.Set<Piece>()
            .FirstOrDefaultAsync(p => p.Id == pieceId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Piece not found.", 404);

        return await db.Set<MediaLink>()
            .Include(m => m.AddedByMusician)
            .Where(m => m.PieceId == pieceId && m.BandId == bandId)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new MediaLinkDto(
                m.Id,
                m.Url,
                m.Type,
                m.Title,
                m.Description,
                m.ThumbnailUrl,
                m.DurationSeconds,
                m.AddedByMusicianId,
                m.AddedByMusician.Name,
                m.CreatedAt
            ))
            .ToListAsync(ct);
    }

    public async Task<MediaLinkDto> CreateAsync(Guid bandId, Guid pieceId, CreateMediaLinkRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SheetMusicManager)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and sheet music managers can add media links.", 403);

        var piece = await db.Set<Piece>()
            .FirstOrDefaultAsync(p => p.Id == pieceId && p.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Piece not found.", 404);

        var url = request.Url.Trim();
        var existingLink = await db.Set<MediaLink>()
            .FirstOrDefaultAsync(m => m.PieceId == pieceId && m.Url == url, ct);

        if (existingLink != null)
            throw new DomainException("CONFLICT", "This link already exists for this piece.", 409);

        var linkType = DetermineMediaLinkType(url);

        var mediaLink = new MediaLink
        {
            PieceId = pieceId,
            BandId = bandId,
            Url = url,
            Type = linkType,
            Title = request.Title?.Trim(),
            Description = request.Description?.Trim(),
            AddedByMusicianId = musicianId
        };

        db.Set<MediaLink>().Add(mediaLink);
        await db.SaveChangesAsync(ct);

        var musician = await db.Set<Musician>().FindAsync(new object[] { musicianId }, ct);

        return new MediaLinkDto(
            mediaLink.Id,
            mediaLink.Url,
            mediaLink.Type,
            mediaLink.Title,
            mediaLink.Description,
            mediaLink.ThumbnailUrl,
            mediaLink.DurationSeconds,
            musicianId,
            musician!.Name,
            mediaLink.CreatedAt
        );
    }

    public async Task<MediaLinkDto> UpdateAsync(Guid bandId, Guid pieceId, Guid linkId, UpdateMediaLinkRequest request, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SheetMusicManager)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and sheet music managers can update media links.", 403);

        var mediaLink = await db.Set<MediaLink>()
            .Include(m => m.AddedByMusician)
            .FirstOrDefaultAsync(m => m.Id == linkId && m.PieceId == pieceId && m.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Media link not found.", 404);

        mediaLink.Title = request.Title?.Trim();
        mediaLink.Description = request.Description?.Trim();

        await db.SaveChangesAsync(ct);

        return new MediaLinkDto(
            mediaLink.Id,
            mediaLink.Url,
            mediaLink.Type,
            mediaLink.Title,
            mediaLink.Description,
            mediaLink.ThumbnailUrl,
            mediaLink.DurationSeconds,
            mediaLink.AddedByMusicianId,
            mediaLink.AddedByMusician.Name,
            mediaLink.CreatedAt
        );
    }

    public async Task DeleteAsync(Guid bandId, Guid pieceId, Guid linkId, Guid musicianId, CancellationToken ct)
    {
        var membership = await RequireMembershipAsync(bandId, musicianId, ct);

        if (membership.Role != MemberRole.Administrator && 
            membership.Role != MemberRole.Conductor && 
            membership.Role != MemberRole.SheetMusicManager)
            throw new DomainException("FORBIDDEN", "Only admins, conductors, and sheet music managers can delete media links.", 403);

        var mediaLink = await db.Set<MediaLink>()
            .FirstOrDefaultAsync(m => m.Id == linkId && m.PieceId == pieceId && m.BandId == bandId, ct)
            ?? throw new DomainException("NOT_FOUND", "Media link not found.", 404);

        db.Set<MediaLink>().Remove(mediaLink);
        await db.SaveChangesAsync(ct);
    }

    private async Task<Membership> RequireMembershipAsync(Guid bandId, Guid musicianId, CancellationToken ct)
    {
        var m = await db.Set<Membership>()
            .FirstOrDefaultAsync(m => m.BandId == bandId && m.MusicianId == musicianId && m.IsActive, ct);

        return m ?? throw new DomainException("BAND_NOT_FOUND", "Band not found or no access.", 404);
    }

    private static MediaLinkType DetermineMediaLinkType(string url)
    {
        var lowerUrl = url.ToLowerInvariant();

        if (lowerUrl.Contains("youtube.com") || lowerUrl.Contains("youtu.be"))
            return MediaLinkType.YouTube;

        if (lowerUrl.Contains("spotify.com"))
            return MediaLinkType.Spotify;

        if (lowerUrl.Contains("soundcloud.com"))
            return MediaLinkType.SoundCloud;

        if (lowerUrl.Contains("music.apple.com"))
            return MediaLinkType.AppleMusic;

        return MediaLinkType.Other;
    }
}
