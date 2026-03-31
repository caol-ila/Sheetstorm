# UX-Spec: Stimmgerät (Tuner)

> **Issue:** MS3 — Stimmgerät  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-design.md §3.8`, `docs/ux-konfiguration.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [User Flow: Tuner öffnen & nutzen](#2-user-flow-tuner-öffnen--nutzen)
3. [Haupt-Screen: Tuner-Ansicht](#3-haupt-screen-tuner-ansicht)
4. [Kammerton-Kalibrierung](#4-kammerton-kalibrierung)
5. [Transpositions-Umschaltung](#5-transpositions-umschaltung)
6. [Micro-Interactions & Animationen](#6-micro-interactions--animationen)
7. [Wireframes: Phone](#7-wireframes-phone)
8. [Wireframes: Tablet & Desktop](#8-wireframes-tablet--desktop)
9. [Accessibility](#9-accessibility)
10. [Responsiveness](#10-responsiveness)
11. [Error States & Edge Cases](#11-error-states--edge-cases)
12. [Integration mit Navigation (GoRouter)](#12-integration-mit-navigation-gorouter)
13. [Abhängigkeiten](#13-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Der Tuner ist ein Werkzeug, kein Feature. Er muss so reagieren wie ein analoges Stimmgerät — und besser aussehen."

Der Tuner wird vor und während der Probe genutzt. Der Musiker hält sein Tablet oder Handy vor sich und stimmt sein Instrument. **Latenz unter 20ms ist nicht verhandelbar** — der Nutzer merkt Verzögerungen sofort und verliert das Vertrauen in das Gerät.

### 1.2 Designprinzipien für den Tuner

| Prinzip | Konkrete Auswirkung |
|---------|---------------------|
| **Lesbarkeit aus 1m** | Erkannter Ton: min. 72sp. Cent-Abweichung: min. 40sp. |
| **Live-Gefühl** | Nadel-Animation max. 16ms nach Audio-Ereignis (60fps) |
| **Kontextfrei nutzbar** | Tuner aus Bottom-Bar direkt erreichbar, kein Stück nötig |
| **Keine Ablenkung** | Minimalistische UI — nur das, was zum Stimmen nötig ist |
| **Handschuh-kompatibel** | Alle Touch-Targets ≥ 48×48 px |

### 1.3 Nutzungskontext

**Wer:** Musiker (alle Instrumente), Registerführer
**Wann:** Vor der Probe (5–10 min), kurz vor dem Auftritt, während der Pause
**Wo:** Proberaum (laut), Bühne (sehr laut), Zuhause (ruhig)
**Gerät:** Tablet primär, Handy sekundär

---

## 2. User Flow: Tuner öffnen & nutzen

```
Bottom-Navigation → "Werkzeuge" Tab (oder direktes Tuner-Icon)
        │
        ▼
  ┌─────────────────────────────┐
  │  Mikrofon-Permission?        │
  └──────┬──────────────────────┘
         │ Bereits erteilt            Noch nicht erteilt:
         ▼                            ▼
   Tuner sofort aktiv          Permission-Dialog (§11.1)
                                       │
                                       ▼
                                 Erteilt → Tuner aktiv
                                 Verweigert → Hinweis + Link
                                              zu Einstellungen
         │
         ▼
  ┌─────────────────────────────────────────────────────┐
  │  Tuner-Hauptscreen                                   │
  │  - Erkannter Ton anzeigen                            │
  │  - Cent-Abweichung als Nadel + Zahl                  │
  │  - Frequenz in Hz                                    │
  └────────────────────────────────────────────────────────┘
         │
         ├──── Kammerton ändern (§4) → Kalibrierungs-Sheet
         │
         ├──── Transposition ändern (§5) → Chip-Auswahl
         │
         └──── Tuner verlassen → Mikrofon stoppt automatisch
```

### 2.1 Zustandsdiagramm

```
[Tuner inaktiv / nicht sichtbar]
        │  Tab öffnen
        ▼
[Permission-Check]
        │  Erteilt
        ▼
[Tuner aktiv — Mikrofon läuft]  ◄──── Immer wenn Screen sichtbar
        │
        ├──→ [Ton erkannt — Anzeige aktualisiert]
        │
        ├──→ [Stille / kein Ton — Placeholder angezeigt]
        │
        └──→ [Screen verlassen] → Mikrofon stoppt (Datenschutz)
```

**Wichtig:** Das Mikrofon läuft **nur wenn der Tuner-Screen sichtbar ist**. Bei Navigation weg vom Screen stoppt es sofort.

---

## 3. Haupt-Screen: Tuner-Ansicht

### 3.1 Layout-Hierarchie (von oben nach unten)

```
┌──────────────────────────────────────────────────────┐
│  [Transposition: C | Bb | Eb | F]  [442 Hz ↕]        │  ← Toolbar (48px hoch)
├──────────────────────────────────────────────────────┤
│                                                        │
│                    ┌──────┐                            │
│                    │  C   │    ← Erkannter Ton (72sp+) │
│                    └──────┘                            │
│                                                        │
│              ─ 12 Cent ─                               │  ← Cent-Abweichung (40sp)
│                                                        │
│   ◄────────────────●──────────────────►               │  ← Nadel-Anzeige
│  -50             0              +50                    │
│                                                        │
│                  261.6 Hz                              │  ← Frequenz (24sp)
│                                                        │
│         [──────────────────────]                       │  ← Stimmbalken (Farbe)
│                                                        │
└──────────────────────────────────────────────────────┘
```

### 3.2 Erkannter Ton

- **Schriftgröße:** min. 72sp (aus 1m lesbar)
- **Schriftfamilie:** `AppTypography.displayLarge` (Monospace-Variante für Ton-Buchstaben)
- **Inhalt:** Ton + Oktave, z.B. `A4`, `C#3`, `Bb4`
- **Transponiert:** Falls Bb-Instrument: Klingendes A4 → Anzeige `H4` (transponierter Ton)
- **Kein Ton erkannt:** Großes `—` in `color-text-secondary`

### 3.3 Cent-Abweichung

- **Schriftgröße:** 40sp, Bold
- **Wert:** −50 bis +50 Cent, Einheit „Cent" kleingeschrieben daneben
- **Farb-Kodierung:**
  - 0 ± 5 Cent: `color-success` (#16A34A) — Grün, gestimmt
  - ± 5–15 Cent: `color-warning` (#D97706) — Orange, fast gestimmt
  - > ± 15 Cent: `color-error` (#DC2626) — Rot, weit daneben
- **Format:** `+12` oder `−7` (immer Vorzeichen, kein `0`)
- **Null:** Zeigt `♩` (Viertelnote-Symbol) in `color-success`

### 3.4 Nadel-Anzeige (Stimmbalken)

```
   ┌─────────────────────────────────────────────────────┐
   │◄ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ►│         │
   │ -50        -25       0       +25       +50          │
   │                      ▲                              │
   │                   Nadel                             │
   └─────────────────────────────────────────────────────┘
```

- **Nadel:** Vertikale Linie, 3px breit, Farbe = Cent-Farbe (Grün/Orange/Rot)
- **Animation:** `AppCurves.smooth`, `AppDurations.fast` (150ms) → fluide, kein Ruckeln
- **Mittelmarke:** Verstärkte Mittellinie (0 Cent), 4px breit, `color-primary`
- **Skalenbeschriftung:** −50, −25, 0, +25, +50 in `AppTypography.labelSmall`
- **Gefärbte Mittelzone:** ±5-Cent-Bereich leicht grün hinterlegt (`color-success` mit 10% Opacity)

### 3.5 Frequenz-Anzeige

- **Schriftgröße:** `AppTypography.titleMedium` (24sp)
- **Inhalt:** Frequenz in Hz mit einer Nachkommastelle, z.B. `440.0 Hz`
- **Farbe:** `color-text-secondary` — sekundäre Information

### 3.6 Stimmbalken (Zusatz-Visualisierung)

Horizontaler Balken am unteren Bildschirmrand:
- **Grüne Zone:** Mittige 10% des Balkens — korrekt gestimmt
- **Animation:** Balken bewegt sich horizontal mit dem Ton
- **Höhe:** 8px
- **Radius:** `AppSpacing.radiusFull`

---

## 4. Kammerton-Kalibrierung

### 4.1 Zugang

Tippen auf `[442 Hz ↕]` in der Toolbar → öffnet Bottom Sheet.

### 4.2 Kalibrierungs-Bottom-Sheet

```
┌─────────────────────────────────────────┐
│  ────────  (Drag-Handle)                │
│  Kammerton (A4)                  ✕      │
│  ─────────────────────────────────────  │
│                                         │
│    [−]   [ 4 4 2 H z ]   [+]           │
│                                         │
│  ●───────────────────── ○               │
│  415 Hz             460 Hz              │
│                                         │
│  Häufig genutzt:                        │
│  [ 440 ]  [ 441 ]  [ 442 ]  [ 443 ]    │
│                                         │
│         [Übernehmen]                    │
└─────────────────────────────────────────┘
```

- **Wertebereich:** 415–460 Hz (Slider + Stepper)
- **Stepper:** `[−]` / `[+]` je 0.5 Hz pro Tap, Long-Press → kontinuierliche Änderung
- **Vorschlagswerte:** 440 / 441 / 442 / 443 als schnelle Auswahl-Chips
- **Default:** 442 Hz (österreichischer Orchesterstandard)
- **Speicherung:** Kapellen-Ebene (gilt für alle Mitglieder als Default), überschreibbar pro Gerät
- **Sofortige Wirkung:** Tuner reagiert live auf Änderung während Sheet offen

### 4.3 Persistenz

- Kammerton wird in **Geräte-Konfiguration** gespeichert
- Beim ersten Start: Kapellen-Default (442 Hz)
- Änderung eines Musikers wirkt nur auf sein Gerät

---

## 5. Transpositions-Umschaltung

### 5.1 Chip-Auswahl in der Toolbar

```
[ C ] [ Bb ] [ Eb ] [ F ]
  ↑
Aktiv = filled chip (color-primary)
Inaktiv = outlined chip (color-border)
```

- **Tippen** → sofortiger Wechsel, kein Bestätigen nötig
- **Chip-Größe:** min. 48×32 px (Touch-Target 48×48 px inkl. Padding)
- **Beschriftung:** `C`, `Bb`, `Eb`, `F`
- **Default:** Aus Instrumentenprofil des Nutzers (konfiguriert beim Onboarding)

### 5.2 Bedeutung der Transposition

| Chip | Instrument | Beispiel | Klingend → Anzeige |
|------|------------|---------|---------------------|
| **C** | Klavier, Flöte, Oboe | `A4` klingend → `A4` | 1:1 |
| **Bb** | Klarinette, Trompete | `A4` klingend → `H4` | +1 Ton |
| **Eb** | Altsaxophon, Klarinette | `A4` klingend → `F#4` | +große Sexte |
| **F** | Waldhorn, Englischhorn | `A4` klingend → `E4` | +Quinte |

### 5.3 Instrument-Preset Verknüpfung

- Unter den Chips: `⚙ Instrument-Preset: Bb-Klarinette` als Hinweis-Text
- Tippen → springt zu Instrument-Profil in Einstellungen
- **Kein Zwang** — Transposition kann jederzeit manuell überschrieben werden

---

## 6. Micro-Interactions & Animationen

### 6.1 Ton-Erkennung

| Ereignis | Animation | Duration | Kurve |
|----------|-----------|----------|-------|
| Neuer Ton erkannt | Ton-Label fades in + leichte Scale 1.0→1.05→1.0 | `AppDurations.base` (250ms) | `AppCurves.easeOut` |
| Kein Ton (Stille) | Ton-Label fades zu `—` | `AppDurations.base` | `AppCurves.easeIn` |
| Nadel bewegt sich | Smooth interpolation (kein Sprung) | `AppDurations.fast` (150ms) | `AppCurves.smooth` |
| Gestimmt (±5 Cent) | Nadel + Hintergrund pulsieren kurz grün | 400ms einmalig | `AppCurves.easeInOut` |

### 6.2 Farb-Übergang

- Cent-Farbe wechselt **nicht abrupt** — `AnimatedColor`, 200ms
- Verhindert Flackern bei Grenzwerten (z.B. 4.9 → 5.1 Cent)

### 6.3 Gestimmt-Indikator

Wenn ±5 Cent für ≥ 1 Sekunde:
```
   ✓ Gestimmt
```
- Grüner Haken + Text erscheinen zentriert über dem Ton-Label
- Autohide nach 2 Sekunden
- Kein Sound (zu viel Lärm in der Probe)

### 6.4 Mikrofon-Eingangspegel (subtil)

Kleiner Pegel-Indikator am rechten Rand der Nadel-Anzeige:
- Zeigt ob Ton laut genug erkannt wird
- Grau = kein Signal, Grün = gutes Signal, Rot = Clipping (zu laut)
- **Mini-Darstellung:** 4px breiter Balken, 40px hoch

---

## 7. Wireframes: Phone

### 7.1 Hochformat (Portrait) — Standard

```
┌───────────────────────┐
│ ●●●●●●●●●●●●●●●●●●●● │  ← Status Bar
├───────────────────────┤
│ C  Bb  Eb  F  │442 Hz│  ← Toolbar (48px)
├───────────────────────┤
│                       │
│                       │
│         ┌───┐         │
│         │ A │         │  ← Erkannter Ton (72sp)
│         └───┘         │
│                       │
│      + 3 Cent         │  ← Cent-Abweichung (40sp, grün)
│                       │
│  ◄─────────●──────►  │  ← Nadel (nah an Mitte = grün)
│ -50       0      +50  │
│                       │
│       440.0 Hz        │  ← Frequenz (24sp, grau)
│                       │
│  ┌─────┬──┬────────┐  │  ← Stimmbalken
│  │     │██│        │  │
│  └─────┴──┴────────┘  │
│                       │
├───────────────────────┤
│ 🎵  📚  🔧  👤        │  ← Bottom Navigation
└───────────────────────┘
```

### 7.2 Querformat (Landscape) — Optional

Im Querformat zeigt das Phone-Layout Ton + Nadel nebeneinander:

```
┌────────────────────────────────────────────┐
│ C Bb Eb F │ 442Hz  ●●●●●●●●●●●●●●●●●●●●● │
├────────────────────────────────────────────┤
│           │                                │
│    ┌───┐  │  ◄──────────●──────────────►  │
│    │ A │  │ -50        0               +50 │
│    └───┘  │                                │
│  +3 Cent  │          440.0 Hz              │
│           │  ┌────────────────────────┐    │
│           │  │      ██               │    │
│           │  └────────────────────────┘    │
└────────────────────────────────────────────┘
```

---

## 8. Wireframes: Tablet & Desktop

### 8.1 Tablet (Portrait, 768px+)

```
┌───────────────────────────────────────────────┐
│  Stimmgerät                    C Bb Eb F │442 │
├───────────────────────────────────────────────┤
│                                               │
│                                               │
│                   ┌────────┐                  │
│                   │   A4   │                  │  ← 96sp
│                   └────────┘                  │
│                                               │
│                 + 3 Cent                      │  ← 48sp
│                                               │
│   ◄──────────────────────●──────────────►    │
│  -50            -25       0     +25      +50  │
│                                               │
│                   440.0 Hz                    │  ← 28sp
│                                               │
│    ┌────────────────────────────────────┐     │
│    │              ████                  │     │
│    └────────────────────────────────────┘     │
│                                               │
│    ─────────────────────────────────────      │
│    Zuletzt gestimmt: A4 (+1 Cent) · 14:32     │  ← Letzte Messung
│                                               │
└───────────────────────────────────────────────┘
```

### 8.2 Desktop (1024px+)

- **Zweispalten-Layout:** Links Tuner, rechts Kalibrierungs-Panel dauerhaft sichtbar (kein Bottom Sheet)
- Tuner-Bereich: 60% Breite, zentriert
- Kalibrierungs-Panel: 40% Breite, Kammerton-Slider + Transpositions-Info

```
┌────────────────────────────────────────────────────────┐
│ Sheetstorm          Tuner              [Einstellungen]  │
├─────────────────────────────┬──────────────────────────┤
│  [ C ] [Bb] [Eb] [ F ]     │  Kammerton                │
│                             │  ●────────────────○      │
│         ┌────────┐          │  415 Hz        460 Hz    │
│         │   A4   │          │  Aktuell: 442 Hz          │
│         └────────┘          │                          │
│           +3 Cent           │  ─────────────────────   │
│                             │  Schnellauswahl          │
│ ◄────────────────●──────►  │  [440] [441] [442] [443] │
│ -50     -25      0   +25  +50                          │
│                             │  ─────────────────────   │
│         440.0 Hz            │  Instrument-Preset        │
│                             │  Bb-Klarinette           │
│  ┌────────────────────────┐ │  [Ändern →]              │
│  │          ████          │ │                          │
│  └────────────────────────┘ │                          │
└─────────────────────────────┴──────────────────────────┘
```

---

## 9. Accessibility

### 9.1 Touch-Targets

| Element | Mindestgröße | Ist-Größe |
|---------|-------------|-----------|
| Transpositions-Chips | 48×48 px | 64×48 px inkl. Padding |
| Kammerton-Button | 48×48 px | 80×48 px |
| Stepper `[−]` / `[+]` | 48×48 px | 48×48 px |
| Kalibrierungs-Vorschlag-Chips | 44×44 px | 64×44 px |

### 9.2 Screen-Reader

- **Erkannter Ton:** `Semantics(label: "Erkannter Ton: A vier")` — Buchstabe + Zahl ausgeschrieben
- **Cent-Abweichung:** `Semantics(label: "Plus drei Cent, fast gestimmt")` — Zahl + Bewertung
- **Nadel:** `ExcludeSemantics()` — visuelles Element, Screen-Reader irrelevant
- **Gestimmt-Indikator:** `Semantics(liveRegion: true)` — automatische Ankündigung

### 9.3 Kontrast

- Alle Textfarben auf ihrem Hintergrund: WCAG AA min. (4.5:1)
- Grüner Text auf weißem Hintergrund: `#16A34A` auf `#FFFFFF` = 4.54:1 ✓
- Roter Text auf weißem Hintergrund: `#DC2626` auf `#FFFFFF` = 4.5:1 ✓

### 9.4 Reduced Motion

- Bei `prefers-reduced-motion`: Nadel-Animation deaktiviert → direktes Setzen der Position
- Ton-Erkennungs-Animation: kein Scale-Pulse, nur Opacity-Wechsel

---

## 10. Responsiveness

| Breakpoint | Layout-Änderung |
|------------|----------------|
| Phone Portrait (< 600px) | Standard-Layout (§7.1) |
| Phone Landscape (< 600px, breit) | Zweispaltig: Ton links, Nadel rechts |
| Tablet (600–1024px) | Vergrößerte Schrift (96sp Ton), Letzte-Messung-Zeile |
| Desktop (> 1024px) | Zweispalten: Tuner + Kalibrierungs-Panel nebeneinander |

**Adaptive Schriftgrößen:**

| Element | Phone | Tablet | Desktop |
|---------|-------|--------|---------|
| Erkannter Ton | 72sp | 96sp | 96sp |
| Cent-Abweichung | 40sp | 48sp | 48sp |
| Frequenz | 24sp | 28sp | 28sp |

---

## 11. Error States & Edge Cases

### 11.1 Mikrofon-Permission verweigert

```
┌───────────────────────────────────────────┐
│                                           │
│          🎤                               │
│                                           │
│    Mikrofon-Zugriff benötigt              │
│                                           │
│    Sheetstorm braucht dein Mikrofon,      │
│    um Töne zu erkennen.                   │
│                                           │
│    [Zu Einstellungen →]                   │
│    [Ohne Mikrofon nutzen (manuell)]       │
│                                           │
└───────────────────────────────────────────┘
```

- **"Ohne Mikrofon nutzen"**: Zeigt leere Nadel, Nutzer kann Ton manuell wählen (Chromatic Keyboard)
- **Fallback** ist explizit — kein stilles Scheitern

### 11.2 Kein Ton erkannt (Stille)

- Ton-Label: `—` (Gedankenstrich, nicht leer)
- Cent-Anzeige: `·` (kein Wert)
- Nadel: zentriert, hellgrau, keine Farbe
- **Keine Error-Message** — Stille ist normal (Instrument nicht gespielt)

### 11.3 Mehrdeutiger Ton (mehrere Frequenzen gleichzeitig)

- Wird in Akkord-Situationen auftreten (Blaskapelle stimmt gemeinsam)
- Zeigt den **stärksten** Ton (höchste Amplitude)
- Kein Hinweis nötig — normales Verhalten

### 11.4 Sehr laute Umgebung / Clipping

- Pegel-Indikator rot
- Kein Alarm, kein Text — visuelles Signal ausreichend
- Musiker erkennt selbst, dass er zu laut spielt

### 11.5 Unbekannte Frequenz (außerhalb Tonleiter)

- Nächstgelegener Ton wird angezeigt + Cent-Abweichung
- Nie einen Fehler werfen — immer besten Versuch anzeigen

### 11.6 App in Hintergrund (anderer Screen)

- Mikrofon **stoppt sofort** (Datenschutz + Akku)
- Bei Rückkehr: Mikrofon startet automatisch (kein erneutes Tap nötig)

### 11.7 Gerät ohne Mikrofon (Desktop ohne Input)

```
┌───────────────────────────────────────────┐
│          🎤✗                              │
│    Kein Mikrofon gefunden                 │
│    Der Tuner benötigt ein Mikrofon.       │
│    Bitte schließe ein Mikrofon an.        │
└───────────────────────────────────────────┘
```

---

## 12. Integration mit Navigation (GoRouter)

### 12.1 Route

```
/tools/tuner
```

### 12.2 Navigation-Einstieg

- **Bottom-Navigation:** Tab „Werkzeuge" (🔧) → Untermenü oder direkt Tuner
- **Schnellzugriff:** Fab oder Shortcut aus Spielmodus-Overlay (`⚙ Werkzeuge`)
- **Deep-Link:** `sheetstorm://tools/tuner`

### 12.3 Back-Navigation

- Standard-Zurück-Geste → zurück zu letztem Screen
- **Kein separater Zurück-Button** notwendig (System-Back ausreichend)

### 12.4 Status-Bar

Im Tuner-Screen: Status-Bar Farbe = `color-surface`, Icons dunkel (kein Vollbild-Modus).

---

## 13. Abhängigkeiten

### 13.1 Für Implementierung (Hill / Banner)

- `PermissionHandler`-Package: Mikrofon-Permission Flow
- Platform Channels: CoreAudio (iOS/macOS), Oboe (Android), WebAudio (Web)
- FFT-Bibliothek: Frequenz-Erkennung unter 20ms
- Konfigurationssystem: Kammerton + Transposition speichern (Geräte-Ebene)

### 13.2 Offene Entscheidungen für Thomas

- **Stimmhistorie:** Soll der Tuner die letzten N Messungen speichern (z.B. "zuletzt A4, +1 Cent")? → Tablet-Wireframe zeigt Version mit Letzte-Messung-Zeile.
- **Manueller Modus:** Bei verweigerter Permission — Chromatic Keyboard als Fallback? → Aktuell als Option vorgesehen, aber komplex. Alternative: Nur Hinweis auf Einstellungen.
