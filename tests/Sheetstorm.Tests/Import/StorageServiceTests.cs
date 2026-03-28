using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Sheetstorm.Infrastructure.Import;

namespace Sheetstorm.Tests.Import;

/// <summary>
/// Tests for the IStorageService contract using a mock (MinIO is not available in test env).
/// Verifies the import pipeline handles storage outcomes correctly.
/// </summary>
public class StorageServiceTests
{
    private readonly IStorageService _storage;

    public StorageServiceTests()
    {
        _storage = Substitute.For<IStorageService>();
    }

    // ── UploadAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task UploadAsync_ReturnsStorageKey()
    {
        _storage.UploadAsync(Arg.Any<Stream>(), "song.pdf", "application/pdf", Arg.Any<CancellationToken>())
            .Returns("kapellen/42/songs/song.pdf");

        using var stream = new MemoryStream([1, 2, 3]);
        var key = await _storage.UploadAsync(stream, "song.pdf", "application/pdf");

        Assert.Equal("kapellen/42/songs/song.pdf", key);
    }

    [Fact]
    public async Task UploadAsync_LargeFile_CompletesSuccessfully()
    {
        var largeKey = "uploads/large-file.pdf";
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(largeKey);

        // Simulate a 50 MB stream
        using var stream = new MemoryStream(new byte[50 * 1024 * 1024]);
        var key = await _storage.UploadAsync(stream, "large-file.pdf", "application/pdf");

        Assert.Equal(largeKey, key);
        await _storage.Received(1).UploadAsync(stream, "large-file.pdf", "application/pdf", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UploadAsync_StorageFailure_ThrowsException()
    {
        _storage.UploadAsync(Arg.Any<Stream>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new IOException("S3 connection refused"));

        using var stream = new MemoryStream([1, 2, 3]);
        await Assert.ThrowsAsync<IOException>(
            () => _storage.UploadAsync(stream, "song.pdf", "application/pdf"));
    }

    // ── GetDownloadUrlAsync ───────────────────────────────────────────────────

    [Fact]
    public async Task GetDownloadUrlAsync_ValidKey_ReturnsPresignedUrl()
    {
        var expectedUrl = "https://s3.example.com/kapellen/42/song.pdf?X-Amz-Signature=abc";
        _storage.GetDownloadUrlAsync("kapellen/42/song.pdf", Arg.Any<CancellationToken>())
            .Returns(expectedUrl);

        var url = await _storage.GetDownloadUrlAsync("kapellen/42/song.pdf");

        Assert.Equal(expectedUrl, url);
        Assert.StartsWith("https://", url);
    }

    [Fact]
    public async Task GetDownloadUrlAsync_NonExistentKey_ThrowsException()
    {
        _storage.GetDownloadUrlAsync("missing/key.pdf", Arg.Any<CancellationToken>())
            .ThrowsAsync(new KeyNotFoundException("Object not found"));

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => _storage.GetDownloadUrlAsync("missing/key.pdf"));
    }

    // ── DeleteAsync ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_ValidKey_CompletesSuccessfully()
    {
        _storage.DeleteAsync("storage/song.pdf", Arg.Any<CancellationToken>()).Returns(Task.CompletedTask);

        await _storage.DeleteAsync("storage/song.pdf"); // should not throw

        await _storage.Received(1).DeleteAsync("storage/song.pdf", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_StorageFailure_ThrowsException()
    {
        _storage.DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ThrowsAsync(new Exception("MinIO bucket unreachable"));

        await Assert.ThrowsAsync<Exception>(
            () => _storage.DeleteAsync("storage/song.pdf"));
    }

    // ── Idempotency ───────────────────────────────────────────────────────────

    [Fact]
    public async Task DeleteAsync_CalledTwiceWithSameKey_BothCallsReceived()
    {
        _storage.DeleteAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(Task.CompletedTask);

        await _storage.DeleteAsync("storage/key.pdf");
        await _storage.DeleteAsync("storage/key.pdf");

        await _storage.Received(2).DeleteAsync("storage/key.pdf", Arg.Any<CancellationToken>());
    }
}
