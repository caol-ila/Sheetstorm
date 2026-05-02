//! SQLite-Schema-Migrationen für omr-sig-store.
//!
//! Schema V1: Inters, Relations, Op-Log (append-only), Snapshots.

use rusqlite::{Connection, Result};

const SCHEMA_V1: &str = r#"
CREATE TABLE IF NOT EXISTS inters (
    id          INTEGER PRIMARY KEY,
    kind        TEXT    NOT NULL,
    bbox_x      INTEGER NOT NULL,
    bbox_y      INTEGER NOT NULL,
    bbox_w      INTEGER NOT NULL,
    bbox_h      INTEGER NOT NULL,
    grade       REAL    NOT NULL,
    contextual  REAL,
    provenance  TEXT    NOT NULL,
    frozen      INTEGER NOT NULL DEFAULT 0,
    system_idx  INTEGER,
    staff_idx   INTEGER,
    measure_number INTEGER,
    voice       INTEGER,
    payload_json TEXT   NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_inters_kind   ON inters(kind);
CREATE INDEX IF NOT EXISTS idx_inters_system ON inters(system_idx);

CREATE TABLE IF NOT EXISTS relations (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    from_id      INTEGER NOT NULL,
    to_id        INTEGER NOT NULL,
    kind         TEXT    NOT NULL,
    variant      TEXT    NOT NULL,
    impacts_json TEXT,
    cause        TEXT,
    provenance   TEXT    NOT NULL,
    frozen       INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (from_id) REFERENCES inters(id),
    FOREIGN KEY (to_id)   REFERENCES inters(id)
);

CREATE TABLE IF NOT EXISTS ops (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_id  INTEGER,
    kind_json  TEXT NOT NULL,
    timestamp  TEXT NOT NULL,
    author     TEXT NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES ops(id)
);

CREATE TABLE IF NOT EXISTS snapshots (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    label      TEXT NOT NULL,
    op_id      INTEGER NOT NULL,
    sig_json   BLOB NOT NULL,
    created_at TEXT NOT NULL
);
"#;

/// Führt alle Schema-Migrationen aus.
pub(crate) fn migrate(conn: &Connection) -> Result<()> {
    conn.execute_batch(SCHEMA_V1)
}
