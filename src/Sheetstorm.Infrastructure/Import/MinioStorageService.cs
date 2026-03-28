using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Sheetstorm.Infrastructure.Import;

/// <summary>
/// S3-compatible storage service (MinIO local, AWS S3 production).
/// </summary>
public class MinioStorageService : IStorageService
{
    private readonly IAmazonS3 _s3;
    private readonly string _bucket;
    private readonly ILogger<MinioStorageService> _logger;

    public MinioStorageService(IAmazonS3 s3, IConfiguration configuration, ILogger<MinioStorageService> logger)
    {
        _s3 = s3;
        _bucket = configuration["Storage:Bucket"] ?? "sheetstorm";
        _logger = logger;
    }

    public async Task<string> UploadAsync(
        Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var storageKey = $"uploads/{DateTime.UtcNow:yyyy/MM/dd}/{Guid.NewGuid()}/{fileName}";

        await EnsureBucketExistsAsync(ct);

        var request = new PutObjectRequest
        {
            BucketName = _bucket,
            Key = storageKey,
            InputStream = stream,
            ContentType = contentType
        };

        await _s3.PutObjectAsync(request, ct);
        _logger.LogInformation("Uploaded {FileName} to {StorageKey}", fileName, storageKey);

        return storageKey;
    }

    public async Task<string> GetDownloadUrlAsync(string storageKey, CancellationToken ct = default)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucket,
            Key = storageKey,
            Expires = DateTime.UtcNow.AddHours(1),
            Verb = HttpVerb.GET
        };

        var url = await _s3.GetPreSignedURLAsync(request);
        return url;
    }

    public async Task DeleteAsync(string storageKey, CancellationToken ct = default)
    {
        var request = new DeleteObjectRequest
        {
            BucketName = _bucket,
            Key = storageKey
        };

        await _s3.DeleteObjectAsync(request, ct);
        _logger.LogInformation("Deleted {StorageKey}", storageKey);
    }

    private async Task EnsureBucketExistsAsync(CancellationToken ct)
    {
        try
        {
            await _s3.EnsureBucketExistsAsync(_bucket);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not ensure bucket {Bucket} exists", _bucket);
        }
    }
}
