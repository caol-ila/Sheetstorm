//! Operations-Log für Edit-History (Undo/Redo, Re-Detection-Replay, Audit).
//!
//! Jede Modifikation am `Sig` wird als `EditOperation` aufgezeichnet. Das
//! Log ist append-only und kann:
//! - Rückwärts angewendet werden (Undo)
//! - Auf einen leeren SIG repliziert werden (Determinism-Check)
//! - Persistiert werden (für Multi-Session Edits)
//! - In CRDT-Format gemappt werden (Multi-User-Collab)

use crate::inter::InterId;
use serde::{Deserialize, Serialize};

/// Stabile ID einer Operation im Log.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(transparent)]
pub struct OperationId(pub u64);

impl std::fmt::Display for OperationId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Op#{}", self.0)
    }
}

/// Was wurde gemacht?
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum EditOperationKind {
    /// Inter hinzugefügt.
    AddInter {
        /// ID des neuen Inters.
        id: InterId,
    },
    /// Inter entfernt.
    RemoveInter {
        /// ID des entfernten Inters.
        id: InterId,
    },
    /// Inter modifiziert (Grade, Bounds, Voice, ...).
    ModifyInter {
        /// ID des modifizierten Inters.
        id: InterId,
        /// Field-Name der geändert wurde (z.B. "grade", "bounds.x").
        field: String,
        /// JSON-Repräsentation des alten Werts.
        before: serde_json::Value,
        /// JSON-Repräsentation des neuen Werts.
        after: serde_json::Value,
    },
    /// Relation hinzugefügt.
    AddRelation {
        /// Quell-Inter.
        from: InterId,
        /// Ziel-Inter.
        to: InterId,
        /// Kind als Debug-String.
        kind: String,
    },
    /// Relation entfernt.
    RemoveRelation {
        /// Quell-Inter.
        from: InterId,
        /// Ziel-Inter.
        to: InterId,
        /// Kind als Debug-String.
        kind: String,
    },
    /// Inter gefroren (User-Bestätigung).
    Freeze {
        /// ID des Inters.
        id: InterId,
    },
    /// Inter aufgetaut (User entfernt Bestätigung).
    Unfreeze {
        /// ID des Inters.
        id: InterId,
    },
    /// Reduce-Pass durchgeführt.
    Reduce {
        /// Anzahl gelöschter Inters.
        n_removed: u32,
        /// Iterations bis Fixpunkt.
        iterations: u32,
    },
    /// Beginn einer Batch-Operation (für atomares Undo).
    BatchBegin {
        /// Optional: Beschreibung für UI.
        label: Option<String>,
    },
    /// Ende einer Batch-Operation.
    BatchEnd,
}

/// Ein einzelner Eintrag im Log.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EditOperation {
    /// Stabile ID.
    pub id: OperationId,
    /// Was wurde gemacht?
    pub kind: EditOperationKind,
    /// ISO-8601 Zeitstempel.
    pub timestamp: String,
    /// Author: User-Login oder "system" für Detector-Runs.
    pub author: String,
    /// Optional: Verweis auf vorhergehende Operation (für CRDT/branching).
    pub parent: Option<OperationId>,
}

/// Append-only Operations-Log.
///
/// Wird in der Praxis in einer SQLite-Tabelle persistiert. Diese In-Memory-
/// Struktur ist die Grundlage; persistente Persistenz folgt in einer
/// separaten Crate (`omr-sig-store`).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct History {
    /// Alle Operationen in chronologischer Reihenfolge.
    pub ops: Vec<EditOperation>,
    /// Nächste freie OperationId.
    pub next_id: u64,
}

impl History {
    /// Erstellt ein leeres Log.
    pub fn new() -> Self {
        Self {
            ops: Vec::new(),
            next_id: 1,
        }
    }

    /// Fügt eine neue Operation hinzu.
    pub fn append(&mut self, kind: EditOperationKind, author: impl Into<String>) -> OperationId {
        let id = OperationId(self.next_id);
        self.next_id += 1;
        let parent = self.ops.last().map(|o| o.id);
        let op = EditOperation {
            id,
            kind,
            timestamp: now_iso(),
            author: author.into(),
            parent,
        };
        self.ops.push(op);
        id
    }

    /// Anzahl Operationen.
    pub fn len(&self) -> usize {
        self.ops.len()
    }

    /// Ist das Log leer?
    pub fn is_empty(&self) -> bool {
        self.ops.is_empty()
    }
}

fn now_iso() -> String {
    // Minimal-Implementierung ohne `chrono`-Dep — reicht für Logging.
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Wir geben eine pseudo-ISO-Form zurück; volle Konformität wird im
    // omr-sig-store via `time` oder `chrono` nachgeholt.
    format!("ts:{}", secs)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn append_increments_id() {
        let mut h = History::new();
        let id1 = h.append(EditOperationKind::AddInter { id: InterId(1) }, "test");
        let id2 = h.append(EditOperationKind::AddInter { id: InterId(2) }, "test");
        assert!(id2.0 > id1.0);
        assert_eq!(h.len(), 2);
    }

    #[test]
    fn parent_is_set_to_previous_op() {
        let mut h = History::new();
        let _ = h.append(EditOperationKind::AddInter { id: InterId(1) }, "a");
        let id2 = h.append(EditOperationKind::Freeze { id: InterId(1) }, "b");
        let op2 = h.ops.iter().find(|o| o.id == id2).unwrap();
        assert!(op2.parent.is_some());
    }
}
