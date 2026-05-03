//! Bibliotheks-Wurzel des `omr-labeler`-Crates.
//!
//! Re-exportiert die Module, sodass Tests und andere Crates auf die
//! Pipeline, Queue, Persistenz und API zugreifen können.

pub mod active_learning;
pub mod api;
pub mod classes;
pub mod frontend;
pub mod persistence;
pub mod pipeline;
pub mod synthetic_warmup;
