//! Persistent patch+embedding corpus backed by SQLite.
//!
//! Schema: a single `patches` table with all metadata plus an optional BLOB
//! column for the f32 embedding vector (little-endian).

use std::collections::HashMap;
use std::path::Path;

use rusqlite::{Connection, params};

use crate::index::EmbeddingIndex;
use crate::types::{ClassLabel, Embedding, PatchSource};

// ── Schema ────────────────────────────────────────────────────────────────────

const SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS patches (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    label            TEXT    NOT NULL,
    source           TEXT    NOT NULL,
    patch_png        BLOB    NOT NULL,
    embedding_version TEXT,
    embedding_vec    BLOB,
    provenance       TEXT,
    created_at       TEXT    NOT NULL,
    user_confirmed   INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_patches_label  ON patches(label);
CREATE INDEX IF NOT EXISTS idx_patches_source ON patches(source);
"#;

// ── LabeledPatch ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct LabeledPatch {
    pub id: u64,
    pub label: ClassLabel,
    pub source: PatchSource,
    /// 64×64 grayscale PNG bytes.
    pub patch_png: Vec<u8>,
    /// Embedding, if already computed.
    pub embedding: Option<Embedding>,
    /// Original file path or synthetic-pattern-id.
    pub provenance: String,
    /// ISO-8601 creation timestamp.
    pub created_at: String,
    pub user_confirmed: bool,
}

// ── CorpusError ───────────────────────────────────────────────────────────────

#[derive(thiserror::Error, Debug)]
pub enum CorpusError {
    #[error("SQLite error: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error("Patch {0} not found")]
    NotFound(u64),
    #[error("Unknown PatchSource string: '{0}'")]
    UnknownSource(String),
    #[error("Encoder version mismatch: corpus has '{corpus_version}', required '{required_version}'")]
    EncoderMismatch { corpus_version: String, required_version: String },
}

// ── Corpus ────────────────────────────────────────────────────────────────────

pub struct Corpus {
    conn: Connection,
}

impl Corpus {
    /// Open (or create) a corpus at `path`.
    pub fn open(path: &Path) -> Result<Self, CorpusError> {
        let conn = Connection::open(path)?;
        conn.execute_batch(SCHEMA)?;
        Ok(Self { conn })
    }

    /// Open an in-memory corpus (useful for tests).
    pub fn open_in_memory() -> Result<Self, CorpusError> {
        let conn = Connection::open_in_memory()?;
        conn.execute_batch(SCHEMA)?;
        Ok(Self { conn })
    }

    // ── Write ops ─────────────────────────────────────────────────────────────

    /// Insert a patch and return the assigned ID.
    pub fn add_patch(&mut self, patch: LabeledPatch) -> Result<u64, CorpusError> {
        let (emb_version, emb_vec): (Option<String>, Option<Vec<u8>>) =
            match &patch.embedding {
                Some(e) => (Some(e.version.clone()), Some(f32s_to_bytes(&e.vec))),
                None => (None, None),
            };
        self.conn.execute(
            r#"INSERT INTO patches
               (label, source, patch_png, embedding_version, embedding_vec,
                provenance, created_at, user_confirmed)
               VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)"#,
            params![
                patch.label,
                patch.source.as_str(),
                patch.patch_png,
                emb_version,
                emb_vec,
                patch.provenance,
                patch.created_at,
                patch.user_confirmed as i32,
            ],
        )?;
        Ok(self.conn.last_insert_rowid() as u64)
    }

    /// Retrieve a patch by ID.
    pub fn get_patch(&self, id: u64) -> Result<LabeledPatch, CorpusError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, label, source, patch_png, embedding_version, embedding_vec,
                    provenance, created_at, user_confirmed
             FROM patches WHERE id = ?1",
        )?;
        let result = stmt.query_row(params![id as i64], row_to_patch);
        match result {
            Ok(p) => Ok(p),
            Err(rusqlite::Error::QueryReturnedNoRows) => Err(CorpusError::NotFound(id)),
            Err(e) => Err(CorpusError::Sqlite(e)),
        }
    }

    /// Delete a patch by ID.
    pub fn delete_patch(&mut self, id: u64) -> Result<(), CorpusError> {
        let affected = self.conn.execute(
            "DELETE FROM patches WHERE id = ?1",
            params![id as i64],
        )?;
        if affected == 0 {
            return Err(CorpusError::NotFound(id));
        }
        Ok(())
    }

    // ── Read ops ──────────────────────────────────────────────────────────────

    /// Count patches per label.
    pub fn count_by_label(&self) -> Result<HashMap<ClassLabel, usize>, CorpusError> {
        let mut stmt = self.conn.prepare(
            "SELECT label, COUNT(*) FROM patches GROUP BY label",
        )?;
        let map = stmt
            .query_map([], |row| {
                let label: String = row.get(0)?;
                let count: i64 = row.get(1)?;
                Ok((label, count as usize))
            })?
            .collect::<Result<HashMap<_, _>, _>>()?;
        Ok(map)
    }

    /// Count patches per source.
    pub fn count_by_source(&self) -> Result<HashMap<PatchSource, usize>, CorpusError> {
        let mut stmt = self.conn.prepare(
            "SELECT source, COUNT(*) FROM patches GROUP BY source",
        )?;
        let rows: Vec<(String, usize)> = stmt
            .query_map([], |row| {
                let s: String = row.get(0)?;
                let c: i64 = row.get(1)?;
                Ok((s, c as usize))
            })?
            .collect::<Result<_, _>>()?;
        let mut map = HashMap::new();
        for (s, c) in rows {
            let src = PatchSource::from_str_opt(&s)
                .ok_or_else(|| CorpusError::UnknownSource(s))?;
            map.insert(src, c);
        }
        Ok(map)
    }

    /// Iterate all patches with the given label (collected to avoid borrow issues).
    pub fn iter_with_label(&self, label: &str) -> impl Iterator<Item = LabeledPatch> {
        let patches = self.collect_where("WHERE label = ?1", params![label]);
        patches.into_iter()
    }

    /// Iterate all patches.
    pub fn iter_all(&self) -> impl Iterator<Item = LabeledPatch> {
        let patches = self.collect_where("", params![]);
        patches.into_iter()
    }

    // ── Index building ────────────────────────────────────────────────────────

    /// Build an `EmbeddingIndex` from patches that have an embedding with the
    /// given version.  Patches without embeddings are silently skipped.
    pub fn into_index(&self, version: &str) -> Result<EmbeddingIndex, CorpusError> {
        use crate::encoder::FEATURE_LEN;
        let mut idx = EmbeddingIndex::new(version, FEATURE_LEN);
        let mut stmt = self.conn.prepare(
            "SELECT id, label, source, embedding_version, embedding_vec
             FROM patches
             WHERE embedding_version = ?1 AND embedding_vec IS NOT NULL",
        )?;
        let rows: Vec<(u64, String, String, Vec<u8>)> = stmt
            .query_map(params![version], |row| {
                let id: i64 = row.get(0)?;
                let label: String = row.get(1)?;
                let source: String = row.get(2)?;
                let vec_bytes: Vec<u8> = row.get(4)?;
                Ok((id as u64, label, source, vec_bytes))
            })?
            .collect::<Result<_, _>>()?;

        for (id, label, source_str, vec_bytes) in rows {
            let source = PatchSource::from_str_opt(&source_str)
                .ok_or_else(|| CorpusError::UnknownSource(source_str))?;
            let emb = Embedding {
                vec: bytes_to_f32s(&vec_bytes),
                version: version.to_string(),
            };
            // Ignore add errors — wrong dim embeddings in corpus are skipped
            let _ = idx.add(id, &emb, label, source);
        }
        idx.build();
        Ok(idx)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    fn collect_where(&self, where_clause: &str, params: impl rusqlite::Params) -> Vec<LabeledPatch> {
        let sql = format!(
            "SELECT id, label, source, patch_png, embedding_version, embedding_vec,
                    provenance, created_at, user_confirmed
             FROM patches {}",
            where_clause
        );
        let mut stmt = match self.conn.prepare(&sql) {
            Ok(s) => s,
            Err(_) => return Vec::new(),
        };
        stmt.query_map(params, row_to_patch)
            .map(|rows| rows.flatten().collect())
            .unwrap_or_default()
    }
}

// ── Row deserialiser ──────────────────────────────────────────────────────────

fn row_to_patch(row: &rusqlite::Row<'_>) -> rusqlite::Result<LabeledPatch> {
    let id: i64 = row.get(0)?;
    let label: String = row.get(1)?;
    let source_str: String = row.get(2)?;
    let patch_png: Vec<u8> = row.get(3)?;
    let emb_version: Option<String> = row.get(4)?;
    let emb_bytes: Option<Vec<u8>> = row.get(5)?;
    let provenance: Option<String> = row.get(6)?;
    let created_at: String = row.get(7)?;
    let confirmed: i32 = row.get(8)?;

    let source = PatchSource::from_str_opt(&source_str)
        .unwrap_or(PatchSource::Synthetic);

    let embedding = match (emb_version, emb_bytes) {
        (Some(ver), Some(bytes)) => Some(Embedding {
            vec: bytes_to_f32s(&bytes),
            version: ver,
        }),
        _ => None,
    };

    Ok(LabeledPatch {
        id: id as u64,
        label,
        source,
        patch_png,
        embedding,
        provenance: provenance.unwrap_or_default(),
        created_at,
        user_confirmed: confirmed != 0,
    })
}

// ── Serialisation helpers ─────────────────────────────────────────────────────

fn f32s_to_bytes(v: &[f32]) -> Vec<u8> {
    v.iter().flat_map(|f| f.to_le_bytes()).collect()
}

fn bytes_to_f32s(b: &[u8]) -> Vec<f32> {
    b.chunks_exact(4)
        .map(|c| f32::from_le_bytes([c[0], c[1], c[2], c[3]]))
        .collect()
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::encoder::{Encoder, HogEncoder, FEATURE_LEN};
    use image::{GrayImage, Luma};

    fn dummy_patch(label: &str, source: PatchSource, embedding: Option<Embedding>) -> LabeledPatch {
        let png = tiny_png();
        LabeledPatch {
            id: 0,
            label: label.to_string(),
            source,
            patch_png: png,
            embedding,
            provenance: "test".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            user_confirmed: false,
        }
    }

    fn tiny_png() -> Vec<u8> {
        let img = GrayImage::from_pixel(64, 64, Luma([128u8]));
        let mut buf = Vec::new();
        img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png).unwrap();
        buf
    }

    fn hog_embedding(v: u8) -> Embedding {
        let enc = HogEncoder::new();
        let img = GrayImage::from_pixel(64, 64, Luma([v]));
        enc.embed(&img).unwrap()
    }

    #[test]
    fn add_patch_assigns_id() {
        let mut corpus = Corpus::open_in_memory().unwrap();
        let p = dummy_patch("notehead", PatchSource::Synthetic, None);
        let id = corpus.add_patch(p).unwrap();
        assert!(id > 0, "expected id > 0, got {id}");
    }

    #[test]
    fn count_by_label_correct() {
        let mut corpus = Corpus::open_in_memory().unwrap();
        corpus.add_patch(dummy_patch("a", PatchSource::Synthetic, None)).unwrap();
        corpus.add_patch(dummy_patch("a", PatchSource::User, None)).unwrap();
        corpus.add_patch(dummy_patch("b", PatchSource::Synthetic, None)).unwrap();
        let counts = corpus.count_by_label().unwrap();
        assert_eq!(counts["a"], 2);
        assert_eq!(counts["b"], 1);
    }

    #[test]
    fn iter_with_label_filters() {
        let mut corpus = Corpus::open_in_memory().unwrap();
        corpus.add_patch(dummy_patch("notehead", PatchSource::Synthetic, None)).unwrap();
        corpus.add_patch(dummy_patch("rest", PatchSource::Synthetic, None)).unwrap();
        corpus.add_patch(dummy_patch("notehead", PatchSource::User, None)).unwrap();
        let notes: Vec<_> = corpus.iter_with_label("notehead").collect();
        assert_eq!(notes.len(), 2, "expected 2 noteheads, got {}", notes.len());
        for p in &notes {
            assert_eq!(p.label, "notehead");
        }
    }

    #[test]
    fn into_index_skips_patches_without_embedding() {
        let mut corpus = Corpus::open_in_memory().unwrap();
        // Patch without embedding
        corpus.add_patch(dummy_patch("x", PatchSource::Synthetic, None)).unwrap();
        // Patch with embedding
        let emb = hog_embedding(64);
        corpus.add_patch(dummy_patch("y", PatchSource::Synthetic, Some(emb))).unwrap();

        let idx = corpus.into_index("hog-v1").unwrap();
        // Only the patch with embedding should be in the index
        assert_eq!(idx.corpus_size(), 1, "expected 1 in index, got {}", idx.corpus_size());
    }
}
