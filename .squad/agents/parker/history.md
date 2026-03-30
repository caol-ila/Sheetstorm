# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## 2026-03-30 — MS2 Nacharbeit Batch 2: Post-Reply Tests + Setlist Tests

**Task:** Orchestration Batch 2 parallel execution (Romanoff, Banner, Strange, Parker)  
**Scope:** #115 Post-Reply tests, #117 Setlist tests, #118 Setlist tests  
**Result:** All done, 35 backend + 54 Flutter tests, 8 empty-state tests added

### Backend Tests (#115 Post-Reply)

**Status:** Completed  
**Tests:** 35 test cases (existed but expanded)

**Coverage:**
- Post creation with replies
- Reply validation and constraints (parent post must exist)
- Soft-delete behavior with replies (cascade or hide?)
- Authorization checks on replies (member only)
- Pagination and ordering (newest first)

**Fixes Applied:**
- 25 assertions replaced with consistent patterns (Red→Green→Refactor TDD)
- Added `RequirePostExistsAsync()` helper in PostService for parent validation
- Integration with Banner's soft-delete: deleted posts hidden from reply list
- Integration with Strange's IBandAuthorizationService: all auth checks use centralized service

**Pattern:** Parent post validation at service layer → test mocks must provide valid parent references

### Flutter Tests (#117 + #118 Setlist)

**Status:** Completed  
**Tests:** 54 test cases

**Coverage:**
- Setlist creation and management (CRUD)
- Song ordering within setlist (reorder via drag-and-drop or API)
- Setlist deletion and soft-delete handling (Romanoff's GoRouter migration affects this)
- Timing information for performances (concert timing data)
- Media link integration (YouTube/Spotify links to songs)

**Improvements:**
- Fixed SharedPreferences mock initialization (was causing flakiness)
- Added 8 empty-state tests (previously missing edge cases):
  - Empty setlist with no songs
  - Setlist with all songs deleted (soft-delete cascade)
  - No media links available
  - Invalid timing data handling
  - Permission denied (non-conductor)
  - Network error during fetch
  - Pagination edge case (last page with 1 item)
  - Concurrent edits conflict

**Fixes Applied:**
- SharedPreferences mocks now properly initialized in `setUpAll()`
- Riverpod 3.x provider override pattern (matches Romanoff's refactoring)
- GoRouter path navigation updated (Romanoff's GoRouter migration compatibility)
- Test fixtures use Strange's centralized IBandAuthorizationService mocks

### Test Quality Improvements

- **Assertion Patterns:** 25 assertions replaced with clearer, more consistent patterns
- **Empty-State Testing:** 8 new tests ensure graceful handling of edge cases
- **SharedPreferences Stability:** Fixed mock initialization preventing test flakiness
- **Cross-Agent Compatibility:** All test fixtures updated to use new patterns from other agents

### Cross-Team Integration

**From Romanoff:**
- GoRouter path parameters: Test fixtures updated for new `context.push()` navigation
- UI test assertions now use type-safe route building

**From Banner:**
- Soft-delete consistency: Setlist deletion tests verify cascade behavior for entries/media links
- Test fixtures mock Post soft-delete behavior correctly

**From Strange:**
- IBandAuthorizationService mocks replace scattered auth checks
- Single mock service used across all test scenarios
- Authorization test cases simplified (service handles it)

### Test Results

✅ 35 backend tests pass  
✅ 54 Flutter tests pass  
✅ No regressions in existing test suites  
✅ All 89 total new/updated tests passing on fresh runs

### Files Modified

- `**/Tests/PostReplyTests.cs` (backend)
- `**/**/setlist_*_test.dart` (Flutter)
- `**/**/post_reply_*_test.dart` (Flutter)
- Test fixtures and mocks

---

### 2026-03-28 — Issue #13: Auth Tests

**Branch:** `squad/13-auth-tests` (von `squad/11-auth-backend` abgezweigt)  
**Commit:** `aff7537`  
**Worktree:** `C:\Source\Sheetstorm-13`

**Was ich getan habe:**
- xUnit v3 (3.2.2) Test-Projekt `Sheetstorm.Tests` für net10.0 angelegt
- **17 Unit Tests für `AuthService`** mit EF Core InMemory-DB:
  - Register: valide Eingabe → User erstellt + Passwort bcrypt-gehasht, Tokens zurückgegeben; E-Mail case-normalisiert; doppelte E-Mail → `EMAIL_ALREADY_EXISTS` (409); schwache Passwörter → `PASSWORD_TOO_WEAK` (422)
  - Login: valide Credentials → JWT + Refresh Token; falsches Passwort → `INVALID_CREDENTIALS` (401); unbekannte E-Mail → gleicher Fehler (kein User-Enumeration)
  - Refresh: valides Token → neue JWT + neues Refresh Token; abgelaufenes/revoziertes Token → `INVALID_REFRESH_TOKEN` (401); Token-Wiederverwendung → `REFRESH_TOKEN_REUSED` (401) + alle Family-Tokens revoziert
  - Passwort-Reset: `ForgotPassword` setzt Token mit 30 Minuten Ablauf; unbekannte E-Mail → gleiche Success-Meldung; `ResetPassword` valide → PW geändert, alte Refresh Tokens revoziert; abgelaufener/ungültiger Token → `INVALID_RESET_TOKEN` (400)
- **4 Unit Tests für JWT-Generierung:** Korrekte Claims (sub, email, name, jti, issuer, audience), 900s Ablaufzeit, `ExpiresIn=900` / `TokenType=Bearer`, unique JTI pro Token
- **3 Integration Tests für Rate Limiting** via `WebApplicationFactory<Program>`: 10 Requests passieren, 11. gibt 429; gilt für gemischte Auth-Endpoints
- `SheetstormWebApplicationFactory`: überschreibt Npgsql mit InMemory EF Core, injiziert Test-JWT-Konfiguration
- `Program.cs` um `public partial class Program {}` ergänzt (WebApplicationFactory-Voraussetzung)
- Test-Projekt zur Solution hinzugefügt

### 2026-03-28 — Issue #27: Spielmodus Tests

**Branch:** `squad/27-spielmodus-tests`  
**Commit:** `2a6febb`  
**Worktree:** `C:\Source\Sheetstorm-27`

**Was ich getan habe:**
- **178 Flutter-Tests** für das Spielmodus-Feature geschrieben (alle grün)
- 10 Testdateien angelegt:
  - `spielmodus_notifier_test.dart` — Unit Tests: initial load, Seitennavigation, Overlay-Toggle, Stimme-Wechsel, Setlist-Navigation, Auto-Scroll, Zoom-Memory, State-Helpers
  - `spielmodus_settings_notifier_test.dart` — Unit Tests: SharedPreferences-Persistenz für alle Settings
  - `page_cache_service_test.dart` — LRU-Cache: Eviction, Hit/Miss, Kapazitätsgrenzen, Performance
  - `page_gesture_detector_test.dart` — Widget Tests: Tap-Zonen (40/60%), Center-Zone, Swipe, UI-Lock, Double-Tap
  - `spielmodus_overlay_test.dart` — Widget Tests: Sichtbarkeit, Buttons, IgnorePointer
  - `ui_lock_overlay_test.dart` — Widget Tests: 5-Tap-Unlock, Counter-Anzeige
  - `night_mode_filter_test.dart` — Widget Tests: ColorFilter-Matrix für Nacht-Modus
  - `two_page_view_test.dart` — Widget Tests: Zwei-Seiten-Ansicht für Tablet
  - `half_page_turn_view_test.dart` — Widget Tests: Halb-Seiten-Layout
  - `spielmodus_performance_test.dart` — Performance: State-Transitions <16ms, Cache-Ops <1ms

**Bugs gefunden und gefixt:**
1. `UiLockOverlay._onCenterTap()`: `setState()` fehlte → Counter wurde visuell nie aktualisiert
2. `SheetMusicPageView`: `Spacer()` in Column innerhalb `Align(heightFactor:)` → unbegrenzte Höhe → Overflow. Fix: `SizedBox(height: 16)`
3. `PageGestureDetector`: `MediaQuery.sizeOf(context).width` gibt Window-Breite zurück, nicht Widget-Breite. Fix: `LayoutBuilder` mit `constraints.maxWidth`
4. `PageGestureDetector`: `onHorizontalDragEnd` + `onScaleStart` können nicht koexistieren (Gesture-Arena-Konflikt). Fix: nur Scale-Callbacks, Swipe-Erkennung via Displacement/Velocity in `_onScaleEnd`
5. `PageGestureDetector`: `ScaleGestureRecognizer` gewinnt Gesture-Arena gegen `TapGestureRecognizer` für ALLE Single-Finger-Gesten. Fix: `onTapUp`/`onDoubleTap` entfernt; Taps und Double-Taps komplett in Scale-Callbacks via Dauer/Displacement-Heuristik
6. `SpielmodusNotifier._loadSheetMusic`: kein `ref.mounted`-Check nach `await` → `setState-after-dispose` wenn Container in Tests vorzeitig disposed. Fix: `if (!ref.mounted) return;` nach dem await
7. `SpielmodusNotifier` + `SpielmodusSettingsNotifier`: Riverpod 2.x `StateNotifier`/`StateNotifierProvider` in Riverpod 3.3.1 entfernt. Fix: Migration auf `@riverpod`-Annotation mit `_$ClassName`-Pattern + `build(String notenId)`-Methode; `dart run build_runner build` für generierte `.g.dart`-Dateien

**Stack-Wissen:**
- **Riverpod 3.3.1**: `StateNotifier` komplett entfernt. `@riverpod` mit `extends _$ClassName`, `build()` als Einstiegspunkt. Family-Provider: `build(String arg)`. Generierte Provider-Namen: `SpielmodusNotifier` → `spielmodusProvider`.
- **autoDispose + ProviderContainer in Tests**: `container.read()` hält autoDispose-Provider NICHT am Leben. Immer `container.listen(provider, (_, __) {})` nutzen + `addTearDown(sub.close)`.
- **HapticFeedback in Unit Tests**: Erfordert `TestWidgetsFlutterBinding.ensureInitialized()` in `setUpAll()`.
- **ScaleGestureRecognizer vs TapGestureRecognizer**: Scale-Recognizer gewinnt für ALLE Pointer-Events (auch Single-Tap). Kombination `onTapUp` + `onScaleStart` auf demselben GestureDetector funktioniert nicht. Lösung: alle Gesten in Scale-Callbacks verarbeiten.
- **LayoutBuilder vs MediaQuery**: `MediaQuery.sizeOf(context).width` = Window-Breite. Für responsive Widget-Logik immer `LayoutBuilder` mit `constraints.maxWidth`.
- **Align(heightFactor:) + Column + Spacer**: Gibt unbegrenzte Höhe → Column mit Spacer crasht. Fix: `Spacer` → `SizedBox` oder `mainAxisSize: MainAxisSize.min`.
- **Test-Surface-Size**: `tester.binding.setSurfaceSize(Size(400, 800))` + `addTearDown(() async => tester.binding.setSurfaceSize(null))` für reproduzierbare Widget-Positionen.


---

## Team Update: Kapellenverwaltung & Auth-Onboarding Spec-Update (2026-03-28T22:10Z)

**From:** Hill (Product Manager)  
**Action:** QA scope expanded — 13 new edge cases + approval workflow testing.

**Test Scenarios Added:**

**Approval Flow (Core):**
1. Join via invitation → request created with status "pending"
2. Admin approves → user receives email, joins Kapelle
3. Admin rejects → user receives email with rejection reason
4. User with rejected request + new invitation → can request again
5. Email invitation (admin provides email) → user still requires approval

**"Meine Musik" Protection:**
6. User cannot leave "Meine Musik" (error handling)
7. User cannot invite others to "Meine Musik" (disabled UI / 403 error)
8. User cannot delete "Meine Musik" (disabled UI / 403 error)
9. "Meine Musik" always remains even if all other Kapellen left

**Entry Point Logic:**
10. Only "Meine Musik" → direct to library (no selector)
11. 1 Kapelle + "Meine Musik" → direct to last active Kapelle
12. 2+ Kapellen → show Kapellen-Auswahl selector
13. Post-onboarding first visit → Kapellen-Auswahl (not library)

**Scope Impact:**
- Test cases: 8 → 13 (+5 edge cases)
- Platforms: Web + Flutter (both approve/reject flows)

**Related Specs:**
- docs/feature-specs/kapellenverwaltung-spec.md § 7.9–7.13 (edge cases)
- docs/feature-specs/auth-onboarding-spec.md (entry point scenarios)

**Next Step:** Test plan document for detailed step-by-step scenarios

---

## Team Update: MS2 Nacharbeit Batch 1 (2026-03-30T21:10Z)

**From:** Scribe  
**Action:** Parker executed P1/P2 batch (GEMA tests verification + Provider overrides migration).

### Parker's Completed Tasks

**Tickets Resolved:**
- #114 — GEMA export tests: Verified existing test coverage in `gema_export_test.dart` — no new tests required (requirement satisfied)
- #113 — Provider overrides: Converted `post_notifier_test.dart` + `substitute_notifier_test.dart` to Riverpod 3.x provider override pattern

**Test Results:** 67 Flutter tests green (modern mock-based architecture)

**Architecture Change:** Migrated from deprecated `mockito` stubs to Riverpod `ProviderContainer(overrides: [...])` pattern with `AsyncValue.data()` for mock injection.

**Assessment Document:** Created `.squad/assessment/parker-gema-provider-task-assessment.md` documenting requirements, GEMA test verification, migration approach, and test results.

### Cross-Team Coordination

**From Banner (Backend):**
- ParentCommentId validation now enforced in `PostService.AddCommentAsync()` 
- Parker's provider override tests for communication notifiers must mock valid post objects with proper references
- Pattern established: Service-layer validation feeds into notifier mock setup

**Files Modified:** 
- `test/features/communication/application/post_notifier_test.dart`
- `test/features/shifts/application/substitute_notifier_test.dart`
- `.squad/assessment/parker-gema-provider-task-assessment.md` (new)
