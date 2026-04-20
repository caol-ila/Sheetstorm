# Romanoff — History

## Core Context

- **Project:** Notenmanagement-App für Blaskapellen mit Flutter-Frontend und ASP.NET Core Backend
- **Role:** Tester
- **Joined:** 2026-04-20T20:35:39.916Z

## Learnings

### 2026-04-20: PdfLabeling Module - Initial RED Tests

**Task:** Create comprehensive RED tests for `FileNameSanitizer` and `FileTargetResolver` services.

**Deliverables:**
- `tests/Sheetstorm.PdfLabeling.Tests/Services/FileNameSanitizerTests.cs` — 11 test methods (7 Facts + 4 Theories)
- `tests/Sheetstorm.PdfLabeling.Tests/Services/FileTargetResolverTests.cs` — 8 test methods (all Facts)

**Test Coverage:**

*FileNameSanitizer:*
- Simple/valid titles pass through unchanged
- Invalid Windows filename chars (`<>:"/\|?*`) replaced with underscore
- Control chars (`\0\t\n\r`) removed
- Multiple spaces collapsed to single space
- Leading/trailing whitespace trimmed
- Truncation to 150 chars max
- Reserved Windows names (CON, PRN, AUX, NUL, COM1-9, LPT1-9) prefixed
- Empty/whitespace/null input returns fallback
- Trailing dots/spaces trimmed (Windows compatibility)

*FileTargetResolver:*
- Empty directory returns requested name
- Existing file triggers suffix `(2)`
- Multiple collisions increment suffix `(3)`, `(4)`...
- Gaps in sequence filled with first free number
- Extension casing preserved
- Case-insensitive collision detection on Windows
- Missing directory throws `DirectoryNotFoundException`
- Extension parameter works with or without leading dot

**RED Evidence:**
- Total tests: **56** (41 InlineData theory expansions + 15 method-level tests)
- Failed: **56**
- Passed: **0**
- All failures: `NotImplementedException` from service stubs (as expected)

**Coordination Notes:**
- Waited for Rogers' scaffold (6 poll attempts × 15s)
- Service stubs created with expected signatures
- Build cache issue resolved with `dotnet clean`
- Project dependencies correctly configured (FluentAssertions 8.9.0, NSubstitute 5.3.0)

**Contract Decisions Made:**
- FileTargetResolver throws `DirectoryNotFoundException` when target directory missing (orchestrator responsible for directory creation)
- Extension parameter accepts both `.pdf` and `pdf` formats
- Invalid chars replaced with `_` (not removed)
- Fallback name for empty/null inputs must be non-empty (exact value TBD by implementer)

<!-- Append learnings below -->
