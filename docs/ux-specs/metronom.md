# UX-Spec: Echtzeit-Metronom

> **Issue:** MS3 — Echtzeit-Metronom  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-design.md`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [Rollen: Dirigent vs. Musiker](#2-rollen-dirigent-vs-musiker)
3. [User Flow: Dirigent startet Metronom](#3-user-flow-dirigent-startet-metronom)
4. [User Flow: Musiker empfängt Beat](#4-user-flow-musiker-empfängt-beat)
5. [Dirigent-View: Steuerung](#5-dirigent-view-steuerung)
6. [Musiker-View: Beat-Indikator](#6-musiker-view-beat-indikator)
7. [Audio-Click Konfiguration](#7-audio-click-konfiguration)
8. [Verbindungs-Status & Latenz-Kompensation](#8-verbindungs-status--latenz-kompensation)
9. [Micro-Interactions & Animationen](#9-micro-interactions--animationen)
10. [Wireframes: Phone](#10-wireframes-phone)
11. [Wireframes: Tablet & Desktop](#11-wireframes-tablet--desktop)
12. [Accessibility](#12-accessibility)
13. [Responsiveness](#13-responsiveness)
14. [Error States & Edge Cases](#14-error-states--edge-cases)
15. [Integration mit Navigation (GoRouter)](#15-integration-mit-navigation-gorouter)
16. [Abhängigkeiten](#16-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Der Dirigent schlägt den Takt — alle sehen ihn gleichzeitig. Nicht fast gleichzeitig. Gleichzeitig."

Das Echtzeit-Metronom ist ein kritisches Live-Tool. Die Synchronisation zwischen Dirigent und Musikern ist das Kernversprechen. **Latenz und Unzuverlässigkeit sind Vertrauensbrüche.**

### 1.2 Zwei völlig verschiedene Nutzungsszenarien

| Rolle | Kontext | Primäraktion | UI-Priorität |
|-------|---------|--------------|--------------|
| **Dirigent** | Steht am Pult, sieht Orchester | BPM + Taktart einstellen, Start/Stop | Kontrolle |
| **Musiker** | Hält Tablet, spielt Instrument | Beat sehen (und hören) | Passives Empfangen |

### 1.3 Designprinzipien

| Prinzip | Auswirkung |
|---------|-----------|
| **Beat ist heilig** | Der Beat-Indikator hat absolute Priorität — keine anderen Animationen dürfen ihn stören |
| **Dirigent hat Kontrolle** | Nur der Dirigent (Rolle im System) kann Start/Stop und BPM ändern |
| **Musiker-View ist passiv** | Keine Steuerelemente — nur Empfangen |
| **Verbindung transparent** | Status immer sichtbar — kein falsches Sicherheitsgefühl |
| **Handschuh-Safe** | Start/Stop: min. 72×72 px |

---

## 2. Rollen: Dirigent vs. Musiker

```
Nutzer öffnet Metronom-Screen
        │
        ▼
  ┌────────────────────────────┐
  │  Rolle prüfen              │
  │  (aus Kapellen-Config)     │
  └──────┬─────────────────────┘
         │ Dirigent / Admin          Musiker / andere Rollen
         ▼                           ▼
   Dirigent-View (§5)           Musiker-View (§6)
   (Steuerung aktiv)            (Empfang passiv)
```

**Wichtig:** Die Rollenprüfung erfolgt lokal aus der gespeicherten Kapellen-Mitgliedschaft. Kein Server-Roundtrip nötig.

---

## 3. User Flow: Dirigent startet Metronom

```
Werkzeuge → Metronom
        │
        ▼
  Dirigent-View öffnet
        │
        ├──── BPM einstellen (Slider / Stepper / Tap-Tempo)
        │
        ├──── Taktart wählen (2/4, 3/4, 4/4, 6/8 etc.)
        │
        ├──── Audio-Click konfigurieren (ein/aus)
        │
        ▼
  [▶ Start] tippen
        │
        ▼
  ┌──────────────────────────────────────────────────────┐
  │  Verbindungs-Check                                   │
  │  WiFi → UDP Multicast versuchen                      │
  │  Kein WiFi → WebSocket (SignalR) Fallback            │
  └──────────────────────────────────────────────────────┘
        │
        ▼
  Metronom läuft
  - Beat-Anzeige im Dirigent-View (klein, als Referenz)
  - Musiker sehen Beat-Indikator
  - Verbindungs-Sidebar zeigt angemeldete Musiker
        │
        ▼
  [⏹ Stop] tippen → Metronom stoppt für alle
```

### 3.1 Tap-Tempo Flow

```
[Tap Tempo] Button antippen (4× antippen)
        │
        ▼
  Erste 2 Taps: kein Wert (zu wenig Daten)
        │
        ▼
  Ab 3. Tap: BPM berechnet + angezeigt
        │
        ▼
  Nach 2s Pause: Tap-Tempo-Modus endet, BPM fixiert
```

---

## 4. User Flow: Musiker empfängt Beat

```
Werkzeuge → Metronom  (oder: Beat-Banner erscheint automatisch wenn Metronom aktiv)
        │
        ▼
  Musiker-View öffnet
        │
        ▼
  ┌────────────────────────────────────────────────────┐
  │  Verbindungs-Check                                 │
  │  WiFi → UDP Multicast (< 5ms)                      │
  │  Kein WiFi → WebSocket (< 50ms)                    │
  └────────────────────────────────────────────────────┘
        │
        ├──── Dirigent hat Metronom laufen → Beat anzeigen
        │
        └──── Kein Metronom aktiv → Warte-Zustand (§14.1)
```

### 4.1 Auto-Discovery

Wenn ein Musiker die Metronom-App öffnet und ein Metronom bereits läuft:
- **Sofortige Verbindung** — kein "Verbinden"-Button
- Beat-Anzeige startet nach erstem Timestamp empfangen

---

## 5. Dirigent-View: Steuerung

### 5.1 Layout

```
┌─────────────────────────────────────────────┐
│  Metronom                    ● 12 verbunden │  ← Header + Verbindungs-Badge
├─────────────────────────────────────────────┤
│                                             │
│           ┌───────────────────┐             │
│           │     1 2 0         │             │  ← BPM (72sp)
│           │      BPM          │             │
│           └───────────────────┘             │
│                                             │
│  [−−] [−] ●────────────────○ [+] [++]      │  ← BPM-Slider + Stepper
│   60                           200          │
│                                             │
│  Taktart:  [2/4] [3/4] [4/4] [6/8] […]    │  ← Taktart-Chips
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │  🔊 Audio-Click                  EIN  │ │  ← Toggle
│  └────────────────────────────────────────┘ │
│                                             │
│  [🎵 Tap Tempo]                            │  ← Großer Button
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │  Takt:  ●  ○  ○  ○                   │ │  ← Mini Beat-Indikator
│  └────────────────────────────────────────┘ │
│                                             │
│         ┌──────────────────┐               │
│         │  ▶  START        │               │  ← Haupt-CTA (72×72 min.)
│         └──────────────────┘               │
│                                             │
└─────────────────────────────────────────────┘
```

### 5.2 BPM-Eingabe

- **Slider:** Bereich 40–240 BPM, Step 1 BPM
- **Stepper:**
  - `[−]` / `[+]`: je 1 BPM
  - `[−−]` / `[++]`: je 5 BPM
  - Long-Press: kontinuierliche Änderung
- **Direkteingabe:** Tippen auf BPM-Zahl → Tastatur öffnet numerisches Keyboard
- **Tap-Tempo:** Großer Button, 4 Taps berechnen Durchschnitt

### 5.3 Taktart

Chips: `2/4`, `3/4`, `4/4`, `6/8`, `[…]`
- `[…]` öffnet Bottom Sheet mit weiteren Optionen: `5/4`, `7/8`, `12/8`, Benutzerdefiniert
- Default: `4/4`
- Chip-Mindestgröße: 64×44 px

### 5.4 Start/Stop Button

- **Gestoppt:** Grüner Button mit ▶-Icon + „Start"
- **Läuft:** Roter Button mit ⏹-Icon + „Stop"
- **Mindestgröße:** 200×72 px (Handy), 240×80 px (Tablet)
- **Farbe läuft:** `color-error` (Rot) — klares Signal, dass etwas aktiv ist
- **Animation Start:** Scale 1.0 → 0.95 → 1.0 (Tap-Feedback), `AppDurations.fast`

### 5.5 Mini Beat-Indikator im Dirigent-View

Kleine Reihe von Kreisen (Taktschläge):
```
● ○ ○ ○   (4/4 — erster Beat hervorgehoben)
```
- Aktiver Beat: `color-primary` gefüllt
- Inaktiv: `color-border` Outline
- Pulsiert kurz bei jedem Beat: Scale 1.0 → 1.3 → 1.0 in 100ms

---

## 6. Musiker-View: Beat-Indikator

### 6.1 Designprinzip Beat-Indikator

> „Der Beat muss instinktiv erfasst werden — ohne Lesen, ohne Nachdenken."

Der visuelle Taktschlag-Indikator nutzt zwei Techniken gleichzeitig:
1. **Farb-Flash:** Gesamter Indikator-Bereich wechselt Farbe auf jeden Beat
2. **Puls-Animation:** Kreis / Form pulsiert (wächst und schrumpft)

### 6.2 Layout Musiker-View

```
┌─────────────────────────────────────────────┐
│  Metronom           ● WiFi  ─ 120 BPM 4/4  │  ← Header
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│          ┌─────────────────────┐            │
│          │                     │            │
│          │       ████          │            │  ← Beat-Fläche
│          │      ██████         │            │     (pulsiert auf Beat)
│          │       ████          │            │
│          │                     │            │
│          └─────────────────────┘            │
│                                             │
│               1  ●  2  ○  3  ○  4  ○       │  ← Takt-Position
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  🔊 Audio-Click (lokal)        AUS  │  │  ← Musiker kann Click selbst steuern
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Latenz-Kompensation: +0 ms    [⚙]  │  │  ← Einstellung
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 6.3 Beat-Fläche

- **Größe:** 60% der Bildschirmbreite, quadratisch (oder rund)
- **Erster Taktschlag (Zählzeit 1):** Weiß → starkes Orange/Rot-Flash
- **Folgende Schläge:** Weiß → helles Blau-Flash
- **Flash-Dauer:** 80ms → zurück zu Weiß
- **Animation:** `AppCurves.easeOut`, Rückweg `AppCurves.easeIn`

### 6.4 Takt-Position-Anzeige

```
1  ●  2  ○  3  ○  4  ○
```
- Aktueller Schlag: `●` in `color-primary`
- Vergangene/künftige: `○` in `color-border`
- Aktualisierung: synchron mit Beat-Flash

### 6.5 BPM + Taktart Header

- Oben rechts, klein: `120 BPM · 4/4`
- `AppTypography.labelMedium`, `color-text-secondary`
- Kein interaktives Element im Musiker-View

---

## 7. Audio-Click Konfiguration

### 7.1 Dirigent-Seite

- **Toggle:** Audio-Click EIN/AUS
- **Wirkung:** Click-Sound wird von Dirigent-Gerät abgespielt
- **Kein Einfluss** auf Musiker-Click (jeder steuert selbst)

### 7.2 Musiker-Seite

- **Toggle:** Lokaler Audio-Click EIN/AUS
- **Default:** AUS (nicht alle Musiker wollen Click hören)
- **Speicherung:** Geräte-Einstellung, persistent

### 7.3 Click-Sounds

- **Zählzeit 1:** Höherer Ton (Holzblock hoch, ~800Hz)
- **Andere Zählzeiten:** Niedrigerer Ton (Holzblock tief, ~600Hz)
- **Latenz-kompensiert:** Click-Wiedergabe berücksichtigt `Latenz-Kompensation`-Einstellung

---

## 8. Verbindungs-Status & Latenz-Kompensation

### 8.1 Verbindungs-Badge (Dirigent-View)

```
● 12 verbunden
```

| Zustand | Farbe | Text |
|---------|-------|------|
| Verbunden, alle synced | `color-success` | `● N verbunden` |
| Verbunden, einige mit hoher Latenz | `color-warning` | `⚠ N verbunden (hohe Latenz)` |
| Keine Verbindung | `color-error` | `✗ Offline` |
| Verbindet... | `color-text-secondary` | `↺ Verbindet...` |

### 8.2 Verbundene-Musiker-Liste (Dirigent, Detail-View)

Tippen auf Badge → Bottom Sheet mit Liste:

```
┌──────────────────────────────────┐
│  ────  (Handle)                  │
│  Verbundene Musiker   [12 / 14]  │
│  ─────────────────────────────── │
│  ✓ Max Müller      WiFi  3ms    │
│  ✓ Anna Huber      WiFi  5ms    │
│  ✓ Tom Schmidt     WiFi  8ms    │
│  ⚠ Lisa Weber      WiFi  42ms   │ ← Warnung
│  ✗ Klaus Bauer     offline      │ ← Nicht verbunden
│  ...                             │
│  ─────────────────────────────── │
│  Ø Latenz: 8ms · Max: 42ms      │
└──────────────────────────────────┘
```

- **Schwellwerte:**
  - < 20ms: Grün (✓)
  - 20–50ms: Orange (⚠)
  - > 50ms: Rot (✗)

### 8.3 Verbindungs-Modus-Anzeige

Im Header des Musiker-Views:
- `WiFi` Icon + `● UDP` — LAN-Modus (< 5ms)
- `WiFi` Icon + `● WS` — WebSocket-Fallback (< 50ms)
- `✗` — Kein Metronom-Empfang

### 8.4 Latenz-Kompensation (Musiker)

Zugang: Kleines `[⚙]` Icon → Inline-Slider:

```
┌─────────────────────────────────────┐
│  Latenz-Kompensation                │
│                                     │
│  [−] ●────────────────○ [+]        │
│  -100ms              +100ms         │
│  Aktuell: +15 ms                    │
│                                     │
│  Tipp: Erhöhe den Wert, wenn du     │
│  den Beat zu früh siehst.           │
└─────────────────────────────────────┘
```

- **Bereich:** −100ms bis +100ms
- **Step:** 5ms
- **Default:** 0ms
- **Speicherung:** Geräte-Einstellung

---

## 9. Micro-Interactions & Animationen

### 9.1 Beat-Flash (Musiker-View)

| Schlag | Animation | Dauer | Kurve |
|--------|-----------|-------|-------|
| Zählzeit 1 | Vollständiger Farb-Flash (Weiß → Orange → Weiß) | 80ms hin, 120ms zurück | `AppCurves.easeOut` / `AppCurves.easeIn` |
| Andere Zählzeiten | Partieller Flash (Weiß → Hellblau → Weiß) | 60ms hin, 100ms zurück | `AppCurves.easeOut` |
| Takt-Position ● | Scale 1.0 → 1.4 → 1.0 | 100ms | `AppCurves.easeInOut` |

### 9.2 Start/Stop (Dirigent)

| Aktion | Animation |
|--------|-----------|
| Start-Tap | Button Scale 0.95, 150ms → Metronom-Zähler erscheint |
| Erster Beat nach Start | Beat-Flash startet sofort (kein Vorlauf) |
| Stop-Tap | Button-Farbe Rot → Grün in 250ms, Beat-Anzeige fades out |

### 9.3 Verbindung herstellen

- Loading-Spinner für max. 2 Sekunden
- Bei UDP-Erfolg: Kurzes Aufflackern des Status-Badge (Grün)
- Bei Fallback zu WebSocket: Badge wechselt Farbe + kleine Toast-Meldung: „Verbunden via Internet (WebSocket)"

### 9.4 BPM-Änderung während laufendem Metronom

- BPM-Änderung wirkt beim **nächsten Taktbeginn** (nicht mitten im Takt)
- Visuelles Feedback: BPM-Zahl kurz hervorgehoben (`color-primary`, 300ms)

---

## 10. Wireframes: Phone

### 10.1 Dirigent-View (Phone, Portrait)

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ Metronom    ● 8 verbunden │
├───────────────────────────┤
│                           │
│          120              │
│          BPM              │
│                           │
│ [−−][−] ●──────────○[+][++]│
│  60                  200  │
│                           │
│ [2/4][3/4][4/4][6/8][…]  │
│                           │
│ ┌───────────────────────┐ │
│ │ 🔊 Audio-Click   EIN │ │
│ └───────────────────────┘ │
│                           │
│ ┌───────────────────────┐ │
│ │   🎵 Tap Tempo        │ │
│ └───────────────────────┘ │
│                           │
│ ● ○ ○ ○                  │
│                           │
│ ┌───────────────────────┐ │
│ │   ▶  START            │ │
│ └───────────────────────┘ │
│                           │
├───────────────────────────┤
│ 🎵  📚  🔧  👤            │
└───────────────────────────┘
```

### 10.2 Musiker-View (Phone, Portrait)

```
┌───────────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●●●●● │
├───────────────────────────┤
│ Metronom  ●WiFi  120·4/4 │
├───────────────────────────┤
│                           │
│                           │
│   ┌───────────────────┐   │
│   │                   │   │
│   │     ████████      │   │  ← Beat-Fläche (pulsiert)
│   │    ██████████     │   │
│   │     ████████      │   │
│   │                   │   │
│   └───────────────────┘   │
│                           │
│      1●  2○  3○  4○      │
│                           │
│ ┌───────────────────────┐ │
│ │ 🔊 Audio-Click  AUS  │ │
│ └───────────────────────┘ │
│                           │
│ Latenz: +0ms         [⚙] │
│                           │
├───────────────────────────┤
│ 🎵  📚  🔧  👤            │
└───────────────────────────┘
```

---

## 11. Wireframes: Tablet & Desktop

### 11.1 Dirigent-View (Tablet, Landscape)

```
┌──────────────────────────────────────────────────┐
│ Metronom                         ● 12 verbunden  │
├──────────────────────┬───────────────────────────┤
│                      │  Verbundene Musiker       │
│       120            │  ✓ Max Müller    3ms      │
│       BPM            │  ✓ Anna Huber    5ms      │
│                      │  ⚠ Lisa Weber   42ms      │
│ [−−][−]●────○[+][++] │  ✗ Klaus Bauer  offline   │
│  60           200    │                           │
│                      │  ─────────────────────    │
│ [2/4][3/4][4/4][6/8] │  Ø 8ms · Max 42ms        │
│                      │                           │
│ 🔊 Audio-Click  EIN  │                           │
│                      │                           │
│ ● ○ ○ ○              │                           │
│                      │                           │
│ [🎵 Tap Tempo]       │                           │
│                      │                           │
│ [────▶ START ────]   │                           │
│                      │                           │
└──────────────────────┴───────────────────────────┘
```

### 11.2 Musiker-View (Tablet, Portrait)

```
┌────────────────────────────────────────┐
│  Metronom         ● WiFi (UDP)         │
│                   120 BPM · 4/4        │
├────────────────────────────────────────┤
│                                        │
│         ┌──────────────────────┐       │
│         │                      │       │
│         │       ████████       │       │  ← Beat-Fläche (groß)
│         │      ██████████      │       │
│         │     ████████████     │       │
│         │      ██████████      │       │
│         │       ████████       │       │
│         │                      │       │
│         └──────────────────────┘       │
│                                        │
│            1●   2○   3○   4○          │
│                                        │
│  🔊 Audio-Click                  AUS  │
│  Latenz-Kompensation: +0ms       [⚙] │
│                                        │
└────────────────────────────────────────┘
```

---

## 12. Accessibility

### 12.1 Touch-Targets

| Element | Mindestgröße | Ist-Größe |
|---------|-------------|-----------|
| Start/Stop Button | 72×72 px | 200×72 px |
| BPM Stepper `[−]`/`[+]` | 48×48 px | 48×48 px |
| BPM `[−−]`/`[++]` | 48×48 px | 48×48 px |
| Taktart-Chips | 48×44 px | 64×44 px |
| Tap-Tempo Button | 64×64 px | 100% Breite × 56px |
| Audio-Click Toggle | 44×44 px | 100% Breite × 48px |

### 12.2 Screen-Reader

- **BPM-Wert:** `Semantics(label: "120 BPM", onTap: "BPM bearbeiten")`
- **Start-Button:** `Semantics(label: "Metronom starten")` / `Semantics(label: "Metronom stoppen")`
- **Beat-Fläche:** `Semantics(label: "Beat-Anzeige, Zählzeit 1 von 4", liveRegion: true)` — aktualisiert bei jedem Beat
- **Verbindungs-Badge:** `Semantics(label: "12 Musiker verbunden")`

### 12.3 Reduced Motion

- Bei `prefers-reduced-motion`: Beat-Flash ohne Größen-Animation (nur Farb-Wechsel)
- Tap-Tempo: kein Scale-Effekt

### 12.4 Farb-unabhängige Informationen

- Takt-Position: Kreis gefüllt/leer (nicht nur Farbe)
- Verbindungs-Status: Icon + Text (nie nur Farbe)

---

## 13. Responsiveness

| Breakpoint | Dirigent-Layout | Musiker-Layout |
|------------|----------------|----------------|
| Phone Portrait | Einspaltiges Scroll-Layout | Beat-Fläche zentriert, groß |
| Phone Landscape | Zweispaltig: Links BPM/Taktart, Rechts Controls | Beat-Fläche links, Takt-Info rechts |
| Tablet Portrait | Wie Phone, größere Targets | Große Beat-Fläche (70% Breite) |
| Tablet Landscape | Zweispaltig: Links Steuerung, Rechts Verbundene-Musiker | Beat-Fläche zentriert |
| Desktop | Dreispaltig: Settings │ Steuerung │ Musiker-Liste | Beat-Fläche zentriert (500px max) |

---

## 14. Error States & Edge Cases

### 14.1 Kein Metronom aktiv (Musiker-View)

```
┌────────────────────────────────────────┐
│                                        │
│              🎵                        │
│                                        │
│    Kein Metronom aktiv                 │
│    Der Dirigent hat noch kein          │
│    Metronom gestartet.                 │
│                                        │
│    Warte auf Dirigent...               │
│                      ↺                 │
└────────────────────────────────────────┘
```

- Spinner dreht sich (zeigt: App verbunden, wartet aktiv)
- Wenn Dirigent startet: automatische Transition, kein Tap nötig

### 14.2 Verbindung verloren (Musiker)

```
┌──────────────────────────────────────────┐
│  ⚠ Verbindung unterbrochen              │
│  Metronom-Sync pausiert · Reconnect...   │
└──────────────────────────────────────────┘
```

- Gelbes Banner oben (über Beat-Fläche)
- Beat-Fläche dimmed (50% Opacity) — zeigt: Daten können veraltet sein
- Auto-Reconnect: unsichtbar wenn < 3 Sekunden, Banner wenn ≥ 3 Sekunden

### 14.3 BPM-Änderung während laufendem Metronom

- BPM-Änderung durch Slider: **Live-Vorschau** im Mini-Indikator des Dirigent-Views
- **Keine sofortige Übertragung** während Drag — erst wenn Finger losgelassen
- **Taktgebundene Wirkung:** Neue BPM gelten ab dem nächsten Taktstrich

### 14.4 Falscher BPM-Wert (< 40 oder > 240)

- Stepper hat harte Grenzen (40–240)
- Direkteingabe: Wenn > 240 eingegeben → auf 240 clampen + kurze Vibration

### 14.5 Nur ein Nutzer (kein Metronom-Netzwerk)

- Dirigent-View funktioniert **vollständig offline** als lokales Metronom
- Verbindungs-Badge: `✗ Offline · Nur lokal`
- Beat-Click und visuelle Anzeige funktionieren normal

### 14.6 Session-Kollision (zwei Dirigenten)

Wenn zweiter Dirigent Metronom starten will während erstes läuft:

```
┌──────────────────────────────────────────────────┐
│  Metronom bereits aktiv                          │
│                                                  │
│  Klaus Bauer hat ein Metronom gestartet.         │
│  (120 BPM · 4/4)                                 │
│                                                  │
│  Möchtest du die Kontrolle übernehmen?           │
│                                                  │
│  [Abbrechen]           [Übernehmen]              │
└──────────────────────────────────────────────────┘
```

- Alter Dirigent erhält: `⚠ Metronom-Kontrolle übernommen von Anna Huber`

---

## 15. Integration mit Navigation (GoRouter)

### 15.1 Routen

```
/tools/metronome              → Metronom (rollenbasiert: Dirigent / Musiker)
/tools/metronome/settings     → Latenz-Kompensation + Audio-Click (Musiker)
```

### 15.2 Persistent Beat-Banner

Falls Musiker auf anderen Screen wechselt während Metronom läuft:
```
┌──────────────────────────────────────┐
│ ● Metronom · 120 BPM · 1/4  [Öffnen]│  ← Sticky Banner (40px hoch)
└──────────────────────────────────────┘
```
- Erscheint am unteren Rand **über** der Bottom-Navigation
- Beat-Flash als kleiner Punkt im Banner (subtil, nicht störend)
- Tippen → springt zurück zu Metronom-Screen

### 15.3 Deep-Links

```
sheetstorm://tools/metronome
```

---

## 16. Abhängigkeiten

### 16.1 Für Implementierung (Hill / Banner)

- **UDP Multicast:** ASP.NET Core UDP-Server + Flutter UDP-Client
- **SignalR WebSocket:** Fallback für Remote/Internet
- **Automatische Erkennung:** WiFi-Netz → UDP, sonst → WebSocket
- **NTP-ähnliche Synchronisation:** Timestamps, nicht Live-Kommandos
- **Audio Click:** Flutter `audioplayers` oder `just_audio`

### 16.2 Offene Entscheidungen für Thomas

- **Beat-Fläche Form:** Quadrat vs. Kreis vs. Vollbild-Flash — alle drei Optionen möglich. Vollbild-Flash ist am auffälligsten, aber könnte störend sein bei gleichzeitigem Notenlesen.
- **Musiker-View im Spielmodus:** Soll das Persistent-Beat-Banner auch im Spielmodus (Noten-Vollbild) erscheinen? Widerspricht leicht dem Focus-First-Prinzip.
