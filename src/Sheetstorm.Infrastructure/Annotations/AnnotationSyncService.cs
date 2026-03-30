using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Infrastructure.Annotations;

public class AnnotationSyncService(AppDbContext db) : IAnnotationSyncService
{
    // ── Band-scoped: Get Annotations ─────────────────────────────────────

    public async Task<IReadOnlyList<AnnotationDto>> GetAnnotationsAsync(
        Guid bandId, Guid piecePageId, AnnotationLevel level, Guid? voiceId,
        Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var query = db.Set<Annotation>()
            .Include(a => a.Elements)
            .Where(a => a.PiecePageId == piecePageId && a.Level == level && a.BandId == bandId);

        if (level == AnnotationLevel.Voice && voiceId.HasValue)
            query = query.Where(a => a.VoiceId == voiceId.Value);

        var annotations = await query.ToListAsync(ct);

        return annotations.Select(a => MapToDto(a, excludeDeleted: true)).ToList();
    }

    // ── Band-scoped: Create Element ──────────────────────────────────────

    public async Task<AnnotationElementDto> CreateElementAsync(
        Guid bandId, CreateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct)
    {
        if (request.Level == AnnotationLevel.Orchestra)
            await RequireConductorOrAdminAsync(bandId, musicianId, ct);
        else
            await RequireMembershipAsync(bandId, musicianId, ct);

        var annotation = await GetOrCreateAnnotationAsync(
            request.PiecePageId, request.Level, request.VoiceId, bandId, musicianId, ct);

        var element = new AnnotationElement
        {
            AnnotationId = annotation.Id,
            Tool = request.Tool,
            Points = request.Points,
            BboxX = request.BboxX,
            BboxY = request.BboxY,
            BboxWidth = request.BboxWidth,
            BboxHeight = request.BboxHeight,
            Text = request.Text,
            StampCategory = request.StampCategory,
            StampValue = request.StampValue,
            Opacity = request.Opacity,
            StrokeWidth = request.StrokeWidth,
            CreatedByMusicianId = musicianId
        };

        db.Set<AnnotationElement>().Add(element);
        annotation.Version++;
        await db.SaveChangesAsync(ct);

        return MapElementToDto(element);
    }

    // ── Band-scoped: Update Element (LWW with optimistic concurrency) ────

    public async Task<AnnotationElementDto> UpdateElementAsync(
        Guid bandId, Guid annotationId, Guid elementId,
        UpdateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var element = await db.Set<AnnotationElement>()
            .Include(e => e.Annotation)
            .FirstOrDefaultAsync(e => e.Id == elementId
                && e.AnnotationId == annotationId
                && !e.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Annotation element not found.", 404);

        // Optimistic concurrency: reject stale versions
        if (element.Version != request.Version)
            throw new DomainException("CONFLICT",
                $"Version conflict. Server version: {element.Version}, your version: {request.Version}.", 409);

        element.BboxX = request.BboxX;
        element.BboxY = request.BboxY;
        element.BboxWidth = request.BboxWidth;
        element.BboxHeight = request.BboxHeight;
        element.Points = request.Points ?? element.Points;
        element.Text = request.Text ?? element.Text;
        element.StampCategory = request.StampCategory ?? element.StampCategory;
        element.StampValue = request.StampValue ?? element.StampValue;
        element.Opacity = request.Opacity;
        element.StrokeWidth = request.StrokeWidth;
        element.Version++;

        element.Annotation.Version++;
        await db.SaveChangesAsync(ct);

        return MapElementToDto(element);
    }

    // ── Band-scoped: Delete Element (Soft-Delete) ────────────────────────

    public async Task DeleteElementAsync(
        Guid bandId, Guid annotationId, Guid elementId,
        Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var element = await db.Set<AnnotationElement>()
            .Include(e => e.Annotation)
            .FirstOrDefaultAsync(e => e.Id == elementId
                && e.AnnotationId == annotationId
                && !e.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Annotation element not found.", 404);

        element.IsDeleted = true;
        element.Version++;
        element.Annotation.Version++;
        await db.SaveChangesAsync(ct);
    }

    // ── Band-scoped: Sync (Delta) ────────────────────────────────────────

    public async Task<AnnotationSyncResponse> SyncElementsAsync(
        Guid bandId, Guid piecePageId, AnnotationLevel level, Guid? voiceId,
        long sinceVersion, Guid musicianId, CancellationToken ct)
    {
        await RequireMembershipAsync(bandId, musicianId, ct);

        var query = db.Set<AnnotationElement>()
            .Include(e => e.Annotation)
            .Where(e => e.Annotation.PiecePageId == piecePageId
                && e.Annotation.Level == level
                && e.Annotation.BandId == bandId
                && e.Version > sinceVersion);

        if (level == AnnotationLevel.Voice && voiceId.HasValue)
            query = query.Where(e => e.Annotation.VoiceId == voiceId.Value);

        var elements = await query.OrderBy(e => e.Version).ToListAsync(ct);
        var currentVersion = elements.Count > 0
            ? elements.Max(e => e.Version)
            : sinceVersion;

        return new AnnotationSyncResponse(
            elements.Select(MapElementToDto).ToList(),
            currentVersion
        );
    }

    // ── Personal Annotations ─────────────────────────────────────────────

    public async Task<IReadOnlyList<AnnotationDto>> GetPersonalAnnotationsAsync(
        Guid piecePageId, Guid musicianId, CancellationToken ct)
    {
        var annotations = await db.Set<Annotation>()
            .Include(a => a.Elements)
            .Where(a => a.PiecePageId == piecePageId
                && a.Level == AnnotationLevel.Private
                && a.CreatedByMusicianId == musicianId)
            .ToListAsync(ct);

        return annotations.Select(a => MapToDto(a, excludeDeleted: true)).ToList();
    }

    public async Task<AnnotationElementDto> CreatePersonalElementAsync(
        Guid piecePageId, CreateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct)
    {
        var annotation = await GetOrCreateAnnotationAsync(
            piecePageId, AnnotationLevel.Private, null, null, musicianId, ct);

        var element = new AnnotationElement
        {
            AnnotationId = annotation.Id,
            Tool = request.Tool,
            Points = request.Points,
            BboxX = request.BboxX,
            BboxY = request.BboxY,
            BboxWidth = request.BboxWidth,
            BboxHeight = request.BboxHeight,
            Text = request.Text,
            StampCategory = request.StampCategory,
            StampValue = request.StampValue,
            Opacity = request.Opacity,
            StrokeWidth = request.StrokeWidth,
            CreatedByMusicianId = musicianId
        };

        db.Set<AnnotationElement>().Add(element);
        annotation.Version++;
        await db.SaveChangesAsync(ct);

        return MapElementToDto(element);
    }

    public async Task<AnnotationElementDto> UpdatePersonalElementAsync(
        Guid elementId, UpdateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct)
    {
        var element = await db.Set<AnnotationElement>()
            .Include(e => e.Annotation)
            .FirstOrDefaultAsync(e => e.Id == elementId
                && e.Annotation.Level == AnnotationLevel.Private
                && e.Annotation.CreatedByMusicianId == musicianId
                && !e.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Annotation element not found.", 404);

        if (element.Version != request.Version)
            throw new DomainException("CONFLICT",
                $"Version conflict. Server version: {element.Version}, your version: {request.Version}.", 409);

        element.BboxX = request.BboxX;
        element.BboxY = request.BboxY;
        element.BboxWidth = request.BboxWidth;
        element.BboxHeight = request.BboxHeight;
        element.Points = request.Points ?? element.Points;
        element.Text = request.Text ?? element.Text;
        element.StampCategory = request.StampCategory ?? element.StampCategory;
        element.StampValue = request.StampValue ?? element.StampValue;
        element.Opacity = request.Opacity;
        element.StrokeWidth = request.StrokeWidth;
        element.Version++;

        element.Annotation.Version++;
        await db.SaveChangesAsync(ct);

        return MapElementToDto(element);
    }

    public async Task DeletePersonalElementAsync(
        Guid elementId, Guid musicianId, CancellationToken ct)
    {
        var element = await db.Set<AnnotationElement>()
            .Include(e => e.Annotation)
            .FirstOrDefaultAsync(e => e.Id == elementId
                && e.Annotation.Level == AnnotationLevel.Private
                && e.Annotation.CreatedByMusicianId == musicianId
                && !e.IsDeleted, ct)
            ?? throw new DomainException("NOT_FOUND", "Annotation element not found.", 404);

        element.IsDeleted = true;
        element.Version++;
        element.Annotation.Version++;
        await db.SaveChangesAsync(ct);
    }

    // ── Private Helpers ──────────────────────────────────────────────────

    private async Task<Annotation> GetOrCreateAnnotationAsync(
        Guid piecePageId, AnnotationLevel level, Guid? voiceId, Guid? bandId,
        Guid musicianId, CancellationToken ct)
    {
        var annotation = await db.Set<Annotation>()
            .FirstOrDefaultAsync(a =>
                a.PiecePageId == piecePageId
                && a.Level == level
                && a.VoiceId == voiceId
                && a.BandId == bandId, ct);

        if (annotation != null)
            return annotation;

        annotation = new Annotation
        {
            PiecePageId = piecePageId,
            Level = level,
            VoiceId = voiceId,
            BandId = bandId,
            CreatedByMusicianId = musicianId
        };

        db.Set<Annotation>().Add(annotation);
        await db.SaveChangesAsync(ct);
        return annotation;
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

    private static AnnotationDto MapToDto(Annotation a, bool excludeDeleted)
    {
        var elements = excludeDeleted
            ? a.Elements.Where(e => !e.IsDeleted).ToList()
            : a.Elements.ToList();

        return new AnnotationDto(
            a.Id,
            a.PiecePageId,
            a.Level,
            a.VoiceId,
            a.BandId,
            a.CreatedByMusicianId,
            a.Version,
            elements.Select(MapElementToDto).ToList()
        );
    }

    private static AnnotationElementDto MapElementToDto(AnnotationElement e) => new(
        e.Id,
        e.AnnotationId,
        e.Tool,
        e.Points,
        e.BboxX,
        e.BboxY,
        e.BboxWidth,
        e.BboxHeight,
        e.Text,
        e.StampCategory,
        e.StampValue,
        e.Opacity,
        e.StrokeWidth,
        e.Version,
        e.CreatedByMusicianId,
        e.IsDeleted,
        e.CreatedAt,
        e.UpdatedAt
    );
}
