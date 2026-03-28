# Feature-Spezifikation: Authentifizierung & Onboarding

> **Version:** 1.0  
> **Status:** Entwurf  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Issue:** #10  
> **UX-Referenz:** `docs/ux-specs/auth-onboarding.md` (Wanda, Issue #9)  
> **Abhängigkeiten:** #7 (Backend-Scaffolding), #8 (Frontend-Scaffolding), #9 (UX Auth/Onboarding)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Edge Cases & Fehlerszenarien](#6-edge-cases--fehlerszenarien)
7. [Abhängigkeiten](#7-abhängigkeiten)
8. [Definition of Done](#8-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Beschreibung

Authentifizierung & Onboarding ist das Eingangstor zu Sheetstorm. Es ermöglicht Musikern, sich zu registrieren, einzuloggen und nach der Registrierung durch einen geführten Onboarding-Wizard zu navigieren, der sie in unter 3 Minuten zum ersten Notenblatt bringt.

Das Feature umfasst:
- **Login** — E-Mail/Passwort + Social Login (Google, Apple auf iOS/macOS)
- **Registrierung** — 4-schrittiger progressiver Flow (E-Mail+Passwort → Name → Instrument → Kapelle)
- **Passwort zurücksetzen** — E-Mail-basierter Reset-Link (30 Minuten gültig)
- **Onboarding-Wizard** — 5 Schritte, alle überspringbar, direkt nach Erstregistrierung
- **Token-Verwaltung** — JWT Access Token + Refresh Token mit Rotation
- **Aushilfen-Sonderfall** — Deep-Link-Zugang ohne Registrierung

### 1.2 UX-Referenz

Die vollständigen Wireframes, Flows und Interaction Patterns sind in Wandas UX-Spec dokumentiert:  
📄 [`docs/ux-specs/auth-onboarding.md`](../ux-specs/auth-onboarding.md)

Kernaussagen aus der UX-Spec:
- Ziel: **unter 3 Minuten** von App-Installation bis erster Note
- Auth-State-Machine: Kein Token → Auth-Screen; Token vorhanden → Validierung → Bibliothek oder Re-Auth
- Onboarding: Max. 5 Fragen, jeder Schritt überspringbar, kein Blocker
- Passwort-Stärke: Live-Anzeige mit Balken + Checkliste (8 Zeichen, Großbuchstabe, Zahl/Sonderzeichen)
- Social Login: Google immer; Apple nur auf iOS/macOS — kein Fake-Button auf Android
- Aushilfen-Deep-Link: `sheetstorm://aushilfe/[token]` → direkt in Aushilfen-Ansicht, kein Account nötig

---

## 2. User Stories

### US-01: Registrierung

**Als Musiker möchte ich mich bei Sheetstorm registrieren,**  
damit ich Zugang zu meinen Noten, meiner Kapelle und allen App-Funktionen bekomme.

**Kontext:** Neues Mitglied öffnet die App zum ersten Mal (organisch oder über Einladungslink).

**Akzeptanzkriterien:**
- Ich kann mich mit E-Mail + Passwort registrieren
- Ich werde durch 4 klare Schritte geführt (E-Mail+PW → Name → Instrument → Kapelle)
- Jeder Schritt hat einen einzigen Fokus (Progressive Disclosure)
- Nach Registrierung startet automatisch der Onboarding-Wizard
- Ich kann mich alternativ mit Google (alle Plattformen) oder Apple (nur iOS/macOS) registrieren

**INVEST-Bewertung:**
- Independent ✓ — kein Login ohne Registrierung möglich, aber unabhängig vom Onboarding
- Negotiable ✓ — Social-Login-Anbieter austauschbar
- Valuable ✓ — ohne Registrierung kein App-Zugang
- Estimable ✓ — klarer Scope: 4 Schritte + API
- Small ✓ — abgrenzbar von Login und Onboarding
- Testable ✓ — messbar via Registrierungs-Rate und E2E-Tests

---

### US-02: Login

**Als Musiker möchte ich mich in Sheetstorm einloggen,**  
damit ich schnell wieder auf meine Noten und Kapelle zugreifen kann.

**Kontext:** Bestehender Nutzer öffnet die App auf einem bekannten oder neuen Gerät.

**Akzeptanzkriterien:**
- Ich kann mich mit E-Mail + Passwort anmelden
- Ich kann mich alternativ mit Google oder Apple (nur iOS/macOS) anmelden
- Nach erfolgreichem Login werde ich direkt zur Bibliothek weitergeleitet (kein Onboarding)
- Bei falschem Passwort sehe ich eine klare Fehlermeldung
- Mein Login-Zustand bleibt erhalten (kein Re-Login bei erneutem App-Start solange Token gültig)
- Ich kann mein Passwort über "Passwort vergessen?" zurücksetzen

**INVEST-Bewertung:**
- Independent ✓ — separater Flow von Registrierung
- Negotiable ✓ — biometrischer Login als spätere Erweiterung möglich
- Valuable ✓ — Kernfunktion für Wiederkehrzugang
- Estimable ✓ — klarer Scope: Login-Screen + Token-Validierung
- Small ✓ — abgrenzbar
- Testable ✓ — E2E-Tests + Token-Validierung

---

### US-03: Passwort zurücksetzen

**Als Musiker möchte ich mein Passwort zurücksetzen können,**  
damit ich bei vergessenem Passwort wieder Zugang zu meinem Account bekomme.

**Kontext:** Nutzer kennt seine E-Mail-Adresse, hat aber das Passwort vergessen.

**Akzeptanzkriterien:**
- Ich kann über "Passwort vergessen?" auf dem Login-Screen einen Reset-Link anfordern
- Ich erhalte eine E-Mail mit Reset-Link (gültig für 30 Minuten)
- Ich kann das neue Passwort direkt im App-Screen setzen (Deep-Link aus E-Mail)
- Der "Erneut senden"-Button ist 60 Sekunden gesperrt (Cooldown)
- Nach erfolgreichem Reset werde ich automatisch eingeloggt

**INVEST-Bewertung:**
- Independent ✓ — separater Flow, kein Blocker für andere Stories
- Negotiable ✓ — Reset-Dauer und Cooldown konfigurierbar
- Valuable ✓ — kritisch für Account-Wiederherstellung
- Estimable ✓ — 3-stufiger Flow + E-Mail-Integration
- Small ✓ — abgrenzbar
- Testable ✓ — messbar: Token-Ablauf, E-Mail-Zustellung, Redirect

---

### US-04: Onboarding-Wizard

**Als neuer Nutzer möchte ich nach der Registrierung durch ein Onboarding geführt werden,**  
damit ich Sheetstorm sofort sinnvoll nutzen kann — mit meinem Instrument und meiner Kapelle korrekt eingerichtet.

**Kontext:** Direkt nach der Erstregistrierung, Daten aus der Registrierung sind vorausgefüllt.

**Akzeptanzkriterien:**
- Der Wizard startet automatisch nach der Erstregistrierung
- Der Wizard hat maximal 5 Schritte (Name bestätigen → Instrument → Kapelle & Standardstimme → Theme → Fertig)
- Jeder Schritt ist überspringbar
- Daten aus der Registrierung sind vorausgefüllt
- Nach Abschluss ist der Nutzer direkt in der Bibliothek (kein weiterer Blocker)
- Der Wizard startet **nicht** bei nachfolgendem Login bestehender Accounts
- Alle Onboarding-Daten können später in den Einstellungen geändert werden

**INVEST-Bewertung:**
- Independent ✓ — nach Registrierung eigenständiger Flow
- Negotiable ✓ — Schritte können angepasst werden, Reihenfolge diskutierbar
- Valuable ✓ — verbessert Aktivierungsrate und Setup-Qualität
- Estimable ✓ — 5 definierte Screens
- Small ✓ — klar abgegrenzt
- Testable ✓ — Onboarding-Abschlussrate, Instrumenten-/Kapellen-Belegung nach Wizard

---

## 3. Akzeptanzkriterien

### AC-01: JWT Access Token nach Login

- **Gegeben:** Nutzer gibt korrekte E-Mail + Passwort ein
- **Wenn:** POST /api/auth/login aufgerufen wird
- **Dann:**
  - Response enthält `access_token` (JWT, signiert mit RS256)
  - Response enthält `refresh_token` (opaque, 30 Tage gültig)
  - `access_token` läuft nach 15 Minuten ab (`exp` Claim gesetzt)
  - Response enthält `token_type: "Bearer"`
  - HTTP-Status: 200 OK

---

### AC-02: Refresh Token Rotation

- **Gegeben:** Nutzer hat ein gültiges Refresh Token
- **Wenn:** POST /api/auth/refresh aufgerufen wird
- **Dann:**
  - Response enthält neues `access_token` und neues `refresh_token`
  - Das alte Refresh Token wird sofort invalidiert (Single-Use)
  - Bei Verwendung eines bereits invalidiertes Refresh Tokens: HTTP 401 + alle Tokens des Nutzers werden invalidiert (Reuse-Detection)
  - HTTP-Status: 200 OK bei Erfolg, 401 bei ungültigem/abgelaufenem Token

---

### AC-03: Passwort-Mindestanforderungen

- **Gegeben:** Nutzer gibt ein Passwort ein (bei Registrierung oder Passwort-Reset)
- **Dann:**
  - Passwort muss mindestens **8 Zeichen** lang sein
  - Passwort muss mindestens **einen Großbuchstaben** enthalten
  - Passwort muss mindestens **eine Zahl oder ein Sonderzeichen** enthalten
  - Passwort-Stärke-Balken zeigt live: Schwach (rot) / Mittel (orange) / Stark (grün)
  - Checkliste zeigt für jede Anforderung ✗/✓ in Echtzeit
  - "Weiter"/"Speichern"-Button ist disabled bis alle Anforderungen erfüllt
  - Bei unerfüllten Anforderungen: Validierungsfehler mit spezifischer Fehlermeldung

---

### AC-04: Onboarding überspringbar

- **Gegeben:** Nutzer befindet sich in einem Onboarding-Schritt (1–5)
- **Wenn:** Nutzer auf "Überspringen" tippt
- **Dann:**
  - Der aktuelle Schritt wird übersprungen
  - Nutzer kommt zum nächsten Schritt (oder direkt zur Bibliothek wenn letzter Schritt)
  - Kein Datenverlust für bereits ausgefüllte Schritte
  - "Überspringen"-Link ist auf jedem Schritt sichtbar (ab Schritt 2)

---

### AC-05: Nach Onboarding — Nutzer hat Instrument und Kapelle

- **Gegeben:** Nutzer hat den Onboarding-Wizard abgeschlossen (oder übersprungen)
- **Dann:**
  - Wenn Schritt 2 (Instrument) ausgefüllt: `user.instruments` enthält mindestens ein Instrument
  - Wenn Schritt 3 (Kapelle) ausgefüllt: `user.bandMemberships` enthält mindestens einen Eintrag mit `defaultVoice`
  - Wenn übersprungen: Felder sind null/leer — App bleibt funktionsfähig
  - `user.onboardingCompleted = true` wird gesetzt (unabhängig davon ob übersprungen oder ausgefüllt)
  - Nutzer landet in der Bibliothek — kein weiterer Onboarding-Screen erscheint

---

### AC-06: Social Login (Google/Apple)

- **Gegeben:** Nutzer tippt auf "Mit Google" oder "Mit Apple"
- **Dann:**
  - Google-Login ist auf allen Plattformen (Web, iOS, Android) verfügbar
  - Apple-Login ist **nur** auf iOS und macOS angezeigt; auf Android/Web ist der Apple-Button **nicht sichtbar**
  - Nach erfolgreichem OAuth-Callback: Wenn E-Mail neu → Account erstellen + Onboarding starten
  - Nach erfolgreichem OAuth-Callback: Wenn E-Mail bekannt → einloggen + zur Bibliothek

---

### AC-07: Aushilfen-Deep-Link

- **Gegeben:** App wird mit `sheetstorm://aushilfe/[token]` geöffnet
- **Dann:**
  - Token wird gegen die API validiert (POST /api/auth/guest-token/validate)
  - Bei gültigem Token: Nutzer landet direkt in der Aushilfen-Ansicht (zugewiesene Stimme)
  - **Kein** Account erforderlich, **kein** Onboarding
  - Bei ungültigem/abgelaufenem Token: Fehlermeldung mit Option zum regulären Login/Register

---

## 4. API-Contract

### Konventionen

- Alle Endpunkte: `Content-Type: application/json`
- Fehler-Response-Format:
  ```json
  {
    "error": "ERROR_CODE",
    "message": "Für den Nutzer lesbare Fehlermeldung",
    "details": {}
  }
  ```
- Authentifizierte Endpunkte: `Authorization: Bearer <access_token>`

---

### POST /api/auth/register

**Beschreibung:** Neuen Nutzeraccount anlegen.

**Request Body:**
```json
{
  "email": "anna@beispiel.de",
  "password": "MeinPasswort1!",
  "displayName": "Anna Mustermann"
}
```

**Validierung:**
- `email`: gültige E-Mail-Adresse, noch nicht registriert
- `password`: min. 8 Zeichen, min. 1 Großbuchstabe, min. 1 Zahl oder Sonderzeichen
- `displayName`: 2–100 Zeichen, nicht leer

**Response 201 Created:**
```json
{
  "user": {
    "id": "uuid",
    "email": "anna@beispiel.de",
    "displayName": "Anna Mustermann",
    "onboardingCompleted": false,
    "createdAt": "2026-03-28T10:00:00Z"
  },
  "access_token": "eyJ...",
  "refresh_token": "rt_abc123...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 400 | `VALIDATION_ERROR` | Pflichtfelder fehlen oder ungültig |
| 409 | `EMAIL_ALREADY_EXISTS` | E-Mail bereits registriert |
| 422 | `PASSWORD_TOO_WEAK` | Passwort erfüllt Mindestanforderungen nicht |

---

### POST /api/auth/login

**Beschreibung:** Nutzer mit E-Mail + Passwort einloggen.

**Request Body:**
```json
{
  "email": "anna@beispiel.de",
  "password": "MeinPasswort1!"
}
```

**Response 200 OK:**
```json
{
  "user": {
    "id": "uuid",
    "email": "anna@beispiel.de",
    "displayName": "Anna Mustermann",
    "onboardingCompleted": true
  },
  "access_token": "eyJ...",
  "refresh_token": "rt_abc123...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 400 | `VALIDATION_ERROR` | E-Mail oder Passwort fehlt |
| 401 | `INVALID_CREDENTIALS` | E-Mail oder Passwort falsch (bewusst generisch) |
| 429 | `TOO_MANY_ATTEMPTS` | Rate Limit: 10 Versuche / 15 Minuten pro IP |

---

### POST /api/auth/refresh

**Beschreibung:** Access Token mittels Refresh Token erneuern.

**Request Body:**
```json
{
  "refresh_token": "rt_abc123..."
}
```

**Response 200 OK:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "rt_xyz789...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 401 | `INVALID_REFRESH_TOKEN` | Token ungültig oder abgelaufen |
| 401 | `REFRESH_TOKEN_REUSED` | Token bereits verwendet — alle Sessions invalidiert |

---

### POST /api/auth/forgot-password

**Beschreibung:** Passwort-Reset-E-Mail anfordern.

**Request Body:**
```json
{
  "email": "anna@beispiel.de"
}
```

**Response 200 OK** (immer, auch wenn E-Mail nicht existiert — verhindert User-Enumeration):
```json
{
  "message": "Wenn diese E-Mail registriert ist, wurde ein Reset-Link gesendet."
}
```

**Verhalten:**
- Reset-Link ist **30 Minuten** gültig
- Erneutes Anfordern innerhalb von **60 Sekunden** wird serverseitig geblockt
- Reset-Link enthält einmalig verwendbaren Token (`/api/auth/reset-password?token=...`)

---

### POST /api/auth/reset-password

**Beschreibung:** Neues Passwort mit Reset-Token setzen.

**Request Body:**
```json
{
  "token": "reset_abc123...",
  "newPassword": "NeuesPasswort2!"
}
```

**Response 200 OK:**
```json
{
  "message": "Passwort erfolgreich geändert.",
  "access_token": "eyJ...",
  "refresh_token": "rt_new...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 400 | `INVALID_RESET_TOKEN` | Token ungültig oder abgelaufen |
| 422 | `PASSWORD_TOO_WEAK` | Neues Passwort erfüllt Anforderungen nicht |

---

### POST /api/auth/social/google

**Beschreibung:** Google OAuth-Callback verarbeiten.

**Request Body:**
```json
{
  "idToken": "google_id_token..."
}
```

**Response 200 OK** (Login) oder **201 Created** (Registrierung):
```json
{
  "user": { "..." },
  "access_token": "eyJ...",
  "refresh_token": "rt_...",
  "isNewUser": true
}
```

---

### POST /api/auth/social/apple

**Beschreibung:** Apple Sign-In Callback verarbeiten (nur iOS/macOS).

**Request Body:**
```json
{
  "identityToken": "apple_identity_token...",
  "authorizationCode": "apple_auth_code...",
  "fullName": { "firstName": "Anna", "familyName": "Mustermann" }
}
```

**Response:** Gleiche Struktur wie Google Social Login.

---

## 5. Datenmodell

### Entity: User

```
User
├── id                    UUID, PK, auto-generated
├── email                 VARCHAR(255), UNIQUE, NOT NULL
├── passwordHash          VARCHAR(255), nullable (null bei Social-Login-Only)
├── displayName           VARCHAR(100), NOT NULL
├── avatarUrl             VARCHAR(500), nullable
├── onboardingCompleted   BOOLEAN, DEFAULT false
├── role                  ENUM('musician', 'admin', 'conductor', ...), DEFAULT 'musician'
├── authProvider          ENUM('email', 'google', 'apple'), DEFAULT 'email'
├── authProviderId        VARCHAR(255), nullable (externe ID beim Social Login)
├── emailVerified         BOOLEAN, DEFAULT false
├── isActive              BOOLEAN, DEFAULT true
├── createdAt             TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
├── updatedAt             TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
└── lastLoginAt           TIMESTAMP WITH TIME ZONE, nullable
```

### Entity: RefreshToken

```
RefreshToken
├── id                    UUID, PK
├── token                 VARCHAR(500), UNIQUE, NOT NULL (gehashed gespeichert)
├── userId                UUID, FK → User.id, NOT NULL
├── expiresAt             TIMESTAMP WITH TIME ZONE, NOT NULL
├── usedAt                TIMESTAMP WITH TIME ZONE, nullable (für Reuse-Detection)
├── isRevoked             BOOLEAN, DEFAULT false
├── createdAt             TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
└── deviceHint            VARCHAR(200), nullable (z.B. "iPhone 15, iOS 18")
```

### Entity: PasswordResetToken

```
PasswordResetToken
├── id                    UUID, PK
├── token                 VARCHAR(500), UNIQUE, NOT NULL (gehashed gespeichert)
├── userId                UUID, FK → User.id, NOT NULL
├── expiresAt             TIMESTAMP WITH TIME ZONE, NOT NULL (+30 Min ab Erstellung)
├── usedAt                TIMESTAMP WITH TIME ZONE, nullable
└── createdAt             TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
```

### Entity: UserInstrument (Onboarding-Daten)

```
UserInstrument
├── id                    UUID, PK
├── userId                UUID, FK → User.id, NOT NULL
├── instrumentName        VARCHAR(100), NOT NULL (z.B. "Klarinette")
├── defaultVoice          VARCHAR(100), nullable (z.B. "2. Klarinette")
├── fallbackEnabled       BOOLEAN, DEFAULT true
├── sortOrder             INTEGER, DEFAULT 0
└── createdAt             TIMESTAMP WITH TIME ZONE, DEFAULT NOW()
```

### Hinweise

- `passwordHash`: bcrypt mit Salt (min. 12 Rounds)
- `token` in RefreshToken/PasswordResetToken: SHA-256 Hash des eigentlichen Tokens (der Klartext-Token wird nur einmal zurückgegeben)
- Kapellen-Mitgliedschaft ist ein separates Entity (`BandMembership`) — Teil des Kapellen-Features (#11 oder #12)

---

## 6. Edge Cases & Fehlerszenarien

### Auth-State-Machine Grenzfälle

| Szenario | Verhalten |
|----------|-----------|
| App-Start mit abgelaufenem Access Token, gültigem Refresh Token | Automatischer Token-Refresh im Hintergrund, Nutzer bemerkt nichts |
| App-Start mit abgelaufenem Refresh Token | Nutzer wird zum Auth-Screen weitergeleitet, Fehlermeldung: "Deine Sitzung ist abgelaufen" |
| App-Start mit abgelaufenem Refresh Token während Nutzung | Nächste API-Anfrage schlägt fehl → zur Auth-Screen, aktuelle Navigation wird gespeichert für Deep-Link nach Re-Login |
| Gleichzeitiger Login von 2 Geräten | Beide Sessions bleiben aktiv (separate Refresh Tokens) |
| Refresh Token auf Gerät A verwendet, Gerät B versucht dasselbe Token | Reuse-Detection → alle Sessions invalidiert → Nutzer auf beiden Geräten ausgeloggt |

### Registrierung Grenzfälle

| Szenario | Verhalten |
|----------|-----------|
| E-Mail bereits registriert mit E-Mail/Passwort | HTTP 409 `EMAIL_ALREADY_EXISTS`, Hinweis: "Mit dieser E-Mail gibt es bereits einen Account. Einloggen?" |
| E-Mail bereits registriert via Google, jetzt mit Passwort registrieren | HTTP 409 mit Hinweis: "Diese E-Mail ist mit Google verknüpft. Bitte mit Google einloggen." |
| Social Login E-Mail = bereits registrierte E-Mail | Account wird verknüpft ODER Fehler je nach Konfiguration (Security-Entscheidung: Erstmal Fehler) |
| Nutzer bricht Registrierung nach Schritt 2 ab | Kein halbfertiger Account gespeichert (Transaktion, erst Commit nach Schritt 4) |
| Einladungslink ungültig/abgelaufen | Fehlermeldung "Dieser Einladungslink ist nicht mehr gültig", Option zur normalen Registrierung |

### Passwort-Reset Grenzfälle

| Szenario | Verhalten |
|----------|-----------|
| Reset-Link nach 30 Min aufgerufen | HTTP 400 `INVALID_RESET_TOKEN`, Nutzer kann erneut anfordern |
| Reset-Link zweimal verwendet | HTTP 400 `INVALID_RESET_TOKEN` beim zweiten Aufruf |
| Nutzer hat kein Passwort (Social-Login-Only) | "Passwort vergessen?"-Flow nicht angezeigt; Hinweis: "Du hast dich mit Google registriert" |
| E-Mail nicht im System | Response trotzdem 200 OK (verhindert User-Enumeration) |

### Onboarding Grenzfälle

| Szenario | Verhalten |
|----------|-----------|
| Nutzer schließt App während Onboarding | Beim Wiedereröffnen: Onboarding fortsetzen (wird erst als abgeschlossen markiert wenn Schritt 5 fertig oder komplett übersprungen) |
| Einladungscode ungültig | Fehlermeldung inline, Nutzer kann anderen Code eingeben oder "Erst mal ohne Kapelle" wählen |
| Einladungscode bereits abgelaufen | Fehlermeldung mit Hinweis, Kapellen-Admin zu kontaktieren |
| Nutzer überspringt alle Schritte | `onboardingCompleted = true`, alle Instrument/Kapellen-Felder leer → App funktioniert im "Solo-Modus" |

### Sicherheits-Szenarien

| Szenario | Verhalten |
|----------|-----------|
| Brute Force Login | Rate Limit: 10 Versuche / 15 Min pro IP → HTTP 429 |
| JWT-Manipulation | Signaturprüfung schlägt fehl → HTTP 401 |
| Expired Access Token mitgesendet | HTTP 401 `TOKEN_EXPIRED` → Client soll Refresh auslösen |
| Concurrent Refresh mit demselben Token (Race Condition) | Idempotenz-Key oder erstes Request gewinnt, zweites bekommt neues Token vom ersten |

---

## 7. Abhängigkeiten

| Issue | Titel | Typ | Beziehung |
|-------|-------|-----|-----------|
| **#7** | Backend-Scaffolding | Technisch | **Blockiert durch** — ASP.NET Core Projekt, DB-Connection, JWT-Middleware müssen existieren |
| **#8** | Frontend-Scaffolding | Technisch | **Blockiert durch** — Flutter Projekt, Riverpod State Management, Navigation-Setup müssen existieren |
| **#9** | UX Auth/Onboarding | Design | **Abhängig von** — Wireframes und Flows sind Input für diese Spec; #9 ist abgeschlossen |
| **#11** | Kapellenverwaltung-Spec | Feature | **Wird benötigt von** — `BandMembership`-Entity und Einladungslink-API sind Teil dieses Features |

### Technische Voraussetzungen (aus #7/#8)

- PostgreSQL-Datenbankverbindung konfiguriert
- Entity Framework Core Migrations eingerichtet
- JWT-Middleware für ASP.NET Core konfiguriert (RS256, JWKS-Endpoint vorhanden)
- Flutter: `flutter_secure_storage` für Token-Speicherung
- Flutter: `riverpod` für Auth-State-Management
- E-Mail-Versand: SMTP oder transaktionaler E-Mail-Service (z.B. SendGrid) konfiguriert

---

## 8. Definition of Done

### Funktional

- [ ] Alle 4 User Stories (US-01 bis US-04) sind vollständig implementiert
- [ ] Alle 7 Akzeptanzkriterien (AC-01 bis AC-07) sind erfüllt und testbar
- [ ] Alle API-Endpunkte sind implementiert und geben die spezifizierten Responses zurück
- [ ] Alle Edge Cases aus §6 sind behandelt (getestet oder mit explizitem Fallback)

### Qualität

- [ ] Unit Tests für Token-Generierung, -Validierung und Rotation (Backend)
- [ ] Unit Tests für Passwort-Validierungslogik (Backend + Frontend)
- [ ] Integration Tests für alle Auth-API-Endpunkte
- [ ] E2E-Test: Vollständiger Happy Path Registrierung → Onboarding → Bibliothek
- [ ] E2E-Test: Login → Bibliothek (bestehender Account)
- [ ] E2E-Test: Passwort vergessen → E-Mail → Reset → Login
- [ ] Test-Coverage Backend: ≥ 80% für Auth-Modul

### UX & Accessibility

- [ ] UX-Review durch Wanda bestätigt (alle Screens entsprechen auth-onboarding.md)
- [ ] Touch-Targets mindestens 44×44px auf allen interaktiven Elementen
- [ ] Apple-Button ist auf Android/Web **nicht** sichtbar
- [ ] Passwort-Stärke-Anzeige ist funktional (Farben + Checkliste)
- [ ] Onboarding "Überspringen" ist auf jedem Schritt ab Schritt 2 sichtbar

### Sicherheit

- [ ] Passwörter werden mit bcrypt (min. 12 Rounds) gehashed gespeichert
- [ ] Refresh Tokens werden gehashed in der Datenbank gespeichert
- [ ] Rate Limiting für Login-Endpunkt implementiert (10 Versuche / 15 Min)
- [ ] User-Enumeration bei "Passwort vergessen" verhindert (immer 200 OK)
- [ ] Refresh Token Reuse Detection implementiert (alle Sessions invalidieren)
- [ ] Security Review durch Stark abgenommen

### Dokumentation

- [ ] API-Endpunkte in OpenAPI/Swagger dokumentiert
- [ ] README oder Wiki-Eintrag für lokales Dev-Setup (JWT-Keys generieren etc.)
- [ ] Diese Feature-Spec ist vollständig und von Thomas abgenommen

### Deployment

- [ ] Datenbankmigrationen sind idempotent und rollback-fähig
- [ ] Environment Variables für JWT-Keys, E-Mail-Service sind dokumentiert
- [ ] Feature ist im Staging-Environment deploybar und getestet
