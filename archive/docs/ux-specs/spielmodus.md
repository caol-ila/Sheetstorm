# UX-Spec: Spielmodus — Sheetstorm

> **Issue:** #24 — [UX] Spielmodus — UX-Flows und Wireframes  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M1 — Kern: Noten & Kapelle  
> **Referenzen:** `docs/ux-design.md §3.1`, `docs/ux-konfiguration.md §8`, `docs/decisions.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [User Flow: Spielmodus starten](#2-user-flow-spielmodus-starten)
3. [Vollbild-Notenansicht (Focus-First)](#3-vollbild-notenansicht-focus-first)
4. [Seitenwechsel-Mechanismen](#4-seitenwechsel-mechanismen)
5. [Half-Page-Turn](#5-half-page-turn)
6. [Auto-Rotation & Auto-Zoom](#6-auto-rotation--auto-zoom)
7. [Overlay & Quick-Access](#7-overlay--quick-access)
8. [Stimme wechseln](#8-stimme-wechseln)
9. [Setlist-Navigation](#9-setlist-navigation)
10. [Annotationen Toggle](#10-annotationen-toggle)
11. [Nacht-/Bühnenmodus](#11-nacht--bühnenmodus)
12. [Kontextuelle Einstellungen](#12-kontextuelle-einstellungen)
13. [Fußpedal (Bluetooth)](#13-fußpedal-bluetooth)
14. [Spielmodus sperren (UI-Lock)](#14-spielmodus-sperren-ui-lock)
15. [Wireframes: Phone](#15-wireframes-phone)
16. [Wireframes: Tablet](#16-wireframes-tablet)
17. [Interaction Patterns & Edge Cases](#17-interaction-patterns--edge-cases)
18. [Abhängigkeiten](#18-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Das Notenblatt ist der Bildschirm. UI existiert nicht — bis der Musiker es braucht."

Der Spielmodus ist der wichtigste Modus von Sheetstorm. Alle anderen Features sind Support. Im Spielmodus gilt: **Focus-First** — Ablenkung ist verboten.

### 1.2 Geltende Designprinzipien

| Prinzip | Konkrete Auswirkung im Spielmodus |
|---------|-----------------------------------|
| **Focus-First** | Gesamte Navigation verschwindet; UI nur auf expliziten Tap |
| **Touch-Native** | Tap-Zonen ≥ 64×64 px; halber Bildschirm pro Seite |
| **Accessibility** | WCAG AAA Kontrast im Spielmodus; Nachtmodus = kein Blendeffekt |
| **Kein Neustart** | Alle Einstellungsänderungen wirken sofort |
| **Handschuh-Safe** | Swipe-Threshold ≥ 40 px; keine kleinen Buttons im Core-Path |

### 1.3 Abgrenzung zur Konkurrenz

| Feature | forScore | Newzik | **Sheetstorm** |
|---------|----------|--------|----------------|
| Half-Page-Turn | ✅ | ✅ | ✅ Standard |
| Auto-Rotation | ❌ | ❌ | ✅ |
| Auto-Zoom | ❌ | ❌ | ✅ |
| 3-Ebenen-Annotation-Toggle | ❌ | ❌ (2 Ebenen) | ✅ |
| Fußpedal (Bluetooth) | ✅ | ❌ | ✅ |
| Nachtmodus | ✅ | ✅ | ✅ |
| Android-Support | ❌ | ❌ | ✅ |

---

## 2. User Flow: Spielmodus starten

```
Setlist / Bibliothek
        │
        ▼
   Stück antippen
        │
        ▼
  ┌─────────────────────────────┐
  │  Stimme bereits bekannt?    │
  └──────┬──────────────────────┘
         │ Ja: Standard-Stimme         Nein / Fallback:
         ▼ automatisch wählen          ▼
    Spielmodus                  Stimmen-Auswahl-Dialog
    direkt öffnen               (Bottom Sheet, §8)
                                        │
                                        ▼
                                   Spielmodus öffnen
         │
         ▼
  ┌─────────────────────────────┐
  │ Auto-Rotation prüfen        │
  │ → Gerät-Ausrichtung messen  │
  │ → Notenlinien horizontal?   │
  │    Ja: keine Rotation       │
  │    Nein: PDF drehen         │
  └──────────────────────────────┘
         │
         ▼
  ┌─────────────────────────────┐
  │ Auto-Zoom berechnen         │
  │ → Seitenbreite = Viewport   │
  │ → Höhe: kein Abschneiden    │
  │   → Fit-Width oder Fit-Page │
  └──────────────────────────────┘
         │
         ▼
  Vollbild-Notenansicht (§3)
  Bildschirm-Timeout deaktiviert
  Overlay versteckt
```

### 2.1 Zustandsdiagramm Spielmodus

```
[Inaktiv / Navigation]
        │  Stück öffnen
        ▼
[Spielmodus — Vollbild]  ◄──── [Overlay sichtbar]
        │  Tap Mitte               │ Tap Mitte / Auto-Hide 4s
        ▼                          │
[Overlay sichtbar] ────────────────┘
        │  ⚙ Settings
        ▼
[Kontextuelle Einstellungen] (Notenblatt dahinter sichtbar)
        │  ✕ oder Tap außerhalb
        ▼
[Overlay sichtbar]
        │  🔒 Sperren
        ▼
[UI-Lock] — nur definierte Tap-Zonen wirken
        │  5x Tap Mitte oder Power-Button
        ▼
[Overlay sichtbar → Entsperren]
        │  ← Zurück
        ▼
[Navigation — Setlist / Bibliothek]
```

---

## 3. Vollbild-Notenansicht (Focus-First)

### 3.1 Layout-Regeln

- **0 px Padding** an allen Rändern — das Notenblatt füllt den gesamten Bildschirm
- **System-Overlays** (Status-Bar, Home-Indicator) werden transparent über dem Notenblatt gerendert, nicht darunter
- **Keine Bottom-Navigation** sichtbar — sie ist komplett ausgeblendet
- **Bildschirm-Timeout** wird automatisch deaktiviert (Keepalive-WakeLock)
- **Auto-Hide-Overlay:** Falls das Overlay versehentlich geöffnet wurde, schließt es sich nach 4 Sekunden ohne Interaktion

### 3.2 Tap-Zonen (asymmetrisch)

```
┌─────────────────────────────────┐
│                                 │
│   ◄ ZURÜCK   │   WEITER ►       │
│              │                  │
│    ~40% B.   │    ~60% B.       │
│              │                  │
│  (Linke Hand)│ (Rechter Daumen) │
│              │                  │
│              │                  │
│   ○ ○ ○ ○ ○│○ ○ ○ ○ ○ ○      │  ← Overlay-Trigger: Mitte-Tap
└─────────────────────────────────┘
```

**Begründung Asymmetrie:** Der rechte Daumen liegt beim Halten des Geräts natürlich auf der rechten Bildschirmhälfte. „Weiter blättern" ist 3× häufiger als „zurück" — die 60%-Zone reduziert Fehlklicks links erheblich.

**Tap-Zonen Größe:** Minimum 64×64 px (handschuh-kompatibel, Design Decision)

**Mitte-Tap:** Bereich von ~5% Breite um die vertikale Mittelachse → öffnet Overlay

### 3.3 Swipe-Gesten

| Geste | Aktion |
|-------|--------|
| Swipe links → rechts | Vorherige Seite |
| Swipe rechts → links | Nächste Seite |
| Swipe oben → unten | Scrollt bei langen Seiten |
| Pinch-to-Zoom | Manueller Zoom (deaktiviert im Performance-Lock) |
| Swipe von oben (Edge) | Systemgeste — wird nicht abgefangen |
| Swipe von unten (Edge) | Systemgeste — wird nicht abgefangen |

**Threshold:** Minimum 40 px horizontale Bewegung für Seiten-Swipe (verhindert versehentliche Gesten bei Notizsetzen)

---

## 4. Seitenwechsel-Mechanismen

Vier gleichwertige Eingabemethoden für den Seitenwechsel — alle lösen dieselbe Aktion aus:

| Methode | Vorwärts | Rückwärts | Verfügbarkeit |
|---------|----------|-----------|---------------|
| **Tap rechts (60%)** | Nächste Seite | — | Immer |
| **Tap links (40%)** | — | Vorherige Seite | Immer |
| **Swipe ← (links)** | Nächste Seite | — | Immer |
| **Swipe → (rechts)** | — | Vorherige Seite | Immer |
| **Fußpedal rechts** | Nächste Seite | — | Wenn verbunden |
| **Fußpedal links** | — | Vorherige Seite | Wenn verbunden |
| **Tastatur →** | Nächste Seite | — | Desktop/Keyboard |
| **Tastatur ←** | — | Vorherige Seite | Desktop/Keyboard |

### 4.1 Seitenwechsel-Animation

```
Normaler Seitenwechsel (kein Half-Page-Turn):
  Aktuelle Seite → Slide out ← / Neue Seite → Slide in ←
  Dauer: 150ms, ease-out
  Keine Fade-Animation (zu langsam für Performance)

Half-Page-Turn (§5):
  Obere Hälfte: Scroll-Übergang 120ms
  Untere Hälfte: Scroll-Übergang 120ms (versetzt)
```

---

## 5. Half-Page-Turn

### 5.1 Konzept (Branchenstandard)

Der „Half-Page-Turn" verhindert den **Page-Jump-Schock** — das abrupte Verschwinden des gesamten Notenblatts beim Seitenwechsel. Statt einer vollen Seite zu scrollen, scrollt die App jeweils eine halbe Seite:

```
Zustand 1 (Normalansicht):
┌──────────────────────────────┐
│  SEITE 2, untere Hälfte      │
│  ─────────────────────────── │ ← Subtile Trennlinie
│  SEITE 3, obere Hälfte       │
└──────────────────────────────┘
         │ Tap/Swipe (Weiter)
         ▼
Zustand 2 (nach Half-Turn):
┌──────────────────────────────┐
│  SEITE 3, untere Hälfte      │
│  ─────────────────────────── │
│  SEITE 4, obere Hälfte       │
└──────────────────────────────┘
         │ Tap/Swipe (Weiter)
         ▼
Zustand 3 (nächste Seite komplett):
┌──────────────────────────────┐
│  SEITE 4, obere Hälfte       │  ← Logischer Seitenübergang
│  SEITE 4, untere Hälfte      │  ← Komplett sichtbar
└──────────────────────────────┘
```

### 5.2 Half-Page-Turn Aktivierung

- **Standard:** Eingeschaltet im Hochformat (Portrait) — entspricht forScore/Newzik Standard
- **Im Querformat (Tablet):** Zwei-Seiten-Ansicht statt Half-Page-Turn (§16)
- **Umschalten:** Via Kontextuelle Einstellungen (§12) oder Nutzer-Einstellungen
- **Keine Policy-Erzwingung** — ist immer nutzersteuerbar

### 5.3 Trennlinie

- **Farbe:** Neutral, 1px, leicht transparent über Notenblatt
- **Im Nachtmodus:** Trennlinie in gedimmtem Orange (warmes Licht, schützt Nachtsicht)
- **Option:** Ausblendbar in Einstellungen (für Nutzer die sie stört)

---

## 6. Auto-Rotation & Auto-Zoom

### 6.1 Auto-Rotation

Notenblätter werden häufig in unterschiedlichen Ausrichtungen eingescannt. Auto-Rotation korrigiert das automatisch beim ersten Öffnen.

```
Beim Öffnen eines Stücks:
  1. PDF-Seite analysieren (pdfrx)
  2. Notenlinien-Winkel erkennen
  3. Wenn Winkel ≠ 0° (horizontal):
     → PDF-Seite programmatisch drehen
     → Ergebnis cachen (keine erneute Berechnung)
  4. Wenn Gerät im Querformat: Doppelseite prüfen

Manuelle Korrektur:
  Overlay → ⚙ → Rotation korrigieren
  [↻ 90°]  [↺ 90°]  [↕ spiegeln]
  Gespeichert pro Stück (nicht global)
```

### 6.2 Auto-Zoom

Optimale Darstellung ohne manuelles Zoomen oder Scrollen:

```
Fit-Strategie (Priorität):
  1. Fit-Width: Breite des Notenblatts = Viewport-Breite
     → Bevorzugt wenn Höhe ≤ 115% des Viewports
  2. Fit-Page: Gesamte Seite sichtbar (wenn Höhe > 115%)
     → Kein vertikales Scrollen nötig
  3. Manueller Override: Nutzer kann pinchen
     → Override pro Session gespeichert
     → Reset: Doppel-Tap auf Notenblatt

Tablet-Querformat:
  → Zwei Seiten nebeneinander, je Fit-Width halbe Breite
```

### 6.3 Adaptive Zoom — Geräteklassen

| Gerät | Standard-Zoom | Begründung |
|-------|--------------|------------|
| Phone Portrait | Fit-Width | Schmalste Ansicht, maximale Breite |
| Phone Landscape | Fit-Page | Kompaktes Format |
| Tablet Portrait | Fit-Width | Hauptnutzungsfall |
| Tablet Landscape | 2-Up Fit-Width | Doppelseite, branchenüblich |
| Desktop | 100% + Zwei-Seiten | Volle Auflösung |

---

## 7. Overlay & Quick-Access

### 7.1 Overlay öffnen

**Trigger:** Tap auf Mitte (ca. 5% Breite um Mittelachse) → Overlay erscheint mit Fade-In 120ms

### 7.2 Overlay-Layout

```
┌─────────────────────────────────────────┐
│  ← Zurück    Stück 3 / 12        ⚙️    │  ← Obere Leiste (min. 44px)
├─────────────────────────────────────────┤
│                                         │
│         [ N O T E N B L A T T ]        │  ← Notenblatt bleibt voll sichtbar
│                                         │    (Overlay ist semi-transparent)
│                                         │
├─────────────────────────────────────────┤
│  🎵 Stimme   🌙 Nacht   🔒 Sperren     │  ← Untere Leiste (min. 44px)
└─────────────────────────────────────────┘
```

### 7.3 Obere Leiste — Aktionen

| Element | Aktion | Details |
|---------|--------|---------|
| `← Zurück` | Setlist / Bibliothek | Im Auftritts-Modus: Bestätigungs-Dialog |
| `Stück 3 / 12` | Setlist-Schnellnavigation | Bottom Sheet mit Stückliste (§9) |
| `⚙️` | Kontextuelle Einstellungen | Max. 5 Optionen (§12) |

### 7.4 Untere Leiste — Aktionen

| Element | Aktion | Details |
|---------|--------|---------|
| `🎵 Stimme` | Stimme wechseln | Drop-Up Sheet (§8) |
| `🌙 Nacht` | Nacht-/Bühnenmodus toggle | Sofort, kein Dialog |
| `🔒 Sperren` | UI-Lock aktivieren | (§14) |

### 7.5 Auto-Hide

- Overlay schließt sich nach **4 Sekunden** ohne Interaktion automatisch
- Bei aktivem Scroll (Finger auf Screen) wird Auto-Hide unterbrochen
- Tap außerhalb des Overlay → sofort schließen

---

## 8. Stimme wechseln

### 8.1 Flow

```
Tap auf „🎵 Stimme" in Overlay
        │
        ▼
Bottom Sheet öffnet (aus Unterkante, 300ms ease-out)
        │
        ▼
Stimme wählen (§8.2)
        │
        ▼
PDF wechselt sofort zur neuen Stimme
Bottom Sheet schließt sich automatisch
```

### 8.2 Stimmen-Auswahl-Dialog

```
┌─────────────────────────────────────────┐
│  Stimme wechseln                   ✕   │
├─────────────────────────────────────────┤
│                                         │
│  MEINE INSTRUMENTE                      │
│  ─────────────────────────────────      │
│  ✓ 2. Klarinette  ●──────────────────  │  ← Aktuell, farblich markiert
│    1. Klarinette                        │
│    Klarinette in B                      │
│    Saxophon (Alt)                       │
│                                         │
│  ANDERE STIMMEN                         │
│  ─────────────────────────────────      │
│    Trompete 1                           │
│    Trompete 2                           │
│    Flügelhorn                           │
│    Horn in F                            │
│    Tuba                                 │
│    Schlagzeug                           │
│                                         │
└─────────────────────────────────────────┘
```

### 8.3 Fallback-Stimmen-Visualisierung

Wenn die exakte Stimme fehlt, wird automatisch die nächstliegende vorausgewählt und **visuell kommuniziert:**

```
┌─────────────────────────────────────────┐
│  MEINE INSTRUMENTE                      │
│  ─────────────────────────────────      │
│  ⚠ 2. Klarinette  [nicht verfügbar]    │  ← Ausgegraut
│  → 1. Klarinette  ●──────────────────  │  ← Auto-Fallback, Pfeil zeigt Grund
│                                         │
│  ℹ️ „2. Klarinette" nicht vorhanden.   │
│     Automatisch zu „1. Klarinette"     │
│     gewechselt.                         │
└─────────────────────────────────────────┘
```

**Fallback-Priorisierung:**
1. Exakte Stimme (z.B. „2. Klarinette")
2. Gleiche Nummer ohne Instrument (z.B. „2. Stimme")
3. Instrument ohne Nummerierung (z.B. „Klarinette")
4. Erste verfügbare Stimme des gleichen Registers

---

## 9. Setlist-Navigation

### 9.1 Schnellnavigation

Tap auf `Stück 3 / 12` in der oberen Overlay-Leiste öffnet die Setlist-Schnellnavigation:

```
┌─────────────────────────────────────────┐
│  Setlist-Navigation               ✕    │
│  Probenvorbereitung 2026-04-03          │
├─────────────────────────────────────────┤
│                                         │
│   1  Böhmischer Traum                   │
│   2  Alte Kameraden                     │
│  ▶ 3  Auf der Vogelwiese   ← aktuell   │  ← Farblich hervorgehoben
│   4  Feuerwehrmarsch                    │
│   5  Der Donauwalzer                    │
│   6  Märchenwalzer                      │
│   ...                                   │
│  12  Finale                             │
│                                         │
└─────────────────────────────────────────┘
```

### 9.2 Navigationsregeln

- Tippen auf Stück → wechselt sofort; Sheet schließt sich
- Aktuelles Stück ist immer sichtbar (Auto-Scroll im Sheet)
- Kein Bestätigungs-Dialog — Stücke in Setlist haben immer bekannte Stimme
- Wenn Stimme nicht verfügbar: Fallback-Logik greift (§8.3)

---

## 10. Annotationen Toggle

### 10.1 Annotationsebenen im Spielmodus

Die drei Annotationsebenen können einzeln ein/ausgeblendet werden — **ohne den Spielmodus zu verlassen**:

```
Via Kontextuelle Einstellungen (§12):
┌─────────────────────────────────────────┐
│  👁 Annotationsebenen                   │
│                                         │
│  [■ Privat  ]  [■ Stimme  ]  [■ Orch. ]│
│   (Grün)        (Blau)        (Orange)  │
│                                         │
└─────────────────────────────────────────┘
```

### 10.2 Interaktionsregeln

- **Ein-Tap:** Toggle ein/aus für jede Ebene
- **Sofort-Wirkung:** Annotations erscheinen/verschwinden ohne Reload
- **Merken:** Letzte Einstellung pro Stück gespeichert (nicht global)
- **Accessibility:** Ebenen nicht nur durch Farbe — immer zusätzlich Icon (Schloss/Person/Gruppe)
- **Policy-Lock:** Wenn Kapelle eine Ebene erzwingt → Schloss-Icon, nicht togglebar

---

## 11. Nacht-/Bühnenmodus

### 11.1 Konzept

Der Nachtmodus ist kein simples Invertieren — er **rendert Noten weiß auf schwarzem Hintergrund** für maximalen Kontrast ohne Blendung der Nachtsicht.

### 11.2 Aktivierung

| Weg | Details |
|-----|---------|
| Overlay → `🌙 Nacht` | Sofort-Toggle, kein Dialog |
| Kontextuelle Einstellungen | Toggle mit Slider-Feedback |
| Kapellen-Policy | Erzwungen bei Konzert-Setlists |
| Tastenkombination | (Desktop) Shift+N |

### 11.3 Nachtmodus-Darstellung

```
Standard (Hell):
┌──────────────────────────────┐
│  ████ Notenblatt weiß ████   │  ← Schwarze Noten auf weißem Grund
│  █ █         ███         █  │
│  ████ ─────────────────  ███ │
└──────────────────────────────┘

Nachtmodus (Bühne):
┌──────────────────────────────┐
│  [SCHWARZER HINTERGRUND]     │
│                              │
│  ░░░░ Notenblatt dunkel ░░░░ │  ← Helle Noten auf schwarzem Grund
│  ░ ░         ░░░         ░  │    (nicht invertiert — direkt dunkel)
│  ░░░░ ─────────────────  ░░░ │
└──────────────────────────────┘

Sepia (optional, Augenermüdung):
┌──────────────────────────────┐
│  [WARMER HINTERGRUND #F5E6C8]│
│  Schwarze Noten auf Sepia    │
└──────────────────────────────┘
```

### 11.4 Nachtmodus & Overlay-Leisten

Im Nachtmodus wird die Overlay-Leiste ebenfalls angepasst:
- Hintergrund: `rgba(0, 0, 0, 0.85)` statt weiß
- Text/Icons: `#E5E7EB` (off-white)
- Trennlinie im Half-Page-Turn: gedimmtes Orange (warm, schützt Nachtsicht)

---

## 12. Kontextuelle Einstellungen

### 12.1 Prinzip: 5 Optionen Maximum

Das ⚙️-Icon öffnet ein Overlay-Panel **über dem sichtbaren Notenblatt** (Notenblatt bleibt vollständig sichtbar dahinter). Maximal 5 Optionen — kein Scrollen.

### 12.2 Layout

```
[Notenblatt sichtbar, leicht gedimmt]

┌──────────────────────────────────────────┐
│  ⚙️  Schnelleinstellungen           ✕   │
├──────────────────────────────────────────┤
│                                          │
│  🌙  Nachtmodus                         │
│  ─────────────────────────   [■ Ein]    │
│                                          │
│  📄  Half-Page-Turn                     │
│  ─────────────────────────   [■ Ein]    │
│                                          │
│  🔤  Schriftgröße                       │
│  [A−] ──────────●──── [A+]              │
│                   Mittel                │
│                                          │
│  👁   Annotationsebenen                 │
│  [■ Privat] [■ Stimme] [■ Orchester]   │
│                                          │
│  ☀️  Helligkeit                         │
│  [☼−] ──────────●──── [☼+]             │
│                   75%                   │
│                                          │
└──────────────────────────────────────────┘
```

### 12.3 Die 5 fixierten Optionen

| # | Option | Typ | Sofort-Wirkung |
|---|--------|-----|----------------|
| 1 | Nachtmodus | Toggle | ✅ Sofort |
| 2 | Half-Page-Turn | Toggle | ✅ Sofort |
| 3 | Schriftgröße | Slider | ✅ Live-Preview |
| 4 | Annotationsebenen | Multi-Toggle | ✅ Sofort |
| 5 | Helligkeit | Slider | ✅ Sofort |

**Keine weiteren Optionen** — mehr Optionen bedeuten mehr Entscheidungen auf der Bühne. Die vollständigen Einstellungen sind in den Gerät-Einstellungen verfügbar.

### 12.4 Verhalten bei Policy-Lock

Wenn eine Kapellen-Policy eine Einstellung erzwingt:

```
│  🌙  Nachtmodus                              │
│  🔒 Von Kapelle vorgegeben                  │
│  Bei Konzert-Setlists immer aktiv.          │  ← Erklärender Text
```

---

## 13. Fußpedal (Bluetooth)

### 13.1 Unterstützte Protokolle

- **BLE HID** (Bluetooth Low Energy Human Interface Device) — Standard für AirTurn, PageFlip, IKMultimedia iRig BlueTurn
- **MIDI CC via Bluetooth** — für MIDI-fähige Pedale
- **USB HID** — für Desktop via USB-Verbindung

### 13.2 Konfiguration (in Gerät-Einstellungen)

```
┌──────────────────────────────────────┐
│  🦶 Fußpedal                         │
│  ─────────────────────────────────   │
│  Verbundenes Gerät:                  │
│  AirTurn BT-105    🟢 Verbunden      │
│  [Trennen]   [Anderes Gerät suchen]  │
│                                      │
│  TASTENBELEGUNG                      │
│  Rechts (A):  [Nächste Seite    ▼]  │
│  Links (B):   [Vorherige Seite  ▼]  │
│  Mitte (C):   [Overlay öffnen   ▼]  │
│                                      │
│  VERFÜGBARE AKTIONEN                 │
│  Nächste Seite / Vorherige Seite     │
│  Half-Turn vorwärts / rückwärts      │
│  Overlay öffnen / schließen          │
│  Nachtmodus toggle                   │
└──────────────────────────────────────┘
```

### 13.3 Verbindungsindikator im Spielmodus

- Kein permanenter Indikator (würde ablenken)
- Verbindungsverlust: Kurzer Toast `🦶 Fußpedal getrennt` (2 Sekunden) am oberen Rand, dann verschwindet er

### 13.4 Pairing-Flow

```
Gerät-Einstellungen → Fußpedal → [Gerät suchen]
         │
         ▼
  Bluetooth-Suche läuft…
  ┌────────────────────────────┐
  │  Gefundene Geräte:         │
  │  🦶 AirTurn BT-105         │  ← Antippen zum Verbinden
  │  🦶 PageFlip Cicada        │
  └────────────────────────────┘
         │ Antippen
         ▼
  Verbunden! Kurze Test-Anleitung:
  "Drücke rechtes Pedal zum Testen"
  → Seite wechselt als Bestätigung
```

---

## 14. Spielmodus sperren (UI-Lock)

### 14.1 Zweck

Verhindert versehentliche Navigations-Aktionen bei:
- Legen des Tablets auf dem Notenständer
- Auftritte mit Bewegung (Marsch)
- Kinder/Schüler, die das Gerät halten

### 14.2 Aktivierung

Overlay → `🔒 Sperren` → Sofortiger UI-Lock, Overlay verschwindet

### 14.3 Im gesperrten Zustand

```
┌─────────────────────────────────────┐
│                                     │
│       N O T E N B L A T T          │  ← Vollbild, kein Overlay
│                                     │
│  [Linke Tap-Zone]   [Rechte Zone]  │  ← Seitenwechsel funktioniert
│                                     │  ← Alle anderen Taps ignoriert
└─────────────────────────────────────┘
  Kleines Schloss-Icon unten rechts (dezent, nicht störend)
```

**Was weiterhin funktioniert:**
- Seitenwechsel (Tap rechts/links, Swipe, Fußpedal)
- Fußpedal alle Aktionen

**Was blockiert ist:**
- Overlay öffnen (Tap Mitte)
- Pinch-to-Zoom
- Stimme wechseln
- Einstellungen

### 14.4 Entsperren

- **5× Tap auf die Mitte** (oder konfigurierbar: Fußpedal-Kombination)
- Kurzer Bestätigungs-Toast: `🔓 Entsperrt`

---

## 15. Wireframes: Phone

### 15.1 Phone — Vollbild Spielmodus (Hochformat)

```
┌─────────────────────────────────┐  ← 390px wide (iPhone 14 reference)
│                                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │   N O T E N B L A T T  │   │
│  │                         │   │
│  │   ████ ████████████    │   │
│  │   ██ █    ███████ █    │   │
│  │   ████────────────████  │   │
│  │   ████ ████████████    │   │
│  │   ██ █    ███████ █    │   │
│  │   ████────────────████  │   │
│  │                         │   │
│  │   ████ ████████████    │   │
│  │   ██ █    ███████ █    │   │
│  │   ████────────────████  │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│   ◄ 40%         60% ►          │  ← Tap-Zonen (unsichtbar)
│                                 │
└─────────────────────────────────┘
```

### 15.2 Phone — Half-Page-Turn (Hochformat)

```
┌─────────────────────────────────┐
│                                 │
│   ████ ████████████████████    │
│   ██ █    ████████████ ███     │  ← SEITE 2, untere Hälfte
│   ████────────────────████     │
│   ████ ████████████████████    │
│   ────────────────────────     │  ← Trennlinie (1px, subtil)
│   ████ ████████████████████    │
│   ██ █    ████████████ ███     │  ← SEITE 3, obere Hälfte
│   ████────────────────████     │
│   ████ ████████████████████    │
│                                 │
└─────────────────────────────────┘
```

### 15.3 Phone — Overlay aktiv

```
┌─────────────────────────────────┐
│ ← Zurück   Stück 3/12     ⚙️   │  ← 44px Leiste, leicht transparent
├─────────────────────────────────┤
│                                 │
│   ████ ████████████████████    │
│   ██ █    ████████████ ███     │  ← Notenblatt sichtbar (gedimmt)
│   ████────────────────████     │
│   ████ ████████████████████    │
│                                 │
├─────────────────────────────────┤
│  🎵 Stimme  🌙 Nacht  🔒 Lock  │  ← 44px Leiste
└─────────────────────────────────┘
```

### 15.4 Phone — Kontextuelle Einstellungen

```
┌─────────────────────────────────┐
│ ← Zurück   Stück 3/12     ⚙️   │
├─────────────────────────────────┤
│                                 │
│   [Notenblatt, stark gedimmt]   │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⚙️ Schnelleinstellungen  ✕ │ │
│ │ ─────────────────────────── │ │
│ │ 🌙 Nachtmodus   [■ Ein]    │ │
│ │ 📄 Half-Page    [■ Ein]    │ │
│ │ 🔤 Größe [A−]──●──[A+]    │ │
│ │ 👁 Layer [■Priv][■Stim][■O]│ │
│ │ ☀️ Helligkeit[☼−]──●──[☼+]│ │
│ └─────────────────────────────┘ │
│                                 │
│  🎵 Stimme  🌙 Nacht  🔒 Lock  │
└─────────────────────────────────┘
```

### 15.5 Phone — Nachtmodus

```
┌─────────────────────────────────┐  ← Schwarzer Hintergrund
│                                 │
│   ░░░░ ░░░░░░░░░░░░░░░░░░░░    │
│   ░░ ░    ░░░░░░░░░░░░ ░░░     │  ← Helle Noten auf schwarz
│   ░░░░────────────────░░░░     │
│   ░░░░ ░░░░░░░░░░░░░░░░░░░░    │
│   ────────────────────────     │  ← Trennlinie (warm-orange, gedimmt)
│   ░░░░ ░░░░░░░░░░░░░░░░░░░░    │
│   ░░ ░    ░░░░░░░░░░░░ ░░░     │
│   ░░░░────────────────░░░░     │
│                                 │
└─────────────────────────────────┘  ← Keine UI-Elemente sichtbar
```

### 15.6 Phone — Stimme wechseln (Bottom Sheet)

```
┌─────────────────────────────────┐
│                                 │
│  [Notenblatt, leicht gedimmt]  │
│                                 │
│                                 │
├─────────────────────────────────┤  ← Sheet öffnet von unten
│  Stimme wechseln           ✕   │
│  ─────────────────────────────  │
│  MEINE INSTRUMENTE              │
│  ✓ 2. Klarinette  ●─────────   │  ← Aktuell
│    1. Klarinette                │
│    Klarinette in B              │
│  ─────────────────────────────  │
│  ANDERE STIMMEN                 │
│    Trompete 1                   │
│    Trompete 2                   │
│    Flügelhorn                   │
└─────────────────────────────────┘
```

---

## 16. Wireframes: Tablet

### 16.1 Tablet — Zwei-Seiten-Ansicht (Querformat)

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  ┌────────────────────────────┐ ┌─────────────────────────────────┐ │
│  │                            │ │                                 │ │
│  │    S E I T E   2           │ │    S E I T E   3                │ │
│  │                            │ │                                 │ │
│  │  ████ █████████████████   │ │  ████ █████████████████████    │ │
│  │  ██ █    █████████ ███    │ │  ██ █    █████████ ███         │ │
│  │  ████───────────────████  │ │  ████───────────────████       │ │
│  │  ████ █████████████████   │ │  ████ █████████████████████    │ │
│  │  ██ █    █████████ ███    │ │  ██ █    █████████ ███         │ │
│  │  ████───────────────████  │ │  ████───────────────████       │ │
│  │                            │ │                                 │ │
│  └────────────────────────────┘ └─────────────────────────────────┘ │
│   ◄────────────────────────────  Tap-Zone Links  │  Tap-Zone Rechts ─► │
└──────────────────────────────────────────────────────────────────────┘
```

### 16.2 Tablet — Overlay (Querformat)

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Zurück         Stück 3 von 12 · Auf der Vogelwiese          ⚙️   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────┐  ┌──────────────────────────────────┐ │
│  │   [SEITE 2, gedimmt]     │  │   [SEITE 3, gedimmt]             │ │
│  └──────────────────────────┘  └──────────────────────────────────┘ │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  🎵 Stimme: 2. Klarinette     🌙 Nachtmodus     🔒 Sperren          │
└──────────────────────────────────────────────────────────────────────┘
```

### 16.3 Tablet — Kontextuelle Einstellungen (als Side Panel)

Auf dem Tablet öffnen die Schnelleinstellungen als **Side Panel** von rechts (nicht als Overlay über dem gesamten Bildschirm):

```
┌────────────────────────────────────────┬────────────────────────────┐
│                                        │  ⚙️ Schnelleinstellungen  │
│   S E I T E   2  (75% Breite)          │  ─────────────────────    │
│                                        │  🌙 Nachtmodus            │
│  ████ █████████████████████           │       [■ Ein]             │
│  ██ █    █████████ ███                │                            │
│  ████───────────────████              │  📄 Half-Page-Turn        │
│  ████ █████████████████████           │       [■ Ein]             │
│  ██ █    █████████ ███                │                            │
│  ████───────────────████              │  🔤 Schriftgröße          │
│                                        │  [A−] ──●── [A+]         │
│                                        │                            │
│                                        │  👁 Annotationsebenen    │
│                                        │  [■Priv][■Stim][□Orch]   │
│                                        │                            │
│                                        │  ☀️ Helligkeit            │
│                                        │  [☼−] ────●── [☼+]      │
│                                        │                            │
│                                        │  ✕ Schließen             │
└────────────────────────────────────────┴────────────────────────────┘
```

### 16.4 Tablet — Stimme wechseln (Modal, Tablet-Stil)

Auf dem Tablet erscheint die Stimmenauswahl als **zentriertes Modal** (nicht als Bottom Sheet):

```
┌──────────────────────────────────────────────────────────────────────┐
│  [Notenblatt im Hintergrund, stark gedimmt]                         │
│                                                                      │
│              ┌─────────────────────────────────┐                    │
│              │  Stimme wechseln           ✕   │                    │
│              │  ─────────────────────────────  │                    │
│              │  MEINE INSTRUMENTE              │                    │
│              │  ✓ 2. Klarinette  ●──────────   │                    │
│              │    1. Klarinette                │                    │
│              │    Klarinette in B              │                    │
│              │    Saxophon (Alt)               │                    │
│              │  ─────────────────────────────  │                    │
│              │  ANDERE STIMMEN                 │                    │
│              │    Trompete 1                   │                    │
│              │    Trompete 2                   │                    │
│              │    Flügelhorn                   │                    │
│              │    Horn in F                    │                    │
│              └─────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 17. Interaction Patterns & Edge Cases

### 17.1 Letzte Seite — kein weiteres Blättern

```
Auf letzter Seite, Tap auf Weiter:
→ Kurzes haptisches Feedback (Vibration, 50ms)
→ Kein visueller Fehler-Zustand
→ Seite bewegt sich minimal rechts und federt zurück (Bounce, 200ms)

Wenn Setlist vorhanden:
→ Kurzer Toast: "Letztes Stück in der Setlist"
   [Neu starten] [Zurück zur Setlist]
```

### 17.2 Offline-Stück — Kein Netzwerk

Alle gespielten Stücke müssen offline verfügbar sein (Offline-Cache). Falls ein Stück nicht gecacht ist:

```
┌─────────────────────────────────────┐
│  ⚠️ Stück nicht offline verfügbar  │
│                                     │
│  „Auf der Vogelwiese" wurde nicht   │
│  heruntergeladen.                   │
│                                     │
│  [Herunterladen]   [Zurück]        │
└─────────────────────────────────────┘
```

### 17.3 Versehentliches Zurück (Auftritts-Modus)

Im Auftritts-Modus (Konzert-Setlist aktiv) schützt ein Bestätigungs-Dialog vor versehentlichem Verlassen:

```
Tap auf „← Zurück":
┌─────────────────────────────────────┐
│  Spielmodus verlassen?              │
│                                     │
│  Das Stück ist noch nicht zu Ende.  │
│                                     │
│  [Abbrechen]       [Verlassen]     │
└─────────────────────────────────────┘
```

### 17.4 Zwei-Finger-Tap (Zoom-Reset)

- Doppel-Tap mit zwei Fingern → Zoom-Reset auf Auto-Zoom
- Verhindert Verwirrung wenn Nutzer versehentlich gezoomt hat

### 17.5 Stift-Erkennung

- **Stift (Apple Pencil / S-Pen):** Aktiviert Annotations-Modus — tippen mit Stift macht keine Seitenwechsel-Aktion
- **Finger:** Seitenwechsel und Overlay-Trigger
- **Gleichzeitig Stift + Finger:** Stift annotiert, Finger wird ignoriert (verhindert Handballenaktionen)

---

## 18. Abhängigkeiten

### 18.1 Für Hill (Frontend / Flutter)

| Komponente | Spec-Verweis |
|------------|-------------|
| `PerformanceViewScreen` | §3, §7 |
| `HalfPageTurnController` | §5 |
| `AutoRotationService` | §6.1 |
| `AutoZoomCalculator` | §6.2 |
| `VoiceSelectionBottomSheet` | §8 |
| `SetlistQuickNav` | §9 |
| `AnnotationLayerToggle` | §10 |
| `NightModeController` | §11 |
| `QuickSettingsOverlay` | §12 |
| `FootpedalService` (BLE HID) | §13 |
| `UILockController` | §14 |

**Technologie-Hinweis:** PDF-Rendering via `pdfrx` (gemäß Technologie-Stack). Keepalive-WakeLock via Flutter `wakelock_plus`.

### 18.2 Für Banner (Backend)

- Keine direkten Backend-Abhängigkeiten im Spielmodus
- Offline-Cache muss durch Banner-Sync vorbefüllt sein
- Annotationen-Sync: Beim Verlassen des Spielmodus (kein Live-Sync während des Spielens)

### 18.3 Offene Fragen für Thomas

- [ ] Soll der Spielmodus beim Öffnen immer auf Seite 1 beginnen, oder soll die letzte Position pro Stück gespeichert werden?
- [ ] Soll der Auftritts-Modus (mit Bestätigungs-Dialog) manuell aktiviert werden oder automatisch bei Konzert-Setlists?
- [ ] Fußpedal: Welche konkreten Geräte soll das Team priorisiert testen? (AirTurn, PageFlip?)
