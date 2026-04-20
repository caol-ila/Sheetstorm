# Decision: Flutter Desktop Process Integration Pattern

**Scope:** Flutter Windows Desktop ↔ Native CLI Integration (#124)  
**Owner:** Parker (Frontend Dev)  
**Status:** PROPOSED (awaiting Rogers integration validation)  
**Date:** 2026-04-21

## Decision

Use **`Process.start()` with NDJSON stdout streaming** for Flutter ↔ CLI integration.

## Context

`sheetstorm_pdf_labeler` (Flutter Windows) needs to drive `Sheetstorm.PdfLabeling.Cli` (.NET 10 console) as a subprocess for AI-powered PDF title recognition. Requirements:
- Secure PAT transmission (no argv logging)
- Real-time progress updates (streaming, not batch)
- Cancellation support
- Cross-platform path resolution (debug vs. release)

## Alternatives Considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **1. Process.start() + NDJSON** | Stream events, PAT in env, cancellable | Manual stdout parsing | **CHOSEN** |
| 2. Named pipes / IPC | Lower latency, binary protocol | Windows-only, complex setup | ❌ Overkill for MVP |
| 3. HTTP server (localhost) | REST API familiar | Port conflicts, overhead | ❌ Too heavyweight |
| 4. FFI (native DLL) | Direct calls, fast | Packaging complexity, harder to test | ❌ CLI reuse blocked |

## Implementation

```dart
// Service spawns CLI with PAT in environment
final process = await Process.start(
  cliPath,
  ['--source', source, '--target', target, '--confidence', confidence.toString()],
  environment: {'SHEETSTORM_PAT': pat}, // NOT in argv
  runInShell: true,
);

// Parse NDJSON line-by-line
process.stdout
  .transform(utf8.decoder)
  .transform(const LineSplitter())
  .listen((line) {
    final json = jsonDecode(line);
    final event = _parseEvent(json); // ProgressEvent | ResultEvent | ErrorEvent | DoneEvent
    controller.add(event);
  });
```

**CLI Path Resolution:**
- **Debug:** `../src/Sheetstorm.PdfLabeling.Cli/bin/Debug/net10.0/Sheetstorm.PdfLabeling.Cli.exe` (relative to repo root)
- **Release:** `<exe-dir>/cli/Sheetstorm.PdfLabeling.Cli.exe` (adjacent to Flutter .exe)
- **Override:** `--dart-define=CLI_PATH=...` for custom scenarios

**Cancellation:**
- `process.stdin.close()` + `process.kill()` after grace period
- Alternative: `--cancel-file <path>` (CLI polls file, less reliable)

## Implications

**Positive:**
- Testable: Mock NDJSON events in tests (no real CLI needed)
- Secure: PAT never in argv (process list safe)
- Responsive: Stream events enable real-time UI updates

**Risks:**
1. **Stdout Buffering:** Large outputs may block → mitigated by line-by-line parsing
2. **Error Handling:** CLI crash = stream ends abruptly → emit ErrorEvent on onDone
3. **Path Resolution Fragility:** Relative paths break if CWD changes → document convention

## Validation Criteria

- [ ] Rogers's CLI emits NDJSON events (Progress, Result, Done) on stdout
- [ ] PAT read from `SHEETSTORM_PAT` environment variable
- [ ] Cancellation via stdin close OR `--cancel-file` works
- [ ] E2E test: Flutter calls CLI, parses events, displays results

## Open Questions

1. Should we add a heartbeat event (e.g., every 5s) to detect hung CLI?
2. CLI stderr handling: ignore, log, or emit as ErrorEvent?
3. Timeout for CLI startup (e.g., 10s max before first event)?

## Related

- Spec: `docs/specs/mvp-pdf-labeler.md` §3.4 (Integration Flow)
- Code: `lib/src/services/labeling_service.dart` (implementation)
- Issue: #124 (PDF Labeler MVP)
