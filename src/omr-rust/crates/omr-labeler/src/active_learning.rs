//! Active-Learning-Queue.
//!
//! Items werden nach Unsicherheit (`uncertainty`, höher = wichtiger) in
//! eine Queue gelegt. `next()` liefert den höchst-unsicheren noch nicht
//! beantworteten Eintrag; `answer()` markiert ihn als bearbeitet und
//! verhindert Wiederholungen.
//!
//! Die Queue ist bewusst einfach gehalten: ein `VecDeque` plus ein
//! `HashSet<u64>` der bereits bearbeiteten IDs. Re-Prioritisierung
//! erfolgt durch Stabil-Sortieren nach Unsicherheit.

use serde::{Deserialize, Serialize};
use std::collections::{HashSet, VecDeque};

/// Welcher Aspekt eines Items wird gerade gelabelt.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Hash)]
#[serde(rename_all = "lowercase")]
pub enum Level {
    /// Ist dies eine zusammenhängende Notenzeile / ein StaffSystem?
    Line,
    /// Ist dies ein zu klassifizierendes Element (Notehead, Akzidens, …)?
    Element,
    /// Klassen-Zuordnung (mehrere Top-K-Klassen sind vorgeschlagen).
    Class,
}

/// Sortier-Reihenfolge der Levels in der Queue. Wir wollen, dass der
/// User erst ALLE Line-Items abarbeitet, dann ALLE Element-Items,
/// dann ALLE Class-Items — und nicht zwischendurch wechselt.
fn level_rank(l: Level) -> u8 {
    match l {
        Level::Line => 0,
        Level::Element => 1,
        Level::Class => 2,
    }
}

impl Level {
    pub fn as_str(&self) -> &'static str {
        match self {
            Level::Line => "line",
            Level::Element => "element",
            Level::Class => "class",
        }
    }
}

/// Ein Eintrag in der Labeling-Queue.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueueItem {
    pub id: u64,
    pub level: Level,
    pub uncertainty: f32,
    pub system_id: String,
    pub element_id: Option<String>,
    pub suggested_class: Option<String>,
    pub top_k: Vec<(String, f32)>,
}

/// Antwort des Annotators.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "kind", content = "value", rename_all = "lowercase")]
pub enum Decision {
    Yes,
    No,
    Skip,
    Class(String),
}

impl Decision {
    pub fn as_str(&self) -> String {
        match self {
            Decision::Yes => "yes".to_string(),
            Decision::No => "no".to_string(),
            Decision::Skip => "skip".to_string(),
            Decision::Class(c) => format!("class:{}", c),
        }
    }
}

/// Die Labeling-Queue.
#[derive(Debug, Default)]
pub struct LabelingQueue {
    pub items: VecDeque<QueueItem>,
    pub labeled: HashSet<u64>,
    pub labeled_count: usize,
    pub last_resort: usize,
    next_id: u64,
}

impl LabelingQueue {
    pub fn new() -> Self {
        Self::default()
    }

    /// Fügt ein neues Item hinzu und liefert dessen ID. Bei höherer
    /// Unsicherheit landet das Item weiter vorne nach dem nächsten
    /// `re_prioritize()`.
    pub fn push(
        &mut self,
        level: Level,
        system_id: String,
        element_id: Option<String>,
        uncertainty: f32,
    ) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.items.push_back(QueueItem {
            id,
            level,
            uncertainty,
            system_id,
            element_id,
            suggested_class: None,
            top_k: Vec::new(),
        });
        id
    }

    /// Fügt ein vorgefertigtes Item ein (z.B. aus dem synthetischen
    /// Warmup) und sorgt dafür, dass `next_id` immer monoton steigt.
    pub fn push_item(&mut self, mut item: QueueItem) -> u64 {
        if item.id == 0 || item.id < self.next_id {
            item.id = self.next_id;
        }
        self.next_id = item.id + 1;
        let id = item.id;
        self.items.push_back(item);
        id
    }

    /// Liefert das höchst-unsichere noch nicht beantwortete Item, ohne
    /// es zu entfernen. Items mit gesetzter `labeled`-Markierung werden
    /// übersprungen.
    pub fn next(&mut self) -> Option<&QueueItem> {
        // Aufräumen: entferne bereits bearbeitete Items am Anfang.
        while let Some(front) = self.items.front() {
            if self.labeled.contains(&front.id) {
                self.items.pop_front();
            } else {
                break;
            }
        }
        self.items.front()
    }

    /// Markiert ein Item als beantwortet.
    pub fn answer(&mut self, item_id: u64, _decision: Decision) {
        if self.labeled.insert(item_id) {
            self.labeled_count += 1;
            self.items.retain(|it| it.id != item_id);
        }
    }

    /// Markiert ein Item als übersprungen — es wird ans Ende der Queue
    /// verschoben und kann später erneut angeboten werden.
    pub fn skip(&mut self, item_id: u64) {
        self.last_resort += 1;
        if let Some(pos) = self.items.iter().position(|it| it.id == item_id) {
            if let Some(it) = self.items.remove(pos) {
                self.items.push_back(it);
            }
        }
    }

    /// Sortiert die Queue strikt nach Level (Line vor Element vor Class)
    /// und innerhalb eines Levels nach Unsicherheit absteigend.
    ///
    /// **Wichtig fuer die UX:** der User will nicht zwischen Frage-Typen
    /// hin- und herspringen ("Ist das eine Notenzeile?" vs "Was ist im
    /// roten Rahmen?"). Daher gruppieren wir strikt:
    ///   1. Alle line-Items (Notenzeile-Validierung)
    ///   2. Alle element-Items (Element-Validierung)
    ///   3. Alle class-Items (Klassifikation)
    pub fn re_prioritize(&mut self) {
        let mut v: Vec<QueueItem> = self.items.drain(..).collect();
        v.sort_by(|a, b| {
            level_rank(a.level)
                .cmp(&level_rank(b.level))
                .then_with(|| {
                    b.uncertainty
                        .partial_cmp(&a.uncertainty)
                        .unwrap_or(std::cmp::Ordering::Equal)
                })
        });
        self.items = v.into();
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn push_and_next() {
        let mut q = LabelingQueue::new();
        let id = q.push(Level::Line, "sys-1".into(), None, 0.5);
        let n = q.next().unwrap();
        assert_eq!(n.id, id);
    }

    #[test]
    fn re_prioritize_sorts_high_first() {
        let mut q = LabelingQueue::new();
        q.push(Level::Line, "a".into(), None, 0.1);
        q.push(Level::Line, "b".into(), None, 0.9);
        q.push(Level::Line, "c".into(), None, 0.5);
        q.re_prioritize();
        let n = q.next().unwrap();
        assert_eq!(n.system_id, "b");
    }

    #[test]
    fn answered_items_dont_repeat() {
        let mut q = LabelingQueue::new();
        let a = q.push(Level::Line, "a".into(), None, 0.1);
        let b = q.push(Level::Line, "b".into(), None, 0.9);
        q.answer(a, Decision::Yes);
        q.answer(b, Decision::No);
        assert!(q.next().is_none());
    }

    #[test]
    fn skip_moves_to_end() {
        let mut q = LabelingQueue::new();
        let a = q.push(Level::Line, "a".into(), None, 0.5);
        let b = q.push(Level::Line, "b".into(), None, 0.5);
        q.skip(a);
        let nxt = q.next().unwrap();
        assert_eq!(nxt.id, b);
    }

    #[test]
    fn re_prioritize_groups_by_level_first() {
        let mut q = LabelingQueue::new();
        // Mische Levels: zwei Class-Items mit hoher Unsicherheit, ein
        // Element-Item mit mittlerer, ein Line-Item mit niedriger.
        // Erwartung nach re_prioritize: Line zuerst, dann Element, dann Class —
        // unabhaengig von Unsicherheit.
        q.push(Level::Class, "c1".into(), Some("c1#e0".into()), 0.99);
        q.push(Level::Class, "c2".into(), Some("c2#e0".into()), 0.95);
        q.push(Level::Element, "e1".into(), Some("e1#e0".into()), 0.5);
        q.push(Level::Line, "l1".into(), None, 0.1);
        q.re_prioritize();
        let n1 = q.next().cloned().unwrap();
        assert_eq!(n1.level, Level::Line);
        // Item beantworten + zum naechsten gehen
        q.answer(n1.id, Decision::Yes);
        let n2 = q.next().cloned().unwrap();
        assert_eq!(n2.level, Level::Element);
        q.answer(n2.id, Decision::Yes);
        let n3 = q.next().cloned().unwrap();
        assert_eq!(n3.level, Level::Class);
        // Innerhalb des Class-Levels: hoehere Unsicherheit zuerst.
        assert!((n3.uncertainty - 0.99).abs() < 1e-6);
    }
}
