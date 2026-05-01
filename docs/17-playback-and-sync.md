# 17 — Playback & Sync

> **Verwandt:** [05 — Conductor-Sync-Protokoll](05-conductor-sync-protocol.md)
> (Time-Sync & Position-Tracking), [10 — Metronom](10-metronom-and-sync-click.md),
> [01 — Funktionale Spec, Abschnitt 13/14](01-functional-spec.md),
> [02 — Tech Stack (Audio)](02-tech-stack.md),
> [22 — Measure-Tracking & Reflowable Layout](22-measure-tracking-and-reflow.md)
> (Bbox-basiertes Highlighting & Cross-Instrument-Sync auch ohne
> vollständige Noten-Erkennung).

Dieses Dokument beschreibt die technische Architektur für
**Score-Playback**, **Übungs-Modus** und **Position-Tracking**. Die
funktionalen Anforderungen stehen in Spec 01; das BLE-Paketformat in
Spec 05.

## 17.1 Komponenten­überblick

```
┌─────────────────── Browser (PWA / Capacitor-WebView) ──────────────────┐
│                                                                        │
│  Razor: PartViewer ──── PlaybackPanel.razor                            │
│              │              │                                          │
│              ▼              ▼                                          │
│      ScoreCursorService   PlaybackController (C#)                      │
│              │              │                                          │
│              └──────► JS-Interop ─────────┐                           │
│                                            ▼                           │
│                          sheetstorm-playback.js (neu)                  │
│                                ├── PositionClock (Lookahead)           │
│                                ├── SampleLibrary (smplr/SF3)           │
│                                ├── VoiceMixer (gain pro Stimme)        │
│                                └── LoopEngine                          │
│                                                                        │
│  sheetstorm-native.js ──► PositionAnchor-Empfang ──► PositionClock     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
                                   ▲
                                   │ Position-Anchor (Spec 05)
                                   │
                       ┌───────────┴───────────┐
                       │   Conductor (Razor)   │
                       │ ConductorSyncPage +   │
                       │ ConductorPlaybackVm   │
                       └───────────────────────┘
```

## 17.2 State-Machine

Eine zentrale State-Machine pro `PartViewer`-Instanz steuert das
Zusammenspiel UI ↔ Audio ↔ Position.

```
                ┌─────────┐
   Stop ◄──────►│ Stopped │ ◄────────── (Score initial geladen)
                └────┬────┘
                     │ Play
                     ▼
                ┌─────────┐    Pause     ┌────────┐
       Stop ◄───┤ Playing │ ◄──────────► │ Paused │
                └────┬────┘              └────┬───┘
                     │ Loop-Wrap              │
                     ▼                        │
                ┌─────────┐                   │
                │ Looping │ ◄─────────────────┘
                └─────────┘
                     │ Sync-Anchor (Conductor-Sprung / D.C.)
                     ▼
                ┌──────────┐
                │ Jumping  │ → kurz, kein Audio (≤ 80 ms), dann Playing
                └──────────┘
```

**Regeln:**

* `Stopped` → `Playing`: Sample-Library MUSS ready sein
  (`SampleLibrary.warmup(voices)` durchgelaufen). Ist sie nicht ready,
  bleiben wir in `Stopped` und zeigen Spinner.
* `Playing` → `Paused`: aktuell klingende Noten werden mit 50 ms
  Release ausgeschwungen, Position-Clock pausiert.
* `Paused` → `Playing`: lookahead startet wieder, allerdings mit
  300 ms „Vorzähler" als optisches Cue-Blink (kein hörbarer Click,
  außer Metronom ist eh aktiv).
* `Jumping`: stoppt alle Stimmen (50 ms Release), schedule-Queue wird
  geleert, Position wird neu gesetzt, dann sofort nach `Playing`.
* `Looping` ist kein eigener Top-State, sondern ein Flag in `Playing`,
  das beim Erreichen von Marker B einen Sprung auf Marker A einleitet.

### Trigger-Quellen

| Trigger | Quelle | Erlaubte Übergänge |
|---|---|---|
| User-`Play` | UI | Stopped/Paused → Playing |
| User-`Pause` | UI | Playing → Paused |
| User-`Stop` | UI | * → Stopped |
| User-`Seek` | Klick im Score / Slider | Playing → Jumping → Playing; Stopped/Paused → unverändert (nur Cursor) |
| User-`Tempo` | Slider | nur Geschwindigkeit, keine State-Transition |
| BLE-`PositionAnchor` (drift ≤ 250 ms) | sheetstorm-native.js | weiche Korrektur, keine Transition |
| BLE-`PositionAnchor` (drift > 250 ms oder Sprung-Flag) | sheetstorm-native.js | Playing → Jumping → Playing |
| BLE-`IsPlaying=false` | Conductor pausiert | Playing → Paused (nur wenn Sync-Modus aktiv) |

## 17.3 Audio-Sample-Loading

### 17.3.1 Format und Hosting

* Primär **SF3** (Vorbis-komprimiertes SF2). MuseScore General als
  37 MB SF3-Datei statt ~150 MB SF2.
* Bei SFZ-Quellen (VCSL, VSCO 2 CE) konvertieren wir vorab in ein
  **Sheetstorm-Sample-Bundle** (`.ssb`):
  * Manifest (JSON): Patch-Liste, Loop-Punkte, Velocity-Layer.
  * Audio-Files als **Opus 96 kbps** (deutlich kleiner als WAV/FLAC,
    Qualität für Übung mehr als ausreichend).
  * Splittung in **Patch-Chunks**: pro Instrument einzeln ladbar.
* Hosting: MinIO (Dev) / S3 + CDN (Prod). Default-Pack ist als
  Service-Worker-Precache markiert (~40 MB).

### 17.3.2 Lade-Strategie

Drei Stufen, in dieser Reihenfolge:

1. **Preload (App-Start, im Hintergrund).**
   Nur das **General-MIDI-Basic-Pack** (MS Basic, ~37 MB, gechunkt).
   Über Service-Worker, mit Network-Idle-Hint. User merkt nichts.

2. **Per-Stück-Warmup.**
   Wenn Stück geöffnet wird, ruft `PlaybackController.PrepareAsync`:
   * Sammelt aus MusicXML alle vorkommenden Instrumente
     (`<score-instrument>` / `<midi-program>`).
   * Mappt auf Patches im aktuell aktiven Pack.
   * Lädt nur die benötigten Patches (lazy, parallel max. 4).
   * Latenz: ~500 ms–2 s je nach Stimmen-Zahl, läuft parallel zum
     Score-Render.

3. **On-Demand (User aktiviert weitere Stimme).**
   Checkbox-Click in der Stimmen-Liste löst Patch-Load aus, bis
   fertig: Stimme ist „grau / Spinner" und stummgeschaltet.

### 17.3.3 Cache

* IndexedDB (`sheetstorm-samples`-Object-Store) als persistenter
  Cache für entpackte AudioBuffer-Bytes.
* LRU-Eviction mit Soft-Limit 200 MB pro Origin (User-konfigurierbar).
* Cache-Key = `{packId}/{patchId}/{sampleHash}` ⇒ packs können ohne
  Cache-Invalidierung versioniert werden.

## 17.4 Mehrstimmigkeit

### 17.4.1 Voice-Pro-Stimme

Pro `Part` ein **VoiceChannel** mit:

* **Note-Event-Queue**: aus MusicXML extrahiert
  (`{ measure, beat, midiNote, durationBeats, velocity }`).
* **Polyphonie­limit**: 16 Noten gleichzeitig pro VoiceChannel
  (z.B. Klavier-Stimme oder Schlagzeug). Standard 4 für reine
  Bläser-Stimmen, deckt Akkorde ab.
* **Gain-Node** (Stimme-Volume + Mute-Flag).
* **Optional: leichte Stereo-Position** pro Familie (Holz links,
  Blech rechts, Schlagwerk Mitte) — weicht Mono-Brei auf.

### 17.4.2 Mix-Bus

```
VoiceChannel[Klarinette 1] ─► Gain ─┐
VoiceChannel[Klarinette 2] ─► Gain ─┤
VoiceChannel[Trompete 1]   ─► Gain ─┼─► MasterGain ─► AudioContext.destination
VoiceChannel[Posaune]      ─► Gain ─┤
…                                   │
                       MetronomeOut ─┘  (eigener Bus, separates Volume)
```

* Master-Gain auf −6 dB Default (Headroom).
* Ein **DynamicsCompressorNode** auf Master verhindert Clipping bei
  vielen aktiven Stimmen.

### 17.4.3 Limit & Fallback

* Phase 1: max. **8 aktive VoiceChannel** gleichzeitig. Aktiviert
  User die 9.: warnen und letzte selbst aktivierte deaktivieren.
* Auf schwacher CPU (Mobile, > 25 ms Audio-Callback-Stalls) wird
  automatisch auf **6 Stimmen** runtergeregelt.

## 17.5 Lookahead-Scheduler & Position-Clock

Analog `metronome.js`:

```js
// Tick-Loop, läuft alle 25 ms
function scheduler() {
  const now = audioCtx.currentTime;
  while (nextNoteTime < now + LOOKAHEAD_SEC /* 0.1s */) {
    scheduleAllVoicesAt(nextNoteTime, currentMeasure, currentBeat);
    advanceBeat();   // ggf. Loop-Wrap, ggf. Sprung
  }
  setTimeout(scheduler, 25);
}
```

* Anker (BLE oder lokal) setzen `currentMeasure`, `currentBeat`,
  `bpm` und `audioCtxAnchorTime`. Daraus extrapoliert die Clock.
* Bei Tempo-Change wird **nicht** die schon scheduled Queue
  zurückgenommen (würde knacken), sondern nur ab `nextNoteTime`
  weitergerechnet.
* Score-Cursor (Razor / DOM) liest dieselbe Clock per
  `requestAnimationFrame` und glättet zwischen Ankern.

## 17.6 Loop-Engine

* User setzt Marker A (Takt+Beat) und B.
* Beim Erreichen von B (in der Lookahead-Queue) wird der **nächste**
  Anker als Sprung auf A geplant.
* Im Conductor-Modus: Conductor sendet `kind=PositionAnchor` mit
  `jumpKind=6 (Loop-Wrap)` und `jumpTargetMeasure=A`. Followers
  springen synchron.
* Loop-Übergang ist immer **on-beat**, nie mitten in einer Note —
  klingende Noten werden mit 30 ms Release abgeschnitten, damit kein
  „Würgen" entsteht.

## 17.7 Latenz-Budget

| Quelle | Typisch | p99 |
|---|---|---|
| BLE-Advertisement → Empfang | 80–200 ms | 500 ms |
| Web Audio Output-Latency (Desktop) | 20–50 ms | 100 ms |
| Web Audio Output-Latency (Mobile/Bluetooth-Kopfhörer) | 100–250 ms | 400 ms |
| UI-Render bis sichtbarer Cursor | 16–32 ms (1–2 Frames) | 60 ms |
| Position-Clock-Drift zwischen Ankern (BPM-Extrapolation) | < 20 ms / s | 50 ms / s |

**Ergebnis (Sync zwischen zwei Followern):**

* Realistisch **80–250 ms** Drift im stabilen BLE-Empfang
  (Score-Cursor: visuell synchron, Audio: hörbar bei Bluetooth-
  Kopfhörern auf Mobile).
* p99 **bis 600 ms** bei BLE-Advertisement-Verlust + Mobile-Audio-
  Latenz. → Daher: **Audio-Playback ist primär für Übung daheim
  (lokal, nicht Sync)** gedacht. Synchron-Live-Playback in der
  Probe ist Phase 2 und akzeptiert hörbares „Echo".
* Score-Cursor (rein visuell, ohne Audio): bleibt < 100 ms Drift.

## 17.8 Übungs-Modus-Implementierung

* `MutMeineSwitch.razor` setzt im PlaybackController:
  ```csharp
  PlaybackController.SetVoiceMute(self.PartId, mute: true);
  ```
* Das Mapping „welche Stimme ist meine" kommt aus
  `Membership.PreferredParts`.
* `Solo meine`: setzt alle anderen auf Mute, eigene auf
  `Volume = 1.0`.
* Tempo-Lokal-Modus: setzt `PlaybackController.TempoSource = Local`,
  ignoriert `bpmTimes100` aus BLE-Anchor. Cursor zeigt zwei
  Cursor-Geister: einen blauen für lokale Audio-Position, einen
  grauen dünnen für Conductor-Position.

## 17.9 Lizenz-Handling für Sample-Packs

| Pack | Anzeige im UI | Quelle | Verteilung |
|---|---|---|---|
| `ms-basic-1.4` (Default) | „MuseScore General (MIT)" | bundle in App-Assets, Service-Worker | offline-fähig |
| `vcsl-band-pack` (optional) | „VCSL (CC0)" | Lazy-Download bei Aktivierung | offline-fähig |
| `vsco2-ce-woods` | „VSCO 2 CE (CC-BY)" | Lazy-Download | offline-fähig, License-Footer Pflicht |
| `bavarian-brass-hq` (Phase 2, paid) | Verein-Lizenz, License-Token | Pro-Verein-Aktivierung im Backend; pro User entschlüsselt | offline nach erstem Sync, expiriert bei Mitgliedschafts­ende |

License-Footer (Pflicht, klein, Ecke unten in der Playback-Leiste):
„Sounds: MuseScore General · VCSL".

## 17.10 File-Structure-Map

### CREATE

* `src/Sheetstorm.Web/Application/Playback/PlaybackController.cs`
  — C#-seitiger Orchestrator: kennt `Piece`, `Part`, lädt Note-Event-
  Liste aus MusicXML, hält State-Machine, bridged zu JS.
  Abh.: `Sheetstorm.Domain.Pieces`, `MusicXmlNoteExtractor`.

* `src/Sheetstorm.Web/Application/Playback/MusicXmlNoteExtractor.cs`
  — Parst MusicXML, erzeugt pro `<part>` eine Liste
  `(measure, beat, midiNote, durationBeats, velocity)`. Berücksichtigt
  Volta/D.C./D.S. via `PerformanceTimeline`.
  Abh.: `System.Xml.Linq`, `Sheetstorm.Domain.Pieces.Part`.

* `src/Sheetstorm.Web/Application/Playback/PerformanceTimeline.cs`
  — Lineare Liste der tatsächlich gespielten Takt-Spannen, abgeleitet
  aus MusicXML-Sprungmarken. Wird auch von Position-Anchor (Spec 05)
  konsumiert.
  Abh.: `MusicXmlNoteExtractor`.

* `src/Sheetstorm.Web/Application/Playback/SamplePackRegistry.cs`
  — Server-seitig: Liste aller verfügbaren Packs + Lizenz-Status pro
  Verein. Endpoints `GET /api/sample-packs`, `POST /api/sample-packs/{id}/activate`.
  Abh.: `Sheetstorm.Domain.Memberships`.

* `src/Sheetstorm.Web/Components/Shared/PlaybackPanel.razor`
  — Einklappbares Panel mit Play/Pause/Stop, Position-Slider, Stimmen-
  Liste, Loop-Marker, Tempo-Slider, Master-Volume.
  Abh.: `PlaybackController` (DI), `PartViewer` (parent).

* `src/Sheetstorm.Web/Components/Shared/PlaybackPanel.razor.css`
  — Scoped-CSS, mobile-friendly Layout (Bühnen-Tap-Target ≥ 44 px).

* `src/Sheetstorm.Web/Components/Shared/VoiceListItem.razor`
  — Eine Zeile in der Stimmen-Liste: Checkbox, Name, Volume, Solo-Indicator.
  Abh.: `PlaybackPanel`.

* `src/Sheetstorm.Web/Components/Shared/ScoreCursor.razor`
  — Overlay über OSMD-SVG, rendert blauen Beat-Cursor (Audio-Position)
  und optional grauen Conductor-Cursor.
  Abh.: `ScoreCursorService`, `PartViewer`.

* `src/Sheetstorm.Web/Application/Playback/ScoreCursorService.cs`
  — Berechnet Cursor-Pixel-Position aus (measure, beat) und OSMD-
  Layout-Cache. Liefert auch Bild-Modus-Stufen (System/Takt/Beat).
  Abh.: `PlaybackController`, OSMD JS-Interop.

* `src/Sheetstorm.Web/wwwroot/js/sheetstorm-playback.js`
  — Web-Audio-Engine: PositionClock, VoiceMixer, LoopEngine,
  Sample-Patch-Loader (über `smplr`). Bridge zu C# via
  `DotNetObjectReference`.
  Abh.: npm `smplr`, `@sfz-tools/core`.

* `src/Sheetstorm.Web/wwwroot/js/sample-pack-loader.js`
  — IndexedDB-Cache, Patch-Chunk-Lazy-Load, Decode-Worker.
  Abh.: nichts extern.

* `src/Sheetstorm.Web/Application/Conductor/PositionAnchorBuilder.cs`
  — Erzeugt `PositionAnchorPayload` (Spec 05) aus aktuellem
  PlaybackController-State des Conductors. Wird vom Conductor-Hub
  aufgerufen.
  Abh.: `PlaybackController`, `ConductorSyncService`.

* `src/Sheetstorm.Domain/Pieces/PerformanceTimelineEntry.cs`
  — Value-Object: `(int Order, int FromMeasure, int ToMeasure, int VoltaPath)`.
  Abh.: nichts.

* `src/Sheetstorm.Domain/Pieces/Part.LayoutHints.cs` (partial class)
  — Neue Property `LayoutHints` (JSON-Spalte `jsonb` in PG), siehe
  Spec 05 für Schema. Migration nötig.
  Abh.: `Sheetstorm.Domain.Pieces.Part`.

* `tests/Sheetstorm.Web.Tests/Playback/MusicXmlNoteExtractorTests.cs`
  — xUnit + FluentAssertions. Test-Cases: einfaches Stück, Volta 1+2,
  D.C. al Fine, D.S. al Coda, Quintolen-Tuplet.
  Abh.: Test-Fixtures unter `tests/.../Fixtures/musicxml/`.

* `tests/Sheetstorm.Web.Tests/Playback/PerformanceTimelineTests.cs`
  — Validiert Sprung-Auflösung in lineare Liste.

* `e2e/playback.spec.ts`
  — Playwright-Test: Stück öffnen → Play → Cursor wandert →
  Mute-Switch → eigene Stimme stumm. Audio-Output wird via
  `getByLabel('Stimme: Klarinette 1') > [aria-pressed]` verifiziert,
  nicht akustisch.
  Abh.: Playwright-Setup im `e2e/`.

* `docs/17-playback-and-sync.md` — diese Datei.

### MODIFY

* `src/Sheetstorm.Web/Components/Shared/PartViewer.razor`
  — Bindet im Score-Modus `<PlaybackPanel>` und `<ScoreCursor>` ein.
  Im Bild-Modus nur `<ScoreCursor Mode="Image">`. Property
  `EnablePlayback` (Default `true` im Score-Modus).

* `src/Sheetstorm.Web/Components/Pages/Events/ConductorSyncPage.razor`
  — Neuer Tab „Playback-Steuerung": Conductor kann zentral Play/Stop
  drücken (broadcastet via PositionAnchorBuilder). Tempo-Slider,
  Performance-Liste-Edit (Volta-Wahl, D.C.-Toggle).

* `src/Sheetstorm.Web/Application/ConductorSyncService.cs`
  — Neue Methode `BroadcastPositionAnchor(...)`, neuer Hub-Event
  `PositionAnchorReceived`. Konsumiert `PositionAnchorBuilder`.

* `src/Sheetstorm.Web/wwwroot/js/sheetstorm-native.js`
  — BLE-Empfänger erkennt zusätzlich `kind=3 (PositionAnchor)`,
  reicht an `sheetstorm-playback.js → onAnchor()` weiter.

* `src/Sheetstorm.Web/wwwroot/js/metronome.js`
  — Refactor: `Lookahead`-Logik in eigenes Modul `lookahead-clock.js`
  extrahieren, von `metronome.js` und `sheetstorm-playback.js`
  geteilt. Verhalten unverändert.
  → Begleitendes Refactor, gedeckt durch existierende Metronom-Tests.

* `src/omr-rust/crates/omr-musicxml/src/lib.rs`
  — Bei MusicXML-Export zusätzlich pro `<measure>` `<bounds>` aus dem
  OMR-Layout schreiben (falls vorhanden), als Quelle für
  Bild-Modus-Takt-Highlight (Spec 05, Stufe B).
  → Existierende Tests ergänzen, kein Breaking Change.

* `docs/01-functional-spec.md` — Abschnitte 13 + 14 (separat).

* `docs/02-tech-stack.md` — Audio-Bibliotheken (separat).

* `docs/05-conductor-sync-protocol.md` — Time-Sync-Section (separat).

* `package.json` (Web-Asset-Pipeline)
  — Dependencies `smplr`, `@sfz-tools/core`. Build-Skript
  `build:samples` zum Konvertieren von SFZ → SSB-Bundle.

### DELETE

Keine. Alle Änderungen sind additiv. Falls `metronome.js` durch
Lookahead-Refactor obsolete wird, bleibt es als dünner Wrapper über
`lookahead-clock.js` bestehen, damit keine bestehenden Importe
brechen.

## 17.11 Offene Punkte / Phase 2

* **Echtes synchrones Live-Playback** in der Probe (alle Geräte
  spielen) braucht entweder NTP-light-Sync (Spec 10) oder
  WLAN-Multicast-Audio. Aktuell aus Latenz-Gründen Phase 2.
* **Schlagzeug-Sample-Mapping**: General-MIDI-Drum-Kit funktioniert
  nicht 1:1 mit Blasmusik-Schlagwerk-Notation (Becken/Trommel-Layout
  weicht ab). Phase 2.
* **Pitch-Bend / Vibrato**: aktuell rein über Sample-Layer. Echte
  Pitch-Modulation per AudioWorklet wäre möglich, kostet aber CPU.
* **Hall-Simulation** (ConvolverNode mit Saal-IR) als optionaler
  „Konzert"-Modus. Phase 2.
* **MIDI-Out**: User schließt Hardware-Synth an, Sheetstorm rendert
  nicht selbst, sondern sendet MIDI. Niedrigste Latenz, aber
  Hardware-Voraussetzung. Evaluieren.
