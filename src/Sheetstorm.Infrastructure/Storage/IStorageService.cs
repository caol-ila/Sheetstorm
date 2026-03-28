namespace Sheetstorm.Infrastructure.Storage;

/// <summary>
/// S3-compatible object storage abstraction.
/// Implement with AWSSDK.S3, MinIO, or Azure Blob as needed.
/// </summary>
public interface IStorageService
{
    /// <summary>Uploads a file and returns its public or pre-signed URL.</summary>
    Task<string> UploadAsync(string bucketKey, Stream content, string contentType, CancellationToken cancellationToken = default);

    /// <summary>Downloads a file stream by its bucket key.</summary>
    Task<Stream> DownloadAsync(string bucketKey, CancellationToken cancellationToken = default);

    /// <summary>Deletes a file by its bucket key.</summary>
    Task DeleteAsync(string bucketKey, CancellationToken cancellationToken = default);

    /// <summary>Returns a pre-signed URL valid for the given duration.</summary>
    Task<string> GetPresignedUrlAsync(string bucketKey, TimeSpan expiry, CancellationToken cancellationToken = default);
}
