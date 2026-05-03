//! Core value types: Embedding, Match, ClassLabel, PatchSource.

use serde::{Deserialize, Serialize};

/// Dense float vector produced by an Encoder.
///
/// `version` is an opaque tag (e.g. `"hog-v1"`, `"cnn-v3-mobilenet"`) that
/// identifies the encoder variant.  Embeddings from different versions MUST
/// NOT be mixed in the same index or compared directly.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Embedding {
    pub vec: Vec<f32>,
    /// Encoder-Version-Tag.  Used for corpus migration checks.
    pub version: String,
}

impl Embedding {
    /// Dimensionality of this embedding.
    pub fn dim(&self) -> usize {
        self.vec.len()
    }

    /// L2-normalise the vector in-place.  No-op for zero vectors.
    pub fn normalize(&mut self) {
        let norm: f32 = self.vec.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 1e-6 {
            for v in &mut self.vec {
                *v /= norm;
            }
        }
    }
}

/// Human-readable symbol class identifier (e.g. `"notehead-filled"`, `"rest-quarter"`).
pub type ClassLabel = String;

/// One k-NN search result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Match {
    pub patch_id: u64,
    pub label: ClassLabel,
    pub distance: f32,
    pub source: PatchSource,
}

/// Where a training patch came from.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum PatchSource {
    /// Synthetically rendered (Bravura font, PrIMuS render pipeline).
    Synthetic,
    /// Manually confirmed by a human user.
    User,
    /// Automatically labelled by the ML detector at low confidence.
    DetectorAuto,
}

impl PatchSource {
    pub fn as_str(self) -> &'static str {
        match self {
            PatchSource::Synthetic => "Synthetic",
            PatchSource::User => "User",
            PatchSource::DetectorAuto => "DetectorAuto",
        }
    }

    pub fn from_str_opt(s: &str) -> Option<Self> {
        match s {
            "Synthetic" => Some(PatchSource::Synthetic),
            "User" => Some(PatchSource::User),
            "DetectorAuto" => Some(PatchSource::DetectorAuto),
            _ => None,
        }
    }
}
