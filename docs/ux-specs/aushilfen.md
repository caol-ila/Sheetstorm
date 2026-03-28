# UX-Spec: Aushilfen-Zugang — Sheetstorm

> **Version:** 1.0  
> **Status:** Entwurf — Review durch Hill (Frontend) und Banner (Backend) ausstehend  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-04-15  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Issue:** TBD  
> **Referenzen:** `docs/feature-specs/aushilfen-spec.md`, `docs/ux-design.md`, `docs/ux-specs/auth-onboarding.md`

---

## Inhaltsverzeichnis

1. [Überblick & Konzept](#1-überblick--konzept)
2. [Design-Tokens (Referenz)](#2-design-tokens-referenz)
3. [Flow 1: Link/QR erstellen (Admin)](#3-flow-1-linkqr-erstellen-admin)
4. [Flow 2: Aushilfe öffnet Link/QR](#4-flow-2-aushilfe-öffnet-linkqr)
5. [Flow 3: Aushilfen-Web-View (Read-Only)](#5-flow-3-aushilfen-web-view-read-only)
6. [Flow 4: Aushilfen verwalten (Admin)](#6-flow-4-aushilfen-verwalten-admin)
7. [Interaction Patterns](#7-interaction-patterns)
8. [Error States & Leerzustände](#8-error-states--leerzustände)
9. [Accessibility](#9-accessibility)
10. [Responsive Breakpoints](#10-responsive-breakpoints)
11. [Abhängigkeiten](#11-abhängigkeiten)

---

## 1. Überblick & Konzept

### 1.1 Ziel

Aushilfen (Gastmusiker) sollen **ohne Account-Erstellung sofort auf ihre Noten zugreifen** können. Ein Dirigent/Admin erstellt einen temporären Zugangslink mit QR-Code, den die Aushilfe scannt oder öffnet. Der Zugang ist:

- **Zeitlich begrenzt** (z.B. 7 Tage)
- **Auf eine Stimme beschränkt** (z.B. „2. Trompete")
- **Auf ein Konzert/Probe beschränkt** (Termin-gebunden)
- **Revozierbar** (Admin kann jederzeit widerrufen)

**Kernproblem:**
- Aushilfen sollen nicht durch Registrierung/Login abgeschreckt werden
- Keine Account-Verwaltung für temporäre Nutzer
- Schneller Zugang bei Proben/Konzerten (QR-Code am Notenständer)

### 1.2 Nutzungskontext

**Szenarien:**
1. **Probe mit Aushilfe:** Dirigent erstellt Link vor Probe, schickt per WhatsApp
2. **Konzert mit Gastmusiker:** Admin erstellt QR-Code, druckt aus, legt am Eingang aus
3. **Kurzfristige Vertretung:** Link per E-Mail, Aushilfe öffnet auf eigenem Gerät
4. **Offline-Nutzung:** Aushilfe lädt Noten beim ersten Öffnen, spielt später offline

### 1.3 Auth-State-Machine (Aushilfen-Sonderfall)

```
App-Start / Deep Link
       │
       ▼
 URL prüfen: /aushilfe/{token}?
       │
   ┌───┴───┐
   │       │
  Ja      Nein
   │       │
   ▼       ▼
Token    Normal
valide?  Auth-Flow
   │     (siehe auth-onboarding.md)
 ┌─┴─┐
 Ja Nein
 │   │
 ▼   ▼
Guest- Error
View   (Token ungültig)
```

**Wichtig:**
- Aushilfen-Flow bypassed normale Authentifizierung
- Token-Prüfung erfolgt **vor** Auth-State-Check
- Kein Login-Screen, keine Registrierung, keine Onboarding-Schritte

### 1.4 Grundprinzipien

- **Zero-Friction:** Tap auf Link → direkt Noten sehen (max 3 Sekunden)
- **Read-Only:** Aushilfe kann nichts bearbeiten, keine Annotationen
- **Privacy-First:** Aushilfe sieht keine Mitgliederliste, keine anderen Stimmen
- **Offline-Support:** Nach initialem Load funktioniert alles offline
- **Progressive Web App (PWA):** Aushilfen-View kann auch im Browser funktionieren (keine App-Installation nötig)

---

## 2. Design-Tokens (Referenz)

Alle hier verwendeten Token stammen aus `docs/ux-design.md` § 7.

| Token                     | Wert       | Verwendung in Aushilfen-View                 |
|---------------------------|------------|----------------------------------------------|
| `color-primary`           | `#1A56DB`  | Play-Button, aktives Stück                   |
| `color-warning`           | `#D97706`  | Hinweis „Zugang läuft bald ab"               |
| `color-error`             | `#DC2626`  | Token abgelaufen/widerrufen                  |
| `color-text-secondary`    | `#6B7280`  | Metadaten (Gültig bis, Rolle)                |
| `color-border`            | `#E5E7EB`  | Setlist-Karten                               |
| `color-background`        | `#FFFFFF`  | Screen-Hintergrund                           |
| `font-size-base`          | `16sp`     | Setlist-Titel, Notentext                     |
| `font-size-lg`            | `20sp`     | Überschriften                                |
| `font-size-sm`            | `14sp`     | Sekundär-Text, Gültigkeits-Info              |
| `space-md`                | `16px`     | Padding zwischen Karten                      |
| `space-lg`                | `24px`     | Header-Padding                               |
| `border-radius-md`        | `8px`      | Karten, Buttons                              |
| `touch-target-min`        | `44×44px`  | Alle interaktiven Elemente                   |
| `touch-target-game`       | `64×64px`  | Play-Button (groß)                           |

---

## 3. Flow 1: Link/QR erstellen (Admin)

### 3.1 Entry Point

**Primär:**
- **Termin-Detail-Ansicht** → „+ Aushilfe hinzufügen" (Button)

**Sekundär:**
- **Kapellen-Admin** → „Aushilfen verwalten" → „+ Neue Aushilfe"

### 3.2 Interaktion

1. Admin öffnet Termin-Detail
2. Tappt auf „+ Aushilfe hinzufügen"
3. Modal/Bottom-Sheet öffnet sich
4. Felder ausfüllen:
   - Name (Vorname Nachname, Pflichtfeld)
   - Instrument (Dropdown, z.B. Trompete)
   - Stimme (Dropdown, z.B. 2. Trompete — abhängig von Instrument)
   - Gültig bis (Date-Picker, Standard: Termin-Datum + 7 Tage)
   - Notiz (Optional, für Admin-Zwecke)
5. „Zugang erstellen" → Backend generiert Token
6. Anzeige: Link + QR-Code + Aktionen

### 3.3 Wireframe — Phone (Erstellung)

```
┌─────────────────────────────────┐
│ Aushilfe hinzufügen        ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Termin: Konzert 2026-03-15      │ ← Kontext-Info
│                                 │
│ Name *                          │
│ ┌───────────────────────────┐   │
│ │ Max Mustermann            │   │ ← Text-Input, Pflicht
│ └───────────────────────────┘   │
│                                 │
│ Instrument *                    │
│ ┌───────────────────────────┐   │
│ │ Trompete              ▼  │   │ ← Dropdown
│ └───────────────────────────┘   │
│                                 │
│ Stimme *                        │
│ ┌───────────────────────────┐   │
│ │ 2. Trompete           ▼  │   │ ← Dropdown (abhängig von Instrument)
│ └───────────────────────────┘   │
│                                 │
│ Gültig bis *                    │
│ ┌───────────────────────────┐   │
│ │ 22.03.2026            📅 │   │ ← Date-Picker
│ └───────────────────────────┘   │
│                                 │
│ Notiz (optional)                │
│ ┌───────────────────────────┐   │
│ │ Ersatz für Anna           │   │ ← Text-Area
│ └───────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   Zugang erstellen        │   │ ← Primär-Button, 48px
│ └───────────────────────────┘   │
│                                 │
│ [Abbrechen]                     │ ← Sekundär-Button (Text)
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Alle Pflichtfelder mit `*` markiert
- Instrument-Dropdown: Liste aus Kapellen-Registern
- Stimme-Dropdown: Dynamisch basierend auf Instrument (aus Bibliothek)
- Gültig-bis: Standard = Termin-Datum + 7 Tage

### 3.4 Wireframe — Phone (Link & QR anzeigen)

```
┌─────────────────────────────────┐
│ Aushilfe erstellt          ✕   │ ← Modal-Header
├─────────────────────────────────┤
│                                 │
│ Max Mustermann                  │ ← Name, font-size-lg
│ 2. Trompete                     │ ← Stimme, color-text-secondary
│ Gültig bis: 22.03.2026          │
│                                 │
├─────────────────────────────────┤
│                                 │
│      ┌─────────────────┐        │
│      │ ░░▓▓▓▓░░▓▓▓▓░░ │        │ ← QR-Code (Client-generiert)
│      │ ▓▓░░▓▓░░▓▓░░▓▓ │        │
│      │ ░░▓▓▓▓░░▓▓▓▓░░ │        │
│      └─────────────────┘        │
│                                 │
│  👆 Zum Scannen bereithalten    │ ← Hinweis
│                                 │
├─────────────────────────────────┤
│                                 │
│ Link:                           │
│ ┌───────────────────────────┐   │
│ │ sheetstorm.io/aushilfe/   │   │ ← Readonly Text-Field
│ │ ash_3k8d...7fj2       📋  │   │ ← Copy-Icon
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │   📲  Link teilen         │   │ ← Share-Button (System-Sheet)
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │   🖼️  QR als Bild speichern │   │ ← Download QR as PNG
│ └───────────────────────────┘   │
│                                 │
│ [Fertig]                        │ ← Schließt Modal
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- QR-Code wird **client-seitig** generiert (JavaScript/Dart QR-Library)
- Copy-Button kopiert vollen Link in Zwischenablage → Toast „Link kopiert"
- Share-Button öffnet System-Share-Sheet (WhatsApp, E-Mail, etc.)
- QR-Download: PNG mit 512×512px, Dateiname `aushilfe_max-mustermann.png`

### 3.5 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Termin: Konzert 2026-03-15                                 │
├──────────────────────────────────────────────────────────────┤
│ Aushilfe hinzufügen                                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────┐  ┌────────────────────────────────┐ │
│  │                    │  │ Name *                         │ │
│  │                    │  │ ┌────────────────────────────┐ │ │
│  │  QR-Code Preview   │  │ │ Max Mustermann             │ │ │
│  │  (nach Erstellung) │  │ └────────────────────────────┘ │ │
│  │                    │  │                                │ │
│  │                    │  │ Instrument *       Stimme *    │ │
│  │                    │  │ ┌───────────┐  ┌─────────────┐│ │
│  │                    │  │ │ Trompete ▼│  │ 2. Tromp. ▼││ │
│  │                    │  │ └───────────┘  └─────────────┘│ │
│  │                    │  │                                │ │
│  └────────────────────┘  │ Gültig bis *                   │ │
│                          │ ┌────────────────────────────┐ │ │
│                          │ │ 22.03.2026             📅 │ │ │
│                          │ └────────────────────────────┘ │ │
│                          │                                │ │
│                          │ Notiz (optional)               │ │
│                          │ ┌────────────────────────────┐ │ │
│                          │ │ Ersatz für Anna            │ │ │
│                          │ └────────────────────────────┘ │ │
│                          │                                │ │
│                          │ [Abbrechen] [Zugang erstellen] │ │
│                          └────────────────────────────────┘ │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- QR-Code wird sofort nach Erstellung in Split-View angezeigt
- Copy-Link-Button direkt neben QR
- Vollständiger Link sichtbar (nicht gekürzt)

---

## 4. Flow 2: Aushilfe öffnet Link/QR

### 4.1 Entry Point

**Varianten:**
1. **QR-Code scannen:** Kamera-App → öffnet `https://app.sheetstorm.io/aushilfe/{token}`
2. **Link tippen:** WhatsApp/E-Mail → öffnet Link im Browser/App
3. **PWA:** Link öffnet sich im Browser, kann als PWA installiert werden

### 4.2 Interaktion

1. Aushilfe öffnet Link/scannt QR
2. App prüft Token (API-Call)
3. **Valide:** Direkt zur Aushilfen-Web-View (Flow 3)
4. **Invalide:** Error-Screen (abgelaufen/widerrufen)

### 4.3 Token-Validierung (Hintergrund)

**API-Call:**
```
GET /api/v1/aushilfe/{token}
```

**Response (Success):**
```json
{
  "name": "Max Mustermann",
  "instrument": "Trompete",
  "stimme": "2. Trompete",
  "termin": {
    "id": 123,
    "titel": "Konzert 2026-03-15",
    "datum": "2026-03-15",
    "setlist": { ... }
  },
  "gueltigBis": "2026-03-22T23:59:59Z",
  "status": "aktiv"
}
```

**Response (Error):**
```json
{
  "error": "TOKEN_WIDERRUFEN",
  "message": "Dieser Zugang wurde widerrufen."
}
```

### 4.4 Wireframe — Phone (Loading)

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│         🎵                      │
│      Sheetstorm                 │
│                                 │
│      ⏳ Zugang wird geprüft...  │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Loading dauert <1 Sekunde (Token-Prüfung)
- Kein Login-Screen, keine Registrierung
- Nach erfolgreicher Prüfung → direkt zu Flow 3

---

## 5. Flow 3: Aushilfen-Web-View (Read-Only)

### 5.1 Konzept

Aushilfe sieht eine **vereinfachte Ansicht** mit:
- Header: Name, Rolle, Gültigkeits-Hinweis
- Setlist: Liste der Stücke für das Konzert/Probe
- Play-Modus: Gleicher Spielmodus wie reguläre App (nur eigene Stimme)

**Einschränkungen:**
- **Keine Bibliothek** (nur Setlist des Termins)
- **Keine Annotationen** (Read-Only)
- **Keine Mitgliederliste** (Privacy)
- **Keine Konfiguration** (nur Play)

### 5.2 Wireframe — Phone (Aushilfen-Home)

```
┌─────────────────────────────────┐
│ 🎵 Sheetstorm                   │ ← Header (kein zurück-Button)
├─────────────────────────────────┤
│                                 │
│ 👤 Max Mustermann               │ ← Name, font-size-lg
│ 2. Trompete                     │ ← Rolle, color-text-secondary
│                                 │
│ ⏳ Zugang bis 22.03.2026        │ ← Gültigkeit, color-warning
│                                 │
├─────────────────────────────────┤
│ Konzert 2026-03-15              │ ← Termin-Titel
├─────────────────────────────────┤
│                                 │
│ Setlist:                        │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 1. Radetzky-Marsch      ▶ │   │ ← Stück-Karte, Play-Icon
│ │    Op. 228 · Strauss      │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 2. An der schönen...    ▶ │   │
│ │    Op. 314 · Strauss      │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 3. Tiroler Adler        ▶ │   │
│ │    Trad. · Arr. Müller    │   │
│ └───────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│ ℹ️ Du kannst die Noten offline   │ ← Hinweis
│   nutzen, nachdem sie geladen   │
│   wurden.                       │
└─────────────────────────────────┘
```

**Hinweise:**
- Kein Tab-Bar (keine Navigation zu anderen Bereichen)
- Play-Icon rechts → öffnet Spielmodus (Flow 5.3)
- Gültigkeits-Hinweis ist prominent aber nicht störend
- Wenn Zugang <24h gültig: Hinweis wird `color-error` mit „Läuft bald ab"

### 5.3 Wireframe — Phone (Spielmodus)

```
┌─────────────────────────────────┐
│                                 │ ← Fullscreen
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  🎼                       ║  │
│  ║                           ║  │
│  ║   [Noten-Rendering]       ║  │
│  ║   (2. Trompete)           ║  │
│  ║                           ║  │
│  ║                           ║  │
│  ║                           ║  │
│  ║                           ║  │
│  ║                           ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  ┌──────────────────────┐       │
│  │ ✕ Radetzky-Marsch    │       │ ← Overlay-Bar (ausblendbar)
│  └──────────────────────┘       │
│                                 │
│          [Tap]       [Tap]      │ ← Tap-Zonen 40/60
│                                 │
└─────────────────────────────────┘
```

**Hinweise:**
- Gleicher Spielmodus wie reguläre App (siehe `docs/ux-specs/spielmodus.md`)
- **Einschränkungen:**
  - Keine Annotationen
  - Keine Stimmen-Wechsel (nur zugewiesene Stimme)
  - Keine Setlist-Navigation (nur aktuelles Stück)
- **Funktionen:**
  - Blättern (Tap-Zonen)
  - Zoom (Pinch)
  - Night-Mode (optional, falls konfiguriert)
  - Overlay-Bar: Zurück, Titel, Seitenzahl

### 5.4 Wireframe — Tablet/Desktop (Landscape)

```
┌──────────────────────────────────────────────────────────────┐
│ 🎵 Sheetstorm                                                │
├──────────────────────────────────────────────────────────────┤
│ Max Mustermann · 2. Trompete · Zugang bis 22.03.2026        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Konzert 2026-03-15                                           │
│                                                              │
│ ┌────────────────────────────────────────────────────────┐   │
│ │ 1. Radetzky-Marsch                                  ▶ │   │
│ │    Op. 228 · Johann Strauss I                         │   │
│ ├────────────────────────────────────────────────────────┤   │
│ │ 2. An der schönen blauen Donau                      ▶ │   │
│ │    Op. 314 · Johann Strauss II                        │   │
│ ├────────────────────────────────────────────────────────┤   │
│ │ 3. Tiroler Adler                                    ▶ │   │
│ │    Trad. · Arr. Josef Müller                          │   │
│ └────────────────────────────────────────────────────────┘   │
│                                                              │
│ ℹ️ Du kannst die Noten offline nutzen, nachdem sie geladen   │
│   wurden.                                                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Mehr Platz für Metadaten (Komponist, Opus-Nummer)
- Hover auf Stück-Karte → Thumbnail-Preview (optional)
- Keyboard-Shortcut: Enter → Play aktuelles Stück

---

## 6. Flow 4: Aushilfen verwalten (Admin)

### 6.1 Entry Point

**Primär:**
- **Termin-Detail-Ansicht** → Tab „Aushilfen" (neben Teilnehmer)

**Sekundär:**
- **Kapellen-Admin** → „Aushilfen verwalten"

### 6.2 Interaktion

1. Admin öffnet Termin-Detail
2. Wählt Tab „Aushilfen"
3. Sieht Liste aller Aushilfen (aktiv/widerrufen/abgelaufen)
4. Aktionen:
   - Link erneut kopieren
   - QR erneut anzeigen
   - Gültigkeit verlängern
   - Zugang widerrufen

### 6.3 Wireframe — Phone (Aushilfen-Liste)

```
┌─────────────────────────────────┐
│ ← Termin: Konzert 2026-03-15    │
├─────────────────────────────────┤
│ Teilnehmer [Aushilfen] Setlist  │ ← Tab-Bar
├─────────────────────────────────┤
│                                 │
│ Aktiv (2)                       │ ← Sektion-Header
│                                 │
│ ┌───────────────────────────┐   │
│ │ Max Mustermann         ⋯ │   │ ← 3-Dot-Menü
│ │ 2. Trompete               │   │
│ │ Gültig bis: 22.03.2026    │   │
│ │                           │   │
│ │ 👁️ 3× aufgerufen           │   │ ← Zugriffs-Counter
│ │ Zuletzt: 15.03., 14:23    │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ Anna Schmidt           ⋯ │   │
│ │ 1. Flöte                  │   │
│ │ Gültig bis: 20.03.2026    │   │
│ │                           │   │
│ │ 👁️ 1× aufgerufen           │   │
│ │ Zuletzt: 14.03., 19:45    │   │
│ └───────────────────────────┘   │
│                                 │
│ Widerrufen (1)                  │ ← Sektion-Header
│                                 │
│ ┌───────────────────────────┐   │
│ │ ⚠️ Peter Meier            ⋯ │   │ ← Grau eingefärbt
│ │ 1. Klarinette             │   │
│ │ Widerrufen am: 12.03.     │   │
│ └───────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │   + Aushilfe hinzufügen   │   │ ← FAB (Floating Action Button)
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

**Hinweise:**
- Status-Badges: Aktiv (grün), Widerrufen (rot), Abgelaufen (grau)
- Zugriffs-Counter zeigt, ob Aushilfe Link geöffnet hat
- 3-Dot-Menü → Aktionen (siehe 6.4)

### 6.4 Wireframe — Phone (Aktionen-Menü)

```
┌─────────────────────────────────┐
│ Max Mustermann                  │ ← Bottom-Sheet
├─────────────────────────────────┤
│                                 │
│ 📋 Link kopieren                │ ← Aktion 1
│                                 │
│ 🖼️ QR-Code anzeigen             │ ← Aktion 2
│                                 │
│ 📅 Gültigkeit verlängern        │ ← Aktion 3
│                                 │
│ 🚫 Zugang widerrufen            │ ← Aktion 4 (destructive)
│                                 │
├─────────────────────────────────┤
│ [Abbrechen]                     │
└─────────────────────────────────┘
```

**Aktionen:**
1. **Link kopieren:** Kopiert `https://app.sheetstorm.io/aushilfe/{token}` → Toast „Link kopiert"
2. **QR-Code anzeigen:** Fullscreen-QR (wie in Flow 3.4)
3. **Gültigkeit verlängern:** Date-Picker → neues Datum → API-Update
4. **Zugang widerrufen:** Confirmation-Dialog → Status = „widerrufen" → Aushilfe kann nicht mehr zugreifen

### 6.5 Wireframe — Phone (Widerrufen-Confirmation)

```
┌─────────────────────────────────┐
│ Zugang widerrufen?              │ ← Dialog-Header
├─────────────────────────────────┤
│                                 │
│ Max Mustermann kann nach dem    │
│ Widerrufen nicht mehr auf die   │
│ Noten zugreifen.                │
│                                 │
│ Diese Aktion kann nicht rück-   │
│ gängig gemacht werden.          │
│                                 │
├─────────────────────────────────┤
│ [Abbrechen] [Widerrufen]        │ ← Destructive rechts
└─────────────────────────────────┘
```

### 6.6 Wireframe — Tablet/Desktop

```
┌──────────────────────────────────────────────────────────────┐
│ ← Termin: Konzert 2026-03-15                                 │
├──────────────────────────────────────────────────────────────┤
│ Teilnehmer  Aushilfen  Setlist                               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Aktiv (2)                                                   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Max Mustermann             Gültig bis: 22.03.2026     │  │
│  │ 2. Trompete                👁️ 3× aufgerufen (15.03.)   │  │
│  │                                                        │  │
│  │ [Link kopieren] [QR zeigen] [Verlängern] [Widerrufen] │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Anna Schmidt               Gültig bis: 20.03.2026     │  │
│  │ 1. Flöte                   👁️ 1× aufgerufen (14.03.)   │  │
│  │                                                        │  │
│  │ [Link kopieren] [QR zeigen] [Verlängern] [Widerrufen] │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  Widerrufen (1)                                              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ⚠️ Peter Meier              Widerrufen am: 12.03.2026   │  │
│  │ 1. Klarinette                                          │  │
│  │                                                        │  │
│  │ [Löschen]                                              │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  [+ Aushilfe hinzufügen]                                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Desktop-Vorteile:**
- Inline-Aktionen (keine Bottom-Sheet nötig)
- Mehr Metadaten sichtbar (letzter Zugriff, Notiz)
- QR-Code-Hover-Preview (optional)

---

## 7. Interaction Patterns

### 7.1 Token-Generierung

- **Format:** `ash_` + 43 Zeichen (base64url)
- **Entropie:** 256-bit (sicher gegen Brute-Force)
- **Backend:** Generierung erfolgt server-seitig, nicht client-seitig

### 7.2 QR-Code-Generierung

- **Client-seitig:** JavaScript/Dart QR-Library (z.B. `qr_flutter`)
- **Größe:** 256×256px (inline), 512×512px (Download)
- **Error Correction:** Level M (15% recovery)
- **Farbe:** Schwarz auf Weiß (höchster Kontrast)

### 7.3 Link-Sharing

- **System-Share-Sheet:** Native iOS/Android/Desktop Share-API
- **Fallback:** Copy-to-Clipboard → Toast „Link kopiert"
- **Deep-Link:** `https://app.sheetstorm.io/aushilfe/{token}`
  - Öffnet App, falls installiert
  - Öffnet PWA, falls im Browser

### 7.4 Offline-Support

- **Service Worker:** Caches PDFs und Assets nach initialem Load
- **Cache-Strategy:** Cache-First für PDFs, Network-First für Token-Validierung
- **Fallback:** Wenn offline und Token nicht gecacht, zeige „Offline — bitte online gehen"

### 7.5 Auto-Refresh

- **Gültigkeits-Check:** Alle 5 Minuten (während Aushilfe aktiv ist)
- **Token-Widerruf:** Aushilfe wird automatisch ausgeloggt und sieht Error-Screen
- **Ablauf:** Hinweis „Zugang abgelaufen" erscheint beim nächsten Öffnen

---

## 8. Error States & Leerzustände

### 8.1 Token abgelaufen

```
┌─────────────────────────────────┐
│                                 │
│         ⚠️                      │
│                                 │
│   Zugang abgelaufen             │ ← font-size-lg, color-error
│                                 │
│   Dieser Zugang ist nicht mehr  │
│   gültig. Bitte kontaktiere den │
│   Dirigenten für einen neuen    │
│   Link.                         │
│                                 │
│   [Zur Startseite]              │ ← Öffnet sheetstorm.io
│                                 │
└─────────────────────────────────┘
```

### 8.2 Token widerrufen

```
┌─────────────────────────────────┐
│                                 │
│         🚫                      │
│                                 │
│   Zugang widerrufen             │
│                                 │
│   Dieser Zugang wurde vom       │
│   Dirigenten widerrufen. Bei    │
│   Fragen wende dich bitte an    │
│   deine Kapelle.                │
│                                 │
│   [Zur Startseite]              │
│                                 │
└─────────────────────────────────┘
```

### 8.3 Token ungültig (Brute-Force/Tippfehler)

```
┌─────────────────────────────────┐
│                                 │
│         ❌                      │
│                                 │
│   Link ungültig                 │
│                                 │
│   Dieser Link ist ungültig.     │
│   Bitte prüfe den Link oder     │
│   scanne den QR-Code erneut.    │
│                                 │
│   [Zur Startseite]              │
│                                 │
└─────────────────────────────────┘
```

### 8.4 Netzwerk-Fehler

```
┌─────────────────────────────────┐
│                                 │
│         🌐                      │
│                                 │
│   Keine Verbindung              │
│                                 │
│   Bitte stelle sicher, dass du  │
│   mit dem Internet verbunden    │
│   bist.                         │
│                                 │
│   [Erneut versuchen]            │
│                                 │
└─────────────────────────────────┘
```

### 8.5 Keine Aushilfen (Admin-View)

```
┌─────────────────────────────────┐
│ ← Termin: Konzert 2026-03-15    │
├─────────────────────────────────┤
│ Teilnehmer [Aushilfen] Setlist  │
├─────────────────────────────────┤
│                                 │
│         👤                      │
│                                 │
│   Noch keine Aushilfen          │
│                                 │
│   Füge Gastmusiker hinzu, die   │
│   temporär auf Noten zugreifen  │
│   sollen.                       │
│                                 │
│   [+ Aushilfe hinzufügen]       │
│                                 │
└─────────────────────────────────┘
```

---

## 9. Accessibility

### 9.1 Screen Reader

- **QR-Code:** Alt-Text „QR-Code für Aushilfen-Zugang von Max Mustermann"
- **Token-Link:** Readable Label „Zugangslink für Aushilfen"
- **Status-Badges:** „Aktiv bis 22. März 2026", nicht nur Farbe

### 9.2 Keyboard-Navigation

- **Tab-Order:** Name → Instrument → Stimme → Gültig bis → Notiz → Zugang erstellen
- **Enter/Space:** Öffnet Aktionen-Menü, kopiert Link
- **Escape:** Schließt Modal/Dialog

### 9.3 Kontrast

- **Farb-Badges:** Grün/Rot/Gelb erfüllen WCAG AA (4.5:1)
- **QR-Code:** Schwarz auf Weiß (höchster Kontrast)
- **Text auf Buttons:** Mindestens 4.5:1 Kontrast

### 9.4 Touch-Targets

- **Minimum:** 44×44px (alle interaktiven Elemente)
- **Play-Button:** 64×64px (groß für schnellen Tap)
- **QR-Code:** Mindestens 200×200px (gut scannbar)

---

## 10. Responsive Breakpoints

### 10.1 Phone (<600px)

- **Layout:** Single-Column
- **QR-Code:** 200×200px (inline), 512×512px (Fullscreen)
- **Setlist:** Volle Breite, Karten gestapelt
- **Modal:** Fullscreen (Bottom-Sheet-Style)

### 10.2 Tablet (600–1024px)

- **Layout:** Two-Column (Split-View bei Erstellung)
- **QR-Code:** 256×256px (Preview), 512×512px (Modal)
- **Setlist:** Grid (2 Spalten)
- **Modal:** Zentriert, 600px Breite

### 10.3 Desktop (>1024px)

- **Layout:** Three-Column (Sidebar + Content + Detail-Panel)
- **QR-Code:** 256×256px (inline), 1024×1024px (Download)
- **Setlist:** Grid (3 Spalten) oder Liste
- **Modal:** Zentriert, 800px Breite
- **Hover-States:** Tooltip auf QR (zeigt Link), Hover auf Stück-Karte (Preview)

---

## 11. Abhängigkeiten

### 11.1 Backend-APIs

- `POST /api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen` — Aushilfe erstellen
- `GET /api/v1/aushilfe/{token}` — Token validieren & Daten abrufen
- `GET /api/v1/aushilfe/{token}/stuecke/{stueckId}/pdf` — PDF für Stimme
- `PATCH /api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen/{aushilfeId}` — Gültigkeit verlängern
- `DELETE /api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen/{aushilfeId}` — Widerrufen
- `GET /api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen` — Liste aller Aushilfen

### 11.2 Frontend-Komponenten

- **QR-Code-Library:** `qr_flutter` (Dart) oder `qrcode.js` (JavaScript)
- **Share-API:** Native System-Share-Sheet (`navigator.share` / `Share.share`)
- **Service Worker:** PWA-Cache für Offline-Support
- **PDF-Renderer:** Bestehender Renderer aus `docs/ux-specs/spielmodus.md`

### 11.3 Bestehende UX-Specs

- `docs/ux-specs/auth-onboarding.md` — Auth-State-Machine (Aushilfen-Sonderfall)
- `docs/ux-specs/spielmodus.md` — Play-Modus (wiederverwendet für Aushilfen)
- `docs/ux-design.md` — Design-Tokens, Farben, Typografie

### 11.4 Feature-Specs

- `docs/feature-specs/aushilfen-spec.md` — Datenmodell, Token-Format, API-Kontrakte

---

**Ende der UX-Spec: Aushilfen-Zugang**
