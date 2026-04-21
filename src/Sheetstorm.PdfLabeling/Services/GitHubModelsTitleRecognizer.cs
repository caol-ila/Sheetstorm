using Microsoft.Extensions.Logging;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Domain;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Sheetstorm.PdfLabeling.Services;

public sealed class GitHubModelsTitleRecognizer : ITitleRecognizer
{
    private readonly HttpClient _httpClient;
    private readonly ITitleRecognizerTokenProvider _tokenProvider;
    private readonly ILogger<GitHubModelsTitleRecognizer>? _logger;
    private readonly IReadOnlyList<TimeSpan> _retryDelays;

    private const string SystemPrompt = """
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
        """;

    private const string UserPrompt = "Analysiere dieses Notenblatt und extrahiere den Titel des Musikstücks. Antworte ausschließlich mit dem JSON-Objekt wie beschrieben.";

    public GitHubModelsTitleRecognizer(
        HttpClient httpClient,
        ITitleRecognizerTokenProvider tokenProvider,
        ILogger<GitHubModelsTitleRecognizer>? logger = null,
        IEnumerable<TimeSpan>? retryDelays = null)
    {
        _httpClient = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
        _tokenProvider = tokenProvider ?? throw new ArgumentNullException(nameof(tokenProvider));
        _logger = logger;
        _retryDelays = (retryDelays ?? [TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(4)]).ToList();
    }

    public async Task<TitleRecognition> RecognizeTitleAsync(byte[] pngBytes, CancellationToken ct = default)
    {
        if (pngBytes == null || pngBytes.Length == 0)
        {
            throw new ArgumentException("PNG bytes cannot be null or empty", nameof(pngBytes));
        }

        ct.ThrowIfCancellationRequested();

        var token = await _tokenProvider.GetTokenAsync(ct);

        var requestPayload = BuildRequestPayload(pngBytes);
        var requestContent = new StringContent(
            JsonSerializer.Serialize(requestPayload),
            Encoding.UTF8,
            "application/json");

        var request = new HttpRequestMessage(HttpMethod.Post, "inference/chat/completions")
        {
            Content = requestContent
        };
        
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
        request.Headers.Add("X-GitHub-Api-Version", "2022-11-28");

        _logger?.LogInformation("Sending title recognition request to GitHub Models (image size: {Size} bytes)", pngBytes.Length);

        return await ExecuteWithRetryAsync(request, ct);
    }

    private async Task<TitleRecognition> ExecuteWithRetryAsync(HttpRequestMessage request, CancellationToken ct)
    {
        Exception? lastException = null;
        var attemptCount = 0;

        while (attemptCount <= _retryDelays.Count)
        {
            try
            {
                attemptCount++;
                
                // Clone request for retries (HttpRequestMessage can only be sent once)
                var requestToSend = attemptCount == 1 ? request : await CloneRequestAsync(request);
                
                var response = await _httpClient.SendAsync(requestToSend, ct);

                if (response.IsSuccessStatusCode)
                {
                    return await ParseResponseAsync(response, ct);
                }

                if (response.StatusCode == HttpStatusCode.Unauthorized)
                {
                    _logger?.LogError("GitHub Models authentication failed. Check PAT and scopes.");
                    throw new HttpRequestException(
                        "GitHub-Authentifizierung fehlgeschlagen. Bitte PAT prüfen.",
                        null,
                        response.StatusCode);
                }

                if (response.StatusCode == HttpStatusCode.Forbidden)
                {
                    _logger?.LogError("Access to GitHub Models denied. Scope 'models:read' required.");
                    throw new HttpRequestException(
                        "Zugriff auf GitHub Models verweigert. Scope 'models:read' erforderlich.",
                        null,
                        response.StatusCode);
                }

                if (response.StatusCode == HttpStatusCode.TooManyRequests ||
                    (int)response.StatusCode >= 500)
                {
                    _logger?.LogWarning("GitHub Models request failed with status {StatusCode}. Attempt {Attempt}/{MaxAttempts}",
                        response.StatusCode, attemptCount, _retryDelays.Count + 1);

                    if (attemptCount <= _retryDelays.Count)
                    {
                        await Task.Delay(_retryDelays[attemptCount - 1], ct);
                        continue;
                    }

                    throw new HttpRequestException(
                        $"GitHub Models vorübergehend nicht erreichbar (Status: {response.StatusCode}).",
                        null,
                        response.StatusCode);
                }

                // Other error codes
                throw new HttpRequestException(
                    $"GitHub Models request failed with status {response.StatusCode}.",
                    null,
                    response.StatusCode);
            }
            catch (HttpRequestException)
            {
                throw;
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex) when (ex is TaskCanceledException or HttpRequestException)
            {
                _logger?.LogWarning(ex, "GitHub Models request failed. Attempt {Attempt}/{MaxAttempts}",
                    attemptCount, _retryDelays.Count + 1);
                
                lastException = ex;

                if (attemptCount <= _retryDelays.Count)
                {
                    await Task.Delay(_retryDelays[attemptCount - 1], ct);
                    continue;
                }

                throw new HttpRequestException(
                    "GitHub Models vorübergehend nicht erreichbar (Timeout).",
                    ex);
            }
        }

        throw lastException ?? new HttpRequestException("GitHub Models request failed.");
    }

    private async Task<HttpRequestMessage> CloneRequestAsync(HttpRequestMessage original)
    {
        var clone = new HttpRequestMessage(original.Method, original.RequestUri);
        
        if (original.Content != null)
        {
            var contentBytes = await original.Content.ReadAsByteArrayAsync();
            clone.Content = new ByteArrayContent(contentBytes);
            
            if (original.Content.Headers != null)
            {
                foreach (var header in original.Content.Headers)
                {
                    clone.Content.Headers.TryAddWithoutValidation(header.Key, header.Value);
                }
            }
        }

        foreach (var header in original.Headers)
        {
            clone.Headers.TryAddWithoutValidation(header.Key, header.Value);
        }

        return clone;
    }

    private async Task<TitleRecognition> ParseResponseAsync(HttpResponseMessage response, CancellationToken ct)
    {
        var responseBody = await response.Content.ReadAsStringAsync(ct);

        try
        {
            var apiResponse = JsonSerializer.Deserialize<GitHubModelsResponse>(responseBody);

            if (apiResponse?.Choices == null || apiResponse.Choices.Count == 0)
            {
                _logger?.LogWarning("GitHub Models returned empty choices array");
                return new TitleRecognition("", 0.0, "Ungültige API-Antwort");
            }

            var content = apiResponse.Choices[0].Message?.Content;
            if (string.IsNullOrWhiteSpace(content))
            {
                _logger?.LogWarning("GitHub Models returned empty content");
                return new TitleRecognition("", 0.0, "Ungültige API-Antwort");
            }

            try
            {
                var titleResponse = JsonSerializer.Deserialize<TitleRecognitionPayload>(content);

                if (titleResponse == null)
                {
                    _logger?.LogWarning("Failed to parse inner JSON from GitHub Models response");
                    return new TitleRecognition("", 0.0, "Ungültige API-Antwort");
                }

                var clampedConfidence = Math.Clamp(titleResponse.Confidence, 0.0, 1.0);
                
                _logger?.LogInformation("Title recognized: '{Title}' with confidence {Confidence:F2}",
                    titleResponse.Title, clampedConfidence);

                return new TitleRecognition(
                    titleResponse.Title ?? "",
                    clampedConfidence,
                    titleResponse.Reasoning);
            }
            catch (JsonException ex)
            {
                _logger?.LogWarning(ex, "Failed to parse inner JSON content: {Content}", content);
                return new TitleRecognition("", 0.0, "Ungültige API-Antwort");
            }
        }
        catch (JsonException ex)
        {
            _logger?.LogWarning(ex, "Failed to parse GitHub Models response");
            return new TitleRecognition("", 0.0, "Ungültige API-Antwort");
        }
    }

    private static object BuildRequestPayload(byte[] pngBytes)
    {
        var base64Image = Convert.ToBase64String(pngBytes);
        var dataUri = $"data:image/png;base64,{base64Image}";

        return new
        {
            model = "openai/gpt-4o",
            messages = new object[]
            {
                new
                {
                    role = "system",
                    content = SystemPrompt
                },
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = UserPrompt
                        },
                        new
                        {
                            type = "image_url",
                            image_url = new
                            {
                                url = dataUri,
                                detail = "high"
                            }
                        }
                    }
                }
            },
            max_tokens = 150,
            temperature = 0.1,
            response_format = new { type = "json_object" }
        };
    }

    private sealed record GitHubModelsResponse(
        [property: JsonPropertyName("choices")] List<Choice>? Choices);

    private sealed record Choice(
        [property: JsonPropertyName("message")] Message? Message);

    private sealed record Message(
        [property: JsonPropertyName("content")] string? Content);

    private sealed record TitleRecognitionPayload(
        [property: JsonPropertyName("title")] string? Title,
        [property: JsonPropertyName("confidence")] double Confidence,
        [property: JsonPropertyName("reasoning")] string? Reasoning);
}
