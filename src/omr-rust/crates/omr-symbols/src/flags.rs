//! Flag-Detection für einzelne 8th/16th Noten (statt Beam-Group).
//!
//! Eine Flag ist ein kleiner geschwungener Bogen am STEM-TIP (Ende, weg vom Notehead).
//! Bei einer einzeln-stehenden 8th-Note: 1 Flag. Sixteenth: 2 Flags. Etc.
//!
//! Heuristik: Am Stem-Tip suchen wir Pixel die SEITLICH vom Stem stehen
//! (ausserhalb der Stem-Spalte selbst). Eine Flag erweitert den Stem nach
//! rechts (bei stem-up) oder rechts (bei stem-down) um ~1-2 Spacings.
//!
//! Anzahl Flags ergibt sich aus der Höhen-Ausdehnung der Seitenpixel:
//!   - 1 Flag: ~1 spacing hoch
//!   - 2 Flags: ~1.7 spacing hoch (zwei übereinander)
//!
//! Output: pro Stem-Index die Anzahl der Flags (0 wenn keine; integriert
//! mit beam_counts: total_count = beams + flags, used für duration).

use omr_core::{Binary, Notehead, Stem};

/// Detektiert Flags an Stems die KEINE Beams haben (d.h. einzeln-stehende 8th/16th).
///
/// Args:
///   - `bin`: Original-Binary VOR Staff-Removal (Flags sind oben/unten am Stem,
///     nicht durch Stafflinien verdeckt).
///   - `stems`: detektierte Stems.
///   - `noteheads`: zugehörige NHs (für Stem-Direction-Bestimmung).
///   - `beam_counts`: pro Stem die Anzahl Beams (0 = keine Beam-Gruppe → Flag möglich).
///   - `spacing`: line spacing.
///
/// Returns: pro Stem die Anzahl Flags. Konservativ: nur wenn deutlich erkennbar.
pub fn detect_flags(
    bin: &Binary,
    stems: &[Stem],
    noteheads: &[Notehead],
    beam_counts: &[u32],
    spacing: f32,
) -> Vec<u32> {
    let mut flags_per_stem = vec![0u32; stems.len()];

    for (i, stem) in stems.iter().enumerate() {
        // Wenn schon ein Beam an diesem Stem hängt, sind Flags ausgeschlossen.
        if beam_counts.get(i).copied().unwrap_or(0) > 0 { continue; }
        let nh_idx = match stem.notehead_idx { Some(i) => i, None => continue };
        let nh = match noteheads.get(nh_idx) { Some(n) => n, None => continue };

        // Stem-Direction: stem geht von NH-Center weg.
        // Wenn nh.center.y > stem.y_top: NH ist UNTEN, Stem geht nach OBEN (stem-up).
        // Sonst: stem-down.
        let stem_up = nh.center.y > stem.y_top as f32;

        // Stem-Tip Position (das Ende weg vom NH)
        let tip_y = if stem_up { stem.y_top } else { stem.y_bot };
        let stem_x = stem.x;

        // Search-Region: ±0.1*spacing in X (stem-Spalte), 0..2*spacing in Y vom Tip.
        // Flag erweitert den Stem nach RECHTS (in Reading-Order). Wir scannen
        // also Pixel rechts vom Stem in einem schmalen Bereich.
        let stem_w_half = 2u32; // Stem-Pixel-Breite halbiert
        let search_w = (spacing * 1.5) as u32;
        let search_h = (spacing * 2.0) as u32;
        let x0 = (stem_x.saturating_add(stem_w_half + 1)).min(bin.w);
        let x1 = (stem_x + stem_w_half + search_w).min(bin.w);

        // Y-Range: vom Tip in Richtung Stem-Mitte (gegen NH) für ~2 Spacings
        let (y0, y1) = if stem_up {
            // Stem geht nach oben, Tip ist OBEN. Suche von Tip nach UNTEN (Richtung NH).
            let y0 = tip_y;
            let y1 = (tip_y + search_h).min(bin.h);
            (y0, y1)
        } else {
            // Stem-down, Tip ist unten. Suche von Tip nach OBEN.
            let y1 = tip_y;
            let y0 = tip_y.saturating_sub(search_h);
            (y0, y1)
        };

        if x0 >= x1 || y0 >= y1 { continue; }

        // Zähle die Y-Reihen die schwarze Pixel haben (= Flag-Höhe)
        let mut flag_rows = 0u32;
        for y in y0..y1 {
            let mut has_pixel = false;
            for x in x0..x1 {
                if bin.get(x, y) != 0 { has_pixel = true; break; }
            }
            if has_pixel { flag_rows += 1; }
        }

        // Klassifikation:
        //   < 0.4 spacing: keine Flag (zu wenig)
        //   0.4 - 1.2 spacing: 1 Flag (8th)
        //   > 1.2 spacing: 2 Flags (16th)
        let flag_rows_f = flag_rows as f32;
        let n_flags = if flag_rows_f < spacing * 0.4 {
            0
        } else if flag_rows_f < spacing * 1.2 {
            1
        } else {
            2
        };
        flags_per_stem[i] = n_flags;
    }

    flags_per_stem
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, Point, Rect};

    fn mk_bin(w: u32, h: u32) -> Binary {
        Binary { w, h, data: vec![0u8; (w * h) as usize] }
    }
    fn put_pixel(bin: &mut Binary, x: u32, y: u32) {
        if x < bin.w && y < bin.h {
            let idx = (y * bin.w + x) as usize;
            bin.data[idx] = 1;
        }
    }

    fn mk_nh(x: f32, y: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: (y as u32).saturating_sub(8), w: 16, h: 16 },
            center: Point { x, y },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx: 0,
        }
    }

    fn mk_stem(x: u32, y_top: u32, y_bot: u32, nh_idx: usize) -> Stem {
        Stem { x, y_top, y_bot, notehead_idx: Some(nh_idx) }
    }

    #[test]
    fn detect_one_flag_on_stem_up() {
        let mut bin = mk_bin(200, 200);
        // NH bei (100, 150), Stem geht nach oben von (100, 142) bis (100, 100)
        // Flag: rechtes Pixel-Cluster bei x=102..108, y=100..115 (~ 0.7 spacing hoch)
        for y in 100..118 {
            for x in 102..108 { put_pixel(&mut bin, x, y); }
        }
        // Stem selbst (vertikale Linie)
        for y in 100..142 { put_pixel(&mut bin, 100, y); put_pixel(&mut bin, 101, y); }

        let nhs = vec![mk_nh(100.0, 150.0)];
        let stems = vec![mk_stem(100, 100, 142, 0)];
        let flags = detect_flags(&bin, &stems, &nhs, &[0], 18.0);
        assert_eq!(flags.len(), 1);
        assert_eq!(flags[0], 1, "expected 1 flag, got {}", flags[0]);
    }

    #[test]
    fn no_flag_when_beams_present() {
        let mut bin = mk_bin(200, 200);
        for y in 100..142 { put_pixel(&mut bin, 100, y); }
        let nhs = vec![mk_nh(100.0, 150.0)];
        let stems = vec![mk_stem(100, 100, 142, 0)];
        // beam_counts > 0 → skip flag detection
        let flags = detect_flags(&bin, &stems, &nhs, &[1], 18.0);
        assert_eq!(flags[0], 0);
    }

    #[test]
    fn no_flag_for_stem_only() {
        let mut bin = mk_bin(200, 200);
        // Stem ohne Flag-Pixel
        for y in 100..142 { put_pixel(&mut bin, 100, y); put_pixel(&mut bin, 101, y); }
        let nhs = vec![mk_nh(100.0, 150.0)];
        let stems = vec![mk_stem(100, 100, 142, 0)];
        let flags = detect_flags(&bin, &stems, &nhs, &[0], 18.0);
        assert_eq!(flags[0], 0);
    }

    #[test]
    fn detect_two_flags_for_sixteenth() {
        let mut bin = mk_bin(200, 200);
        // 16th-Flag: ~1.5 spacing hohe Pixelreihe rechts vom Stem-Tip
        for y in 100..130 {
            for x in 102..108 { put_pixel(&mut bin, x, y); }
        }
        for y in 100..142 { put_pixel(&mut bin, 100, y); put_pixel(&mut bin, 101, y); }
        let nhs = vec![mk_nh(100.0, 150.0)];
        let stems = vec![mk_stem(100, 100, 142, 0)];
        let flags = detect_flags(&bin, &stems, &nhs, &[0], 18.0);
        assert_eq!(flags[0], 2, "expected 2 flags for 16th, got {}", flags[0]);
    }
}
