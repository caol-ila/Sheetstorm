# omr-sig-store — SQLite-Persistenz für den Symbol Interpretation Graph

> Phase 3 der SIG-Architektur: SQLite-Persistenz, Op-Log und R\*-Tree Spatial-Index.

## Überblick

`omr-sig-store` ergänzt `omr-sig` um persistente Speicherung:

| Modul | Inhalt |
|---|---|
| [`store`](src/store.rs) | `SigStore`: `load_sig` / `save_sig`, `record_op`, `snapshot`, `inters_in_rect` |
| [`schema`](src/schema.rs) | SQLite-Schema V1 (Migrationen mit `CREATE TABLE IF NOT EXISTS`) |
| [`ops`](src/ops.rs) | Op-Log: append-only Schreiben und Lesen der `ops`-Tabelle |
| [`spatial`](src/spatial.rs) | R\*-Tree-Wrapper: `SpatialEntry`, `build_spatial_index`, `query_rect` |
| [`error`](src/error.rs) | `StoreError` (SQLite + JSON), `Result<T>` Alias |

## API

```rust
use std::path::Path;
use omr_sig_store::SigStore;
use omr_sig::{Sig, EditOperationKind, InterId};

// In-Memory (ideal für Tests)
let mut store = SigStore::open_in_memory()?;

// Dateibasiert
let mut store = SigStore::open(Path::new("scene.db"))?;

// Sig speichern
store.save_sig(&sig)?;

// Sig laden (rekonstruiert auch den Spatial-Index)
let sig = store.load_sig()?;

// Op-Log
let op_id = store.record_op(EditOperationKind::AddInter { id: InterId(1) }, "user")?;

// Snapshot erstellen
store.snapshot("after-detect")?;

// Spatial-Query
let inters = store.inters_in_rect(100, 50, 200, 100);
```

## SQLite-Schema V1

```sql
CREATE TABLE inters (
    id INTEGER PRIMARY KEY,
    kind TEXT NOT NULL,
    bbox_x INTEGER NOT NULL, bbox_y INTEGER NOT NULL,
    bbox_w INTEGER NOT NULL, bbox_h INTEGER NOT NULL,
    grade REAL NOT NULL,
    contextual REAL,
    provenance TEXT NOT NULL,
    frozen INTEGER NOT NULL DEFAULT 0,
    system_idx INTEGER, staff_idx INTEGER,
    measure_number INTEGER, voice INTEGER,
    payload_json TEXT NOT NULL DEFAULT '{}'
);

CREATE TABLE relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_id INTEGER NOT NULL, to_id INTEGER NOT NULL,
    kind TEXT NOT NULL,
    variant TEXT NOT NULL,   -- 'support' or 'exclusion'
    impacts_json TEXT,        -- SupportImpacts als JSON
    cause TEXT,               -- ExclusionCause als JSON
    provenance TEXT NOT NULL,
    frozen INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE ops (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_id INTEGER,
    kind_json TEXT NOT NULL,  -- EditOperationKind als JSON
    timestamp TEXT NOT NULL,
    author TEXT NOT NULL
);

CREATE TABLE snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT NOT NULL,
    op_id INTEGER NOT NULL,
    sig_json BLOB NOT NULL,  -- JSON: {inters:[...], relations:[...]}
    created_at TEXT NOT NULL
);
```

## Design-Entscheidungen

### Spatial-Index: In-Memory, nicht persistiert

Der R\*-Tree (`rstar::RTree<SpatialEntry>`) wird bei `load_sig()` aus den
Datenbank-Rows rekonstruiert. Keine separate Persistenz notwendig — der
SQLite-Roundtrip ist schnell genug für typische SIG-Größen.

### JSON für komplexe Felder

`payload_json`, `impacts_json`, `kind_json` sind als JSON gespeichert.
Das erleichtert Schema-Evolution ohne Breaking-Migrations.

### Op-Log: append-only

Kein UPDATE/DELETE auf die `ops`-Tabelle. Das Log ist unveränderlich und
dient als Audit-Trail und Undo/Redo-Basis.

### Dynamisches Linking gegen `winsqlite3.dll`

Auf Windows linkt die Crate gegen `winsqlite3.dll` (via
`sqlite3lib/libsqlite3.a` — eine Import-Library), ohne dass ein C-Compiler
benötigt wird. Auf anderen Systemen kann die `bundled`-Feature von `rusqlite`
aktiviert werden.

## Tests

```powershell
cd src/omr-rust
cargo test -p omr-sig-store
# 8 tests passed
```

### Test-Suite

| Test | Was wird geprüft |
|---|---|
| `open_in_memory_works` | Store öffnet sich korrekt |
| `save_and_load_roundtrip` | Anzahl + Kinds + Grades nach Roundtrip korrekt |
| `frozen_inters_persist` | Frozen-Flag und User-Provenance überleben Roundtrip |
| `relations_persist` | Support- und Exclusion-Edges korrekt persistiert |
| `op_log_appends_and_reads` | Ops monoton steigend, Author korrekt gespeichert |
| `snapshot_creates_versioned_record` | Snapshot-Count steigt, Label gespeichert |
| `spatial_query_finds_inters_in_region` | R\*-Tree findet Inters in Region |
| `spatial_query_excludes_outside` | R\*-Tree schließt Inters außerhalb aus |
