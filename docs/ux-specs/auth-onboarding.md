# UX-Spec: Authentifizierung & Onboarding — Sheetstorm

> **Version:** 1.0
> **Status:** Entwurf — Review durch Hill (Frontend) ausstehend
> **Autorin:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Issue:** #9
> **Referenzen:** `docs/ux-design.md`, `docs/ux-konfiguration.md`, `docs/anforderungen.md`

---

## Inhaltsverzeichnis

1. [Überblick & Kontext](#1-überblick--kontext)
2. [Design-Tokens (Referenz)](#2-design-tokens-referenz)
3. [Login-Flow](#3-login-flow)
4. [Registrierungs-Flow](#4-registrierungs-flow)
5. [Onboarding-Wizard (5 Schritte)](#5-onboarding-wizard-5-schritte)
6. [Error States](#6-error-states)
7. [Interaction Patterns](#7-interaction-patterns)
8. [Accessibility](#8-accessibility)
9. [Abhängigkeiten & Nächste Schritte](#9-abhängigkeiten--nächste-schritte)

---

## 1. Überblick & Kontext

### 1.1 Ziel

Musiker sollen **in unter 3 Minuten** von der App-Installation bis zum Öffnen der ersten Note gelangen. Authentifizierung und Onboarding sind der erste Eindruck — sie dürfen nicht wie eine Hürde wirken.

### 1.2 Nutzungskontext

- **Erstzugang:** Neues Mitglied erhält einen Einladungslink von der Kapelle
- **Aushilfe:** Temporärer Zugang über `sheetstorm://aushilfe/[token]` — **kein Account nötig**
- **Kapellenwechsel:** Nutzer ist bereits registriert und tritt einer weiteren Kapelle bei
- **Geräte-Login:** Bestehender Account auf neuem Gerät

### 1.3 Zustands-Übersicht (Auth-State-Machine)

```
                ┌─────────────┐
                │   App-Start  │
                └──────┬──────┘
                       │
           ┌───────────┴────────────┐
           │                        │
    [Kein Token]              [Token vorhanden]
           │                        │
           ▼                        ▼
   ┌──────────────┐        ┌─────────────────┐
   │ Auth-Screen  │        │ Token valide?    │
   └──────┬───────┘        └────────┬────────┘
          │                    Ja ──┘   └── Nein
    ┌─────┴──────┐              │              │
    │            │              ▼              ▼
  Login    Registrierung    Bibliothek    Auth-Screen
    │            │
    └─────┬──────┘
          │
          ▼
    Onboarding-Wizard
    (nur wenn neu)
          │
          ▼
      Bibliothek
```

### 1.4 Aushilfen-Sonderfall

Wenn die App mit einem `sheetstorm://aushilfe/[token]`-Link geöffnet wird:

```
Deep Link erkannt → Token prüfen (API) → Direkt in Aushilfen-Ansicht
                                           (keine Registrierung, keine Onboarding-Schritte)
```

---

## 2. Design-Tokens (Referenz)

Alle hier verwendeten Token stammen aus `docs/ux-design.md` § 7.

| Token | Wert | Verwendung in Auth/Onboarding |
|-------|------|-------------------------------|
| `color-primary` | `#1A56DB` | CTA-Buttons, Links |
| `color-error` | `#DC2626` | Fehler-Messages, Validierung |
| `color-success` | `#16A34A` | Passwort-Stärke „Stark", Bestätigung |
| `color-warning` | `#D97706` | Passwort-Stärke „Mittel" |
| `color-text-secondary` | `#6B7280` | Helper-Text, Passwort-Hinweise |
| `color-border` | `#E5E7EB` | Input-Rahmen (Neutral) |
| `color-background` | `#FFFFFF` | Screen-Hintergrund |
| `font-size-base` | `16sp` | Input-Labels, Fehlertexte |
| `font-size-lg` | `20sp` | Screen-Titel |
| `font-size-xl` | `28sp` | Begrüßungs-Heading |
| `touch-target-min` | `44×44px` | Alle interaktiven Elemente |
| `border-radius-md` | `8px` | Input-Felder, Buttons |
| `space-md` | `16px` | Standard-Padding zwischen Elementen |
| `space-lg` | `24px` | Abschnitte |

---

## 3. Login-Flow

### 3.1 Login-Screen — Phone

```
┌─────────────────────────────┐
│                             │
│         🎵                  │
│      Sheetstorm             │ ← font-size-xl, font-weight-bold
│  Deine Noten. Überall.      │ ← color-text-secondary
│                             │
├─────────────────────────────┤
│                             │
│  E-Mail                     │ ← Label: 14sp, color-text-secondary
│  ┌─────────────────────┐    │
│  │ anna@beispiel.de    │    │ ← 16sp, Höhe 48px (Touch-Target)
│  └─────────────────────┘    │
│                             │
│  Passwort                   │
│  ┌─────────────────────┐    │
│  │ ••••••••••••     👁 │    │ ← Augen-Icon: Passwort anzeigen
│  └─────────────────────┘    │
│                             │
│  [Passwort vergessen?]      │ ← Rechts ausgerichtet, color-primary
│                             │
│  ┌─────────────────────┐    │
│  │     Anmelden        │    │ ← Primär-Button, 48px Höhe
│  └─────────────────────┘    │
│                             │
│  ─────── oder ───────       │
│                             │
│  ┌─────────────────────┐    │
│  │  🔍  Mit Google     │    │ ← Google-Brand-Button
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │    Mit Apple       │    │ ← Apple-Brand-Button (schwarz)
│  └─────────────────────┘    │
│                             │
│  Noch kein Account?         │
│  [Jetzt registrieren →]     │ ← color-primary, 44px Touch-Target
│                             │
└─────────────────────────────┘
```

### 3.2 Login-Screen — Tablet (600px+)

```
┌───────────────────────────────────────────────────┐
│                                                   │
│     ┌──────────────────────────────────┐          │
│     │                                  │          │
│     │         🎵  Sheetstorm           │          │
│     │   Deine Noten. Überall.          │          │
│     │                                  │          │
│     │  E-Mail                          │          │
│     │  ┌───────────────────────────┐   │          │
│     │  │ anna@beispiel.de          │   │          │
│     │  └───────────────────────────┘   │          │
│     │                                  │          │
│     │  Passwort                        │          │
│     │  ┌───────────────────────────┐   │          │
│     │  │ ••••••••••••          👁  │   │          │
│     │  └───────────────────────────┘   │          │
│     │                [Passwort verges.]│          │
│     │                                  │          │
│     │  ┌───────────────────────────┐   │          │
│     │  │         Anmelden          │   │          │
│     │  └───────────────────────────┘   │          │
│     │                                  │          │
│     │  ─────────── oder ─────────      │          │
│     │  ┌──────────┐  ┌──────────┐      │          │
│     │  │🔍 Google │  │  Apple  │      │          │
│     │  └──────────┘  └──────────┘      │          │
│     │                                  │          │
│     │  [Jetzt registrieren →]          │          │
│     └──────────────────────────────────┘          │
│            Card: max-width 480px, zentriert        │
└───────────────────────────────────────────────────┘
```

### 3.3 Social Login — Detail

**Google Sign-In:**
- Standard OAuth 2.0-Flow, Google-eigenes Popup/Sheet
- Nach Rückkehr: Prüfung ob E-Mail bereits registriert
  - Ja → Login abgeschlossen
  - Nein → Weiterleitung zu Onboarding (Account wird automatisch erstellt)

**Apple Sign-In:**
- Nur auf iOS/macOS nativ
- Auf Android/Web: Nicht angezeigt (kein Apple-Fake-Button!)
- After callback: gleiche Logik wie Google

**Plattformlogik:**
```
iOS/macOS  → Google-Button + Apple-Button anzeigen
Android    → Google-Button anzeigen, Apple NICHT
Web        → Google-Button + Apple-Button anzeigen
```

### 3.4 Passwort vergessen — Flow

```
SCHRITT 1: E-Mail eingeben
┌─────────────────────────────┐
│  ← Zurück  Passwort zurück. │
├─────────────────────────────┤
│                             │
│  Wir schicken dir einen     │
│  Link zum Zurücksetzen.     │
│                             │
│  E-Mail-Adresse             │
│  ┌─────────────────────┐    │
│  │ anna@beispiel.de    │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │    Link senden      │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘

SCHRITT 2: Bestätigung
┌─────────────────────────────┐
│  ← Zurück                   │
├─────────────────────────────┤
│                             │
│         ✅                  │
│                             │
│  E-Mail gesendet!           │
│                             │
│  Prüfe dein Postfach bei    │
│  anna@beispiel.de           │
│                             │
│  Der Link ist 30 Minuten    │
│  gültig.                    │
│                             │
│  [Erneut senden]            │ ← Disabled für 60 Sek., Countdown
│                             │
│  [Zurück zum Login]         │
│                             │
└─────────────────────────────┘

SCHRITT 3: Neues Passwort setzen (aus E-Mail-Link)
┌─────────────────────────────┐
│  Neues Passwort             │
├─────────────────────────────┤
│                             │
│  Neues Passwort             │
│  ┌─────────────────────┐    │
│  │                  👁 │    │
│  └─────────────────────┘    │
│  ████████░░░░  Stark  ✓     │ ← Passwort-Stärke-Anzeige
│                             │
│  Passwort wiederholen       │
│  ┌─────────────────────┐    │
│  │                  👁 │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  Passwort speichern │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

---

## 4. Registrierungs-Flow

### 4.1 Registrierungs-Flow — Übersicht

```
Login-Screen
    │
    [Jetzt registrieren →]
    │
    ▼
┌──────────────────────────────────────┐
│  Schritt 1: E-Mail + Passwort        │
│  Schritt 2: Name                     │
│  Schritt 3: Instrument(e)            │
│  Schritt 4: Kapelle beitreten/erstellen│
│  → Weiterleitung: Onboarding-Wizard  │
└──────────────────────────────────────┘
```

**Design-Entscheidung:** Registrierung ist in **4 Mini-Schritte** aufgeteilt (statt einem langen Formular). Jeder Schritt hat einen einzigen Fokuspunkt — Progressive Disclosure.

### 4.2 Registrierung Schritt 1 — E-Mail & Passwort — Phone

```
┌─────────────────────────────┐
│  ← Zurück        1 von 4    │ ← Fortschrittsanzeige
│  ●───────────────────────   │ ← Fortschritts-Balken 25%
├─────────────────────────────┤
│                             │
│  Konto erstellen            │ ← font-size-xl
│                             │
│  E-Mail-Adresse             │
│  ┌─────────────────────┐    │
│  │                     │    │
│  └─────────────────────┘    │
│  ✓  Gültige E-Mail-Adresse  │ ← Inline-Validierung
│                             │
│  Passwort                   │
│  ┌─────────────────────┐    │
│  │                  👁 │    │
│  └─────────────────────┘    │
│  Passwort-Stärke:           │
│  [░░░░░░░░░░░░░░]          │ ← Stärke-Balken (leer)
│                             │
│  Mindestens:                │
│  □ 8 Zeichen                │ ← Checkliste, wird grün wenn erfüllt
│  □ Großbuchstabe            │
│  □ Zahl oder Sonderzeichen  │
│                             │
│  ┌─────────────────────┐    │
│  │      Weiter →       │    │ ← Disabled bis Validierung ok
│  └─────────────────────┘    │
│                             │
│  ─────── oder ───────       │
│  [🔍 Mit Google]            │
│  [  Mit Apple  ]            │ ← Nur iOS/macOS
│                             │
└─────────────────────────────┘
```

### 4.3 Registrierung Schritt 2 — Name — Phone

```
┌─────────────────────────────┐
│  ← Zurück        2 von 4    │
│  ●●──────────────────────   │ ← 50%
├─────────────────────────────┤
│                             │
│  Wie heißt du?              │
│                             │
│  ┌─────────────────────┐    │
│  │ Anna                │    │ ← Autofokus, placeholder: „Dein Name"
│  └─────────────────────┘    │
│                             │
│  Dieser Name wird in        │
│  deiner Kapelle angezeigt.  │ ← color-text-secondary, 14sp
│                             │
│  ┌─────────────────────┐    │
│  │      Weiter →       │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

### 4.4 Registrierung Schritt 3 — Instrument(e) — Phone

```
┌─────────────────────────────┐
│  ← Zurück        3 von 4    │
│  ●●●─────────────────────   │ ← 75%
├─────────────────────────────┤
│                             │
│  Was spielst du?            │
│  (Mehrere möglich)          │ ← color-text-secondary
│                             │
│  🔍 [Instrument suchen…]   │
│  ─────────────────────────  │
│                             │
│  HOLZBLASINSTRUMENTE        │ ← Kategorie-Header
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 🎵  │ │ 🎵  │ │ 🎵  │   │
│  │Klar.│ │Flöte│ │Sax  │   │
│  └─────┘ └─────┘ └─────┘   │ ← Tap zum Auswählen (44px min)
│                             │
│  BLECHBLASINSTRUMENTE       │
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 🎺  │ │ 🎺  │ │ 🎺  │   │
│  │Tromp│ │Flüg.│ │Horn │   │
│  └─────┘ └─────┘ └─────┘   │
│                             │
│  AUSGEWÄHLT: Klarinette ✓  │ ← Selektion-Summary unten
│  Standard-Stimme:           │
│  [2. Klarinette         ▼] │ ← Dropdown, wenn Instrument gewählt
│                             │
│  ┌─────────────────────┐    │
│  │      Weiter →       │    │
│  └─────────────────────┘    │
│  [Überspringen]             │ ← 14sp, color-text-secondary
│                             │
└─────────────────────────────┘
```

### 4.5 Registrierung Schritt 4 — Kapelle — Phone

```
┌─────────────────────────────┐
│  ← Zurück        4 von 4    │
│  ●●●●─────────────────────  │ ← Fast fertig
├─────────────────────────────┤
│                             │
│  Bist du Teil einer         │
│  Kapelle?                   │
│                             │
│  ┌─────────────────────┐    │
│  │  📱  Kapelle beitr. │    │ ← Primäre Aktion
│  └─────────────────────┘    │
│  Einladungscode oder        │
│  QR-Code                    │
│                             │
│  ┌─────────────────────┐    │
│  │  ➕  Neue Kapelle   │    │ ← Sekundäre Aktion (outlined)
│  └─────────────────────┘    │
│  Du bist der Erste hier     │
│                             │
│  [Erst mal ohne Kapelle]    │ ← Text-Link, color-text-secondary
│                             │
└─────────────────────────────┘

--- Wenn "Kapelle beitreten" gewählt ---
┌─────────────────────────────┐
│  ← Zurück   Kapelle betreten│
├─────────────────────────────┤
│                             │
│  Einladungscode eingeben    │
│  ┌─────────────────────┐    │
│  │ MK-2024-XYZ         │    │ ← Auto-Uppercase, Code-Format
│  └─────────────────────┘    │
│                             │
│  ─────── oder ───────       │
│                             │
│  ┌─────────────────────┐    │
│  │  📷  QR-Code scannen│    │ ← Kamera-Zugriff
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │      Beitreten      │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘

--- Wenn "Neue Kapelle erstellen" gewählt ---
┌─────────────────────────────┐
│  ← Zurück   Kapelle anlegen │
├─────────────────────────────┤
│                             │
│  Name der Kapelle           │
│  ┌─────────────────────┐    │
│  │ Musikkapelle ...    │    │
│  └─────────────────────┘    │
│                             │
│  Region (optional)          │
│  ┌─────────────────────┐    │
│  │ Bayern, Deutschland │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │   Kapelle erstellen │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

### 4.6 Registrierung — Tablet (600px+)

Auf Tablet: Gleiche Schritte, aber alle in einer **zentrierten Card** (max-width: 480px), gleiche Logik wie Login-Tablet (§ 3.2).

---

## 5. Onboarding-Wizard (5 Schritte)

Der Onboarding-Wizard startet **direkt nach der Registrierung** (nicht nach Login bestehender Accounts). Er übernimmt die Daten aus der Registrierung (Name, Instrument, Kapelle) als Vorauswahl.

**Regeln:**
- Max. 5 Fragen (hier: Bestätigung/Verfeinerung bestehender Daten + neue Infos)
- Jeder Schritt ist überspringbar
- Keine Zahlungsinformationen
- Kein Blocker — App ist nach Schritt 5 sofort nutzbar
- Alle Daten können später in den Einstellungen geändert werden

### 5.1 Schritt 1/5 — Willkommen & Name bestätigen — Phone

```
┌─────────────────────────────┐
│                             │
│       🎵 Sheetstorm         │ ← Logo
│                             │
│  Herzlich willkommen,       │ ← font-size-xl
│  Anna! 👋                   │ ← Name aus Registrierung
│                             │
│  Nur 5 kurze Fragen —       │
│  dann geht's los.           │ ← color-text-secondary
│                             │
│  ●○○○○              1/5    │ ← Fortschritts-Dots
│                             │
│  Name bestätigen            │
│  ┌─────────────────────┐    │
│  │ Anna Mustermann     │    │ ← Vorausgefüllt aus Registrierung
│  └─────────────────────┘    │
│                             │
│       [Los geht's →]        │ ← Primär-CTA, 48px Höhe
│                             │
└─────────────────────────────┘
```

### 5.2 Schritt 2/5 — Instrument(e) bestätigen — Phone

```
┌─────────────────────────────┐
│  ●●○○○              2/5    │
├─────────────────────────────┤
│                             │
│  Dein Instrument            │
│  (Mehrere möglich)          │
│                             │
│  ┌─────────────────────┐    │
│  │ ✓ 🎵 Klarinette    │    │ ← Vorausgefüllt aus Registrierung
│  │   Stimme: 2. Klar.  │    │
│  └─────────────────────┘    │
│                             │
│  [+ Weiteres hinzufügen]    │ ← Optional
│                             │
│  Fallback-Logik             │
│  Wenn deine Stimme nicht    │
│  vorhanden ist:             │
│  [■ Nächste Stimme auto]   │ ← Toggle, default: An
│                             │
│  [← Zurück]  [Weiter →]    │
│  [Überspringen]             │
│                             │
└─────────────────────────────┘
```

### 5.3 Schritt 3/5 — Kapelle & Standardstimme — Phone

```
┌─────────────────────────────┐
│  ●●●○○              3/5    │
├─────────────────────────────┤
│                             │
│  Deine Kapelle              │
│                             │
│  ┌─────────────────────┐    │
│  │ ✓ Musikkapelle Bsp. │    │ ← Aus Registrierung, wenn beigetreten
│  │   312 Stücke        │    │
│  └─────────────────────┘    │
│                             │
│  Standard-Stimme bei        │
│  dieser Kapelle:            │
│  [2. Klarinette         ▼] │ ← Dropdown, filtert nach Instrument
│                             │
│  Beim Öffnen eines Stücks   │
│  wird diese Stimme auto-    │
│  matisch gewählt.           │ ← color-text-secondary, 14sp
│                             │
│  [← Zurück]  [Weiter →]    │
│  [Überspringen]             │
│                             │
└─────────────────────────────┘

--- Wenn noch keine Kapelle beigetreten ---
┌─────────────────────────────┐
│  ●●●○○              3/5    │
├─────────────────────────────┤
│                             │
│  Kapelle später             │
│  beitreten?                 │
│                             │
│  [Einladungscode eingeben]  │
│  [QR-Code scannen]          │
│                             │
│  [Erst mal alleine üben]    │ ← Text-Link
│                             │
│  [← Zurück]  [Weiter →]    │
│                             │
└─────────────────────────────┘
```

### 5.4 Schritt 4/5 — Theme wählen — Phone

```
┌─────────────────────────────┐
│  ●●●●○              4/5    │
├─────────────────────────────┤
│                             │
│  Wie soll Sheetstorm        │
│  aussehen?                  │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │  HELL    │ │  DUNKEL  │  │ ← Live-Preview im Thumbnail
│  │ ─────── │ │ ─────── │  │
│  │ ██ Text │ │ ░░ Text │  │
│  │ ─────── │ │ ─────── │  │
│  └──────────┘ └──────────┘  │
│                             │
│  ● Wie mein Gerät           │ ← Default: System-Einstellung
│  ○ Immer Hell               │
│  ○ Immer Dunkel             │
│                             │
│  Tipp: Im Spielmodus        │
│  kannst du jederzeit        │
│  wechseln. ⚙               │ ← color-text-secondary, 14sp
│                             │
│  [← Zurück]  [Weiter →]    │
│  [Überspringen]             │
│                             │
└─────────────────────────────┘
```

### 5.5 Schritt 5/5 — Fertig! — Phone

```
┌─────────────────────────────┐
│  ●●●●●              5/5    │
├─────────────────────────────┤
│                             │
│         ✅                  │ ← 64px Icon
│                             │
│  Alles bereit, Anna!        │ ← font-size-xl, font-weight-bold
│                             │
│  ┌─────────────────────┐    │
│  │ 🏛 Musikkapelle Bsp.│    │ ← Kapelle, der du beigetreten bist
│  │ 312 Stücke warten   │    │
│  │ auf dich            │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  Zur Bibliothek →   │    │ ← Primär-CTA
│  └─────────────────────┘    │
│                             │
│  [Aktuelle Setlist           │
│   ansehen →]                │ ← Sekundäre Aktion (wenn vorhanden)
│                             │
└─────────────────────────────┘
```

### 5.6 Onboarding-Wizard — Tablet (600px+)

Auf Tablet: Zentrierte Card, max-width 560px. Instrument-Auswahl (Schritt 2) nutzt ein **2-Spalten-Grid** statt vertikaler Liste.

```
┌───────────────────────────────────────────────────┐
│                                                   │
│     ┌──────────────────────────────────────┐      │
│     │  ●●●○○                       3/5    │      │
│     │                                      │      │
│     │  Dein Instrument                     │      │
│     │                                      │      │
│     │  ┌─────────┐  ┌─────────┐           │      │
│     │  │✓🎵 Klar.│  │  🎵Sax │           │      │
│     │  └─────────┘  └─────────┘           │      │
│     │  ┌─────────┐  ┌─────────┐           │      │
│     │  │ 🎺Tromp.│  │ 🎺Flüg.│           │      │
│     │  └─────────┘  └─────────┘           │      │
│     │                                      │      │
│     │  [← Zurück]         [Weiter →]      │      │
│     └──────────────────────────────────────┘      │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## 6. Error States

### 6.1 Falsches Passwort

```
┌─────────────────────────────┐
│  E-Mail                     │
│  ┌─────────────────────┐    │
│  │ anna@beispiel.de    │    │
│  └─────────────────────┘    │
│                             │
│  Passwort                   │
│  ┌─────────────────────┐    │
│  │ ••••••••••••     👁 │    │ ← Roter Rahmen: color-error
│  └─────────────────────┘    │
│  ✗ Falsches Passwort.       │ ← color-error, 14sp
│    [Passwort vergessen?]    │ ← Direkt darunter, Schnellzugriff
│                             │
│  ┌─────────────────────┐    │
│  │      Anmelden       │    │ ← Button bleibt aktiv
│  └─────────────────────┘    │
└─────────────────────────────┘

Nach 5 Fehlversuchen:
┌─────────────────────────────┐
│  ⚠️ Zu viele Versuche       │ ← Warn-Banner, color-warning-bg
│  Bitte warte 5 Minuten      │
│  oder setze dein Passwort   │
│  zurück.                    │
│  [Passwort zurücksetzen →] │
└─────────────────────────────┘
```

### 6.2 E-Mail existiert bereits (Registrierung)

```
│  E-Mail-Adresse             │
│  ┌─────────────────────┐    │
│  │ anna@beispiel.de    │    │ ← Roter Rahmen
│  └─────────────────────┘    │
│  ✗ Diese E-Mail ist         │ ← color-error, 14sp
│    bereits registriert.     │
│    [Anmelden →]             │ ← Inline-Link zum Login
```

### 6.3 Ungültiger Einladungscode (Kapelle beitreten)

```
│  ┌─────────────────────┐    │
│  │ MK-2024-XYZ         │    │ ← Roter Rahmen
│  └─────────────────────┘    │
│  ✗ Ungültiger Code.         │
│    Prüfe die Groß-/Klein-   │
│    schreibung.              │ ← Hilfreich, nicht schuldzuweisend
│                             │
│  Noch kein Code?            │
│  [Kapelle später beitreten] │ ← Flucht-Pfad ohne Blocker
```

### 6.4 Netzwerkfehler

```
─── Offline-Banner (oben, persistent) ────
┌─────────────────────────────────────────┐
│  📡 Keine Verbindung — Bitte WLAN oder  │
│     Mobilfunk prüfen.       [Erneut]   │
└─────────────────────────────────────────┘
─── Button-State bei Netzwerkfehler ──────
│  ┌─────────────────────┐    │
│  │   ↻ Anmelden...     │    │ ← Spinner, Button disabled
│  └─────────────────────┘    │
│  ✗ Verbindungsfehler.       │
│    Bitte versuche es        │
│    später erneut.           │
│  [Erneut versuchen]         │
```

### 6.5 Ungültige E-Mail-Adresse (Inline-Validierung)

```
│  E-Mail-Adresse             │
│  ┌─────────────────────┐    │
│  │ anna@              │    │ ← Roter Rahmen, sofort beim Tippen
│  └─────────────────────┘    │
│  ✗ Bitte gib eine gültige   │
│    E-Mail-Adresse ein.      │ ← color-error, erscheint nach
│                             │    Verlassen des Feldes (on blur)
```

### 6.6 Passwort zu schwach

```
│  Passwort                   │
│  ┌─────────────────────┐    │
│  │ pass             👁 │    │
│  └─────────────────────┘    │
│  Passwort-Stärke:           │
│  [████░░░░░░░░░░]  Schwach  │ ← Rot, color-error
│                             │
│  ✓ 8 Zeichen                │ ← Grün
│  ✗ Großbuchstabe            │ ← Rot
│  ✗ Zahl oder Sonderzeichen  │ ← Rot
```

### 6.7 Account gesperrt (Admin-Aktion)

```
┌─────────────────────────────┐
│         ⛔                  │
│  Dein Account wurde         │
│  gesperrt.                  │
│                             │
│  Bitte wende dich an deinen │
│  Kapellen-Administrator.    │
│                             │
│  [Administrator kontaktieren│
│   →]                        │ ← mailto: des Admins, wenn bekannt
│                             │
└─────────────────────────────┘
```

---

## 7. Interaction Patterns

### 7.1 Inline-Validierung — Regeln

| Feld | Wann validieren | Regel |
|------|----------------|-------|
| E-Mail | `onBlur` (nach Verlassen) | Regex-Prüfung, dann Server-Prüfung |
| Passwort (neu) | `onChange` (live) | Stärke-Anzeige live, Anforderungen live |
| Passwort-Wiederholung | `onBlur` | Match-Prüfung |
| Name | `onBlur` | Minimum 2 Zeichen |
| Einladungscode | `onChange` | Format-Normalisierung (uppercase, Bindestrich) |

**Timing-Regel:** Fehler werden erst nach `onBlur` gezeigt (nicht beim ersten Zeichen). Ausnahme: Passwort-Stärke ist live, weil sie positiv motiviert, nicht schuldzuweisend.

### 7.2 Passwort-Stärke-Anzeige

```
Bewertung:
  Sehr schwach → 1 Block rot    → Text: „Sehr schwach"
  Schwach      → 2 Blöcke rot   → Text: „Schwach"
  Mittel       → 3 Blöcke gelb  → Text: „Mittel"
  Stark        → 4 Blöcke grün  → Text: „Stark" + ✓
  
Farben:
  Rot    = color-error   (#DC2626)
  Gelb   = color-warning (#D97706)
  Grün   = color-success (#16A34A)

Implementierungshinweis für Hill:
  zxcvbn (https://github.com/dropbox/zxcvbn) liefert
  Score 0–4 für realistische Stärke-Bewertung.
  Flutter-Package: zxcvbn_dart oder äquivalent.
```

### 7.3 Button-Zustände

| Zustand | Visual | Interaktion |
|---------|--------|-------------|
| Standard | Primärfarbe, white text | Tippbar |
| Hover (Web/Desktop) | Primär-Dark | Tippbar |
| Disabled | `color-border` BG, `color-text-secondary` text | Nicht tippbar |
| Loading | Spinner-Icon + Text grau | Nicht tippbar |
| Error | Kurzes Shake-Animation (200ms) | Tippbar |

**Shake-Animation:**
```
Keyframes:
  0%   translateX(0)
  20%  translateX(-8px)
  40%  translateX(8px)
  60%  translateX(-4px)
  80%  translateX(4px)
  100% translateX(0)
  Dauer: 300ms, einmalig
```

### 7.4 Fortschritts-Dots (Onboarding)

```
Nicht aktiv: ○  (Farbe: color-border, 8px)
Aktiv:       ●  (Farbe: color-primary, 10px)
Abgeschlossen: ● (Farbe: color-success, 8px)

Tap auf abgeschlossene Dots: Navigation zurück zu diesem Schritt
```

### 7.5 Passwort-Sichtbarkeit (👁-Icon)

- Toggle zwischen `••••••` und Klartext
- Icon wechselt: `👁` (sichtbar) ↔ `👁‍🗨` (verborgen)
- Touch-Target: 44×44px (Icon + umliegender Bereich)
- Zustand wird nicht gespeichert (bei jedem Öffnen: versteckt)

### 7.6 Keyboard-Handling

| Kontext | Keyboard-Typ |
|---------|-------------|
| E-Mail-Feld | `emailAddress` |
| Passwort-Feld | `visiblePassword` |
| Name-Feld | `name` / `text` |
| Einladungscode | `text`, Auto-Uppercase |
| Suche Instrument | `text` |

**Return-Key-Verhalten:** In Form-Flows springt „Return" zum nächsten Feld. Im letzten Feld: führt `onSubmit` aus (Formular absenden).

---

## 8. Accessibility

### 8.1 Touch-Targets

Alle interaktiven Elemente respektieren die Token aus `docs/ux-design.md`:

| Element | Minimum | Ist |
|---------|---------|-----|
| Alle Buttons | `touch-target-min` (44px) | 48px Höhe |
| Passwort-👁 | `touch-target-min` (44px) | 44×44px |
| Fortschritts-Dots | `touch-target-min` (44px) | 44×44px tap area |
| Inline-Links | `touch-target-min` (44px) | Padding erhöht tap area |
| Checkbox/Toggle | `touch-target-min` (44px) | 44×44px |
| Instrument-Kacheln | `touch-target-min` (44px) | 80px min |
| Social-Login-Buttons | `touch-target-min` (44px) | 48px Höhe |

### 8.2 Lesbarkeit bei schlechtem Licht

**Kontrastanforderungen (WCAG 2.1 AA+):**

| Element | Kontrast-Minimum | Sollwert |
|---------|-----------------|---------|
| Normaler Text | 4.5:1 | ≥ 7:1 |
| Große Texte (18sp+) | 3:1 | ≥ 4.5:1 |
| Fehler-Rot auf weiß | 4.5:1 | `#DC2626` erreicht 4.7:1 ✓ |
| Primär-Blau auf weiß | 4.5:1 | `#1A56DB` erreicht 5.1:1 ✓ |
| Placeholder-Text | 4.5:1 | Mindestens `#767676` |

**Nachtmodus (Dark Theme):**
- Alle Error-States bleiben auf dunklem Hintergrund lesbar
- Fehler-Rot auf Dark: `#F87171` (Helleres Rot für Dark Mode, WCAG AA)
- Input-Rahmen: Sichtbarer Contrast auf `#111827` Background

### 8.3 Screen-Reader-Unterstützung

| Element | Semantic Label |
|---------|---------------|
| Passwort-👁 | „Passwort anzeigen" / „Passwort verbergen" |
| Fortschritts-Dots | „Schritt 2 von 5" |
| Error-Message | `role="alert"` — wird sofort vorgelesen |
| Social-Login-Buttons | „Mit Google anmelden" / „Mit Apple anmelden" |
| Passwort-Stärke | Live-Region: „Passwort-Stärke: Mittel" |
| Instrument-Kachel | „Klarinette, ausgewählt" / „Klarinette, nicht ausgewählt" |

### 8.4 Fokus-Management

- **Tab-Reihenfolge:** E-Mail → Passwort → Passwort-anzeigen → Formular-Absenden → Links (Passwort vergessen, Registrieren)
- **Nach Submit-Fehler:** Fokus springt auf erstes Fehlerfeld
- **Nach Screen-Wechsel (Onboarding-Schritt):** Fokus auf Heading des neuen Schritts
- **Modal/Sheet:** Fokus bleibt im Modal (Focus-Trap)

### 8.5 Reduzierte Bewegung

```
@media (prefers-reduced-motion: reduce):
  Shake-Animation → Statisches Rot-Highlighting statt Shake
  Fortschritts-Dots → Kein Pulse-Effekt
  Screen-Übergänge → Instant statt Slide
```

---

## 9. Abhängigkeiten & Nächste Schritte

### 9.1 Was Hill (Frontend) braucht

**Implementierungs-Specs:**

| Thema | Detail | Priorität |
|-------|--------|-----------|
| Passwort-Stärke | `zxcvbn` oder äquivalentes Package für Flutter | P0 |
| Social Login | Firebase Auth oder Supabase Auth für Google/Apple OAuth | P0 |
| Deep Link Handling | `sheetstorm://aushilfe/[token]` muss vor Auth-Screen abgefangen werden | P0 |
| Form-Validierung | Inline-Validierung nach `onBlur`, Passwort live | P0 |
| QR-Code-Scanner | Camera-Permission-Flow für Einladungscode | P1 |
| Keyboard-Dismissal | Tap außerhalb Keyboard dismisst — verhindert versteckte Buttons | P0 |
| Safe-Area | iOS Notch/Home-Indicator: Content nicht überlappen | P0 |
| Rate-Limiting UI | Nach 5 Fehlversuchen: Countdown-Timer anzeigen | P1 |

**Design-Assets die ich noch liefere:**
- [ ] Finale Farbwerte im Dark-Mode für alle Error/Success-States
- [ ] Logo-Asset in SVG (für Hill zum Einbinden)
- [ ] Instrument-Icon-Set (für Onboarding-Kacheln)

### 9.2 Was Banner (Backend) braucht

| API-Endpoint | Zweck |
|-------------|-------|
| `POST /auth/register` | Registrierung mit E-Mail/Passwort |
| `POST /auth/login` | Login mit E-Mail/Passwort |
| `POST /auth/oauth/google` | Google OAuth Callback |
| `POST /auth/oauth/apple` | Apple OAuth Callback |
| `POST /auth/password-reset` | Passwort-Reset-Link senden |
| `POST /auth/password-reset/confirm` | Neues Passwort setzen (Token aus E-Mail) |
| `GET /kapelle/invite/[code]` | Einladungscode validieren |
| `POST /kapelle/join` | Kapelle beitreten |
| `POST /kapelle/create` | Neue Kapelle anlegen |
| `GET /aushilfe/[token]` | Aushilfen-Token validieren |

**Rate-Limiting:** Login-Endpunkt sollte nach 5 Fehlversuchen pro IP/Account eine 429-Response mit `Retry-After` Header liefern.

### 9.3 Offene Fragen (für Thomas / Team)

1. **E-Mail-Bestätigung:** Sollen neue Accounts eine Bestätigungs-E-Mail bekommen? → Wenn ja, brauchen wir einen „Bitte bestätige deine E-Mail"-State im Flow.
2. **Magic-Link Login:** Zusätzlich zu Passwort: Einmaligen Login-Link per E-Mail schicken? (Weniger Reibung, besonders für Musiker die selten einloggen)
3. **Kapellen-Suche:** Soll es auf Schritt 4 (Kapelle beitreten) eine öffentliche Suche nach Kapellenname geben, oder nur per Code?
4. **Sprache im Onboarding:** Instrument-Namen auf Deutsch oder Englisch? (Entscheidung in `decisions.md`: Deutsch-first → Deutsch)

### 9.4 Meilenstein-Zuordnung

Diese Spec gehört zu **M1 — Kern: Noten & Kapelle**. Die Auth-UX ist Voraussetzung für alle anderen Features des ersten Meilensteins.

**Blockiert von dieser Spec:**
- Hill kann Auth-Screens implementieren
- Banner kann Auth-API nach dieser Spec designen
- Parker kann Auth-Flow-Tests schreiben (Happy Path + Error States sind hier definiert)

---

*Erstellt von Wanda (UX Designer) — Issue #9*
*Design-Tokens referenzieren `docs/ux-design.md` § 7*
*Onboarding-Wizard basiert auf `docs/ux-konfiguration.md` § 7*
