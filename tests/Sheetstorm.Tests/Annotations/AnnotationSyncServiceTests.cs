using Microsoft.EntityFrameworkCore;
using Sheetstorm.Domain.Annotations;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Infrastructure.Annotations;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Annotations;

public class AnnotationSyncServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly AnnotationSyncService _sut;
    private readonly Guid _bandId = Guid.NewGuid();
    private readonly Guid _musicianId = Guid.NewGuid();
    private readonly Guid _otherMusicianId = Guid.NewGuid();
    private readonly Guid _piecePageId = Guid.NewGuid();
    private readonly Guid _pieceId = Guid.NewGuid();
    private readonly Guid _voiceId = Guid.NewGuid();

    public AnnotationSyncServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _db = new AppDbContext(options);

        SeedData();
        _sut = new AnnotationSyncService(_db);
    }

    private void SeedData()
    {
        _db.Musicians.Add(new Musician { Id = _musicianId, Email = "test@test.com", Name = "Test User" });
        _db.Musicians.Add(new Musician { Id = _otherMusicianId, Email = "other@test.com", Name = "Other User" });
        _db.Bands.Add(new Band { Id = _bandId, Name = "Test Band" });
        _db.Memberships.Add(new Membership { MusicianId = _musicianId, BandId = _bandId, Role = MemberRole.Conductor, IsActive = true });
        _db.Memberships.Add(new Membership { MusicianId = _otherMusicianId, BandId = _bandId, Role = MemberRole.Musician, IsActive = true });
        _db.Pieces.Add(new Piece { Id = _pieceId, BandId = _bandId, Title = "Test Piece" });
        _db.PiecePages.Add(new PiecePage { Id = _piecePageId, PieceId = _pieceId, PageNumber = 1, StorageKey = "test" });
        _db.Voices.Add(new Voice { Id = _voiceId, PieceId = _pieceId, Label = "Klarinette 1" });
        _db.SaveChanges();
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Entity Creation ───────────────────────────────────────────────────

    [Fact]
    public void Annotation_HasCorrectDefaults()
    {
        var annotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Voice,
            VoiceId = _voiceId,
            BandId = _bandId,
            CreatedByMusicianId = _musicianId
        };

        Assert.NotEqual(Guid.Empty, annotation.Id);
        Assert.Equal(AnnotationLevel.Voice, annotation.Level);
        Assert.Equal(1L, annotation.Version);
        Assert.Empty(annotation.Elements);
    }

    [Fact]
    public void AnnotationElement_HasCorrectDefaults()
    {
        var element = new AnnotationElement
        {
            AnnotationId = Guid.NewGuid(),
            Tool = AnnotationTool.Pencil,
            BboxX = 0.1,
            BboxY = 0.2,
            BboxWidth = 0.3,
            BboxHeight = 0.4,
            CreatedByMusicianId = _musicianId
        };

        Assert.NotEqual(Guid.Empty, element.Id);
        Assert.Equal(1L, element.Version);
        Assert.False(element.IsDeleted);
        Assert.Equal(1.0, element.Opacity);
        Assert.Equal(3.0, element.StrokeWidth);
    }

    // ── GetAnnotations ────────────────────────────────────────────────────

    [Fact]
    public async Task GetAnnotations_ReturnsVoiceAnnotations()
    {
        var annotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Voice,
            VoiceId = _voiceId,
            BandId = _bandId,
            CreatedByMusicianId = _musicianId
        };
        _db.Set<Annotation>().Add(annotation);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAnnotationsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, _musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(annotation.Id, result[0].Id);
    }

    [Fact]
    public async Task GetAnnotations_NonMember_Throws()
    {
        var outsiderId = Guid.NewGuid();
        _db.Musicians.Add(new Musician { Id = outsiderId, Email = "outsider@test.com", Name = "Outsider" });
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<DomainException>(() =>
            _sut.GetAnnotationsAsync(_bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, outsiderId, CancellationToken.None));
    }

    // ── CreateElement ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateElement_VoiceLevel_CreatesAnnotationAndElement()
    {
        var request = new CreateAnnotationElementRequest(
            PiecePageId: _piecePageId,
            Level: AnnotationLevel.Voice,
            VoiceId: _voiceId,
            Tool: AnnotationTool.Pencil,
            Points: "[{\"x\":0.1,\"y\":0.2}]",
            BboxX: 0.1,
            BboxY: 0.2,
            BboxWidth: 0.5,
            BboxHeight: 0.3,
            Text: null,
            StampCategory: null,
            StampValue: null,
            Opacity: 1.0,
            StrokeWidth: 3.0
        );

        var result = await _sut.CreateElementAsync(_bandId, request, _musicianId, CancellationToken.None);

        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal(AnnotationTool.Pencil, result.Tool);
        Assert.Equal(1L, result.Version);
    }

    [Fact]
    public async Task CreateElement_OrchestraLevel_RequiresConductorOrAdmin()
    {
        var request = new CreateAnnotationElementRequest(
            PiecePageId: _piecePageId,
            Level: AnnotationLevel.Orchestra,
            VoiceId: null,
            Tool: AnnotationTool.Text,
            Points: null,
            BboxX: 0.1,
            BboxY: 0.2,
            BboxWidth: 0.5,
            BboxHeight: 0.3,
            Text: "Forte!",
            StampCategory: null,
            StampValue: null,
            Opacity: 1.0,
            StrokeWidth: 3.0
        );

        // Conductor can create orchestra annotations
        var result = await _sut.CreateElementAsync(_bandId, request, _musicianId, CancellationToken.None);
        Assert.NotEqual(Guid.Empty, result.Id);
    }

    [Fact]
    public async Task CreateElement_OrchestraLevel_MusicianForbidden()
    {
        var request = new CreateAnnotationElementRequest(
            PiecePageId: _piecePageId,
            Level: AnnotationLevel.Orchestra,
            VoiceId: null,
            Tool: AnnotationTool.Pencil,
            Points: "[{\"x\":0.1,\"y\":0.2}]",
            BboxX: 0.1,
            BboxY: 0.2,
            BboxWidth: 0.5,
            BboxHeight: 0.3,
            Text: null,
            StampCategory: null,
            StampValue: null,
            Opacity: 1.0,
            StrokeWidth: 3.0
        );

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.CreateElementAsync(_bandId, request, _otherMusicianId, CancellationToken.None));
        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    [Fact]
    public async Task CreateElement_ReusesExistingAnnotationContainer()
    {
        var annotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Voice,
            VoiceId = _voiceId,
            BandId = _bandId,
            CreatedByMusicianId = _musicianId
        };
        _db.Set<Annotation>().Add(annotation);
        await _db.SaveChangesAsync();

        var request = new CreateAnnotationElementRequest(
            PiecePageId: _piecePageId,
            Level: AnnotationLevel.Voice,
            VoiceId: _voiceId,
            Tool: AnnotationTool.Pencil,
            Points: "[{\"x\":0.1,\"y\":0.2}]",
            BboxX: 0.1, BboxY: 0.2, BboxWidth: 0.5, BboxHeight: 0.3,
            Text: null, StampCategory: null, StampValue: null,
            Opacity: 1.0, StrokeWidth: 3.0
        );

        var result = await _sut.CreateElementAsync(_bandId, request, _musicianId, CancellationToken.None);
        Assert.Equal(annotation.Id, result.AnnotationId);
    }

    // ── UpdateElement (LWW Conflict Resolution) ───────────────────────────

    [Fact]
    public async Task UpdateElement_SameVersion_Succeeds()
    {
        var (annotationId, elementId) = await CreateTestElement();

        var request = new UpdateAnnotationElementRequest(
            Version: 1,
            BboxX: 0.5, BboxY: 0.6, BboxWidth: 0.7, BboxHeight: 0.8,
            Points: null, Text: null, StampCategory: null, StampValue: null,
            Opacity: 0.8, StrokeWidth: 5.0
        );

        var result = await _sut.UpdateElementAsync(
            _bandId, annotationId, elementId, request, _musicianId, CancellationToken.None);

        Assert.Equal(2L, result.Version);
        Assert.Equal(0.5, result.BboxX);
    }

    [Fact]
    public async Task UpdateElement_StaleVersion_ThrowsConflict()
    {
        var (annotationId, elementId) = await CreateTestElement();

        // First update bumps version to 2
        var request1 = new UpdateAnnotationElementRequest(
            Version: 1, BboxX: 0.5, BboxY: 0.6, BboxWidth: 0.7, BboxHeight: 0.8,
            Points: null, Text: null, StampCategory: null, StampValue: null,
            Opacity: 0.8, StrokeWidth: 5.0
        );
        await _sut.UpdateElementAsync(_bandId, annotationId, elementId, request1, _musicianId, CancellationToken.None);

        // Second update with stale version = 1 should fail
        var request2 = new UpdateAnnotationElementRequest(
            Version: 1, BboxX: 0.9, BboxY: 0.9, BboxWidth: 0.9, BboxHeight: 0.9,
            Points: null, Text: null, StampCategory: null, StampValue: null,
            Opacity: 1.0, StrokeWidth: 3.0
        );

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateElementAsync(_bandId, annotationId, elementId, request2, _otherMusicianId, CancellationToken.None));
        Assert.Equal("CONFLICT", ex.ErrorCode);
        Assert.Equal(409, ex.StatusCode);
    }

    [Fact]
    public async Task UpdateElement_NotFound_Throws()
    {
        var (annotationId, _) = await CreateTestElement();

        var request = new UpdateAnnotationElementRequest(
            Version: 1, BboxX: 0.5, BboxY: 0.6, BboxWidth: 0.7, BboxHeight: 0.8,
            Points: null, Text: null, StampCategory: null, StampValue: null,
            Opacity: 0.8, StrokeWidth: 5.0
        );

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.UpdateElementAsync(_bandId, annotationId, Guid.NewGuid(), request, _musicianId, CancellationToken.None));
        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteElement (Soft-Delete) ───────────────────────────────────────

    [Fact]
    public async Task DeleteElement_SoftDeletes()
    {
        var (annotationId, elementId) = await CreateTestElement();

        await _sut.DeleteElementAsync(_bandId, annotationId, elementId, _musicianId, CancellationToken.None);

        var element = await _db.Set<AnnotationElement>().FindAsync(elementId);
        Assert.NotNull(element);
        Assert.True(element.IsDeleted);
    }

    [Fact]
    public async Task DeleteElement_AlreadyDeleted_Throws()
    {
        var (annotationId, elementId) = await CreateTestElement();
        await _sut.DeleteElementAsync(_bandId, annotationId, elementId, _musicianId, CancellationToken.None);

        var ex = await Assert.ThrowsAsync<DomainException>(() =>
            _sut.DeleteElementAsync(_bandId, annotationId, elementId, _musicianId, CancellationToken.None));
        Assert.Equal("NOT_FOUND", ex.ErrorCode);
    }

    // ── Sync (Delta) ─────────────────────────────────────────────────────

    [Fact]
    public async Task SyncElements_ReturnsDeltaSinceVersion()
    {
        var (annotationId, element1Id) = await CreateTestElement();

        // Update element to bump version to 2
        var updateReq = new UpdateAnnotationElementRequest(
            Version: 1, BboxX: 0.5, BboxY: 0.6, BboxWidth: 0.7, BboxHeight: 0.8,
            Points: null, Text: null, StampCategory: null, StampValue: null,
            Opacity: 0.8, StrokeWidth: 5.0
        );
        await _sut.UpdateElementAsync(_bandId, annotationId, element1Id, updateReq, _musicianId, CancellationToken.None);

        // Sync with sinceVersion=0 should return all
        var result = await _sut.SyncElementsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, 0, _musicianId, CancellationToken.None);

        Assert.NotEmpty(result.Elements);
        Assert.True(result.CurrentVersion > 0);
    }

    [Fact]
    public async Task SyncElements_SinceHighVersion_ReturnsEmpty()
    {
        await CreateTestElement();

        var result = await _sut.SyncElementsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, 9999, _musicianId, CancellationToken.None);

        Assert.Empty(result.Elements);
    }

    // ── Private Annotations (no band scope) ──────────────────────────────

    [Fact]
    public async Task GetPersonalAnnotations_ReturnsOnlyOwnAnnotations()
    {
        var annotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Private,
            CreatedByMusicianId = _musicianId
        };
        _db.Set<Annotation>().Add(annotation);

        var otherAnnotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Private,
            CreatedByMusicianId = _otherMusicianId
        };
        _db.Set<Annotation>().Add(otherAnnotation);
        await _db.SaveChangesAsync();

        var result = await _sut.GetPersonalAnnotationsAsync(_piecePageId, _musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Equal(_musicianId, result[0].CreatedByMusicianId);
    }

    // ── Edge Cases ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetAnnotations_ExcludesSoftDeletedElements()
    {
        var annotation = new Annotation
        {
            PiecePageId = _piecePageId,
            Level = AnnotationLevel.Voice,
            VoiceId = _voiceId,
            BandId = _bandId,
            CreatedByMusicianId = _musicianId,
            Elements =
            [
                new AnnotationElement
                {
                    Tool = AnnotationTool.Pencil,
                    BboxX = 0.1, BboxY = 0.2, BboxWidth = 0.3, BboxHeight = 0.4,
                    CreatedByMusicianId = _musicianId,
                    IsDeleted = false
                },
                new AnnotationElement
                {
                    Tool = AnnotationTool.Text,
                    BboxX = 0.5, BboxY = 0.6, BboxWidth = 0.7, BboxHeight = 0.8,
                    CreatedByMusicianId = _musicianId,
                    IsDeleted = true
                }
            ]
        };
        _db.Set<Annotation>().Add(annotation);
        await _db.SaveChangesAsync();

        var result = await _sut.GetAnnotationsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, _musicianId, CancellationToken.None);

        Assert.Single(result);
        Assert.Single(result[0].Elements);
        Assert.False(result[0].Elements[0].IsDeleted);
    }

    [Fact]
    public async Task SyncElements_IncludesSoftDeletedElements()
    {
        // Sync must include deleted elements so clients can remove them
        var (annotationId, elementId) = await CreateTestElement();
        await _sut.DeleteElementAsync(_bandId, annotationId, elementId, _musicianId, CancellationToken.None);

        var result = await _sut.SyncElementsAsync(
            _bandId, _piecePageId, AnnotationLevel.Voice, _voiceId, 0, _musicianId, CancellationToken.None);

        Assert.Single(result.Elements);
        Assert.True(result.Elements[0].IsDeleted);
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private async Task<(Guid AnnotationId, Guid ElementId)> CreateTestElement()
    {
        var request = new CreateAnnotationElementRequest(
            PiecePageId: _piecePageId,
            Level: AnnotationLevel.Voice,
            VoiceId: _voiceId,
            Tool: AnnotationTool.Pencil,
            Points: "[{\"x\":0.1,\"y\":0.2}]",
            BboxX: 0.1, BboxY: 0.2, BboxWidth: 0.5, BboxHeight: 0.3,
            Text: null, StampCategory: null, StampValue: null,
            Opacity: 1.0, StrokeWidth: 3.0
        );

        var result = await _sut.CreateElementAsync(_bandId, request, _musicianId, CancellationToken.None);
        return (result.AnnotationId, result.Id);
    }
}
