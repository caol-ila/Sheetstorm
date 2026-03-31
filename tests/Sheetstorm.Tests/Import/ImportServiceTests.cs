using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Import;
using Sheetstorm.Infrastructure.Import;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Persistence;

namespace Sheetstorm.Tests.Import;

public class ImportServiceTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly IStorageService _storage;
    private readonly IAiMetadataService _ai;
    private readonly ILogger<ImportService> _logger;
    private readonly ImportService _sut;

    public ImportServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _db = new AppDbContext(options);
        _storage = Substitute.For<IStorageService>();
        _ai = Substitute.For<IAiMetadataService>();
        _logger = Substitute.For<ILogger<ImportService>>();
        _sut = new ImportService(_db, new BandAuthorizationService(_db), _storage, _ai, _logger);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musicianId, Guid bandId)> SeedMitgliedAsync()
    {
        var musician = new Musician { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test" };
        var band = new Band { Name = "Test Band" };
        var mitglied = new Membership { Musician = musician, Band = band, IsActive = true };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(mitglied);
        await _db.SaveChangesAsync();
        return (musician.Id, band.Id);
    }

    private void SetupStorageUpload(string key = "storage/test.pdf")
        => _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(key);

    private void SetupAiSuccess(string? titel = "AI Title")
        => _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(titel, "Composer", "C-Dur", "4/4", 120));

    // ── ImportAsync: File Upload ───────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_ValidFile_KapelleScope_CreatesStueckWithCorrectOwnership()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        SetupAiSuccess("Böhmischer Traum");

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", bandId, musicianId);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Equal(bandId, piece.BandId);
        Assert.Null(piece.MusicianId); // Band-scoped: no personal owner
        Assert.Equal("test.pdf", piece.OriginalFileName);
    }

    [Fact]
    public async Task ImportAsync_PersonalScope_NullBandId_SetsMusikerOwner()
    {
        var musician = new Musician { Email = "personal@test.com", Name = "Personal" };
        _db.Musicians.Add(musician);
        await _db.SaveChangesAsync();

        SetupStorageUpload();
        SetupAiSuccess();

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "personal.pdf", "application/pdf", null, musician.Id);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Null(piece.BandId);
        Assert.Equal(musician.Id, piece.MusicianId);
    }

    [Fact]
    public async Task ImportAsync_UploadedFile_StorageKeyIsPersisted()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload("uploads/2024/song.pdf");
        SetupAiSuccess();

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "song.pdf", "application/pdf", bandId, musicianId);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Equal("uploads/2024/song.pdf", piece.StorageKey);
    }

    [Fact]
    public async Task ImportAsync_NotAMember_ThrowsDomainException()
    {
        var band = new Band { Name = "Foreign Band" };
        _db.Bands.Add(band);
        await _db.SaveChangesAsync();

        using var stream = new MemoryStream([1, 2, 3]);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ImportAsync(stream, "test.pdf", "application/pdf", band.Id, Guid.NewGuid()));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
        Assert.Equal(403, ex.StatusCode);
    }

    [Fact]
    public async Task ImportAsync_InactiveMembership_ThrowsDomainException()
    {
        var musician = new Musician { Email = "inactive@test.com", Name = "Inactive" };
        var band = new Band { Name = "Band" };
        var mitglied = new Membership { Musician = musician, Band = band, IsActive = false };
        _db.Musicians.Add(musician);
        _db.Bands.Add(band);
        _db.Memberships.Add(mitglied);
        await _db.SaveChangesAsync();

        using var stream = new MemoryStream([1, 2, 3]);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ImportAsync(stream, "test.pdf", "application/pdf", band.Id, musician.Id));

        Assert.Equal("FORBIDDEN", ex.ErrorCode);
    }

    // ── ImportAsync: State Machine ────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_StateMachine_PendingThenProcessingDuringAi_ThenCompleted()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();

        ImportStatus? statusDuringAi = null;
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(async _ =>
            {
                // Status should be Processing while AI runs
                statusDuringAi = (await _db.Pieces.FirstOrDefaultAsync())?.ImportStatus;
                return new PieceMetadataDto("Title", null, null, null, null);
            });

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal(ImportStatus.Processing, statusDuringAi);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
    }

    [Fact]
    public async Task ImportAsync_AiExtractionFails_SetsStueckStatusToFailed()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("AI service unavailable"));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal(ImportStatus.Failed, result.ImportStatus);
        Assert.Null(result.ExtractedMetadata);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Equal(ImportStatus.Failed, piece.ImportStatus);
    }

    [Fact]
    public async Task ImportAsync_AiFailure_StueckIsStillPersisted()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload("uploads/orphan.pdf");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new InvalidOperationException("Timeout"));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "orphan.pdf", "application/pdf", bandId, musicianId);

        Assert.True(await _db.Pieces.AnyAsync(s => s.Id == result.PieceId));
    }

    // ── ImportAsync: AI Metadata Extraction ──────────────────────────────────

    [Fact]
    public async Task ImportAsync_AiReturnsFullMetadata_AllFieldsApplied()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto("Tiroler Polka", "Franz Müller", "G-Dur", "3/4", 138));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "song.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal("Tiroler Polka", result.Title);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
        Assert.NotNull(result.ExtractedMetadata);
        Assert.Equal("Franz Müller", result.ExtractedMetadata!.Composer);
        Assert.Equal("G-Dur", result.ExtractedMetadata.MusicalKey);
        Assert.Equal("3/4", result.ExtractedMetadata.TimeSignature);
        Assert.Equal(138, result.ExtractedMetadata.Tempo);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Equal("Tiroler Polka", piece.Title);
        Assert.Equal("Franz Müller", piece.Composer);
        Assert.Equal("G-Dur", piece.MusicalKey);
        Assert.Equal("3/4", piece.TimeSignature);
        Assert.Equal(138, piece.Tempo);
    }

    [Fact]
    public async Task ImportAsync_AiReturnsTitleNull_TitleFallsBackToFileName()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "My Polka.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal("My Polka", result.Title);
    }

    [Fact]
    public async Task ImportAsync_AiReturnsTitleWhitespaceOnly_TitleFallsBackToFileName()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto("   ", null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "Fallback.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal("Fallback", result.Title);
    }

    [Fact]
    public async Task ImportAsync_SeekableStream_StreamIsResetToZeroBeforeAi()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        SetupStorageUpload();

        long? positionDuringAi = null;
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(callInfo =>
            {
                positionDuringAi = callInfo.Arg<Stream>().Position;
                return Task.FromResult(new PieceMetadataDto(null, null, null, null, null));
            });

        using var stream = new MemoryStream(new byte[100]);
        stream.Position = 100; // simulate exhausted stream after upload

        await _sut.ImportAsync(stream, "test.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal(0, positionDuringAi);
    }

    // ── GetPiecesAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetPiecesAsync_ReturnsStueckeForKapelleOnly()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var otherKapelle = new Band { Name = "Other" };
        _db.Bands.Add(otherKapelle);
        _db.Pieces.Add(new Piece { BandId = bandId, Title = "Song A", ImportStatus = ImportStatus.Completed });
        _db.Pieces.Add(new Piece { BandId = bandId, Title = "Song B", ImportStatus = ImportStatus.Completed });
        _db.Pieces.Add(new Piece { BandId = otherKapelle.Id, Title = "Other Song", ImportStatus = ImportStatus.Completed });
        await _db.SaveChangesAsync();

        var result = await _sut.GetPiecesAsync(bandId, musicianId);

        Assert.Equal(2, result.Count);
        Assert.All(result, s => Assert.Equal(bandId, s.BandId));
    }

    [Fact]
    public async Task GetPiecesAsync_NotMember_ThrowsDomainException()
    {
        var band = new Band { Name = "K" };
        _db.Bands.Add(band);
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPiecesAsync(band.Id, Guid.NewGuid()));
    }

    [Fact]
    public async Task GetPiecesAsync_EmptyLibrary_ReturnsEmptyList()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();

        var result = await _sut.GetPiecesAsync(bandId, musicianId);

        Assert.Empty(result);
    }

    // ── GetPieceAsync ────────────────────────────────────────────────────────

    [Fact]
    public async Task GetPieceAsync_ExistingStueck_ReturnsMappedDto()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "Serenade", Composer = "Bach",
            ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        var result = await _sut.GetPieceAsync(bandId, piece.Id, musicianId);

        Assert.Equal(piece.Id, result.Id);
        Assert.Equal("Serenade", result.Title);
        Assert.Equal("Bach", result.Composer);
        Assert.Equal(bandId, result.BandId);
    }

    [Fact]
    public async Task GetPieceAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var otherKapelle = new Band { Name = "Other" };
        _db.Bands.Add(otherKapelle);
        var piece = new Piece { BandId = otherKapelle.Id, Title = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPieceAsync(bandId, piece.Id, musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetPieceAsync_NonExistentId_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPieceAsync(bandId, Guid.NewGuid(), musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
    }

    // ── CreatePieceAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreatePieceAsync_ValidDto_ReturnsCreatedDto()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var dto = new PieceCreateDto("Neue Polka", "Müller", null, 2024, "G-Dur", "3/4", 140, null);

        var result = await _sut.CreatePieceAsync(bandId, dto, musicianId);

        Assert.Equal("Neue Polka", result.Title);
        Assert.Equal("Müller", result.Composer);
        Assert.Equal(bandId, result.BandId);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
        Assert.True(result.Id != Guid.Empty);
    }

    [Fact]
    public async Task CreatePieceAsync_TrimsLeadingAndTrailingWhitespace()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var dto = new PieceCreateDto("  Polka  ", "  Müller  ", null, null, null, null, null, null);

        var result = await _sut.CreatePieceAsync(bandId, dto, musicianId);

        Assert.Equal("Polka", result.Title);
        Assert.Equal("Müller", result.Composer);
    }

    [Fact]
    public async Task CreatePieceAsync_NotMember_ThrowsDomainException()
    {
        var band = new Band { Name = "K" };
        _db.Bands.Add(band);
        await _db.SaveChangesAsync();
        var dto = new PieceCreateDto("Title", null, null, null, null, null, null, null);

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreatePieceAsync(band.Id, dto, Guid.NewGuid()));
    }

    // ── UpdatePieceAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdatePieceAsync_ValidChanges_UpdatesAllFields()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "Old Title", Composer = "Old",
            ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        var dto = new PieceUpdateDto("New Title", "New Composer", "New Arr", 2025, "D-Dur", "6/8", 90, "Description");
        var result = await _sut.UpdatePieceAsync(bandId, piece.Id, dto, musicianId);

        Assert.Equal("New Title", result.Title);
        Assert.Equal("New Composer", result.Composer);
        Assert.Equal("New Arr", result.Arranger);
        Assert.Equal(2025, result.PublicationYear);
        Assert.Equal("D-Dur", result.MusicalKey);
        Assert.Equal("6/8", result.TimeSignature);
        Assert.Equal(90, result.Tempo);
        Assert.Equal("Description", result.Description);
    }

    [Fact]
    public async Task UpdatePieceAsync_StueckNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var dto = new PieceUpdateDto("Title", null, null, null, null, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdatePieceAsync(bandId, Guid.NewGuid(), dto, musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdatePieceAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var otherKapelle = new Band { Name = "Other" };
        _db.Bands.Add(otherKapelle);
        var piece = new Piece { BandId = otherKapelle.Id, Title = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        var dto = new PieceUpdateDto("Hack", null, null, null, null, null, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdatePieceAsync(bandId, piece.Id, dto, musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
    }

    // ── DeletePieceAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task DeletePieceAsync_WithStorageKey_DeletesFromStorageAndDb()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "To Delete",
            StorageKey = "storage/key.pdf", ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        await _sut.DeletePieceAsync(bandId, piece.Id, musicianId);

        await _storage.Received(1).DeleteAsync("storage/key.pdf", Arg.Any<CancellationToken>());
        Assert.False(await _db.Pieces.AnyAsync(s => s.Id == piece.Id));
    }

    [Fact]
    public async Task DeletePieceAsync_WithoutStorageKey_SkipsStorageDeleteAndRemovesFromDb()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "Manual Entry",
            StorageKey = null, ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        await _sut.DeletePieceAsync(bandId, piece.Id, musicianId);

        await _storage.DidNotReceive().DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
        Assert.False(await _db.Pieces.AnyAsync(s => s.Id == piece.Id));
    }

    [Fact]
    public async Task DeletePieceAsync_StorageDeleteFails_StillRemovesFromDb()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "Orphan",
            StorageKey = "storage/broken.pdf", ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        _storage.DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("MinIO unreachable"));

        await _sut.DeletePieceAsync(bandId, piece.Id, musicianId); // must NOT throw

        Assert.False(await _db.Pieces.AnyAsync(s => s.Id == piece.Id));
    }

    [Fact]
    public async Task DeletePieceAsync_StueckNotFound_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePieceAsync(bandId, Guid.NewGuid(), musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task DeletePieceAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var otherKapelle = new Band { Name = "Other" };
        _db.Bands.Add(otherKapelle);
        var piece = new Piece { BandId = otherKapelle.Id, Title = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePieceAsync(bandId, piece.Id, musicianId));

        Assert.Equal("PIECE_NOT_FOUND", ex.ErrorCode);
    }

    // ── Band-scoped access isolation ──────────────────────────────────────

    [Fact]
    public async Task KapelleScopedAccess_MemberOfKapelleA_CannotReadKapelleB()
    {
        var (musicianId, kapelleAId) = await SeedMitgliedAsync();

        var kapelleB = new Band { Name = "Band B" };
        _db.Bands.Add(kapelleB);
        _db.Pieces.Add(new Piece { BandId = kapelleB.Id, Title = "Secret Song", ImportStatus = ImportStatus.Completed });
        await _db.SaveChangesAsync();

        // musician is member of A but NOT B → should be denied
        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetPiecesAsync(kapelleB.Id, musicianId));
    }

    [Fact]
    public async Task KapelleScopedAccess_MemberOfKapelleA_CannotDeleteFromKapelleB()
    {
        var (musicianId, kapelleAId) = await SeedMitgliedAsync();

        var kapelleB = new Band { Name = "Band B" };
        _db.Bands.Add(kapelleB);
        var piece = new Piece { BandId = kapelleB.Id, Title = "Protected", ImportStatus = ImportStatus.Completed };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeletePieceAsync(kapelleB.Id, piece.Id, musicianId));
    }

    // ── Personal collection ───────────────────────────────────────────────────

    [Fact]
    public async Task PersonalCollection_ImportCreatesPersonalStueck_VisibleOnlyViaOwner()
    {
        var musician = new Musician { Email = "personal@test.com", Name = "Solo" };
        _db.Musicians.Add(musician);
        await _db.SaveChangesAsync();

        SetupStorageUpload();
        SetupAiSuccess("Personal Piece");

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "solo.pdf", "application/pdf", null, musician.Id);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Null(piece.BandId);
        Assert.Equal(musician.Id, piece.MusicianId);
        Assert.Equal("Personal Piece", piece.Title);
    }
}
