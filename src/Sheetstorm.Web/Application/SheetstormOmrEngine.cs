using Sheetstorm.Domain.Identity;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Adapter, der die selbstgebaute Sheetstorm-OMR-Engine (Rust) im Sidecar-Container über HTTP anspricht.
/// Drop-in-Replacement für <see cref="AudiverisOmrEngine"/> — gleiche Schnittstelle und HTTP-API.
///
/// Aktivierung:
///   ENV `Omr__Provider=sheetstorm`
///   ENV `Omr__BaseUrl=http://sheetstorm-omr:8091`
/// </summary>
public sealed class SheetstormOmrEngine(
    LocalFileStore store,
    IHttpClientFactory httpFactory,
    ILogger<SheetstormOmrEngine> log) : IOmrEngine
{
    public async Task<OmrResult> RecognizeAsync(
        string blobKey,
        string originalFileName,
        IReadOnlyList<Instrument> availableInstruments,
        CancellationToken ct = default)
    {
        var xml = await DoRecognizeAsync(blobKey, originalFileName, ct);
        if (string.IsNullOrEmpty(xml))
        {
            return new OmrResult(null, null, new List<DetectedPart>());
        }
        var (title, composer, parts) = AudiverisOmrEngine.ParseMusicXml(xml, availableInstruments);
        return new OmrResult(title, composer, parts);
    }

    public async Task<string?> RecognizeRawMusicXmlAsync(
        string blobKey,
        string originalFileName,
        CancellationToken ct = default)
    {
        return await DoRecognizeAsync(blobKey, originalFileName, ct);
    }

    public async Task<string?> RecognizeDetectionsJsonAsync(
        string blobKey,
        string originalFileName,
        CancellationToken ct = default)
    {
        using var activity = SheetstormTelemetry.Activity.StartActivity("sheetstorm-omr.http.detections", System.Diagnostics.ActivityKind.Client);
        activity?.SetTag("omr.engine", "sheetstorm");
        activity?.SetTag("omr.blob_key", blobKey);
        activity?.SetTag("omr.filename", originalFileName);

        var client = httpFactory.CreateClient("sheetstorm-omr");
        client.Timeout = TimeSpan.FromMinutes(5);

        await using var fileStream = store.OpenRead(blobKey);
        var size = store.GetSize(blobKey);
        activity?.SetTag("file.size_bytes", size);

        using var content = new MultipartFormDataContent();
        var streamContent = new StreamContent(fileStream);
        streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(GuessMimeType(originalFileName));
        content.Add(streamContent, "file", originalFileName);

        log.LogInformation("Sheetstorm-OMR: rufe /detections für {File} ({Size} byte)", originalFileName, size);
        var sw = System.Diagnostics.Stopwatch.StartNew();
        var resp = await client.PostAsync("/detections", content, ct);
        sw.Stop();

        activity?.SetTag("omr.http.status", (int)resp.StatusCode);
        activity?.SetTag("omr.http.elapsed_ms", sw.ElapsedMilliseconds);

        if (!resp.IsSuccessStatusCode)
        {
            var body = await resp.Content.ReadAsStringAsync(ct);
            log.LogError("Sheetstorm-OMR /detections Fehler {Code} nach {Elapsed:F1}s: {Body}", (int)resp.StatusCode, sw.Elapsed.TotalSeconds, body);
            activity?.SetStatus(System.Diagnostics.ActivityStatusCode.Error, $"HTTP {(int)resp.StatusCode}");
            return null;
        }

        var json = await resp.Content.ReadAsStringAsync(ct);
        activity?.SetTag("detections.size_bytes", json.Length);
        log.LogInformation("Sheetstorm-OMR /detections fertig: {Bytes} byte JSON in {Elapsed:F1}s", json.Length, sw.Elapsed.TotalSeconds);
        return json;
    }

    private async Task<string?> DoRecognizeAsync(string blobKey, string originalFileName, CancellationToken ct)
    {
        using var activity = SheetstormTelemetry.Activity.StartActivity("sheetstorm-omr.http.recognize", System.Diagnostics.ActivityKind.Client);
        activity?.SetTag("omr.engine", "sheetstorm");
        activity?.SetTag("omr.blob_key", blobKey);
        activity?.SetTag("omr.filename", originalFileName);

        var client = httpFactory.CreateClient("sheetstorm-omr");
        client.Timeout = TimeSpan.FromMinutes(5);

        await using var fileStream = store.OpenRead(blobKey);
        var size = store.GetSize(blobKey);
        activity?.SetTag("file.size_bytes", size);

        using var content = new MultipartFormDataContent();
        var streamContent = new StreamContent(fileStream);
        streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(GuessMimeType(originalFileName));
        content.Add(streamContent, "file", originalFileName);

        log.LogInformation("Sheetstorm-OMR: rufe /recognize für {File} ({Size} byte)", originalFileName, size);
        var sw = System.Diagnostics.Stopwatch.StartNew();
        var resp = await client.PostAsync("/recognize", content, ct);
        sw.Stop();

        activity?.SetTag("omr.http.status", (int)resp.StatusCode);
        activity?.SetTag("omr.http.elapsed_ms", sw.ElapsedMilliseconds);

        if (!resp.IsSuccessStatusCode)
        {
            var body = await resp.Content.ReadAsStringAsync(ct);
            log.LogError("Sheetstorm-OMR Fehler {Code} nach {Elapsed:F1}s: {Body}", (int)resp.StatusCode, sw.Elapsed.TotalSeconds, body);
            activity?.SetStatus(System.Diagnostics.ActivityStatusCode.Error, $"HTTP {(int)resp.StatusCode}");
            return null;
        }

        var xml = await resp.Content.ReadAsStringAsync(ct);
        activity?.SetTag("musicxml.size_bytes", xml.Length);
        log.LogInformation("Sheetstorm-OMR fertig: {Bytes} byte MusicXML in {Elapsed:F1}s", xml.Length, sw.Elapsed.TotalSeconds);
        return xml;
    }

    private static string GuessMimeType(string filename)
    {
        var ext = System.IO.Path.GetExtension(filename).ToLowerInvariant();
        return ext switch
        {
            ".pdf" => "application/pdf",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".tiff" or ".tif" => "image/tiff",
            ".bmp" => "image/bmp",
            _ => "application/octet-stream",
        };
    }
}
