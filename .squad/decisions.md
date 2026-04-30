# Architektur-Entscheidungen (ADRs)

Dieses Dokument sammelt die zentralen Architektur-Entscheidungen für
Sheetstorm. Jede Entscheidung wird als kurzer ADR (Architecture Decision
Record) dokumentiert. Neue Entscheidungen werden chronologisch unten
angefügt.

---

## ADR-OMR-002: Symbol-Library + Layout-Hints

* **Datum:** 2026-04-30
* **Status:** ACCEPTED
* **Kontext:** Echte Vereinsnoten enthalten viele Symbole jenseits von
  Noteheads (Fermaten, Akzente, Tempo-Text, Dynamik, Slurs, Volta-Klammern,
  Wiederholungs-Marken). Die aktuelle OMR-Engine in `src/omr-rust/`
  erkennt nur Notehead/Stem/Beam/Bar. Text-Bereiche wie *espressivo*,
  *rit.*, Tempo-Marken oder Liedtext wurden bisher fälschlich als
  Noteheads detektiert (False Positives), während musikalisch relevante
  Symbole still fehlten (False Negatives).
* **Entscheidung:** Phasenweiser Aufbau einer **Symbol-Library** mit
  synthetischen Templates und Bravura/Emmentaler-Glyphen (permissive
  Lizenzen, kein Audiveris-Code). **Layout-Hints** geben den
  Pipeline-Stufen erwartete Bereiche pro Symbol-Typ vor (Titel oben,
  Dynamik unter dem System, Tempo über Takt 1, …). Vor der
  Notehead-Detektion läuft ein **Text-Diskriminator**, der typografische
  Bereiche markiert und vom Notehead-Pfad ausschließt. Details und
  Phasenplan: `docs/18-symbol-library-and-layout.md`.
* **Konsequenz:** Höhere Code-Komplexität in der OMR-Engine
  (zusätzliche Pipeline-Stufen, größeres Template-Inventar, neue
  Validierungs-Anforderungen pro Symbol-Klasse), aber **massiv bessere
  Accuracy auf realen Scans** und nachvollziehbare Per-Symbol-Metriken.
  Validierung pflichtweise gegen synthetisches Korpus + manuell
  annotierte Ground-Truth auf mindestens 3 echten Scans.
* **Alternativen abgelehnt:**
  * **(a) Nur Notehead-Erkennung verbessern** — zu unzuverlässig auf
    realen Vereinsnoten; löst weder False Positives durch Text noch
    False Negatives bei Fermate/Akzent/Dynamik.
  * **(b) ML-basiertes End-to-End-Modell** — zu langsam für unsere
    Latenz-Ziele (< 30 s pro Seite, 1 CPU-Kern), schwer reproduzierbar,
    Trainingsdaten-Beschaffung aufwendig, schlechte Erklärbarkeit für
    den UI-Reviewer.
* **Verweise:**
  * `docs/15-omr-pipeline-spec.md` — Pipeline-Stufen
  * `docs/16-omr-algorithm-research.md` — Algorithmen-Recherche
  * `docs/18-symbol-library-and-layout.md` — vollständige Spezifikation
  * `docs/01-functional-spec.md §2.7` — funktionaler Hinweis

---

## ADR-OMR-003: Layered OMR & Measure-First-Strategy

* **Datum:** 2026-04-30
* **Status:** ACCEPTED
* **Kontext:** Vollständige OMR (alle Noten zu 100 % korrekt erkannt)
  ist auf realen Vereinsnoten hart — heutiger Notehead-Recall liegt
  realistisch bei 60–80 %. Trotzdem wartet ein Großteil des
  User-Mehrwerts (Live-Position-Highlighting, Cross-Instrument-Sync,
  Reflowable Layout) **nicht** auf perfekte Note-Erkennung: Er hängt
  primär an robust erkannten **Takten + Sprungmarken + Tempo**.
* **Entscheidung:** Die OMR-Pipeline wird in **Layer 0–5** strukturiert
  (siehe `docs/22-measure-tracking-and-reflow.md`). Layer 1–3
  (Takt-Bboxes, Sprungmarken, Time-Signature/Tempo) werden als
  **MVP-Tier** geliefert und sind für die Killer-Features A
  (Live-Highlight), B (Cross-Instrument-Sync), C (Reflowable Layout)
  ausreichend — auch wenn Layer 4–5 (Pitches/Durations,
  Voices/Slurs) nur teilweise erkannt sind. Die `PerformanceTimeline`
  (linearisierte Spielreihenfolge) wird als reine Funktion über
  `MeasureLayout[]` implementiert und ist stimmenübergreifend
  identisch.
* **Konsequenz:** Investitions-Priorität verschiebt sich von
  „Notehead-Recall maximieren" auf **„Takt- und Sprungmarken-Erkennung
  robust machen"**. Quality-Gates: ≥ 95 % Bbox-Korrektheit auf
  Test-Korpus, PerformanceTimeline-Längen-Diff zwischen Stimmen
  ≤ 1 %. BLE-Protokoll (Spec 05) bekommt Versionsbump v3 mit Feld
  `linear_performance_index`. Score-Playback (Spec 17) bleibt
  optional / Layer-4-abhängig.
* **Alternativen abgelehnt:**
  * **(a) Erst alle Layer fertig, dann Features liefern** — würde
    Cross-Instrument-Sync und Reflow um Quartale verzögern, ohne
    technischen Grund.
  * **(b) Reines Pixel-Streaming des PDFs ohne semantische Layer** —
    macht Cross-Instrument-Sync und Reflow unmöglich.
* **Verweise:**
  * `docs/22-measure-tracking-and-reflow.md` — vollständige Spezifikation
  * `docs/05-conductor-sync-protocol.md` — BLE-Paket v3
  * `docs/15-omr-pipeline-spec.md` — Pipeline-Stufen pro Layer
  * `docs/17-playback-and-sync.md` — Cursor-Service nutzt Bbox-Map
