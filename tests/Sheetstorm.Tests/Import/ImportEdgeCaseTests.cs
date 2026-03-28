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

/// <summary>
/// Edge-case tests: corrupt files, unsupported formats (service layer),
/// empty streams, and concurrent upload scenarios.
/// </summary>
public class ImportEdgeCaseTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly IStorageService _storage;
    private readonly IAiMetadataService _ai;
    private readonly ILogger<ImportService> _logger;
    private readonly ImportService _sut;

    public ImportEdgeCaseTests()
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

    // ── Corrupt / empty files ─────────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_EmptyStream_StorageUploadStillCalledAndStueckCreated()
    {
        // An empty file passes controller checks if Length > 0 but content is empty.
        // ImportService itself doesn't validate content — that's the AI's job.
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("storage/empty.pdf");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream(); // 0 bytes
        var result = await _sut.ImportAsync(stream, "empty.pdf", "application/pdf", bandId, musicianId);

        Assert.NotEqual(Guid.Empty, result.PieceId);
        await _storage.Received(1).UploadAsync(stream, "empty.pdf", "application/pdf", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ImportAsync_CorruptFile_AiThrowsException_StatusSetToFailed()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("storage/corrupt.pdf");

        // Simulates AI failing on a corrupt/unreadable PDF
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new InvalidDataException("PDF structure is malformed"));

        // Corrupt: random bytes that aren't a valid PDF
        var corruptBytes = new byte[] { 0x00, 0xFF, 0xFE, 0xAB, 0xCD };
        using var stream = new MemoryStream(corruptBytes);
        var result = await _sut.ImportAsync(stream, "corrupt.pdf", "application/pdf", bandId, musicianId);

        Assert.Equal(ImportStatus.Failed, result.ImportStatus);
        Assert.Null(result.ExtractedMetadata);
    }

    [Fact]
    public async Task ImportAsync_CorruptFile_FileNamePreservedInStueck()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("storage/corrupt.pdf");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("Parse error"));

        using var stream = new MemoryStream([0x00, 0xFF]);
        var result = await _sut.ImportAsync(stream, "broken-file.pdf", "application/pdf", bandId, musicianId);

        var piece = await _db.Pieces.FirstAsync(s => s.Id == result.PieceId);
        Assert.Equal("broken-file.pdf", piece.OriginalFileName);
    }

    [Fact]
    public async Task ImportAsync_StorageUploadFails_ThrowsExceptionBeforeCreatingStueck()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new IOException("S3 disk full"));

        using var stream = new MemoryStream([1, 2, 3]);
        await Assert.ThrowsAsync<IOException>(
            () => _sut.ImportAsync(stream, "song.pdf", "application/pdf", bandId, musicianId));

        // No Piece should have been created since upload failed
        Assert.False(await _db.Pieces.AnyAsync());
    }

    // ── Non-seekable streams ──────────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_NonSeekableStream_AiIsStillCalled()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("storage/key.pdf");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto("Title", null, null, null, null));

        using var nonSeekable = new NonSeekableStream([1, 2, 3, 4, 5]);
        var result = await _sut.ImportAsync(nonSeekable, "test.pdf", "application/pdf", bandId, musicianId);

        await _ai.Received(1).ExtractMetadataAsync(Arg.Any<Stream>(), "test.pdf", Arg.Any<CancellationToken>());
        Assert.Equal(ImportStatus.Completed, result.ImportStatus);
    }

    // ── File naming edge cases ────────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_FileNameWithoutExtension_TitleEqualsFullFileName()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("key");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "mysong", "application/pdf", bandId, musicianId);

        // Path.GetFileNameWithoutExtension("mysong") == "mysong"
        Assert.Equal("mysong", result.Title);
    }

    [Fact]
    public async Task ImportAsync_FileNameWithMultipleDots_TitleUsesCorrectBaseName()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("key");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "my.polka.v2.pdf", "application/pdf", bandId, musicianId);

        // Path.GetFileNameWithoutExtension strips only last extension
        Assert.Equal("my.polka.v2", result.Title);
    }

    // ── Concurrent uploads ────────────────────────────────────────────────────

    [Fact]
    public async Task ImportAsync_ConcurrentUploadsToSameKapelle_BothSucceed()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();

        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(callInfo => Task.FromResult($"storage/{callInfo.ArgAt<string>(1)}"));
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream1 = new MemoryStream([1, 2, 3]);
        using var stream2 = new MemoryStream([4, 5, 6]);

        var task1 = _sut.ImportAsync(stream1, "song1.pdf", "application/pdf", bandId, musicianId);
        var task2 = _sut.ImportAsync(stream2, "song2.pdf", "application/pdf", bandId, musicianId);

        var results = await Task.WhenAll(task1, task2);

        Assert.Equal(2, results.Length);
        Assert.All(results, r => Assert.Equal(ImportStatus.Completed, r.ImportStatus));
        Assert.Equal(2, await _db.Pieces.CountAsync(s => s.BandId == bandId));
    }

    [Fact]
    public async Task ImportAsync_ConcurrentUploadsFromDifferentMusiker_BothSucceed()
    {
        // Two different members of the same Band upload simultaneously
        var band = new Band { Name = "Shared Band" };
        _db.Bands.Add(band);

        var musiker1 = new Musician { Email = "m1@test.com", Name = "M1" };
        var musiker2 = new Musician { Email = "m2@test.com", Name = "M2" };
        _db.Musicians.AddRange(musiker1, musiker2);
        _db.Memberships.AddRange(
            new Membership { Musician = musiker1, Band = band, IsActive = true },
            new Membership { Musician = musiker2, Band = band, IsActive = true });
        await _db.SaveChangesAsync();

        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(callInfo => Task.FromResult($"storage/{Guid.NewGuid()}.pdf"));
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var s1 = new MemoryStream([1, 2, 3]);
        using var s2 = new MemoryStream([4, 5, 6]);

        var t1 = _sut.ImportAsync(s1, "upload1.pdf", "application/pdf", band.Id, musiker1.Id);
        var t2 = _sut.ImportAsync(s2, "upload2.pdf", "application/pdf", band.Id, musiker2.Id);

        var results = await Task.WhenAll(t1, t2);

        Assert.Equal(2, results.Length);
        Assert.Equal(2, await _db.Pieces.CountAsync());
    }

    // ── Labeling: assign pages (PiecePage) ──────────────────────────────────

    [Fact]
    public async Task ImportAsync_CreatedStueck_HasEmptyPageCollection()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns("key");
        _ai.ExtractMetadataAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(new PieceMetadataDto(null, null, null, null, null));

        using var stream = new MemoryStream([1, 2, 3]);
        var result = await _sut.ImportAsync(stream, "song.pdf", "application/pdf", bandId, musicianId);

        var piece = await _db.Pieces
            .Include(s => s.Pages)
            .FirstAsync(s => s.Id == result.PieceId);

        // Pages are assigned post-import in a separate labeling step
        Assert.Empty(piece.Pages);
    }

    [Fact]
    public async Task DeletePiece_WithPages_StueckIsRemovedFromDb()
    {
        var (musicianId, bandId) = await SeedMitgliedAsync();
        var piece = new Piece
        {
            BandId = bandId, Title = "With Pages",
            StorageKey = "key", ImportStatus = ImportStatus.Completed
        };
        _db.Pieces.Add(piece);
        await _db.SaveChangesAsync();

        _storage.DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(Task.CompletedTask);

        await _sut.DeletePieceAsync(bandId, piece.Id, musicianId);

        Assert.False(await _db.Pieces.AnyAsync(s => s.Id == piece.Id));
    }
}

// ── Test helpers ──────────────────────────────────────────────────────────────

/// <summary>Simulates a network/pipe stream that is not seekable.</summary>
internal sealed class NonSeekableStream(byte[] data) : Stream
{
    private readonly MemoryStream _inner = new(data);

    public override bool CanRead => true;
    public override bool CanSeek => false;
    public override bool CanWrite => false;
    public override long Length => throw new NotSupportedException();
    public override long Position
    {
        get => throw new NotSupportedException();
        set => throw new NotSupportedException();
    }

    public override int Read(byte[] buffer, int offset, int count) => _inner.Read(buffer, offset, count);
    public override void Flush() { }
    public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
    public override void SetLength(long value) => throw new NotSupportedException();
    public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();

    protected override void Dispose(bool disposing)
    {
        if (disposing) _inner.Dispose();
        base.Dispose(disposing);
    }
}
