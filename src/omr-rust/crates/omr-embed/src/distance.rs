//! Distance functions for embedding vectors.
//!
//! All functions operate on raw `&[f32]` slices so they can be used both
//! with `Embedding::vec` and with internal index representations.

/// Cosine distance between two vectors: `1 − cosine_similarity`.
///
/// Returns `1.0` if either vector is (near-)zero.
/// Result is in `[0.0, 2.0]`; for unit vectors in `[0.0, 1.0]`.
pub fn cosine(a: &[f32], b: &[f32]) -> f32 {
    debug_assert_eq!(a.len(), b.len(), "cosine: length mismatch");
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm_a < 1e-6 || norm_b < 1e-6 {
        return 1.0;
    }
    (1.0 - (dot / (norm_a * norm_b))).clamp(0.0, 2.0)
}

/// Euclidean distance between two vectors: `√Σ(aᵢ − bᵢ)²`.
pub fn euclidean(a: &[f32], b: &[f32]) -> f32 {
    debug_assert_eq!(a.len(), b.len(), "euclidean: length mismatch");
    a.iter()
        .zip(b.iter())
        .map(|(x, y)| (x - y).powi(2))
        .sum::<f32>()
        .sqrt()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cosine_orthogonal_is_one() {
        let a = vec![1.0_f32, 0.0, 0.0];
        let b = vec![0.0_f32, 1.0, 0.0];
        let d = cosine(&a, &b);
        assert!((d - 1.0).abs() < 1e-5, "expected 1.0 got {d}");
    }

    #[test]
    fn cosine_parallel_is_zero() {
        let a = vec![1.0_f32, 0.0, 0.0];
        let b = vec![3.0_f32, 0.0, 0.0];
        let d = cosine(&a, &b);
        assert!(d.abs() < 1e-5, "expected 0.0 got {d}");
    }

    #[test]
    fn euclidean_zero_for_same_vector() {
        let v = vec![1.0_f32, 2.0, 3.0, 4.0];
        let d = euclidean(&v, &v);
        assert!(d.abs() < 1e-6, "expected 0.0 got {d}");
    }

    #[test]
    fn cosine_with_real_embeddings() {
        use crate::encoder::{Encoder, HogEncoder};
        use image::{GrayImage, Luma};

        let enc = HogEncoder::new();
        let patch = GrayImage::from_pixel(64, 64, Luma([128u8]));
        let emb = enc.embed(&patch).expect("encode failed");

        // Same patch → distance ≈ 0.
        let d = cosine(&emb.vec, &emb.vec);
        assert!(d.abs() < 1e-5, "self-cosine expected 0 got {d}");
    }
}
