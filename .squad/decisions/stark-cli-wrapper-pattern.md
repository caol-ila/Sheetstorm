# CLI-Wrapper Pattern for Flutter Desktop Integration

**Decision Owner:** Stark (Lead)  
**Status:** ACTIVE  
**Date:** 2026-04-21  
**Context:** PDF Labeler MVP (#124) — Flutter Desktop UI + C# Library integration

---

## Decision

When integrating Flutter Desktop with C# business logic, use a **CLI Wrapper Pattern** emitting **NDJSON on stdout** instead of:
1. Embedding C# via native FFI (e.g., `dart:ffi` + P/Invoke)
2. Running a long-lived HTTP server (e.g., ASP.NET Core API for local IPC)
3. Named pipes / sockets for direct IPC

---

## Rationale

**CLI Wrapper = Simplicity + Security + Testability**

### Why NDJSON on stdout?

1. **Simple Integration:**  
   - Flutter: `Process.start(exe, args)` + `stdout.transform(LineSplitter())`  
   - No FFI bindings, no HTTP client setup, no named pipe discovery  
   - Platform-agnostic: Works on Windows/macOS/Linux without code changes (beyond exe path)

2. **Security Benefits:**  
   - PAT passed via **environment variable** (not argv) → never visible in `ps`/Task Manager  
   - CLI process isolated from UI process → crash in CLI doesn't kill UI  
   - No network stack exposed (vs. localhost HTTP server with CORS/auth complexity)

3. **Testability:**  
   - CLI fully testable standalone: `echo '{"folder":"..."}' | cli.exe` → verify NDJSON output  
   - Flutter side mocked easily: Replace `Process.start()` with `Stream.fromIterable([...])`  
   - Integration tests via golden files: Record CLI output, replay in Flutter tests

4. **Progress Streaming:**  
   - NDJSON = one event per line → natural fit for `Stream<String>` → `Stream<JsonMap>`  
   - Real-time progress updates without polling (vs. HTTP long-polling or WebSockets overhead)

5. **Cancellation Control:**  
   - Graceful: Send SIGINT (Ctrl+C) → CLI emits partial `"done"` event, exits cleanly  
   - Programmatic: Write to `--cancel-file` → CLI polls every N iterations, stops gracefully  
   - Hard kill: `Process.kill(pid)` if CLI hangs (timeout guard in Flutter)

---

## Pattern Components

### C# CLI Wrapper

```csharp
// Program.cs (Sheetstorm.PdfLabeling.Cli)
var rootCommand = new RootCommand("PDF Labeler CLI");
// ... add options (--folder, --template, --dry-run, --pat-env, --cancel-file) ...

rootCommand.SetHandler(async (folder, template, dryRun, patEnv, cancelFile) =>
{
    var pat = Environment.GetEnvironmentVariable(patEnv ?? "SHEETSTORM_PAT");
    if (string.IsNullOrEmpty(pat)) { Console.Error.WriteLine("PAT missing"); return 2; }

    var orchestrator = BuildOrchestrator(pat); // DI setup
    var progress = new NdjsonProgressReporter(); // IProgress<ProgressUpdate> → stdout

    var results = await orchestrator.LabelAsync(new LabelingJob(folder, template, dryRun), progress);
    
    foreach (var result in results)
    {
        Console.WriteLine(JsonSerializer.Serialize(new {
            type = "result",
            original = result.OriginalPath,
            title = result.Recognition?.Title,
            confidence = result.Recognition?.Confidence,
            status = result.Status.ToString()
        }));
    }
    Console.WriteLine(JsonSerializer.Serialize(new { type = "done", processed = results.Length }));
}, folderOption, templateOption, dryRunOption, patEnvOption, cancelFileOption);

return await rootCommand.InvokeAsync(args);
```

### Flutter Integration

```dart
// cli_service.dart
class CliService {
  Stream<LabelingEvent> startLabeling(LabelingJob job, String pat) async* {
    final process = await Process.start(
      'Sheetstorm.PdfLabeling.Cli.exe',
      ['--folder', job.folder, '--template', job.template],
      environment: {'SHEETSTORM_PAT': pat},
    );

    await for (final line in process.stdout.transform(utf8.decoder).transform(LineSplitter())) {
      final json = jsonDecode(line);
      yield switch (json['type']) {
        'progress' => ProgressEvent.fromJson(json),
        'result' => ResultEvent.fromJson(json),
        'error' => ErrorEvent.fromJson(json),
        'done' => DoneEvent.fromJson(json),
        _ => throw FormatException('Unknown event type: ${json['type']}'),
      };
    }
  }
}

// labeling_job_provider.dart (Riverpod)
final labelingJobProvider = StreamProvider.autoDispose.family<LabelingEvent, LabelingJob>(
  (ref, job) async* {
    final pat = await ref.watch(secureStorageServiceProvider).readPat();
    final service = ref.watch(cliServiceProvider);
    yield* service.startLabeling(job, pat);
  },
);
```

---

## Alternatives Considered

### 1. FFI (dart:ffi + C# P/Invoke)

**Rejected Reasons:**
- Complex setup: Export C# as native library (UnmanagedCallersOnly), manage GC across boundary  
- Platform-specific builds: Separate DLLs for Windows/macOS/Linux  
- Callback marshalling pain: Progress callbacks require delegate pinning, manual memory management  
- Debugging nightmare: Crashes in native code often kill Dart VM without stack trace

**When to Use:** Real-time bidirectional communication (e.g., audio/video processing, low-latency game engines)

### 2. Local HTTP Server (ASP.NET Core + HttpClient)

**Rejected Reasons:**
- Startup overhead: Launch Kestrel server (~200–500ms), discover random port, configure CORS  
- Security complexity: HTTPS certificate for localhost? Auth tokens for single-user desktop app?  
- Resource waste: HTTP stack + JSON parsing + connection pooling for local-only IPC overkill  
- Firewall prompts: Users see "Allow Sheetstorm.PdfLabeling.Cli.exe network access?" on first run

**When to Use:** Multi-client desktop app (e.g., Docker Desktop with CLI + GUI + browser extension all talking to same daemon)

### 3. Named Pipes / Unix Sockets

**Rejected Reasons:**
- Discovery complexity: How does Flutter find pipe name? Hardcode? Read from temp file? Registry?  
- Platform variance: Windows named pipes ≠ Unix domain sockets → platform-specific code  
- Framing protocol needed: Binary length prefix or JSON delimiter (NDJSON anyway)  
- Error handling: Pipe broken → how to restart CLI? HTTP has retry logic built-in

**When to Use:** High-throughput IPC with large binary payloads (e.g., database client talking to local server)

---

## Trade-offs

### Pros
- **Simplest integration:** No native code, no HTTP stack, no pipe discovery  
- **Secure by default:** PAT in env var, isolated processes, no network exposure  
- **Testable at every layer:** CLI standalone, Flutter mocked, E2E via golden files  
- **Real-time streaming:** NDJSON naturally maps to Dart `Stream<T>`, Riverpod `StreamProvider`

### Cons
- **Process startup overhead:** ~50–100ms to spawn CLI (vs. ~1ms for FFI call)  
- **No shared memory:** Every file path/title/error message serialized to JSON (vs. FFI passing pointers)  
- **Parsing cost:** JSON decode every event (vs. binary struct in FFI)

**Verdict:** Overhead acceptable for batch workload (hundreds of PDFs, minutes of runtime). Not suitable for real-time loops (e.g., 60 FPS game rendering).

---

## When to Use This Pattern

✅ **Good Fit:**
- Flutter Desktop + C# library integration (reuse existing .NET business logic)  
- Batch processing workflows (file conversion, data import/export, report generation)  
- Progress reporting needed (avoid blocking UI while processing)  
- PAT/secrets required (env var safer than argv or config files)

❌ **Bad Fit:**
- Real-time bidirectional communication (<10ms latency required)  
- High-throughput binary data transfer (MB/s, e.g., video streams)  
- Tight loops where process startup overhead dominates (e.g., calling CLI per keystroke)

---

## References

- **Implementation:** `src/Sheetstorm.PdfLabeling.Cli/` (Rogers), `sheetstorm_pdf_labeler/lib/features/labeling/services/cli_service.dart` (Parker)  
- **Spec:** `docs/specs/mvp-pdf-labeler.md` § "CLI-Kontrakt (NDJSON)"  
- **Issue:** #124 (PDF Labeler MVP)  
- **Commit:** bd6ad75 (spec update), 64c44dc (history)

---

## Future Improvements

1. **Binary Protocol:** If perf becomes bottleneck, replace NDJSON with MessagePack or Protocol Buffers (still via stdout)  
2. **Bidirectional Stdin:** For interactive workflows (e.g., "approve/reject each file"), CLI reads JSON commands from stdin  
3. **Error Recovery:** CLI emits `"checkpoint"` events every N files → Flutter can resume from last checkpoint on crash  
4. **Telemetry:** CLI logs to stderr, Flutter captures and forwards to OTEL collector (preserve stdout for NDJSON only)
