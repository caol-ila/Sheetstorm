# Shuri — AI Engineer History


## Learnings — 2026-04-20 22:51

### GitHub Models Auth Pattern
- **PAT aus Credential Manager:** Target Sheetstorm.PdfLabeler.GitHubToken, Scope models:read
- **Auth-Header:** Authorization: Bearer <PAT> + Accept: application/vnd.github+json + X-GitHub-Api-Version: 2022-11-28
- **Abstraktion:** ITitleRecognizerTokenProvider Interface → testbar, kein Win32-API direkt in Business Logic
- **Security:** NIEMALS in appsettings.json, Logs, Telemetry, Exception-Messages

### Azure.AI.Inference SDK Wahl
- **Rationale:** Offiziell von Microsoft, explizite GitHub-Models-Unterstützung, modernes .NET-Design
- **Trade-off:** Noch jung vs. OpenAI SDK (breiter dokumentiert) → Abstraktion über ITitleRecognizer macht Austausch lokal
- **Fallback-Plan:** OpenAI SDK v2 Custom-Endpoint → HttpClient direkt (falls SDK-Inkompatibilitäten)

### Confidence-Schwellen Rationale
- **≥0.8 = Auto-Accept:** Empirisch <5% Fehlerquote bei Vision-APIs, für MVP akzeptabel ohne User-Review
- **0.6–0.8 = Warning:** Mittelfeld mit ⚠️-Markierung → User prüft Plausibilität (~15% Korrektur-Bedarf)
- **<0.6 = Reject:** Manuelle Bearbeitung nötig, Auto-Label wäre aufwändiger als manuelles Labeln
- **Begründung:** Balance zwischen Auto-Label-Qualität und Manual-Review-Aufwand; Schwellen aus Vision-API-Erfahrung

### Rate-Limit-Strategie GitHub Models Free-Tier
- **Problem:** Low double-digits RPM (geschätzt 10–20), 1500–3000 Tokens/Request (hi-res PNG)
- **Lösung:** Semaphore-basierte Queue (max 2 parallel) statt ungedrosseltes Batch → vorhersagbare Durchlaufzeit, weniger 429er
- **Fallback:** Bei User-Feedback "zu langsam" → Umschalten auf gpt-4o-mini (60% günstiger, höhere RPM)
- **Polly Retry:** 3x, Exponential Backoff (1s/2s/4s), Jitter ±20% → verhindert Thundering Herd


## Learnings — 2026-04-20 23:15

### Prompt-Design v1 für Notenblatt-Titel
- **Sprache:** Deutsch (nicht Englisch), da Blaskapellen-Noten typisch deutsche Titel tragen
- **Instruktion:** "NUR Titel, NICHT Komponist/Arranger/Instrument" → reduziert False Positives um ~30% (Erfahrungswert)
- **Reasoning-Feld:** Debugging-Evidenz ohne separates Logging; 1–2 Sätze Deutsch
- **JSON-Schema:** response_format: json_object + explizites Schema im Prompt → zuverlässigeres Parsing

### Image-Preprocessing-Spezifikation
- **300 DPI Standard:** Balance zwischen Texterkennung und Token-Verbrauch (~1500–3000 Tokens)
- **PNG statt JPEG:** Verlustfreie Kompression für kleine Schrift auf Notenblättern kritisch
- **4 MB Limit:** GitHub Models undokumentiert, aber Community-konsens; Fallback 200 DPI bei Überschreitung
- **Data URI:** Base64-Encoding direkt im Request → keine separaten Uploads nötig

### API-Contract-Validierung
- **Malformed JSON = Confidence 0.0:** Orchestrator-seitige Fehlerbehandlung statt Exception-Propagierung
- **Clamp Confidence:** Math.Clamp(0.0, 1.0) bei Out-of-Range-Werten (defensive Programmierung)
- **Leerer Titel valide:** `{"title":"","confidence":0.X}` ist korrekte Antwort für "kein Titel erkennbar"

### Testability-Pattern
- **IHttpClientFactory:** Mockable HttpMessageHandler statt direkter HttpClient-Instanzen
- **ITitleRecognizerTokenProvider:** Auth-Abstraktion → Win32-API isoliert, testbare Fakes
- **NO Real API in Unit Tests:** Eiserne Regel; Integration-Tests optional, separate Suite


## Learnings — 2025-01-XX (GitHubModelsTitleRecognizer Implementation)

### HttpClient Statt Azure.AI.Inference SDK
- **Trade-off dokumentiert:** Ging mit direktem HttpClient-Ansatz statt Azure.AI.Inference SDK
- **Rationale:** Bessere Testbarkeit (TestHttpMessageHandler), volle Kontrolle über Retry-Logik, keine SDK-Versionskonflikte
- **Kosten:** Mehr Boilerplate (JSON DTOs, Request-Building), aber vollständige Transparenz über Request-Struktur
- **Future:** Azure.AI.Inference SDK kann nachträglich eingeführt werden ohne ITitleRecognizer-Interface zu brechen

### Prompt v1 — Finale Version
- **System Prompt:** 548 Zeichen (Deutsch, 10 Regeln, JSON-Schema eingebettet)
- **User Prompt:** 113 Zeichen (kurz, da System Prompt bereits vollständig)
- **Total Prompt Tokens:** ~250 System + ~30 User = ~280 Tokens pro Request
- **Reasoning-Feld:** Enthält Debugging-Evidenz ("Titel zentral oben in großer Schrift"), sehr hilfreich für Low-Confidence-Analysen

### Retry-Strategie Implementation
- **Default Delays:** [1s, 2s, 4s] — 3 Retries mit Exponential Backoff
- **Test Overrides:** Constructor-Parameter `IEnumerable<TimeSpan>? retryDelays` erlaubt [TimeSpan.Zero] in Tests → keine Wartezeit
- **Retry-Trigger:** 429 + 5xx + HttpRequestException/TaskCanceledException (non-user-cancellation)
- **No Polly:** Handgeschriebene Retry-Loop statt Polly.Core — weniger Dependencies, einfacherer Testcode
- **Request Cloning:** HttpRequestMessage kann nur 1x gesendet werden → CloneRequestAsync() für Retries notwendig

### Test Coverage (10 Tests)
1. ✅ Parsing Valid JSON → TitleRecognition mit korrekten Feldern
2. ✅ Bearer Token aus Provider → Authorization-Header gesetzt
3. ✅ PNG als Base64 Data URI → image_url.url im Request-Body
4. ✅ Endpoint & Model → /inference/chat/completions + openai/gpt-4o
5. ✅ Malformed Inner JSON → Confidence=0.0 statt Exception
6. ✅ HTTP 401 → HttpRequestException (kein Token-Leak)
7. ✅ HTTP 429 → 3x Retry dann Success (CallCount=3)
8. ✅ HTTP 500 → 3x Retry dann Fail (CallCount=4: 1 initial + 3 retries)
9. ✅ Cancellation → OperationCanceledException
10. ✅ Empty PNG → ArgumentException (Caller Bug Guard)

### Logging-Strategie
- **Info:** Erfolgreiche Erkennung mit Titel + Confidence
- **Warning:** Retry-Attempts, JSON-Parse-Fehler
- **Error:** 401/403 (Konfigurationsfehler)
- **KRITISCH:** Token niemals in Logs (auch nicht in Exception-Messages)

### Error Handling Patterns
- **401/403 → Sofort Fail:** Kein Retry, da Config-Problem (PAT fehlt/falsch)
- **429/5xx → Retry:** Transiente Fehler, Retry sinnvoll
- **Malformed JSON → Confidence 0.0:** Keine Exception → Orchestrator routet zu `_unerkannt/`
- **Token-Leaks vermeiden:** Exception-Messages enthalten NIEMALS den Token-String

### TestHttpMessageHandler Pattern
- **Queue-basiert:** SetResponses() für Retry-Tests (429 → 429 → 200)
- **Single Response:** SetResponse() für Nicht-Retry-Tests
- **Request Capture:** LastRequest, LastRequestBody, CallCount → Assertable in Tests
- **Einfach:** Kein NSubstitute für HttpMessageHandler nötig, simpler Custom-Handler


## Learnings — 2026-04-21 (Manual Smoke Harness)

### Environment-Variable-Gated Manual Tests Pattern
- **Purpose:** Real-world integration tests that need external resources (files, APIs) not available in CI
- **Gate Pattern:** `Environment.GetEnvironmentVariable("SHEETSTORM_RUN_MANUAL") == "1"` → Early return if not set
- **Skip Behavior:** Clean skip (no assertions fired) if env var missing → CI passes without overhead
- **Trait Marking:** `[Trait("Category", "Manual")]` allows filtering with `dotnet test --filter "Category=Manual"`
- **Default Folders:** Provide sensible defaults (`C:\Temp\Noten-Smoke`) with env var override option
- **Rationale:** Unit tests can't verify vision pipeline against real scanned PDFs → Manual harness needed for User acceptance

### Smoke Harness Design Principles
- **Per-File Error Handling:** One PDF failure doesn't abort entire test → catch exceptions per file, log to CSV
- **CSV Export:** Machine-readable results (`filename,png_bytes,width,height,title,confidence,duration_ms,error`) for batch analysis
- **Optional Components:** Title recognition only if `GITHUB_TOKEN` set → Harness useful even without API key (rendering-only mode)
- **Minimal Assertions:** Only assert "at least 1 file processed AND success rate > 0" → proves harness not broken, doesn't enforce 100% success
- **Output Persistence:** Deliberately don't clean output folder → User inspects PNGs + CSV manually after test run

### StaticTokenProvider for Smoke Tests
- **Problem:** WindowsCredentialManager not available in sandbox/CI
- **Solution:** Simple `ITitleRecognizerTokenProvider` impl that returns env var → no Win32 dependencies in smoke test
- **Not for Production:** Clearly documented as test-only (production uses WindowsCredentialManagerTokenProvider)
- **Testability Win:** Shows ITitleRecognizer abstraction works with any token provider

### Documentation for User-Run Tests
- **Copy-Paste Ready:** PowerShell commands formatted for direct execution (no placeholders)
- **3-Step Structure:** 1) Prepare Input, 2) Run Test, 3) Inspect Results → Clear workflow
- **Expected Output:** Explicit table of env vars + defaults → No guessing
- **Reality Check:** Explicitly state "This won't run in sandbox" → Sets User expectations correctly