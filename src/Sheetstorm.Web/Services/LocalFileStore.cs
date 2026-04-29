namespace Sheetstorm.Web.Services;

/// <summary>
/// Sehr einfache lokale Datei-Speicherung für Iteration 2.
/// Spätere Iterationen können auf S3/MinIO umgestellt werden.
/// BlobKey ist relativer Pfad unter dem konfigurierten Root.
/// </summary>
public sealed class LocalFileStore(IConfiguration config, ILogger<LocalFileStore> log)
{
    public string Root => Path.GetFullPath(config["FileStore:Root"] ?? Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".filestore"));

    public async Task<string> SaveAsync(Stream content, string subfolder, string fileName, CancellationToken ct = default)
    {
        Directory.CreateDirectory(Path.Combine(Root, subfolder));
        var safeName = $"{Guid.NewGuid():N}-{Path.GetFileName(fileName)}";
        var key = Path.Combine(subfolder, safeName).Replace('\\', '/');
        var fullPath = Path.Combine(Root, key);
        await using var fs = File.Create(fullPath);
        await content.CopyToAsync(fs, ct);
        log.LogInformation("Datei gespeichert: {Key}", key);
        return key;
    }

    public Stream OpenRead(string blobKey)
    {
        var fullPath = Path.Combine(Root, blobKey);
        if (!File.Exists(fullPath)) throw new FileNotFoundException("Blob nicht gefunden", blobKey);
        return File.OpenRead(fullPath);
    }

    public bool Exists(string blobKey) => File.Exists(Path.Combine(Root, blobKey));

    public long GetSize(string blobKey) => new FileInfo(Path.Combine(Root, blobKey)).Length;

    public string GetMimeType(string fileName) => Path.GetExtension(fileName).ToLowerInvariant() switch
    {
        ".pdf" => "application/pdf",
        ".xml" or ".musicxml" => "application/vnd.recordare.musicxml+xml",
        ".mp3" => "audio/mpeg",
        ".mid" or ".midi" => "audio/midi",
        _ => "application/octet-stream",
    };
}
