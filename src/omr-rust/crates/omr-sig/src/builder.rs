//! `SigBuilder` — Konstruktion eines `Sig` aus den Outputs der bestehenden
//! Detektoren.
//!
//! Diese Crate ist die Bridge zwischen der bestehenden Pipeline (Notehead,
//! Stem, Beam, MeasureBar, ...) und der SIG-Architektur. Sie übersetzt
//! Detektor-Resultate in `Inter`-Knoten und fügt Support-/Exclusion-Edges
//! basierend auf geometrischen Heuristiken hinzu.
//!
//! Verwendung:
//! ```ignore
//! let mut sig = Sig::new();
//! let builder = SigBuilder::new(line_spacing);
//! builder
//!     .add_noteheads(&mut sig, &noteheads)
//!     .add_stems(&mut sig, &stems)
//!     .add_beams(&mut sig, &beams)
//!     .add_bars(&mut sig, &bars)
//!     .link_head_stem(&mut sig)
//!     .link_beam_stem(&mut sig);
//! sig.contextualize();
//! ```

use omr_core::{Notehead, Stem};

use crate::grade::Grade;
use crate::inter::{Inter, InterId, InterKind};
use crate::inters::{BarInter, BeamInter, HeadInter, StemInter};
use crate::relation::{Relation, RelationKind, SupportImpacts, SupportKind};
use crate::sig::Sig;

/// Builder zum Aufbau eines SIG aus Detektor-Resultaten.
pub struct SigBuilder {
    /// Erwartete Stafflinien-Distanz in Pixeln (für Geometrie-Toleranzen).
    pub line_spacing: f32,
    /// Maximaler X-Versatz Stem ↔ Head (in Pixeln).
    pub head_stem_max_dx: f32,
    /// Maximaler Beam ↔ Stem y-Distance (in Pixeln).
    pub beam_stem_max_dy: f32,

    // Internal: maps für linkup-step
    head_id_per_orig: Vec<InterId>,
    stem_id_per_orig: Vec<InterId>,
    beam_id_per_orig: Vec<InterId>,
}

impl SigBuilder {
    /// Erstellt einen neuen Builder mit Standard-Heuristiken.
    pub fn new(line_spacing: f32) -> Self {
        Self {
            line_spacing,
            head_stem_max_dx: line_spacing.max(8.0),
            beam_stem_max_dy: line_spacing * 0.6,
            head_id_per_orig: Vec::new(),
            stem_id_per_orig: Vec::new(),
            beam_id_per_orig: Vec::new(),
        }
    }

    /// Fügt alle Noteheads als `HeadInter` zum SIG hinzu. Behält den Index
    /// für spätere Linkup-Operationen.
    pub fn add_noteheads(mut self, sig: &mut Sig, noteheads: &[Notehead]) -> Self {
        self.head_id_per_orig.clear();
        for nh in noteheads {
            let id = sig.next_inter_id();
            let head = HeadInter::from_notehead(id, nh);
            self.head_id_per_orig.push(sig.add_inter(Box::new(head)));
        }
        self
    }

    /// Fügt alle Stems als `StemInter` hinzu. Stem-Confidence wird konstant
    /// auf 0.85 gesetzt, kann später per Detektor variiert werden.
    pub fn add_stems(mut self, sig: &mut Sig, stems: &[Stem]) -> Self {
        self.stem_id_per_orig.clear();
        for stem in stems {
            let id = sig.next_inter_id();
            let si = StemInter::from_stem(id, stem, Grade::new(0.85));
            self.stem_id_per_orig.push(sig.add_inter(Box::new(si)));
        }
        self
    }

    /// Fügt Beams als `BeamInter` hinzu. Erwartet (x_start, x_end, y_top, y_bot, level).
    pub fn add_beams(
        mut self,
        sig: &mut Sig,
        beams: &[(u32, u32, u32, u32, u8)],
    ) -> Self {
        self.beam_id_per_orig.clear();
        for &(x_start, x_end, y_top, y_bot, level) in beams {
            let id = sig.next_inter_id();
            let bi = BeamInter::new(id, x_start, x_end, y_top, y_bot, level, Grade::new(0.80));
            self.beam_id_per_orig.push(sig.add_inter(Box::new(bi)));
        }
        self
    }

    /// Fügt Taktstriche hinzu. Erwartet (x, system_idx).
    pub fn add_bars(self, sig: &mut Sig, bars: &[(u32, u32)]) -> Self {
        for &(x, system_idx) in bars {
            let id = sig.next_inter_id();
            let bi = BarInter::new(id, x, system_idx, Grade::new(0.90));
            sig.add_inter(Box::new(bi));
        }
        self
    }

    /// Fügt `HeadStem`-Support-Edges hinzu: für jedes Stem das nächst-passende
    /// NH (innerhalb `head_stem_max_dx`) wird verbunden.
    ///
    /// Audiveris-typischer Support-Multiplikator: 1.5 (Geometric).
    pub fn link_head_stem(self, sig: &mut Sig) -> Self {
        // Sammle Pairs (head_id, stem_id, distance) und nimm jeweils das beste.
        let mut pairs: Vec<(InterId, InterId, f32)> = Vec::new();
        let head_ids: Vec<(InterId, f32, f32, u32, u32)> = self
            .head_id_per_orig
            .iter()
            .filter_map(|&id| {
                let h = sig.get(id)?;
                if h.kind() != InterKind::Head { return None; }
                let bb = h.bounds();
                Some((id, bb.cx(), bb.cy(), bb.x, bb.y + bb.h))
            })
            .collect();

        for &stem_id in &self.stem_id_per_orig {
            let stem = match sig.get(stem_id) {
                Some(s) if s.kind() == InterKind::Stem => s,
                _ => continue,
            };
            let stem_bb = stem.bounds();
            let stem_cx = stem_bb.cx();
            // Find closest head whose center.x is near stem.x AND whose y-bbox
            // touches stem's y-range.
            let mut best: Option<(InterId, f32)> = None;
            for &(head_id, hcx, hcy, _hx, _hyb) in &head_ids {
                let dx = (hcx - stem_cx).abs();
                if dx > self.head_stem_max_dx {
                    continue;
                }
                // Y must overlap stem range (head between top and bot).
                if (hcy as u32) < stem_bb.y || (hcy as u32) > stem_bb.y + stem_bb.h {
                    continue;
                }
                if best.map(|(_, d)| dx < d).unwrap_or(true) {
                    best = Some((head_id, dx));
                }
            }
            if let Some((head_id, dist)) = best {
                pairs.push((head_id, stem_id, dist));
            }
        }
        for (head_id, stem_id, _) in pairs {
            sig.add_relation(Relation::support(
                RelationKind::HeadStem,
                head_id,
                stem_id,
                SupportImpacts::asymmetric(1.5, 1.5, SupportKind::Geometric),
            ));
        }
        self
    }

    /// Fügt `BeamStem`-Support-Edges hinzu: jedes Stem dessen Y-Range einen
    /// Beam überlappt UND dessen X im Beam-Bereich liegt → Edge.
    pub fn link_beam_stem(self, sig: &mut Sig) -> Self {
        let mut pairs: Vec<(InterId, InterId)> = Vec::new();
        let beams: Vec<(InterId, u32, u32, u32, u32)> = self
            .beam_id_per_orig
            .iter()
            .filter_map(|&id| {
                let b = sig.get(id)?;
                if b.kind() != InterKind::Beam { return None; }
                let bb = b.bounds();
                Some((id, bb.x, bb.x + bb.w, bb.y, bb.y + bb.h))
            })
            .collect();

        for &stem_id in &self.stem_id_per_orig {
            let stem = match sig.get(stem_id) {
                Some(s) if s.kind() == InterKind::Stem => s,
                _ => continue,
            };
            let stem_bb = stem.bounds();
            let sx = (stem_bb.cx()) as u32;
            for &(beam_id, x_start, x_end, y_top, y_bot) in &beams {
                if sx < x_start || sx > x_end {
                    continue;
                }
                // Beam-Y-Range muss innerhalb Stem-Y-Range liegen.
                let stem_top = stem_bb.y;
                let stem_bot = stem_bb.y + stem_bb.h;
                let beam_in_stem = y_top >= stem_top.saturating_sub(2)
                    && y_bot <= stem_bot.saturating_add(2);
                if beam_in_stem {
                    pairs.push((beam_id, stem_id));
                }
            }
        }
        for (beam_id, stem_id) in pairs {
            sig.add_relation(Relation::support(
                RelationKind::BeamStem,
                beam_id,
                stem_id,
                SupportImpacts::symmetric(1.4, SupportKind::Geometric),
            ));
        }
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{Notehead, NoteheadKind, Point, Rect, Stem};

    fn make_nh(x: u32, y: u32, conf: f32) -> Notehead {
        Notehead {
            bbox: Rect { x, y, w: 8, h: 6 },
            center: Point { x: x as f32 + 4.0, y: y as f32 + 3.0 },
            confidence: conf,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        }
    }

    #[test]
    fn builder_adds_head_inters() {
        let mut sig = Sig::new();
        let nhs = vec![make_nh(10, 20, 0.9), make_nh(30, 20, 0.8)];
        let _ = SigBuilder::new(10.0).add_noteheads(&mut sig, &nhs);
        assert_eq!(sig.inter_count(), 2);
        let heads: Vec<_> = sig.inters_of_kind(InterKind::Head).collect();
        assert_eq!(heads.len(), 2);
    }

    #[test]
    fn link_head_stem_creates_support_edge() {
        let mut sig = Sig::new();
        // NH at (10,20) with bbox 10..18 / 20..26 — center (14, 23)
        // Stem at x=14, y_top=10, y_bot=30 — covers NH y-range
        let nhs = vec![make_nh(10, 20, 0.9)];
        let stems = vec![Stem { x: 14, y_top: 10, y_bot: 30, notehead_idx: None }];
        let _ = SigBuilder::new(10.0)
            .add_noteheads(&mut sig, &nhs)
            .add_stems(&mut sig, &stems)
            .link_head_stem(&mut sig);
        let head_stem_rels: Vec<_> = sig.relations_of_kind(RelationKind::HeadStem).collect();
        assert_eq!(head_stem_rels.len(), 1);
        assert!(head_stem_rels[0].is_support());
    }

    #[test]
    fn link_head_stem_skips_distant_pairs() {
        let mut sig = Sig::new();
        // NH at (10, 20) center (14, 23)
        // Stem far away at x=200 — should NOT link
        let nhs = vec![make_nh(10, 20, 0.9)];
        let stems = vec![Stem { x: 200, y_top: 10, y_bot: 30, notehead_idx: None }];
        let _ = SigBuilder::new(10.0)
            .add_noteheads(&mut sig, &nhs)
            .add_stems(&mut sig, &stems)
            .link_head_stem(&mut sig);
        let head_stem_rels: Vec<_> = sig.relations_of_kind(RelationKind::HeadStem).collect();
        assert_eq!(head_stem_rels.len(), 0);
    }

    #[test]
    fn link_beam_stem_creates_edges() {
        let mut sig = Sig::new();
        // Two stems at x=20 and x=40, both running y=5..40
        let stems = vec![
            Stem { x: 20, y_top: 5, y_bot: 40, notehead_idx: None },
            Stem { x: 40, y_top: 5, y_bot: 40, notehead_idx: None },
        ];
        // Beam from x=15 to x=45, y=10..14 (within stems' y-range)
        let beams = vec![(15u32, 45u32, 10u32, 14u32, 1u8)];
        let _ = SigBuilder::new(10.0)
            .add_stems(&mut sig, &stems)
            .add_beams(&mut sig, &beams)
            .link_beam_stem(&mut sig);
        let bs_rels: Vec<_> = sig.relations_of_kind(RelationKind::BeamStem).collect();
        assert_eq!(bs_rels.len(), 2);
    }

    #[test]
    fn contextualize_after_build_raises_grades() {
        let mut sig = Sig::new();
        let nhs = vec![make_nh(10, 20, 0.7)];
        let stems = vec![Stem { x: 14, y_top: 10, y_bot: 30, notehead_idx: None }];
        let _ = SigBuilder::new(10.0)
            .add_noteheads(&mut sig, &nhs)
            .add_stems(&mut sig, &stems)
            .link_head_stem(&mut sig);
        sig.contextualize();
        // Head and stem both should have contextual grade > intrinsic
        for inter in sig.inters() {
            let i = inter.grade().value();
            let c = inter.effective_grade().value();
            assert!(c >= i, "contextual {} should be >= intrinsic {}", c, i);
        }
    }
}
