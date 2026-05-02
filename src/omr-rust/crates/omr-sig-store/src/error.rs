//! Fehlertypen für omr-sig-store.

/// Fehler in omr-sig-store.
#[derive(Debug, thiserror::Error)]
pub enum StoreError {
    /// SQLite-Fehler.
    #[error("SQLite error: {0}")]
    Sqlite(#[from] rusqlite::Error),

    /// JSON-Serialisierungs-/Deserialisierungsfehler.
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}

/// Ergebnis-Typ für alle Store-Operationen.
pub type Result<T, E = StoreError> = std::result::Result<T, E>;
