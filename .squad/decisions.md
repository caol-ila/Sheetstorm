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
