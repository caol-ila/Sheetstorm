# AI-Integration: GitHub Models Title Recognition

## 1. Overview

`ITitleRecognizer` extrahiert den Titel eines Musikstücks aus der ersten Seite eines PDF-Notenblatts mittels Vision-API. Die Komponente abstrahiert GitHub Models (GPT-4o Vision) hinter einem testbaren Interface.

**Vertrag:**
```csharp
public interface ITitleRecognizer
{
    ValueTask<TitleRecognitionResult> RecognizeTitleAsync(
        Stream pdfStream,
        CancellationToken cancellationToken = default);
}

public sealed record TitleRecognitionResult(
    string Title,
    double Confidence,
    string Reasoning);
```

**Input:** PDF-Stream (beliebige Länge, nur erste Seite wird verarbeitet)  
**Output:** Titel (leer bei Fehler), Confidence 0.0–1.0, Reasoning (für Debugging/Logging)

---

## 2. GitHub Models Endpoint

**Base URL:** `https://models.github.ai/inference`  
**Model:** `openai/gpt-4o`  
**API-Stil:** OpenAI Chat Completions (kompatibel)

### Request Headers
```http
POST /chat/completions HTTP/1.1
Host: models.github.ai
Authorization: Bearer <GITHUB_PAT>
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
Content-Type: application/json
```

### Request Payload
```json
{
  "model": "openai/gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "<SYSTEM_PROMPT>"
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "<USER_PROMPT>"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/png;base64,<BASE64_PNG>",
            "detail": "high"
          }
        }
      ]
    }
  ],
  "max_tokens": 150,
  "temperature": 0.1,
  "response_format": { "type": "json_object" }
}
```

**Notes:**
- `detail: "high"` → bessere Erkennung kleiner Schrift, höherer Token-Verbrauch (~1500–3000 Tokens)
- `temperature: 0.1` → deterministische Ausgabe, minimale Halluzinationen
- `response_format: json_object` → erzwingt JSON-Antwort (reduziert Parsing-Fehler)

---

## 3. Prompt Design

### System Prompt (Deutsch)
```text
Du bist ein Experte für das Lesen von Notenblättern für Blasmusik, Volksmusik und klassische Ensembles.

Deine Aufgabe:
1. Extrahiere NUR den Titel des Musikstücks aus dem Notenblatt.
2. Ignoriere Komponistennamen, Arrangeure, Instrumentenbezeichnungen (z. B. "Trompete in B", "1. Stimme"), Verlagsnamen, Katalognummern.
3. Der Titel steht typischerweise zentral oben auf der ersten Seite und ist oft größer/fetter gesetzt als anderer Text.
4. Falls mehrere Textelemente vorhanden sind: Wähle dasjenige, das am ehesten den Werktitel beschreibt (nicht "Klarinette" oder "Partitur", sondern z. B. "An der schönen blauen Donau").

Antworte STRIKT im folgenden JSON-Format:
{
  "title": "Der extrahierte Titel",
  "confidence": 0.95,
  "reasoning": "Der Titel steht zentriert oben in großer Schrift. Komponistenname 'Johann Strauss' wurde ignoriert."
}

Regeln:
- "title" ist ein String (leer, falls kein Titel erkennbar).
- "confidence" ist eine Zahl zwischen 0.0 und 1.0 (0.0 = völlig unsicher, 1.0 = absolut sicher).
- "reasoning" erklärt kurz deine Entscheidung (auf Deutsch, max. 1–2 Sätze).
- Falls kein Titel lesbar ist oder das Bild kein Notenblatt zeigt: {"title":"","confidence":0.0,"reasoning":"Kein Titel erkennbar."}
```

### User Prompt (Deutsch)
```text
Analysiere dieses Notenblatt und extrahiere den Titel des Musikstücks. Antworte ausschließlich mit dem JSON-Objekt wie beschrieben.
```

**Rationale:**
- Deutsch, da Blaskapellen-Noten typischerweise deutschsprachige Titel tragen (auch italienische/lateinische Titel werden korrekt erkannt).
- Explizite Beispiele für zu ignorierende Elemente (Komponist, Arrangement, Instrument) reduzieren False Positives.
- `reasoning`-Feld ermöglicht Debugging bei unerwarteten Ergebnissen.

---

## 4. JSON Schema (Response)

**Draft-07 Schema:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["title", "confidence", "reasoning"],
  "properties": {
    "title": {
      "type": "string",
      "description": "Der extrahierte Titel des Musikstücks (leer, falls nicht erkennbar)."
    },
    "confidence": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Konfidenz der Erkennung (0.0 = unsicher, 1.0 = sicher)."
    },
    "reasoning": {
      "type": "string",
      "description": "Begründung der Entscheidung (1–2 Sätze, Deutsch)."
    }
  },
  "additionalProperties": false
}
```

**C# DTO:**
```csharp
internal sealed record ApiTitleResponse(
    [property: JsonPropertyName("title")] string Title,
    [property: JsonPropertyName("confidence")] double Confidence,
    [property: JsonPropertyName("reasoning")] string Reasoning);
```

---

## 5. Response Validation

### Parsing (System.Text.Json)
```csharp
JsonSerializerOptions options = new()
{
    PropertyNameCaseInsensitive = true,
    AllowTrailingCommas = true,
    ReadCommentHandling = JsonCommentHandling.Skip
};

ApiTitleResponse? response = JsonSerializer.Deserialize<ApiTitleResponse>(
    responseBody, options);
```

### Fehlerbehandlung
| Fehlertyp | Aktion | Rückgabe |
|-----------|--------|----------|
| JSON-Parse-Fehler | Log warning, treat as recognition failure | `TitleRecognitionResult("", 0.0, "Ungültige API-Antwort")` |
| Fehlende Felder (`title`/`confidence`/`reasoning` null) | Log warning, treat as failure | `TitleRecognitionResult("", 0.0, "Unvollständige API-Antwort")` |
| `confidence` außerhalb 0.0–1.0 | Clamp to range | `Math.Clamp(response.Confidence, 0.0, 1.0)` |
| Leerer `title` mit `confidence > 0` | Accept (valid case: kein Titel gefunden) | `TitleRecognitionResult("", response.Confidence, response.Reasoning)` |

**Regel:** Malformed JSON → Confidence = 0.0 → Orchestrator routet zu `_unerkannt/`.

---

## 6. Confidence Handling

### Schwellenwerte
| Confidence | Verhalten | User-sichtbar |
|------------|-----------|---------------|
| **≥ 0.8** | Auto-Accept | PDF → `<Titel>.pdf` ohne Warnung |
| **0.6 – 0.8** | Accept mit Warnung | PDF → `<Titel>.pdf` + ⚠️-Icon im UI (zukünftig) |
| **< 0.6** | Reject | PDF → `_unerkannt/<original-dateiname>.pdf` |

### Rationale
- **≥ 0.8:** Empirisch <5% Fehlerquote bei GPT-4o Vision für Texterkennung; für MVP ohne Review akzeptabel.
- **0.6–0.8:** Grauzone mit ~15% Korrektur-Bedarf; User soll Plausibilität prüfen.
- **< 0.6:** Auto-Label wäre aufwändiger zu korrigieren als manuelle Erfassung.

### Orchestrator-Logik
```csharp
string targetPath = result.Confidence >= 0.6
    ? Path.Combine(targetDir, $"{SanitizeFilename(result.Title)}.pdf")
    : Path.Combine(targetDir, "_unerkannt", originalFilename);

if (result.Confidence is >= 0.6 and < 0.8)
{
    _logger.LogWarning("Titel '{Title}' mit niedriger Konfidenz {Confidence:F2}",
        result.Title, result.Confidence);
}
```

**Wichtig:** Originalfilename bleibt in `_unerkannt/` erhalten → User kann manuelle Benennung durchführen.

---

## 7. Image Preprocessing

### Pipeline
1. **PDF → Raster:** PdfPig Page 1 → SkiaSharp-Rendering mit 300 DPI
2. **Format:** PNG (verlustfrei, bessere Texterkennung als JPEG)
3. **Kompression:** PNG-Level 6 (Standard)
4. **Größenlimit:** ≤ 4 MB (GitHub Models Limit; bei Überschreitung → Downscale auf 200 DPI)
5. **Encoding:** Base64 Data URI → `data:image/png;base64,<BASE64>`

### Code-Skizze
```csharp
using PdfPig;
using PdfPig.Content;
using SkiaSharp;

byte[] RenderPdfPageToPng(Stream pdfStream, int dpi = 300)
{
    using PdfDocument pdf = PdfDocument.Open(pdfStream);
    Page page = pdf.GetPage(1);
    
    float scale = dpi / 72f;
    int width = (int)(page.Width * scale);
    int height = (int)(page.Height * scale);
    
    using var surface = SKSurface.Create(new SKImageInfo(width, height));
    SKCanvas canvas = surface.Canvas;
    canvas.Clear(SKColors.White);
    
    // Render page (simplified; real impl uses PdfPig rendering API)
    // ...
    
    using SKImage image = surface.Snapshot();
    using SKData data = image.Encode(SKEncodedImageFormat.Png, 100);
    
    byte[] pngBytes = data.ToArray();
    
    // Fallback: Downscale if > 4 MB
    if (pngBytes.Length > 4 * 1024 * 1024)
        return RenderPdfPageToPng(pdfStream, dpi: 200);
    
    return pngBytes;
}

string ToDataUri(byte[] pngBytes) =>
    $"data:image/png;base64,{Convert.ToBase64String(pngBytes)}";
```

**Hinweis:** PdfPig bietet kein direktes Raster-Rendering; Alternativen:
- **PdfiumViewer** (native Wrapper, Windows-only)
- **Ghostscript.NET** (plattformübergreifend, externe Dependency)
- **SkiaSharp + PDFSharp** (hybride Lösung)

→ Implementierungsdetail an Alonso (Backend-Engineer) delegieren.

---

## 8. Rate Limiting & Retry

### Semaphore-basierte Queue
```csharp
private static readonly SemaphoreSlim _semaphore = new(2, 2); // Max 2 parallel

public async ValueTask<TitleRecognitionResult> RecognizeTitleAsync(
    Stream pdfStream, CancellationToken ct)
{
    await _semaphore.WaitAsync(ct);
    try
    {
        return await RecognizeWithRetryAsync(pdfStream, ct);
    }
    finally
    {
        _semaphore.Release();
    }
}
```

**Rationale:** GitHub Models Free-Tier RPM ~10–20 (geschätzt); Semaphore verhindert 429-Flut.

### Polly Retry Policy
```csharp
using Polly;
using Polly.Contrib.WaitAndRetry;

private static readonly ResiliencePipeline _pipeline = new ResiliencePipelineBuilder()
    .AddRetry(new()
    {
        MaxRetryAttempts = 3,
        Delay = TimeSpan.FromSeconds(1),
        BackoffType = DelayBackoffType.Exponential, // 1s, 2s, 4s
        UseJitter = true,
        ShouldHandle = new PredicateBuilder().Handle<HttpRequestException>()
            .HandleResult<HttpResponseMessage>(r =>
                r.StatusCode == HttpStatusCode.TooManyRequests ||
                (int)r.StatusCode >= 500)
    })
    .Build();
```

**Jitter:** ±20% (Polly-Default) verhindert Thundering Herd bei Batch-Verarbeitung.

### Circuit Breaker (Optional)
```csharp
.AddCircuitBreaker(new()
{
    FailureRatio = 0.5,
    MinimumThroughput = 10,
    BreakDuration = TimeSpan.FromMinutes(1)
})
```

**Anwendungsfall:** Falls GitHub Models komplett down → Nach 5 Failures für 1 Min pausieren statt weiter zu hammern.

---

## 9. Auth Abstraction

### Interface
```csharp
public interface ITitleRecognizerTokenProvider
{
    ValueTask<string> GetTokenAsync(CancellationToken cancellationToken = default);
}
```

### Windows Implementation (Credential Manager)
```csharp
internal sealed class WindowsCredentialManagerTokenProvider : ITitleRecognizerTokenProvider
{
    private const string CredentialTarget = "Sheetstorm.PdfLabeler.GitHubToken";
    
    public ValueTask<string> GetTokenAsync(CancellationToken ct)
    {
        string token = CredentialManager.ReadCredential(CredentialTarget)
            ?? throw new InvalidOperationException(
                $"GitHub PAT nicht gefunden. Bitte mit 'cmdkey /generic:{CredentialTarget} /user:github /pass:<PAT>' speichern.");
        
        return ValueTask.FromResult(token);
    }
}

// CredentialManager.cs (P/Invoke Wrapper)
internal static class CredentialManager
{
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(
        string target, int type, int flags, out IntPtr credential);
    
    [DllImport("advapi32.dll")]
    private static extern void CredFree(IntPtr credential);
    
    public static string? ReadCredential(string target)
    {
        if (!CredRead(target, 1 /* GENERIC */, 0, out IntPtr credPtr))
            return null;
        
        try
        {
            var cred = Marshal.PtrToStructure<CREDENTIAL>(credPtr);
            return Marshal.PtrToStringUni(cred.CredentialBlob, 
                (int)cred.CredentialBlobSize / 2);
        }
        finally
        {
            CredFree(credPtr);
        }
    }
    
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL
    {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        // ... (weitere Felder ausgelassen)
    }
}
```

### Security Rules (KRITISCH)
- **NIEMALS** PAT in `appsettings.json`, Environment Variables (außer CI), Logs, Telemetry, Exception-Messages.
- **NIEMALS** PAT serialisiert (JSON/XML) oder in Datenbankschema.
- **NIEMALS** PAT in Git-Commits (auch nicht in History).
- Token-Rotation alle 90 Tage (organisatorische Maßnahme, nicht technisch erzwungen).

---

## 10. Testability

### HttpClient Injection (IHttpClientFactory)
```csharp
// Startup.cs / Program.cs
builder.Services.AddHttpClient<ITitleRecognizer, GitHubModelsTitleRecognizer>(client =>
{
    client.BaseAddress = new Uri("https://models.github.ai/");
    client.Timeout = TimeSpan.FromSeconds(30);
});
```

### Unit Test (Mocked Handler)
```csharp
[Fact]
public async Task RecognizeTitleAsync_ValidResponse_ReturnsParsedTitle()
{
    // Arrange
    var mockHandler = new MockHttpMessageHandler();
    mockHandler.When("https://models.github.ai/chat/completions")
        .Respond("application/json", """
            {
              "choices": [{
                "message": {
                  "content": "{\"title\":\"Egerländer Polka\",\"confidence\":0.92,\"reasoning\":\"Titel zentral oben.\"}"
                }
              }]
            }
            """);
    
    var httpClient = new HttpClient(mockHandler);
    var tokenProvider = new FakeTokenProvider("ghp_test");
    var recognizer = new GitHubModelsTitleRecognizer(httpClient, tokenProvider);
    
    using var pdfStream = File.OpenRead("test.pdf");
    
    // Act
    var result = await recognizer.RecognizeTitleAsync(pdfStream);
    
    // Assert
    Assert.Equal("Egerländer Polka", result.Title);
    Assert.Equal(0.92, result.Confidence, precision: 2);
}

private sealed class FakeTokenProvider : ITitleRecognizerTokenProvider
{
    private readonly string _token;
    public FakeTokenProvider(string token) => _token = token;
    public ValueTask<string> GetTokenAsync(CancellationToken ct) => 
        ValueTask.FromResult(_token);
}
```

**Regel:** KEINE echten API-Calls in Unit-Tests (slow, flaky, kostenpflichtig). Integration-Tests optional in separater Suite.

---

## 11. Failure Taxonomy

| Error Type | HTTP | Detection | Action | User Message (DE) |
|------------|------|-----------|--------|-------------------|
| **Unauthorized** | 401 | Response status | Log error, return confidence=0 | "GitHub-Authentifizierung fehlgeschlagen. Bitte PAT prüfen." |
| **Forbidden** | 403 | Response status | Log error, return confidence=0 | "Zugriff auf GitHub Models verweigert. Scope 'models:read' erforderlich." |
| **Model Not Found** | 404 | Response status | Log error, fallback to gpt-4o-mini | "Modell 'gpt-4o' nicht verfügbar. Fallback verwendet." |
| **Rate Limit** | 429 | Response status | Polly retry (3x), then fail | "GitHub Models Rate-Limit erreicht. Bitte später erneut versuchen." |
| **Server Error** | 5xx | Response status | Polly retry (3x), then fail | "GitHub Models vorübergehend nicht erreichbar." |
| **Timeout** | — | HttpClient timeout (30s) | Retry, then fail | "Anfrage an GitHub Models abgebrochen (Timeout)." |
| **JSON Parse** | 200 | JsonException | Log warning, return confidence=0 | "Ungültige Antwort von GitHub Models." |
| **Low Confidence** | 200 | `confidence < 0.6` | Route to `_unerkannt/` | "(Kein User-Fehler; PDF landet in '_unerkannt'-Ordner)" |

### Logging-Strategie
```csharp
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Unauthorized)
{
    _logger.LogError("GitHub Models authentication failed. Check PAT and scopes.");
    return new TitleRecognitionResult("", 0.0, 
        "GitHub-Authentifizierung fehlgeschlagen. Bitte PAT prüfen.");
}
catch (JsonException ex)
{
    _logger.LogWarning(ex, "Failed to parse GitHub Models response: {ResponseBody}", 
        responseBody);
    return new TitleRecognitionResult("", 0.0, "Ungültige API-Antwort");
}
```

**Wichtig:** Log-Level:
- `LogError` → 401/403/404 (Konfigurationsfehler)
- `LogWarning` → 429/5xx/Timeout (transiente Fehler)
- `LogInformation` → Erfolgreiche Erkennung mit Confidence

---

## 12. Cost Notes

### Token-Schätzung pro Request
| Component | Tokens (Estimate) |
|-----------|-------------------|
| System Prompt | ~250 tokens |
| User Prompt | ~30 tokens |
| Image (300 DPI, PNG, hi-res) | ~1500–3000 tokens (detail=high) |
| Response (JSON) | ~50 tokens |
| **TOTAL INPUT** | **~1800–3300 tokens** |
| **TOTAL OUTPUT** | **~50 tokens** |

### GitHub Models Free-Tier (Stand 2026-04)
- **RPM (Requests per Minute):** ~10–20 (undokumentiert; basierend auf Community-Reports)
- **TPM (Tokens per Minute):** Unbekannt; vermutlich ~40k–60k
- **Monatliches Limit:** Unklar (GitHub kommuniziert nur "fair use")

### Batch-Processing-Schätzung
- **100 PDFs:** ~330k Input-Tokens → ~10–15 Minuten bei 2 parallel (Semaphore)
- **1000 PDFs:** ~3.3M Input-Tokens → ~2 Stunden bei 2 parallel

### Fallback: gpt-4o-mini
Falls Free-Tier zu restriktiv oder User-Feedback "zu langsam":
```json
{
  "model": "openai/gpt-4o-mini"
}
```

**Trade-offs:**
- **Kosten:** ~60% günstiger (falls kostenpflichtig)
- **RPM:** Höhere Rate Limits (geschätzt 3–5x)
- **Qualität:** Marginal schlechter bei komplexen Layouts (~5–10% mehr Low-Confidence-Fälle)

→ Entscheidung nach MVP-Nutzerdaten.

---

## 13. Open Questions / Future Work

1. **PdfPig Raster-Rendering:** Welche Library für PDF→PNG? (Alonso evaluiert)
2. **Circuit Breaker Threshold:** 5 Failures oder 10? (Telemetrie abwarten)
3. **User-Feedback-Loop:** ⚠️-Icon im UI für 0.6–0.8-Confidence? (UX-Team)
4. **Prompt Versioning:** v1 im Code hardcoded; später `.prompt`-Files + Versionierung? (Shuri entscheidet nach MVP)
5. **Multi-Page PDFs:** Soll Seite 2+ geprüft werden, falls Seite 1 kein Titel? (Nein für MVP; Edge-Case)

---

**Version:** 1.0 (2026-04-20)  
**Author:** Shuri (AI Engineer)  
**Status:** Ready for Implementation
