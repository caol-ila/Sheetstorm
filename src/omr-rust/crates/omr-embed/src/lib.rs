//! omr-embed — Vector-Embedding-System für OMR-Symbole.
//!
//! Wandelt Symbol-Patches (64×64 Grayscale) in Embedding-Vektoren um.
//! Per HNSW-Index findet man die k-Nachbarn und aus deren Labeln eine
//! Distribution.  Füttert Phase-5 `HeadInterMulti.pitch_distribution`.

pub mod corpus;
pub mod distance;
pub mod encoder;
pub mod index;
pub mod types;

pub use encoder::{EncoderError, Encoder, HogEncoder};
pub use index::{EmbeddingIndex, IndexError, KnnResult};
pub use corpus::{Corpus, CorpusError, LabeledPatch};
pub use types::{ClassLabel, Embedding, Match};
pub use distance::{cosine, euclidean};

#[cfg(feature = "cnn")]
pub use encoder::OnnxCnnEncoder;
