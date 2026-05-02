//! # omr-sig-store
//!
//! SQLite-Persistenz für den Symbol Interpretation Graph (SIG).
//!
//! ## Features
//! - **SigStore**: `load_sig` / `save_sig` — Roundtrip-sichere Persistenz
//! - **Op-Log**: append-only SQLite-Tabelle für alle Edit-Operationen
//! - **R\*-Tree Spatial-Index**: schnelle Region-Queries (`inters_in_rect`)
//! - **Snapshots**: versionierte SIG-Kompakt-Serialisierung
//!
//! ## Quickstart
//! ```no_run
//! use omr_sig_store::SigStore;
//! use omr_sig::Sig;
//!
//! let mut store = SigStore::open_in_memory().unwrap();
//! let sig = Sig::new();
//! store.save_sig(&sig).unwrap();
//! let loaded = store.load_sig().unwrap();
//! assert_eq!(loaded.inter_count(), 0);
//! ```

#![warn(missing_docs)]

pub mod error;
mod ops;
mod schema;
pub mod spatial;
pub mod store;

pub use error::{Result, StoreError};
pub use spatial::SpatialEntry;
pub use store::SigStore;
