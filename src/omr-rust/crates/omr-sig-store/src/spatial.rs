//! R*-Tree-Spatial-Index für Inters im SIG.
//!
//! Der Index wird beim `load_sig()` aus SQLite rekonstruiert —
//! kein separates Persistieren nötig.

use omr_sig::InterId;
use rstar::{RTree, RTreeObject, AABB};

/// Ein Eintrag im Spatial-Index: verknüpft eine InterId mit ihrer Bounding-Box.
#[derive(Clone, Debug)]
pub struct SpatialEntry {
    /// Stabile ID des Inters.
    pub inter_id: InterId,
    /// Bounding-Box: [x, y, w, h].
    pub bbox: [u32; 4],
}

impl RTreeObject for SpatialEntry {
    type Envelope = AABB<[f32; 2]>;

    fn envelope(&self) -> Self::Envelope {
        AABB::from_corners(
            [self.bbox[0] as f32, self.bbox[1] as f32],
            [
                (self.bbox[0] + self.bbox[2]) as f32,
                (self.bbox[1] + self.bbox[3]) as f32,
            ],
        )
    }
}

/// Baut einen RTree aus einer Liste von SpatialEntry (Bulk-Load für Effizienz).
pub(crate) fn build_spatial_index(entries: Vec<SpatialEntry>) -> RTree<SpatialEntry> {
    RTree::bulk_load(entries)
}

/// Liefert alle Inters, deren Bounding-Box das Query-Rechteck schneidet.
pub(crate) fn query_rect(
    tree: &RTree<SpatialEntry>,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
) -> Vec<InterId> {
    let query_envelope = AABB::from_corners(
        [x as f32, y as f32],
        [(x + w) as f32, (y + h) as f32],
    );
    tree.locate_in_envelope_intersecting(&query_envelope)
        .map(|e| e.inter_id)
        .collect()
}
