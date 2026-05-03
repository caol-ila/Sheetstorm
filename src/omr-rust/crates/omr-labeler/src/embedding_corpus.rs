//! Active-Learning — Embedding-Corpus-Integration.
//!
//! Kapselt den `omr-embed`-Corpus + Index als einen synchronen Zustandsblock,
//! der hinter einem `tokio::sync::Mutex` geteilt wird.
//!
//! Workflow:
//! 1. Beim Start: `EmbeddingState::from_corpus_dir(dir)` oder leer via `new()`.
//! 2. Wenn Annotator eine Klassen-Entscheidung trifft: `add_user_label(...)`.
//! 3. Für Re-Priorisierung der Queue: `knn_classify(...)` + `entropy()`.
//! 4. Stats über `corpus_stats()` für den UI-Endpoint.

use omr_embed::{
    corpus::{Corpus, CorpusError, LabeledPatch},
    encoder::{Encoder, HogEncoder, FEATURE_LEN},
    index::EmbeddingIndex,
    types::{ClassLabel, Match, PatchSource},
};
use std::collections::HashMap;
use std::path::Path;

const ENCODER_VERSION: &str = "hog-v1";
const REBUILD_EVERY: usize = 10;

// ── EmbeddingState ─────────────────────────────────────────────────────────────

/// Zustandsblock für Embedding-Corpus + k-NN-Index.
///
/// Nicht `Clone` — wird hinter einem `Arc<tokio::sync::Mutex<EmbeddingState>>`
/// geteilt.
pub struct EmbeddingState {
    corpus: Corpus,
    index: EmbeddingIndex,
    encoder: HogEncoder,
    labels_since_rebuild: usize,
}

impl std::fmt::Debug for EmbeddingState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("EmbeddingState")
            .field("index_size", &self.index.corpus_size())
            .field("labels_since_rebuild", &self.labels_since_rebuild)
            .finish()
    }
}

impl EmbeddingState {
    /// Erstellt einen leeren Corpus im Arbeitsspeicher (nützlich für Tests).
    pub fn new() -> Result<Self, CorpusError> {
        let corpus = Corpus::open_in_memory()?;
        let index = EmbeddingIndex::new(ENCODER_VERSION, FEATURE_LEN);
        Ok(Self {
            corpus,
            index,
            encoder: HogEncoder::new(),
            labels_since_rebuild: 0,
        })
    }

    /// Öffnet (oder erstellt) einen Corpus unter `dir/corpus.db`.
    /// Baut den Index direkt aus dem gespeicherten Corpus auf.
    pub fn from_corpus_dir(dir: &Path) -> Result<Self, CorpusError> {
        std::fs::create_dir_all(dir).ok();
        let db_path = dir.join("corpus.db");
        let corpus = Corpus::open(&db_path)?;
        let index = corpus.into_index(ENCODER_VERSION)?;
        Ok(Self {
            corpus,
            index,
            encoder: HogEncoder::new(),
            labels_since_rebuild: 0,
        })
    }

    /// Fügt ein vom Annotator bestätigtes Label + PNG-Patch hinzu.
    ///
    /// - Der Patch wird HoG-enkodiert und ins Corpus eingefügt.
    /// - Das Embedding wird auch direkt in den laufenden Index eingespielt
    ///   (kein vollständiger Rebuild nötig).
    /// - Alle `REBUILD_EVERY` Labels wird der Index vollständig neu aufgebaut,
    ///   um akumulierte Drifts zu beseitigen.
    pub fn add_user_label(
        &mut self,
        label: ClassLabel,
        patch_png: Vec<u8>,
        provenance: String,
    ) -> Result<(), anyhow::Error> {
        let gray = decode_png_to_gray(&patch_png)
            .ok_or_else(|| anyhow::anyhow!("PNG-Decode fehlgeschlagen"))?;
        let emb = self
            .encoder
            .embed(&gray)
            .map_err(|e| anyhow::anyhow!("HoG-Encode fehlgeschlagen: {e}"))?;

        let patch = LabeledPatch {
            id: 0,
            label: label.clone(),
            source: PatchSource::User,
            patch_png,
            embedding: Some(emb.clone()),
            provenance,
            created_at: chrono_now(),
            user_confirmed: true,
        };

        let id = self.corpus.add_patch(patch)?;
        let _ = self
            .index
            .add(id, &emb, label, PatchSource::User);

        self.labels_since_rebuild += 1;
        if self.labels_since_rebuild >= REBUILD_EVERY {
            self.rebuild_index()?;
        }
        Ok(())
    }

    /// Klassifiziert einen PNG-Patch mit k-NN und gibt den Top-1-Match zurück.
    /// Gibt `None` zurück wenn der Index leer ist.
    pub fn knn_classify(&mut self, patch_png: &[u8]) -> Option<Match> {
        let gray = decode_png_to_gray(patch_png)?;
        let emb = self.encoder.embed(&gray).ok()?;
        let results = self.index.knn(&emb, 1).ok()?;
        results.into_iter().next()
    }

    /// Entropie der Label-Verteilung im Corpus (Shannon, in Bits).
    ///
    /// Niedrige Entropie = Corpus ist stark auf wenige Klassen konzentriert.
    /// Hohe Entropie = Klassen sind gleichmäßig verteilt — guter Balanceindikator.
    pub fn entropy(&self) -> f64 {
        let counts = self.corpus.count_by_label().unwrap_or_default();
        let total: usize = counts.values().sum();
        if total == 0 {
            return 0.0;
        }
        let n = total as f64;
        counts
            .values()
            .map(|&c| {
                let p = c as f64 / n;
                if p > 0.0 {
                    -p * p.log2()
                } else {
                    0.0
                }
            })
            .sum()
    }

    /// Gibt Corpus-Statistiken als Key-Value-Map zurück.
    pub fn corpus_stats(&self) -> HashMap<String, serde_json::Value> {
        use serde_json::json;
        let by_label = self
            .corpus
            .count_by_label()
            .unwrap_or_default();
        let by_source = self
            .corpus
            .count_by_source()
            .unwrap_or_default();
        let total: usize = by_label.values().sum();

        let synthetic = by_source
            .get(&PatchSource::Synthetic)
            .copied()
            .unwrap_or(0);
        let user = by_source
            .get(&PatchSource::User)
            .copied()
            .unwrap_or(0);

        let mut map = HashMap::new();
        map.insert("total".to_string(), json!(total));
        map.insert("synthetic".to_string(), json!(synthetic));
        map.insert("user".to_string(), json!(user));
        map.insert("classes".to_string(), json!(by_label.len()));
        map.insert(
            "index_size".to_string(),
            json!(self.index.corpus_size()),
        );
        map.insert("entropy_bits".to_string(), json!(self.entropy()));
        map.insert("labels_since_rebuild".to_string(), json!(self.labels_since_rebuild));
        map
    }

    // ── Privat ──────────────────────────────────────────────────────────────

    fn rebuild_index(&mut self) -> Result<(), CorpusError> {
        self.index = self.corpus.into_index(ENCODER_VERSION)?;
        self.labels_since_rebuild = 0;
        Ok(())
    }
}

// ── Hilfsfunktionen ───────────────────────────────────────────────────────────

/// Dekodiert ein PNG-Byte-Slice zu einem 64×64-Graustufenbild.
/// Gibt `None` bei fehlerhaftem PNG oder falschem Format zurück.
fn decode_png_to_gray(png_bytes: &[u8]) -> Option<image::GrayImage> {
    let img = image::load_from_memory(png_bytes).ok()?;
    let gray = img.into_luma8();
    // Auf 64×64 skalieren, falls nötig.
    if gray.width() == 64 && gray.height() == 64 {
        Some(gray)
    } else {
        use image::imageops::FilterType;
        let resized = image::imageops::resize(&gray, 64, 64, FilterType::Lanczos3);
        Some(resized)
    }
}

fn chrono_now() -> String {
    // Kein chrono-Dependency — ISO-8601-ähnlicher Timestamp via std.
    // Für Produktionsreife könnte man chrono einbinden.
    std::time::SystemTime::UNIX_EPOCH
        .elapsed()
        .map(|d| format!("{}", d.as_secs()))
        .unwrap_or_else(|_| "0".to_string())
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use image::{GrayImage, Luma};

    fn make_patch_png(pixel: u8) -> Vec<u8> {
        let img = GrayImage::from_pixel(64, 64, Luma([pixel]));
        let mut buf = Vec::new();
        img.write_to(
            &mut std::io::Cursor::new(&mut buf),
            image::ImageFormat::Png,
        )
        .unwrap();
        buf
    }

    #[tokio::test]
    async fn new_state_is_empty() {
        let state = EmbeddingState::new().unwrap();
        assert_eq!(state.index.corpus_size(), 0);
        let stats = state.corpus_stats();
        assert_eq!(stats["total"], 0);
    }

    #[tokio::test]
    async fn add_label_grows_index() {
        let mut state = EmbeddingState::new().unwrap();
        let png = make_patch_png(128);
        state
            .add_user_label("notehead-filled".to_string(), png, "test".to_string())
            .unwrap();
        let stats = state.corpus_stats();
        assert_eq!(stats["total"], 1);
        assert_eq!(stats["user"], 1);
        assert!(state.index.corpus_size() >= 1);
    }

    #[tokio::test]
    async fn knn_classify_returns_added_label() {
        let mut state = EmbeddingState::new().unwrap();
        let png = make_patch_png(200);
        state
            .add_user_label("notehead-filled".to_string(), png.clone(), "test".to_string())
            .unwrap();
        let top1 = state.knn_classify(&png).unwrap();
        assert_eq!(top1.label, "notehead-filled");
        assert!(top1.distance < 1e-3, "self-distance should be ≈0");
    }

    #[tokio::test]
    async fn entropy_zero_for_uniform_class() {
        let mut state = EmbeddingState::new().unwrap();
        for i in 0..5u8 {
            let png = make_patch_png(i * 20);
            state
                .add_user_label("notehead-filled".to_string(), png, format!("t{i}"))
                .unwrap();
        }
        // Alle Patches sind in derselben Klasse → Entropie ≈ 0
        let h = state.entropy();
        assert!(h < 1e-6, "single-class entropy should be 0, got {h}");
    }

    #[tokio::test]
    async fn entropy_higher_for_balanced_classes() {
        let mut state = EmbeddingState::new().unwrap();
        for i in 0..4u8 {
            let png = make_patch_png(i * 60);
            let label = format!("class-{i}");
            state
                .add_user_label(label, png, format!("t{i}"))
                .unwrap();
        }
        let h = state.entropy();
        // 4 gleichmäßige Klassen → H ≈ 2 Bits
        assert!(h > 1.9, "balanced 4-class entropy should be ~2 bits, got {h}");
    }
}
