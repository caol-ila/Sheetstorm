# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## 2026-03-28 — Issue #8: Flutter Frontend Scaffolding

**Branch:** `squad/8-frontend-scaffolding`  
**Commit:** `368db49`

### Was wurde gebaut

Vollständiges Flutter-Projekt-Scaffolding für `sheetstorm_app/`:

**Struktur (Clean Architecture):**
- `lib/core/` — Theme, Design Tokens, Constants, Routing (go_router)
- `lib/features/` — auth, kapelle, noten, spielmodus, config, annotationen
- `lib/shared/` — AppShell (Bottom Nav), Drift-Datenbank, API-Client (dio)

**Design-Token-System** direkt aus ux-design.md:
- `AppColors` — Light/Dark, Config-Ebenen (blau/grün/orange), Annotation-Layer
- `AppSpacing` — Touch-Targets 44px (min) / 64px (Spielmodus), Border-Radius
- `AppTypography` — Inter-Font, 12–72sp Skala
- `AppDurations`/`AppCurves` — Animation-Tokens

**App Shell:** 4 Bottom-Navigation-Tabs (Bibliothek/Setlists/Kalender/Profil), Material 3, Wakelock-Handling im Spielmodus.

**SpielmodusScreen:** Vollbild (SystemUI immersive), asymmetrische Tap-Zonen (40% zurück / 60% weiter), Kontextmenü max. 5 Optionen.

**Drift DB:** Tabellen für Noten, Stimmen, Annotationen, KonfigurationEintraege.

**Verifiizierte Versionen (alle per web_search):**
- Flutter 3.41.5 / Dart 3.11.0, flutter_riverpod 3.3.1, go_router 17.1.0
- dio 5.9.2, drift 2.32.1, pdfrx 2.2.24, flutter_svg 1.1.6, cached_network_image 3.4.1

### Flutter nicht installiert
Flutter-SDK war auf dem Build-Agenten nicht vorhanden → Projekt-Struktur manuell erstellt. `build_runner` muss nach Flutter-Installation ausgeführt werden, um `.g.dart`-Stubs durch echten generierten Code zu ersetzen:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Noch offen (spätere Issues)
- Platform-spezifische Dateien (android/, ios/, windows/) — werden von `flutter create` generiert
- build_runner generierten Code (`.g.dart` sind Stubs)
- Auth-Provider-Implementierung
- Spielmodus: pdfrx-Integration, Half-Page-Turn-Logik
- Annotationen: SVG-Layer-Implementation
- Config: 3-Ebenen-Override-Logik

---

## 2026-03-28 — PR #88 Fix (Auth Backend): SHA-256, EmailVerified, IEmailService, IStorageService

**Branch:** `squad/88-auth-fix` (based on `squad/11-auth-backend`)
**Worktree:** `C:\Source\Sheetstorm-88-fix`
**Assigned by:** Thomas (via Ralph) — Banner locked out per Reviewer Rejection Protocol

### Was wurde geändert

**1. SHA-256 Hashing für Refresh Tokens (Security Fix)**
- `AuthService.CreateRefreshTokenAsync`: speichert `SHA256(tokenValue)` in der DB
- `AuthService.RefreshAsync`: hasht das eingehende Token vor dem DB-Lookup
- Neuer privater Helper `HashToken(string)` — `SHA256.HashData` → Hex-String
- Roher Token geht nur zum Client, nie in die DB → verhindert Token-Diebstahl via DB-Dump

**2. E-Mail-Bestätigung (EmailVerified)**
- `Musiker` Entität: neue Felder `EmailVerified`, `EmailVerificationToken`, `EmailVerificationTokenExpiresAt`
- Bei `RegisterAsync`: `EmailVerified = false`, Verification-Token generieren (24h Ablauf), `IEmailService.SendEmailVerificationAsync` aufrufen
- `UserDto` exposes `EmailVerified`

**3. IEmailService + DevEmailService**
- `Infrastructure/Email/IEmailService.cs`: `SendEmailVerificationAsync`, `SendPasswordResetAsync`
- `Infrastructure/Email/DevEmailService.cs`: Stub — loggt E-Mails auf Konsole (dev-only)
- `DependencyInjection.cs`: `IEmailService → DevEmailService` registriert

**4. POST /api/auth/verify-email**
- `VerifyEmailRequest(Token)` in `AuthModels.cs`
- `IAuthService.VerifyEmailAsync` + Implementierung in `AuthService`
- `AuthController`: neuer Endpoint, idempotent (bereits verifiziert = 200 OK)

**5. IStorageService (S3-kompatibel)**
- `Infrastructure/Storage/IStorageService.cs`: `UploadAsync`, `DownloadAsync`, `DeleteAsync`, `GetPresignedUrlAsync`
- Noch kein konkreter S3-Provider — bewusst als Interface-only, Implementierung in eigenem Issue

### Build-Ergebnis
`dotnet build` → **0 Warnungen, 0 Fehler**

---

## 2026-03-28 — PR #95 Fix (Kapelle Backend): Stimmen-Override Endpoints

**Branch:** `squad/95-kapelle-fix` (based on `squad/16-kapelle-backend`)
**Worktree:** `C:\Source\Sheetstorm-95-fix`
**Assigned by:** Thomas (via Ralph) — Banner locked out per Reviewer Rejection Protocol

### Was wurde geändert

**1. KapelleStimmenMapping Entität**
- `Domain/Entities/KapelleStimmenMapping.cs`: `KapelleId`, `Instrument` (bis 100 Zeichen), `Stimme` (bis 100 Zeichen)
- EF-Config: `KapelleStimmenMappingConfiguration` — Unique-Index auf `(KapelleId, Instrument)`, Cascade-Delete
- `AppDbContext`: `KapelleStimmenMappings` DbSet
- `Kapelle` Entität: `StimmenMappings` Navigation Collection

**2. Nutzer-Override auf Mitgliedschaft**
- `Mitgliedschaft.StimmenOverride` (nullable string, max 100): persönliche Stimme für dieses Mitglied
- Priorität: `StimmenOverride > Kapelle-Default-Mapping > Globaler Default`

**3. DTOs (KapelleModels.cs)**
- `StimmenMappingEintrag(Instrument, Stimme)`
- `StimmenMappingResponse(IReadOnlyList<StimmenMappingEintrag>)`
- `StimmenMappingSetzenRequest(IReadOnlyList<StimmenMappingEintrag>)`
- `NutzerStimmenRequest(StimmenOverride?)` — null = Override entfernen

**4. Service-Layer**
- `IKapelleService`: 3 neue Methoden
- `KapelleService.GetStimmenMappingAsync` — alle Einträge für die Kapelle (Mitglied-Guard)
- `KapelleService.SetStimmenMappingAsync` — atomares Replace aller Einträge (Admin-Guard)
- `KapelleService.SetNutzerStimmenAsync` — Admin kann alle setzen, Mitglied nur eigene

**5. Neue Endpoints**
- `GET  /api/kapellen/{id}/stimmen-mapping` (jedes Mitglied)
- `PUT  /api/kapellen/{id}/stimmen-mapping` (Admin — ersetzt komplette Mapping-Liste)
- `PUT  /api/kapellen/{id}/mitglieder/{userId}/stimmen` (Admin oder selbst)

### Build-Ergebnis
`dotnet build` → **0 Warnungen, 0 Fehler**


## 2026-03-28 — Issue #12: Flutter Auth UI & Token Management

**Branch:** `squad/12-auth-flutter`  
**Commit:** `33d1ce8`  
**Worktree:** `C:\Source\Sheetstorm-12`

### Was wurde gebaut

**Daten-Schicht:**
- `auth_models.dart` — `User`, `AuthTokens`, `AuthResponse` (manuelles JSON, kein build_runner nötig)
- `TokenStorage` — `flutter_secure_storage 10.0.0`, persistiert Access/Refresh Token + User JSON in verschlüsseltem Storage (Android: EncryptedSharedPreferences)
- `AuthService` — eigener Dio ohne Auth-Interceptor (vermeidet circular dependency), deckt alle Endpunkte: `login`, `register`, `refreshToken`, `forgotPassword`, `validateGuestToken`, `completeOnboarding`

**State-Schicht:**
- `AuthState` — sealed class: `AuthLoading / AuthUnauthenticated / AuthAuthenticated(User) / AuthError(String)`
- `AuthNotifier` — Riverpod `Notifier` (keepAlive), initialisiert aus Storage beim App-Start, async `login/register/logout/forgotPassword`, `markOnboardingCompleted`, `onAuthError` (Callback für Dio-Interceptor)

**Routing:**
- go_router `redirect`-Guard mit `_RouterNotifier` (ChangeNotifier als `refreshListenable`)
- Logik: AuthLoading → `/loading`, AuthAuthenticated + !onboardingCompleted → `/onboarding`, Authenticated auf Auth-Route → `/app/bibliothek`, Unauthenticated auf geschützter Route → `/login`
- Neue Routen: `/loading`, `/register`, `/forgot-password`, `/onboarding`, `/aushilfe/:token` (Placeholder für Issue #15)

**API-Client:**
- `_AuthInterceptor` vollständig implementiert: Bearer-Token Injection, Auto-Refresh bei 401 (Retry-Request mit neuem Token), bei Refresh-Fehler `onAuthError()` aufrufen

**Screens:**
- `LoginScreen` — E-Mail + Passwort, Passwort vergessen Link, Social Login (Google immer, Apple nur iOS/macOS), Link zu Register
- `RegisterScreen` — 4-Step progressiver Flow: E-Mail+PW (mit Stärke-Anzeige, Weiter-Button disabled bis gültig) → Name → Instrument (FilterChips, 25 Blaskapellen-Instrumente) → Kapelle (optional, überspringbar)
- `ForgotPasswordScreen` — Email-Input, Success-State, 60s Cooldown-Timer auf "Erneut senden"
- `OnboardingScreen` — 5-Step Wizard via PageView: Name bestätigen → Instrument → Kapelle & Standardstimme → Theme (Hell/Dunkel/System) → Fertig; jeder Schritt überspringbar

**Shared Widgets:**
- `AuthTextField` — 44px Touch-Target, Eye-Toggle für Passwortfelder
- `PasswordStrengthIndicator` — Live-Balken (Schwach/Mittel/Stark) + Checkliste (8 Zeichen, Großbuchstabe, Zahl/Sonderzeichen)
- `SocialLoginButtons` — `Platform.isIOS || Platform.isMacOS` Guard für Apple-Button

### Wichtige Entscheidungen

- **Kein build_runner nötig für Models**: Manuelle JSON-Serialisierung statt freezed/json_annotation
- **Circular-Dep-Lösung**: `AuthService` hat eigenes Dio, `apiClient` liest `tokenStorageProvider` + `authServiceProvider` via `ref.read` (nicht watch)
- **flutter_secure_storage 10.0.0** (neueste Version, per web_search verifiziert)
- `authNotifierProvider` keepAlive — Auth-State überlebt Widget-Tree-Rebuild

### Noch offen (spätere Issues)
- Google Sign-In / Apple Sign-In OAuth-Integration (Placeholder-Buttons vorhanden)
- Aushilfen-Deep-Link-Flow `/aushilfe/:token` (Issue #15)
- Kapellen-Suche in Registrierung/Onboarding braucht API (Issue nach Backend-Auth)
- build_runner nach Flutter-Installation für alle `.g.dart`-Stubs

