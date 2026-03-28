# Decisions

## Decision 1: Tech-Stack v3 — Verifizierte Versionen

**Autor:** Stark (Lead / Architect)  
**Datum:** 2026-03-28  
**Typ:** Aktualisierung  
**Dokument:** `docs/technologie-entscheidung.md` v3

### Kontext

Thomas hat festgestellt, dass v2 des Tech-Stack-Dokuments veraltete Versionsnummern aus Training-Data enthielt. v3 korrigiert dies durch individuelle `web_search`-Abfragen für **jede einzelne Technologie**.

### Änderungen v2 → v3

| Technologie | v2 (alt) | v3 (verifiziert) | Quelle |
|-------------|----------|-------------------|--------|
| **Flutter** | 3.35.4 | **3.41.5** | flutter.dev, GitHub CHANGELOG |
| **Dart** | 3.9.2 | **3.11.0** | dart.dev/changelog |
| **Flutter Impeller** | (nicht spezifiziert) | **Impeller 2.0** | Flutter 3.41 release notes |
| **.NET MAUI** | 10.0.50 | **10.0.5** | endoflife.date, Microsoft Support |
| **SignalR** | "Teil von ASP.NET Core 10" | **@microsoft/signalr 10.0.0** | npmjs.com |
| **flutter_blue_plus** | (nicht versioniert) | **1.34.5** | pub.dev |
| **Azure AI Vision** | (nicht spezifiziert) | **Image Analysis 4.0 GA** | learn.microsoft.com |
| **SQLite** | 3.51.3 | 3.51.3 (bestätigt, 3.52.0 zurückgezogen) | sqlite.org |

Alle anderen Versionen (PostgreSQL 18.3, Drift 2.32.1, Riverpod 3.3.1, pdfrx 2.2.24, etc.) wurden per Web-Suche **bestätigt** — keine Änderung nötig.

### Methodik

- 18 separate `web_search`-Aufrufe durchgeführt
- Jede Version mit Quell-URL und Datum dokumentiert
- Neuer Abschnitt "Versions-Referenz" mit Spalte "Verifiziert via" für Audit-Trail
- Kein Rückgriff auf Training-Data für Versionsnummern

### Empfehlung

Kernentscheidung (Flutter + ASP.NET Core + PostgreSQL) bleibt unverändert und bestätigt. Nur Versionsnummern aktualisiert.

**Status:** Zur Prüfung durch Thomas.

---

## Decision 2: Feature-Gap-Entscheidung: 18 Features übernommen

**Von:** Stark (Lead / Architect)  
**Datum:** 2026-03-28  
**Typ:** Feature-Adoption-Entscheidung  
**Status:** Umgesetzt — PR #2 offen

### Entscheidung

Thomas hat aus der Feature-Gap-Analyse (39 Gaps, Fury) **18 Features** zur Aufnahme in die Spezifikation freigegeben. Die restlichen Features bleiben im Backlog.

### Übernommene Features

| # | Feature | Meilenstein | Spec-ID |
|---|---------|:-----------:|---------|
| 0 | GEMA-/Verwertungsgesellschaft-Meldung | MS2 | F-VL-04 |
| 6 | Kalender-Sync bidirektional | MS2 | F-VL-03 (erweitert) |
| 8 | Zweiseitenansicht (Two-Up-Modus) | MS1 | F-SM-07 |
| 9 | Link Points für Wiederholungen | MS1 | F-SM-08 |
| 10 | Dirigenten-Mastersteuerung (Song-Broadcast) | MS2 | F-VL-05 |
| 11 | Dark Mode / Nachtmodus / Sepia | MS1 | F-SM-09 |
| 12 | Anwesenheitsstatistiken | MS2 | F-VL-06 |
| 13 | Register-basierte Benachrichtigungen | MS2 | F-VL-07 |
| 14 | Nachrichten-Board / Pinnwand | MS2 | F-VL-08 |
| 15 | Umfragen / Abstimmungen | MS2 | F-VL-09 |
| 22 | Media Links (YouTube/Spotify) | MS2 | F-NV-08 |
| 27 | Konzertprogramm mit Timing | MS2 | F-SL-03 |
| 29 | Platzhalter in Setlists | MS2 | F-SL-02 |
| 30 | Aufgabenverwaltung / To-Do-Listen | MS3 | F-VL-10 |
| 31 | Auto-Scroll / Reflow | MS3 | F-SM-10 |
| 34 | AI-Annotations-Analyse (Cross-Part) | MS4 | F-AI-01 |
| 35 | Face-Gesten für Seitenwechsel | MS5 | F-SM-11 |
| 40 | Inventarverwaltung (Instrumente) | MS5 | F-VL-11 |

### Nicht übernommene Features (Backlog)

Features #4, #5, #7, #16–#21, #23–#26, #28, #32–#33, #36–#39, #41 wurden **nicht** übernommen und bleiben im Backlog für spätere Betrachtung. Sie sind in `docs/feature-gap-analyse.md` mit 🔜 Backlog markiert.

### Auswirkungen auf Meilensteine

- **MS1** wächst um 3 Features (Zweiseitenansicht, Link Points, Dark Mode)
- **MS2** wächst am stärksten (+9 Features: GEMA, Dirigenten-Broadcast, Kommunikationsfeatures)
- **MS3** +2 Features (Auto-Scroll, Aufgabenverwaltung)
- **MS4** +1 Feature (AI Cross-Part Analyse)
- **MS5** +2 Features (Face-Gesten, Inventar)

**GEMA-Meldung** ist rechtlich kritisch (gesetzliche Pflicht in DACH) — Must-Priorität in MS2.

### Nächste Schritte

1. Thomas reviewed PR #2 und mergt
2. Scribe konsolidiert diese Inbox-Datei in decisions.md
3. Bei MS1-Planung die 3 neuen Spielmodus-Features einplanen
4. Bei MS2-Planung GEMA-Feature priorisieren (rechtliche Pflicht)

---

## Decision 3: Password Reset Tokens Should Also Be Hashed

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-03-28  
**Context:** Auth backend fix (squad/88-auth-fix)  
**Status:** Follow-up issue (not blocking)

### Observation

While fixing email verification token hashing, observed that `PasswordResetToken` in `ForgotPasswordAsync` and `ResetPasswordAsync` is still stored and looked up in plaintext. This is inconsistent with the SHA-256 hashing pattern now applied to both refresh tokens and email verification tokens.

### Recommendation

Apply the same `HashToken()` pattern to password reset tokens in a follow-up PR:
- `ForgotPasswordAsync`: store `HashToken(token)`, send raw token in email
- `ResetPasswordAsync`: hash incoming token before DB lookup

This is low-risk, follows the existing pattern, and closes the last plaintext-token gap.

### Priority

Follow-up issue — not blocking current PR.

---

## Decision 4: DomainException Layer Separation

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-03-28  
**Context:** Kapelle backend fix (squad/95-kapelle-fix)  
**Status:** Implemented in squad/95-kapelle-fix

### Decision

Introduced `DomainException` in `Sheetstorm.Domain.Exceptions` to separate domain errors from auth errors. The middleware now catches both `DomainException` and `AuthException`.

**Rule:** `AuthException` is ONLY for actual authentication/authorization failures (FORBIDDEN/403). All domain errors (not-found, conflict, validation) use `DomainException` with appropriate HTTP status codes.

This prevents the Flutter auth interceptor from misinterpreting domain errors as auth failures (which triggered token refresh or logout).

### Impact

All future services should follow this pattern. Any new domain error codes go through `DomainException`, not `AuthException`.

---

## Decision 5: Auth Flutter Client Alignment

**By:** Vision (Principal Frontend Engineer)  
**Date:** 2026-03-29  
**Branch:** squad/93-auth-flutter-fix  
**Commit:** 8531deb  
**Status:** Implemented and merged to main

### Context

The auth Flutter fix (PR #93) was unanimously rejected by all 3 reviewers. After Strange fixed the backend contracts on squad/88-auth-fix, the Flutter client needed to align.

### Changes Made

1. **Endpoint prefix**: All auth endpoints changed from `/auth/` to `/api/auth/` to match backend routing.
2. **verify-email contract**: Changed from `POST /auth/email-verify/$token` (token in URL) to `POST /api/auth/verify-email` with JSON body `{ "token": "..." }`.
3. **Resend button removed**: Backend has no resend-verification endpoint. UI button removed; TODO added for follow-up.
4. **Refresh race condition fixed**: Added `Completer<void>`-based mutex in `_AuthInterceptor` — only one refresh in flight at a time, concurrent callers wait for result. Prevents family-based rotation reuse detection.
5. **completeOnboarding Dio instance fixed**: Now uses `apiClientProvider` (with auth interceptor) instead of `AuthService._dio` (bare, no Bearer token).
6. **Async storage writes awaited**: `onAuthError()` and `markOnboardingCompleted()` now properly `await` storage writes to prevent stale-state race conditions.

### Follow-up Needed

- **Strange**: Add `POST /api/auth/resend-verification` endpoint so we can re-enable the resend button in the email verification screen.
- **build_runner**: The `.g.dart` files need regeneration once Flutter SDK is available in the build environment.

### Team Impact

- Frontend now fully aligned to Strange's backend API contracts on squad/88-auth-fix.
- The Completer mutex pattern should be reused in any future interceptor that handles token rotation.

---

## Decision 6: Final Merge Decisions — Re-Review Round (All 3 Branches)

**Author:** Stark (Lead / Architect)  
**Date:** 2026-03-29  
**Status:** All 3 branches merged to main

### squad/88-auth-fix — ✅ MERGED

**Vote:** 2/3 APPROVE (Opus ✅, GPT ✅, Sonnet ❌)

**Sonnet's rejection dismissed.** Primary claim ("IStorageService not removed") was factually wrong — Opus confirmed removal in commit ed44824. Secondary concerns are valid but non-blocking:
- **Raw token in DevEmailService logs:** Dev-only service, acceptable for development. FOLLOW-UP: strip tokens before production.
- **Registration returns tokens to unverified users:** Design decision, not a bug. Many apps grant partial access pre-verification.
- **No rate limiting on verify-email:** Already designated as FOLLOW-UP item.

**Merged** into main. No conflicts.

### squad/93-auth-flutter-fix — ✅ MERGED

**Vote:** 3/3 APPROVE (unanimous)

All three reviewers approved. Noted follow-ups (non-blocking):
- Interceptor path guard hardening
- Base URL duplication cleanup
- JSON key format (snake_case vs camelCase) — verify against backend response format

**Merged** into main. No conflicts.

### squad/95-kapelle-fix — ✅ MERGED

**Vote:** 2/3 APPROVE (Sonnet ✅, Opus ✅, GPT ❌)

**GPT's rejection dismissed after code verification.** GPT claimed admin A can remove admin B leaving zero admins. **This is incorrect.** Verified in `KapelleService.MitgliedEntfernenAsync`:

1. To remove another member, the caller **must be an admin** (`requester.Rolle != MitgliedRolle.Administrator` → 403)
2. Therefore if admin A removes admin B, admin A still exists → at least 1 admin remains
3. Self-removal guard correctly counts ALL admins via `CountAsync` and blocks if `adminCount <= 1`
4. `RolleAendernAsync` has a parallel guard preventing demotion of the last admin

The logic is sound. GPT's concern represents a misunderstanding of the code flow.

**Minor items noted by Opus (non-blocking FOLLOW-UPs):**
- `AuthException` coupling in domain layer — consider `DomainException` instead
- Typo `VorgeseheRolle` → should be `VorgeseheneRolle` (consistent typo, functional, cosmetic fix)

**Merged** into main. One conflict in `DependencyInjection.cs` (both #88 and #95 added service registrations) — resolved by keeping both: `IEmailService` + `IKapelleService`.

### Summary

| Branch | Decision | Conflicts | Status |
|--------|----------|-----------|--------|
| squad/88-auth-fix | MERGE | None | ✅ Merged |
| squad/93-auth-flutter-fix | MERGE | None | ✅ Merged |
| squad/95-kapelle-fix | MERGE | 1 (resolved) | ✅ Merged |

All three branches merged to main and pushed to origin.

### FOLLOW-UP Items (Future Issues)

1. Strip tokens from DevEmailService logs before production deployment
2. Rate limiting on verify-email endpoint
3. Flutter auth interceptor path guard hardening
4. Base URL duplication cleanup in Flutter
5. Verify JSON key format consistency (snake_case vs camelCase) between backend and Flutter
6. Add `POST /api/auth/resend-verification` endpoint (blocking resend button re-enable)
7. Fix typo `VorgeseheRolle` → `VorgeseheneRolle` (cosmetic)
8. Password reset token hashing (follow-up PR, low priority)
