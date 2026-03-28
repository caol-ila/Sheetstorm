namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// Abstraction for S3-compatible object storage (MinIO local, S3 production).
/// </summary>
public interface IStorageService
{
    /// <summary>Upload a file stream to storage and return the storage key.</summary>
    Task<string> UploadAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);

    /// <summary>Generate a pre-signed download URL for the given storage key.</summary>
    Task<string> GetDownloadUrlAsync(string storageKey, CancellationToken ct = default);

    /// <summary>Delete an object from storage.</summary>
    Task DeleteAsync(string storageKey, CancellationToken ct = default);
}
