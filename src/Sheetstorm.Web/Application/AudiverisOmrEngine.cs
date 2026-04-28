using System.Xml.Linq;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Web.Services;

namespace Sheetstorm.Web.Application;

/// <summary>
/// Adapter, der Audiveris im Sidecar-Container über HTTP anspricht.
/// Liefert MusicXML zurück, das wir parsen für DetectedPart-Liste.
///
/// Aktivierung: Set ENV `Audiveris__BaseUrl=http://audiveris:8080` und
/// registriere im DI als <see cref="IOmrEngine"/>.
/// Falls nicht erreichbar, fällt Sheetstorm automatisch auf die Stub-Engine zurück.
/// </summary>
public sealed class AudiverisOmrEngine(LocalFileStore store, IHttpClientFactory httpFactory, ILogger<AudiverisOmrEngine> log) : IOmrEngine
{
    public async Task<OmrResult> RecognizeAsync(string blobKey, string originalFileName, IReadOnlyList<Instrument> availableInstruments, CancellationToken ct = default)
    {
        var client = httpFactory.CreateClient("audiveris");
        client.Timeout = TimeSpan.FromMinutes(5);

        await using var pdf = store.OpenRead(blobKey);
        using var content = new MultipartFormDataContent();
        var streamContent = new StreamContent(pdf);
        streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/pdf");
        content.Add(streamContent, "pdf", originalFileName);

        log.LogInformation("Audiveris: rufe /recognize für {File}", originalFileName);
        var resp = await client.PostAsync("/recognize", content, ct);
        if (!resp.IsSuccessStatusCode)
        {
            var body = await resp.Content.ReadAsStringAsync(ct);
            throw new InvalidOperationException($"Audiveris-Fehler {(int)resp.StatusCode}: {body}");
        }

        var xml = await resp.Content.ReadAsStringAsync(ct);
        var (title, composer, parts) = ParseMusicXml(xml, availableInstruments);
        return new OmrResult(title, composer, parts);
    }

    /// <summary>
    /// Extrahiert Titel/Komponist und die <part-list> aus MusicXML.
    /// MusicXML-Struktur:
    ///   <score-partwise>
    ///     <work><work-title>...</work-title></work>
    ///     <identification><creator type="composer">...</creator></identification>
    ///     <part-list>
    ///       <score-part id="P1"><part-name>Klarinette in B</part-name></score-part>
    ///       ...
    /// </summary>
    internal static (string? Title, string? Composer, List<DetectedPart> Parts) ParseMusicXml(string xml, IReadOnlyList<Instrument> available)
    {
        XDocument doc;
        try { doc = XDocument.Parse(xml); }
        catch { return (null, null, new List<DetectedPart>()); }

        var ns = doc.Root?.GetDefaultNamespace() ?? XNamespace.None;
        var title = doc.Descendants(ns + "work-title").FirstOrDefault()?.Value
                  ?? doc.Descendants(ns + "movement-title").FirstOrDefault()?.Value;
        var composer = doc.Descendants(ns + "creator")
            .FirstOrDefault(e => (string?)e.Attribute("type") == "composer")?.Value;

        var parts = new List<DetectedPart>();
        var page = 1;
        foreach (var sp in doc.Descendants(ns + "score-part"))
        {
            var name = sp.Element(ns + "part-name")?.Value?.Trim();
            if (string.IsNullOrEmpty(name)) continue;

            var matched = MatchInstrument(name, available);
            parts.Add(new DetectedPart(
                DisplayName: name,
                InstrumentFamily: matched?.Family.ToString() ?? "Sonstige",
                InstrumentId: matched?.Id ?? available.First(i => i.Family == InstrumentFamily.Sonstige).Id,
                Transposition: matched?.DefaultTransposition,
                FromPage: page,
                ToPage: page,
                Confidence: matched is null ? 0.40 : 0.85));
            page++;
        }
        return (title, composer, parts);
    }

    private static Instrument? MatchInstrument(string partName, IReadOnlyList<Instrument> available)
    {
        var n = partName.ToLowerInvariant();
        // Exakter Match bevorzugt
        var exact = available.FirstOrDefault(i => string.Equals(i.Name, partName, StringComparison.OrdinalIgnoreCase));
        if (exact is not null) return exact;
        // Fuzzy: enthält Instrument-Namen
        return available
            .OrderByDescending(i => i.Name.Length)
            .FirstOrDefault(i => n.Contains(i.Name.Split(' ', '/')[0].ToLowerInvariant()));
    }
}
