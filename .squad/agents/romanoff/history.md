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

---

### Foundation Scaffold Phase 5 — 2026-04-20

**E2E Framework:**
- Playwright TypeScript config (strict mode): baseURL, viewport, trace, screenshot on-failure
- 2 tests: Ping roundtrip (happy path) + keyboard navigation (accessibility smoke)
- CanvasKit multi-layer handling: Semantics (primary) + Screenshots (fallback) + Keyboard (accessibility)
- Accessibility-first selectors: getByRole > getByLabel > getByTestId (last resort)

**Semantics Hardening:**
- home_screen_test.dart: Added explicit `getSemantics()` assertion to verify semantic nodes
- Framework-Spec §4.2: Every widget test must include `matchesSemantics()` or equivalent
- Before: `ensureSemantics()` only enables tree (doesn't verify)
- After: Assert semantics exist + have labels (production-compliant)

**Documentation:**
- e2e/README.md: Setup + CanvasKit troubleshooting
- docs/operations/e2e.md: 15KB comprehensive guide (CanvasKit, selectors, POM, keyboard nav)

**Open Decisions for Team:**
1. Semantics activation: Production default (Option A) vs conditional (Option B) vs test-only (Option C)?
2. Visual regression: Manual review only (now) vs automated pixel-diff (future)?
3. POM threshold: <5 tests inline, 5–10 consider, >10 mandatory

**Escalation: DONE**
- All scaffold complete; cannot execute without Flutter/backend running
- Config + tests valid; CI will first-run them
- Accessibility-first approach future-proofs for WCAG compliance

**Lessons:**
1. CanvasKit opacity = non-obvious to non-Flutter devs; needs dedicated docs (done in §2, §7.3)
2. Scaffolding ≠ execution: Valid E2E tests written despite local tooling gaps; CI validates
3. Accessibility-first testing = right default (catches real user flows)
- Build cache issue resolved with `dotnet clean`
- Project dependencies correctly configured (FluentAssertions 8.9.0, NSubstitute 5.3.0)

**Contract Decisions Made:**
- FileTargetResolver throws `DirectoryNotFoundException` when target directory missing (orchestrator responsible for directory creation)
- Extension parameter accepts both `.pdf` and `pdf` formats
- Invalid chars replaced with `_` (not removed)
- Fallback name for empty/null inputs must be non-empty (exact value TBD by implementer)

### 2026-04-21: App Foundation — E2E Scaffolding (Phase 5)

**Task:** Scaffold Playwright TypeScript E2E setup for Flutter Web app (Issue #126, Branch `feat/app-scaffold`).

**Deliverables:**

E2E Infrastructure:
- `sheetstorm_app/package.json` — npm scripts for Playwright (`test:e2e`, `test:e2e:ui`, `e2e:install`)
- `sheetstorm_app/playwright.config.ts` — baseURL, trace, screenshot, viewport settings
- `sheetstorm_app/e2e/tsconfig.json` — TypeScript strict mode + Playwright types
- `sheetstorm_app/e2e/ping-roundtrip.spec.ts` — 2 tests (ping response + keyboard navigation)
- `sheetstorm_app/e2e/README.md` — Setup + CanvasKit troubleshooting
- `docs/operations/e2e.md` — Comprehensive 15KB ops guide (DevLoop, Debugging, CI, Best Practices)

Test Hardening:
- `sheetstorm_app/test/semantics_test.dart` — Added explicit `getSemantics()` assertion (Framework-Spec §4.2 compliance)

**Key Decisions:**

*CanvasKit-Handling Strategy:*
- Multi-layered approach: Accessibility-first selectors (`getByRole()`) + Screenshot fallback + Keyboard navigation
- Rationale: Flutter Web's CanvasKit renders to `<canvas>` → DOM opaque → `getByText()` fails
- Solution: Enable `window.flutterSemanticsEnabled` + capture screenshots as evidence
- Documented in e2e/README.md §"CanvasKit vs HTML Renderer" + ops guide §2

*Accessibility-First Selectors:*
- Preference order: `getByRole()` > `getByLabel()` > `getByPlaceholder()` > `getByText()` > `getByTestId()`
- Rationale: Matches screen reader navigation → tests real user experience (Framework-Spec §4.2)
- CSS/XPath selectors avoided (brittle on styling changes)

*webServer Integration:*
- Manual for now (developer starts Aspire + Flutter Web separately)
- Rationale: Aspire Flutter integration not implemented yet, CI timing needs health-checks
- TODO: Automate when AppHost Flutter resource exists

*Test Scope:*
- Foundation Phase: 1 smoke test (ping roundtrip) + 1 accessibility test (keyboard navigation)
- Validates: CORS, HTTP client, routing, i18n, backend connectivity
- Future work: Error handling, responsive layouts, multi-page navigation

**Verification:**

Backend Test (`PingEndpointTests.cs`):
- ✅ Asserts `content.Should().Contain("Hallo Blaskapelle")` (line 71)
- ⚠️ Execution failed locally (Docker not running for Testcontainers) — expected, CI will run

Flutter Semantics Test (`semantics_test.dart`):
- ✅ Hardened with `tester.getSemantics()` + label assertion
- Before: Only `ensureSemantics()` (enabled tree but no verification)
- After: Explicit semantic node retrieval + label check (Framework-Spec §4.2 compliant)

**Commits:**
- `194024b` — chore: add Playwright E2E scaffolding (#126)

**Learnings:**

*CanvasKit Documentation Critical:*
- Flutter Web's rendering behavior non-obvious → dedicated README section + ops guide chapter
- Prevents "Why don't tests work?" frustration

*Scaffolding ≠ Execution:*
- E2E tests written with best practices without local execution (Flutter/Docker not installed)
- CI will be first environment to run tests → unblocks Foundation Phase completion

*Test-Only Dependencies:*
- `package.json` in `sheetstorm_app/` might conflict with Flutter tooling
- Mitigated: `private: true`, `devDependencies` only, `.gitignore` node_modules

**Open Questions:**

1. Should `window.flutterSemanticsEnabled = true` be production-default? (Accessibility vs bundle size)
2. Visual Regression Testing: Manual review vs automated pixel-diff vs structural diff? (Defer to Feature Phase)
3. CI E2E workflow implementation timing (after Foundation merge?)
4. Page Object Model threshold: <5 tests inline OK, >10 tests POM mandatory

**Decision Log:** `.squad/decisions/inbox/romanoff-e2e-setup.md` (11KB deep-dive)

**References:**
- Issue #126
- Framework-Spec §6.3 (Testing strategies)
- Copilot-Instructions E2E section (line 261-281)
- Playwright Best Practices: https://playwright.dev/docs/best-practices

<!-- Append learnings below -->
