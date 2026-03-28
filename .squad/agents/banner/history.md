# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## Session Log

### 2026-03-28 — PR #93 Auth Flutter Fix (Lockout: Romanoff → Banner)

**Requested by:** Thomas (via Ralph)
**Branch:** `squad/93-auth-flutter-fix` (worktree off `squad/12-auth-flutter`)
**PR under review:** #93 — [Dev] #12 Auth Flutter UI & Token Management

**Stark's Review — All 4 Action Items Resolved:**

1. ✅ **Token storage on flutter_secure_storage** — was already done by Romanoff in original PR (no change needed)
2. ✅ **`/email-verify/:token` route + handler** — Added `EmailVerificationScreen`, `/email-verify` and `/email-verify/:token` routes, `AuthService.verifyEmail()`, `AuthNotifier.verifyEmail()` + `resendVerificationEmail()`
3. ✅ **Token expiry on app start** — `TokenStorage.isAccessTokenExpired()` with 60s margin; `_initializeAuth` now attempts silent refresh → logout on failure
4. ✅ **`debugLogDiagnostics: kDebugMode`** — was hardcoded `true`

**Architecture Decisions Implemented:**
- **E-Mail-Bestätigung (Pflicht):** New `AuthEmailPendingVerification` state; `login`/`register` gate `AuthAuthenticated` on `user.emailVerified`; redirect logic updated
- **Dev-Mode Auto-Verify:** `AppConfig.devAutoVerifyEmail = kDebugMode` — skips email verification in debug builds
- **User model:** `emailVerified` field added; `TokenStorage` persists access token expiry timestamp

**Files changed (8):**
- `lib/core/config/app_config.dart` *(new)*
- `lib/core/routing/app_router.dart`
- `lib/features/auth/application/auth_notifier.dart`
- `lib/features/auth/data/models/auth_models.dart`
- `lib/features/auth/data/services/auth_service.dart`
- `lib/features/auth/data/services/token_storage.dart`
- `lib/features/auth/presentation/screens/email_verification_screen.dart` *(new)*
- `lib/features/auth/presentation/screens/register_screen.dart`

**Note:** PR comment could not be posted automatically (no GitHub write token available in environment). Comment should be posted manually on PR #93 referencing branch `squad/93-auth-flutter-fix`.

