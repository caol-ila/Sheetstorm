// Logical Group Detection for OMR
//! Fasst atomare Erkennungsergebnisse (Noteheads, Stems, Beams) zu
//! musikalisch sinnvollen Gruppen zusammen.
use crate::beams::Beam;
use omr_core::{Notehead, Rect, Stem};

#[derive(Debug, Clone, PartialEq)]
pub enum LogicalGroupKind {
    BeamedGroup { beam_levels: u32 },
    ChordCluster { note_count: u32 },
    SingleNote,
    TiedPair,
    SlurredPhrase { note_count: u32 },
    Isolated,
}

#[derive(Debug, Clone)]
pub struct LogicalGroup {
    pub kind: LogicalGroupKind,
    pub bbox: Rect,
    pub class_id: String,
}

pub fn detect_logical_groups(
    noteheads: &[Notehead],
    _stems: &[Stem],
    beams: &[Beam],
    line_spacing: f32,
) -> Vec<LogicalGroup> {
    if noteheads.is_empty() { return vec![]; }

    let beam_levels = count_beam_levels(beams, line_spacing);
    if beam_levels > 0 {
        // All noteheads belong to one beamed group (simplified model)
        let kind = LogicalGroupKind::BeamedGroup { beam_levels };
        let bbox = union_bbox_noteheads(noteheads, beams);
        let class_id = kind_to_class_id(&kind).to_string();
        return vec![LogicalGroup { kind, bbox, class_id }];
    }

    let x_tol = 0.5 * line_spacing;
    let y_min_span = 0.4 * line_spacing;
    let mut used = vec![false; noteheads.len()];
    let mut groups: Vec<LogicalGroup> = Vec::new();

    // Phase 1: chord clusters
    for i in 0..noteheads.len() {
        if used[i] { continue; }
        let cx_i = noteheads[i].bbox.x as f32 + noteheads[i].bbox.w as f32 * 0.5;
        let mut cluster = vec![i];
        for j in (i + 1)..noteheads.len() {
            if used[j] { continue; }
            let cx_j = noteheads[j].bbox.x as f32 + noteheads[j].bbox.w as f32 * 0.5;
            if (cx_j - cx_i).abs() <= x_tol {
                cluster.push(j);
            }
        }
        if cluster.len() >= 2 {
            let min_y = cluster.iter().map(|&ci| noteheads[ci].bbox.y).min().unwrap_or(0);
            let max_y = cluster.iter().map(|&ci| noteheads[ci].bbox.y + noteheads[ci].bbox.h).max().unwrap_or(0);
            if ((max_y.saturating_sub(min_y)) as f32) >= y_min_span {
                for &ci in &cluster { used[ci] = true; }
                let note_count = cluster.len() as u32;
                let kind = LogicalGroupKind::ChordCluster { note_count };
                let bbox = union_noteheads_slice(noteheads, &cluster);
                let class_id = kind_to_class_id(&kind).to_string();
                groups.push(LogicalGroup { kind, bbox, class_id });
            }
        }
    }

    // Phase 2: single notes
    for (i, nh) in noteheads.iter().enumerate() {
        if used[i] { continue; }
        used[i] = true;
        let kind = LogicalGroupKind::SingleNote;
        let class_id = kind_to_class_id(&kind).to_string();
        groups.push(LogicalGroup { kind, bbox: nh.bbox, class_id });
    }

    groups
}

pub fn class_id_for_group(group: &LogicalGroup) -> &'static str {
    kind_to_class_id(&group.kind)
}

fn kind_to_class_id(kind: &LogicalGroupKind) -> &'static str {
    match kind {
        LogicalGroupKind::BeamedGroup { beam_levels } => match beam_levels {
            1 => "group/beamed_group_2_eighths",
            2 => "group/beamed_group_4_sixteenths",
            3 => "group/beamed_group_8_thirty_seconds",
            _ => "group/beamed_group",
        },
        LogicalGroupKind::ChordCluster { note_count } => match note_count {
            2 => "chord/2_notes",
            3 => "chord/3_notes",
            4 => "chord/4_notes",
            _ => "chord/n_notes",
        },
        LogicalGroupKind::SingleNote => "note/single",
        LogicalGroupKind::TiedPair => "group/tied_pair",
        LogicalGroupKind::SlurredPhrase { .. } => "group/slurred_phrase",
        LogicalGroupKind::Isolated => "symbol/isolated",
    }
}

pub(crate) fn count_beam_levels(beams: &[Beam], line_spacing: f32) -> u32 {
    if beams.is_empty() { return 0; }
    let band = 0.3 * line_spacing;
    let mut levels: Vec<f32> = Vec::new();
    for beam in beams {
        let cy = (beam.y_top as f32 + beam.y_bot as f32) * 0.5;
        if !levels.iter().any(|&ly| (cy - ly).abs() < band) {
            levels.push(cy);
        }
    }
    levels.len() as u32
}

fn union_bbox_noteheads(noteheads: &[Notehead], beams: &[Beam]) -> Rect {
    let x = noteheads.iter().map(|n| n.bbox.x)
        .chain(beams.iter().map(|b| b.x_start))
        .min().unwrap_or(0);
    let y = noteheads.iter().map(|n| n.bbox.y)
        .chain(beams.iter().map(|b| b.y_top))
        .min().unwrap_or(0);
    let x2 = noteheads.iter().map(|n| n.bbox.x + n.bbox.w)
        .chain(beams.iter().map(|b| b.x_end))
        .max().unwrap_or(0);
    let y2 = noteheads.iter().map(|n| n.bbox.y + n.bbox.h)
        .chain(beams.iter().map(|b| b.y_bot))
        .max().unwrap_or(0);
    Rect { x, y, w: x2.saturating_sub(x), h: y2.saturating_sub(y) }
}

fn union_noteheads_slice(noteheads: &[Notehead], indices: &[usize]) -> Rect {
    let x = indices.iter().map(|&i| noteheads[i].bbox.x).min().unwrap_or(0);
    let y = indices.iter().map(|&i| noteheads[i].bbox.y).min().unwrap_or(0);
    let x2 = indices.iter().map(|&i| noteheads[i].bbox.x + noteheads[i].bbox.w).max().unwrap_or(0);
    let y2 = indices.iter().map(|&i| noteheads[i].bbox.y + noteheads[i].bbox.h).max().unwrap_or(0);
    Rect { x, y, w: x2.saturating_sub(x), h: y2.saturating_sub(y) }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{Notehead, NoteheadKind, Point, Rect, Stem};
    use crate::beams::Beam;

    fn nh(x: u32, y: u32, w: u32, h: u32) -> Notehead {
        Notehead {
            bbox: Rect { x, y, w, h },
            center: Point { x: x as f32 + w as f32 * 0.5, y: y as f32 + h as f32 * 0.5 },
            confidence: 0.9,
            kind: NoteheadKind::Filled,
            staff_idx: 0,
        }
    }

    fn beam(x_start: u32, x_end: u32, y_top: u32, y_bot: u32) -> Beam {
        Beam { x_start, x_end, y_top, y_bot }
    }

    #[test]
    fn empty_noteheads_returns_empty() {
        let groups = detect_logical_groups(&[], &[], &[], 16.0);
        assert!(groups.is_empty());
    }

    #[test]
    fn single_notehead_becomes_single_note() {
        let noteheads = vec![nh(50, 100, 12, 12)];
        let groups = detect_logical_groups(&noteheads, &[], &[], 16.0);
        assert_eq!(groups.len(), 1);
        assert_eq!(groups[0].kind, LogicalGroupKind::SingleNote);
        assert_eq!(groups[0].class_id, "note/single");
    }

    #[test]
    fn two_noteheads_same_x_form_chord() {
        let noteheads = vec![nh(50, 100, 12, 12), nh(52, 116, 12, 12)];
        let groups = detect_logical_groups(&noteheads, &[], &[], 16.0);
        let chord = groups.iter().find(|g| matches!(g.kind, LogicalGroupKind::ChordCluster { .. }));
        assert!(chord.is_some(), "expected chord cluster");
    }

    #[test]
    fn beamed_group_with_two_beams_detected() {
        let noteheads = vec![
            nh(20, 100, 12, 12), nh(50, 102, 12, 12),
            nh(80, 98, 12, 12), nh(110, 101, 12, 12),
        ];
        let beams = vec![
            beam(20, 120, 78, 82),
            beam(20, 120, 73, 77),
        ];
        let groups = detect_logical_groups(&noteheads, &[], &beams, 16.0);
        let beamed = groups.iter().find(|g| matches!(g.kind, LogicalGroupKind::BeamedGroup { .. }));
        assert!(beamed.is_some(), "expected beamed group");
        if let LogicalGroupKind::BeamedGroup { beam_levels } = beamed.unwrap().kind {
            assert_eq!(beam_levels, 2, "expected 2 beam levels for sixteenth notes");
        }
    }

    #[test]
    fn class_id_for_beamed_group_sixteenths() {
        let group = LogicalGroup {
            kind: LogicalGroupKind::BeamedGroup { beam_levels: 2 },
            bbox: Rect { x: 0, y: 0, w: 10, h: 10 },
            class_id: "group/beamed_group_4_sixteenths".to_string(),
        };
        assert_eq!(class_id_for_group(&group), "group/beamed_group_4_sixteenths");
    }

    #[test]
    fn class_id_for_chord_three_notes() {
        let group = LogicalGroup {
            kind: LogicalGroupKind::ChordCluster { note_count: 3 },
            bbox: Rect { x: 0, y: 0, w: 10, h: 10 },
            class_id: "chord/3_notes".to_string(),
        };
        assert_eq!(class_id_for_group(&group), "chord/3_notes");
    }

    #[test]
    fn class_id_for_single_note() {
        let group = LogicalGroup {
            kind: LogicalGroupKind::SingleNote,
            bbox: Rect { x: 0, y: 0, w: 10, h: 10 },
            class_id: "note/single".to_string(),
        };
        assert_eq!(class_id_for_group(&group), "note/single");
    }

    #[test]
    fn union_bbox_spans_beams_and_noteheads() {
        let noteheads = vec![nh(10, 20, 12, 12), nh(50, 22, 12, 12)];
        let beams = vec![beam(10, 62, 15, 19)];
        let bb = union_bbox_noteheads(&noteheads, &beams);
        assert_eq!(bb.x, 10); assert_eq!(bb.y, 15);
        assert_eq!(bb.x + bb.w, 62);
    }

    #[test]
    fn count_beam_levels_two_bands() {
        let beams = vec![beam(20, 120, 78, 82), beam(20, 120, 73, 77)];
        assert_eq!(count_beam_levels(&beams, 16.0), 2);
    }
}
