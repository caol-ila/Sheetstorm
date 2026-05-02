//! `Sig` — der Symbol Interpretation Graph.
//!
//! Verwaltet alle `Inter`s und `Relation`s. Bietet:
//! - `add_inter()`, `remove_inter()`, `get()`, `get_mut()`
//! - `add_relation()`, `remove_relation()`
//! - `contextualize()` — berechnet Contextual Grade für alle Inters
//! - `reduce()` — Fixpunkt-Loop zum Auflösen von Mutual-Exclusion-Konflikten
//! - `query()` — Graph-Queries (filter by kind, system, measure, ...)
//!
//! Verwendet intern `petgraph::stable_graph::StableGraph` mit `InterId` als
//! Knoten-Daten und `Relation` als Kanten-Daten.

use crate::grade::{contextual_grade, Grade};
use crate::inter::{Inter, InterId, InterKind};
use crate::relation::{Relation, RelationKind, RelationVariant};
use petgraph::graph::EdgeIndex;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::Direction;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::debug;

/// Ergebnis eines `reduce()`-Aufrufs — wer wurde gelöscht, wer geschwächt.
#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct ReduceReport {
    /// IDs gelöschter Inters.
    pub removed_inters: Vec<InterId>,
    /// IDs gelöschter Relations.
    pub removed_relations: Vec<EdgeIndexSerde>,
    /// Anzahl Fixpunkt-Iterationen.
    pub iterations: u32,
}

/// Serializable wrapper für petgraph EdgeIndex.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(transparent)]
pub struct EdgeIndexSerde(pub usize);

/// Hauptstruktur für den Symbol Interpretation Graph.
pub struct Sig {
    /// Petgraph-StableGraph: `NodeIndex` → InterId, `EdgeIndex` → Relation.
    graph: StableDiGraph<InterId, Relation>,
    /// Inter-Storage: InterId → Box<dyn Inter>.
    inters: HashMap<InterId, Box<dyn Inter>>,
    /// Reverse-Lookup: InterId → NodeIndex.
    node_for_id: HashMap<InterId, NodeIndex>,
    /// Nächste freie InterId.
    next_id: u64,
    /// Default-Threshold für `reduce()` — Inters unter diesem Grade werden gelöscht.
    pub min_grade_threshold: f64,
}

impl Default for Sig {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Debug for Sig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Sig")
            .field("inters", &self.inters.len())
            .field("relations", &self.graph.edge_count())
            .field("min_grade_threshold", &self.min_grade_threshold)
            .finish()
    }
}

impl Sig {
    /// Erstellt einen leeren SIG.
    pub fn new() -> Self {
        Self {
            graph: StableDiGraph::new(),
            inters: HashMap::new(),
            node_for_id: HashMap::new(),
            next_id: 1,
            min_grade_threshold: 0.20, // Audiveris-default
        }
    }

    /// Vergebene Inter-Anzahl.
    pub fn inter_count(&self) -> usize {
        self.inters.len()
    }

    /// Vergebene Relation-Anzahl.
    pub fn relation_count(&self) -> usize {
        self.graph.edge_count()
    }

    /// Erzeugt eine neue, monoton steigende `InterId`.
    pub fn next_inter_id(&mut self) -> InterId {
        let id = InterId(self.next_id);
        self.next_id += 1;
        id
    }

    /// Fügt einen `Inter` hinzu. Übergibt eine Box<dyn Inter> mit bereits
    /// gesetzter `InterId` (per `next_inter_id()`).
    ///
    /// Panics wenn die ID bereits vergeben ist.
    pub fn add_inter(&mut self, inter: Box<dyn Inter>) -> InterId {
        let id = inter.id();
        assert!(
            !self.inters.contains_key(&id),
            "InterId {} already in SIG",
            id
        );
        let node_idx = self.graph.add_node(id);
        self.node_for_id.insert(id, node_idx);
        self.inters.insert(id, inter);
        id
    }

    /// Liefert immutable-Reference zum Inter.
    pub fn get(&self, id: InterId) -> Option<&dyn Inter> {
        self.inters.get(&id).map(|b| b.as_ref())
    }

    /// Liefert mutable-Reference zum Inter.
    pub fn get_mut(&mut self, id: InterId) -> Option<&mut Box<dyn Inter>> {
        self.inters.get_mut(&id)
    }

    /// Entfernt Inter und alle eingehenden/ausgehenden Relations.
    /// Frozen-Inters können nur per `force=true` entfernt werden.
    pub fn remove_inter(&mut self, id: InterId, force: bool) -> Option<Box<dyn Inter>> {
        let frozen = self.get(id).map(|i| i.is_frozen()).unwrap_or(false);
        if frozen && !force {
            return None;
        }
        let node_idx = self.node_for_id.remove(&id)?;
        self.graph.remove_node(node_idx);
        self.inters.remove(&id)
    }

    /// Fügt eine `Relation` hinzu. Beide Endpunkte müssen im SIG existieren.
    pub fn add_relation(&mut self, relation: Relation) -> Option<EdgeIndex> {
        let from_node = *self.node_for_id.get(&relation.from)?;
        let to_node = *self.node_for_id.get(&relation.to)?;
        Some(self.graph.add_edge(from_node, to_node, relation))
    }

    /// Iterator über alle `Inter`s.
    pub fn inters(&self) -> impl Iterator<Item = &dyn Inter> + '_ {
        self.inters.values().map(|b| b.as_ref())
    }

    /// Iterator über alle `Inter`s einer bestimmten `InterKind`.
    pub fn inters_of_kind(&self, kind: InterKind) -> impl Iterator<Item = &dyn Inter> + '_ {
        self.inters().filter(move |i| i.kind() == kind)
    }

    /// Typed-Iterator: alle Inters die zu konkretem Typ `T` downcast-bar sind.
    /// Erlaubt typed Field-Access (z.B. midi, pitch, duration bei HeadInter).
    pub fn typed_inters<T: 'static>(&self) -> impl Iterator<Item = &T> + '_ {
        self.inters().filter_map(|i| i.as_any().downcast_ref::<T>())
    }

    /// Liefert ein konkretes typisiertes Inter via Downcast.
    pub fn get_typed<T: 'static>(&self, id: InterId) -> Option<&T> {
        self.get(id).and_then(|i| i.as_any().downcast_ref::<T>())
    }

    /// Iterator über alle `Relation`s.
    pub fn relations(&self) -> impl Iterator<Item = &Relation> + '_ {
        self.graph.edge_indices().filter_map(move |e| self.graph.edge_weight(e))
    }

    /// Iterator über Relationen eines spezifischen Kinds.
    pub fn relations_of_kind(&self, kind: RelationKind) -> impl Iterator<Item = &Relation> + '_ {
        self.relations().filter(move |r| r.kind == kind)
    }

    /// Wer ist mit diesem Inter über Support-Edges verbunden? Liefert Partner-IDs.
    pub fn support_partners(&self, id: InterId) -> Vec<InterId> {
        let Some(&node) = self.node_for_id.get(&id) else { return Vec::new(); };
        let mut out = Vec::new();
        for dir in [Direction::Outgoing, Direction::Incoming] {
            for e in self.graph.edges_directed(node, dir) {
                let r = e.weight();
                if !r.is_support() {
                    continue;
                }
                let partner_id = if r.from == id { r.to } else { r.from };
                if !out.contains(&partner_id) {
                    out.push(partner_id);
                }
            }
        }
        out
    }

    /// Wer steht mit diesem Inter im Mutual-Exclusion-Konflikt?
    pub fn exclusion_partners(&self, id: InterId) -> Vec<InterId> {
        let Some(&node) = self.node_for_id.get(&id) else { return Vec::new(); };
        let mut out = Vec::new();
        for dir in [Direction::Outgoing, Direction::Incoming] {
            for e in self.graph.edges_directed(node, dir) {
                let r = e.weight();
                if !r.is_exclusion() {
                    continue;
                }
                let partner_id = if r.from == id { r.to } else { r.from };
                if !out.contains(&partner_id) {
                    out.push(partner_id);
                }
            }
        }
        out
    }

    /// Berechnet den Contextual Grade für jeden Inter.
    ///
    /// Audiveris-Formel:
    /// `contribution = Σ partner.grade · (target_ratio - 1.0)` über alle
    /// Support-Edges
    /// `cg = (1 + contribution) · g / (1 + contribution · g)`
    ///
    /// Mutual-Exclusion-Partner werden NICHT als Beiträger gezählt (best-of-partition).
    pub fn contextualize(&mut self) {
        let mut new_cg: HashMap<InterId, Grade> = HashMap::new();
        // Snapshot der intrinsics und Edges um borrow conflicts zu vermeiden
        let inter_ids: Vec<InterId> = self.inters.keys().copied().collect();
        for id in inter_ids {
            let intrinsic = self.get(id).map(|i| i.grade()).unwrap_or(Grade::unknown());
            let node = match self.node_for_id.get(&id) {
                Some(n) => *n,
                None => continue,
            };
            let mut contribution = 0.0;
            for dir in [Direction::Outgoing, Direction::Incoming] {
                for e in self.graph.edges_directed(node, dir) {
                    let r = e.weight();
                    let RelationVariant::Support(impacts) = &r.variant else {
                        continue;
                    };
                    // Direction matters: target_ratio gilt FÜR den Empfänger
                    let (partner_id, ratio) = if r.from == id {
                        (r.to, impacts.source_ratio)
                    } else {
                        (r.from, impacts.target_ratio)
                    };
                    let partner_g = self.get(partner_id).map(|i| i.grade().value()).unwrap_or(0.0);
                    contribution += partner_g * (ratio - 1.0).max(0.0);
                }
            }
            let cg = contextual_grade(intrinsic, contribution);
            new_cg.insert(id, cg);
        }
        // Apply
        for (id, cg) in new_cg {
            if let Some(inter) = self.inters.get_mut(&id) {
                inter.meta_mut().contextual = Some(cg);
            }
        }
    }

    /// Greedy-Konflikt-Auflösung wie Audiveris `SigReducer`.
    ///
    /// Algorithmus (vereinfacht):
    /// 1. `contextualize()` neu berechnen
    /// 2. Für jeden Mutual-Exclusion-Konflikt: behalte den Inter mit höherem
    ///    `effective_grade`, lösche den Verlierer (außer er ist `frozen`).
    /// 3. Lösche Inters mit `effective_grade < min_grade_threshold` (außer frozen).
    /// 4. Wiederhole bis Fixpunkt erreicht.
    ///
    /// Returns Report mit gelöschten IDs.
    pub fn reduce(&mut self) -> ReduceReport {
        let mut report = ReduceReport::default();
        let max_iterations = 50;
        for iter in 0..max_iterations {
            self.contextualize();
            let mut changed = false;

            // 1) Mutual-Exclusion-Resolver: pro Konfliktpaar Verlierer löschen.
            let mut to_remove: Vec<InterId> = Vec::new();
            let inter_ids: Vec<InterId> = self.inters.keys().copied().collect();
            for id in &inter_ids {
                let inter_grade = self.get(*id).map(|i| i.effective_grade().value()).unwrap_or(0.0);
                let inter_frozen = self.get(*id).map(|i| i.is_frozen()).unwrap_or(false);
                if to_remove.contains(id) {
                    continue;
                }
                for partner in self.exclusion_partners(*id) {
                    if to_remove.contains(&partner) {
                        continue;
                    }
                    let p_grade = self.get(partner).map(|i| i.effective_grade().value()).unwrap_or(0.0);
                    let p_frozen = self.get(partner).map(|i| i.is_frozen()).unwrap_or(false);
                    if inter_frozen && p_frozen {
                        // Beide frozen → kein Reduce, keep both (Audiveris-Verhalten:
                        // User-Konflikt soll explizit gemeldet werden, nicht automatisch
                        // aufgelöst). Hier akzeptieren wir den Zustand.
                        continue;
                    }
                    if inter_frozen {
                        to_remove.push(partner);
                        continue;
                    }
                    if p_frozen {
                        to_remove.push(*id);
                        break;
                    }
                    // Beide nicht-frozen: behalte den mit höherem effective_grade.
                    if inter_grade < p_grade {
                        to_remove.push(*id);
                        break;
                    } else if p_grade < inter_grade {
                        to_remove.push(partner);
                    }
                    // Bei Gleichstand: behalte beide (stabiles Verhalten).
                }
            }
            for id in &to_remove {
                if self.remove_inter(*id, false).is_some() {
                    report.removed_inters.push(*id);
                    changed = true;
                }
            }

            // 2) Threshold-Filter (für nicht-frozen Inters).
            let mut threshold_kills: Vec<InterId> = Vec::new();
            for id in self.inters.keys().copied().collect::<Vec<_>>() {
                let inter = match self.get(id) {
                    Some(i) => i,
                    None => continue,
                };
                if inter.is_frozen() {
                    continue;
                }
                if inter.effective_grade().value() < self.min_grade_threshold {
                    threshold_kills.push(id);
                }
            }
            for id in &threshold_kills {
                if self.remove_inter(*id, false).is_some() {
                    report.removed_inters.push(*id);
                    changed = true;
                }
            }

            if !changed {
                report.iterations = iter + 1;
                debug!(iterations = iter + 1, "Sig::reduce reached fixpoint");
                return report;
            }
        }
        report.iterations = max_iterations;
        debug!("Sig::reduce hit max_iterations safety-cap");
        report
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::grade::Grade;
    use crate::inter::{Inter, InterId, InterKind, InterMeta};
    use crate::relation::{ExclusionCause, Relation, SupportImpacts, SupportKind};
    use omr_core::Rect;

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

    fn mk_inter(sig: &mut Sig, kind: InterKind, grade: f64) -> InterId {
        let id = sig.next_inter_id();
        let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
        let meta = InterMeta::new(id, kind, bounds, Grade::new(grade));
        sig.add_inter(Box::new(TestInter { meta }))
    }

    #[test]
    fn add_and_get_inter() {
        let mut sig = Sig::new();
        let id = mk_inter(&mut sig, InterKind::Head, 0.8);
        assert_eq!(sig.inter_count(), 1);
        let inter = sig.get(id).unwrap();
        assert_eq!(inter.kind(), InterKind::Head);
        assert!((inter.grade().value() - 0.8).abs() < 1e-9);
    }

    #[test]
    fn exclusion_kills_lower_grade() {
        let mut sig = Sig::new();
        let strong = mk_inter(&mut sig, InterKind::Head, 0.9);
        let weak = mk_inter(&mut sig, InterKind::Head, 0.4);
        sig.add_relation(Relation::exclusion(
            RelationKind::HeadStem,
            strong,
            weak,
            ExclusionCause::BoundsOverlap,
        ));
        let report = sig.reduce();
        assert!(report.removed_inters.contains(&weak));
        assert!(!report.removed_inters.contains(&strong));
        assert_eq!(sig.inter_count(), 1);
    }

    #[test]
    fn frozen_inter_survives_exclusion_against_higher_grade() {
        let mut sig = Sig::new();
        // Frozen weak inter
        let weak_id_holder = {
            let id = sig.next_inter_id();
            let bounds = Rect { x: 0, y: 0, w: 1, h: 1 };
            let mut meta = InterMeta::new(id, InterKind::Head, bounds, Grade::new(0.4));
            meta = meta.freeze();
            sig.add_inter(Box::new(TestInter { meta }));
            id
        };
        let strong = mk_inter(&mut sig, InterKind::Head, 0.9);
        sig.add_relation(Relation::exclusion(
            RelationKind::HeadStem,
            weak_id_holder,
            strong,
            ExclusionCause::BoundsOverlap,
        ));
        sig.reduce();
        // Frozen weak survives, strong gets killed
        assert!(sig.get(weak_id_holder).is_some());
        assert!(sig.get(strong).is_none());
    }

    #[test]
    fn support_raises_contextual_grade() {
        let mut sig = Sig::new();
        let head = mk_inter(&mut sig, InterKind::Head, 0.6);
        let stem = mk_inter(&mut sig, InterKind::Stem, 0.6);
        sig.add_relation(Relation::support(
            RelationKind::HeadStem,
            head,
            stem,
            SupportImpacts::symmetric(2.0, SupportKind::Geometric),
        ));
        sig.contextualize();
        let head_cg = sig.get(head).unwrap().effective_grade().value();
        // ohne support: 0.6, mit support sollte > 0.6 sein
        assert!(head_cg > 0.6, "contextual {} should exceed intrinsic 0.6", head_cg);
    }

    #[test]
    fn threshold_kills_weak_inter() {
        let mut sig = Sig::new();
        sig.min_grade_threshold = 0.50;
        let weak = mk_inter(&mut sig, InterKind::Head, 0.10);
        let strong = mk_inter(&mut sig, InterKind::Head, 0.85);
        sig.reduce();
        assert!(sig.get(weak).is_none());
        assert!(sig.get(strong).is_some());
    }
}
