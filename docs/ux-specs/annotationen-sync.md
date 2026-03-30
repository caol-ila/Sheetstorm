# UX-Spec: Annotationen-Sync (Echtzeit)

> **Issue:** MS3 — Annotationen-Sync  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-31  
> **Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync  
> **Referenzen:** `docs/meilensteine.md §MS3`, `docs/ux-specs/annotationen.md`, `docs/ux-design.md §3.7`

---

## Inhaltsverzeichnis

1. [Übersicht & Designprinzipien](#1-übersicht--designprinzipien)
2. [Was ist neu gegenüber MS1-Annotationen?](#2-was-ist-neu-gegenüber-ms1-annotationen)
3. [User Flow: Registerführer macht Live-Markierung](#3-user-flow-registerführer-macht-live-markierung)
4. [User Flow: Musiker empfängt Annotation](#4-user-flow-musiker-empfängt-annotation)
5. [Live-Sync-Indikator](#5-live-sync-indikator)
6. [Gleichzeitige Bearbeitung: Konflikt-Anzeige](#6-gleichzeitige-bearbeitung-konflikt-anzeige)
7. [Sync-Status im Spielmodus](#7-sync-status-im-spielmodus)
8. [Micro-Interactions & Animationen](#8-micro-interactions--animationen)
9. [Wireframes: Phone](#9-wireframes-phone)
10. [Wireframes: Tablet](#10-wireframes-tablet)
11. [Accessibility](#11-accessibility)
12. [Responsiveness](#12-responsiveness)
13. [Error States & Edge Cases](#13-error-states--edge-cases)
14. [Integration mit Navigation (GoRouter)](#14-integration-mit-navigation-gorouter)
15. [Abhängigkeiten](#15-abhängigkeiten)

---

## 1. Übersicht & Designprinzipien

### 1.1 Kernsatz

> „Der Registerführer zeichnet — alle sehen es. Ohne Verzögerung, ohne Unterbrechung."

Annotationen-Sync erweitert das in MS1 etablierte 3-Ebenen-Annotationssystem um **Echtzeit-Synchronisation**. In der Register-Probe zeichnet der Registerführer Markierungen ins Notenblatt — alle anderen Mitglieder mit derselben Stimme sehen sie sofort erscheinen.

### 1.2 Kontext: Register-Probe

**Szenario:** Register-Probe der Klarinetten. Der Registerführer (Max) macht auf Seite 4 eine Dynamik-Markierung (Stimmen-Ebene). Alle 6 Klarinettisten sehen die Markierung binnen Millisekunden auf ihrem Gerät.

**Wer profitiert:**

| Rolle | Nutzen |
|-------|--------|
| **Registerführer** | Einmal zeichnen, alle haben es sofort |
| **Musiker (gleiche Stimme)** | Keine Nachfragen „was hat er gezeichnet?" |
| **Dirigent** | Orchester-Annotationen gehen sofort an alle |

### 1.3 Designprinzipien

| Prinzip | Auswirkung |
|---------|-----------|
| **Noten im Fokus** | Sync-UI ist sekundär — nie der Noteninhalt |
| **Neue Annotationen sichtbar machen** | Fremde Annotationen kurz hervorheben, dann normal |
| **Konflikte transparent, nicht blockierend** | Annotation wird trotzdem gespeichert |
| **Offline-Tolerant** | Bei Verbindungsverlust: lokal speichern, später sync |

---

## 2. Was ist neu gegenüber MS1-Annotationen?

| Feature | MS1 | MS3 (Sync) |
|---------|-----|-----------|
| Privat-Annotationen | ✅ Lokal | ✅ Cloud-Sync (§Cloud-Sync Spec) |
| Stimmen-Annotationen | ✅ Lokal | ✅ **Echtzeit-Sync** |
| Orchester-Annotationen | ✅ Lokal | ✅ **Echtzeit-Sync** |
| Sync-Indikator | ❌ | ✅ **Neu** |
| Gleichzeitig-Bearbeitungs-Warnung | ❌ | ✅ **Neu** |
| „Wer hat das gezeichnet?" | ❌ | ✅ **Neu** |

---

## 3. User Flow: Registerführer macht Live-Markierung

```
Registerführer öffnet Spielmodus
        │
        ▼
  Annotation-Tool öffnen (Overlay → Stift-Icon)
        │
        ▼
  Ebene wählen: ● Stimme (Grün) oder ○ Orchester (Orange)
        │
        ▼
  Auf Notenblatt zeichnen (Strich, Symbol, Text)
        │
        ▼
  ┌──────────────────────────────────────────────────────┐
  │  Lokal: Annotation sofort sichtbar auf eigenem Gerät  │
  │  Sync: Annotation wird hochgeladen                   │
  │  Empfänger: Alle Musiker mit gleicher Stimme / alle  │
  └──────────────────────────────────────────────────────┘
        │
        ▼
  Sync-Indikator erscheint kurz (§5)
        │
        ▼
  Fertig — Annotation bei allen sichtbar
```

---

## 4. User Flow: Musiker empfängt Annotation

```
Musiker ist im Spielmodus, Stimmen-Annotation eingeblendet
        │
        ▼
  Neue Annotation kommt via WebSocket/UDP
        │
        ▼
  Annotation erscheint auf Notenblatt mit Einblend-Animation (§8.1)
        │
        ▼
  Kurzes „Neu von [Name]" Label erscheint (§5.2)
        │
        ▼
  Label fades out nach 3 Sekunden
  Annotation bleibt normal sichtbar
```

---

## 5. Live-Sync-Indikator

### 5.1 Sync-Pulse-Icon

Im Spielmodus-Overlay (obere rechte Ecke):

```
   ⟳ Sync aktiv
```

- **Icon:** Pulsierender Kreis oder WiFi-Wellen-Symbol
- **Größe:** 20×20 px (dezent)
- **Farbe:** `color-success` (#16A34A) wenn verbunden, `color-warning` wenn Verbindungsprobleme
- **Animation:** Langsames Pulsieren (Opacity 1.0 ↔ 0.6, 2s Zyklus) — zeigt „lebt"
- Erscheint **nur** wenn Stimmen-Ebene oder Orchester-Ebene eingeblendet ist (sonst irrelevant)

### 5.2 „Neu von [Name]" Label

Wenn neue fremde Annotation empfangen wird:

```
┌──────────────────────────────┐
│  🖊 Max M. · eben jetzt      │  ← Annotation-Attribution (oben auf Notenblatt)
└──────────────────────────────┘
```

- Erscheint als kleines Label **direkt über der neuen Annotation**
- Sichtbar: 3 Sekunden, dann `fade-out`
- Enthält: Avatar-Initial (A) oder Name-Abkürzung + „eben jetzt"
- `AppTypography.labelSmall`, `color-text-secondary`
- **Nur für neue eingehende Annotationen** — eigene Annotationen zeigen kein Label

### 5.3 Verbundene-Nutzer-Badge

In der Annotation-Toolbar (wenn sichtbar):

```
[ 🖊 ]  [ ● 6 ]
```

- Zahl = Anzahl Nutzer, die gerade dieselbe Seite in derselben Stimme geöffnet haben
- Grün = alle verbunden, Orange = einige offline
- Tippen → Liste der verbundenen Nutzer (Bottom Sheet)

---

## 6. Gleichzeitige Bearbeitung: Konflikt-Anzeige

### 6.1 Was ist ein Annotationskonflikt?

Zwei Nutzer zeichnen **gleichzeitig** an derselben Stelle → überlappende Annotationen.
Das ist bei Stimmen-Annotationen möglich (jeder mit dieser Stimme kann bearbeiten).

### 6.2 Kein Blocking-Dialog

Bei Überlappung: **Beide Annotationen werden gespeichert und angezeigt.**
- Keine Fehlermeldung
- Keine Unterbrechung des Zeichnens
- Überlappende Annotationen sind normal (wie auf echtem Notenblatt)

### 6.3 Gleichzeitig-Zeichnen-Indikator

Wenn ein anderer Nutzer **aktiv zeichnet** (Strich in Arbeit, noch nicht gespeichert):

```
┌──────────────────────┐
│  ✏ Max zeichnet...   │  ← Banner im Spielmodus (nicht ablenkend)
└──────────────────────┘
```

- Kleines Banner **unten** (über Bottom-Navigation, unter Notenblatt)
- 24px hoch, `color-surface` Hintergrund, `color-border` Rahmen
- Nur wenn sichtbar: anderer Nutzer in derselben Ebene aktiv zeichnet
- Verschwindet 2 Sekunden nach letztem Zeichenereignis

### 6.4 Halbfertige Annotation (andere Person)

Wenn andere Person Strich zeichnet und noch nicht abgeschlossen:
- Annotation erscheint mit **50% Opacity** (zeigt: In-Progress, nicht final)
- Nach Fertigstellung: auf 100% Opacity springen + Einblend-Animation

---

## 7. Sync-Status im Spielmodus

### 7.1 Integrierte Status-Anzeige

Der Sync-Status stört den Spielmodus nie. Nur zwei Zustände werden gezeigt:

| Zustand | Anzeige | Position |
|---------|---------|----------|
| **Verbunden** | Kleiner grüner Punkt neben Ebenen-Toggle | Overlay (nur wenn offen) |
| **Offline / Fehler** | Kleines ⚠-Icon | Overlay (nur wenn offen) |

### 7.2 Offline im Spielmodus

- Keine störende Meldung während des Spielens
- Annotationen werden lokal gespeichert
- Beim nächsten Öffnen des Overlays: kurzer Hinweis `⚠ Offline · 3 Annotationen ausstehend`

---

## 8. Micro-Interactions & Animationen

### 8.1 Neue Annotation erscheint (eingehend)

| Schritt | Animation | Dauer | Kurve |
|---------|-----------|-------|-------|
| 1. Annotation erscheint | Opacity 0 → 1 + Scale 0.8 → 1.0 | 300ms | `AppCurves.easeOut` |
| 2. Kurze Highlight-Glow | Farbe leicht aufhellen (120%) | 400ms | `AppCurves.easeInOut` |
| 3. Attribution-Label fade-in | Opacity 0 → 1 | 200ms | `AppCurves.easeOut` |
| 4. Attribution-Label fade-out | Opacity 1 → 0 | 500ms nach 3s | `AppCurves.easeIn` |

### 8.2 Annotation wird gelöscht (von anderem Nutzer)

- Annotation fades-out: Opacity 1 → 0, 400ms, `AppCurves.easeIn`
- Kein auffälliges Flackern
- Keine Bestätigungsnachfrage für den empfangenden Nutzer

### 8.3 Sync-Pulse

- Sync-Icon pulsiert bei Aktivität: Opacity 0.6 → 1.0 → 0.6, 800ms
- Bei Inaktivität: gleichmäßiges langsames Pulsieren (1.0 ↔ 0.5, 2s)

### 8.4 Verbindung verloren / wiederhergestellt

- Verloren: Sync-Icon wechselt zu Orange-Warn, 300ms fade
- Wiederhergestellt: Icon wechselt zurück zu Grün, kurze Rotation-Animation

---

## 9. Wireframes: Phone

### 9.1 Spielmodus mit Stimmen-Sync aktiv

```
┌───────────────────────────────┐
│                               │  ← Status Bar (transparent)
│  ════════════════════════════ │  ← Notenblatt (beginnt hier)
│  ♩ ♪   ♩  ♪    ♪   ♩        │
│         ─ dim ─              │  ← Orchester-Annotation (orange)
│  ♩ ♪   ♩  ♪    ♪   ♩        │
│   ~~~~~~~~~~~~~~~~~~~        │  ← Stimmen-Annotation (grün, gerade eingeblendet)
│  ┌──────────────────────┐    │
│  │ 🖊 Max M. · eben     │    │  ← Attribution-Label (3s, dann weg)
│  └──────────────────────┘    │
│  ♩ ♪   ♩  ♪    ♪   ♩        │
│  ════════════════════════════ │
│                               │
│  ┌──────────────────────┐     │  ← Gleichzeitig-Zeichnen Banner (wenn aktiv)
│  │  ✏ Anna zeichnet...  │     │
│  └──────────────────────┘     │
├───────────────────────────────┤
│ 🎵  📚  🔧  👤                │
└───────────────────────────────┘
```

### 9.2 Overlay mit Sync-Status

```
┌───────────────────────────────┐
│ ← Zurück     Seite 4/12   ⟳● │  ← Sync-Punkt oben rechts
├───────────────────────────────┤
│  ════════════════════════════ │
│  (Notenblatt gedimmt)         │
├───────────────────────────────┤
│  Ebenen: [👤●][🎵●][🎼●]     │  ← Alle 3 Ebenen mit Punkt (aktiv/inaktiv)
│  🖊 Zeichnen   📝 Text   ○ Radieren│
│  ──────────────────────────── │
│  ● 6 Musiker verbunden        │
└───────────────────────────────┘
```

---

## 10. Wireframes: Tablet

### 10.1 Tablet im Spielmodus mit Sync

```
┌────────────────────────────────────────────────────┐
│                                                    │
│  ══════════════════════════════════════════════   │
│  ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩         │
│                ─ dim ─                             │  ← Orchester (orange)
│  ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩ ♩ ♪ ♩ ♪ ♪ ♩         │
│  ┌──────────────────────────────────────────────┐ │
│  │  ~~~~~~~~~~~~~~~~~~~                          │ │  ← Stimmen-Annotation
│  └──────────────────────────────────────────────┘ │
│  ┌────────────────┐                               │
│  │ 🖊 Max M. eben │                               │  ← Attribution
│  └────────────────┘                               │
│  ══════════════════════════════════════════════   │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## 11. Accessibility

### 11.1 Screen-Reader

- **Neue eingehende Annotation:** `Semantics(liveRegion: true, label: "Neue Markierung von Max Müller")` — wird angekündigt
- **Gleichzeitig-Zeichnen-Banner:** `Semantics(liveRegion: true, label: "Anna Huber zeichnet gerade")` — angekündigt wenn erscheint
- **Sync-Indikator:** `Semantics(label: "Annotationen synchronisiert")` / `"Annotationen offline"`
- **Attribution-Label:** `ExcludeSemantics()` wenn parallel zu liveRegion-Ankündigung (kein Doppel-Ansage)

### 11.2 Reduced Motion

- Einblend-Animation bei neuer Annotation: nur Opacity (kein Scale)
- Gleichzeitig-Zeichnen-Banner: kein Slide-in, nur Opacity

### 11.3 Farb-Unabhängigkeit

- Ebenen-Farben (Blau/Grün/Orange) sind bereits durch Form + Position unterschiedlich
- Sync-Zustand: Icon + Farbe (nie Farbe allein)

---

## 12. Responsiveness

| Breakpoint | Sync-Indikator-Position | Attribution-Label |
|------------|------------------------|-------------------|
| Phone | Overlay-Header rechts | Direkt über Annotation |
| Tablet | Overlay-Header rechts | Direkt über Annotation, größer |
| Desktop | Permanente Sidebar-Info | Tooltip neben Annotation |

---

## 13. Error States & Edge Cases

### 13.1 Offline während Zeichnen

- Annotation wird lokal gespeichert (normal)
- Sync-Indikator wechselt zu Orange
- Annotation hat kleines `⏳` Icon neben sich (ausstehend)
- Sobald online: `⏳` verschwindet, Annotation synced

### 13.2 Annotation kommt zurück anders (Merge)

Wenn eine Annotation nach dem Sync leicht verändert zurückkommt (z.B. Timestamps angepasst):
- Keine sichtbare Änderung — ist intern
- Kein UI-Feedback nötig

### 13.3 Verbindungsunterbrechung während Gegner zeichnet

- Halbfertige fremde Annotation (50% Opacity) bleibt bis:
  - Verbindung wiederhergestellt + Completion-Event empfangen
  - Oder: Timeout nach 30 Sekunden → Annotation auf 100% setzen (Best-Effort)

### 13.4 Nutzer löscht eigene Annotation, die andere bereits gesehen haben

- Normal: Annotation verschwindet bei allen
- Keine Benachrichtigung an andere Nutzer
- Kein Bestätigen nötig (wie auf echtem Papier — Radiergummi)

### 13.5 Annotation auf nicht-vorhandener Seite

Wenn Empfänger Annotation empfängt für Seite, die er gerade nicht sieht:
- Annotation gespeichert (für wenn er blättert)
- Kein UI-Hinweis „du hast eine neue Annotation auf Seite 7" → zu störend

### 13.6 Synchronisation nach langem Offline

- Bulk-Sync: alle ausständigen Annotationen auf einmal
- Keine Animation für jeden einzelnen Eintrag (zu chaotisch bei 50+ Annotationen)
- Stattdessen: `ℹ Annotationen aktualisiert · 24 neue Markierungen`

---

## 14. Integration mit Navigation (GoRouter)

### 14.1 Kein eigener Screen

Annotationen-Sync ist **vollständig in den Spielmodus integriert** — kein separater Screen.

### 14.2 Sync läuft im Hintergrund

Auch wenn Nutzer im Spielmodus auf anderen Tab wechselt:
- WebSocket-Verbindung bleibt offen (für 5 Minuten nach Verlassen)
- Eingehende Annotationen werden gecacht
- Beim Zurückkommen: Sync-Update ohne Animation (kein Chaos)

---

## 15. Abhängigkeiten

### 15.1 Für Implementierung (Hill / Banner)

- **WebSocket (SignalR):** Für Echtzeit-Push von Annotationsänderungen
- **Conflict-Resolution:** Last-Write-Wins per Annotation-ID
- **Annotation-Metadata:** Jede Annotation hat `author_id`, `created_at`, `updated_at`, `device_id`
- **Permissions:** Stimmen-Ebene = alle mit gleicher Stimme; Orchester-Ebene = nur Dirigent/Admin schreibt, alle lesen

### 15.2 Referenz auf MS1

- Annotationstypen, Farben, Werkzeuge: siehe `docs/ux-specs/annotationen.md`
- Ebenen-Konzept (Privat/Stimme/Orchester): unverändert aus MS1
- MS3 erweitert nur den **Sync-Layer**, nicht das Annotationsmodell selbst

### 15.3 Offene Entscheidungen für Thomas

- **Schreib-Rechte Stimmen-Ebene:** Aktuell: „Alle mit dieser Stimme können schreiben." Alternative: Nur Registerführer. → Empfehlung Wanda: Alle dürfen schreiben (demokratisch, pragmatisch für Probenalltag).
- **Gleichzeitig-Zeichnen sichtbar machen:** „Anna zeichnet..." Banner — gewünscht oder zu viel Unruhe?
