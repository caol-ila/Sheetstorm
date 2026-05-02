//! # omr-sig — Symbol Interpretation Graph
//!
//! Multi-Hypothesen-Architektur für OMR (Optical Music Recognition).
//!
//! ## Idee
//! Klassische OMR-Pipelines treffen früh harte Entscheidungen ("dies ist
//! ein Notenkopf, jenes nicht"). Bei mehrdeutigen Bildern verlieren wir
//! dadurch wichtige Alternativen.
//!
//! Das **Symbol Interpretation Graph (SIG)** modelliert stattdessen jede
//! mögliche Interpretation als Knoten (`Inter`) und Beziehungen als Kanten
//! (`Relation`). Konflikte (`Exclusion`) und Unterstützungen (`Support`)
//! erlauben **iteratives Auflösen** zur konsistentesten Hypothese-Menge.
//!
//! ## Inspiriert von Audiveris
//! Audiveris (Java, https://github.com/Audiveris/audiveris) hat das SIG-
//! Konzept eingeführt. Diese Crate baut die Idee in Rust nach und erweitert
//! sie um:
//! - **User-Provenance & Frozen-Inters** — User-bestätigte Interpretationen
//!   überleben Re-Detection
//! - **Probabilistic Grades** — Inter trägt Wahrscheinlichkeitsverteilungen
//!   statt single Score
//! - **Music-Theory-Relations** — Key/Voice-Leading/Phrase als Edges
//! - **Edit-History** — alle Modifikationen sind Operations für Undo/Redo
//! - **Cross-Document-Relations** — gleiche Stimme mehrfach hochgeladen
//!
//! ## Module
//! - [`inter`] — `Inter` Trait + konkrete Interpretation-Typen
//! - [`relation`] — `Relation` Enum (Exclusion + Support + diverse Sub-Typen)
//! - [`grade`] — `GradeImpacts` (gewichtetes geometrisches Mittel) + Contextual
//! - [`sig`] — `Sig` Hauptstruktur mit Graph-Operationen
//! - [`reducer`] — `reduce()` Fixpunkt-Loop für Konflikt-Auflösung
//! - [`history`] — Operation-Log für Undo/Redo
//! - [`spatial`] — R*-Tree-Index für räumliche Queries
//!
//! ## Status
//! **Iteration 1**: Foundation (Inter trait, Relation enum, Sig struct,
//! contextualize+reduce). Migration der bestehenden Detektoren erfolgt in
//! folgenden Iterationen.

#![warn(missing_docs)]

pub mod builder;
pub mod grade;
pub mod history;
pub mod inter;
pub mod inters;
pub mod music_theory;
pub mod relation;
pub mod sig;

pub use builder::SigBuilder;
pub use grade::{contextual_grade, Grade, GradeImpacts};
pub use history::{EditOperation, EditOperationKind, History, OperationId};
pub use inter::{Inter, InterId, InterKind, InterMeta, Provenance};
pub use inters::{
    AlterInter, BarInter, BeamInter, ClefInter, ClefType, HeadInter, KeySignatureInter,
    LedgerInter, RestInter, SlurInter, StemInter, TimeSignatureInter,
};
pub use music_theory::{
    add_key_consistency_edges, add_measure_budget_edges, diatonic_pitches, is_diatonic,
};
pub use relation::{ExclusionCause, Relation, RelationKind, SupportImpacts, SupportKind};
pub use sig::{ReduceReport, Sig};
