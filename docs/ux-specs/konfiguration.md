# UX-Spec: Konfigurationssystem (3 Ebenen) — Sheetstorm

> **Issue:** #32 — [UX] Konfigurationssystem (3 Ebenen) — UX-Flows und Wireframes  
> **Version:** 1.0 (konsolidiert aus `docs/ux-konfiguration.md`)  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M1 — Kern: Noten & Kapelle  
> **Referenzen:** `docs/ux-konfiguration.md`, `docs/konfigurationskonzept.md`, `docs/decisions.md`

---

## Inhaltsverzeichnis

1. [Konzept: 3-Ebenen-Konfiguration](#1-konzept-3-ebenen-konfiguration)
2. [Navigation & Discovery](#2-navigation--discovery)
3. [User Flows — alle Ebenen](#3-user-flows--alle-ebenen)
4. [Ebene 1: Kapelle-Einstellungen (Admin)](#4-ebene-1-kapelle-einstellungen-admin)
5. [Ebene 2: Nutzer-Einstellungen](#5-ebene-2-nutzer-einstellungen)
6. [Ebene 3: Gerät-Einstellungen](#6-ebene-3-gerät-einstellungen)
7. [Interaction Patterns](#7-interaction-patterns)
8. [Onboarding-Integration](#8-onboarding-integration)
9. [Spielmodus — Kontextuelle Einstellungen](#9-spielmodus--kontextuelle-einstellungen)
10. [Edge Cases](#10-edge-cases)
11. [Wireframes: Phone](#11-wireframes-phone)
12. [Wireframes: Tablet/Desktop](#12-wireframes-tabletdesktop)
13. [Abhängigkeiten](#13-abhängigkeiten)

---

## 1. Konzept: 3-Ebenen-Konfiguration

### 1.1 Ebenenmodell

```
╔════════════════════════════════════════════════════════╗
║  EBENE 1: KAPELLE (Blau #1A56DB)                      ║
║  Gilt für alle Mitglieder dieser Kapelle              ║
║  Wer: Admins + Dirigenten können konfigurieren        ║
║  → Wer darf Noten hochladen?                          ║
║  → Welcher AI-Key wird genutzt?                       ║
║  → Policies: Erzwungene Einstellungen für Konzerte    ║
╠════════════════════════════════════════════════════════╣
║  EBENE 2: NUTZER/PERSÖNLICH (Grün #16A34A)            ║
║  Gilt nur für diesen Account (alle Geräte)            ║
║  Wer: Jeder Musiker konfiguriert sich selbst          ║
║  → Welches Instrument spiele ich?                     ║
║  → Helles oder dunkles Theme?                         ║
║  → Bevorzugte Stimme pro Kapelle                      ║
╠════════════════════════════════════════════════════════╣
║  EBENE 3: GERÄT (Orange #D97706)                      ║
║  Gilt nur auf diesem Gerät — NICHT synchronisiert     ║
║  Wer: Jeder Nutzer pro Gerät                          ║
║  → Schriftgröße im Spielmodus                         ║
║  → Touch-Zone-Empfindlichkeit                         ║
║  → Fußpedal-Belegung                                  ║
╚════════════════════════════════════════════════════════╝
```

### 1.2 Vererbungsregel

```
DEFAULT → Kapelle → Nutzer → Gerät
         (Policy)  (über-    (überschreibt
                   schreibt   Nutzer &
                   Kapelle)   Kapelle)

AUSNAHME: Policy-Lock
  Kapelle setzt 🔒 → Nutzer und Gerät können nicht überschreiben
```

### 1.3 Farbsystem & Icons

| Ebene | Farbe | Hex | Icon | Einsatz |
|-------|-------|-----|------|---------|
| Kapelle | Blau | `#1A56DB` | 🏛 | Linker Rand, Badge, Label |
| Nutzer | Grün | `#16A34A` | 👤 | Linker Rand, Badge, Label |
| Gerät | Orange | `#D97706` | 📱 | Linker Rand, Badge, Label |

**Barrierefreiheit:** Farbe ist NIE das einzige Unterscheidungsmerkmal. Jede Ebene hat ein eigenes Icon und einen textuellen Label.

### 1.4 Vererbungsanzeige im UI

Wenn eine Einstellung von einer übergeordneten Ebene kommt:

```
STANDARD VON KAPELLE (überschreibbar):
┌─────────────────────────────────────────────────────┐
│  Dark Mode                                          │
│  🏛 Standard von Kapelle: An                       │  ← Blauer Hinweis
│  [Eigenen Wert festlegen]                           │
└─────────────────────────────────────────────────────┘

ERZWUNGEN VON KAPELLE (Policy-Lock):
┌─────────────────────────────────────────────────────┐
│  🏛 🔒 Nachtmodus bei Konzerten                    │
│  Von Kapelle vorgegeben. Kann nicht geändert werden.│
│  Frage deinen Administrator.                        │
└─────────────────────────────────────────────────────┘
```

---

## 2. Navigation & Discovery

### 2.1 Zugangspunkte (bewusst redundant)

Verschiedene Nutzer haben verschiedene mentale Modelle — alle Wege führen zu den Einstellungen:

| Zugangspunkt | Pfad | Zielgruppe |
|-------------|------|-----------|
| **Profil-Tab → Einstellungen** | Bottom-Nav → 👤 → ⚙️ | Alle Nutzer |
| **Kapellen-Tab → Verwaltung** | Bottom-Nav → 👤 → Kapelle → Einstellungen | Admins |
| **Spielmodus → ⚙️** | Overlay → ⚙️-Icon | Alle während des Spielens |
| **Einstellungs-Suche** | Überall via 🔍 in Einstellungen | Technikaffine Nutzer |

### 2.2 Einstellungs-Hierarchie (vollständig)

```
Einstellungen
├── 🏛 KAPELLE (nur Admins sichtbar)
│   ├── Allgemein
│   │   ├── Kapellenname, Profilbild, Beschreibung
│   │   ├── Sprache des Archivs
│   │   └── Zeitzone
│   ├── Mitglieder & Rollen
│   │   ├── Upload-Berechtigung (welche Rollen dürfen hochladen)
│   │   ├── Aushilfen-Zugang (erlauben, Gültigkeit)
│   │   └── Rollen-Management-Link → Kapellenverwaltung
│   ├── AI & Import
│   │   ├── AI-Provider (Azure AI Vision etc.)
│   │   ├── API-Key (verschlüsselt)
│   │   ├── Quota-Anzeige
│   │   ├── Fallback-Verhalten (wenn kein Key)
│   │   └── Standard-Sprache für OCR
│   └── Policies
│       ├── Nachtmodus bei Konzert erzwingen
│       ├── Mindest-Schriftgröße festlegen
│       └── Annotationen nur auf eigener Ebene
│
├── 👤 NUTZER / PERSÖNLICH
│   ├── Profil & Konto
│   │   ├── Name, Profilbild, E-Mail
│   │   ├── Passwort ändern
│   │   ├── Zwei-Faktor-Authentifizierung
│   │   └── Konto löschen
│   ├── Instrumente & Stimmen
│   │   ├── Meine Instrumente (Haupt + weitere)
│   │   ├── Standardstimme pro Kapelle
│   │   └── Fallback-Verhalten
│   ├── Darstellung
│   │   ├── Theme (Hell / Dunkel / System)
│   │   └── Sprache der App
│   ├── AI (persönlich)
│   │   ├── Eigener AI-API-Key
│   │   └── Fallback-Verhalten (wenn kein Kapellen-Key)
│   └── Benachrichtigungen
│       ├── Probe-Erinnerungen
│       ├── Neue Noten verfügbar
│       └── Einladungen & Nachrichten
│
└── 📱 GERÄT
    ├── Anzeige
    │   ├── Schriftgröße im Spielmodus (Slider)
    │   ├── Helligkeit im Spielmodus (Slider)
    │   ├── Bildschirm-Timeout deaktivieren (im Spielmodus)
    │   ├── Auto-Rotation sperren (im Spielmodus)
    │   └── Noten-Hintergrundfarbe (Weiß / Sepia / Schwarz)
    ├── Touch & Gesten
    │   ├── Tap-Zonen-Aufteilung (Slider %, Standard 40/60)
    │   ├── Wisch-Empfindlichkeit (Niedrig / Mittel / Hoch)
    │   └── Stift-Erkennung (Annotation mit Stift / Finger)
    ├── Audio
    │   ├── Tuner-Referenzton Hz (Standard 440 Hz)
    │   └── Metronom-Lautstärke (Slider)
    ├── Fußpedal
    │   ├── Verbundenes Gerät (BLE/MIDI)
    │   └── Tastenbelegung (Rechts / Links / Mitte)
    └── Speicher & Cache
        ├── Cache-Größe und Verbrauch
        ├── Cache leeren (destructive, Bestätigung)
        └── Auto-Vorab-Laden (Setlists, nur WLAN)
```

### 2.3 Einstellungs-Suche

```
┌──────────────────────────────────────────┐
│  🔍 Einstellungen suchen…                │
├──────────────────────────────────────────┤
│  „helligkeit"                            │
│  ────────────────────────────────        │
│  📱 Helligkeit im Spielmodus            │  ← Gerät-Einstellung
│     Gerät → Anzeige                     │  ← Breadcrumb
│                                          │
│  📱 Auto-Helligkeit                     │
│     Gerät → Anzeige                     │
└──────────────────────────────────────────┘
```

**Suchergebnis-Format:** Einstellungsname + Ebenen-Icon + Pfad (Breadcrumb) + 1-Tap Navigation

---

## 3. User Flows — alle Ebenen

### 3.1 Flow: Admin richtet Kapelle ein (Ersteinrichtung)

```
Admin registriert sich → Onboarding-Wizard
        │
        ▼
Kapelle erstellen (Schritt 4 im Onboarding)
        │
        ▼
Kapellen-Dashboard
        │
        ▼ (Handlungsbedarf-Widget zeigt Aufgaben)
  ┌─────────────────────────────────────────┐
  │  HANDLUNGSBEDARF                        │
  │  ⚠️ Noch keine Noten — Importieren      │
  │  ⚠️ Noch keine Mitglieder — Einladen   │
  │  ⚠️ AI-Key konfigurieren (optional)    │
  └─────────────────────────────────────────┘
        │
        ▼
Admin → Einstellungen → Kapelle → AI & Import
→ API-Key hinterlegen → Toast „Gespeichert"

Admin → Einstellungen → Kapelle → Mitglieder & Rollen
→ Upload-Berechtigung konfigurieren
```

### 3.2 Flow: Musiker richtet Profil ein

```
Nach Onboarding-Wizard oder beim ersten Login:
        │
        ▼
Einstellungen → 👤 Nutzer → Instrumente & Stimmen
        │
        ▼
[+ Instrument hinzufügen] → Instrument-Picker
→ Standardstimme pro Kapelle festlegen
→ Auto-Save → Toast

        │
        ▼
Einstellungen → 👤 Nutzer → Darstellung
→ Theme wählen → Sofort-Preview
→ Auto-Save (kein Button)
```

### 3.3 Flow: Nutzer ändert Gerät-Einstellung

```
Einstellungen → 📱 Gerät → Anzeige
        │
        ▼
Schriftgröße-Slider bewegen
        │
        ▼
Änderung sofort angewendet (Live-Preview)
        │
        ▼
Auto-Save (kein Button)
        │
        ▼
Undo-Toast erscheint für 5 Sekunden:
┌────────────────────────────────────────┐
│  Schriftgröße geändert    [Rückgängig] │
└────────────────────────────────────────┘
```

### 3.4 Flow: Admin setzt Policy

```
Einstellungen → 🏛 Kapelle → Policies
        │
        ▼
Policy aktivieren (z.B. „Nachtmodus bei Konzert")
        │
        ▼
Bestätigungs-Dialog:
┌─────────────────────────────────────────┐
│  Policy aktivieren?                     │
│                                         │
│  „Nachtmodus bei Konzert erzwingen"     │
│  wird für alle 43 Mitglieder aktiviert. │
│  Mitglieder können diese Einstellung    │
│  dann nicht mehr ändern.               │
│                                         │
│  [Abbrechen]       [Aktivieren]        │
└─────────────────────────────────────────┘
        │ Bestätigen
        ▼
Policy gespeichert
→ Toast: „Policy aktiviert für 43 Mitglieder"
→ Mitglieder sehen Schloss-Icon in ihren Einstellungen
```

---

## 4. Ebene 1: Kapelle-Einstellungen (Admin)

### 4.1 Admin-Dashboard — Handlungsbedarf

Das Kapellen-Dashboard zeigt offene Aufgaben prominent:

```
┌──────────────────────────────────────────────────────────────┐
│  HANDLUNGSBEDARF                          Alles in Ordnung ✓ │
│  ─────────────────────────────────────────────────────────   │
│  ⚠️  3 Mitglieder ohne Instrumente             [Ansehen →]  │
│  ⚠️  AI-Key läuft in 12 Tagen ab               [Erneuern →] │
│  ℹ️  2 Stücke ohne Stimmen-Zuordnung           [Zuordnen →] │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 Allgemein-Tab

| Feld | UI-Element | Typ |
|------|-----------|-----|
| Kapellenname | Textfeld | Auto-Save |
| Profilbild | Bild-Picker | Bestätigung |
| Beschreibung | Textarea | Auto-Save |
| Zeitzone | Dropdown | Auto-Save |
| Sprache des Archivs | Dropdown | Auto-Save |

### 4.3 Mitglieder & Rollen-Tab

```
UPLOAD-BERECHTIGUNG
  Wer darf Noten zur Kapelle hinzufügen?
  ☑ Administrator
  ☑ Dirigent
  ☑ Notenwart
  ☐ Registerführer
  ☐ Musiker

AUSHILFEN-EINSTELLUNGEN
  Aushilfen-Links erlauben:  [■ An]
  Standard-Gültigkeit:       [7 Tage     ▼]
  Zugriff:                   [Nur zugewiesene Stimme ▼]
```

### 4.4 AI & Import-Tab

```
KAPELLEN-AI-KEY
  Provider:  [Azure AI Vision         ▼]
  API-Key:   [●●●●●●●●●●●●●     👁 Anzeigen]
  Status:    🟢 Aktiv · Quota: 8.420/10.000
  Ablauf:    15. April 2026 ⚠️          [Erneuern]

FALLBACK-VERHALTEN
  Wenn kein Key verfügbar:
  ○ Nur manueller Import (kein AI)
  ● Nutzer darf eigenen Key hinterlegen

IMPORT-STANDARDS
  Standard-Sprache für OCR: [Deutsch ▼]
  Auto-Metadaten-Erkennung: [■ An]
```

### 4.5 Policies-Tab

```
⚠️ Policies mit Bedacht verwenden — sie schränken alle Mitglieder ein

[ ] Nachtmodus bei Konzert erzwingen
    Alle Geräte wechseln in den Nachtmodus wenn eine Konzert-Setlist
    geöffnet wird.

[ ] Mindest-Schriftgröße
    Nutzer können nicht kleiner als [——] einstellen.
    Wert: [Mittel ▼]

[ ] Annotationen nur auf eigener Ebene
    Musiker dürfen nur auf der Privat-Ebene annotieren.
    (Stimme- und Orchester-Ebene ist schreibgeschützt)
```

---

## 5. Ebene 2: Nutzer-Einstellungen

### 5.1 Profil & Konto

| Feld | UI | Typ |
|------|-----|-----|
| Name | Textfeld | Auto-Save |
| Profilbild | Bild-Picker | — |
| E-Mail | Textfeld (mit Verifikation) | Bestätigung per E-Mail |
| Passwort ändern | → eigener Flow | Aktuelles PW nötig |
| 2FA | Toggle + Setup-Flow | — |
| Konto löschen | Roter Button | Bestätigung + PW |

### 5.2 Instrumente & Stimmen

→ Siehe `docs/ux-specs/stimmenauswahl.md` für vollständige Spec.

Kurzfassung:
- Hauptinstrument + Nebeninstrumente anlegen
- Standardstimme pro Kapelle festlegen
- Fallback-Logik konfigurieren

### 5.3 Darstellung

```
THEME
  [Hell]   [Dunkel]   [● Wie Gerät]   ← Standard: System
  
  Änderung wirkt sofort — gesamte UI aktualisiert
  Keine Bestätigung nötig

SPRACHE DER APP
  [Deutsch ▼]
  (Änderung wirkt sofort — kein Neustart)
```

### 5.4 AI (persönlich)

```
PERSÖNLICHER AI-KEY
  Eigener Key überschreibt Kapellen-Key

  Provider:  [Azure AI Vision ▼]
  API-Key:   [nicht konfiguriert        ]
  
  Status: Kapellen-Key wird genutzt
  
  [Eigenen Key hinterlegen]

FALLBACK-REIHENFOLGE
  1. Eigener Key (wenn konfiguriert)
  2. Kapellen-Key (wenn vorhanden)
  3. Manueller Import (kein AI)
```

### 5.5 Benachrichtigungen

```
PROBEN & TERMINE
  Probe-Erinnerungen: [■ An] — [2 Stunden vorher ▼]
  Termin-Einladungen: [■ An]

NOTEN
  Neue Noten für meine Stimme: [■ An]
  Stimmen-Annotationen (Orchester): [■ An]

VERWALTUNG
  Einladungen:  [■ An]
  Nachrichten:  [■ An]
  Updates:      [□ Aus]
```

---

## 6. Ebene 3: Gerät-Einstellungen

**Kernregel:** Gerät-Einstellungen werden **niemals** synchronisiert. Jedes Gerät hat seine eigene Konfiguration.

### 6.1 Anzeige

| Einstellung | UI-Element | Standard |
|-------------|-----------|---------|
| Schriftgröße Spielmodus | Slider (5 Stufen) | Mittel |
| Helligkeit Spielmodus | Slider (%) | 75% |
| Bildschirm-Timeout | Toggle „Deaktivieren" | An (deaktiviert) |
| Auto-Rotation sperren | Toggle | Aus |
| Noten-Hintergrundfarbe | Radio: Weiß / Sepia / Schwarz | Weiß |

### 6.2 Touch & Gesten

| Einstellung | UI-Element | Standard |
|-------------|-----------|---------|
| Tap-Zonen-Aufteilung | Slider (20%–50% links) | 40% links / 60% rechts |
| Wisch-Empfindlichkeit | Segmented: Niedrig/Mittel/Hoch | Mittel |
| Stift: Annotation | Toggle | An |
| Finger: Annotation | Toggle | Aus (verhindert Handballen-Striche) |

### 6.3 Audio

| Einstellung | UI-Element | Standard |
|-------------|-----------|---------|
| Tuner-Referenzton | Zahleneingabe mit +/- | 440 Hz |
| Metronom-Lautstärke | Slider | 80% |

### 6.4 Fußpedal

```
VERBUNDENES GERÄT
  [Kein Gerät verbunden]
  [Gerät suchen →] → Bluetooth-Pairing-Flow

TASTENBELEGUNG (wenn verbunden)
  Rechts (A): [Nächste Seite    ▼]
  Links (B):  [Vorherige Seite  ▼]
  Mitte (C):  [Overlay toggle   ▼]
  
  Verfügbare Aktionen:
  Nächste/Vorherige Seite, Half-Turn vor/zurück,
  Overlay öffnen/schließen, Nachtmodus toggle
```

### 6.5 Speicher & Cache

```
OFFLINE-CACHE
  Verwendet: 1,2 GB von 5 GB
  [████████░░░░░░░░░░░░] 24%
  [Cache leeren]  ← Destructive, Bestätigung nötig

AUTO-VORAB-LADEN
  Kommende Setlists vorab laden: [■ An]
  Nur im WLAN:                   [■ An]
  Vorab-Laden wie viele Tage im Voraus: [3 Tage ▼]
```

---

## 7. Interaction Patterns

### 7.1 Auto-Save — der wichtigste Pattern

**Kein „Speichern"-Button existiert in den Einstellungen.**

```
Nutzer ändert Einstellung
        │
        ▼
Sofort gespeichert (lokal + Sync-Queue)
        │
        ▼
Toast erscheint (5 Sekunden):
┌────────────────────────────────────────┐
│  Schriftgröße geändert    [Rückgängig] │
└────────────────────────────────────────┘
        │ [Rückgängig] getippt
        ▼
Einstellung zurückgesetzt
Toast: „Rückgängig gemacht"
```

### 7.2 Gefährliche Aktionen — Bestätigung erforderlich

Nur wirklich irreversible oder weitreichende Aktionen bekommen einen Dialog:

| Aktion | Bestätigung |
|--------|-------------|
| Cache leeren | Dialog mit Erklärung |
| Policy aktivieren | Dialog mit Anzahl betroffener Nutzer |
| Konto löschen | Dialog + Passwort-Eingabe |
| Kapelle verlassen | Dialog |

Alles andere: kein Dialog, nur Undo-Toast.

### 7.3 Sofortige Wirkung — keine Neustarts

| Einstellung | Wirkung |
|-------------|---------|
| Theme hell/dunkel | Sofort — gesamte UI |
| Sprache | Sofort — Text wechselt |
| AI-Key | Ab dem nächsten Import |
| Schriftgröße Spielmodus | Beim nächsten Stück öffnen |
| Cache leeren | Sofort nach Bestätigung |
| Policy aktivieren | Sofort für alle Mitglieder |

**Absolute Regel:** „Bitte App neu starten" darf NIE erscheinen.

### 7.4 Vererbungsanzeige

Wenn eine Einstellung von oben kommt, wird das klar kommuniziert:

```
ÜBERSCHREIBBAR (blauer Hinweis):
  🏛 Standard von Kapelle: An
  [Eigenen Wert festlegen]

ERZWUNGEN (Lock):
  🏛 🔒 Nachtmodus bei Konzerten
  Von Kapelle vorgegeben.
  Kann nicht geändert werden.
  Frage deinen Administrator.
```

### 7.5 Admin-Einstellungen nur für Admins

- Kapellen-Einstellungen sind für Nicht-Admins **vollständig ausgeblendet** (nicht ausgegraut — versteckt)
- Wenn ein Nutzer Admin wird, erscheinen die Einstellungen sofort
- Kein Hinweis auf existierende Admin-Einstellungen für Nicht-Admins

---

## 8. Onboarding-Integration

### 8.1 Onboarding-Wizard (5 Schritte, max. 3 Minuten)

```
Schritt 1/5: Willkommen
┌─────────────────────────────────┐
│                                 │
│         🎵 Sheetstorm           │
│                                 │
│  Deine Noten. Jederzeit.        │
│  Überall.                       │
│                                 │
│  Schnell einrichten —           │
│  nur 5 kurze Fragen.            │
│                                 │
│       [Los geht's →]            │
│                                 │
│       [Ich bin Gast]            │  ← Aushilfen-Token-Flow
└─────────────────────────────────┘

Schritt 2/5: Name
┌─────────────────────────────────┐
│  ○○●○○                 2/5      │
│  Wie heißt du?                  │
│  [Anna                       ]  │
│  [← Zurück]     [Weiter →]     │
└─────────────────────────────────┘

Schritt 3/5: Instrument & Stimme
┌─────────────────────────────────┐
│  ○○○●○                 3/5      │
│  Was spielst du?                │
│  (Mehrere möglich)              │
│  🔍 [Instrument suchen…]        │
│  🎵 Klarinette            ✓    │
│     Stimme: [2. Klar.       ▼] │
│  🎺 Trompete                    │
│  🎶 Tuba                        │
│  ...                            │
│  [← Zurück]     [Weiter →]     │
└─────────────────────────────────┘

Schritt 4/5: Kapelle
┌─────────────────────────────────┐
│  ○○○○●                 4/5      │
│  Bist du Teil einer Kapelle?    │
│                                 │
│  [Kapelle beitreten →]          │
│  (QR-Code oder Einladungscode)  │
│                                 │
│  [Neue Kapelle erstellen →]     │
│                                 │
│  [Erst mal ohne Kapelle]        │
│                                 │
│  [← Zurück]                     │
└─────────────────────────────────┘

Schritt 5/5: Darstellung
┌─────────────────────────────────┐
│  ○○○○○●                5/5      │
│  Wie soll Sheetstorm aussehen?  │
│                                 │
│  ┌────────┐   ┌────────┐        │
│  │ HELL   │   │ DUNKEL │        │
│  │ [Prev] │   │ [Prev] │        │
│  └────────┘   └────────┘        │
│                                 │
│  [● Wie mein Gerät]             │
│                                 │
│  [← Zurück]     [Fertig ✓]     │
└─────────────────────────────────┘

Abschluss:
┌─────────────────────────────────┐
│         ✅                      │
│  Alles bereit, Anna!            │
│                                 │
│  Deine Kapelle hat              │
│  312 Stücke für dich.           │
│                                 │
│  [Bibliothek →]                 │
│  [Setlist ansehen →]            │
└─────────────────────────────────┘
```

### 8.2 Onboarding-Regeln

| Regel | Begründung |
|-------|-----------|
| Maximal 5 Fragen | Musiker sollen in <3 Minuten spielbereit sein |
| Alle Schritte überspringbar | Kein Blocker, sinnvolle Defaults |
| Kein Zahlungs-Screen | Gehört nicht ins Onboarding |
| Keine Passwort-Eingabe | Separater Auth-Flow (vor Wizard) |
| Fortschritts-Dots | Kein Blocker-Gefühl |
| Name aus Registrierung vorausgefüllt | Keine Doppeleingabe |

### 8.3 Gerät-Einstellungen beim ersten Login (neues Gerät)

Beim ersten Login auf einem neuen Gerät erhalten die Gerät-Einstellungen intelligente Defaults:

```
BEIM ERSTEN LOGIN AUF NEUEM GERÄT:

1. Nutzer-Einstellungen werden synchronisiert ✓
   (Instrumente, Stimmen, Theme, AI-Key)

2. Gerät-Einstellungen: Intelligente Defaults
   → Phone:   Schriftgröße Mittel, Tap-Zone 40/60
   → Tablet:  Schriftgröße Groß, 2-Up Ansicht
   → Desktop: Schriftgröße Standard, Tastatur-Shortcuts

3. Kurzer Hinweis:
   ┌─────────────────────────────────────────────┐
   │  📱 Neues Gerät erkannt                     │
   │  Gerät-Einstellungen für dieses Gerät       │
   │  optimiert.                     [Anpassen] │
   └─────────────────────────────────────────────┘
   Toast, 8 Sekunden, nicht blockierend
```

---

## 9. Spielmodus — Kontextuelle Einstellungen

→ Vollständige Spec in `docs/ux-specs/spielmodus.md §12`

### 9.1 Prinzip: 5 Optionen Maximum

Das ⚙️-Icon im Spielmodus öffnet ein Overlay-Panel über dem sichtbaren Notenblatt (Notenblatt bleibt sichtbar dahinter). Maximal 5 Optionen — kein Scrollen im Spielmodus.

### 9.2 Die 5 Kontextoptionen (fix)

```
┌──────────────────────────────────────────┐
│  ⚙️ Schnelleinstellungen             ✕  │
│  [Notenblatt sichtbar dahinter]          │
├──────────────────────────────────────────┤
│  🌙 Nachtmodus           [■ Ein]        │
│  📄 Half-Page-Turn       [■ Ein]        │
│  🔤 Schriftgröße  [A−]──●──[A+]        │
│  👁 Layer  [■ Priv]  [■ Stim]  [■ Orch]│
│  ☀️ Helligkeit   [☼−]────●──[☼+]      │
└──────────────────────────────────────────┘
```

### 9.3 Warum genau 5?

- Mehr als 5 Optionen erfordern Scrollen → unmöglich während des Spielens
- Alle 5 sind sofort wirksam — kein Navigieren, kein Speichern
- Vollständige Einstellungen sind für die Vorbereitung (nicht für die Bühne)

---

## 10. Edge Cases

### 10.1 Ersteinrichtung (leere Kapelle)

```
Admin erstellt Kapelle → Leeres Dashboard

HANDLUNGSBEDARF (prominent):
  ⚠️ Noch keine Noten — [Jetzt importieren →]
  ⚠️ Noch keine Mitglieder — [Einladen →]
  ℹ️ AI-Key optional — [Konfigurieren →]

→ Leerer Zustand ist kein Fehler, sondern eine Einladung zum Handeln
```

### 10.2 Multi-Kapellen: Policy-Konflikte

```
Nutzer ist in Kapelle A und B.
Kapelle A: Policy „Nachtmodus An" aktiv
Kapelle B: Keine Policy

Wenn Kapelle A aktiv:
  Einstellung zeigt: 🔒 Nachtmodus erzwungen (Kapelle A)

Wenn Kapelle B aktiv:
  Einstellung zeigt: Eigene Kontrolle, keine Einschränkung

UI in Einstellungen bei Lock:
  „Diese Einstellung wird von der Kapelle vorgegeben,
  wenn ‚Musikkapelle A' aktiv ist."
```

### 10.3 Offline-Einstellungsänderungen

```
NUTZER-EINSTELLUNGEN:
  → Lokal sofort gespeichert
  → Sync-Queue: synchronisiert sobald online
  → Kein Error-State, kein Blocker

KAPELLEN-EINSTELLUNGEN:
  → Disabled mit Hinweis:
    „Kapellen-Einstellungen benötigen Internetverbindung"
    Button ausgegraut

GERÄT-EINSTELLUNGEN:
  → Immer verfügbar (lokal, keine Synchronisation)
```

### 10.4 AI-Key abgelaufen

```
In Kapellen-Einstellungen:
  Status: 🔴 Abgelaufen (15. April 2026)
  → Roter Badge auf AI & Import Tab
  → [Erneuern]-Button prominent

Im Import-Flow (wenn kein Key):
  ⚠️ Keine KI verfügbar
  [KI-Key konfigurieren]
  [Ohne KI fortfahren →]  ← Manueller Import, kein Blocker
```

### 10.5 Aushilfen: Keine Einstellungen

Aushilfen (Token-Zugang ohne Account) haben keine Einstellungen:
- Gerät-Einstellungen: Vollständig verfügbar (lokal)
- Nutzer-Einstellungen: Nicht verfügbar (kein Account)
- Kapellen-Einstellungen: Nicht verfügbar
- Fußpedal: Verfügbar (gerätebezogen)
- Nachtmodus via Kontextuell: Verfügbar

### 10.6 Gerätewechsel — Defaults neu laden

```
Beim ersten Login auf neuem Gerät:
  1. Nutzer-Einstellungen synchronisiert ✓
  2. Gerät-Einstellungen: Intelligente Defaults
  3. Hinweis-Toast: „Gerät-Einstellungen anpassen?"
     [Jetzt anpassen]  [Später]
```

---

## 11. Wireframes: Phone

### 11.1 Phone — Einstellungen Hauptseite

```
┌─────────────────────────────────┐
│  ← Profil        Einstellungen  │
├─────────────────────────────────┤
│  🔍 Einstellungen suchen…       │
├─────────────────────────────────┤
│                                 │
│ ▌ 🏛 KAPELLE                   │  ← ▌ = Blauer linker Rand
│   Musikkapelle Beispiel         │
│   ─────────────────────────     │
│   Allgemein                   > │
│   Mitglieder & Rollen         > │
│   AI & Import             ⚠️  > │  ← Badge bei Handlungsbedarf
│   Policies                    > │
│                                 │
│ ▌ 👤 NUTZER                    │  ← ▌ = Grüner linker Rand
│   ─────────────────────────     │
│   Profil & Konto              > │
│   Instrumente & Stimmen       > │
│   Darstellung                 > │
│   AI (persönlich)             > │
│   Benachrichtigungen          > │
│                                 │
│ ▌ 📱 GERÄT                     │  ← ▌ = Oranger linker Rand
│   Dieses Gerät                  │
│   ─────────────────────────     │
│   Anzeige                     > │
│   Touch & Gesten              > │
│   Audio                       > │
│   Fußpedal                    > │
│   Speicher & Cache            > │
│                                 │
└─────────────────────────────────┘
│  📚    🎵    📅    👤            │
└─────────────────────────────────┘
```

### 11.2 Phone — Kapelle: AI & Import-Tab

```
┌─────────────────────────────────┐
│  ← Einstellungen  AI & Import   │
├─────────────────────────────────┤
│                                 │
│  KAPELLEN-AI-KEY                │
│  ─────────────────────────────  │
│  Provider:                      │
│  [Azure AI Vision          ▼]  │
│                                 │
│  API-Key:                       │
│  [●●●●●●●●●●●●        👁]     │
│                                 │
│  Status: 🟢 Aktiv               │
│  Quota: 8.420 / 10.000          │
│  [████████░░░░░░░░░░] 84%       │
│                                 │
│  Ablauf: 15. April 2026 ⚠️      │
│  [Jetzt erneuern]               │
│                                 │
│  FALLBACK                       │
│  ─────────────────────────────  │
│  Wenn kein Key:                 │
│  ○ Nur manuell (kein AI)        │
│  ● Nutzer-Key erlauben ← Std.   │
│                                 │
│  IMPORT-STANDARD                │
│  ─────────────────────────────  │
│  OCR-Sprache: [Deutsch     ▼]  │
│  Auto-Metadaten: [■ An]         │
│                                 │
└─────────────────────────────────┘
```

### 11.3 Phone — Gerät: Anzeige-Tab

```
┌─────────────────────────────────┐
│  ← Einstellungen  📱 Anzeige    │
├─────────────────────────────────┤
│                                 │
│  SPIELMODUS                     │
│  ─────────────────────────────  │
│  Schriftgröße                   │
│  [A−] ○──────●────────○ [A+]   │
│       Kl.  Mittel  Gr.  Sehr gr.│
│                                 │
│  Helligkeit                     │
│  [☼−] ──────────●───── [☼+]   │
│                   75%           │
│                                 │
│  Bildschirm-Timeout             │
│  Im Spielmodus: [■ Deaktiviert] │
│  (Bildschirm bleibt immer an)   │
│                                 │
│  Auto-Rotation sperren          │
│  Im Spielmodus: [□ Aus]         │
│                                 │
│  NOTEN-HINTERGRUND              │
│  ─────────────────────────────  │
│  ● Weiß   ○ Sepia   ○ Schwarz  │
│                                 │
└─────────────────────────────────┘
```

### 11.4 Phone — Gerät: Touch & Gesten-Tab

```
┌─────────────────────────────────┐
│  ← Einstellungen  Touch & Gesten│
├─────────────────────────────────┤
│                                 │
│  TAP-ZONEN AUFTEILUNG           │
│  ─────────────────────────────  │
│  ◄──────────┤●├──────────────► │
│    30%   [40%]   70%            │
│  Zurück (links) │ Weiter (rechts)│
│                                 │
│  WISCH-EMPFINDLICHKEIT          │
│  ─────────────────────────────  │
│  [Niedrig]  [● Mittel]  [Hoch]  │
│                                 │
│  STIFT-ERKENNUNG                │
│  ─────────────────────────────  │
│  Stift → Annotation: [■ An]     │
│  Finger → Annotation: [□ Aus]   │
│  (Verhindert Handballen-Striche)│
│                                 │
└─────────────────────────────────┘
```

### 11.5 Phone — Nutzer: Darstellung

```
┌─────────────────────────────────┐
│  ← Einstellungen  Darstellung   │
├─────────────────────────────────┤
│                                 │
│  THEME                          │
│  ─────────────────────────────  │
│  ○ Hell                         │
│  ○ Dunkel                       │
│  ● Wie Gerät ← Standard        │
│                                 │
│  Ändert sich sofort.            │
│  Kein Neustart nötig.           │
│                                 │
│  SPRACHE DER APP                │
│  ─────────────────────────────  │
│  [Deutsch                  ▼]  │
│                                 │
│  Ändert sich sofort.            │
│                                 │
│  🏛 Dark Mode                   │
│  Von Kapelle: An                │  ← Vererbungshinweis (blau)
│  [Eigenen Wert festlegen]       │
│                                 │
└─────────────────────────────────┘
```

---

## 12. Wireframes: Tablet/Desktop

### 12.1 Tablet/Desktop — Einstellungen (Split-View)

```
┌─────────────────────────────┬────────────────────────────────────────────┐
│  EINSTELLUNGEN              │  📱 Anzeige                                │
│  🔍 Suchen…                 │  ─────────────────────────────────────     │
│  ─────────────────────────  │  SPIELMODUS                               │
│ ▌ 🏛 KAPELLE                │  ─────────────────────────────────────     │
│   Allgemein                 │  Schriftgröße                             │
│   Mitglieder & Rollen       │  ○ Klein   ● Mittel   ○ Groß   ○ Sehr gr.│
│   AI & Import          ⚠️   │                                           │
│   Policies                  │  Helligkeit im Spielmodus                 │
│                             │  [─────────────────────●─] 75%            │
│ ▌ 👤 NUTZER                 │                                           │
│   Profil & Konto            │  Bildschirm-Timeout im Spielmodus         │
│   Instrumente & Stimmen     │  [■ Deaktiviert]                          │
│   Darstellung               │                                           │
│   AI (persönlich)           │  Auto-Rotation sperren                    │
│   Benachrichtigungen        │  [□ Aus]                                  │
│                             │                                           │
│ ▌ 📱 GERÄT                  │  NOTEN-HINTERGRUND                        │
│   ► Anzeige ●               │  ─────────────────────────────────────     │
│   Touch & Gesten            │  ○ Weiß  ● Sepia  ○ Schwarz (Nacht)     │
│   Audio                     │                                           │
│   Fußpedal                  │                                           │
│   Speicher & Cache          │                                           │
└─────────────────────────────┴────────────────────────────────────────────┘
```

### 12.2 Desktop — Admin-Dashboard (Kapelle-Einstellungen)

```
┌──────────────────────┬───────────────────────────────────────────────────┐
│  SHEETSTORM          │  🏛 Kapellen-Einstellungen                        │
│  [Kapelle ▼]         │  Musikkapelle Beispiel                            │
│  ─────────────────── │  ─────────────────────────────────────────────    │
│  📚 Bibliothek       │                                                   │
│  🎵 Setlists         │  HANDLUNGSBEDARF              Alles gut ✓         │
│  📅 Kalender         │  ┌───────────────────────────────────────────┐    │
│  ─────────────────── │  │  ⚠️ 3 Mitglieder ohne Instrumente [→]    │    │
│  ADMIN               │  │  ⚠️ AI-Key läuft in 12 Tagen ab  [→]    │    │
│  👥 Mitglieder       │  └───────────────────────────────────────────┘    │
│  ⚙️ Einstellungen    │                                                   │
│     ├ Allgemein      │  ──────────────────────────────────────────────   │
│     ├ Mitglieder     │  Allgemein    Mitglieder    AI/Import    Policies │
│     ├ AI/Import  ⚠️  │                                                   │
│     └ Policies       │  [Tab: AI/Import aktiv]                           │
│  ─────────────────── │                                                   │
│  👤 Profil           │  KAPELLEN-AI-KEY                                  │
│  ⚙️ Einstellungen    │  Provider:  [Azure AI Vision         ▼]          │
│                      │  API-Key:   [●●●●●●●●●●●●       👁 Anzeigen]    │
│                      │  Status:    🟢 Aktiv · 8.420/10.000              │
│                      │  Ablauf:    15. April 2026 ⚠️       [Erneuern]   │
└──────────────────────┴───────────────────────────────────────────────────┘
```

### 12.3 Tablet — Onboarding Schritt 3 (Instrument)

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                    ○○○●○                 3/5                         │
│                                                                      │
│                    Was spielst du?                                   │
│            (Mehrere Instrumente möglich)                             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  🔍 Instrument suchen…                                        │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  🎵 Klarinette                                       ✓ ───  │   │
│  │     Standard-Stimme: [2. Klarinette                     ▼]  │   │
│  │                                                             │   │
│  │  🎵 Oboe                                                    │   │
│  │  🎺 Trompete                                                │   │
│  │  🎺 Flügelhorn                                              │   │
│  │  🎺 Tenorhorn                                               │   │
│  │  🎶 Tuba                                                    │   │
│  │  🎵 Querflöte                                               │   │
│  │  🥁 Schlagzeug                                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│                [← Zurück]              [Weiter →]                    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 13. Abhängigkeiten

### 13.1 Für Hill (Frontend / Flutter)

| Komponente | Spec-Verweis |
|------------|-------------|
| `SettingsScreen` (3-Ebenen Hauptseite) | §11.1 |
| `SettingsSearchScreen` | §2.3 |
| `KapelleSettingsScreen` (Admin) | §4, §11.2 |
| `NutzerSettingsScreen` | §5 |
| `GeraetSettingsScreen` | §6, §11.3–11.4 |
| `InheritanceBadge` (Blau/Lock) | §1.4, §7.4 |
| `AutoSaveToast` (Undo-Pattern) | §7.1 |
| `PolicyConfirmDialog` | §7.2 |
| `OnboardingWizard` (5 Schritte) | §8.1 |
| `QuickSettingsOverlay` (Spielmodus) | §9 |
| `NewDeviceSettingsToast` | §8.3 |

### 13.2 Für Banner (Backend)

| Endpoint | Zweck |
|----------|-------|
| `GET /api/kapelle/{id}/settings` | Kapellen-Einstellungen laden |
| `PUT /api/kapelle/{id}/settings` | Kapellen-Einstellungen speichern |
| `POST /api/kapelle/{id}/policies` | Policy aktivieren |
| `GET /api/user/settings` | Nutzer-Einstellungen laden |
| `PUT /api/user/settings` | Nutzer-Einstellungen speichern |
| `GET /api/user/settings/resolved` | Einstellungen mit Vererbung (merged) |
| `POST /api/device/register` | Neues Gerät registrieren + Defaults |

**Hinweis:** Gerät-Einstellungen haben **keinen** Backend-Endpoint — sie werden nur lokal (SQLite/Drift) gespeichert.

### 13.3 Offene Fragen für Thomas

- [ ] Welche Policies sollen für M1 implementiert werden? (Alle 3 aus §4.5 oder nur Nachtmodus?)
- [ ] Soll die Kapellen-Sichtbarkeit in den Settings konfigurierbar sein (öffentlich durchsuchbar vs. nur Einladung)?
- [ ] Wie lange sollen Undo-Toasts angezeigt werden? (5 Sekunden Standard oder anpassbar?)
- [ ] Darf ein Nutzer seinen AI-Key auch dann nutzen, wenn die Kapelle keinen hat, ohne Bestätigung des Admins?
