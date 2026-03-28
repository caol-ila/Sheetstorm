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
