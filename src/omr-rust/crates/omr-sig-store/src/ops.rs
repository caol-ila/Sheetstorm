//! OpLog-Persistenz: append-only Operations-Log in SQLite.
//!
//! Kein UPDATE/DELETE auf die ops-Tabelle — das Log ist unveränderlich.

use omr_sig::EditOperationKind;
use rusqlite::Connection;

use crate::error::Result;

/// Schreibt eine neue Operation in die ops-Tabelle.
///
/// Gibt die SQLite-rowid zurück (=persistente ID der Operation).
pub(crate) fn append_op(
    conn: &Connection,
    kind: &EditOperationKind,
    author: &str,
    timestamp: &str,
) -> Result<i64> {
    let kind_json = serde_json::to_string(kind)?;

    // parent = letzte op id (falls vorhanden)
    let parent_id: Option<i64> = conn
        .query_row("SELECT MAX(id) FROM ops", [], |row| row.get(0))
        .ok()
        .flatten();

    conn.execute(
        "INSERT INTO ops (parent_id, kind_json, timestamp, author) VALUES (?1, ?2, ?3, ?4)",
        rusqlite::params![parent_id, kind_json, timestamp, author],
    )?;

    Ok(conn.last_insert_rowid())
}

/// Liest alle Operationen aus der ops-Tabelle in chronologischer Reihenfolge.
pub(crate) fn list_ops(conn: &Connection) -> Result<Vec<(i64, EditOperationKind, String, String)>> {
    let mut stmt =
        conn.prepare("SELECT id, kind_json, timestamp, author FROM ops ORDER BY id ASC")?;

    let rows = stmt.query_map([], |row| {
        let id: i64 = row.get(0)?;
        let kind_json: String = row.get(1)?;
        let timestamp: String = row.get(2)?;
        let author: String = row.get(3)?;
        Ok((id, kind_json, timestamp, author))
    })?;

    let mut result = Vec::new();
    for row in rows {
        let (id, kind_json, timestamp, author) = row?;
        let kind: EditOperationKind = serde_json::from_str(&kind_json)?;
        result.push((id, kind, timestamp, author));
    }
    Ok(result)
}

/// Zählt die Einträge im Op-Log.
pub(crate) fn count_ops(conn: &Connection) -> Result<i64> {
    let n: i64 = conn.query_row("SELECT COUNT(*) FROM ops", [], |row| row.get(0))?;
    Ok(n)
}
