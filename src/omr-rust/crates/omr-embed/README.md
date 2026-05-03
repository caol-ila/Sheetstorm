# omr-embed — Vector Embedding System for OMR Symbols

Converts symbol patches (64×64 grayscale) into dense embedding vectors.
A HNSW index provides k-NN lookup → class probability distribution.
User-confirmed examples land directly in the corpus → active-learning loop.

## Architecture

```
GrayImage (64×64)
    │
    ▼
┌─────────────────────────────┐
│  Encoder (trait)            │
│  ├── HogEncoder (no train)  │  → 1764-dim HoG descriptor
│  └── OnnxCnnEncoder*        │  → 256-dim CNN embedding
└─────────────────────────────┘
    │  Embedding { vec, version }
    ▼
┌─────────────────────────────┐
│  EmbeddingIndex             │  linear scan (default)
│  add() → build() → knn()    │  or HNSW via `hnsw` feature†
│  knn_distribution()         │  → Distribution<ClassLabel>
└─────────────────────────────┘
    ▲
┌─────────────────────────────┐
│  Corpus (SQLite)            │  rusqlite + system SQLite
│  add_patch / iter / count   │
│  into_index(version)        │  → EmbeddingIndex
└─────────────────────────────┘
```

\* requires `--features cnn`  
† requires `--features hnsw` + MinGW toolchain with dlltool

## Quick Start

```rust
use omr_embed::{HogEncoder, Encoder, EmbeddingIndex, Corpus, LabeledPatch};
use omr_embed::types::PatchSource;
use image::GrayImage;
use std::path::Path;

// 1. Encode a patch
let enc = HogEncoder::new();
let patch = GrayImage::from_pixel(64, 64, image::Luma([128u8]));
let emb = enc.embed(&patch)?;

// 2. Build an index
let mut idx = EmbeddingIndex::new("hog-v1", enc.dim());
idx.add(1, &emb, "notehead-filled".to_string(), PatchSource::Synthetic)?;
idx.build();

// 3. Query
let matches = idx.knn(&emb, 5)?;
let dist = idx.knn_distribution(&emb, 5)?;
println!("Best guess: {}", dist.argmax());

// 4. Persist corpus
let mut corpus = Corpus::open(Path::new("corpus.db"))?;
corpus.add_patch(LabeledPatch {
    id: 0,
    label: "notehead-filled".to_string(),
    source: PatchSource::User,
    patch_png: vec![/* PNG bytes */],
    embedding: Some(emb),
    provenance: "scan-2024.png".to_string(),
    created_at: "2024-01-01T00:00:00Z".to_string(),
    user_confirmed: true,
})?;

// 5. Rebuild index from corpus
let idx = corpus.into_index("hog-v1")?;
```

## Embedding Versioning

Embeddings carry a `version` tag (e.g. `"hog-v1"`, `"cnn-v3-mobilenet"`).
`EmbeddingIndex` enforces that all stored embeddings share the same version.
When migrating encoder versions, create a new corpus column and re-encode.

## Feature Flags

| Flag | Effect |
|------|--------|
| `hnsw` | Enables `instant-distance` HNSW backend (requires MinGW `dlltool` on Windows GNU) |
| `cnn` | Enables `OnnxCnnEncoder` (requires tract-onnx, ~50 MB) |

## HoG Descriptor Details

Input: 64×64 grayscale patch  
Cell: 8×8 px → 8×8 = 64 cells  
Block: 2×2 cells (16×16 px), stride 1 → 7×7 = 49 blocks  
Bins: 9 (unsigned orientation [0, π))  
Normalisation: L2-Hys per block (clip 0.2, re-normalise)  
**Output: 1764-dim f32 vector**
