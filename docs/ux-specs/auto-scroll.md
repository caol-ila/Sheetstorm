# UX-Spec: Auto-Scroll / Reflow (Spielmodus-Erweiterung)

> **Issue:** MS3 — Auto-Scroll / Reflow  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-specs/spielmodus.md`, `docs/ux-design.md §3.1`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [Integration in den Spielmodus](#2-integration-in-den-spielmodus)
3. [User Flow: Auto-Scroll aktivieren](#3-user-flow-auto-scroll-aktivieren)
4. [Geschwindigkeits-Steuerung](#4-geschwindigkeits-steuerung)
5. [Play / Pause / Reset Controls](#5-play--pause--reset-controls)
6. [BPM-basierter Modus](#6-bpm-basierter-modus)
7. [Manueller Modus](#7-manueller-modus)
8. [Scroll-Verhalten & Übergänge](#8-scroll-verhalten--übergänge)
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

> „Der Musiker übt alleine. Er will mitspielen — nicht blättern. Auto-Scroll übernimmt die Seite."

Auto-Scroll löst ein echtes Problem beim Solo-Üben: Der Musiker muss mit einer Hand oder einem Pedal blättern, während er spielt. Auto-Scroll scrollt die Noten automatisch, sodass beide Hände frei bleiben.

### 1.2 Kontext

**Wer:** Musiker beim Üben zuhause, Üben ohne Fußpedal
**Wann:** Solo-Üben, Vorspielen, Durchlaufen von Stücken
**Gerät:** Tablet (primär), Handy (sekundär), Desktop-Ständer

### 1.3 Designprinzipien

| Prinzip | Auswirkung |
|---------|-----------|
| **Kein separater Screen** | Auto-Scroll ist im Spielmodus integriert, kein Modus-Wechsel |
| **Sofort startbar** | Ein Tap → läuft. Keine Konfiguration erzwungen |
| **Manuell überschreibbar** | Nutzer kann jederzeit tippen/wischen und übernimmt Kontrolle |
| **Kein Verstecken** | Controls bleiben sichtbar (subtil) während Scroll läuft |
| **Pause ist sicher** | Jederzeit pausierbar ohne Positionsverlust |

---

## 2. Integration in den Spielmodus

### 2.1 Kein neuer Screen — Erweiterung des Overlays

Auto-Scroll ist **kein eigener Modus** — es ist ein Feature des Spielmodus-Overlays.

```
Spielmodus-Overlay (kurzer Tap auf Mitte)
         │
         ▼
   Overlay öffnet → enthält jetzt: [▶ Auto-Scroll]
         │
         ▼
   Tap auf [▶ Auto-Scroll] → Controls erscheinen am unteren Rand
   Notenblatt bleibt im Vordergrund
```

### 2.2 Positions-Hierarchie im Spielmodus

```
┌───────────────────────────────────┐
│     [Overlay-Header] (wenn offen) │  ← Oben
├───────────────────────────────────┤
│                                   │
│       NOTENBLATT                  │  ← Hauptfläche (immer)
│       (scrollt automatisch)       │
│                                   │
├───────────────────────────────────┤
│  [▶ 120 BPM] [■] [⟳] [−][+]     │  ← Auto-Scroll Controls (unten, immer sichtbar)
└───────────────────────────────────┘
```

Die Auto-Scroll-Controls nehmen **40px** am unteren Rand ein. Das Notenblatt wird um 40px nach oben verschoben (kein Überlappen).

---

## 3. User Flow: Auto-Scroll aktivieren

```
Spielmodus (Vollbild, normaler Zustand)
        │
        ▼
  Option A: Overlay öffnen → [▶ Auto-Scroll starten]
        │
  Option B: Dedicated Button in Spielmodus-Toolbar (Fußzeile-Button)
        │
        ▼
  Auto-Scroll-Control-Bar erscheint am unteren Rand (Slide-in von unten)
  Notenblatt-Höhe reduziert sich um 40px (kein Abschneiden)
        │
        ├──── Sofort starten mit letzter BPM/Geschwindigkeits-Einstellung
        │
        ▼
  [▶ Play] tippen → Scroll beginnt
        │
        ├──── Manueller Eingriff möglich (§5.4)
        │
        └──── [■ Stop] tippen → Scroll stoppt, Position bleibt
```

---

## 4. Geschwindigkeits-Steuerung

### 4.1 Zwei Modi

| Modus | Trigger | Verwendung |
|-------|---------|-----------|
| **BPM-basiert** | Metronom läuft oder BPM aus Stück-Metadaten | Synchrones Spielen zur Aufnahme |
| **Manuell (px/s)** | Default wenn kein BPM bekannt | Freies Üben |

### 4.2 Geschwindigkeits-Control

```
  [−] ●────────────────○ [+]
  0.5×                 3×
```

- **Bereich:** 0.5× bis 3× der Basis-Geschwindigkeit
- **Faktor 1.0×:** Entspricht ca. 1 Seite pro Minute (typisches Blasmusik-Tempo)
- **Stepper:** `[−]` / `[+]` je 0.1× Schritt
- **Slider:** Direktes Ziehen für größere Änderungen
- **Anzeige:** `1.2×` oder `120 BPM` (je nach Modus)

### 4.3 Geschwindigkeit während Scroll ändern

- Änderung wirkt **sofort** (nicht abwarten)
- Kein Ruckeln — sanfte Beschleunigung/Verlangsamung über 500ms

---

## 5. Play / Pause / Reset Controls

### 5.1 Control-Bar Layout

```
┌─────────────────────────────────────────────┐
│  [■ Stop]  [▶ Play]  [⟳ Reset]  [−] 1.0× [+] │
└─────────────────────────────────────────────┘
```

Kompakte Variante (Phone, 40px Höhe):
```
┌─────────────────────────────────────────────┐
│  [■] [▶] [⟳]              [−] 1.0× [+]     │
└─────────────────────────────────────────────┘
```

### 5.2 Button-Zustände

| Button | Gestoppt | Läuft | Pausiert |
|--------|----------|-------|----------|
| **Play ▶** | Aktiv, grün | Ausgeblendet | Aktiv, grün |
| **Pause ⏸** | Ausgeblendet | Aktiv | Ausgeblendet |
| **Stop ■** | Inaktiv (grau) | Aktiv, rot | Aktiv |
| **Reset ⟳** | Aktiv | Aktiv | Aktiv |

### 5.3 Button-Größen

| Button | Mindestgröße | Bemerkung |
|--------|-------------|-----------|
| Play/Pause | 48×40 px | Primäre Aktion |
| Stop | 44×40 px | Sekundäre Aktion |
| Reset | 44×40 px | Tertiäre Aktion |
| Stepper `[−]`/`[+]` | 44×40 px | |

### 5.4 Manueller Eingriff während Auto-Scroll

Wenn Nutzer auf Notenblatt tippt oder wischt während Auto-Scroll läuft:

**Option A (Pause-bei-Eingriff):**
- Auto-Scroll pausiert sofort
- Position verschoben zu getippter Stelle
- Play-Button erscheint → Nutzer entscheidet ob er weitermacht

**Option B (Weiter-nach-Eingriff):**
- Auto-Scroll läuft weiter von neuer Position

→ **Empfehlung Wanda:** Option A. Der Nutzer übernimmt aktiv die Kontrolle — das sollte respektiert werden. Auto-Scroll nach manuellem Eingriff fortzusetzen wäre überraschend.

### 5.5 Reset

- Stoppt Scroll
- Springt zurück zu Anfang des Stücks (Seite 1, Position oben)
- **Kein Bestätigen** — Reset ist keine Destructive Action

---

## 6. BPM-basierter Modus

### 6.1 BPM-Quelle

Priorität (absteigende Reihenfolge):
1. **Echtzeit-Metronom** läuft → BPM vom Metronom übernehmen (live)
2. **Stück-Metadaten** haben BPM-Angabe → als Startpunkt verwenden
3. **Letzte manuelle Eingabe** → wiederverwenden
4. **Default:** 100 BPM

### 6.2 BPM-Verknüpfung mit Metronom

Wenn Metronom aktiv:
```
  [▶ 120 BPM] [■] [⟳]    BPM: Vom Metronom ⟲
```
- BPM-Wert in Control-Bar zeigt aktuellen Metronom-Wert
- Stepper `[−]`/`[+]` deaktiviert (grau) — Metronom hat Kontrolle
- Kleines `⟲`-Icon zeigt „live verknüpft"

Wenn Metronom nicht aktiv:
- Stepper aktiv, manuell einstellbar

### 6.3 BPM → Scrollgeschwindigkeit Berechnung

Die Umrechnung von BPM in Scrollgeschwindigkeit hängt von:
- Anzahl Takte pro Seite (aus PDF-Analyse, wenn verfügbar)
- Taktart
- Manuell kalibrierbarer Faktor (§7)

---

## 7. Manueller Modus

### 7.1 Wann aktiv?

- Default wenn kein BPM bekannt
- Explizit wählbar über `[BPM-Modus ↔ Manuell]` Toggle in Control-Bar (nur auf Tablet/Desktop sichtbar)

### 7.2 Kalibrierung

Erstes Mal Auto-Scroll für dieses Stück aktiviert → optional:

```
┌──────────────────────────────────────────────┐
│  Geschwindigkeit einstellen                  │
│                                              │
│  [−] ●────────────────○ [+]                 │
│  Langsam                  Schnell            │
│                                              │
│  Tipp: Mit 1.0× starten und anpassen.       │
│                                              │
│  [Start]         [Ohne Einstellung starten] │
└──────────────────────────────────────────────┘
```

- Dieser Dialog erscheint **nur beim ersten Start** — danach startet sofort mit letzter Einstellung
- „Ohne Einstellung starten" → `1.0×` Default

---

## 8. Scroll-Verhalten & Übergänge

### 8.1 Scroll-Typ

**Kontinuierliches vertikales Scrollen** (kein Seitenwechsel):
- PDF wird als kontinuierliche Rolle angezeigt
- Seiten gehen nahtlos ineinander über
- Kein Seitenflip — fließender Scroll

**Begründung:** Beim Seitenwechsel gibt es eine Unterbrechung — der Musiker verliert kurz die Position. Kontinuierliches Scrollen ist beim Üben natürlicher.

### 8.2 Seiten-Übergänge

Zwischen Seiten: kleiner Abstand (8px) als visueller Trenner, aber kein harter Schnitt.

### 8.3 Scroll-Endpunkt

Wenn letzte Seite erreicht:
- Scroll stoppt automatisch
- Auto-Scroll geht in „Pausiert"-Zustand
- Position bleibt am Ende

### 8.4 Vorausschauen

Ein kleiner Vorlauf von ~20% der nächsten Seite ist sichtbar, bevor Auto-Scroll weitergeht. So ist der Musiker immer einen Moment voraus (wie beim Blattlesen).

---

## 9. Micro-Interactions & Animationen

### 9.1 Control-Bar erscheint / verschwindet

| Aktion | Animation | Dauer | Kurve |
|--------|-----------|-------|-------|
| Control-Bar einblenden | Slide-in von unten | 250ms | `AppCurves.easeOut` |
| Control-Bar ausblenden | Slide-out nach unten | 200ms | `AppCurves.easeIn` |
| Notenblatt schrumpft | Höhe −40px | 250ms | `AppCurves.easeOut` |

### 9.2 Play / Pause

| Aktion | Animation |
|--------|-----------|
| Play tippen | Button-Icon wechselt ▶ → ⏸, Scale-Pulse 0.9→1.0, 150ms |
| Pause tippen | ⏸ → ▶, gleiche Animation |
| Scroll startet | Noten beginnen sanft zu scrollen (keine sofortige Vollgeschwindigkeit, 300ms Anlauf) |
| Scroll pausiert | Sanftes Ausrollen (300ms Auslauf) |

### 9.3 Geschwindigkeit ändern

- Stepper-Tap: Feedback-Pulse (Scale 1.0 → 1.1 → 1.0), 100ms
- Geschwindigkeit-Zahl: animierter Ziffernwechsel

### 9.4 Manueller Eingriff → Pause

- Auto-Scroll-Symbol in Control-Bar: kurzes Blinken (3×, 100ms je), dann ⏸-Zustand
- Notenblatt: kein eigenes Feedback (zu störend)

---

## 10. Wireframes: Phone

### 10.1 Spielmodus mit Auto-Scroll aktiv (läuft)

```
┌───────────────────────────┐
│                           │  ← Status Bar
│  ═════════════════════   │
│  ♩ ♪   ♩  ♪    ♪   ♩   │
│  ♩ ♪   ♩  ♪    ♪   ♩   │
│                           │
│  ♩ ♪   ♩  ♪    ♪   ♩   │
│  ♩ ♪   ♩  ♪    ♪   ♩   │
│  ═════════════════════   │
│                           │  ← Kontinuierlich scrollend ↑
│  ═════════════════════   │  ← Nächste Seite bereits sichtbar
│  ♩ ♪   ♩  ♪    ♪   ♩   │
├───────────────────────────┤
│  [■][⏸][⟳]    [−]1.0×[+] │  ← Control-Bar (40px)
└───────────────────────────┘
```

### 10.2 Spielmodus mit Auto-Scroll pausiert

```
┌───────────────────────────┐
│                           │
│  (Notenblatt — statisch)  │
│                           │
├───────────────────────────┤
│  [■][▶][⟳]    [−]1.0×[+] │  ← ▶ statt ⏸
└───────────────────────────┘
```

### 10.3 Overlay mit Auto-Scroll-Einstieg

```
┌───────────────────────────┐
│ ← Zurück  Seite 3/12  ⚙  │
├───────────────────────────┤
│  (Notenblatt)             │
├───────────────────────────┤
│  [▶ Auto-Scroll starten]  │  ← Im Overlay
│  ─────────────────────    │
│  Stimme   | ○ Annotationen│
│  Nachtmodus          AUS  │
└───────────────────────────┘
```

---

## 11. Wireframes: Tablet & Desktop

### 11.1 Tablet (Landscape)

```
┌────────────────────────────────────────────────────┐
│                                                    │
│  ════════════════════════════════════════════════  │
│  ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩          │
│  ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩          │
│                                                    │
│  ════════════════════════════════════════════════  │
│                              ↑ Scrollt             │
├────────────────────────────────────────────────────┤
│  [■ Stop]  [⏸ Pause]  [⟳ Reset]   BPM-Modus       │
│                              [−] 1.0× [+]   [⟲ Metronom] │
└────────────────────────────────────────────────────┘
```

### 11.2 Desktop

```
┌─────────────────────────────────────────────────────────────┐
│  Sheetstorm             Spielmodus: Sonate Nr. 3            │
├────────────────────────────────────────────────────────────-┤
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩         │
│  ...                            ↑ scrollt automatisch       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [■ Stop]  [⏸ Pause]  [⟳ Anfang]   Modus: [BPM ● | Manuell]│
│  Geschwindigkeit: [────●────] 1.0×   [−] [+]               │
│  BPM: 120 (vom Metronom ⟲)                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 12. Accessibility

### 12.1 Touch-Targets

| Element | Mindestgröße |
|---------|-------------|
| Play/Pause | 48×48 px |
| Stop | 48×48 px |
| Reset | 48×48 px |
| Stepper `[−]`/`[+]` | 48×48 px |
| Geschwindigkeits-Slider | 44px Höhe |

### 12.2 Screen-Reader

- **Play-Button:** `Semantics(label: "Auto-Scroll starten")` / `"Auto-Scroll pausieren"`
- **Stop-Button:** `Semantics(label: "Auto-Scroll stoppen")`
- **Reset-Button:** `Semantics(label: "Zum Anfang zurückspringen")`
- **Geschwindigkeit:** `Semantics(label: "Scroll-Geschwindigkeit: 1.0 fach", onIncrease: "Erhöhen", onDecrease: "Verringern")`
- **Status:** `Semantics(liveRegion: true)` wenn Scroll-Status wechselt

### 12.3 Tastatur (Desktop)

| Taste | Aktion |
|-------|--------|
| Leertaste | Play / Pause |
| Escape | Stop |
| Pos1 | Reset (Anfang) |
| `+` / `-` | Geschwindigkeit erhöhen / verringern |

### 12.4 Reduced Motion

- Bei `prefers-reduced-motion`: kein kontinuierliches Scrollen → seitenweises Scrollen stattdessen (automatischer Seitenwechsel alle N Sekunden)

---

## 13. Responsiveness

| Breakpoint | Control-Bar | Geschwindigkeits-Control |
|------------|-------------|--------------------------|
| Phone Portrait | Kompakte Bar (Icon-only für Stop/Play/Reset) | Stepper `[−] 1.0× [+]` |
| Phone Landscape | Erweiterte Bar | Slider + Stepper |
| Tablet | Volle Bar mit Labels | Slider + Stepper + Modus-Toggle |
| Desktop | Volle Bar mit Labels | Slider + Stepper + Modus-Toggle + Keyboard-Shortcuts |

---

## 14. Error States & Edge Cases

### 14.1 Stück ohne Seiten (leeres PDF)

- Auto-Scroll deaktiviert (Button inaktiv, grau)
- Kein Fehler-Dialog — Button-Zustand kommuniziert alles

### 14.2 Stück mit nur einer Seite

- Auto-Scroll funktioniert (scrollt bis Ende, stoppt)
- Kein Unterschied in der UI

### 14.3 Sehr schnelle Einstellung (3×)

- Visuell funktioniert's — aber Noten werden zu schnell, um gelesen zu werden
- Kein Warnung-Dialog — Nutzer entscheidet selbst
- Stepper erlaubt 3× Maximum (harte Grenze)

### 14.4 Sehr langsame Einstellung (0.1×)

- Minimale Grenze: 0.3× (unter 0.3 ist es de facto Pause)
- Falls unter 0.3 eingegeben: auf 0.3 clampen

### 14.5 App in Hintergrund während Scroll

- Scroll pausiert automatisch (App nicht sichtbar)
- Beim Zurückkommen: Scroll weiter in Pause-Zustand
- Nutzer entscheidet ob er weiterläuft

### 14.6 Fußpedal + Auto-Scroll gleichzeitig

- Fußpedal-Tap: übernimmt Kontrolle, pausiert Auto-Scroll
- Gleiche Logik wie manueller Eingriff (§5.4)

### 14.7 BPM-Wechsel während Scroll (Metronom-Verbindung)

- Neue BPM: Geschwindigkeit passt sich innerhalb 500ms sanft an
- Kein abrupter Sprung

---

## 15. Integration mit Navigation (GoRouter)

### 15.1 Kein eigener Screen

Auto-Scroll ist Teil des Spielmodus — keine eigene Route.

### 15.2 Scroll-Position persistieren

- Position beim Verlassen des Spielmodus gespeichert (wie bisher)
- Auto-Scroll-Zustand wird **nicht** persistiert — jedes Mal manuell starten

---

## 16. Abhängigkeiten

### 16.1 Für Implementierung (Hill)

- **Kontinuierliches Scrollen:** PDF-Renderer muss alle Seiten als vertikale Rolle rendern (kein Seiten-Flip-Modus)
- **Scroll-Controller:** `ScrollController` mit programmatischer Steuerung (BPM → px/s)
- **BPM-Verknüpfung:** Stream von Metronom-BPM-Änderungen → Auto-Scroll-Speed-Controller

### 16.2 Offene Entscheidungen für Thomas

- **Manueller Eingriff → Pause oder Weiter?** (§5.4 — Empfehlung: Pause)
- **Scroll-Typ:** Kontinuierlich (empfohlen) oder Seiten-weise mit Auto-Flip?
- **Reduced Motion:** Seiten-weise Variante für Nutzer mit Reduced-Motion-Präferenz?
