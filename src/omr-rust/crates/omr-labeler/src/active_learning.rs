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

use crate::embedding_corpus::EmbeddingState;
use serde::{Deserialize, Serialize};
use std::collections::{HashSet, VecDeque};
use std::sync::Arc;
use tokio::sync::Mutex;

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
    /// Optional gecachter Patch (PNG-Bytes) für Embedding-basierte Klassifikation.
    #[serde(skip)]
    pub patch_png: Option<Vec<u8>>,
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
    /// Optional: geteilter Embedding-Zustand für HNSW-basierte Priorisierung.
    pub embedding_state: Option<Arc<Mutex<EmbeddingState>>>,
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
            patch_png: None,
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

    /// Sortiert die Queue stabil nach Unsicherheit absteigend.
    pub fn re_prioritize(&mut self) {
        let mut v: Vec<QueueItem> = self.items.drain(..).collect();
        v.sort_by(|a, b| {
            b.uncertainty
                .partial_cmp(&a.uncertainty)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        self.items = v.into();
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    /// Re-priorisiert die Queue anhand der Embedding-Entropie.
    ///
    /// Falls `embedding_state` vorhanden ist, wird für jedes Element-Item
    /// mit gecachtem `patch_png` die Shannon-Entropie berechnet und als
    /// neue `uncertainty` gesetzt. Anschließend wird standard `re_prioritize()`
    /// aufgerufen. Items ohne Patch werden unverändert gelassen.
    pub async fn re_prioritize_with_embeddings(&mut self) -> anyhow::Result<()> {
        let emb_arc = match self.embedding_state.clone() {
            Some(a) => a,
            None => {
                self.re_prioritize();
                return Ok(());
            }
        };

        // Entropien vorab berechnen (Lock halten, Queue nicht mutieren).
        let mut entropies: Vec<(u64, f32)> = Vec::new();
        {
            let mut emb = emb_arc.lock().await;
            for item in self.items.iter() {
                if let Some(png) = &item.patch_png {
                    let ent = emb.entropy(png, 5).await.unwrap_or(item.uncertainty);
                    entropies.push((item.id, ent));
                }
            }
        }

        // Uncertainties aktualisieren.
        for (id, ent) in entropies {
            if let Some(item) = self.items.iter_mut().find(|it| it.id == id) {
                item.uncertainty = ent;
            }
        }

        self.re_prioritize();
        Ok(())
    }

    /// Berechnet Top-K-Vorschläge für ein Item via HNSW und speichert sie in `top_k`.
    ///
    /// `patch_png` muss der PNG-Bytes des Patches sein. Nach dem Aufruf hat das
    /// Item `top_k` mit bis zu 5 Einträgen `(label, confidence)`.
    pub async fn enrich_with_top_k(&mut self, item_id: u64, patch_png: &[u8]) -> anyhow::Result<()> {
        let emb_arc = match self.embedding_state.clone() {
            Some(a) => a,
            None => return Ok(()),
        };

        let top_k = {
            let mut emb = emb_arc.lock().await;
            emb.knn_classify(patch_png, 5).await?
        };

        if let Some(item) = self.items.iter_mut().find(|it| it.id == item_id) {
            item.top_k = top_k;
            item.patch_png = Some(patch_png.to_vec());
        }
        Ok(())
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
}
