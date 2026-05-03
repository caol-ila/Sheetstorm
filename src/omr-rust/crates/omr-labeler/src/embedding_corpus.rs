//! Verbindet omr-labeler mit dem omr-embed Korpus.
//!
//! Beim Start:
//! 1. Lade synthetic_corpus_v1 in einen omr_embed::Corpus (in-memory SQLite)
//! 2. Embedde alle synthetic patches via HogEncoder
//! 3. Baue EmbeddingIndex (linear scan, ausreichend für ≤50k Patches)
//!
//! Bei jedem User-Label:
//! 4. Embedde den Patch
//! 5. Add zu Corpus (mit PatchSource::User)
//! 6. Re-build Index (incremental: alle 10 Labels)

use anyhow::{Context, Result};
use image::GrayImage;
use omr_embed::{Corpus, EmbeddingIndex, Encoder, HogEncoder, LabeledPatch, PatchSource};
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;

// ── Timestamp helper ─────────────────────────────────────────────────────────

fn now_iso8601() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0) as i64;
    let days = secs / 86400;
    let rem = secs % 86400;
    let (hh, mm, ss) = (rem / 3600, (rem % 3600) / 60, rem % 60);
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!("{y:04}-{m:02}-{d:02}T{hh:02}:{mm:02}:{ss:02}Z")
}

// ── Image decode helper ───────────────────────────────────────────────────────

/// Dekodiert PNG/JPEG-Bytes als GrayImage (64×64 Nearest-Neighbor).
pub fn decode_png_to_gray(data: &[u8]) -> Result<GrayImage> {
    let img = image::load_from_memory(data).context("image decode")?;
    Ok(img.to_luma8())
}

// ── EmbeddingState ────────────────────────────────────────────────────────────

/// Kombinierter Zustand aus Corpus, Index und Encoder.
///
/// Hält alle User-Labels und synthetischen Patches in einer In-Memory-SQLite-DB.
/// Der Index (lineare Scan) wird inkrementell beim 10. User-Label neu aufgebaut.
pub struct EmbeddingState {
    pub corpus: Corpus,
    pub index: EmbeddingIndex,
    pub encoder: Arc<dyn Encoder + Send + Sync>,
    pub labels_since_rebuild: usize,
}

impl EmbeddingState {
    /// Leerer Zustand ohne Corpus-Daten (für Tests).
    pub fn new_empty() -> Self {
        let encoder: Arc<dyn Encoder + Send + Sync> = Arc::new(HogEncoder::new());
        let corpus = Corpus::open_in_memory().expect("in-memory SQLite");
        let index = EmbeddingIndex::new(encoder.version(), encoder.dim());
        Self {
            corpus,
            index,
            encoder,
            labels_since_rebuild: 0,
        }
    }

    /// Lädt synthetischen Corpus aus Verzeichnis (Klasen-Subdirs mit PNG-Dateien).
    ///
    /// Pro Klasse werden bis zu `max_per_class` Bilder eingelesen, eingebettet
    /// und dem Corpus hinzugefügt. Anschließend wird der Index aufgebaut.
    pub async fn from_corpus_dir(dir: &Path) -> Result<Self> {
        let mut state = Self::new_empty();

        if !dir.exists() {
            tracing::info!(
                "Synthetischer Corpus-Pfad nicht gefunden: {} — starte ohne Vorwissen.",
                dir.display()
            );
            return Ok(state);
        }

        let read = match std::fs::read_dir(dir) {
            Ok(r) => r,
            Err(e) => {
                tracing::warn!("Kann Corpus-Verzeichnis nicht lesen ({}): {}", dir.display(), e);
                return Ok(state);
            }
        };

        let mut total_loaded = 0usize;

        for entry in read.flatten() {
            let class_dir = entry.path();
            if !class_dir.is_dir() {
                continue;
            }
            let class_name = match class_dir.file_name().and_then(|s| s.to_str()) {
                Some(s) => s.to_string(),
                None => continue,
            };

            let mut image_paths: Vec<_> = std::fs::read_dir(&class_dir)
                .ok()
                .into_iter()
                .flatten()
                .flatten()
                .filter_map(|e| {
                    let fp = e.path();
                    let ext = fp.extension()?.to_str()?.to_ascii_lowercase();
                    if ["png", "jpg", "jpeg", "bmp"].contains(&ext.as_str()) {
                        Some(fp)
                    } else {
                        None
                    }
                })
                .collect();
            image_paths.sort();
            image_paths.truncate(50); // max 50 per class to keep startup fast

            for img_path in &image_paths {
                let png_bytes = match std::fs::read(img_path) {
                    Ok(b) => b,
                    Err(_) => continue,
                };
                let gray = match decode_png_to_gray(&png_bytes) {
                    Ok(g) => g,
                    Err(_) => continue,
                };
                let mut emb = match state.encoder.embed(&gray) {
                    Ok(e) => e,
                    Err(_) => continue,
                };
                emb.normalize();

                let patch = LabeledPatch {
                    id: 0,
                    label: class_name.clone(),
                    source: PatchSource::Synthetic,
                    patch_png: png_bytes,
                    embedding: Some(emb),
                    provenance: img_path.display().to_string(),
                    created_at: "2024-01-01T00:00:00Z".to_string(),
                    user_confirmed: false,
                };
                let _ = state.corpus.add_patch(patch);
                total_loaded += 1;
            }
        }

        tracing::info!(
            "Embedding-Corpus geladen: {} Patches aus {}",
            total_loaded,
            dir.display()
        );

        state.rebuild_index()?;
        Ok(state)
    }

    /// Baut den EmbeddingIndex neu aus dem aktuellen Corpus auf.
    pub fn rebuild_index(&mut self) -> Result<()> {
        self.index = self
            .corpus
            .into_index(self.encoder.version())
            .map_err(|e| anyhow::anyhow!("Index-Build: {}", e))?;
        self.labels_since_rebuild = 0;
        tracing::debug!("EmbeddingIndex neu aufgebaut: {} Einträge", self.index.corpus_size());
        Ok(())
    }

    /// Fügt ein User-Label zum Corpus hinzu und aktualisiert den Index.
    ///
    /// Jedes 10. Label wird der Index vollständig neu aufgebaut (für Konsistenz).
    pub async fn add_user_label(&mut self, patch_png: &[u8], label: &str) -> Result<()> {
        let gray = decode_png_to_gray(patch_png)?;
        let mut emb = self
            .encoder
            .embed(&gray)
            .map_err(|e| anyhow::anyhow!("Encode: {}", e))?;
        emb.normalize();

        let patch = LabeledPatch {
            id: 0,
            label: label.to_string(),
            source: PatchSource::User,
            patch_png: patch_png.to_vec(),
            embedding: Some(emb.clone()),
            provenance: "user-label".to_string(),
            created_at: now_iso8601(),
            user_confirmed: true,
        };
        let id = self
            .corpus
            .add_patch(patch)
            .map_err(|e| anyhow::anyhow!("Corpus-Add: {}", e))?;

        // Incremental add to index (avoids full rebuild every time).
        let _ = self.index.add(id, &emb, label.to_string(), PatchSource::User);

        self.labels_since_rebuild += 1;
        if self.labels_since_rebuild >= 10 {
            self.rebuild_index()?;
        }
        Ok(())
    }

    /// Klassifiziert einen Patch via k-NN-Lookup.
    ///
    /// Gibt die Top-k Labels mit Konfidenz-Score [0..1] zurück.
    /// Konfidenz = `1 − cosine_distance` (höher = ähnlicher).
    pub async fn knn_classify(&mut self, patch_png: &[u8], k: usize) -> Result<Vec<(String, f32)>> {
        if self.index.corpus_size() == 0 {
            return Ok(Vec::new());
        }
        let gray = decode_png_to_gray(patch_png)?;
        let mut emb = self
            .encoder
            .embed(&gray)
            .map_err(|e| anyhow::anyhow!("Encode: {}", e))?;
        emb.normalize();

        let matches = self
            .index
            .knn(&emb, k)
            .map_err(|e| anyhow::anyhow!("kNN: {}", e))?;

        Ok(matches
            .into_iter()
            .map(|m| (m.label, (1.0_f32 - m.distance).max(0.0)))
            .collect())
    }

    /// Berechnet die Shannon-Entropie des k-NN-Labelings (höher = unsicherer).
    ///
    /// Gibt `1.0` zurück wenn keine Daten im Index vorhanden.
    pub async fn entropy(&mut self, patch_png: &[u8], k: usize) -> Result<f32> {
        let results = self.knn_classify(patch_png, k).await?;
        if results.is_empty() {
            return Ok(1.0);
        }

        // Label-Voting: wie viele der k Nachbarn haben dasselbe Label?
        let mut label_votes: HashMap<&str, f32> = HashMap::new();
        let total = results.len() as f32;
        for (label, _conf) in &results {
            *label_votes.entry(label.as_str()).or_insert(0.0) += 1.0;
        }

        // Shannon-Entropie H = −Σ p·log₂(p)
        let entropy: f32 = label_votes
            .values()
            .map(|&count| {
                let p = count / total;
                if p > 1e-9 { -p * p.log2() } else { 0.0 }
            })
            .sum();

        Ok(entropy)
    }

    // ── Stats ─────────────────────────────────────────────────────────────────

    /// Anzahl Patches im Index.
    pub fn corpus_size(&self) -> usize {
        self.index.corpus_size()
    }

    /// Label → Anzahl Patches.
    pub fn label_distribution(&self) -> HashMap<String, usize> {
        self.corpus.count_by_label().unwrap_or_default()
    }

    /// Anzahl User-bestätigter Patches.
    pub fn user_label_count(&self) -> usize {
        self.corpus
            .count_by_source()
            .unwrap_or_default()
            .get(&PatchSource::User)
            .copied()
            .unwrap_or(0)
    }

    /// Anzahl synthetischer Patches.
    pub fn synthetic_count(&self) -> usize {
        self.corpus
            .count_by_source()
            .unwrap_or_default()
            .get(&PatchSource::Synthetic)
            .copied()
            .unwrap_or(0)
    }

    /// Anzahl eindeutiger Klassen mit User-Labels.
    pub fn user_class_count(&self) -> usize {
        let dist = self.label_distribution();
        // We count classes that have at least one user label
        let user_labels = self
            .corpus
            .iter_all()
            .filter(|p| p.source == PatchSource::User)
            .map(|p| p.label)
            .collect::<std::collections::HashSet<_>>();
        user_labels.len()
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use image::{GrayImage, Luma};

    fn black_patch() -> Vec<u8> {
        let img = GrayImage::from_pixel(64, 64, Luma([0u8]));
        let mut buf = Vec::new();
        img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)
            .unwrap();
        buf
    }

    fn gradient_patch() -> Vec<u8> {
        let mut img = GrayImage::new(64, 64);
        for y in 0..64u32 {
            for x in 0..64u32 {
                img.put_pixel(x, y, Luma([((x + y) * 2).min(255) as u8]));
            }
        }
        let mut buf = Vec::new();
        img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)
            .unwrap();
        buf
    }

    #[tokio::test]
    async fn empty_state_knn_returns_empty() {
        let mut state = EmbeddingState::new_empty();
        let patch = black_patch();
        let result = state.knn_classify(&patch, 5).await.unwrap();
        assert!(result.is_empty());
    }

    #[tokio::test]
    async fn empty_state_entropy_returns_one() {
        let mut state = EmbeddingState::new_empty();
        let patch = black_patch();
        let ent = state.entropy(&patch, 5).await.unwrap();
        assert!((ent - 1.0).abs() < 1e-5, "expected entropy=1.0 for empty index, got {ent}");
    }

    #[tokio::test]
    async fn add_user_label_and_classify() {
        let mut state = EmbeddingState::new_empty();
        let patch = black_patch();
        state.add_user_label(&patch, "quarter_note").await.unwrap();

        let results = state.knn_classify(&patch, 1).await.unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].0, "quarter_note");
        assert!(results[0].1 > 0.9, "confidence should be high for self-lookup, got {}", results[0].1);
    }

    #[tokio::test]
    async fn entropy_low_for_uniform_labels() {
        let mut state = EmbeddingState::new_empty();
        // Add 5 same-class patches
        let patch = gradient_patch();
        for _ in 0..5 {
            state.add_user_label(&patch, "half_note").await.unwrap();
        }
        let ent = state.entropy(&patch, 5).await.unwrap();
        // All neighbors same class → entropy = 0
        assert!(ent < 0.1, "expected low entropy for uniform labels, got {ent}");
    }

    #[tokio::test]
    async fn corpus_size_grows_after_adding_labels() {
        let mut state = EmbeddingState::new_empty();
        assert_eq!(state.corpus_size(), 0);
        let patch = black_patch();
        state.add_user_label(&patch, "rest").await.unwrap();
        assert_eq!(state.corpus_size(), 1);
    }

    #[tokio::test]
    async fn user_label_count_tracked() {
        let mut state = EmbeddingState::new_empty();
        let patch = black_patch();
        state.add_user_label(&patch, "a").await.unwrap();
        state.add_user_label(&patch, "b").await.unwrap();
        assert_eq!(state.user_label_count(), 2);
    }
}
