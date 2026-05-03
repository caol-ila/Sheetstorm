//! k-NN Index for embedding vectors.
//!
//! Default backend: **linear scan** (O(n) per query, zero dependencies).
//! Sufficient for labeling corpora up to ~50k patches; swap in HNSW via the
//! `hnsw` feature flag when higher throughput is needed.
//!
//! Embedding-version is validated on every `add()` call — no mixing of
//! different encoder versions.

use std::collections::BinaryHeap;
use std::cmp::Reverse;

use omr_sig::Distribution;

use crate::types::{ClassLabel, Embedding, Match, PatchSource};

// ── KnnResult ─────────────────────────────────────────────────────────────────

/// Sorted by distance ascending.
pub type KnnResult = Vec<Match>;

// ── IndexError ────────────────────────────────────────────────────────────────

#[derive(thiserror::Error, Debug)]
pub enum IndexError {
    #[error("version mismatch: index expects '{expected}', got '{found}'")]
    VersionMismatch { expected: String, found: String },
    #[error("dim mismatch: index expects {expected}, got {found}")]
    DimMismatch { expected: usize, found: usize },
    #[error("index is empty — call add() first")]
    EmptyIndex,
}

// ── Stored entry ──────────────────────────────────────────────────────────────

struct Entry {
    patch_id: u64,
    label: ClassLabel,
    source: PatchSource,
    vec: Vec<f32>,
}

// ── EmbeddingIndex ────────────────────────────────────────────────────────────

/// Flat k-NN index with cosine distance.
///
/// Uses a linear scan — O(n · dim) per query. For corpora up to ~50k patches
/// this easily stays under 1 ms.  Enable the `hnsw` feature for approximate
/// HNSW lookup on larger corpora.
pub struct EmbeddingIndex {
    expected_version: String,
    expected_dim: usize,
    entries: Vec<Entry>,
}

impl EmbeddingIndex {
    /// Create a new empty index for a specific encoder version and dimension.
    pub fn new(version: &str, dim: usize) -> Self {
        Self {
            expected_version: version.to_string(),
            expected_dim: dim,
            entries: Vec::new(),
        }
    }

    /// Add a labeled embedding.  Version and dim must match the index.
    pub fn add(
        &mut self,
        patch_id: u64,
        embedding: &Embedding,
        label: ClassLabel,
        source: PatchSource,
    ) -> Result<(), IndexError> {
        if embedding.version != self.expected_version {
            return Err(IndexError::VersionMismatch {
                expected: self.expected_version.clone(),
                found: embedding.version.clone(),
            });
        }
        if embedding.vec.len() != self.expected_dim {
            return Err(IndexError::DimMismatch {
                expected: self.expected_dim,
                found: embedding.vec.len(),
            });
        }
        self.entries.push(Entry {
            patch_id,
            label,
            source,
            vec: embedding.vec.clone(),
        });
        Ok(())
    }

    /// No-op for API compatibility with HNSW backends (linear scan needs no build step).
    pub fn build(&mut self) {}

    /// k-NN search via linear scan.  Returns up to `k` matches sorted
    /// by cosine distance (closest first).
    pub fn knn(&mut self, query: &Embedding, k: usize) -> Result<KnnResult, IndexError> {
        if query.version != self.expected_version {
            return Err(IndexError::VersionMismatch {
                expected: self.expected_version.clone(),
                found: query.version.clone(),
            });
        }
        if self.entries.is_empty() {
            return Ok(Vec::new());
        }

        // Max-heap keyed on Reverse(distance) so we keep the k smallest distances.
        // Heap element: (Reverse(distance_bits), index_in_entries)
        let k_actual = k.min(self.entries.len());
        let mut heap: BinaryHeap<(Reverse<u32>, usize)> = BinaryHeap::with_capacity(k_actual + 1);

        for (i, entry) in self.entries.iter().enumerate() {
            let d = crate::distance::cosine(&query.vec, &entry.vec);
            let bits = d.to_bits();
            if heap.len() < k_actual {
                heap.push((Reverse(bits), i));
            } else if let Some(&(Reverse(worst_bits), _)) = heap.peek() {
                if bits < worst_bits {
                    heap.pop();
                    heap.push((Reverse(bits), i));
                }
            }
        }

        let mut results: KnnResult = heap
            .into_sorted_vec()
            .into_iter()
            .map(|(Reverse(bits), i)| {
                let e = &self.entries[i];
                Match {
                    patch_id: e.patch_id,
                    label: e.label.clone(),
                    distance: f32::from_bits(bits),
                    source: e.source,
                }
            })
            .collect();

        // BinaryHeap::into_sorted_vec returns descending; reverse to ascending.
        results.reverse();
        Ok(results)
    }

    /// k-NN search returning a `Distribution<ClassLabel>`.
    ///
    /// Weights per label: sum of `exp(−distance)` over the top-k neighbours.
    pub fn knn_distribution(
        &mut self,
        query: &Embedding,
        k: usize,
    ) -> Result<Distribution<ClassLabel>, IndexError> {
        let matches = self.knn(query, k)?;
        if matches.is_empty() {
            return Err(IndexError::EmptyIndex);
        }
        let mut label_weights: std::collections::HashMap<ClassLabel, f32> =
            std::collections::HashMap::new();
        for m in &matches {
            *label_weights.entry(m.label.clone()).or_insert(0.0) += (-m.distance).exp();
        }
        let weights: Vec<(ClassLabel, f32)> = label_weights.into_iter().collect();
        Ok(Distribution::from_weights(weights))
    }

    /// Number of embeddings stored in the index.
    pub fn corpus_size(&self) -> usize {
        self.entries.len()
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::encoder::{Encoder, HogEncoder, FEATURE_LEN};
    use image::GrayImage;

    fn hog_embed(patch: &GrayImage) -> Embedding {
        HogEncoder::new().embed(patch).unwrap()
    }

    #[test]
    fn add_and_knn_returns_self_first() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let patch = GrayImage::from_fn(64, 64, |x, _| image::Luma([(x * 4) as u8]));
        let emb = hog_embed(&patch);
        idx.add(1, &emb, "notehead".to_string(), PatchSource::Synthetic).unwrap();
        let results = idx.knn(&emb, 1).unwrap();
        assert_eq!(results.len(), 1);
        assert!(
            results[0].distance < 1e-3,
            "self-distance should be ≈0, got {}",
            results[0].distance
        );
        assert_eq!(results[0].label, "notehead");
    }

    #[test]
    fn knn_returns_sorted_by_distance() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let p1 = GrayImage::from_fn(64, 64, |x, _| image::Luma([(x * 4) as u8]));
        let p2 = GrayImage::from_fn(64, 64, |_, y| image::Luma([(y * 4) as u8]));
        let p3 = GrayImage::from_pixel(64, 64, image::Luma([128u8]));
        idx.add(1, &hog_embed(&p1), "a".into(), PatchSource::Synthetic).unwrap();
        idx.add(2, &hog_embed(&p2), "b".into(), PatchSource::User).unwrap();
        idx.add(3, &hog_embed(&p3), "c".into(), PatchSource::DetectorAuto).unwrap();

        let results = idx.knn(&hog_embed(&p1), 3).unwrap();
        assert_eq!(results.len(), 3);
        for w in results.windows(2) {
            assert!(
                w[0].distance <= w[1].distance,
                "distances not ascending: {} > {}",
                w[0].distance,
                w[1].distance
            );
        }
    }

    #[test]
    fn knn_distribution_softmax_normalizes() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let p1 = GrayImage::from_fn(64, 64, |x, _| image::Luma([(x * 4) as u8]));
        let p2 = GrayImage::from_fn(64, 64, |_, y| image::Luma([(y * 4) as u8]));
        idx.add(1, &hog_embed(&p1), "a".into(), PatchSource::Synthetic).unwrap();
        idx.add(2, &hog_embed(&p2), "b".into(), PatchSource::User).unwrap();

        let dist = idx.knn_distribution(&hog_embed(&p1), 2).unwrap();
        let total: f32 = dist.alternatives.iter().map(|(_, p)| p).sum();
        assert!((total - 1.0).abs() < 1e-5, "probs must sum to 1, got {total}");
    }

    #[test]
    fn version_mismatch_returns_error() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let bad = Embedding { vec: vec![0.0; FEATURE_LEN], version: "other-v1".to_string() };
        assert!(matches!(
            idx.add(1, &bad, "x".into(), PatchSource::Synthetic),
            Err(IndexError::VersionMismatch { .. })
        ));
    }

    #[test]
    fn dim_mismatch_returns_error() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let bad = Embedding { vec: vec![0.0; 10], version: "hog-v1".to_string() };
        assert!(matches!(
            idx.add(1, &bad, "x".into(), PatchSource::Synthetic),
            Err(IndexError::DimMismatch { .. })
        ));
    }

    #[test]
    fn empty_index_returns_empty() {
        let mut idx = EmbeddingIndex::new("hog-v1", FEATURE_LEN);
        let emb = Embedding { vec: vec![0.0; FEATURE_LEN], version: "hog-v1".to_string() };
        let results = idx.knn(&emb, 5).unwrap();
        assert!(results.is_empty());
    }
}
