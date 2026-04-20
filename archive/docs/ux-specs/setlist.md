# UX-Spec: Setlist-Verwaltung — Sheetstorm

> **Issue:** TBD — [UX] Setlist-Verwaltung — UX-Flows und Wireframes  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Referenzen:** `docs/feature-specs/setlist-spec.md`, `docs/ux-design.md §3.4`, `docs/ux-konfiguration.md`, `docs/ux-specs/spielmodus.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Konzept](#1-übersicht--konzept)
2. [User Flow: Setlist erstellen](#2-user-flow-setlist-erstellen)
3. [Builder-UI: Stücke hinzufügen & Drag & Drop](#3-builder-ui-stücke-hinzufügen--drag--drop)
4. [Platzhalter-Einträge](#4-platzhalter-einträge)
5. [Timing-Ansicht](#5-timing-ansicht)
6. [Setlist-Player-Modus](#6-setlist-player-modus)
7. [Setlist-Übersicht](#7-setlist-übersicht)
8. [Setlist bearbeiten & löschen](#8-setlist-bearbeiten--löschen)
9. [Responsive Verhalten](#9-responsive-verhalten)
10. [Navigation & Routing](#10-navigation--routing)
11. [Interaction Patterns](#11-interaction-patterns)
12. [Error States & Leerzustände](#12-error-states--leerzustände)
13. [Accessibility](#13-accessibility)
14. [Wireframes: Phone](#14-wireframes-phone)
15. [Wireframes: Tablet/Desktop](#15-wireframes-tabletdesktop)
16. [Abhängigkeiten](#16-abhängigkeiten)

---

## 1. Übersicht & Konzept

### 1.1 Das Kernproblem

Ein Dirigent plant ein Konzert: Er muss die Reihenfolge der Stücke festlegen, Timing kalkulieren, Pausen einplanen — und das alles so, dass am Konzerttag jeder Musiker mit einem Tap durch das gesamte Programm spielen kann, ohne manuell nach Noten zu suchen.

**Status Quo (ohne Sheetstorm):**
- Konzertprogramm als Word-Dokument
- Musiker bekommen Liste per E-Mail
- Im Konzert: Manuelles Suchen auf dem Tablet
- Timing in Excel berechnet
- Noch nicht eingescannte Stücke als "TODO" notiert

**Sheetstorm-Lösung:**
- Setlists = digitale, durchspielbare Programme
- Platzhalter für noch fehlende Noten
- Automatische Timing-Kalkulation
- Nahtloser Übergang im Spielmodus
- Keine Unterbrechung zwischen Stücken

### 1.2 Kern-Use-Cases

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | 1 Woche vor Konzert | Setlist zusammenstellen, Stücke sortieren, Timing prüfen |
| Notenwart | Während Setlist-Planung | Platzhalter für fehlende Noten eintragen, später ersetzen |
| Musiker | Konzerttag, Bühne | Setlist-Modus starten, durch Programm spielen ohne Suche |
| Admin | Nach Konzert | Aufführungsdaten für GEMA exportieren (separate Spec) |

### 1.3 Design-Prinzipien

| Prinzip | Konkrete Auswirkung |
|---------|---------------------|
| **Focus-First** | Setlist-Player hat keine ablenkenden UI-Elemente |
| **Touch-Native** | Drag-Handle ≥ 64×64 px, Long-Press auf Mobile |
| **Progressive Disclosure** | Timing-Features nur zeigen wenn benötigt |
| **No Restart** | Alle Änderungen sofort gespeichert (Auto-Save + Undo-Toast) |
| **Accessibility** | Drag & Drop auch per Keyboard (Tab + Pfeiltasten) |

### 1.4 Abgrenzung zu MS1

**MS1 (vorhanden):**
- Spielmodus für einzelne Stücke
- Stimmenauswahl
- Seitenwechsel-Mechanismen

**MS2 (neu):**
- Setlist-Verwaltung
- Setlist-Player mit nahtlosem Übergang
- Platzhalter ohne Stück-Referenz
- Timing-Kalkulation

---

## 2. User Flow: Setlist erstellen

```
Setlists-Tab → [+ Neue Setlist]
        │
        ▼
Formular (Modal/Sheet):
  - Name* (Pflicht)
  - Typ* (Konzert | Probe | Marschmusik)
  - Datum (optional)
  - Startzeit (optional, für Timing)
  - Beschreibung (optional, max. 500 Zeichen)
        │
        ▼
[Erstellen] → Auto-Save
        │
        ▼
Setlist-Detail-Ansicht (leer)
  → Ready für Stücke hinzufügen
```

### 2.1 Formular-Validierung

| Feld | Validierung | Fehlerfall |
|------|-------------|------------|
| Name | 1–120 Zeichen, nicht leer | "Name darf nicht leer sein" |
| Typ | Auswahl aus 3 Optionen | Immer gültig (Radio/Dropdown) |
| Datum | ISO 8601 Date, optional | Warnung wenn in Vergangenheit |
| Startzeit | HH:MM, optional | Validierung nur wenn gesetzt |
| Beschreibung | Max. 500 Zeichen | Zeichen-Counter |

### 2.2 Erstellen-Bestätigung

- **Kein** Bestätigungsdialog
- Sofort zur Setlist-Detail-Ansicht
- Toast: "Setlist '[Name]' erstellt" (3 Sekunden)
- Undo-Option im Toast für 8 Sekunden

---

## 3. Builder-UI: Stücke hinzufügen & Drag & Drop

### 3.1 Setlist-Detail-Ansicht (Builder)

```
PHONE (< 600px):
┌─────────────────────────────────┐
│ ← Setlists  Frühjahrskonzert   │
│  ✏️ [Bearbeiten]  ⋮             │
├─────────────────────────────────┤
│ 📅 15. Mai 2026 • 20:00         │
│ 🎵 Konzert • 8 Stücke • 1h 32min│
├─────────────────────────────────┤
│  [+ Stück]  [+ Platzhalter]     │
├─────────────────────────────────┤
│                                 │
│ ⋮⋮ 1. Böhmischer Traum          │  ← Drag-Handle links
│     Josef Strauß • 4:30         │    Komponist + Dauer
│                                 │
│ ⋮⋮ 2. Alte Kameraden            │
│     Carl Teike • 3:15           │
│                                 │
│ ⋮⋮ 3. 📌 Polka: Im Frühling     │  ← Platzhalter (Pin-Icon)
│     (Platzhalter) • 3:00        │
│                                 │
│ ⋮⋮ 4. Feuerwehrmarsch           │
│     Josef Blaha • 4:45          │
│                                 │
│ 💤 PAUSE (15 Min)               │  ← Pause-Eintrag (anders gestylt)
│                                 │
│ ⋮⋮ 5. Der Donauwalzer           │
│     ...                         │
│                                 │
│ [▶️ Setlist spielen]            │  ← Primäre Aktion
└─────────────────────────────────┘
```

### 3.2 Stück hinzufügen (Picker)

```
[+ Stück] → öffnet Noten-Picker Modal

┌─────────────────────────────────┐
│ Stück hinzufügen           ✕   │
├─────────────────────────────────┤
│ 🔍 Suche nach Titel...          │
├─────────────────────────────────┤
│                                 │
│ 📄 Böhmischer Traum             │  ← Thumbnail + Metadaten
│    Josef Strauß • Marsch        │    Tap zum Hinzufügen
│    [📎 Hinzufügen]              │
│                                 │
│ 📄 Alte Kameraden               │
│    Carl Teike • Marsch          │
│    [📎 Hinzufügen]              │
│                                 │
│ 📄 Auf der Vogelwiese           │
│    Josef Strauß • Polka         │
│    [📎 Hinzufügen]              │
│                                 │
│ ... (scrollbar)                 │
│                                 │
│ [Alle Noten durchsuchen →]     │
└─────────────────────────────────┘
```

**Picker-Features:**
- Suche (Echtzeit-Filter nach Titel/Komponist)
- Cursor-Pagination (30 Stücke pro Seite)
- Thumbnails (erste Seite als Preview)
- Mehrfach-Hinzufügen möglich (gleiches Stück = Zugabe)
- Tap auf Stück → sofort hinzugefügt an Ende der Setlist
- Picker bleibt offen für weitere Hinzufügungen
- [✕] oder Swipe-Down zum Schließen

### 3.3 Drag & Drop Umsortierung

**Touch (Mobile/Tablet):**
```
Long-Press auf ⋮⋮ Drag-Handle (600ms)
        │
        ▼
Eintrag hebt sich ab (elevation, opacity 0.9)
Andere Einträge zeigen Drop-Zonen (gestrichelte Linien)
        │ Drag-Bewegung
        ▼
Drop-Zone highlighted beim Hovern
        │ Loslassen
        ▼
Eintrag snapped in neue Position (smooth animation)
Auto-Save → Positionen in DB gespeichert
Toast: "Reihenfolge geändert" (mit Undo)
```

**Mouse (Desktop):**
```
Hover über ⋮⋮ → Cursor wird zum "grab"-Icon
Click + Drag → Element folgt Cursor
Drop → Wie Touch-Flow
```

**Keyboard (Accessibility):**
```
Tab → Fokus auf Eintrag
Enter → "Verschieben"-Modus aktiviert
↑/↓ → Eintrag nach oben/unten verschieben
Enter → Position bestätigen, Verschieben-Modus beenden
Esc → Abbrechen
```

### 3.4 Drag-Feedback

| Zustand | Visuelles Feedback |
|---------|-------------------|
| Idle | Drag-Handle dezent grau |
| Hover | Drag-Handle dunkler, Cursor: grab |
| Long-Press | Element hebt sich ab, opacity 0.9 |
| Dragging | Andere Einträge: Drop-Zonen (gestrichelte Linien) |
| Drop-Zone aktiv | Highlight (blauer Rahmen) |
| Drop | Smooth animation in neue Position (200ms ease-out) |

---

## 4. Platzhalter-Einträge

### 4.1 Konzept

Platzhalter sind Setlist-Einträge **ohne** Stück-Referenz. Sie ermöglichen vollständige Programmplanung, auch wenn Noten noch nicht digitalisiert sind.

**Use-Case:** Dirigent plant Konzert, aber "Polka: Im Frühling" liegt nur auf Papier beim Notenwart. Platzhalter wird eingetragen — später durch echtes Stück ersetzt.

### 4.2 Platzhalter hinzufügen

```
[+ Platzhalter] → öffnet Formular

┌─────────────────────────────────┐
│ Platzhalter hinzufügen     ✕   │
├─────────────────────────────────┤
│                                 │
│ Titel*                          │
│ [Polka: Im Frühling________]   │
│                                 │
│ Komponist (optional)            │
│ [Unbekannt_________________]    │
│                                 │
│ Geschätzte Dauer (optional)     │
│ [3:00_] oder [3_] Minuten       │
│                                 │
│ Notizen (optional)              │
│ [Noten liegen beim Dirigenten_] │
│ (max. 250 Zeichen)              │
│                                 │
│ [Abbrechen]  [Hinzufügen ✓]    │
└─────────────────────────────────┘
```

### 4.3 Platzhalter in Setlist

```
⋮⋮ 3. 📌 Polka: Im Frühling       ← Pin-Icon (distinguishes from real pieces)
    (Platzhalter) • 3:00
    Unbekannt
    [🔄 In Stück umwandeln]        ← Inline-Action
```

**Visuell unterscheidbar:**
- 📌 Pin-Icon statt 📄 Noten-Icon
- "(Platzhalter)"-Badge in Metadaten
- Grauer Text (opacity 0.7)
- [🔄 In Stück umwandeln]-Button

### 4.4 Platzhalter in Stück umwandeln

```
[🔄 In Stück umwandeln] → öffnet Noten-Picker
Picker zeigt alle Stücke
Tap auf Stück → Platzhalter wird ersetzt
Toast: "Platzhalter durch '[Stück]' ersetzt"
```

### 4.5 Platzhalter im Spielmodus

**Verhalten:** Platzhalter werden übersprungen mit Hinweis-Toast.

```
Spielmodus: Stück 2 (letztes echtes Stück)
       │
       ▼ Tap "Weiter" oder Swipe
       ▼
Platzhalter erkannt
       │
       ▼
Toast (4 Sekunden, mittig):
┌────────────────────────────────┐
│ ℹ️ „Polka: Im Frühling" noch  │
│ nicht digitalisiert            │
│ → Überspringe zu nächstem Stück│
└────────────────────────────────┘
       │
       ▼
Automatischer Sprung zu Stück 4 (nächstes echtes Stück)
```

---

## 5. Timing-Ansicht

### 5.1 Konzept

Setlists können eine **Startzeit** haben (z.B. "20:00"). Basierend auf geschätzten Dauern pro Eintrag berechnet das System automatisch Start- und Endzeiten für jedes Stück.

**Kernwert:** Dirigenten wissen genau, wann welches Stück gespielt wird — wichtig für Veranstalter, Pausen, Logistik.

### 5.2 Timing aktivieren

```
Setlist-Detail → [⚙️ Bearbeiten] → Startzeit eingeben

Startzeit:  [20:00_] (HH:MM)
[■ Timing-Ansicht anzeigen]   ← Toggle

→ Wenn aktiviert: Timing-Spalten erscheinen
```

### 5.3 Timing-Ansicht (Phone)

```
Mit Startzeit: 20:00
┌─────────────────────────────────┐
│ Frühjahrskonzert 2026           │
│ Startzeit: 20:00 • Gesamt: 1h 32min│
│ ─────────────────────────────── │
│ [■ Timing anzeigen]   ✓         │  ← Toggle
├─────────────────────────────────┤
│                                 │
│ ⋮⋮ 1. Böhmischer Traum          │
│     20:00 – 20:04 (4 Min)      │  ← Berechnete Zeiten
│     [Dauer: 4:30__]            │  ← Editierbar
│                                 │
│ ⋮⋮ 2. Alte Kameraden            │
│     20:04 – 20:08 (3 Min)      │
│     [Dauer: 3:15__]            │
│                                 │
│ ⋮⋮ 3. 📌 Polka: Im Frühling     │
│     20:08 – 20:11 (3 Min)      │
│     [Dauer: 3:00__]            │
│                                 │
│ 💤 PAUSE                        │
│     20:11 – 20:26 (15 Min)     │
│     [Dauer: 15__]              │
│                                 │
│ ⋮⋮ 4. Feuerwehrmarsch           │
│     20:26 – 20:31 (5 Min)      │
│     [Dauer: 4:45__]            │
│                                 │
│ ...                             │
└─────────────────────────────────┘
```

### 5.4 Pause-Einträge

**Spezialtyp:** Keine Stück-Referenz, nur für Timing.

```
[+ Pause] → öffnet Formular

┌─────────────────────────────────┐
│ Pause hinzufügen           ✕   │
├─────────────────────────────────┤
│ Dauer (Minuten)                 │
│ [15_]                           │
│                                 │
│ Beschreibung (optional)         │
│ [Getränke im Foyer_________]    │
│                                 │
│ [Abbrechen]  [Hinzufügen ✓]    │
└─────────────────────────────────┘
```

**Darstellung:**
```
💤 PAUSE (15 Min)
   Getränke im Foyer
   20:11 – 20:26
```

### 5.5 Timing-Kalkulation Logik

```
Startzeit = 20:00 (Setlist-Startzeit)
Position 1: Start = 20:00, Dauer = 4:30 → Ende = 20:04
Position 2: Start = 20:04 (= Ende von Position 1), Dauer = 3:15 → Ende = 20:08
Position 3: Start = 20:08, Dauer = 3:00 → Ende = 20:11
Position 4 (Pause): Start = 20:11, Dauer = 15:00 → Ende = 20:26
Position 5: Start = 20:26, Dauer = 4:45 → Ende = 20:31
...
Gesamtdauer = Summe aller Dauern = 1h 32min
Endzeit = 20:00 + 1h 32min = 21:32
```

### 5.6 Fehlende Dauer

Wenn für einen Eintrag keine Dauer eingegeben ist:

```
⋮⋮ 5. Der Donauwalzer
    20:26 – ? (Dauer fehlt)       ← ? statt Endzeit
    [Dauer: ___] (leer)           ← Input-Feld mit Warnung
    ⚠️ Dauer eingeben für Timing
```

**Timing-Kalkulation stoppt** an dieser Stelle — nachfolgende Einträge zeigen keine Zeiten.

---

## 6. Setlist-Player-Modus

### 6.1 Konzept

Der Setlist-Player erweitert den MS1-Spielmodus um **nahtlose Navigation** durch alle Stücke einer Setlist — ohne manuelle Suche, ohne Unterbrechung.

**Unterschied zu normalem Spielmodus:**
- Automatischer Übergang zum nächsten Stück (optional)
- Progress-Indikator "Stück 3 von 12"
- Schnellnavigation zur Setlist-Übersicht
- Preloading der nächsten Seiten

### 6.2 Flow: Setlist-Player starten

```
Setlist-Detail → [▶️ Setlist spielen]
        │
        ▼
Spielmodus startet mit Stück 1
(Erste Seite, korrekte Stimme wie in MS1)
        │
        ▼
Zusätzliche Navigation:
  - ⏮ Vorheriges Stück
  - ⏭ Nächstes Stück
  - Progress: "Stück 3 von 12"
```

### 6.3 Setlist-Player UI (Phone)

```
VOLLBILD (wie MS1 Spielmodus):
┌─────────────────────────────────┐
│ ← Zurück  🎵 Stück 3/12   ⚙️   │  ← Obere Leiste (Overlay)
├─────────────────────────────────┤
│                                 │
│     N O T E N B L A T T        │
│                                 │
│     (Vollbild, 0px Padding)     │
│                                 │
├─────────────────────────────────┤
│ ⏮ ⏸ ⏭ | 🎵 Stimme  🌙  🔒    │  ← Untere Leiste (Overlay)
└─────────────────────────────────┘
   ↑ NEU in Setlist-Player
```

**Neue Elemente:**
- **Progress "Stück 3/12"** — Tap öffnet Setlist-Schnellnavigation
- **⏮ ⏭ Buttons** — Vorheriges/Nächstes Stück

### 6.4 Setlist-Schnellnavigation

```
Tap auf "Stück 3/12" → öffnet Sheet

┌─────────────────────────────────┐
│ Setlist-Navigation         ✕   │
│ Frühjahrskonzert 2026           │
├─────────────────────────────────┤
│                                 │
│  1  Böhmischer Traum            │
│  2  Alte Kameraden              │
│ ▶ 3  Auf der Vogelwiese   ← Aktuell │  ← Highlighted
│  4  Feuerwehrmarsch             │
│  💤 PAUSE                       │  ← Ausgegraut, nicht anklickbar
│  5  Der Donauwalzer             │
│  6  Märchenwalzer               │
│  ...                            │
│ 12  Finale                      │
│                                 │
└─────────────────────────────────┘
```

**Verhalten:**
- Tap auf Stück → sofortiger Wechsel, Sheet schließt sich
- Aktuelles Stück highlighted (blauer Hintergrund)
- Platzhalter ausgegraut (nicht klickbar, mit Hinweis-Icon)
- Pausen ausgegraut (keine Noten)
- Auto-Scroll zum aktuellen Stück

### 6.5 Automatischer Übergang

**Optionales Feature** (konfigurierbar in Einstellungen):

```
Einstellungen → Nutzer → Spielmodus
[■ Auto-Wechsel bei Setlists]
```

**Verhalten:**
```
Letzte Seite von Stück 3 erreicht
        │
        ▼ Tap "Weiter" oder Swipe
        ▼
Sanfte Animation (200ms fade)
        │
        ▼
Erste Seite von Stück 4 geladen
(Preloading = keine Wartezeit)
```

**Visuelles Feedback:**
```
Bei Auto-Wechsel: Kurzer Toast (1 Sekunde)
┌─────────────────────────────┐
│ → Nächstes Stück: [Titel]   │
└─────────────────────────────┘
```

### 6.6 Preloading

**Ziel:** Übergang < 200ms

**Strategie:**
- Nächstes Stück lädt im Hintergrund, sobald aktuelles Stück zu 50% durchgespielt ist
- Erste 2 Seiten gecacht (für schnellen Start)
- Stimme automatisch vorausgewählt (wie in MS1)

### 6.7 Platzhalter im Player

```
Stück 3 → Tap "Weiter"
        │
        ▼
Stück 4 = Platzhalter
        │
        ▼
Toast (4 Sekunden):
┌────────────────────────────────┐
│ ℹ️ „Polka: Im Frühling" noch  │
│ nicht digitalisiert            │
│ → Überspringe zu Stück 5       │
└────────────────────────────────┘
        │
        ▼
Automatischer Sprung zu Stück 5
```

### 6.8 Ende der Setlist

```
Letztes Stück, letzte Seite → Tap "Weiter"
        │
        ▼
Fullscreen-Overlay (2 Sekunden):
┌─────────────────────────────────┐
│                                 │
│       🎉                        │
│   Ende der Setlist              │
│   Frühjahrskonzert 2026         │
│                                 │
│   [← Zurück zur Setlist]        │
│   [🔁 Nochmal abspielen]        │
│                                 │
└─────────────────────────────────┘
```

---

## 7. Setlist-Übersicht

### 7.1 Setlists-Tab (Phone)

```
┌─────────────────────────────────┐
│ 🏛 [Kapelle ▼]    🔍  [+ Neu]  │  ← Header mit Kapellen-Switcher
├─────────────────────────────────┤
│ [Alle ▼] [Sortierung: Datum ▼] │  ← Filter + Sortierung
├─────────────────────────────────┤
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Frühjahrskonzert 2026    ││ ← Setlist-Kachel
│ │ Konzert • 15. Mai 2026      ││
│ │ 12 Stücke • 1h 32min        ││
│ │ ─────────────────────────── ││
│ │ [▶️ Spielen]    [⋮]         ││ ← Quick-Actions
│ └─────────────────────────────┘│
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Probenvorbereitung       ││
│ │ Probe • 3. April 2026       ││
│ │ 8 Stücke • 45min            ││
│ │ ─────────────────────────── ││
│ │ [▶️ Spielen]    [⋮]         ││
│ └─────────────────────────────┘│
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Festumzug Stadtfest      ││  ← Vergangene (gedimmt)
│ │ Marschmusik • 12. März 2026 ││
│ │ 6 Stücke • 35min            ││
│ │ ─────────────────────────── ││
│ │ [▶️ Spielen]    [⋮]         ││
│ └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### 7.2 Filter & Sortierung

```
[Alle ▼] → öffnet Dropdown

┌─────────────────────────────┐
│ Filtern nach Typ            │
├─────────────────────────────┤
│ ✓ Alle                      │
│   Konzert                   │
│   Probe                     │
│   Marschmusik               │
│ ─────────────────────────── │
│ Zeitraum                    │
│ ○ Alle                      │
│ ● Zukünftig                 │
│ ○ Vergangen                 │
└─────────────────────────────┘
```

```
[Sortierung: Datum ▼] → öffnet Dropdown

┌─────────────────────────────┐
│ Sortieren nach              │
├─────────────────────────────┤
│ ● Datum (neueste zuerst)    │
│   Datum (älteste zuerst)    │
│   Name (A-Z)                │
│   Name (Z-A)                │
└─────────────────────────────┘
```

### 7.3 Setlist-Kachel (Detail)

**Aufbau:**
```
┌─────────────────────────────────┐
│ 🎵 [Name der Setlist]           │  ← Typ-Icon + Name
│ [Typ] • [Datum]                 │  ← Metadaten
│ [Anzahl] Stücke • [Dauer]       │
│ ─────────────────────────────── │
│ [▶️ Spielen]    [⋮]             │  ← Primäre + Sekundäre Aktionen
└─────────────────────────────────┘
```

**Typ-Icons:**
- 🎵 Konzert (rot)
- 🎼 Probe (blau)
- 🎺 Marschmusik (orange)

**Vergangene Setlists:**
- Opacity 0.6
- Kein "Spielen"-Button → stattdessen "Details anzeigen"

### 7.4 Suche

```
Tap auf 🔍 → öffnet Suchfeld

┌─────────────────────────────────┐
│ ← [Suche nach Name...______]   │
├─────────────────────────────────┤
│ Ergebnisse (3)                  │
│                                 │
│ 🎵 Frühjahrskonzert 2026        │
│ 🎵 Frühjahrsmarsch 2025         │
│ 🎵 Frühjahrskonzert 2024        │
└─────────────────────────────────┘
```

**Suche-Verhalten:**
- Echtzeit-Filter (Client-seitig wenn < 100 Setlists)
- Sucht in Name + Beschreibung
- Minimal 2 Zeichen für Suche

### 7.5 Leerzustand

```
┌─────────────────────────────────┐
│                                 │
│       🎵                        │
│                                 │
│   Noch keine Setlists           │
│                                 │
│   Erstelle deine erste Setlist  │
│   für Proben oder Konzerte.     │
│                                 │
│   [+ Neue Setlist erstellen]    │
│                                 │
└─────────────────────────────────┘
```

---

## 8. Setlist bearbeiten & löschen

### 8.1 Bearbeiten-Modus

```
Setlist-Detail → [✏️ Bearbeiten] → Formular

┌─────────────────────────────────┐
│ ← Abbrechen   Bearbeiten        │
├─────────────────────────────────┤
│ Name                            │
│ [Frühjahrskonzert 2026_____]   │
│                                 │
│ Typ                             │
│ ● Konzert  ○ Probe  ○ Marsch   │
│                                 │
│ Datum                           │
│ [15.05.2026____]               │
│                                 │
│ Startzeit                       │
│ [20:00_]                       │
│                                 │
│ Beschreibung                    │
│ [Traditionelles Konzert_____]  │
│ (max. 500 Zeichen)              │
│                                 │
│ [Speichern ✓]                  │
└─────────────────────────────────┘
```

**Auto-Save + Undo:**
- Änderungen sofort gespeichert beim Verlassen des Feldes
- Toast: "Änderungen gespeichert" (mit Undo, 8 Sekunden)

### 8.2 Duplizieren

```
Setlist-Detail → [⋮] → [Duplizieren]

Erstellt Kopie mit:
- Name: "[Original-Name] (Kopie)"
- Alle Einträge identisch
- Neue ID
- Erstellt-von: Aktueller Nutzer

Toast: "Setlist dupliziert" → Tap öffnet neue Setlist
```

### 8.3 Löschen

```
Setlist-Detail → [⋮] → [Löschen]

Sicherheitsabfrage:
┌─────────────────────────────────┐
│ Setlist löschen?                │
├─────────────────────────────────┤
│ „Frühjahrskonzert 2026"         │
│ wirklich löschen?               │
│                                 │
│ Diese Aktion kann nicht         │
│ rückgängig gemacht werden.      │
│                                 │
│ Verknüpfte Termine zeigen       │
│ dann „Setlist gelöscht".        │
│                                 │
│ [Abbrechen]  [Löschen ✓]       │
└─────────────────────────────────┘
```

**Nach Löschen:**
- Zurück zur Setlist-Übersicht
- Toast: "Setlist gelöscht" (keine Undo-Option)
- Audit-Log: Wer hat wann gelöscht

---

## 9. Responsive Verhalten

### 9.1 Breakpoints

| Viewport | Layout-Anpassungen |
|----------|-------------------|
| **Phone (< 600px)** | Single-Column, Bottom-Buttons, Long-Press Drag |
| **Tablet (600–1024px)** | Two-Column-Grid (Setlist-Übersicht), Drag-Handle sichtbar |
| **Desktop (> 1024px)** | Three-Column-Grid, Sidebar-Navigation, Mouse-Drag |

### 9.2 Tablet: Setlist-Übersicht

```
TABLET (Landscape, 768×1024):
┌─────────────────────────────────────────────────────────────┐
│ 🏛 [Kapelle ▼]  Setlists         🔍  [Filter ▼]  [+ Neu]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌──────────────────┐  ┌──────────────────┐                │
│ │ 🎵 Frühjahrs-    │  │ 🎵 Probenvorbr.  │                │
│ │    konzert 2026  │  │ Probe • 3. Apr   │                │
│ │ Konzert • 15. Mai│  │ 8 Stücke • 45min │                │
│ │ 12 Stücke • 1h32 │  │ [▶️ Spielen] [⋮] │                │
│ │ [▶️ Spielen] [⋮] │  └──────────────────┘                │
│ └──────────────────┘                                       │
│                                                             │
│ ┌──────────────────┐  ┌──────────────────┐                │
│ │ 🎵 Festumzug     │  │ ...              │                │
│ │ ...              │  │                  │                │
│ └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### 9.3 Desktop: Setlist-Detail (Sidebar)

```
DESKTOP (1440×900):
┌────────┬──────────────────────────────────────────────┐
│ SIDE   │ Frühjahrskonzert 2026                        │
│ BAR    │ ✏️ [Bearbeiten]  [⋮ Mehr]  [▶️ Spielen]     │
│        ├──────────────────────────────────────────────┤
│ 📚 Bib │ 📅 15. Mai 2026 • 20:00 Uhr                  │
│ 🎵 Set │ 🎵 Konzert • 12 Stücke • Gesamt: 1h 32min    │
│ 📅 Kal │ ──────────────────────────────────────────── │
│        │ [+ Stück]  [+ Platzhalter]  [+ Pause]       │
│        ├──────────────────────────────────────────────┤
│        │                                              │
│        │ ⋮⋮ 1. Böhmischer Traum        20:00 – 20:04 │  ← Wide Table
│        │     Josef Strauß • 4:30        [Dauer: 4:30]│
│        │                                              │
│        │ ⋮⋮ 2. Alte Kameraden           20:04 – 20:08 │
│        │     Carl Teike • 3:15          [Dauer: 3:15]│
│        │                                              │
│        │ ⋮⋮ 3. 📌 Polka: Im Frühling    20:08 – 20:11 │
│        │     (Platzhalter) • 3:00       [🔄 Umwand.] │
│        │                                              │
│        │ ...                                          │
└────────┴──────────────────────────────────────────────┘
```

---

## 10. Navigation & Routing

### 10.1 URL-Schema

```
/setlists                    → Setlist-Übersicht
/setlists/new                → Neue Setlist erstellen
/setlists/{id}               → Setlist-Detail
/setlists/{id}/edit          → Setlist bearbeiten
/setlists/{id}/play          → Setlist-Player starten
/setlists/{id}/play/{pieceId}→ Setlist-Player mit spezifischem Stück
```

### 10.2 Bottom-Navigation (Phone)

```
┌─────────────────────────────────┐
│ [📚 Bibliothek] [🎵 Setlists]  │  ← Setlist-Tab neu in MS2
│ [📅 Kalender] [👤 Profil]       │
└─────────────────────────────────┘
```

**Setlist-Tab ist zweiter Tab** (nach Bibliothek) — hohe Priorität.

### 10.3 Deep-Links

```
sheetstorm://setlists/{id}              → Öffnet Setlist-Detail
sheetstorm://setlists/{id}/play         → Startet Setlist-Player
sheetstorm://setlists/{id}/play/3       → Startet Player bei Stück 3
```

---

## 11. Interaction Patterns

### 11.1 Auto-Save + Undo-Toast

**Prinzip:** Keine "Speichern"-Buttons — Änderungen sofort persistiert.

```
Änderung (z.B. Drag & Drop)
        │
        ▼
API-Call (POST /positions)
        │
        ▼ Success
        ▼
Toast (8 Sekunden):
┌────────────────────────────┐
│ ✓ Reihenfolge geändert     │
│   [Rückgängig]             │
└────────────────────────────┘
        │ Tap [Rückgängig]
        ▼
API-Call (POST /positions mit alten Werten)
Toast: "Änderung rückgängig gemacht"
```

### 11.2 Long-Press Context Menu (Mobile)

```
Long-Press auf Setlist-Eintrag (z.B. in Liste)
        │
        ▼
Context-Menu (Bottom Sheet):
┌─────────────────────────────┐
│ Böhmischer Traum            │
├─────────────────────────────┤
│ 🎵 Stimme anzeigen          │
│ 🎵 Noten öffnen             │
│ ⏱️ Dauer bearbeiten         │
│ 🗑️ Aus Setlist entfernen    │
│ ✕ Abbrechen                 │
└─────────────────────────────┘
```

### 11.3 Swipe-Geste (iOS/Android)

```
Swipe left auf Setlist-Eintrag:
┌─────────────────────────────┐
│ ⋮⋮ Böhmischer Traum    [🗑️] │  ← Löschen-Button erscheint
└─────────────────────────────┘
```

---

## 12. Error States & Leerzustände

### 12.1 Leerzustände

| Kontext | Leerzustand |
|---------|-------------|
| Setlist-Übersicht | "Noch keine Setlists. [+ Neue Setlist erstellen]" |
| Setlist-Detail (keine Einträge) | "Noch keine Stücke. [+ Stück hinzufügen]" |
| Noten-Picker (keine Noten) | "Noch keine Noten in der Bibliothek. [→ Noten importieren]" |
| Setlist-Schnellnavigation (nur Platzhalter) | "Alle Stücke sind Platzhalter — bitte Noten hinzufügen." |

### 12.2 Error States

| Fehler | Anzeige | Recovery |
|--------|---------|----------|
| Setlist-Name leer | "Name darf nicht leer sein" (unter Input) | Input fokussieren |
| Dauer ungültig | "Bitte gültige Dauer eingeben (z.B. 3:45)" | Input fokussieren |
| Stück nicht verfügbar | "Stück wurde gelöscht" + [Aus Setlist entfernen] | Manuelles Entfernen |
| Netzwerkfehler beim Speichern | Toast: "Speichern fehlgeschlagen. Erneut versuchen?" + [Wiederholen] | Retry-Button |
| Setlist gelöscht (während Bearbeitung) | "Diese Setlist existiert nicht mehr" → Zurück zur Übersicht | — |

### 12.3 Offline-Verhalten

```
Keine Internetverbindung:
┌────────────────────────────────┐
│ ⚠️ Offline                     │
│ Änderungen werden gespeichert, │
│ sobald Verbindung besteht.     │
└────────────────────────────────┘
```

**Offline-Fähigkeit:**
- Setlist-Anzeige funktioniert (gecachte Daten)
- Änderungen werden lokal gespeichert
- Sync bei Verbindung

---

## 13. Accessibility

### 13.1 Keyboard-Navigation

| Kontext | Keyboard-Shortcuts |
|---------|-------------------|
| Setlist-Übersicht | Tab: Fokus auf Kacheln, Enter: Öffnen |
| Setlist-Detail | Tab: Fokus auf Einträge, Enter: Verschiebe-Modus |
| Drag & Drop | Enter: Verschieben aktivieren, ↑/↓: Bewegen, Enter: Bestätigen |
| Setlist-Player | ←/→: Seite wechseln, Shift+←/→: Stück wechseln, Esc: Zurück |

### 13.2 Screen Reader

**Semantisches HTML:**
- `<nav>` für Bottom-Navigation
- `<main>` für Setlist-Detail
- `<article>` für Setlist-Kacheln
- `<button>` statt `<div>` für Aktionen

**Aria-Labels:**
```html
<button aria-label="Setlist 'Frühjahrskonzert 2026' spielen">
  ▶️ Spielen
</button>

<div role="listitem" aria-label="Stück 3 von 12: Böhmischer Traum, Josef Strauß, Dauer 4:30">
  ...
</div>
```

### 13.3 Touch-Targets

| Element | Mindestgröße |
|---------|-------------|
| Drag-Handle | 64×64 px |
| Buttons (Primär) | 48×48 px |
| Buttons (Sekundär) | 44×44 px |
| List-Items (tappable) | Min. 48 px Höhe |

### 13.4 Kontrast

| Kontext | Kontrast-Ratio |
|---------|---------------|
| Text auf Hintergrund | ≥ 4.5:1 (WCAG AA) |
| Icons | ≥ 3:1 (WCAG AA) |
| Platzhalter (grauer Text) | ≥ 3:1 (noch lesbar) |
| Disabled Elements | 2:1 (erkennbar als disabled) |

---

## 14. Wireframes: Phone

### 14.1 Phone — Setlist-Übersicht

```
┌─────────────────────────────────┐
│ 🏛 [Kapelle ▼]    🔍  [+ Neu]  │
├─────────────────────────────────┤
│ [Alle ▼] [Sortierung: Datum ▼] │
├─────────────────────────────────┤
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Frühjahrskonzert 2026    ││
│ │ Konzert • 15. Mai 2026      ││
│ │ 12 Stücke • 1h 32min        ││
│ │ ─────────────────────────── ││
│ │ [▶️ Spielen]    [⋮]         ││
│ └─────────────────────────────┘│
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Probenvorbereitung       ││
│ │ Probe • 3. April 2026       ││
│ │ 8 Stücke • 45min            ││
│ │ ─────────────────────────── ││
│ │ [▶️ Spielen]    [⋮]         ││
│ └─────────────────────────────┘│
│                                 │
│ ┌─────────────────────────────┐│
│ │ 🎵 Festumzug Stadtfest      ││
│ │ Marschmusik • 12. März 2026 ││
│ │ 6 Stücke • 35min (vergangen)││
│ │ ─────────────────────────── ││
│ │ [Details]       [⋮]         ││
│ └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
│ [📚 Bibl.][🎵 Setl.][📅][👤]  │  ← Bottom-Nav
└─────────────────────────────────┘
```

### 14.2 Phone — Setlist-Detail (Builder)

```
┌─────────────────────────────────┐
│ ← Setlists  Frühjahrskonzert   │
│  ✏️ [Bearbeiten]  ⋮             │
├─────────────────────────────────┤
│ 📅 15. Mai 2026 • 20:00         │
│ 🎵 Konzert • 12 Stücke • 1h32min│
│ ─────────────────────────────── │
│ [■ Timing anzeigen]   ✓         │
├─────────────────────────────────┤
│  [+ Stück]  [+ Platzhalter]     │
├─────────────────────────────────┤
│                                 │
│ ⋮⋮ 1. Böhmischer Traum          │
│     Josef Strauß • 4:30         │
│     20:00 – 20:04               │
│                                 │
│ ⋮⋮ 2. Alte Kameraden            │
│     Carl Teike • 3:15           │
│     20:04 – 20:08               │
│                                 │
│ ⋮⋮ 3. 📌 Polka: Im Frühling     │
│     (Platzhalter) • 3:00        │
│     20:08 – 20:11               │
│     [🔄 In Stück umwandeln]     │
│                                 │
│ ⋮⋮ 4. Feuerwehrmarsch           │
│     Josef Blaha • 4:45          │
│     20:11 – 20:16               │
│                                 │
│ 💤 PAUSE (15 Min)               │
│     20:16 – 20:31               │
│                                 │
│ ⋮⋮ 5. Der Donauwalzer           │
│     ...                         │
│                                 │
├─────────────────────────────────┤
│ [▶️ Setlist spielen]            │
└─────────────────────────────────┘
```

### 14.3 Phone — Noten-Picker (Stück hinzufügen)

```
┌─────────────────────────────────┐
│ Stück hinzufügen           ✕   │
├─────────────────────────────────┤
│ 🔍 [Suche nach Titel...____]   │
├─────────────────────────────────┤
│                                 │
│ 📄 Böhmischer Traum             │
│    Josef Strauß • Marsch        │
│    [Hinzufügen]                 │
│                                 │
│ 📄 Alte Kameraden               │
│    Carl Teike • Marsch          │
│    [Hinzufügen]                 │
│                                 │
│ 📄 Auf der Vogelwiese           │
│    Josef Strauß • Polka         │
│    [Hinzufügen]                 │
│                                 │
│ 📄 Feuerwehrmarsch              │
│    Josef Blaha • Marsch         │
│    [Hinzufügen]                 │
│                                 │
│ ... (scrollbar)                 │
│                                 │
│ [→ Alle Noten durchsuchen]     │
└─────────────────────────────────┘
```

### 14.4 Phone — Platzhalter hinzufügen

```
┌─────────────────────────────────┐
│ Platzhalter hinzufügen     ✕   │
├─────────────────────────────────┤
│                                 │
│ Titel*                          │
│ [Polka: Im Frühling________]   │
│                                 │
│ Komponist (optional)            │
│ [Unbekannt_________________]    │
│                                 │
│ Geschätzte Dauer (optional)     │
│ [3:00_] oder [3_] Minuten       │
│                                 │
│ Notizen (optional)              │
│ [Noten beim Dirigenten_____]    │
│ (max. 250 Zeichen)              │
│                                 │
│ [Abbrechen]  [Hinzufügen ✓]    │
└─────────────────────────────────┘
```

### 14.5 Phone — Setlist-Player (Overlay sichtbar)

```
┌─────────────────────────────────┐
│ ← Zurück  🎵 Stück 3/12   ⚙️   │
├─────────────────────────────────┤
│                                 │
│     N O T E N B L A T T        │
│                                 │
│     (Vollbild, 0px Padding)     │
│                                 │
│     Böhmischer Traum            │
│     Josef Strauß                │
│                                 │
├─────────────────────────────────┤
│ ⏮ ⏸ ⏭ | 🎵 Stimme  🌙  🔒    │
└─────────────────────────────────┘
```

### 14.6 Phone — Setlist-Schnellnavigation

```
┌─────────────────────────────────┐
│ Setlist-Navigation         ✕   │
│ Frühjahrskonzert 2026           │
├─────────────────────────────────┤
│                                 │
│  1  Böhmischer Traum            │
│  2  Alte Kameraden              │
│ ▶ 3  Auf der Vogelwiese  ← Aktuell│  ← Highlighted
│  4  Feuerwehrmarsch             │
│  💤 PAUSE (15 Min)              │  ← Ausgegraut
│  5  Der Donauwalzer             │
│  6  Märchenwalzer               │
│  7  📌 Polka: Im Frühling       │  ← Platzhalter ausgegraut
│  8  Finale                      │
│                                 │
└─────────────────────────────────┘
```

---

## 15. Wireframes: Tablet/Desktop

### 15.1 Tablet — Setlist-Übersicht (Two-Column Grid)

```
TABLET (768×1024, Landscape):
┌─────────────────────────────────────────────────────────────┐
│ 🏛 [Kapelle ▼]  Setlists         🔍  [Filter ▼]  [+ Neu]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌──────────────────────┐  ┌──────────────────────┐        │
│ │ 🎵 Frühjahrskonzert  │  │ 🎵 Probenvorbereitung │        │
│ │    2026              │  │ Probe • 3. April 2026 │        │
│ │ Konzert • 15. Mai    │  │ 8 Stücke • 45min      │        │
│ │ 12 Stücke • 1h 32min │  │ [▶️ Spielen] [⋮ Mehr] │        │
│ │ [▶️ Spielen] [⋮ Mehr]│  └──────────────────────┘        │
│ └──────────────────────┘                                   │
│                                                             │
│ ┌──────────────────────┐  ┌──────────────────────┐        │
│ │ 🎵 Festumzug         │  │ 🎵 Weihnachtskonzert │        │
│ │ Marschmusik • 12. März│  │ Konzert • 20. Dez    │        │
│ │ 6 Stücke • 35min     │  │ 15 Stücke • 2h 10min │        │
│ │ [Details] [⋮ Mehr]   │  │ [▶️ Spielen] [⋮ Mehr]│        │
│ └──────────────────────┘  └──────────────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 15.2 Desktop — Setlist-Detail (Table Layout)

```
DESKTOP (1440×900):
┌─────┬───────────────────────────────────────────────────────┐
│ NAV │ Frühjahrskonzert 2026                                 │
│     │ ✏️ [Bearbeiten] [⋮ Mehr] [▶️ Setlist spielen]        │
│ 📚  ├───────────────────────────────────────────────────────┤
│ 🎵  │ 📅 15. Mai 2026 • 20:00 Uhr                          │
│ 📅  │ 🎵 Konzert • 12 Stücke • Gesamt: 1h 32min            │
│ 👤  │ ─────────────────────────────────────────────────────│
│     │ [+ Stück]  [+ Platzhalter]  [+ Pause]                │
│     ├───────────────────────────────────────────────────────┤
│     │                                                       │
│     │ # │ Titel             │ Komponist │ Dauer │ Timing   │
│     │ ─────────────────────────────────────────────────────│
│     │ ⋮⋮ 1 Böhmischer Traum  Josef S.   4:30   20:00-20:04│
│     │ ⋮⋮ 2 Alte Kameraden    Carl T.    3:15   20:04-20:08│
│     │ 📌 3 Polka: Im Frühl.  (Platzh.)  3:00   20:08-20:11│
│     │      [🔄 In Stück umwandeln]                         │
│     │ ⋮⋮ 4 Feuerwehrmarsch   Josef B.   4:45   20:11-20:16│
│     │ 💤   PAUSE (15 Min)                15:00  20:16-20:31│
│     │ ⋮⋮ 5 Der Donauwalzer   ...         ...   ...         │
│     │ ...                                                   │
│     │                                                       │
└─────┴───────────────────────────────────────────────────────┘
```

### 15.3 Tablet — Setlist-Player (Querformat, Two-Page)

```
TABLET (1024×768, Landscape):
┌─────────────────────────────────────────────────────────────┐
│ ← Zurück  🎵 Stück 3/12 — Böhmischer Traum  ⚙️             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────┐  ┌────────────────┐                   │
│  │                │  │                │                   │
│  │   SEITE 2      │  │   SEITE 3      │                   │
│  │                │  │                │                   │
│  │   (Noten)      │  │   (Noten)      │                   │
│  │                │  │                │                   │
│  │                │  │                │                   │
│  │                │  │                │                   │
│  └────────────────┘  └────────────────┘                   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ ⏮ Zurück │ ⏸ Pause │ ⏭ Weiter │ 🎵 Stimme │ 🌙 │ 🔒      │
└─────────────────────────────────────────────────────────────┘
```

---

## 16. Abhängigkeiten

### 16.1 MS1-Features (vorhanden)

- Spielmodus (Vollbild-Notenansicht)
- Stimmenauswahl-Logik
- Seitenwechsel-Mechanismen
- Auto-Rotation & Auto-Zoom
- PDF-Rendering

### 16.2 MS2-Features (parallel entwickelt)

- Konzertplanung (Termin ↔ Setlist-Verknüpfung)
- GEMA-Export (separate Spec)

### 16.3 Backend-Abhängigkeiten

- `/api/v1/kapellen/{id}/setlists` — CRUD-Endpoints
- `/api/v1/setlists/{id}/entries` — Setlist-Einträge
- `/api/v1/setlists/{id}/entries/positions` — Drag & Drop

### 16.4 Frontend-Abhängigkeiten

- Drag & Drop Library (z.B. `flutter_reorderable_list`)
- Datetime-Picker (für Datum/Startzeit)
- PDF-Viewer mit Preloading-Support

---

**Ende der UX-Spec: Setlist-Verwaltung**
