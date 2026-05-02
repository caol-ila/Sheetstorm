//! Inter (Interpretation) — ein Knoten im Symbol Interpretation Graph.
//!
//! Jeder Detektor (Templates, Stems, Beams, ...) erzeugt `Inter`-Instanzen
//! und fügt sie dem `Sig` hinzu. Inters können später durch `reduce()`
//! gelöscht werden, wenn Mutual-Exclusion sie überflüssig macht.

use omr_core::Rect;
use serde::{Deserialize, Serialize};

use crate::grade::Grade;

/// Stabile ID eines `Inter` im SIG. Wird beim `add_inter()` vergeben.
///
/// IDs sind monoton wachsend pro `Sig`-Instanz und werden NICHT wiederverwendet
/// (auch nach `remove_inter`). So bleiben Edit-History-Einträge nach
/// Remove+Re-Add eindeutig auflösbar.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(transparent)]
pub struct InterId(pub u64);

impl std::fmt::Display for InterId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "I#{}", self.0)
    }
}

/// Klassifikation eines `Inter` — was repräsentiert er musikalisch?
///
/// Diese Liste wird mit jedem migriertem Detektor erweitert. Ungenutzte
/// Varianten kommen später dazu (z.B. `LyricSyllable`, `ChordName`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum InterKind {
    /// Notenkopf — Filled, Open oder Whole.
    Head,
    /// Stem (vertikaler Strich).
    Stem,
    /// Beam (Balken-Verbindung zwischen Stems).
    Beam,
    /// Flag (Fähnchen am Stem-Ende für isolierte Achtel/16tel).
    Flag,
    /// Slur (Bogen über mehrere Notes).
    Slur,
    /// Tie (Bogen zwischen zwei gleichen Notes).
    Tie,
    /// Notenpause (Quarter-Rest, Eighth-Rest, Whole-Rest, ...).
    Rest,
    /// Notenschlüssel (Treble, Bass, Alto, ...).
    Clef,
    /// Vorzeichen (Sharp, Flat, Natural, Double-Sharp/Flat).
    Alter,
    /// Tonart (Folge von Vorzeichen am Zeilenanfang).
    KeySignature,
    /// Taktangabe (4/4, 3/4, ...).
    TimeSignature,
    /// Taktstrich.
    Bar,
    /// Doppelter Taktstrich.
    BarDouble,
    /// Wiederholungsstart (||:).
    RepeatStart,
    /// Wiederholungsende (:||).
    RepeatEnd,
    /// Volta-Klammer (1./2. Wiederholung).
    Volta,
    /// Punktierung.
    AugmentationDot,
    /// Hilfslinie.
    Ledger,
    /// Triolen-Marker (3-er Gruppe).
    Tuplet,
    /// Dynamik-Marker (p, mf, f, ff, ...).
    Dynamic,
    /// Tempo-Anweisung ("Allegro", "♩=120", ...).
    Tempo,
    /// Articulation (Staccato, Accent, Tenuto, ...).
    Articulation,
    /// Sprungmarke (Coda, Segno, Fine, D.S., D.C.).
    JumpMark,
    /// Allgemeiner Text (Lyrics, Title, PartName).
    Text,
}

/// Herkunft einer Interpretation — wer hat sie erzeugt?
///
/// Wichtig für User-Workflow: User-bestätigte Inters überleben jede
/// Re-Detection (`frozen=true`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Provenance {
    /// Klassischer Detektor (Templates, Connected-Components, ...).
    Detector,
    /// Vom CNN/HoG+SVM-Klassifier vorgeschlagen.
    MlClassifier,
    /// Repair-Algorithmus (Plausibility, Beat-Mismatch-Fix).
    Repair,
    /// Vom User manuell hinzugefügt oder modifiziert.
    User,
    /// Aus dem Edit-Log replayed (z.B. nach Re-Detection).
    History,
}

/// Metadaten, die JEDER `Inter` mitbringt — unabhängig von seiner Kind.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InterMeta {
    /// Stabile ID, vergeben bei `Sig::add_inter`.
    pub id: InterId,
    /// Welche Art von Symbol ist das?
    pub kind: InterKind,
    /// Bounding-Box im Original-Bild (post-deskew, pre-rotation).
    pub bounds: Rect,
    /// Intrinsic Grade — Detektor-eigener Score, in [0.0, 1.0].
    pub grade: Grade,
    /// Aktueller Contextual Grade — wird von `Sig::contextualize` neu berechnet.
    /// `None` bedeutet "noch nicht berechnet".
    pub contextual: Option<Grade>,
    /// Wer hat diese Interpretation erzeugt?
    pub provenance: Provenance,
    /// Wenn `true`: User hat bestätigt, überlebt jede `reduce()`.
    pub frozen: bool,
    /// Welches StaffSystem (Zeile) im Sheet? `None` für überstaff-Symbole.
    pub system_idx: Option<u32>,
    /// Welches Staff (innerhalb eines Systems, für Klavier-Grand-Staff)?
    pub staff_idx: Option<u32>,
    /// Welcher Takt (1-basiert, post-detection)? `None` wenn nicht zugeordnet.
    pub measure_number: Option<u32>,
    /// Welche Stimme (1-basiert)? `None` wenn nicht zugeordnet.
    pub voice: Option<u8>,
}

impl InterMeta {
    /// Erstellt neue Metadaten für einen Detektor-erzeugten Inter.
    pub fn new(id: InterId, kind: InterKind, bounds: Rect, grade: Grade) -> Self {
        Self {
            id,
            kind,
            bounds,
            grade,
            contextual: None,
            provenance: Provenance::Detector,
            frozen: false,
            system_idx: None,
            staff_idx: None,
            measure_number: None,
            voice: None,
        }
    }

    /// Markiert diesen Inter als User-bestätigt.
    pub fn freeze(mut self) -> Self {
        self.frozen = true;
        self.provenance = Provenance::User;
        self
    }
}

/// Trait für alle Interpretation-Typen.
///
/// Konkrete Inters wie `HeadInter`, `StemInter`, ... implementieren dieses
/// Trait und tragen typ-spezifische Daten (z.B. Pitch bei Head, x-Position
/// bei Stem). Über das Trait kann `Sig` einheitlich auf Metadaten zugreifen.
///
/// Erweiterung von `Any` erlaubt sicheres Downcasten zu konkreten Typen,
/// was für typed-Lookup-Operationen wie `sig.head_inters()` notwendig ist.
pub trait Inter: std::fmt::Debug + Send + Sync + std::any::Any {
    /// Gemeinsame Metadaten.
    fn meta(&self) -> &InterMeta;
    /// Mutable Zugriff auf Metadaten (für `set_contextual`, `freeze`).
    fn meta_mut(&mut self) -> &mut InterMeta;
    /// Downcast-Zugriff für typed accessors.
    fn as_any(&self) -> &dyn std::any::Any;
    /// Mutable Downcast-Zugriff.
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any;

    /// Convenience: ID.
    fn id(&self) -> InterId {
        self.meta().id
    }
    /// Convenience: Kind.
    fn kind(&self) -> InterKind {
        self.meta().kind
    }
    /// Convenience: Bounds.
    fn bounds(&self) -> Rect {
        self.meta().bounds
    }
    /// Convenience: intrinsic grade.
    fn grade(&self) -> Grade {
        self.meta().grade
    }
    /// Convenience: contextual grade falls berechnet, sonst intrinsic.
    fn effective_grade(&self) -> Grade {
        self.meta().contextual.unwrap_or(self.meta().grade)
    }
    /// Convenience: ist user-bestätigt?
    fn is_frozen(&self) -> bool {
        self.meta().frozen
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::Rect;

    #[derive(Debug)]
    struct DummyInter {
        meta: InterMeta,
    }
    impl Inter for DummyInter {
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

    #[test]
    fn meta_freezing_sets_provenance_user() {
        let bounds = Rect { x: 10, y: 20, w: 8, h: 8 };
        let meta = InterMeta::new(InterId(1), InterKind::Head, bounds, Grade::new(0.8));
        let frozen = meta.freeze();
        assert!(frozen.frozen);
        assert_eq!(frozen.provenance, Provenance::User);
    }

    #[test]
    fn effective_grade_uses_contextual_when_set() {
        let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
        let mut meta = InterMeta::new(InterId(1), InterKind::Head, bounds, Grade::new(0.5));
        meta.contextual = Some(Grade::new(0.9));
        let inter = DummyInter { meta };
        assert!((inter.effective_grade().value() - 0.9).abs() < 1e-6);
    }
}
