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

/// Eine vom User manuell gezogene Bounding-Box-Annotation.
///
/// Im Gegensatz zu `Label` (Y/N-Antworten zu vorhandenen Items) speichert
/// `Annotation` die User-eigene Box-Position als Gold-Standard fuer
/// Detector-Training. Koordinaten sind im *gerenderten Crop-Bild* des Systems
/// (gleiche Skalierung wie /api/system/{id}/image).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Annotation {
    pub id: Option<i64>,
    pub system_id: String,
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
    pub class_id: String,
    pub created_at: String,
    pub user_session: Option<String>,
}

impl Annotation {
    pub fn new(system_id: impl Into<String>, x: i32, y: i32, w: i32, h: i32, class_id: impl Into<String>) -> Self {
        Self {
            id: None,
            system_id: system_id.into(),
            x,
            y,
            w,
            h,
            class_id: class_id.into(),
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

            CREATE TABLE IF NOT EXISTS annotations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                system_id TEXT NOT NULL,
                x INTEGER NOT NULL,
                y INTEGER NOT NULL,
                w INTEGER NOT NULL,
                h INTEGER NOT NULL,
                class_id TEXT NOT NULL,
                created_at TEXT NOT NULL,
                user_session TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_annotations_system_id ON annotations(system_id);
            CREATE INDEX IF NOT EXISTS idx_annotations_class_id ON annotations(class_id);
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

    /// Liefert die meistgenutzten Class-Decisions aus der DB, sortiert nach
    /// Anzahl (desc) und letzter Nutzung (desc). Format: `(class_id, count)`,
    /// ohne `class:`-Praefix. Damit kann der Labeler Top-K-Vorschlaege auf
    /// echte User-Praeferenzen (inkl. Custom-Klassen) stuetzen.
    pub fn recent_class_decisions(&self, limit: u32) -> Result<Vec<(String, u64)>> {
        let mut stmt = self.conn.prepare(
            "SELECT decision, COUNT(*) as cnt, MAX(created_at) as last
             FROM labels
             WHERE level = 'class' AND decision LIKE 'class:%'
             GROUP BY decision
             ORDER BY cnt DESC, last DESC
             LIMIT ?1",
        )?;
        let rows = stmt.query_map(params![limit as i64], |row| {
            let decision: String = row.get(0)?;
            let count: i64 = row.get(1)?;
            Ok((decision, count))
        })?;
        let mut out = Vec::new();
        for r in rows {
            let (decision, count) = r?;
            // "class:foo" → "foo"
            let class_id = decision
                .strip_prefix("class:")
                .unwrap_or(&decision)
                .to_string();
            if class_id.is_empty() {
                continue;
            }
            out.push((class_id, count.max(0) as u64));
        }
        Ok(out)
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

    // ---- Annotation-CRUD ---------------------------------------------------

    /// Speichert eine User-gezogene Annotation.
    pub fn save_annotation(&self, ann: &Annotation) -> Result<i64> {
        self.conn.execute(
            "INSERT INTO annotations (system_id, x, y, w, h, class_id, created_at, user_session)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                ann.system_id,
                ann.x,
                ann.y,
                ann.w,
                ann.h,
                ann.class_id,
                ann.created_at,
                ann.user_session,
            ],
        )?;
        Ok(self.conn.last_insert_rowid())
    }

    /// Aktualisiert die Klasse einer bestehenden Annotation (Reclassify).
    pub fn update_annotation_class(&self, id: i64, class_id: &str) -> Result<()> {
        self.conn.execute(
            "UPDATE annotations SET class_id = ?1 WHERE id = ?2",
            params![class_id, id],
        )?;
        Ok(())
    }

    /// Loescht eine Annotation.
    pub fn delete_annotation(&self, id: i64) -> Result<()> {
        self.conn
            .execute("DELETE FROM annotations WHERE id = ?1", params![id])?;
        Ok(())
    }

    /// Liefert alle Annotationen fuer ein System.
    pub fn annotations_for_system(&self, system_id: &str) -> Result<Vec<Annotation>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, system_id, x, y, w, h, class_id, created_at, user_session
             FROM annotations WHERE system_id = ?1 ORDER BY id ASC",
        )?;
        let rows = stmt.query_map(params![system_id], |row| {
            Ok(Annotation {
                id: Some(row.get(0)?),
                system_id: row.get(1)?,
                x: row.get(2)?,
                y: row.get(3)?,
                w: row.get(4)?,
                h: row.get(5)?,
                class_id: row.get(6)?,
                created_at: row.get(7)?,
                user_session: row.get(8)?,
            })
        })?;
        let mut out = Vec::new();
        for r in rows {
            out.push(r?);
        }
        Ok(out)
    }

    /// Liefert pro System die Anzahl der Annotationen (fuer die System-Liste).
    pub fn annotation_counts_per_system(&self) -> Result<Vec<(String, u64)>> {
        let mut stmt = self.conn.prepare(
            "SELECT system_id, COUNT(*) FROM annotations GROUP BY system_id ORDER BY system_id",
        )?;
        let rows = stmt.query_map([], |row| {
            let sys: String = row.get(0)?;
            let cnt: i64 = row.get(1)?;
            Ok((sys, cnt.max(0) as u64))
        })?;
        let mut out = Vec::new();
        for r in rows {
            out.push(r?);
        }
        Ok(out)
    }

    /// Anzahl Annotationen insgesamt.
    pub fn count_annotations(&self) -> Result<u64> {
        let count: i64 = self
            .conn
            .query_row("SELECT COUNT(*) FROM annotations", [], |row| row.get(0))?;
        Ok(count.max(0) as u64)
    }

    /// Liefert alle Annotationen (fuer Export).
    pub fn get_all_annotations(&self) -> Result<Vec<Annotation>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, system_id, x, y, w, h, class_id, created_at, user_session
             FROM annotations ORDER BY id ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(Annotation {
                id: Some(row.get(0)?),
                system_id: row.get(1)?,
                x: row.get(2)?,
                y: row.get(3)?,
                w: row.get(4)?,
                h: row.get(5)?,
                class_id: row.get(6)?,
                created_at: row.get(7)?,
                user_session: row.get(8)?,
            })
        })?;
        let mut out = Vec::new();
        for r in rows {
            out.push(r?);
        }
        Ok(out)
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

    #[test]
    fn recent_class_decisions_sorted_by_count() {
        let db = LabelDb::open_in_memory().unwrap();
        // Drei verschiedene Klassen mit unterschiedlichen Counts.
        for _ in 0..5 {
            db.save_label(&Label::new("class", "class:Gitarrenakkord", "elt-x"))
                .unwrap();
        }
        for _ in 0..2 {
            db.save_label(&Label::new("class", "class:Taktnummer", "elt-y"))
                .unwrap();
        }
        db.save_label(&Label::new("class", "class:atom/clef_treble", "elt-z"))
            .unwrap();
        // Non-class-Label darf nicht auftauchen.
        db.save_label(&Label::new("element", "yes", "elt-w")).unwrap();

        let recent = db.recent_class_decisions(10).unwrap();
        assert_eq!(recent.len(), 3);
        assert_eq!(recent[0], ("Gitarrenakkord".to_string(), 5));
        assert_eq!(recent[1], ("Taktnummer".to_string(), 2));
        assert_eq!(recent[2], ("atom/clef_treble".to_string(), 1));
    }

    #[test]
    fn recent_class_decisions_respects_limit() {
        let db = LabelDb::open_in_memory().unwrap();
        for i in 0..6 {
            db.save_label(&Label::new("class", &format!("class:cls{}", i), "elt"))
                .unwrap();
        }
        let recent = db.recent_class_decisions(3).unwrap();
        assert_eq!(recent.len(), 3);
    }

    #[test]
    fn save_and_query_annotations() {
        let db = LabelDb::open_in_memory().unwrap();
        let id1 = db
            .save_annotation(&Annotation::new("sys-1", 10, 20, 30, 40, "ton/viertel"))
            .unwrap();
        db.save_annotation(&Annotation::new("sys-1", 50, 20, 30, 40, "ton/achtel"))
            .unwrap();
        db.save_annotation(&Annotation::new("sys-2", 10, 20, 30, 40, "akkord/2_noten"))
            .unwrap();

        assert_eq!(db.count_annotations().unwrap(), 3);
        let s1 = db.annotations_for_system("sys-1").unwrap();
        assert_eq!(s1.len(), 2);
        assert_eq!(s1[0].class_id, "ton/viertel");

        db.update_annotation_class(id1, "ton/halbe").unwrap();
        let s1 = db.annotations_for_system("sys-1").unwrap();
        let updated = s1.iter().find(|a| a.id == Some(id1)).unwrap();
        assert_eq!(updated.class_id, "ton/halbe");

        db.delete_annotation(id1).unwrap();
        assert_eq!(db.count_annotations().unwrap(), 2);

        let counts = db.annotation_counts_per_system().unwrap();
        assert_eq!(counts.len(), 2);
    }
}
