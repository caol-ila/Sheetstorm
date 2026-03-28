using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Domain.Entities;
using Sheetstorm.Domain.Enums;
using Sheetstorm.Domain.Exceptions;
using Sheetstorm.Domain.Import;
using Sheetstorm.Infrastructure.Import;
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
        _sut = new ImportService(_db, _storage, _ai, _logger);
    }

    public void Dispose()
    {
        _db.Dispose();
        GC.SuppressFinalize(this);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Guid musikerId, Guid kapelleId)> SeedMitgliedAsync()
    {
        var musiker = new Musiker { Email = $"m{Guid.NewGuid()}@test.com", Name = "Test" };
        var kapelle = new Kapelle { Name = "Test Kapelle" };
        var mitglied = new Mitgliedschaft { Musiker = musiker, Kapelle = kapelle, IstAktiv = true };
        _db.Musiker.Add(musiker);
        _db.Kapellen.Add(kapelle);
        _db.Mitgliedschaften.Add(mitglied);
        await _db.SaveChangesAsync();
        return (musiker.Id, kapelle.Id);
    }

    private void SetupStorageUpload(string key = "storage/test.pdf")
        => _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(key);

    private void SetupAiSuccess(string? titel = "AI Title")
        => _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new StueckMetadataDto(titel, "Komponist", "C-Dur", "4/4", 120));

    // ── ImportAsync: File Upload ───────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_ValidFile_KapelleScope_CreatesStueckWithCorrectOwnership()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        SetupAiSuccess("Böhmischer Traum");

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelleId, musikerId);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Equal(kapelleId, stueck.KapelleID);
        Assert.Null(stueck.MusikerID); // kapelle-scoped: no personal owner
        Assert.Equal("test.pdf", stueck.OriginalDateiname);
    }

    [Fact]
    public async Task ImportAsync_PersonalScope_NullKapelleId_SetsMusikerOwner()
    {
        var musiker = new Musiker { Email = "personal@test.com", Name = "Personal" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        SetupStorageUpload();
        SetupAiSuccess();

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "personal.pdf", "application/pdf", null, musiker.Id);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Null(stueck.KapelleID);
        Assert.Equal(musiker.Id, stueck.MusikerID);
    }

    [Fact]
    public async Task ImportAsync_UploadedFile_StorageKeyIsPersisted()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload("uploads/2024/song.pdf");
        SetupAiSuccess();

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "song.pdf", "application/pdf", kapelleId, musikerId);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Equal("uploads/2024/song.pdf", stueck.StorageKey);
    }

    [Fact]
    public async Task ImportAsync_NotAMember_ThrowsDomainException()
    {
        var kapelle = new Kapelle { Name = "Foreign Kapelle" };
        _db.Kapellen.Add(kapelle);
        await _db.SaveChangesAsync();

        using var stream = new MemoryStream([1, 2, 3]);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelle.Id, Guid.NewGuid()));

        Assert.Equal("KAPELLE_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task ImportAsync_InactiveMitgliedschaft_ThrowsDomainException()
    {
        var musiker = new Musiker { Email = "inactive@test.com", Name = "Inactive" };
        var kapelle = new Kapelle { Name = "Kapelle" };
        var mitglied = new Mitgliedschaft { Musiker = musiker, Kapelle = kapelle, IstAktiv = false };
        _db.Musiker.Add(musiker);
        _db.Kapellen.Add(kapelle);
        _db.Mitgliedschaften.Add(mitglied);
        await _db.SaveChangesAsync();

        using var stream = new MemoryStream([1, 2, 3]);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelle.Id, musiker.Id));

        Assert.Equal("KAPELLE_NOT_FOUND", ex.ErrorCode);
    }

    // ── ImportAsync: State Machine ────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_StateMachine_PendingThenProcessingDuringAi_ThenCompleted()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();

        ImportStatus? statusDuringAi = null;
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(async _ =>
            {
                // Status should be Processing while AI runs
                statusDuringAi = (await _db.Stuecke.FirstOrDefaultAsync())?.ImportStatus;
                return new StueckMetadataDto("Title", null, null, null, null);
            });

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal(ImportStatus.Processing, statusDuringAi);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
    }

    [Fact]
    public async Task ImportAsync_AiExtractionFails_SetsStueckStatusToFailed()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("AI service unavailable"));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal(ImportStatus.Failed, result.ImportStatus);
        Assert.Null(result.ExtractedMetadata);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Equal(ImportStatus.Failed, stueck.ImportStatus);
    }

    [Fact]
    public async Task ImportAsync_AiFailure_StueckIsStillPersisted()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload("uploads/orphan.pdf");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new InvalidOperationException("Timeout"));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "orphan.pdf", "application/pdf", kapelleId, musikerId);

        Assert.True(await _db.Stuecke.AnyAsync(s => s.Id == result.StueckId));
    }

    // ── ImportAsync: AI Metadata Extraction ──────────────────────────────────

    [Fact]
    public async Task ImportAsync_AiReturnsFullMetadata_AllFieldsApplied()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new StueckMetadataDto("Tiroler Polka", "Franz Müller", "G-Dur", "3/4", 138));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "song.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal("Tiroler Polka", result.Titel);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
        Assert.NotNull(result.ExtractedMetadata);
        Assert.Equal("Franz Müller", result.ExtractedMetadata!.Komponist);
        Assert.Equal("G-Dur", result.ExtractedMetadata.Tonart);
        Assert.Equal("3/4", result.ExtractedMetadata.Taktart);
        Assert.Equal(138, result.ExtractedMetadata.Tempo);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Equal("Tiroler Polka", stueck.Titel);
        Assert.Equal("Franz Müller", stueck.Komponist);
        Assert.Equal("G-Dur", stueck.Tonart);
        Assert.Equal("3/4", stueck.Taktart);
        Assert.Equal(138, stueck.Tempo);
    }

    [Fact]
    public async Task ImportAsync_AiReturnsTitleNull_TitleFallsBackToFileName()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new StueckMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "My Polka.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal("My Polka", result.Titel);
    }

    [Fact]
    public async Task ImportAsync_AiReturnsTitleWhitespaceOnly_TitleFallsBackToFileName()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new StueckMetadataDto("   ", null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "Fallback.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal("Fallback", result.Titel);
    }

    [Fact]
    public async Task ImportAsync_SeekableStream_StreamIsResetToZeroBeforeAi()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        SetupStorageUpload();

        long? positionDuringAi = null;
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(callInfo =>
            {
                positionDuringAi = callInfo.Arg<Stream>().Position;
                return Task.FromResult(new StueckMetadataDto(null, null, null, null, null));
            });

        using var stream = new MemoryStream(new byte[100]);
        stream.Position = 100; // simulate exhausted stream after upload

        await _sut.ImportAsync(stream, "test.pdf", "application/pdf", kapelleId, musikerId);

        Assert.Equal(0, positionDuringAi);
    }

    // ── GetStueckeAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetStueckeAsync_ReturnsStueckeForKapelleOnly()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var otherKapelle = new Kapelle { Name = "Other" };
        _db.Kapellen.Add(otherKapelle);
        _db.Stuecke.Add(new Stueck { KapelleID = kapelleId, Titel = "Song A", ImportStatus = ImportStatus.Completed });
        _db.Stuecke.Add(new Stueck { KapelleID = kapelleId, Titel = "Song B", ImportStatus = ImportStatus.Completed });
        _db.Stuecke.Add(new Stueck { KapelleID = otherKapelle.Id, Titel = "Other Song", ImportStatus = ImportStatus.Completed });
        await _db.SaveChangesAsync();

        var result = await _sut.GetStueckeAsync(kapelleId, musikerId);

        Assert.Equal(2, result.Count);
        Assert.All(result, s => Assert.Equal(kapelleId, s.KapelleId));
    }

    [Fact]
    public async Task GetStueckeAsync_NotMember_ThrowsDomainException()
    {
        var kapelle = new Kapelle { Name = "K" };
        _db.Kapellen.Add(kapelle);
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStueckeAsync(kapelle.Id, Guid.NewGuid()));
    }

    [Fact]
    public async Task GetStueckeAsync_EmptyLibrary_ReturnsEmptyList()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();

        var result = await _sut.GetStueckeAsync(kapelleId, musikerId);

        Assert.Empty(result);
    }

    // ── GetStueckAsync ────────────────────────────────────────────────────────

    [Fact]
    public async Task GetStueckAsync_ExistingStueck_ReturnsMappedDto()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var stueck = new Stueck
        {
            KapelleID = kapelleId, Titel = "Serenade", Komponist = "Bach",
            ImportStatus = ImportStatus.Completed
        };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        var result = await _sut.GetStueckAsync(kapelleId, stueck.Id, musikerId);

        Assert.Equal(stueck.Id, result.Id);
        Assert.Equal("Serenade", result.Titel);
        Assert.Equal("Bach", result.Komponist);
        Assert.Equal(kapelleId, result.KapelleId);
    }

    [Fact]
    public async Task GetStueckAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var otherKapelle = new Kapelle { Name = "Other" };
        _db.Kapellen.Add(otherKapelle);
        var stueck = new Stueck { KapelleID = otherKapelle.Id, Titel = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStueckAsync(kapelleId, stueck.Id, musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
        Assert.Equal(404, ex.StatusCode);
    }

    [Fact]
    public async Task GetStueckAsync_NonExistentId_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStueckAsync(kapelleId, Guid.NewGuid(), musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
    }

    // ── CreateStueckAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task CreateStueckAsync_ValidDto_ReturnsCreatedDto()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var dto = new StueckCreateDto("Neue Polka", "Müller", null, 2024, "G-Dur", "3/4", 140, null);

        var result = await _sut.CreateStueckAsync(kapelleId, dto, musikerId);

        Assert.Equal("Neue Polka", result.Titel);
        Assert.Equal("Müller", result.Komponist);
        Assert.Equal(kapelleId, result.KapelleId);
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
        Assert.True(result.Id != Guid.Empty);
    }

    [Fact]
    public async Task CreateStueckAsync_TrimsLeadingAndTrailingWhitespace()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var dto = new StueckCreateDto("  Polka  ", "  Müller  ", null, null, null, null, null, null);

        var result = await _sut.CreateStueckAsync(kapelleId, dto, musikerId);

        Assert.Equal("Polka", result.Titel);
        Assert.Equal("Müller", result.Komponist);
    }

    [Fact]
    public async Task CreateStueckAsync_NotMember_ThrowsDomainException()
    {
        var kapelle = new Kapelle { Name = "K" };
        _db.Kapellen.Add(kapelle);
        await _db.SaveChangesAsync();
        var dto = new StueckCreateDto("Title", null, null, null, null, null, null, null);

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.CreateStueckAsync(kapelle.Id, dto, Guid.NewGuid()));
    }

    // ── UpdateStueckAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task UpdateStueckAsync_ValidChanges_UpdatesAllFields()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var stueck = new Stueck
        {
            KapelleID = kapelleId, Titel = "Old Title", Komponist = "Old",
            ImportStatus = ImportStatus.Completed
        };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        var dto = new StueckUpdateDto("New Title", "New Komponist", "New Arr", 2025, "D-Dur", "6/8", 90, "Beschreibung");
        var result = await _sut.UpdateStueckAsync(kapelleId, stueck.Id, dto, musikerId);

        Assert.Equal("New Title", result.Titel);
        Assert.Equal("New Komponist", result.Komponist);
        Assert.Equal("New Arr", result.Arrangeur);
        Assert.Equal(2025, result.VeroeffentlichungsJahr);
        Assert.Equal("D-Dur", result.Tonart);
        Assert.Equal("6/8", result.Taktart);
        Assert.Equal(90, result.Tempo);
        Assert.Equal("Beschreibung", result.Beschreibung);
    }

    [Fact]
    public async Task UpdateStueckAsync_StueckNotFound_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var dto = new StueckUpdateDto("Title", null, null, null, null, null, null, null);

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateStueckAsync(kapelleId, Guid.NewGuid(), dto, musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task UpdateStueckAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var otherKapelle = new Kapelle { Name = "Other" };
        _db.Kapellen.Add(otherKapelle);
        var stueck = new Stueck { KapelleID = otherKapelle.Id, Titel = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        var dto = new StueckUpdateDto("Hack", null, null, null, null, null, null, null);
        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.UpdateStueckAsync(kapelleId, stueck.Id, dto, musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
    }

    // ── DeleteStueckAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteStueckAsync_WithStorageKey_DeletesFromStorageAndDb()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var stueck = new Stueck
        {
            KapelleID = kapelleId, Titel = "To Delete",
            StorageKey = "storage/key.pdf", ImportStatus = ImportStatus.Completed
        };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        await _sut.DeleteStueckAsync(kapelleId, stueck.Id, musikerId);

        await _storage.Received(1).DeleteAsync("storage/key.pdf", Arg.Any<CancellationToken>());
        Assert.False(await _db.Stuecke.AnyAsync(s => s.Id == stueck.Id));
    }

    [Fact]
    public async Task DeleteStueckAsync_WithoutStorageKey_SkipsStorageDeleteAndRemovesFromDb()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var stueck = new Stueck
        {
            KapelleID = kapelleId, Titel = "Manual Entry",
            StorageKey = null, ImportStatus = ImportStatus.Completed
        };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        await _sut.DeleteStueckAsync(kapelleId, stueck.Id, musikerId);

        await _storage.DidNotReceive().DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
        Assert.False(await _db.Stuecke.AnyAsync(s => s.Id == stueck.Id));
    }

    [Fact]
    public async Task DeleteStueckAsync_StorageDeleteFails_StillRemovesFromDb()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var stueck = new Stueck
        {
            KapelleID = kapelleId, Titel = "Orphan",
            StorageKey = "storage/broken.pdf", ImportStatus = ImportStatus.Completed
        };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        _storage.DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("MinIO unreachable"));

        await _sut.DeleteStueckAsync(kapelleId, stueck.Id, musikerId); // must NOT throw

        Assert.False(await _db.Stuecke.AnyAsync(s => s.Id == stueck.Id));
    }

    [Fact]
    public async Task DeleteStueckAsync_StueckNotFound_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteStueckAsync(kapelleId, Guid.NewGuid(), musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
    }

    [Fact]
    public async Task DeleteStueckAsync_StueckFromOtherKapelle_ThrowsDomainException()
    {
        var (musikerId, kapelleId) = await SeedMitgliedAsync();
        var otherKapelle = new Kapelle { Name = "Other" };
        _db.Kapellen.Add(otherKapelle);
        var stueck = new Stueck { KapelleID = otherKapelle.Id, Titel = "Foreign", ImportStatus = ImportStatus.Completed };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        var ex = await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteStueckAsync(kapelleId, stueck.Id, musikerId));

        Assert.Equal("STUECK_NOT_FOUND", ex.ErrorCode);
    }

    // ── Kapelle-scoped access isolation ──────────────────────────────────────

    [Fact]
    public async Task KapelleScopedAccess_MemberOfKapelleA_CannotReadKapelleB()
    {
        var (musikerId, kapelleAId) = await SeedMitgliedAsync();

        var kapelleB = new Kapelle { Name = "Kapelle B" };
        _db.Kapellen.Add(kapelleB);
        _db.Stuecke.Add(new Stueck { KapelleID = kapelleB.Id, Titel = "Secret Song", ImportStatus = ImportStatus.Completed });
        await _db.SaveChangesAsync();

        // musician is member of A but NOT B → should be denied
        await Assert.ThrowsAsync<DomainException>(
            () => _sut.GetStueckeAsync(kapelleB.Id, musikerId));
    }

    [Fact]
    public async Task KapelleScopedAccess_MemberOfKapelleA_CannotDeleteFromKapelleB()
    {
        var (musikerId, kapelleAId) = await SeedMitgliedAsync();

        var kapelleB = new Kapelle { Name = "Kapelle B" };
        _db.Kapellen.Add(kapelleB);
        var stueck = new Stueck { KapelleID = kapelleB.Id, Titel = "Protected", ImportStatus = ImportStatus.Completed };
        _db.Stuecke.Add(stueck);
        await _db.SaveChangesAsync();

        await Assert.ThrowsAsync<DomainException>(
            () => _sut.DeleteStueckAsync(kapelleB.Id, stueck.Id, musikerId));
    }

    // ── Personal collection ───────────────────────────────────────────────────

    [Fact]
    public async Task PersonalCollection_ImportCreatesPersonalStueck_VisibleOnlyViaOwner()
    {
        var musiker = new Musiker { Email = "personal@test.com", Name = "Solo" };
        _db.Musiker.Add(musiker);
        await _db.SaveChangesAsync();

        SetupStorageUpload();
        SetupAiSuccess("Personal Piece");

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "solo.pdf", "application/pdf", null, musiker.Id);

        var stueck = await _db.Stuecke.FirstAsync(s => s.Id == result.StueckId);
        Assert.Null(stueck.KapelleID);
        Assert.Equal(musiker.Id, stueck.MusikerID);
        Assert.Equal("Personal Piece", stueck.Titel);
    }
}
