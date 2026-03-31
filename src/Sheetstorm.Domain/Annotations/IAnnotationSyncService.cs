using Sheetstorm.Domain.Enums;

namespace Sheetstorm.Domain.Annotations;

public interface IAnnotationSyncService
{
    // Band-scoped annotations (Voice + Orchestra)
    Task<IReadOnlyList<AnnotationDto>> GetAnnotationsAsync(
        Guid bandId, Guid piecePageId, AnnotationLevel level, Guid? voiceId,
        Guid musicianId, CancellationToken ct);

    Task<AnnotationElementDto> CreateElementAsync(
        Guid bandId, CreateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct);

    Task<AnnotationElementDto> UpdateElementAsync(
        Guid bandId, Guid annotationId, Guid elementId,
        UpdateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct);

    Task DeleteElementAsync(
        Guid bandId, Guid annotationId, Guid elementId,
        Guid musicianId, CancellationToken ct);

    Task<AnnotationSyncResponse> SyncElementsAsync(
        Guid bandId, Guid piecePageId, AnnotationLevel level, Guid? voiceId,
        long sinceVersion, Guid musicianId, CancellationToken ct);

    // Personal annotations (Private level, no band scope)
    Task<IReadOnlyList<AnnotationDto>> GetPersonalAnnotationsAsync(
        Guid piecePageId, Guid musicianId, CancellationToken ct);

    Task<AnnotationElementDto> CreatePersonalElementAsync(
        Guid piecePageId, CreateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct);

    Task<AnnotationElementDto> UpdatePersonalElementAsync(
        Guid elementId, UpdateAnnotationElementRequest request,
        Guid musicianId, CancellationToken ct);

    Task DeletePersonalElementAsync(
        Guid elementId, Guid musicianId, CancellationToken ct);
}
