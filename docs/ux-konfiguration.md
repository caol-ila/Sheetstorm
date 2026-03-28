# UX-Design: Konfigurationssystem — Sheetstorm

> **Version:** 2.0
> **Status:** Entwurf — Review ausstehend
> **Autorin:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Meilenstein:** M1 — Kern: Noten & Kapelle
> **Referenzen:** `docs/anforderungen.md`, `docs/konfigurationskonzept.md`, `docs/ux-design.md`, `docs/ux-research-konkurrenz.md`

---

## Inhaltsverzeichnis

1. [Konzept: 3-Ebenen-Konfiguration](#1-konzept-3-ebenen-konfiguration)
2. [Navigation & Discovery](#2-navigation--discovery)
3. [Kapelle-Einstellungen (Admin-Dashboard)](#3-kapelle-einstellungen-admin-dashboard)
4. [Nutzer-Einstellungen](#4-nutzer-einstellungen)
5. [Gerät-Einstellungen](#5-gerät-einstellungen)
6. [Interaction Patterns](#6-interaction-patterns)
7. [Onboarding-Wizard](#7-onboarding-wizard)
8. [Spielmodus — Kontextuelle Einstellungen](#8-spielmodus--kontextuelle-einstellungen)
9. [Edge Cases](#9-edge-cases)
10. [Wireframes: Alle Key-Screens](#10-wireframes-alle-key-screens)

---

## 1. Konzept: 3-Ebenen-Konfiguration

Sheetstorm hat drei Konfigurationsebenen. Jede Ebene hat einen eigenen Kontext, eine eigene Farbe und eine klar kommunizierte Auswirkungsreichweite.

### 1.1 Ebenenmodell

```
╔════════════════════════════════════════════╗
║  EBENE 1: KAPELLE (Blau)                  ║
║  Gilt für alle Mitglieder dieser Kapelle  ║
║  → Wer darf Noten hochladen?              ║
║  → Welcher AI-Key wird genutzt?           ║
║  → Standardsprache des Archivs?           ║
╠════════════════════════════════════════════╣
║  EBENE 2: NUTZER/PERSÖNLICH (Grün)        ║
║  Gilt nur für diesen Account              ║
║  → Welches Instrument spiele ich?         ║
║  → Helles oder dunkles Theme?             ║
║  → Bevorzugte Stimme pro Stück?           ║
╠════════════════════════════════════════════╣
║  EBENE 3: GERÄT (Orange)                  ║
║  Gilt nur auf diesem Gerät                ║
║  → Schriftgröße im Spielmodus?            ║
║  → Touch-Zone-Empfindlichkeit?            ║
║  → Gespeicherter lokaler Cache?           ║
╚════════════════════════════════════════════╝
```

**Vererbungsregel:** Kapelle → Nutzer → Gerät. Niedrigere Ebenen können Werte überschreiben, **außer wenn die Kapelle eine Policy erzwingt** (Lock-Icon + Erklärung).

### 1.2 Farbsystem

| Ebene | Farbe | Hex | Einsatz |
|-------|-------|-----|---------|
| Kapelle | Blau | `#1A56DB` | Linker Rand, Badge, Icon |
| Nutzer | Grün | `#16A34A` | Linker Rand, Badge, Icon |
| Gerät | Orange | `#D97706` | Linker Rand, Badge, Icon |

**Barrierefreiheit:** Nie Farbe als einziges Unterscheidungsmerkmal. Jede Ebene hat zusätzlich ein eigenes Icon:
- Kapelle: 🏛 (Gebäude)
- Nutzer: 👤 (Person)
- Gerät: 📱 (Gerät)

### 1.3 Vererbungsanzeige im UI

Wenn eine Einstellung von einer übergeordneten Ebene kommt:

```
┌─────────────────────────────────────────┐
│  Dark Mode                              │
│  🏛 Standard von Kapelle: An           │ ← Blauer Hinweis
│  [Eigenen Wert festlegen]               │
│                                         │
│  Stimmgröße im Spielmodus              │
│  🏛 🔒 Von Kapelle vorgegeben: Groß    │ ← Lock = erzwungen
│  (Diese Einstellung kann nicht          │
│   geändert werden)                      │
└─────────────────────────────────────────┘
```

**Lock-Einstellungen:** Wenn die Kapelle eine Einstellung erzwingt (z.B. einheitlicher Nachtmodus beim Konzert), zeigt das UI das Schloss-Icon mit einem kurzen erklärenden Text. Kein verstecktes Override-Verhalten.

---

## 2. Navigation & Discovery

### 2.1 Einstellungs-Zugangspunkte

Einstellungen sind an drei Stellen erreichbar — das ist **bewusst redundant**, weil verschiedene Nutzer verschiedene mentale Modelle haben:

| Zugangspunkt | Pfad | Zielgruppe |
|-------------|------|-----------|
| **Profil-Tab → Einstellungen** | Bottom-Nav → 👤 → ⚙️ | Alle Nutzer |
| **Kapellen-Tab → Verwaltung** | Bottom-Nav → 👤 → Kapelle → Einstellungen | Admins |
| **Kontextuell im Spielmodus** | ⚙️ Overlay | Alle während des Spielens |
| **Einstellungs-Suche** | Überall via 🔍 | Technikaffine Nutzer |

### 2.2 Einstellungs-Suche

Alle Einstellungen sind durchsuchbar. Tippen auf „Einstellungen suchen…" öffnet eine Volltextsuche über alle Settings-Schlüssel:

```
┌──────────────────────────────────┐
│  🔍 Einstellungen suchen...      │
├──────────────────────────────────┤
│  "helligkeit"                    │
│  ────────────                    │
│  📱 Helligkeit im Spielmodus    │ ← Gerät-Einstellung
│     Gerät → Anzeige             │
│                                  │
│  📱 Auto-Helligkeit             │ ← Gerät-Einstellung
│     Gerät → Anzeige             │
└──────────────────────────────────┘
```

**Suchergebnisse zeigen immer:**
1. Einstellungsname
2. Ebenen-Icon (🏛/👤/📱)
3. Pfad (breadcrumb)
4. Direkt zum Setting navigieren (ein Tap)

### 2.3 Einstellungs-Hierarchie (alle Ebenen)

```
Einstellungen
├── 🏛 Kapelle (nur Admins)
│   ├── Allgemein
│   │   ├── Kapellenname, Bild, Beschreibung
│   │   ├── Sprache des Archivs
│   │   └── Zeitzone
│   ├── Mitglieder & Rollen
│   │   ├── Berechtigungen konfigurieren
│   │   ├── Wer darf Noten hochladen
│   │   └── Aushilfen-Zugang
│   ├── AI & Import
│   │   ├── AI-Provider & API-Key
│   │   ├── Standardsprache für OCR
│   │   └── Automatische Metadaten-Erkennung
│   └── Policies (Erzwungene Einstellungen)
│       ├── Einheitlicher Nachtmodus bei Konzerten
│       └── Mindest-Schriftgröße
│
├── 👤 Nutzer / Persönlich
│   ├── Profil
│   │   ├── Name, Profilbild, E-Mail
│   │   └── Benachrichtigungen
│   ├── Instrumente & Stimmen
│   │   ├── Meine Instrumente (Hauptinstrument + weitere)
│   │   └── Standard-Stimme pro Kapelle
│   ├── Darstellung
│   │   ├── Theme (Hell / Dunkel / System)
│   │   └── Sprache der App
│   └── AI (persönlich)
│       ├── Eigener AI-API-Key
│       └── Fallback-Verhalten
│
└── 📱 Gerät
    ├── Anzeige
    │   ├── Schriftgröße im Spielmodus
    │   ├── Helligkeit im Spielmodus
    │   ├── Bildschirm-Timeout deaktivieren
    │   └── Auto-Rotation sperren
    ├── Audio
    │   ├── Tuner-Referenzton (Hz)
    │   └── Metronom-Lautstärke
    ├── Touch & Gesten
    │   ├── Tap-Zone-Aufteilung (links/rechts %)
    │   ├── Wisch-Schwellenwert
    │   └── Stift-Erkennung
    ├── Fußpedal
    │   ├── Verbundenes Gerät
    │   └── Tastenbelegung
    └── Speicher
        ├── Offline-Cache-Größe
        ├── Cache leeren
        └── Automatisches Vorab-Laden
```

---

## 3. Kapelle-Einstellungen (Admin-Dashboard)

### 3.1 Admin-Dashboard — Desktop

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│  SHEETSTORM      │  🏛 Kapellen-Einstellungen                           │
│  [Kapelle ▼]     │  Musikkapelle Beispiel                               │
│  ─────────────── │  ─────────────────────────────────────────────────   │
│  📚 Bibliothek   │  HANDLUNGSBEDARF             Alles in Ordnung ✓     │
│  🎵 Setlists     │  ┌────────────────────────────────────────────────┐  │
│  📅 Kalender     │  │  ⚠️  3 Mitglieder ohne Instrumente → [Ansehen] │  │
│  ─────────────── │  │  ⚠️  AI-Key läuft in 12 Tagen ab → [Erneuern] │  │
│  ADMIN           │  │  ℹ️  2 Stücke ohne Stimmen → [Zuordnen]        │  │
│  👥 Mitglieder   │  └────────────────────────────────────────────────┘  │
│  ⚙  Einstellungen│                                                      │
│     ├ Allgemein  │  EINSTELLUNGEN                                        │
│     ├ Mitglieder │  ─────────────────────────────────────────────────   │
│     ├ AI/Import  │  Allgemein     Mitglieder     AI/Import     Policies  │
│     └ Policies   │                                                      │
│  ─────────────── │  [Tab: Allgemein aktiv]                              │
│  👤 Profil       │                                                      │
│  ⚙  Einstellungen│  Kapellenname:  [Musikkapelle Beispiel          ]   │
│                  │  Profilbild:    [Bild ändern]                        │
│                  │  Beschreibung:  [Gegründet 1948…              ]      │
│                  │  Zeitzone:      [Europe/Vienna               ▼]      │
│                  │                                                      │
└──────────────────┴──────────────────────────────────────────────────────┘
```

### 3.2 Mitglieder-Tab (Admin)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Mitglieder & Rollen                               [+ Einladen]        │
├─────────────────────────────────────────────────────────────────────────┤
│  UPLOAD-BERECHTIGUNG                                                    │
│  Wer darf Noten zur Kapelle hinzufügen?                                 │
│  ☑ Administrator                                                        │
│  ☑ Dirigent                                                             │
│  ☑ Notenwart                                                            │
│  ☐ Registerführer                                                       │
│  ☐ Musiker                                                              │
├─────────────────────────────────────────────────────────────────────────┤
│  AUSHILFEN                                                              │
│  Aushilfen-Links erlauben: [■ An]                                       │
│  Gültigkeit: [7 Tage ▼]                                                 │
│  Zugriff: [Nur zugewiesene Stimme ▼]                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 AI/Import-Tab (Admin)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  AI & Import                                                            │
├─────────────────────────────────────────────────────────────────────────┤
│  KAPELLEN-AI-KEY                                                        │
│  Provider:  [Azure AI Vision         ▼]                                 │
│  API-Key:   [●●●●●●●●●●●●●●●●●    👁  Anzeigen]                       │
│  Status:    🟢 Aktiv · Quota: 8.420/10.000                              │
│  Ablauf:    15. April 2026 ⚠️                             [Erneuern]    │
│                                                                         │
│  Fallback-Verhalten:                                                    │
│  Wenn kein Key verfügbar:                                               │
│  ○ Manueller Import (kein AI)                                           │
│  ● Nutzer darf eigenen Key hinterlegen                                  │
│                                                                         │
│  IMPORT-STANDARDS                                                       │
│  Standard-Sprache für OCR: [Deutsch ▼]                                  │
│  Auto-Metadaten-Erkennung: [■ An]                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.4 Policies-Tab (Admin)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Policies — Erzwungene Einstellungen                                    │
│  Mitglieder können diese Einstellungen nicht überschreiben             │
├─────────────────────────────────────────────────────────────────────────┤
│  ⚠️ Mit Bedacht verwenden — Policies schränken alle Mitglieder ein     │
├─────────────────────────────────────────────────────────────────────────┤
│  [ ] Nachtmodus bei Konzert erzwingen                                   │
│      Alle Geräte wechseln in den Nachtmodus wenn eine Konzert-         │
│      Setlist geöffnet wird.                                             │
│                                                                         │
│  [ ] Mindest-Schriftgröße                                               │
│      Nutzer können nicht kleiner als [—] einstellen.                   │
│                                                                         │
│  [ ] Annotationen nur auf eigener Ebene                                 │
│      Musiker dürfen nur auf der Privat-Ebene annotieren.               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Nutzer-Einstellungen

### 4.1 Nutzer-Einstellungen — Phone

```
┌─────────────────────────────┐
│  ← Profil    Mein Profil    │
├─────────────────────────────┤
│         [Profilbild]        │
│         Anna Mustermann     │
│         anna@example.com    │
│         [Profil bearbeiten] │
├─────────────────────────────┤
│  INSTRUMENTE & STIMMEN      │
├─────────────────────────────┤
│  Meine Instrumente          │
│  ┌─────────────────────┐    │
│  │ 🎵 2. Klarinette ● │    │ ← ● = Hauptinstrument
│  │ 🎵 1. Klarinette   │    │
│  └─────────────────────┘    │
│  [+ Instrument hinzufügen]  │
│                             │
│  Standard-Stimme            │
│  Klar. bei MK Beispiel:     │
│  [2. Klarinette        ▼]   │
├─────────────────────────────┤
│  DARSTELLUNG                │
├─────────────────────────────┤
│  Theme                      │
│  [Hell] [Dunkel] [System ✓] │
│                             │
│  Sprache                    │
│  [Deutsch               ▼] │
├─────────────────────────────┤
│  AI (PERSÖNLICH)            │
├─────────────────────────────┤
│  Eigener AI-Key             │
│  [Nicht konfiguriert    ]   │
│  Kapellen-Key wird genutzt  │
└─────────────────────────────┘
```

### 4.2 Instrumente-Verwaltung (Detail)

```
┌─────────────────────────────┐
│  ← Profil  Instrumente      │
├─────────────────────────────┤
│  HAUPTINSTRUMENT            │
│  ┌─────────────────────┐    │
│  │  🎵 Klarinette      │    │
│  │  Stimmen-Standard:  │    │
│  │  [2. Klarinette ▼] │    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  WEITERE INSTRUMENTE        │
│  🎵 Saxophon (Alt)  ✏️ 🗑   │
│                             │
│  [+ Instrument hinzufügen]  │
├─────────────────────────────┤
│  FALLBACK-LOGIK             │
│  Wenn meine Stimme nicht    │
│  vorhanden ist:             │
│  → Automatisch nächste      │
│    Stimme vorschlagen [■ An]│
└─────────────────────────────┘
```

---

## 5. Gerät-Einstellungen

### 5.1 Gerät-Einstellungen — Phone

```
┌─────────────────────────────┐
│  ← Einstellungen  📱 Gerät  │
├─────────────────────────────┤
│  ANZEIGE                    │
│  ─────────────────────      │
│  Schriftgröße Spielmodus    │
│  [A−] ●────────────── [A+] │ ← Slider
│         Mittel              │
│                             │
│  Helligkeit Spielmodus      │
│  [☼−] ──────●────── [☼+]  │
│              75%            │
│                             │
│  Bildschirm-Timeout         │
│  Im Spielmodus: [■ Aus]     │
│  (Bildschirm bleibt an)     │
│                             │
│  Auto-Rotation sperren      │
│  Im Spielmodus:  [□ Aus]    │
├─────────────────────────────┤
│  TOUCH & GESTEN             │
│  ─────────────────────      │
│  Tap-Zonen Aufteilung       │
│  ◄─────┤├──────────────────►│
│   30%  │  70% →             │ ← Verstellbar
│                             │
│  Wisch-Empfindlichkeit      │
│  [Niedrig] [●Mittel] [Hoch] │
│                             │
│  Stift-Erkennung            │
│  Stift beim Annotieren:[■An]│
│  Finger beim Annot.: [□ Aus]│ ← Verhindert versehentliche Striche
├─────────────────────────────┤
│  AUDIO                      │
│  ─────────────────────      │
│  Tuner-Referenzton          │
│  A4 = [440] Hz  [−] [+]    │
│                             │
│  Metronom-Lautstärke        │
│  [🔇─] ──────●────── [🔊]  │
├─────────────────────────────┤
│  FUSSPEDALAL                │
│  ─────────────────────      │
│  Verbundenes Gerät          │
│  AirTurn BT-105 🟢 Aktiv   │
│  [Neu verbinden] [Entfernen]│
│                             │
│  Tastenbelegung:            │
│  Rechts: [Nächste Seite ▼] │
│  Links:  [Vorherige Seite▼]│
├─────────────────────────────┤
│  SPEICHER                   │
│  ─────────────────────      │
│  Offline-Cache              │
│  Verwendet: 1,2 GB / 5 GB   │
│  [██████░░░░░░░]            │
│  [Cache leeren]             │
│                             │
│  Auto-Vorab-Laden           │
│  Kommende Setlist:[■ An]   │
│  Nur im WLAN:      [■ An]  │
└─────────────────────────────┘
```

### 5.2 Gerät-Einstellungen — Desktop (Side-Panel)

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│  ← Zurück        │  📱 Gerät-Einstellungen                              │
│  EINSTELLUNGEN   │  Desktop-Browser                                     │
│  ─────────────── │  ─────────────────────────────────────────────────   │
│  🏛 Kapelle      │  ANZEIGE          TOUCH         AUDIO     SPEICHER   │
│  👤 Nutzer       │  ─────────────────────────────────────────────────   │
│  📱 Gerät        │  [Tab: Anzeige aktiv]                                │
│     ├ Anzeige    │                                                      │
│     ├ Touch      │  Schriftgröße im Spielmodus                          │
│     ├ Audio      │  ○ Klein    ● Mittel    ○ Groß    ○ Sehr groß        │
│     ├ Fußpedal   │                                                      │
│     └ Speicher   │  Helligkeit im Spielmodus                            │
│                  │  [───────────────●─────] 75%                         │
│                  │                                                      │
│                  │  Bildschirm-Timeout im Spielmodus                    │
│                  │  [■ Deaktiviert]  (Bildschirm bleibt immer an)       │
│                  │                                                      │
│                  │  Noten-Hintergrundfarbe im Spielmodus                │
│                  │  ○ Weiß  ● Sepia  ○ Schwarz (Nacht)                 │
└──────────────────┴──────────────────────────────────────────────────────┘
```

---

## 6. Interaction Patterns

### 6.1 Auto-Save mit Undo-Toast

Jede Einstellungsänderung wird **sofort und automatisch** gespeichert. Kein „Speichern"-Button existiert.

```
Nutzer ändert Schriftgröße → Sofort angewendet
                           → Toast erscheint unten:

┌────────────────────────────────────────┐
│  Schriftgröße geändert    [Rückgängig] │ ← 5 Sekunden sichtbar
└────────────────────────────────────────┘
```

**Gefährliche Aktionen** (irreversibel oder weitreichend) bekommen einen Bestätigungs-Dialog:

```
  ⚠️ Cache leeren?
  
  Alle lokal gespeicherten Noten werden
  gelöscht. Du kannst sie jederzeit neu
  herunterladen, benötigst dafür aber
  eine Internetverbindung.
  
  [Abbrechen]       [Cache leeren]
                    (roter Button)
```

### 6.2 Vererbungsanzeige

Wenn eine Einstellung von einer übergeordneten Ebene stammt, zeigt das UI dies klar an:

```
STANDARD VON KAPELLE
┌─────────────────────────────────────────┐
│  🏛 Dark Mode                           │
│  Von Kapelle: An                        │
│  ─────────────────────────────────────  │
│  [Eigenen Wert festlegen]               │
└─────────────────────────────────────────┘

ERZWUNGEN VON KAPELLE (Lock)
┌─────────────────────────────────────────┐
│  🏛 🔒 Nachtmodus bei Konzerten         │
│  Von Kapelle vorgegeben                 │
│  Kann nicht geändert werden.            │
│  Frage deinen Administrator.            │
└─────────────────────────────────────────┘
```

### 6.3 Keine Einstellung erfordert Neustart

Alle Einstellungen wirken sofort:

| Einstellung | Wirkung |
|-------------|---------|
| Theme hell/dunkel | Sofort — komplette UI-Aktualisierung |
| Sprache | Sofort — Text wechselt ohne Reload |
| AI-Provider-Key | Ab dem nächsten Import |
| Schriftgröße Spielmodus | Beim nächsten Öffnen eines Stücks |
| Cache leeren | Sofort nach Bestätigung |

**Nie zeigen:** „Bitte App neu starten, um die Änderung zu übernehmen."

### 6.4 Kontextuelle Einstellungen im Spielmodus

Im Spielmodus müssen die häufigsten Anpassungen **ohne den Modus zu verlassen** zugänglich sein (→ Sektion 8).

---

## 7. Onboarding-Wizard

**Maximal 5 Fragen.** Alles andere hat sinnvolle Defaults. Blaskapellen-Mitglieder sollen in unter 3 Minuten spielbereit sein.

### 7.1 Wizard-Flow

```
Schritt 1/5: Willkommen
┌─────────────────────────────┐
│                             │
│       🎵 Sheetstorm         │
│                             │
│  Deine Noten. Jederzeit.    │
│  Überall.                   │
│                             │
│  Schnell einrichten —       │
│  nur 5 kurze Fragen.        │
│                             │
│       [Los geht's →]        │
│                             │
│       [Ich bin Gast]        │ ← Aushilfen-Link-Zugang
└─────────────────────────────┘

Schritt 2/5: Dein Name
┌─────────────────────────────┐
│  ○○●○○             2/5      │ ← Fortschritts-Dots
│                             │
│  Wie heißt du?              │
│                             │
│  [Anna                    ] │
│                             │
│  [← Zurück]  [Weiter →]    │
└─────────────────────────────┘

Schritt 3/5: Dein Instrument
┌─────────────────────────────┐
│  ○○○●○             3/5      │
│                             │
│  Was spielst du?            │
│                             │
│  🔍 [Instrument suchen…]   │
│  ─────────────────────────  │
│  🎵 Klarinette       ✓     │ ← Mehrfachauswahl möglich
│     → Stimme: [2. Klar.▼] │
│  🎵 Saxophon (Alt)         │
│  🎺 Trompete               │
│  🎺 Flügelhorn             │
│  🎵 Flöte                  │
│  ...                        │
│                             │
│  [← Zurück]  [Weiter →]    │
└─────────────────────────────┘

Schritt 4/5: Kapelle
┌─────────────────────────────┐
│  ○○○○●             4/5      │
│                             │
│  Bist du Teil einer         │
│  Kapelle?                   │
│                             │
│  [Kapelle beitreten]        │ ← QR-Code scannen oder Code eingeben
│                             │
│  [Neue Kapelle erstellen]   │
│                             │
│  [Erst mal ohne Kapelle]    │
│                             │
│  [← Zurück]                 │
└─────────────────────────────┘

Schritt 5/5: Darstellung
┌─────────────────────────────┐
│  ○○○○○●            5/5      │ ← Letzter Schritt
│                             │
│  Wie soll Sheetstorm        │
│  aussehen?                  │
│                             │
│  ┌────────┐  ┌────────┐     │
│  │ HELL   │  │ DUNKEL │     │
│  │ [Prev] │  │ [Prev] │     │
│  └────────┘  └────────┘     │
│                             │
│  [Wie mein Gerät] ✓         │
│                             │
│  [← Zurück]  [Fertig ✓]    │
└─────────────────────────────┘

Abschluss:
┌─────────────────────────────┐
│                             │
│       ✅                    │
│  Alles bereit, Anna!        │
│                             │
│  Deine Kapelle hat          │
│  312 Stücke für dich.       │
│                             │
│       [Bibliothek →]        │
│       [Setlist ansehen →]   │
│                             │
└─────────────────────────────┘
```

### 7.2 Onboarding-Regeln

- **Kein Passwort-Screen im Wizard** — wird separat behandelt (E-Mail-Link oder Social-Login)
- **Alle Felder haben Defaults** — Nutzer kann jeden Schritt mit „Weiter" überspringen
- **Fortschritts-Dots** — zeigen Gesamtlänge, kein Blocker-Gefühl
- **Kein Schritt fragt nach Zahlungsinformationen** — gehört nicht ins Onboarding

---

## 8. Spielmodus — Kontextuelle Einstellungen

### 8.1 Kontextmenü im Spielmodus

Tap auf ⚙️ in der Spielmodus-Overlay-Leiste öffnet ein Overlay-Panel (Notenblatt bleibt sichtbar):

```
┌─────────────────────────────┐
│     [Notenblatt sichtbar]   │
│     [mit Dimm-Overlay]      │
├─────────────────────────────┤
│  ⚙️ Schnelleinstellungen   ✕│
├─────────────────────────────┤
│                             │
│  🌙 Nachtmodus              │
│  [●─────────────────────]  │ ← Ein
│                             │
│  📄 Half-Page-Turn          │
│  [●─────────────────────]  │ ← Ein
│                             │
│  🔤 Schriftgröße            │
│  [A−] ──────●──── [A+]     │
│                             │
│  👁 Annotationsebenen       │
│  [■ Privat] [■ Stimme] [■ Orch.]│
│                             │
│  ☀️ Helligkeit              │
│  [☼−] ────────●── [☼+]    │
│                             │
└─────────────────────────────┘
```

**Regeln für Kontextmenü:**
- Maximal 5 Optionen (kein Scrollen nötig)
- Notenblatt bleibt in vollem Kontext sichtbar hinter dem Overlay
- Sofortige Wirkung aller Änderungen (Auto-Save)
- Kein „Zurück zur Einstellung" — das ist das Setting

### 8.2 Stimmwechsel im Spielmodus

```
Tap auf „🎵 Stimme" in der Overlay-Leiste →

┌─────────────────────────────┐
│  Stimme wechseln       ✕   │
├─────────────────────────────┤
│  MEINE INSTRUMENTE          │
│  ✓ 2. Klarinette  ████████ │ ← Farblich hervorgehoben
│    1. Klarinette            │
├─────────────────────────────┤
│  ANDERE STIMMEN             │
│    Trompete 1               │
│    Trompete 2               │
│    Flügelhorn               │
└─────────────────────────────┘
```

---

## 9. Edge Cases

### 9.1 Erstmalige Einrichtung

**Scenario:** Neue Kapelle, erster Admin richtet ein.

```
Schritt 1: Admin registriert sich → Onboarding-Wizard
Schritt 2: Kapelle erstellen → Name, Profilbild, Beschreibung
Schritt 3: Einladungslinks generieren für Mitglieder
Schritt 4: Kapellen-Dashboard → Handlungsbedarf zeigt:
           ⚠️ "Noch keine Noten — Jetzt importieren"
           ⚠️ "Noch keine Mitglieder — Einladen"
```

**UX-Implikation:** Leerer Zustand ist kein Fehler. Leere Bibliothek zeigt prominente Import-Einladung.

### 9.2 Multi-Kapellen: Konflikte

**Scenario:** Nutzer ist in zwei Kapellen. Kapelle A erzwingt Nachtmodus, Kapelle B nicht.

```
REGEL: Die Einstellung gilt für die aktuell aktive Kapelle.

Kapelle A aktiv → Policy: Nachtmodus an
Kapelle B aktiv → Policy: keine Vorgabe (Nutzereinstellung gilt)

UI zeigt im Setting:
"Diese Einstellung wird von der Kapelle vorgegeben,
wenn 'Musikkapelle A' aktiv ist."
```

### 9.3 Offline-Einstellungsänderungen

**Scenario:** Nutzer ändert Einstellungen ohne Internetverbindung.

```
NUTZER-EINSTELLUNGEN:
→ Lokal sofort gespeichert
→ Sync-Queue: wird synchronisiert sobald online
→ Kein Error-State, kein Blocker

KAPELLEN-EINSTELLUNGEN:
→ Nicht offline änderbar (erfordert Server-Validierung)
→ Disabled mit Hinweis: "Kapellen-Einstellungen benötigen
  eine Internetverbindung"

GERÄTE-EINSTELLUNGEN:
→ Immer lokal, keine Synchronisation nötig
```

### 9.4 AI-Key abgelaufen / nicht konfiguriert

**Scenario:** Import-Flow gestartet, aber kein gültiger AI-Key vorhanden.

```
┌─────────────────────────────┐
│  ⚠️ Keine KI verfügbar      │
│                             │
│  Für die automatische       │
│  Erkennung wird ein AI-Key  │
│  benötigt.                  │
│                             │
│  [KI-Key konfigurieren]     │
│                             │
│  [Ohne KI fortfahren]       │ ← Manueller Import als Fallback
│  (Metadaten von Hand)       │
└─────────────────────────────┘
```

**Kein Blocker:** Nutzer kann immer ohne AI importieren. AI ist Enhancement, nicht Requirement.

### 9.5 Aushilfen-Zugang (ohne Registrierung)

**Scenario:** Ersatzmusiker soll schnell Zugang zu seinen Noten erhalten.

```
ADMIN / NOTENWART:

1. Bibliothek → Stück → ⋯ → Aushilfen-Link erstellen
2. Stimme wählen: [Trompete 1 ▼]
3. Gültigkeit: [7 Tage ▼]
4. [Link kopieren] → In WhatsApp/E-Mail teilen

AUSHILFE (kein Account):

1. Link öffnet im Browser
2. Nur die zugewiesene Stimme sichtbar
3. PDF download oder direkter Viewer
4. Keine Registrierung, kein Passwort
5. Nach Ablaufdatum: Link ungültig → freundliche Fehlermeldung
```

### 9.6 Gerätewechsel — Keine Einstellungen übertragen

**Scenario:** Nutzer hat ein neues Tablet und meldet sich an.

```
BEIM ERSTEN LOGIN AUF NEUEM GERÄT:

1. Nutzer-Einstellungen (Profil, Instrumente, Theme): werden geladen ✓
2. Gerät-Einstellungen: werden auf intelligente Defaults gesetzt
   → Schriftgröße: Mittel
   → Touch-Zonen: Standard (40/60)
   → Fußpedal: Nicht konfiguriert
3. Kurzer Hinweis: "Neue Geräte-Einstellungen — für dieses
   Gerät anpassen?"
   [Jetzt anpassen] [Später]
```

---

## 10. Wireframes: Alle Key-Screens

### 10.1 Einstellungen-Hauptseite — Phone

```
┌─────────────────────────────┐
│  ← Profil    Einstellungen  │
├─────────────────────────────┤
│  🔍 Einstellungen suchen…   │
├─────────────────────────────┤
│                             │
│  🏛 KAPELLE                 │ ← Blauer Balken links
│  Musikkapelle Beispiel      │
│  ─────────────────────      │
│  Allgemein                >│
│  Mitglieder & Rollen       >│
│  AI & Import               >│
│  Policies                  >│
│                             │
│  👤 NUTZER                  │ ← Grüner Balken links
│  ─────────────────────      │
│  Profil & Konto            >│
│  Instrumente & Stimmen     >│
│  Darstellung               >│
│  AI (persönlich)           >│
│  Benachrichtigungen        >│
│                             │
│  📱 GERÄT                   │ ← Oranger Balken links
│  Dieses Gerät               │
│  ─────────────────────      │
│  Anzeige                   >│
│  Touch & Gesten            >│
│  Audio                     >│
│  Fußpedal                  >│
│  Speicher & Cache          >│
│                             │
└─────────────────────────────┘
│  📚    🎵    📅    👤        │
└─────────────────────────────┘
```

### 10.2 Einstellungen-Hauptseite — Desktop (Split-View)

```
┌──────────────────────┬──────────────────────────────────────────────────┐
│  🏛 KAPELLE          │  👤 Profil & Konto                               │
│  ─────────────────── │  ─────────────────────────────────────────────   │
│  Allgemein           │  PROFIL-DETAILS                                  │
│  Mitglieder & Rollen │  Name:       [Anna Mustermann              ]     │
│  AI & Import         │  E-Mail:     [anna@example.com             ]     │
│  Policies            │  Profilbild: [Bild ändern]                       │
│                      │  ─────────────────────────────────────────────   │
│  👤 NUTZER           │  SICHERHEIT                                      │
│  ─────────────────── │  Passwort ändern                                 │
│  ► Profil & Konto ●  │  Zwei-Faktor-Authentifizierung                  │
│  Instrumente         │  ─────────────────────────────────────────────   │
│  Darstellung         │  KONTO LÖSCHEN                                   │
│  AI (persönlich)     │  ⚠️ Konto und alle persönlichen Daten löschen   │
│  Benachrichtigungen  │  [Konto löschen]  (roter Button)                 │
│                      │                                                  │
│  📱 GERÄT            │                                                  │
│  ─────────────────── │                                                  │
│  Anzeige             │                                                  │
│  Touch & Gesten      │                                                  │
│  Audio               │                                                  │
│  Fußpedal            │                                                  │
│  Speicher & Cache    │                                                  │
└──────────────────────┴──────────────────────────────────────────────────┘
```

### 10.3 Onboarding — Schritt 3 (Instrument) — Tablet

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              ○○○●○              3/5                 │
│                                                     │
│              Was spielst du?                        │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  🔍 Instrument suchen…                        │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │  🎵 Klarinette                    ✓ ─────  │    │ ← Ausgewählt
│  │     Standard-Stimme: [2. Klarinette    ▼]  │    │
│  │                                             │    │
│  │  🎵 Oboe                                   │    │
│  │  🎺 Trompete                               │    │
│  │  🎺 Flügelhorn                             │    │
│  │  🎺 Tenorhorn                              │    │
│  │  🎶 Tuba                                   │    │
│  │  🎵 Querflöte                              │    │
│  │  🎵 Fagott                                 │    │
│  │  🥁 Schlagzeug                             │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
│          [← Zurück]        [Weiter →]               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 10.4 Aushilfen-Link erstellen — Phone (Notenwart)

```
┌─────────────────────────────┐
│  ← Böhmischer Traum         │
│  Aushilfen-Zugang erstellen │
├─────────────────────────────┤
│  Stück:                     │
│  Böhmischer Traum           │
│                             │
│  Stimme:                    │
│  [Trompete 1           ▼]  │
│                             │
│  Gültigkeit:                │
│  [7 Tage               ▼]  │
│                             │
│  Notiz (optional):          │
│  [z.B. für Susi M.       ] │
│                             │
│  [Link erstellen]           │
├─────────────────────────────┤
│  ZULETZT ERSTELLT           │
│  ─────────────────────      │
│  Trompete 1 · Susi M.       │
│  Noch 5 Tage gültig         │
│  [Link kopieren] [Löschen]  │
└─────────────────────────────┘
```

### 10.5 Kontextuelle Einstellungen im Spielmodus — Tablet

```
┌──────────────────────────────────────────────────────────┐
│  ← Zurück    Böhm. Traum (3/12)                    ⚙    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│           [NOTENBLATT — SICHTBAR DAHINTER]              │
│           [gedimmt durch halbtransparentes Overlay]     │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ ┌──────────────────────────────────────────────────────┐ │
│ │  ⚙ Schnelleinstellungen                        ✕   │ │
│ │  ──────────────────────────────────────────────────  │ │
│ │  🌙 Nachtmodus              [●───────────────────]  │ │
│ │                                                      │ │
│ │  📄 Half-Page-Turn          [●───────────────────]  │ │
│ │                                                      │ │
│ │  🔤 Schriftgröße     [A-] ──────●──── [A+]          │ │
│ │                                                      │ │
│ │  👁 Ebenen   [■ Priv.] [■ Stimme] [■ Orch.]         │ │
│ │                                                      │ │
│ │  ☀️ Helligkeit      [☼−] ────────●── [☼+]           │ │
│ └──────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

> **Nächste Schritte:**
> 1. Abstimmung mit Stark zu Datenmodell der Config-Ebenen (Policy-Serialisierung)
> 2. Onboarding-Test: 5 Musiker, kalte Erstnutzung messen
> 3. Einstellungs-Suche: Welche Keywords suchen Nutzer? (Card-Sorting Session)
> 4. Aushilfen-Link-Flow mit echten Notenwarten testen
> 5. Abstimmung mit Romanoff (Frontend) zu Auto-Save-Implementation (Riverpod + Drift)

---

*Erstellt von Wanda (UX Designer), Sheetstorm-Projekt. Version 2.0 — Komplette Überarbeitung.*
