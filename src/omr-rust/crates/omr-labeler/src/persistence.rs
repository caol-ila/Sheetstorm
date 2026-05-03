//! SQLite-Persistenz für Labels.
//!
//! Schema (idempotent):
//! ```sql
//! CREATE TABLE IF NOT EXISTS labels (
//!     id INTEGER PRIMARY KEY AUTOINCREMENT,
//!     level TEXT NOT NULL,
//!     decision TEXT NOT NULL,
//!     item_ref TEXT NOT NULL,
//!     image_data BLOB,
//!     created_at TEXT NOT NULL,
//!     user_session TEXT
//! );
//! ```

use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Eintrag in der Labels-Tabelle.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Label {
    /// Datenbank-ID. Bei neuen Labels kann das `None` sein.
    pub id: Option<i64>,
    /// Level: "line", "element" oder "class".
    pub level: String,
    /// Entscheidung: "yes", "no", "skip" oder "class:<name>".
    pub decision: String,
    /// Referenz auf das gelabelte Item (System-/Element-/Sample-ID).
    pub item_ref: String,
    /// Optional: PNG-Bytes des Patches zum Zeitpunkt des Labelings.
    pub image_data: Option<Vec<u8>>,
    /// ISO-8601-Timestamp.
    pub created_at: String,
    /// Optionaler Session-Identifier (z.B. User-Cookie).
    pub user_session: Option<String>,
}

impl Label {
    /// Hilfsfunktion: erzeugt ein neues Label mit aktuellem Timestamp.
    pub fn new(level: impl Into<String>, decision: impl Into<String>, item_ref: impl Into<String>) -> Self {
        Self {
            id: None,
            level: level.into(),
            decision: decision.into(),
            item_ref: item_ref.into(),
            image_data: None,
            created_at: now_iso8601(),
            user_session: None,
        }
    }
}

fn now_iso8601() -> String {
    // Vermeidet die `chrono`-Abhängigkeit. Nutzt SystemTime und
    // formatiert "YYYY-MM-DDTHH:MM:SSZ" via `humantime`-freier Variante.
    use std::time::{SystemTime, UNIX_EPOCH};
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Sehr einfache Konvertierung — ausreichend für Sortier-/Audit-Zwecke.
    let secs = now as i64;
    let days = secs / 86400;
    let rem = secs % 86400;
    let hh = rem / 3600;
    let mm = (rem % 3600) / 60;
    let ss = rem % 60;
    // Vereinfachte Datumsberechnung (Howard Hinnant / civil_from_days).
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as i64;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}Z",
        y, m, d, hh, mm, ss
    )
}

/// SQLite-basiertes Label-Repository.
pub struct LabelDb {
    conn: Connection,
}

impl LabelDb {
    /// Öffnet (oder erstellt) eine SQLite-Datei.
    pub fn open(path: &Path) -> Result<Self> {
        let conn = Connection::open(path)
            .with_context(|| format!("SQLite öffnen: {}", path.display()))?;
        let me = Self { conn };
        me.migrate()?;
        Ok(me)
    }

    /// Öffnet eine In-Memory-Datenbank (für Tests).
    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let me = Self { conn };
        me.migrate()?;
        Ok(me)
    }

    fn migrate(&self) -> Result<()> {
        self.conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS labels (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                level TEXT NOT NULL,
                decision TEXT NOT NULL,
                item_ref TEXT NOT NULL,
                image_data BLOB,
                created_at TEXT NOT NULL,
                user_session TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_labels_level ON labels(level);
            CREATE INDEX IF NOT EXISTS idx_labels_item_ref ON labels(item_ref);
            "#,
        )?;
        Ok(())
    }

    /// Persistiert ein Label und liefert die generierte ID.
    pub fn save_label(&self, label: &Label) -> Result<i64> {
        self.conn.execute(
            "INSERT INTO labels (level, decision, item_ref, image_data, created_at, user_session)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                label.level,
                label.decision,
                label.item_ref,
                label.image_data,
                label.created_at,
                label.user_session,
            ],
        )?;
        Ok(self.conn.last_insert_rowid())
    }

    /// Anzahl Labels für einen Level (oder "" für alle).
    pub fn count_labels(&self, level: &str) -> Result<u64> {
        let count: i64 = if level.is_empty() {
            self.conn
                .query_row("SELECT COUNT(*) FROM labels", [], |row| row.get(0))?
        } else {
            self.conn.query_row(
                "SELECT COUNT(*) FROM labels WHERE level = ?1",
                params![level],
                |row| row.get(0),
            )?
        };
        Ok(count.max(0) as u64)
    }

    /// Liefert alle Labels (sortiert nach ID).
    pub fn get_all_labels(&self) -> Result<Vec<Label>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, level, decision, item_ref, image_data, created_at, user_session
             FROM labels ORDER BY id ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(Label {
                id: Some(row.get(0)?),
                level: row.get(1)?,
                decision: row.get(2)?,
                item_ref: row.get(3)?,
                image_data: row.get(4)?,
                created_at: row.get(5)?,
                user_session: row.get(6)?,
            })
        })?;
        let mut out = Vec::new();
        for r in rows {
            out.push(r?);
        }
        Ok(out)
    }

    /// Löscht das zuletzt eingefügte Label und liefert es zurück (Undo).
    pub fn pop_last_label(&self) -> Result<Option<Label>> {
        let row: Option<Label> = self
            .conn
            .query_row(
                "SELECT id, level, decision, item_ref, image_data, created_at, user_session
                 FROM labels ORDER BY id DESC LIMIT 1",
                [],
                |row| {
                    Ok(Label {
                        id: Some(row.get(0)?),
                        level: row.get(1)?,
                        decision: row.get(2)?,
                        item_ref: row.get(3)?,
                        image_data: row.get(4)?,
                        created_at: row.get(5)?,
                        user_session: row.get(6)?,
                    })
                },
            )
            .ok();
        if let Some(ref l) = row {
            if let Some(id) = l.id {
                self.conn
                    .execute("DELETE FROM labels WHERE id = ?1", params![id])?;
            }
        }
        Ok(row)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn save_and_count_labels() {
        let db = LabelDb::open_in_memory().unwrap();
        assert_eq!(db.count_labels("").unwrap(), 0);
        db.save_label(&Label::new("line", "yes", "sys-1")).unwrap();
        db.save_label(&Label::new("element", "no", "elt-1")).unwrap();
        assert_eq!(db.count_labels("").unwrap(), 2);
        assert_eq!(db.count_labels("line").unwrap(), 1);
    }

    #[test]
    fn pop_last_returns_inserted() {
        let db = LabelDb::open_in_memory().unwrap();
        db.save_label(&Label::new("line", "yes", "sys-1")).unwrap();
        db.save_label(&Label::new("element", "no", "elt-1")).unwrap();
        let popped = db.pop_last_label().unwrap().unwrap();
        assert_eq!(popped.item_ref, "elt-1");
        assert_eq!(db.count_labels("").unwrap(), 1);
    }
}
