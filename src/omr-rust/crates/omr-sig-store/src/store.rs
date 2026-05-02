//! SigStore — SQLite-Persistenz für den Symbol Interpretation Graph.
//!
//! Speichert Inters, Relations, Op-Log und Snapshots.
//! Hält einen R*-Tree-Spatial-Index im Speicher (wird bei `load_sig`
//! aus der DB rekonstruiert).

use std::path::Path;

use omr_sig::{
    EditOperationKind, ExclusionCause, Grade, History, InterId, InterMeta, OperationId,
    Provenance, Relation, RelationKind, Sig, SupportImpacts,
};
use omr_sig::relation::RelationVariant;
use rstar::RTree;
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use tracing::debug;

use crate::{
    error::Result,
    ops::{append_op, count_ops, list_ops},
    schema::migrate,
    spatial::{build_spatial_index, query_rect, SpatialEntry},
};

// ── GenericInter ──────────────────────────────────────────────────────────────

/// Minimaler Inter-Typ für Roundtrip aus SQLite.
///
/// Trägt nur die `InterMeta`; typ-spezifische Felder (Pitch, NoteheadKind, ...)
/// werden in `payload_json` abgelegt (für zukünftige Typed-Deserialisierung).
#[derive(Debug)]
struct GenericInter {
    meta: InterMeta,
}

impl omr_sig::Inter for GenericInter {
    fn meta(&self) -> &InterMeta {
        &self.meta
    }
    fn meta_mut(&mut self) -> &mut InterMeta {
        &mut self.meta
    }
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
        self
    }
}

// ── Serialisierungs-Hilfsstrukturen für Snapshots ────────────────────────────

#[derive(Serialize, Deserialize)]
struct InterRow {
    id: i64,
    kind: String,
    bbox_x: u32,
    bbox_y: u32,
    bbox_w: u32,
    bbox_h: u32,
    grade: f64,
    contextual: Option<f64>,
    provenance: String,
    frozen: bool,
    system_idx: Option<u32>,
    staff_idx: Option<u32>,
    measure_number: Option<u32>,
    voice: Option<u8>,
    payload_json: String,
}

#[derive(Serialize, Deserialize)]
struct RelationRow {
    from_id: i64,
    to_id: i64,
    kind: String,
    variant: String,
    impacts_json: Option<String>,
    cause: Option<String>,
    provenance: String,
    frozen: bool,
}

#[derive(Serialize, Deserialize)]
struct SigSnapshot {
    inters: Vec<InterRow>,
    relations: Vec<RelationRow>,
}

// ── SigStore ──────────────────────────────────────────────────────────────────

/// SQLite-basierter Speicher für einen Symbol Interpretation Graph.
///
/// Hält eine SQLite-`Connection`, einen R*-Tree-Spatial-Index (im Speicher)
/// und ein in-memory `History`-Log.
pub struct SigStore {
    pub(crate) conn: Connection,
    pub(crate) spatial: RTree<SpatialEntry>,
    pub(crate) history: History,
}

impl SigStore {
    /// Öffnet (oder erstellt) eine SQLite-Datei und führt Schema-Migrationen aus.
    pub fn open(path: &Path) -> Result<Self> {
        let conn = Connection::open(path)?;
        migrate(&conn)?;
        Ok(Self {
            conn,
            spatial: RTree::new(),
            history: History::new(),
        })
    }

    /// Öffnet einen In-Memory-Store (ideal für Tests).
    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        migrate(&conn)?;
        Ok(Self {
            conn,
            spatial: RTree::new(),
            history: History::new(),
        })
    }

    // ── Sig-Persistenz ────────────────────────────────────────────────────────

    /// Speichert den kompletten Sig-State in SQLite (replaces existing data).
    ///
    /// Aktualisiert auch den Spatial-Index im Speicher.
    pub fn save_sig(&mut self, sig: &Sig) -> Result<()> {
        // 1. Spatial-Daten vorbereiten (vor dem borrow auf self.conn)
        let mut spatial_entries: Vec<SpatialEntry> = Vec::new();

        let mut inter_rows: Vec<InterRow> = Vec::new();
        for inter in sig.inters() {
            let meta = inter.meta();
            spatial_entries.push(SpatialEntry {
                inter_id: meta.id,
                bbox: [meta.bounds.x, meta.bounds.y, meta.bounds.w, meta.bounds.h],
            });
            inter_rows.push(InterRow {
                id: meta.id.0 as i64,
                kind: serde_json::to_string(&meta.kind)?,
                bbox_x: meta.bounds.x,
                bbox_y: meta.bounds.y,
                bbox_w: meta.bounds.w,
                bbox_h: meta.bounds.h,
                grade: meta.grade.value(),
                contextual: meta.contextual.map(|g| g.value()),
                provenance: serde_json::to_string(&meta.provenance)?,
                frozen: meta.frozen,
                system_idx: meta.system_idx,
                staff_idx: meta.staff_idx,
                measure_number: meta.measure_number,
                voice: meta.voice,
                payload_json: serde_json::to_string(&meta)?,
            });
        }

        let mut relation_rows: Vec<RelationRow> = Vec::new();
        for relation in sig.relations() {
            let (variant_str, impacts_json, cause_str) = match &relation.variant {
                RelationVariant::Support(impacts) => {
                    ("support".to_string(), Some(serde_json::to_string(impacts)?), None)
                }
                RelationVariant::Exclusion(cause) => {
                    ("exclusion".to_string(), None, Some(serde_json::to_string(cause)?))
                }
            };
            relation_rows.push(RelationRow {
                from_id: relation.from.0 as i64,
                to_id: relation.to.0 as i64,
                kind: serde_json::to_string(&relation.kind)?,
                variant: variant_str,
                impacts_json,
                cause: cause_str,
                provenance: serde_json::to_string(&relation.provenance)?,
                frozen: relation.frozen,
            });
        }

        // 2. Alles in einer Transaktion schreiben
        {
            let tx = self.conn.transaction()?;
            tx.execute("DELETE FROM relations", [])?;
            tx.execute("DELETE FROM inters", [])?;

            for row in &inter_rows {
                tx.execute(
                    "INSERT INTO inters (id, kind, bbox_x, bbox_y, bbox_w, bbox_h, \
                     grade, contextual, provenance, frozen, system_idx, staff_idx, \
                     measure_number, voice, payload_json) \
                     VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15)",
                    rusqlite::params![
                        row.id,
                        row.kind,
                        row.bbox_x,
                        row.bbox_y,
                        row.bbox_w,
                        row.bbox_h,
                        row.grade,
                        row.contextual,
                        row.provenance,
                        row.frozen as i32,
                        row.system_idx,
                        row.staff_idx,
                        row.measure_number,
                        row.voice,
                        row.payload_json,
                    ],
                )?;
            }

            for row in &relation_rows {
                tx.execute(
                    "INSERT INTO relations (from_id, to_id, kind, variant, \
                     impacts_json, cause, provenance, frozen) \
                     VALUES (?1,?2,?3,?4,?5,?6,?7,?8)",
                    rusqlite::params![
                        row.from_id,
                        row.to_id,
                        row.kind,
                        row.variant,
                        row.impacts_json,
                        row.cause,
                        row.provenance,
                        row.frozen as i32,
                    ],
                )?;
            }

            tx.commit()?;
        }

        // 3. Spatial-Index neu aufbauen
        self.spatial = build_spatial_index(spatial_entries);

        debug!(inters = inter_rows.len(), relations = relation_rows.len(), "save_sig complete");
        Ok(())
    }

    /// Lädt den Sig aus der SQLite-DB und rekonstruiert den Spatial-Index.
    pub fn load_sig(&self) -> Result<Sig> {
        let mut sig = Sig::new();

        // Inters laden
        let inter_rows = self.read_inter_rows()?;
        let mut max_id: u64 = 0;

        for row in &inter_rows {
            let meta: InterMeta = serde_json::from_str(&row.payload_json)?;
            max_id = max_id.max(meta.id.0);
            sig.add_inter(Box::new(GenericInter { meta }));
        }

        // next_id auf max_id + 1 vorspulen, damit neue Inters eindeutige IDs bekommen
        for _ in 0..max_id {
            sig.next_inter_id();
        }

        // Relations laden
        let relation_rows = self.read_relation_rows()?;
        for row in relation_rows {
            if let Some(relation) = decode_relation_row(&row) {
                sig.add_relation(relation);
            }
        }

        debug!(
            inters = sig.inter_count(),
            relations = sig.relation_count(),
            "load_sig complete"
        );
        Ok(sig)
    }

    // ── Op-Log ────────────────────────────────────────────────────────────────

    /// Schreibt eine neue Operation in das persistente Op-Log.
    ///
    /// Aktualisiert auch das in-memory `History`-Log.
    pub fn record_op(&mut self, kind: EditOperationKind, author: &str) -> Result<OperationId> {
        let timestamp = now_iso();
        let rowid = append_op(&self.conn, &kind, author, &timestamp)?;
        // In-memory History aktuell halten
        self.history.append(kind, author);
        Ok(OperationId(rowid as u64))
    }

    /// Liefert alle Op-Log-Einträge in chronologischer Reihenfolge.
    pub fn ops(&self) -> Result<Vec<(OperationId, EditOperationKind, String, String)>> {
        let raw = list_ops(&self.conn)?;
        Ok(raw
            .into_iter()
            .map(|(id, kind, ts, author)| (OperationId(id as u64), kind, ts, author))
            .collect())
    }

    /// Zählt Op-Log-Einträge (nützlich für Tests).
    pub fn op_count(&self) -> Result<i64> {
        count_ops(&self.conn)
    }

    // ── Snapshot ──────────────────────────────────────────────────────────────

    /// Speichert einen versionierten Snapshot des aktuellen Sig-State.
    ///
    /// Liest den aktuellen Stand aus SQLite und schreibt ihn als JSON-Blob
    /// in die snapshots-Tabelle.
    pub fn snapshot(&self, label: &str) -> Result<()> {
        let inter_rows = self.read_inter_rows()?;
        let relation_rows = self.read_relation_rows()?;

        let snap = SigSnapshot {
            inters: inter_rows,
            relations: relation_rows,
        };
        let sig_json = serde_json::to_string(&snap)?;

        let op_id: i64 = self
            .conn
            .query_row("SELECT COALESCE(MAX(id), 0) FROM ops", [], |row| row.get(0))?;

        let created_at = now_iso();
        self.conn.execute(
            "INSERT INTO snapshots (label, op_id, sig_json, created_at) VALUES (?1,?2,?3,?4)",
            rusqlite::params![label, op_id, sig_json, created_at],
        )?;

        debug!(%label, "snapshot created");
        Ok(())
    }

    /// Zählt Snapshots (nützlich für Tests).
    pub fn snapshot_count(&self) -> Result<i64> {
        let n: i64 =
            self.conn
                .query_row("SELECT COUNT(*) FROM snapshots", [], |row| row.get(0))?;
        Ok(n)
    }

    // ── Spatial-Queries ───────────────────────────────────────────────────────

    /// Liefert alle Inters, deren Bounding-Box das Rechteck (x,y,w,h) schneidet.
    ///
    /// Nutzt den im Speicher gehaltenen R*-Tree.
    pub fn inters_in_rect(&self, x: u32, y: u32, w: u32, h: u32) -> Vec<InterId> {
        query_rect(&self.spatial, x, y, w, h)
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    fn read_inter_rows(&self) -> Result<Vec<InterRow>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, kind, bbox_x, bbox_y, bbox_w, bbox_h, grade, contextual, \
             provenance, frozen, system_idx, staff_idx, measure_number, voice, payload_json \
             FROM inters ORDER BY id ASC",
        )?;

        let rows = stmt.query_map([], |row| {
            Ok(InterRow {
                id: row.get(0)?,
                kind: row.get(1)?,
                bbox_x: row.get(2)?,
                bbox_y: row.get(3)?,
                bbox_w: row.get(4)?,
                bbox_h: row.get(5)?,
                grade: row.get(6)?,
                contextual: row.get(7)?,
                provenance: row.get(8)?,
                frozen: {
                    let v: i32 = row.get(9)?;
                    v != 0
                },
                system_idx: row.get(10)?,
                staff_idx: row.get(11)?,
                measure_number: row.get(12)?,
                voice: row.get(13)?,
                payload_json: row.get(14)?,
            })
        })?;

        let mut result = Vec::new();
        for row in rows {
            result.push(row?);
        }
        Ok(result)
    }

    fn read_relation_rows(&self) -> Result<Vec<RelationRow>> {
        let mut stmt = self.conn.prepare(
            "SELECT from_id, to_id, kind, variant, impacts_json, cause, provenance, frozen \
             FROM relations ORDER BY id ASC",
        )?;

        let rows = stmt.query_map([], |row| {
            Ok(RelationRow {
                from_id: row.get(0)?,
                to_id: row.get(1)?,
                kind: row.get(2)?,
                variant: row.get(3)?,
                impacts_json: row.get(4)?,
                cause: row.get(5)?,
                provenance: row.get(6)?,
                frozen: {
                    let v: i32 = row.get(7)?;
                    v != 0
                },
            })
        })?;

        let mut result = Vec::new();
        for row in rows {
            result.push(row?);
        }
        Ok(result)
    }
}

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

fn decode_relation_row(row: &RelationRow) -> Option<Relation> {
    let from = InterId(row.from_id as u64);
    let to = InterId(row.to_id as u64);
    let kind: RelationKind = serde_json::from_str(&row.kind).ok()?;
    let provenance: Provenance = serde_json::from_str(&row.provenance).ok()?;

    let variant = match row.variant.as_str() {
        "support" => {
            let impacts: SupportImpacts =
                serde_json::from_str(row.impacts_json.as_deref()?).ok()?;
            RelationVariant::Support(impacts)
        }
        "exclusion" => {
            let cause: ExclusionCause =
                serde_json::from_str(row.cause.as_deref()?).ok()?;
            RelationVariant::Exclusion(cause)
        }
        _ => return None,
    };

    Some(Relation {
        kind,
        from,
        to,
        extra: Vec::new(),
        variant,
        provenance,
        frozen: row.frozen,
    })
}

fn now_iso() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    format!("ts:{}", secs)
}

// ── Fehlende Grade-Konvertierung ──────────────────────────────────────────────

fn _grade_from_f64(v: f64) -> Grade {
    Grade::new(v)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::Rect;
    use omr_sig::{
        grade::Grade,
        inter::{Inter, InterId, InterKind, InterMeta},
        relation::{ExclusionCause, Relation, RelationKind, SupportImpacts, SupportKind},
        EditOperationKind, Provenance, Sig,
    };

    // ── Hilfs-Inter für Tests ──────────────────────────────────────────────────

    #[derive(Debug)]
    struct TestInter {
        meta: InterMeta,
    }

    impl Inter for TestInter {
        fn meta(&self) -> &InterMeta {
            &self.meta
        }
        fn meta_mut(&mut self) -> &mut InterMeta {
            &mut self.meta
        }
        fn as_any(&self) -> &dyn std::any::Any {
            self
        }
        fn as_any_mut(&mut self) -> &mut dyn std::any::Any {
            self
        }
    }

    fn mk_inter(sig: &mut Sig, kind: InterKind, grade: f64, bounds: Rect) -> InterId {
        let id = sig.next_inter_id();
        let meta = InterMeta::new(id, kind, bounds, Grade::new(grade));
        sig.add_inter(Box::new(TestInter { meta }))
    }

    fn rect(x: u32, y: u32, w: u32, h: u32) -> Rect {
        Rect { x, y, w, h }
    }

    // ── Tests ──────────────────────────────────────────────────────────────────

    #[test]
    fn open_in_memory_works() {
        let store = SigStore::open_in_memory();
        assert!(store.is_ok(), "open_in_memory should succeed");
        let store = store.unwrap();
        assert_eq!(store.op_count().unwrap(), 0);
        assert_eq!(store.snapshot_count().unwrap(), 0);
    }

    #[test]
    fn save_and_load_roundtrip() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        let head_id = mk_inter(&mut sig, InterKind::Head, 0.9, rect(10, 20, 8, 8));
        let stem_id = mk_inter(&mut sig, InterKind::Stem, 0.8, rect(14, 10, 2, 30));
        let _bar_id = mk_inter(&mut sig, InterKind::Bar, 0.7, rect(100, 0, 2, 100));

        store.save_sig(&sig).unwrap();
        let loaded = store.load_sig().unwrap();

        assert_eq!(loaded.inter_count(), 3, "Anzahl Inters");
        let head = loaded.get(head_id).expect("Head found");
        assert_eq!(head.kind(), InterKind::Head);
        assert!((head.grade().value() - 0.9).abs() < 1e-9, "Head grade");

        let stem = loaded.get(stem_id).expect("Stem found");
        assert_eq!(stem.kind(), InterKind::Stem);
        assert!((stem.grade().value() - 0.8).abs() < 1e-9, "Stem grade");
    }

    #[test]
    fn frozen_inters_persist() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        let id = {
            let inter_id = sig.next_inter_id();
            let meta = InterMeta::new(inter_id, InterKind::Head, rect(0, 0, 5, 5), Grade::new(0.6))
                .freeze();
            sig.add_inter(Box::new(TestInter { meta }));
            inter_id
        };

        store.save_sig(&sig).unwrap();
        let loaded = store.load_sig().unwrap();

        let inter = loaded.get(id).expect("inter exists after load");
        assert!(inter.is_frozen(), "frozen flag survives roundtrip");
        assert_eq!(inter.meta().provenance, Provenance::User);
    }

    #[test]
    fn relations_persist() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        let head = mk_inter(&mut sig, InterKind::Head, 0.9, rect(10, 20, 8, 8));
        let stem = mk_inter(&mut sig, InterKind::Stem, 0.8, rect(14, 10, 2, 30));
        sig.add_relation(Relation::support(
            RelationKind::HeadStem,
            head,
            stem,
            SupportImpacts::symmetric(2.0, SupportKind::Geometric),
        ));
        let weak = mk_inter(&mut sig, InterKind::Head, 0.3, rect(10, 20, 8, 8));
        sig.add_relation(Relation::exclusion(
            RelationKind::HeadStem,
            head,
            weak,
            ExclusionCause::BoundsOverlap,
        ));

        store.save_sig(&sig).unwrap();
        let loaded = store.load_sig().unwrap();

        assert_eq!(loaded.relation_count(), 2, "beide Relations persistiert");
        assert_eq!(loaded.support_partners(head), vec![stem], "support edge");
        assert!(
            loaded.exclusion_partners(head).contains(&weak),
            "exclusion edge"
        );
    }

    #[test]
    fn op_log_appends_and_reads() {
        let mut store = SigStore::open_in_memory().unwrap();

        let op1 = store
            .record_op(EditOperationKind::AddInter { id: InterId(1) }, "alice")
            .unwrap();
        let op2 = store
            .record_op(EditOperationKind::Freeze { id: InterId(1) }, "alice")
            .unwrap();
        let op3 = store
            .record_op(
                EditOperationKind::RemoveInter { id: InterId(1) },
                "bob",
            )
            .unwrap();

        assert!(op2 > op1, "IDs monoton steigend");
        assert!(op3 > op2, "IDs monoton steigend");
        assert_eq!(store.op_count().unwrap(), 3);

        let ops = store.ops().unwrap();
        assert_eq!(ops.len(), 3);
        assert_eq!(ops[1].3, "alice", "author korrekt");
        assert_eq!(ops[2].3, "bob", "author korrekt");
    }

    #[test]
    fn snapshot_creates_versioned_record() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        mk_inter(&mut sig, InterKind::Head, 0.9, rect(0, 0, 8, 8));
        store.save_sig(&sig).unwrap();
        store
            .record_op(EditOperationKind::AddInter { id: InterId(1) }, "system")
            .unwrap();

        store.snapshot("after-detect").unwrap();
        assert_eq!(store.snapshot_count().unwrap(), 1);

        // Zweiter Snapshot
        store.snapshot("final").unwrap();
        assert_eq!(store.snapshot_count().unwrap(), 2);
    }

    #[test]
    fn spatial_query_finds_inters_in_region() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        mk_inter(&mut sig, InterKind::Head, 0.9, rect(10, 10, 20, 20)); // in region
        mk_inter(&mut sig, InterKind::Stem, 0.8, rect(50, 50, 5, 30));  // out of region

        store.save_sig(&sig).unwrap();

        // Query: [5,5] .. [35,35] — overlaps mit dem Head-Inter bei (10,10,20,20)
        let found = store.inters_in_rect(5, 5, 30, 30);
        assert_eq!(found.len(), 1, "genau 1 Inter in der Region");
    }

    #[test]
    fn spatial_query_excludes_outside() {
        let mut store = SigStore::open_in_memory().unwrap();

        let mut sig = Sig::new();
        // Alle Inters weit weg von der Suchregion
        mk_inter(&mut sig, InterKind::Head, 0.9, rect(200, 200, 20, 20));
        mk_inter(&mut sig, InterKind::Stem, 0.8, rect(300, 300, 5, 30));

        store.save_sig(&sig).unwrap();

        // Query weit weg von den Inters
        let found = store.inters_in_rect(0, 0, 10, 10);
        assert_eq!(found.len(), 0, "keine Inters in leerer Region");
    }
}

