using Microsoft.Extensions.Logging;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// Local filesystem storage for development — no MinIO/S3 dependency needed.
/// Files are stored under {ContentRoot}/storage/uploads/.
/// </summary>
public class LocalFileStorageService : IStorageService
{
    private readonly string _basePath;
    private readonly ILogger<LocalFileStorageService> _logger;

    public LocalFileStorageService(string basePath, ILogger<LocalFileStorageService> logger)
    {
        _basePath = basePath;
        _logger = logger;
        Directory.CreateDirectory(_basePath);
    }

    public async Task<string> UploadAsync(
        Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var storageKey = $"uploads/{DateTime.UtcNow:yyyy/MM/dd}/{Guid.NewGuid()}/{fileName}";
        var fullPath = Path.Combine(_basePath, storageKey.Replace('/', Path.DirectorySeparatorChar));

        Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

        await using var fileStream = File.Create(fullPath);
        await stream.CopyToAsync(fileStream, ct);

        _logger.LogInformation("Uploaded {FileName} to local storage: {StorageKey}", fileName, storageKey);
        return storageKey;
    }

    public Task<string> GetDownloadUrlAsync(string storageKey, CancellationToken ct = default)
    {
        var fullPath = Path.Combine(_basePath, storageKey.Replace('/', Path.DirectorySeparatorChar));
        // Return a file:// URL for local dev
        return Task.FromResult($"file:///{fullPath.Replace('\\', '/')}");
    }

    public Task DeleteAsync(string storageKey, CancellationToken ct = default)
    {
        var fullPath = Path.Combine(_basePath, storageKey.Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
            _logger.LogInformation("Deleted local file: {StorageKey}", storageKey);
        }
        return Task.CompletedTask;
    }
}
