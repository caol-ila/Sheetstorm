//! Encoder trait + concrete implementations.
//!
//! `HogEncoder` works on 64×64 grayscale patches and produces a 1764-dim
//! L2-Hys-normalised HoG descriptor:
//!   cell=8×8 px, block=2×2 cells (16×16 px), 9 bins, stride=1 cell
//!   → 7×7 blocks × 4 cells/block × 9 bins = **1764 features**

use image::GrayImage;
use crate::types::Embedding;

// ── HoG constants (64×64 input) ──────────────────────────────────────────────

/// Expected patch width/height in pixels.
pub const PATCH_SIZE: u32 = 64;
/// Cell side in pixels.
const CELL_SIZE: u32 = 8;
/// Block side in cells.
const BLOCK_CELLS: u32 = 2;
/// Orientation bins.
const N_BINS: usize = 9;
/// Cells per axis of the patch.
const CELLS_PER_AXIS: u32 = PATCH_SIZE / CELL_SIZE; // 8
/// Blocks per axis (stride-1 sliding window).
const BLOCKS_PER_AXIS: u32 = CELLS_PER_AXIS - BLOCK_CELLS + 1; // 7
/// Total descriptor length.
pub const FEATURE_LEN: usize = (BLOCKS_PER_AXIS as usize)
    * (BLOCKS_PER_AXIS as usize)
    * (BLOCK_CELLS as usize)
    * (BLOCK_CELLS as usize)
    * N_BINS; // 7*7*2*2*9 = 1764

// ── EncoderError ─────────────────────────────────────────────────────────────

#[derive(thiserror::Error, Debug)]
pub enum EncoderError {
    #[error("ONNX model load failed: {0}")]
    OnnxLoad(String),
    #[error("ONNX inference failed: {0}")]
    OnnxInference(String),
    #[error("Unexpected output shape: expected {expected} dims, got {got}")]
    OutputShape { expected: usize, got: usize },
}

// ── Encoder trait ─────────────────────────────────────────────────────────────

pub trait Encoder: Send + Sync {
    fn embed(&self, patch: &GrayImage) -> Result<Embedding, EncoderError>;
    fn dim(&self) -> usize;
    fn version(&self) -> &str;
}

// ── HogEncoder ───────────────────────────────────────────────────────────────

/// HoG-based encoder.  Requires no training — works immediately.
/// Baseline for cold-start scenarios.
///
/// Cell 8×8 px, Block 16×16 px (2×2 cells), 9 bins
/// → 64×64 patch → 1764-dim descriptor
pub struct HogEncoder;

impl HogEncoder {
    pub fn new() -> Self {
        Self
    }
}

impl Default for HogEncoder {
    fn default() -> Self { Self::new() }
}

impl Encoder for HogEncoder {
    fn embed(&self, patch: &GrayImage) -> Result<Embedding, EncoderError> {
        let resized = resize_nn(patch, PATCH_SIZE, PATCH_SIZE);
        let (mag, ori) = compute_gradients(&resized);
        let cells = compute_cell_histograms(&mag, &ori);
        let vec = block_normalize(&cells);
        Ok(Embedding { vec, version: self.version().to_string() })
    }

    fn dim(&self) -> usize { FEATURE_LEN }

    fn version(&self) -> &str { "hog-v1" }
}

// ── HoG internals ────────────────────────────────────────────────────────────

fn resize_nn(src: &GrayImage, w: u32, h: u32) -> GrayImage {
    if src.width() == w && src.height() == h {
        return src.clone();
    }
    let sw = src.width() as f32;
    let sh = src.height() as f32;
    let mut dst = GrayImage::new(w, h);
    for y in 0..h {
        for x in 0..w {
            let sx = ((x as f32 + 0.5) * sw / w as f32).floor() as u32;
            let sy = ((y as f32 + 0.5) * sh / h as f32).floor() as u32;
            let sx = sx.min(src.width() - 1);
            let sy = sy.min(src.height() - 1);
            dst.put_pixel(x, y, *src.get_pixel(sx, sy));
        }
    }
    dst
}

fn compute_gradients(img: &GrayImage) -> (Vec<f32>, Vec<f32>) {
    let w = img.width() as i32;
    let h = img.height() as i32;
    let n = (w * h) as usize;
    let mut mag = vec![0.0_f32; n];
    let mut ori = vec![0.0_f32; n];
    let pi = std::f32::consts::PI;

    let get = |x: i32, y: i32| -> f32 {
        if x < 0 || y < 0 || x >= w || y >= h {
            0.0
        } else {
            img.get_pixel(x as u32, y as u32)[0] as f32
        }
    };

    for y in 0..h {
        for x in 0..w {
            let gx = get(x + 1, y) - get(x - 1, y);
            let gy = get(x, y + 1) - get(x, y - 1);
            let m = (gx * gx + gy * gy).sqrt();
            let mut a = gy.atan2(gx);
            if a < 0.0 { a += pi; }
            if a >= pi { a -= pi; }
            let idx = (y * w + x) as usize;
            mag[idx] = m;
            ori[idx] = a;
        }
    }
    (mag, ori)
}

fn compute_cell_histograms(mag: &[f32], ori: &[f32]) -> Vec<f32> {
    let cpa = CELLS_PER_AXIS as usize;
    let cs = CELL_SIZE as usize;
    let mut cells = vec![0.0_f32; cpa * cpa * N_BINS];
    let bin_width = std::f32::consts::PI / N_BINS as f32;
    let img_w = PATCH_SIZE as usize;

    for cy in 0..cpa {
        for cx in 0..cpa {
            let base = (cy * cpa + cx) * N_BINS;
            for py in 0..cs {
                for px in 0..cs {
                    let x = cx * cs + px;
                    let y = cy * cs + py;
                    let pix = y * img_w + x;
                    let m = mag[pix];
                    if m == 0.0 { continue; }
                    let a = ori[pix];
                    let bin_pos = a / bin_width - 0.5;
                    let lower = bin_pos.floor() as i32;
                    let frac = bin_pos - lower as f32;
                    let lo = lower.rem_euclid(N_BINS as i32) as usize;
                    let hi = (lower + 1).rem_euclid(N_BINS as i32) as usize;
                    cells[base + lo] += m * (1.0 - frac);
                    cells[base + hi] += m * frac;
                }
            }
        }
    }
    cells
}

fn block_normalize(cells: &[f32]) -> Vec<f32> {
    let cpa = CELLS_PER_AXIS as usize;
    let bc = BLOCK_CELLS as usize;
    let bpa = BLOCKS_PER_AXIS as usize;
    let mut feats = Vec::with_capacity(FEATURE_LEN);

    for by in 0..bpa {
        for bx in 0..bpa {
            let mut block: Vec<f32> = Vec::with_capacity(bc * bc * N_BINS);
            for dy in 0..bc {
                for dx in 0..bc {
                    let cy = by + dy;
                    let cx = bx + dx;
                    let base = (cy * cpa + cx) * N_BINS;
                    block.extend_from_slice(&cells[base..base + N_BINS]);
                }
            }
            // L2-Hys: clip at 0.2 then re-normalise
            let norm = block.iter().map(|v| v * v).sum::<f32>().sqrt();
            if norm > 1e-6 {
                for v in &mut block { *v /= norm; }
                for v in &mut block { if *v > 0.2 { *v = 0.2; } }
                let norm2 = block.iter().map(|v| v * v).sum::<f32>().sqrt();
                if norm2 > 1e-6 {
                    for v in &mut block { *v /= norm2; }
                }
            }
            feats.extend(block);
        }
    }
    debug_assert_eq!(feats.len(), FEATURE_LEN);
    feats
}

// ── OnnxCnnEncoder (optional) ─────────────────────────────────────────────────
//
// Wraps a trained MobileNetV3-Small ONNX model produced by
// tools/training/train_embedding.py.
//
// Input:  [1, 3, 64, 64] float32 (RGB, ImageNet-normalised)
// Output: [1, 256] float32 (L2-normalised embedding)
//
// The encoder converts incoming GrayImage patches to 3-channel RGB by
// replicating the grayscale channel, then applies ImageNet normalisation.

/// ImageNet channel mean (R, G, B) — used by `OnnxCnnEncoder`.
#[cfg(feature = "cnn")]
const IMAGENET_MEAN: [f32; 3] = [0.485, 0.456, 0.406];
/// ImageNet channel std (R, G, B) — used by `OnnxCnnEncoder`.
#[cfg(feature = "cnn")]
const IMAGENET_STD: [f32; 3] = [0.229, 0.224, 0.225];

#[cfg(feature = "cnn")]
pub struct OnnxCnnEncoder {
    model: tract_onnx::prelude::SimplePlan<
        tract_onnx::prelude::TypedFact,
        Box<dyn tract_onnx::prelude::TypedOp>,
        tract_onnx::prelude::Graph<
            tract_onnx::prelude::TypedFact,
            Box<dyn tract_onnx::prelude::TypedOp>,
        >,
    >,
    dim: usize,
}

#[cfg(feature = "cnn")]
impl OnnxCnnEncoder {
    /// Load an ONNX model from a file path.
    ///
    /// The model must accept `[1, 3, 64, 64]` float32 input (RGB, ImageNet-normalised)
    /// and produce `[1, dim]` float32 output (L2-normalised embeddings).
    pub fn from_path(model_path: &std::path::Path) -> Result<Self, EncoderError> {
        use tract_onnx::prelude::*;
        let model = tract_onnx::onnx()
            .model_for_path(model_path)
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .with_input_fact(0, f32::fact([1, 3, 64, 64]).into())
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .into_optimized()
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .into_runnable()
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?;
        Ok(Self { model, dim: 256 })
    }

    /// Load an ONNX model from raw bytes (e.g. via `include_bytes!`).
    pub fn from_bytes(model_bytes: &[u8]) -> Result<Self, EncoderError> {
        use tract_onnx::prelude::*;
        let model = tract_onnx::onnx()
            .model_for_read(&mut std::io::Cursor::new(model_bytes))
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .with_input_fact(0, f32::fact([1, 3, 64, 64]).into())
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .into_optimized()
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?
            .into_runnable()
            .map_err(|e| EncoderError::OnnxLoad(e.to_string()))?;
        Ok(Self { model, dim: 256 })
    }

    /// Load the pre-trained symbol encoder bundled in the crate assets.
    ///
    /// The ONNX file is embedded at compile time via `include_bytes!` when
    /// `assets/symbol_encoder_v1.onnx` is present (detected by `build.rs`).
    ///
    /// To generate the model:
    /// ```text
    /// cd tools/training
    /// python train_embedding.py --corpus data/synthetic_corpus_v1/single
    /// cp models/symbol_encoder_v1.onnx \
    ///    src/omr-rust/crates/omr-embed/assets/symbol_encoder_v1.onnx
    /// ```
    #[cfg(has_embedded_model)]
    pub fn embedded() -> Result<Self, EncoderError> {
        const MODEL_BYTES: &[u8] =
            include_bytes!("../assets/symbol_encoder_v1.onnx");
        Self::from_bytes(MODEL_BYTES)
    }

    /// Placeholder returned when the embedded model was not compiled in.
    #[cfg(not(has_embedded_model))]
    pub fn embedded() -> Result<Self, EncoderError> {
        Err(EncoderError::OnnxLoad(
            "Embedded model not compiled in. \
             Generate it with: python tools/training/train_embedding.py \
             and copy models/symbol_encoder_v1.onnx to \
             src/omr-rust/crates/omr-embed/assets/symbol_encoder_v1.onnx, \
             then rebuild.".into(),
        ))
    }
}

#[cfg(feature = "cnn")]
impl Encoder for OnnxCnnEncoder {
    /// Embed a 64×64 grayscale patch.
    ///
    /// The grayscale channel is replicated to RGB, then ImageNet-normalised
    /// before inference, matching the Python training pipeline.
    fn embed(&self, patch: &GrayImage) -> Result<Embedding, EncoderError> {
        use tract_onnx::prelude::*;
        let resized = resize_nn(patch, PATCH_SIZE, PATCH_SIZE);

        // Convert grayscale → 3-channel RGB with ImageNet normalisation.
        let input: Tensor = tract_ndarray::Array4::from_shape_fn(
            (1, 3, PATCH_SIZE as usize, PATCH_SIZE as usize),
            |(_, c, y, x)| {
                let gray = resized.get_pixel(x as u32, y as u32)[0] as f32 / 255.0;
                (gray - IMAGENET_MEAN[c]) / IMAGENET_STD[c]
            },
        )
        .into();

        let outputs = self
            .model
            .run(tvec![input.into()])
            .map_err(|e| EncoderError::OnnxInference(e.to_string()))?;
        let arr = outputs[0]
            .to_array_view::<f32>()
            .map_err(|e| EncoderError::OnnxInference(e.to_string()))?;
        let vec: Vec<f32> = arr.iter().copied().collect();
        if vec.len() != self.dim {
            return Err(EncoderError::OutputShape {
                expected: self.dim,
                got: vec.len(),
            });
        }
        Ok(Embedding { vec, version: self.version().to_string() })
    }

    fn dim(&self) -> usize { self.dim }
    fn version(&self) -> &str { "cnn-v1" }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use image::{GrayImage, Luma};

    fn gradient_patch() -> GrayImage {
        let mut img = GrayImage::new(64, 64);
        for y in 0..64u32 {
            for x in 0..64u32 {
                img.put_pixel(x, y, Luma([(x * 4).min(255) as u8]));
            }
        }
        img
    }

    fn uniform_patch(v: u8) -> GrayImage {
        GrayImage::from_pixel(64, 64, Luma([v]))
    }

    #[test]
    fn hog_encoder_produces_consistent_dim() {
        let enc = HogEncoder::new();
        let patch = gradient_patch();
        let emb = enc.embed(&patch).unwrap();
        assert_eq!(emb.vec.len(), enc.dim());
        assert_eq!(emb.vec.len(), FEATURE_LEN);
    }

    #[test]
    fn hog_encoder_same_patch_same_embedding() {
        let enc = HogEncoder::new();
        let patch = gradient_patch();
        let e1 = enc.embed(&patch).unwrap();
        let e2 = enc.embed(&patch).unwrap();
        assert_eq!(e1.vec, e2.vec, "HoG must be deterministic");
    }

    #[test]
    fn hog_encoder_different_patches_different_embeddings() {
        let enc = HogEncoder::new();
        let e1 = enc.embed(&gradient_patch()).unwrap();
        let e2 = enc.embed(&uniform_patch(0)).unwrap();
        assert_ne!(e1.vec, e2.vec);
    }

    #[test]
    fn hog_normalize_makes_unit_length() {
        let enc = HogEncoder::new();
        let mut emb = enc.embed(&gradient_patch()).unwrap();
        emb.normalize();
        let norm: f32 = emb.vec.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!(
            (norm - 1.0).abs() < 1e-5 || norm < 1e-6,
            "expected unit norm, got {norm}"
        );
    }
}
