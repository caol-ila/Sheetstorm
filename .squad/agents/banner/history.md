# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28 — Issue #11: Auth Backend (JWT, Refresh, Reset)

**Branch:** `squad/11-auth-backend`  
**Worktree:** `C:\Source\Sheetstorm-11`  
**Base:** `squad/7-backend-scaffolding`

**Was gebaut:**
- `AuthController` mit 5 Endpoints: `/register`, `/login`, `/refresh`, `/forgot-password`, `/reset-password`
- `AuthService` + `IAuthService` in `Sheetstorm.Infrastructure.Auth`
- `RefreshToken` Entity mit Family-basierter Rotation und Reuse-Detection (ganzes Token-Family wird revoked bei Wiederverwendung)
- `Musiker` Entity erweitert: `Instrument`, `OnboardingCompleted`, `PasswordResetToken`, `PasswordResetTokenExpiresAt`, `PasswordResetRequestedAt`
- EF Konfigurationen: `MusikerConfiguration`, `RefreshTokenConfiguration` (Unique-Indizes)
- `AuthExceptionMiddleware` für strukturierte JSON Fehler-Responses
- Rate Limiting: 10 Requests / 15 Minuten pro IP auf allen Auth-Endpoints (built-in ASP.NET Core)
- BCrypt.Net-Next 4.1.0 für Password-Hashing

**Architektur-Entscheidung:** DTOs in `Sheetstorm.Domain.Auth` statt `Sheetstorm.Api.Models.Auth`, damit `Infrastructure` sie ohne zirkuläre Referenz nutzen kann. Api-Layer bekommt die Types via global using.

**Pakete hinzugefügt:**
- `BCrypt.Net-Next` 4.1.0 → Infrastructure
- `Microsoft.AspNetCore.Authentication.JwtBearer` 10.0.5 → Infrastructure (für JWT-Generierung)

---

### 2026-03-28 — Issue #16: Kapellenverwaltung — Backend REST-API

**Branch:** `squad/16-kapelle-backend`  
**Worktree:** `C:\Source\Sheetstorm-16`  
**Base:** `squad/11-auth-backend`

**Was gebaut:**
- `KapelleController` mit 6 Endpoints: `POST /api/kapellen`, `GET /api/kapellen`, `GET /api/kapellen/{id}`, `PUT /api/kapellen/{id}`, `DELETE /api/kapellen/{id}`, `POST /api/kapellen/beitreten`
- `MitgliederController` mit 4 Endpoints: `GET mitglieder`, `POST einladungen`, `PUT mitglieder/{userId}/rolle`, `DELETE mitglieder/{userId}`
- `Einladung` Entity (Code, KapelleID, VorgeseheRolle, ExpiresAt, IsUsed, ErstelltVon, EingeloestVon)
- `Kapelle` Entity erweitert: `Ort`, `LogoUrl`, `Einladungen` Navigation
- DTOs in `Sheetstorm.Domain.Kapellenverwaltung` (wegen Namenskonflikt mit Klasse `Kapelle`)
- EF Konfigurationen: `KapelleConfiguration`, `MitgliedschaftConfiguration` (Unique-Index MusikerID+KapelleID), `EinladungConfiguration` (Unique-Index Code)
- `KapelleService` + `IKapelleService` in `Sheetstorm.Infrastructure.KapelleManagement`
- Rollenbasierte Autorisierung in der Service-Schicht (kein Policy-Framework nötig)
- Einladungscode: 8-Zeichen, kryptografisch zufällig, Einmalverwendung, konfigurierbares Ablaufdatum (1–30 Tage)
- Schutz: Letzter Admin kann Kapelle nicht verlassen; Re-Aktivierung bei Wiederbeitritt

**Architektur-Entscheidungen:**
- DTOs-Namespace `Sheetstorm.Domain.Kapellenverwaltung` statt `Sheetstorm.Domain.Kapelle`, weil letzteres mit der gleichnamigen Entity-Klasse kollidiert (C# löst Namespace `Kapelle` vor importiertem Typ auf)
- Service-Namespace `Sheetstorm.Infrastructure.KapelleManagement` statt `Sheetstorm.Infrastructure.Kapelle` — gleicher Grund: Namespace-Konflikt mit `Kapelle`-Klasse in Infrastructure-internen Dateien
- Rollenprüfungen in Service-Schicht, nicht via ASP.NET Core Policies — Rollen sind in der DB, kein JWT-Claim, flexibler für Multi-Kapellen-Szenario
- `AuthException` wird auch für Kapelle-Fehler genutzt (Middleware fängt sie bereits ab)
- `POST /api/kapellen/beitreten` im `KapelleController` statt im `MitgliederController`, da kein `{kapelleId}` vorhanden und Antwort ein `KapelleDto` ist
