# omr-labeler

Standalone Active-Learning-Labeling-Tool für die Sheetstorm OMR-Pipeline.

## Was es ist

Ein einzelner Rust-Prozess (`omr-labeler`), der

1. einen lokalen HTTP-Server (axum) startet,
2. ein eingebettetes Web-Frontend ausliefert (Vanilla JS, kein Build-Step),
3. PDFs aus einem Filestore einliest, StaffSysteme erkennt und Element-
   Patches extrahiert,
4. einen synthetischen Cold-Start-Corpus zum Seed der Queue verwendet,
5. den Annotator mit hochmotiviertem keyboard-driven UX durch die Queue
   führt und
6. alle Antworten in einer SQLite-Datenbank persistiert.

## Architektur

```
src/
├── main.rs              CLI + Server-Bootstrapping
├── api.rs               axum-Router + Handler
├── pipeline.rs          PDF → Systems → Elements + HoG-Embeddings
├── active_learning.rs   Queue (Level, Decision, Re-Prioritization)
├── synthetic_warmup.rs  Cold-Start aus Klassen-Subdirs
├── persistence.rs       SQLite-Repository für Labels
└── frontend.rs          Embed der HTML/CSS/JS-Assets

web/
├── index.html           Layout + Sidebar
├── style.css            Dark-mode, minimalist
└── app.js               Queue-Polling, Hotkeys, Stats
```

Abhängige Crates:

- `omr-core` — Typen (Binary, StaffSystem, Rect, …).
- `omr-staff` — Staff-Detection + Removal.
- `omr-pipeline` — `pdf_render::render_pages` (best effort, fällt
  zurück, wenn pdfium nicht verfügbar ist).
- `omr-embed` — neuer Stub-Crate; HogEncoder + EmbeddingIndex.

## Start

```pwsh
cd src/omr-rust
cargo run -p omr-labeler -- --filestore <pfad> --port 8095
```

Optionen:

| Option              | Default                                   | Beschreibung                          |
|---------------------|-------------------------------------------|---------------------------------------|
| `--filestore`       | `src/.filestore/parts`                    | Wurzelverzeichnis mit PDFs            |
| `--synthetic-corpus`| `tools/training/data/synthetic_corpus_v1` | Klassen-Subdirs für den Cold-Start    |
| `--db`              | `labeler.db`                              | SQLite-Datei                          |
| `--port`            | `8095`                                    | TCP-Port                              |
| `--no-browser`      | (off)                                     | Browser nicht automatisch öffnen      |

## Hotkeys

| Taste     | Aktion                       |
|-----------|------------------------------|
| `Y`       | Antwort *Yes*                |
| `N`       | Antwort *No*                 |
| `Space`   | Item überspringen            |
| `U`       | Letztes Label rückgängig     |
| `1`–`5`   | Top-K-Klassen wählen         |
| `E`       | Klasse manuell eingeben      |

## API-Endpoints

| Methode | Pfad                          | Zweck                                  |
|---------|-------------------------------|----------------------------------------|
| GET     | `/`                           | Frontend (`index.html`)                |
| GET     | `/api/status`                 | Counts (PDFs, Systems, Elements, Labels)|
| GET     | `/api/queue/next?level=&n=`   | Nächste Items                          |
| POST    | `/api/queue/answer`           | Antwort speichern                      |
| POST    | `/api/queue/skip`             | Item überspringen                      |
| POST    | `/api/queue/undo`             | Letztes Label entfernen                |
| GET     | `/api/system/{id}/image`      | PNG des Systems                        |
| GET     | `/api/element/{id}/image`     | PNG des Element-Patches                |
| GET     | `/api/stats`                  | Fortschritt + Per-Level-Counts         |
| GET     | `/api/export/corpus`          | JSON-Export aller Labels               |

## Wichtige Entscheidungen

* **Kein `bundled`-Feature für rusqlite.** Der Workspace nutzt
  dynamisches Linken gegen `winsqlite3.dll` (siehe `.cargo/config.toml`
  und `omr-sig-store`). Das Tool folgt dieser Konvention.
* **Eingebettete Web-Assets via `include_str!`.** Damit der Binary ohne
  externe Datei-Abhängigkeiten ausgeliefert werden kann.
* **Brute-force-EmbeddingIndex** im neuen `omr-embed`-Crate — reicht für
  Labeling-Workloads (< 10k Items), kann später durch HNSW ersetzt
  werden.
* **pdfium-Fallback.** Wenn die pdfium-Bibliothek nicht verfügbar ist,
  loggt das Tool eine Warnung und arbeitet mit einer leeren Pipeline-
  State weiter — kein Panic.

## Tests

```pwsh
cd src/omr-rust
cargo test -p omr-labeler
```

Abdeckung:

* `pipeline::tests::scan_filestore_finds_pdfs`
* `pipeline::tests::scan_filestore_handles_missing_dir`
* `active_learning::tests::push_and_next`
* `active_learning::tests::re_prioritize_sorts_high_first`
* `active_learning::tests::answered_items_dont_repeat`
* `active_learning::tests::skip_moves_to_end`
* `synthetic_warmup::tests::load_empty_dir_returns_empty`
* `synthetic_warmup::tests::load_corpus_with_classes`
* `persistence::tests::save_and_count_labels`
* `persistence::tests::pop_last_returns_inserted`
* Integration: `tests/api_tests.rs` mit
  `api_status_returns_counts`,
  `api_queue_next_returns_item`,
  `api_queue_answer_persists_label`,
  `api_export_corpus_returns_json`.
