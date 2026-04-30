# 22 — Measure-Tracking & Reflowable Layout

> **Verwandt:** [01 — Funktionale Spec](01-functional-spec.md),
> [05 — Conductor-Sync-Protokoll](05-conductor-sync-protocol.md),
> [15 — OMR-Pipeline](15-omr-pipeline-spec.md),
> [17 — Playback & Sync](17-playback-and-sync.md),
> [18 — Symbol-Library & Layout](18-symbol-library-and-layout.md),
> [20 — Phase 3 Cloud-Backstop](20-phase3-cloud-backstop.md).
>
> **Status:** ACCEPTED (siehe `.squad/decisions.md` ADR-OMR-003)
> **Phase:** A in PR-Range #136+, B/C/D folgen.

Diese Spec beschreibt die **Layered-OMR-Strategie** von Sheetstorm: Statt
darauf zu warten, bis die OMR alle Noten zu 100 % erkennt, liefern wir
schon mit **Takt-Bboxes + Sprungmarken + Tempo** drei
Killer-Features — Live-Position-Highlighting, Cross-Instrument-Sync und
Reflowable Layout.

## 22.1 Vision & Mehrwert

Reale Vereinsnoten (Mendocino, ANGELS, Bohemian Rhapsody Medley, …)
sind ein OCR-Albtraum: alte Kopien, handschriftliche Markierungen,
ungewöhnliche Layouts. Voller Notehead-Recall (≥ 95 %) ist hart,
realistisch sind heute eher **60–80 %**. Diese Spec sagt:

> **Wir brauchen die Noten gar nicht alle, um den größten Teil des
> User-Mehrwerts zu liefern.**

Wenn folgende **minimale** Datenmenge zuverlässig erkannt wird,
gewinnen wir 80 % des Nutzens:

| Datum | Quelle | Required für |
|---|---|---|
| Bbox pro Takt (Reading-Order) | OMR Layer 1 | A, B, C, D |
| System-Layout (Takt → Zeile) | OMR Layer 1 | C |
| Sprungmarken (Volta/D.C./D.S./Coda/Segno/Fine/Repeat) | OMR Layer 2 | A (korrekt!), B, D |
| Time-Signature & Tempo (BPM) | OMR Layer 3 | A, B, D |
| Pitches/Durations | OMR Layer 4 | (nur Score-Playback Spec 17) |

Daraus folgen drei Killer-Features, die **alle ohne Layer 4**
funktionieren:

### Feature A — Live-Position-Highlighting

Während ein Stück läuft (BLE-Sync vom Dirigenten oder User-Tap-Tempo),
hebt die App **den aktuellen Takt** visuell hervor. Das ist ein
gelblicher Rahmen um die `bbox_orig` direkt auf dem **Original-Bild**
des Notenblatts.

> **Schlüsselpunkt:** Wir highlighten die Bbox auf dem Original.
> Ob OMR die Sechzehntel im Takt korrekt erkannt hat, ist für das
> Highlight egal. Schon ein erkannter Takt-Rahmen → User sieht,
> wo er ist.

### Feature B — Cross-Instrument-Sync

Im Probelokal sitzen Musiker mit unterschiedlichen Stimmen
nebeneinander. Beispiel:

| Instrument | Takte/Zeile | Aktuell auf … |
|---|---|---|
| Klar 1   | 6 | Zeile 3, Takt 14 |
| Trompete | 4 | Zeile 5, Takt 14 |
| Posaune  | 8 | Zeile 2, Takt 14 |

Alle drei Geräte highlighten **gleichzeitig denselben musikalischen
Takt**, obwohl er auf jedem Blatt an einer anderen physischen Stelle
steht. Sprungmarken werden auf jedem Gerät korrekt aufgelöst
(Volta 1./2., D.S. al Coda, Da Capo).

### Feature C — Reflowable Layout / Zoom

Statt das Original-PDF eingefroren zu zeigen, **extrahieren** wir die
Takte als Bild-Crops und ordnen sie neu an. User wählt:

* 1 / 2 / 3 / 4 Takte pro Zeile,
* Zoom 50 %–300 % stufenlos,
* Page-Bruch automatisch.

Konkreter Anwendungsfall: ältere Musiker auf 6"-Tablet bei schwachem
Festzelt-Licht — statt Lupe rausholen einfach „Reflow 2/Zeile, 200 %".

---

## 22.2 Architektur — Layered OMR

```
┌──────────────────────────────────────────────────────────────┐
│ Sheetstorm Layered OMR                                        │
├──────────────────────────────────────────────────────────────┤
│  Layer 0: Original PDF/Image (immutable)                      │
│  Layer 1: Page-Layout (Systeme, Bbox pro Takt, Reading-Order) │
│  Layer 2: Sprungmarken & Repeat-Struktur                      │
│  Layer 3: Time-Signature & Tempo                              │
│  Layer 4: Pitches & Durations (NHs, Stems, Beams)             │
│  Layer 5: Voice/Chord/Slur-Resolution                         │
│                                                                │
│  💡 ALLE Features ab Layer 2 sind nutzbar — auch wenn         │
│     Layer 4+5 nur teilweise erkannt sind.                     │
└──────────────────────────────────────────────────────────────┘
```

| Layer | Daten | Pipeline-Stufe (siehe Spec 15) | Features ab dann |
|---|---|---|---|
| 0 | PDF-Pixel, DPI, Seitenanzahl | Loader | – |
| 1 | Stafflines, Systeme, **Bbox pro Takt**, Reading-Order | Staff-Detect, Bar-Line-Detect, System-Group | C (statisch), Bbox-Highlights ohne Sync |
| 2 | Volta-Klammern, D.C./D.S./Coda/Segno/Fine, Repeat-Bars | Symbol-Library (Spec 18), Layout-Hints | **A, B**, Performance-Order |
| 3 | Time-Sig, Tempo-Marker (♩=120), Auftakt | Symbol-Library + Text-OCR | A präziser (Beat-Subdivisions), Metronom-Setup |
| 4 | Noteheads, Stems, Beams pro Takt | NH-Detect, Stem-Detect | Score-Playback (Spec 17), Fingersatz |
| 5 | Voices, Chords, Slurs | Voice-Resolver | Voice-Highlighting, MusicXML-Export |

**Wichtig:** Die Engine darf jeden Layer **eigenständig** ausspielen.
Wenn Layer 4 für Takt 17 versagt, blockiert das **nicht** die A/B/C-
Features. Layer-Status pro Takt im Quality-Report mitführen
(`measure.layers_complete = {1,2,3}`, `4 = partial`).

---

## 22.3 Datenmodell-Erweiterung

Pseudo-Code (Rust-Style, indikativ — finale Form siehe
`src/omr-rust/`):

```rust
pub struct MeasureLayout {
    pub measure_idx: u32,                       // 1-basiert, in Reading-Order
    pub system_idx: u32,                        // welches System (Zeile)
    pub measure_in_system: u32,                 // Index innerhalb der Zeile
    pub bbox_orig: Rect,                        // Bbox im Original-Bild
    pub bbox_clean: Rect,                       // Bbox nach Deskew/Despeckle
    pub measure_number_displayed: Option<u32>,  // Nummer wie auf dem Blatt gedruckt
    pub time_signature: Option<TimeSignature>,
    pub key_signature: Option<KeySignature>,
    pub jump_marks: Vec<JumpMark>,
    pub layers_complete: BitSet,                // welche Layer für diesen Takt
    pub confidence: f32,                        // 0..1
}

pub enum JumpMark {
    Volta { number: u8, x_range: (f32, f32) },  // "1.", "2." mit Klammer
    DcAlFine,
    DsAlCoda { segno_target: usize },
    Coda { is_target: bool },                   // Coda-Quelle vs. -Ziel
    Segno { is_target: bool },
    Fine,
    RepeatStart,
    RepeatEnd,
    DalCapo,
}

/// Linearisierte Spielreihenfolge unter Beachtung aller Sprungmarken.
/// Entspricht der "Performance Order" eines Dirigenten.
pub struct PerformanceTimeline {
    pub linear_order: Vec<u32>,                 // measure_idx in Spielreihenfolge
    pub repeat_count: HashMap<u32, u8>,         // wie oft jeder Takt vorkommt
}
```

`PerformanceTimeline` ist der **Schlüssel** für B + D: Sie ist
**stimmenübergreifend identisch** (modulo Auftakt-Unterschiede,
siehe Edge Cases unten).

---

## 22.4 Cross-Instrument-Sync-Algorithmus

**Logische Position:**

```
LogicalPos = (linear_index, beat_within_measure, beat_subdivision)
```

ist **universell** — instrumenten- und layoutunabhängig.

### Ablauf

1. **Server-Side Indexing** (bei Upload jeder Stimme):
   * OMR liefert `MeasureLayout[]` und `PerformanceTimeline`.
   * Backend speichert pro Stimme die Map
     `linear_index → measure_idx → bbox_orig` als JSON.
2. **Dirigent (live):**
   * Sendet via BLE `LogicalPos = (linear_index, beat, subdivision)`
     (siehe Spec 05, Paket-Erweiterung).
3. **Follower (live):**
   * Empfängt Paket → schlägt `linear_index` in **eigener**
     Map nach → erhält `measure_idx` und `bbox_orig`.
   * Rendert Cursor-Overlay um `bbox_orig`.

### Edge Cases

| Fall | Auflösung |
|---|---|
| Auftakt nur in einer Stimme | Pro Stimme `pickup_measures: u32` mitführen, beim Linearisieren Offset addieren. Dirigent broadcastet **performance-relativen** Index. |
| Volta 1./2. | Linearisierer expandiert: `[1,2,3,4,5(volta1),6(repeat→2),3,4,5(volta2),7,…]`. Beide Geräte expandieren gleich. |
| Coda-Sprung | `DsAlCoda { segno_target }` wird **deterministisch** aufgelöst — Linearisierer ist reine Funktion `MeasureLayout[] → linear_order`. Zwei Geräte mit gleichen Sprungmarken erzeugen identische Order. |
| Eine Stimme hat Mehr-Takt-Pause als „1 Multimeasure-Rest" notiert | Multimeasure-Rests werden in Layer 2 als N reale Takte expandiert. Ohne Expansion driftet der Sync. |
| OMR hat in Stimme X eine Sprungmarke verpasst | Quality-Gate: `PerformanceTimeline.length` muss zwischen allen Stimmen ≤ 1 % abweichen, sonst Warnung im Upload-UI mit Manual-Fix-Aufforderung. |

---

## 22.5 Reflowable Layout

User wählt Modus pro Stück / pro Stimme:

| Modus | Beschreibung | Use-Case |
|---|---|---|
| **Original** | PDF wie ist | Konzert, Standard |
| **Reflow** | Takte extrahiert, neu angeordnet, N Takte/Zeile | Probe, kleines Tablet |
| **Single-Measure** | 1 Takt pro Bildschirm, Auto-Advance | Live-Modus, Premium |

### Implementation

Pseudo-Pipeline (Server-Side, einmalig pro Upload):

```
for each MeasureLayout m:
    crop = render_pdf_page(m.page).crop(m.bbox_orig + padding)
    save_tile(piece_id, part_id, m.measure_idx, crop)  // PNG, 32-bit
```

Mobile / Web rendert dann ein **CSS-Flex-Grid** oder Canvas mit den
Tiles in der gewünschten Spaltenzahl. Cursor + Highlight bleiben
auf Tile-Ebene funktional (Map: `linear_index → tile-DOM-id`).

### Caveats

* **Slurs/Bögen über Taktgrenzen**: werden beim einfachen Crop
  abgeschnitten. Marker am Crop-Rand setzen (Tilde `~` rechts unten
  / links unten = „Bogen geht weiter").
* **Volta-Klammern** spannen mehrere Takte. Optionen:
  1. Volta-Group als **gemeinsamer Crop** (Bbox = Union der
     Takte 1..N der Volta) — einfacher, aber bricht das N/Zeile-Grid.
  2. Volta-Klammer als **separate Overlay-Schicht** über den
     Einzeltakt-Tiles rendern.
  Empfehlung Phase C: Variante 1 (gruppierter Crop), markiert mit
  Volta-Number-Badge.
* **System-Klammern / Akkoladen** (mehrere Stimmen vertikal): irrelevant,
  da Reflow pro Stimme gilt.
* **Padding** um jeden Crop (≈ 8–12 px @ 300 DPI), damit Stafflines
  und Akzidenzien nicht abgeschnitten werden.

---

## 22.6 UI-Mockups (ASCII-Art)

```
[Original-Modus]                 [Reflow 2/Zeile, Zoom 150%]
┌─────────────────────┐          ┌──────────────┬───────────┐
│ ♩=120  1│2│3│4│5│6 │          │ ♩=120 │  1   │   2       │
│        ─────────── │          │       │      │           │
│  7│8│9│10│11│12   │          │       └──────┴───────────┤
│ ─────────────────  │          │  3            │  4        │
│ 13│14│15│16        │          │ ──── Cursor ──┴──────────┤
└─────────────────────┘          │  5            │  6        │
                                 │ ──────────────┴──────────┘
                                 │  ... weiter scrollen ...
```

```
[Single-Measure-Mode, Live, Auto-Advance]
┌────────────────────────────────────────┐
│  ♩=120          Takt 14 / 87           │
│                                        │
│                                        │
│        ┌───────────────────────┐       │
│        │   ♪ ♪ ♩ ♩  | ♩. ♪ ♩  │       │   ← großer einzelner Takt
│        │   ───────────────────│       │
│        └───────────────────────┘       │
│                                        │
│  ●───●───●───●  Beat-Indikator         │
│                                        │
│   [⏮ Probe]   [▶ Live-Sync]   [⏭]      │
└────────────────────────────────────────┘
```

Mini-Map-Indikator (optional, Phase C/D): Streifen am unteren Rand
mit Punkt pro System, aktueller Punkt hervorgehoben.

---

## 22.7 Implementation-Phasen

### Phase A — Layer 1 + 2 (jetzt, PR #136 oder Folge-PR)

* **Bbox pro Takt** stabilisieren (haben wir teilweise — Quality-Gate
  ≥ 95 % auf Test-Korpus).
* **Sprungmarken-Detection** ausbauen: Volta, D.C., D.S., Coda, Segno,
  Fine, Repeat-Bars. Coda/Segno/D.S.-Disambiguation ist heute
  unzuverlässig (siehe README-OMR-Status) → Symbol-Library
  (Spec 18) und Layout-Hints anziehen.
* **PerformanceTimeline-Linearizer** als reine Funktion implementieren
  + Unit-Tests gegen die 5 Referenzstücke.
* **Daten-Export**: API liefert `MeasureLayout[] + PerformanceTimeline`
  pro Stimme als JSON neben dem PDF.

### Phase B — Cross-Instrument-Sync

* **BLE-Paket erweitern** (Spec 05): `linear_performance_index`
  zusätzlich zu / anstelle von `measureNumber`. Versionsbump
  `version = 0x03` mit Backwards-Fallback.
* **Server-Side**: pro Stimme `linear_index → bbox_orig`-Map
  vorrechnen und cachen.
* **Mobile UI**: Cursor-Overlay über Original-PDF, Update bei
  jedem `PositionAnchor`.

### Phase C — Reflowable Layout

* **Crop-Pipeline** (Server, async Job): Bbox → PNG-Tile pro Takt,
  Caching.
* **Mobile UI**: Grid-Layout-Modus, Toggle zwischen Original/Reflow.
* **Performance-Budget**: 100 Takte rendern in < 100 ms (Target).

### Phase D — Single-Measure-Auto-Advance

* Premium-Feature.
* Nur 1 Takt sichtbar, Auto-Advance bei `beat == 0` des nächsten
  Takts.
* User-konfigurierbar: „Lookahead" (Takt N+1 als kleines Preview unten).

---

## 22.8 Trade-Offs & Open Questions

| Thema | Frage | Tendenz |
|---|---|---|
| **Slur-Continuation** | Bögen über Taktgrenzen — abschneiden vs. mehrere Takte gemeinsam croppen? | Phase C: abschneiden + Tilde-Marker. Slur-Reflow-Algorithmus = Phase 4+. |
| **Mini-Map** | Braucht der User einen System-Index-Indikator im Reflow? | A/B-Test in Phase C. |
| **Volta im Reflow** | Volta 1./2. nebeneinander mit „Repeat"-Symbol vs. linear hintereinander? | Empfehlung: gemeinsamer Crop pro Volta-Group (siehe 22.5). |
| **Performance** | Crop+Render von 100 Takten in < 100 ms erreichbar? | Wahrscheinlich ja mit Server-side Pre-Rendering und PNG-Tile-Cache. Verifizieren in Phase C. |
| **Gestures** | Pinch-Zoom, Double-Tap-Auto-Advance, Swipe-für-Nächste-Zeile? | Standard-Gestures spezifizieren wenn Phase C closed ist. |
| **Multimeasure-Rests** | Wie expandieren wenn nicht alle Stimmen das gleich notieren? | Symmetrisch zu N realen Takten expandieren — Sprungmarken ignorieren MMRs nicht. |
| **Handgeschriebene Marken** | Dirigent annotiert „Wiederholung streichen" — wie in PerformanceTimeline einfließen lassen? | Phase 2+ Manual-Override-UI: User kann pro Stück Linear-Order editieren. |

---

## 22.9 Akzeptanz-Kriterien

### Phase A — done wenn

* ≥ 95 % der Takt-Bboxes auf Test-Korpus (5 echte PDFs:
  Mendocino, ANGELS, Bohemian Rhapsody Medley, sowie 2 weitere
  Vereinsstücke) korrekt.
* Volta 1./2. + Coda-Marken werden in linearer Performance-Order
  korrekt aufgelöst.
* Unit-Tests für `PerformanceTimeline`-Linearizer mit
  ≥ 10 synthetischen + 5 echten Eingaben grün.
* Quality-Gate: PerformanceTimeline-Längen-Diff zwischen Stimmen
  desselben Stücks ≤ 1 %.

### Phase B — done wenn

* 2 Geräte mit verschiedenen Stimmen highlighten synchron den
  gleichen logischen Takt (Sichtprüfung).
* Manueller Test mit Klar 1 + Klar 2 auf Mendocino erfolgreich.
* BLE-Latenz-Budget aus Spec 05 weiterhin eingehalten
  (Highlight-Update ≤ 200 ms nach Anchor).

### Phase C — done wenn

* User kann 1 / 2 / 3 / 4 Takte pro Zeile wählen.
* Zoom 50 %–300 % stufenlos.
* Cursor + Highlight bleiben bei Reflow funktional.
* Slur-Tilde-Marker erscheint bei abgeschnittenen Bögen.

### Phase D — done wenn

* Single-Measure-Mode mit Auto-Advance bei Beat-0-Wechsel.
* Lookahead-Preview konfigurierbar (0 / 1 / 2 Takte).
* Funktioniert ohne erkannten Layer 4 (nur Bbox + Tempo).

---

## 22.10 Out of Scope (für jetzt)

* **Slur-Reflow** (Bögen visuell rekonstruieren über umgebrochene Takte) — Phase 4+.
* **Notations-Editor** (User editiert Pitches/Durations) — eigene Feature-Familie.
* **Voice-Highlighting innerhalb eines Takts** (Bass-Linie hervorheben) — braucht Layer 5.
* **Audio-Synchronization** (App lauscht aufs Orchester und schätzt Position) — siehe Spec 20 (Phase 3 SMT-Cloud-Backstop).
* **Video-/Looper-Funktionen** — eigene Spec-Familie.

---

## 22.11 Querverweise

* `docs/01-functional-spec.md §2.7` — Digitalisierung / Import.
* `docs/05-conductor-sync-protocol.md` — BLE-Paket-Erweiterung
  `linear_performance_index`.
* `docs/15-omr-pipeline-spec.md` — Pipeline-Stufen, Layer-Mapping.
* `docs/17-playback-and-sync.md` — Cursor-Service nutzt Bbox-Map.
* `docs/18-symbol-library-and-layout.md` — Symbol-Library für
  Volta/Coda/Segno/D.C./D.S./Fine.
* `docs/20-phase3-cloud-backstop.md` — Cloud-Audio-Backstop (orthogonal,
  ergänzt Position-Tracking ohne BLE-Dirigent).
* `.squad/decisions.md` ADR-OMR-003 — **Layered OMR & Measure-First**.
