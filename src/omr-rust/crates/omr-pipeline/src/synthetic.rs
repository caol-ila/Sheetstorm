// Synthetic-Score-Builder mit vollstaendiger Ground-Truth.
//
// Builder-API:
//   let mut b = ScoreBuilder::new(width, height, spacing, top_y, 'G');
//   b.add_staff();
//   b.add_clef();
//   let n0 = b.add_note(80.0, 'C', 4, NoteKind::Filled, 1.0, true);
//   let n1 = b.add_note(160.0, 'D', 4, NoteKind::Filled, 0.5, true);
//   b.add_beam(n0, n1, 4.0);
//   b.add_barline(800.0);
//   let (image, gt) = b.build();
//
// Die GroundTruth hat pixel-genaue Positionen aller Symbole, gegen die
// wir die Pipeline-Detections messen.

use image::{GrayImage, ImageBuffer, Luma};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NoteKind {
    Filled,
    Open,
    Whole,
}

#[derive(Debug, Clone, Copy)]
pub struct GtNotehead {
    pub center_x: f32,
    pub center_y: f32,
    pub kind: NoteKind,
    pub step: char,
    pub octave: i8,
    pub alter: i8,
    pub duration_quarters: f32,
}

#[derive(Debug, Clone, Copy)]
pub struct GtStem {
    pub x: f32,
    pub y_top: f32,
    pub y_bot: f32,
    pub note_idx: usize,
}

#[derive(Debug, Clone, Copy)]
pub struct GtBeam {
    pub x_start: f32,
    pub x_end: f32,
    pub y: f32,
    pub thickness: f32,
}

#[derive(Debug, Clone, Copy)]
pub struct GtBar {
    pub x: f32,
}

#[derive(Debug, Clone)]
pub struct GroundTruth {
    pub width: u32,
    pub height: u32,
    pub spacing: f32,
    pub staff_top_y: u32,
    pub clef: char,
    pub time_beats: u32,
    pub time_beat_type: u32,
    pub key_fifths: i32,
    pub noteheads: Vec<GtNotehead>,
    pub stems: Vec<GtStem>,
    pub beams: Vec<GtBeam>,
    pub bars: Vec<GtBar>,
}

pub struct ScoreBuilder {
    img: GrayImage,
    spacing: f32,
    staff_top_y: u32,
    width: u32,
    height: u32,
    clef: char,
    gt: GroundTruth,
}

impl ScoreBuilder {
    pub fn new(width: u32, height: u32, spacing: f32, staff_top_y: u32, clef: char) -> Self {
        let img = ImageBuffer::from_pixel(width, height, Luma([255u8]));
        let gt = GroundTruth {
            width,
            height,
            spacing,
            staff_top_y,
            clef,
            time_beats: 4,
            time_beat_type: 4,
            key_fifths: 0,
            noteheads: Vec::new(),
            stems: Vec::new(),
            beams: Vec::new(),
            bars: Vec::new(),
        };
        Self { img, spacing, staff_top_y, width, height, clef, gt }
    }

    pub fn with_time(mut self, beats: u32, beat_type: u32) -> Self {
        self.gt.time_beats = beats;
        self.gt.time_beat_type = beat_type;
        self
    }

    pub fn add_staff(&mut self) {
        for i in 0..5u32 {
            let y = self.staff_top_y + (i as f32 * self.spacing) as u32;
            for x in 5..(self.width - 5) {
                for ty in 0..2u32 {
                    if y + ty < self.height {
                        self.img.put_pixel(x, y + ty, Luma([0]));
                    }
                }
            }
        }
    }

    pub fn add_clef(&mut self) {
        let cx = 18u32;
        let top = self.staff_top_y;
        let bot = top + (self.spacing * 4.0) as u32;
        match self.clef {
            'G' => {
                let h = bot - top + (self.spacing * 3.0) as u32;
                let pseudo_top = top.saturating_sub((self.spacing * 1.5) as u32);
                for y in pseudo_top..pseudo_top + h {
                    if y < self.height {
                        for tx in 0..3u32 {
                            self.img.put_pixel(cx + tx, y, Luma([0]));
                        }
                    }
                }
                let loop_cy = top + (self.spacing * 3.0) as u32;
                let r = (self.spacing * 1.0) as i32;
                for ang in 0..360 {
                    let rad = (ang as f32).to_radians();
                    let px = (cx as i32 + r) + ((r as f32) * rad.cos()) as i32;
                    let py = loop_cy as i32 + ((r as f32) * rad.sin()) as i32;
                    if px > 0 && py > 0 && (px as u32) < self.width && (py as u32) < self.height {
                        self.img.put_pixel(px as u32, py as u32, Luma([0]));
                    }
                }
            }
            'F' => {
                let r = (self.spacing * 1.5) as i32;
                let cy = top + (self.spacing * 1.0) as u32;
                for ang in 0..360 {
                    let rad = (ang as f32).to_radians();
                    let px = cx as i32 + (r as f32 * rad.cos() * 0.7) as i32;
                    let py = cy as i32 + (r as f32 * rad.sin() * 0.7) as i32;
                    if px > 0 && py > 0 && (px as u32) < self.width && (py as u32) < self.height {
                        self.img.put_pixel(px as u32, py as u32, Luma([0]));
                    }
                }
                for off in 0..2 {
                    let px = cx as i32 + (self.spacing * 1.5) as i32;
                    let py = cy as i32 + off as i32 * (self.spacing as i32);
                    for dx in 0..2 {
                        for dy in 0..2 {
                            let xx = px + dx;
                            let yy = py + dy;
                            if xx > 0 && yy > 0 && (xx as u32) < self.width && (yy as u32) < self.height {
                                self.img.put_pixel(xx as u32, yy as u32, Luma([0]));
                            }
                        }
                    }
                }
            }
            _ => {}
        }
    }

    fn y_for_pitch(&self, step: char, octave: i8) -> f32 {
        let halftones_below_top = match self.clef {
            'G' => match (step, octave) {
                ('F', 5) => 0.0,
                ('E', 5) => 1.0,
                ('D', 5) => 2.0,
                ('C', 5) => 3.0,
                ('B', 4) => 4.0,
                ('A', 4) => 5.0,
                ('G', 4) => 6.0,
                ('F', 4) => 7.0,
                ('E', 4) => 8.0,
                ('D', 4) => 9.0,
                ('C', 4) => 10.0,
                ('B', 3) => 11.0,
                ('A', 3) => 12.0,
                _ => 8.0,
            },
            'F' => match (step, octave) {
                ('A', 3) => 0.0,
                ('G', 3) => 1.0,
                ('F', 3) => 2.0,
                ('E', 3) => 3.0,
                ('D', 3) => 4.0,
                ('C', 3) => 5.0,
                ('B', 2) => 6.0,
                ('A', 2) => 7.0,
                ('G', 2) => 8.0,
                _ => 5.0,
            },
            _ => 5.0,
        };
        self.staff_top_y as f32 + halftones_below_top * (self.spacing * 0.5)
    }

    pub fn add_note(
        &mut self,
        center_x: f32,
        step: char,
        octave: i8,
        kind: NoteKind,
        duration_quarters: f32,
        with_stem: bool,
    ) -> usize {
        let center_y = self.y_for_pitch(step, octave);
        let nh_w = (self.spacing * 1.3) as u32;
        let nh_h = (self.spacing * 0.95) as u32;
        let nh_x = (center_x as u32).saturating_sub(nh_w / 2);
        let nh_y = (center_y as u32).saturating_sub(nh_h / 2);

        match kind {
            NoteKind::Filled => self.draw_filled_ellipse(nh_x, nh_y, nh_w, nh_h),
            NoteKind::Open => self.draw_open_ellipse(nh_x, nh_y, nh_w, nh_h),
            NoteKind::Whole => self.draw_open_ellipse(nh_x, nh_y, (nh_w as f32 * 1.2) as u32, nh_h),
        }

        let note_idx = self.gt.noteheads.len();
        self.gt.noteheads.push(GtNotehead {
            center_x,
            center_y,
            kind,
            step,
            octave,
            alter: 0,
            duration_quarters,
        });

        if with_stem && kind != NoteKind::Whole {
            let middle_y = self.staff_top_y as f32 + 2.0 * self.spacing;
            let stem_up = center_y > middle_y;
            let stem_x = if stem_up { nh_x + nh_w - 1 } else { nh_x };
            let stem_len = (self.spacing * 3.5) as u32;
            let (y_top, y_bot) = if stem_up {
                let top = nh_y.saturating_sub(stem_len);
                (top, nh_y + nh_h / 2)
            } else {
                (nh_y + nh_h / 2, (nh_y + stem_len).min(self.height - 1))
            };
            for y in y_top..=y_bot {
                if y < self.height {
                    self.img.put_pixel(stem_x, y, Luma([0]));
                    if stem_x + 1 < self.width {
                        self.img.put_pixel(stem_x + 1, y, Luma([0]));
                    }
                }
            }
            self.gt.stems.push(GtStem {
                x: stem_x as f32,
                y_top: y_top as f32,
                y_bot: y_bot as f32,
                note_idx,
            });
        }
        note_idx
    }

    pub fn add_beam(&mut self, note_idx_a: usize, note_idx_b: usize, beam_offset: f32) {
        let stem_a = self.gt.stems.iter().find(|s| s.note_idx == note_idx_a).copied();
        let stem_b = self.gt.stems.iter().find(|s| s.note_idx == note_idx_b).copied();
        if let (Some(sa), Some(sb)) = (stem_a, stem_b) {
            let nh_a = self.gt.noteheads[note_idx_a];
            let middle_y = self.staff_top_y as f32 + 2.0 * self.spacing;
            let stem_up = nh_a.center_y > middle_y;
            let beam_y = if stem_up {
                sa.y_top + beam_offset
            } else {
                sa.y_bot - beam_offset
            };
            let thickness = self.spacing * 0.45;
            let x_start = sa.x.min(sb.x) as u32;
            let x_end = sa.x.max(sb.x) as u32 + 1;
            let y_top = beam_y as u32;
            let y_bot = (beam_y + thickness) as u32;
            for y in y_top..=y_bot {
                for x in x_start..=x_end {
                    if x < self.width && y < self.height {
                        self.img.put_pixel(x, y, Luma([0]));
                    }
                }
            }
            self.gt.beams.push(GtBeam {
                x_start: x_start as f32,
                x_end: x_end as f32,
                y: beam_y,
                thickness,
            });
        }
    }

    pub fn add_barline(&mut self, x: f32) {
        let xi = x as u32;
        let top = self.staff_top_y;
        let bot = top + (self.spacing * 4.0) as u32;
        for y in top..=bot.min(self.height - 1) {
            self.img.put_pixel(xi, y, Luma([0]));
            if xi + 1 < self.width {
                self.img.put_pixel(xi + 1, y, Luma([0]));
            }
        }
        self.gt.bars.push(GtBar { x });
    }

    fn draw_filled_ellipse(&mut self, x: u32, y: u32, w: u32, h: u32) {
        let cx = x as f32 + w as f32 / 2.0;
        let cy = y as f32 + h as f32 / 2.0;
        let rx = w as f32 / 2.0;
        let ry = h as f32 / 2.0;
        for dy in 0..h {
            for dx in 0..w {
                let xx = x + dx;
                let yy = y + dy;
                if xx >= self.width || yy >= self.height { continue; }
                let nx = (xx as f32 + 0.5 - cx) / rx;
                let ny = (yy as f32 + 0.5 - cy) / ry;
                if nx * nx + ny * ny <= 1.0 {
                    self.img.put_pixel(xx, yy, Luma([0]));
                }
            }
        }
    }

    fn draw_open_ellipse(&mut self, x: u32, y: u32, w: u32, h: u32) {
        let cx = x as f32 + w as f32 / 2.0;
        let cy = y as f32 + h as f32 / 2.0;
        let rx = w as f32 / 2.0;
        let ry = h as f32 / 2.0;
        // Outline-Dicke 0.18*spacing — robust gegen Staff-Removal.
        // Dünner Rand wuerde von Staff-Removal aufgebrochen werden.
        let rx_in = rx * 0.62;
        let ry_in = ry * 0.50;
        for dy in 0..h {
            for dx in 0..w {
                let xx = x + dx;
                let yy = y + dy;
                if xx >= self.width || yy >= self.height { continue; }
                let nx = (xx as f32 + 0.5 - cx) / rx;
                let ny = (yy as f32 + 0.5 - cy) / ry;
                let inside = nx * nx + ny * ny <= 1.0;
                let nx_i = (xx as f32 + 0.5 - cx) / rx_in;
                let ny_i = (yy as f32 + 0.5 - cy) / ry_in;
                let inner = nx_i * nx_i + ny_i * ny_i <= 1.0;
                if inside && !inner {
                    self.img.put_pixel(xx, yy, Luma([0]));
                }
            }
        }
    }

    pub fn build(self) -> (GrayImage, GroundTruth) {
        (self.img, self.gt)
    }
}

// === Standard-Generatoren ===

pub fn corpus_basic_quarters() -> (GrayImage, GroundTruth) {
    let mut b = ScoreBuilder::new(700, 220, 16.0, 60, 'G');
    b.add_staff();
    b.add_clef();
    let pitches = [('C', 4), ('D', 4), ('E', 4), ('F', 4), ('G', 4), ('A', 4), ('B', 4), ('C', 5)];
    for (i, &(s, o)) in pitches.iter().enumerate() {
        let x = 80.0 + i as f32 * 70.0;
        b.add_note(x, s, o, NoteKind::Filled, 1.0, true);
    }
    b.build()
}

pub fn corpus_quarters_with_bars() -> (GrayImage, GroundTruth) {
    let mut b = ScoreBuilder::new(900, 220, 16.0, 60, 'G');
    b.add_staff();
    b.add_clef();
    let pitches = [('C', 4), ('D', 4), ('E', 4), ('F', 4), ('G', 4), ('A', 4), ('B', 4), ('C', 5)];
    for (i, &(s, o)) in pitches.iter().enumerate() {
        let x = 80.0 + i as f32 * 90.0;
        b.add_note(x, s, o, NoteKind::Filled, 1.0, true);
    }
    b.add_barline(80.0 + 3.5 * 90.0 + 25.0);
    b.add_barline(80.0 + 7.5 * 90.0 + 25.0);
    b.build()
}

pub fn corpus_eighth_beams() -> (GrayImage, GroundTruth) {
    let mut b = ScoreBuilder::new(900, 240, 18.0, 80, 'G');
    b.add_staff();
    b.add_clef();
    let pitches = [('C', 4), ('D', 4), ('E', 4), ('F', 4), ('G', 4), ('A', 4), ('B', 4), ('C', 5)];
    let mut indices = Vec::new();
    for (i, &(s, o)) in pitches.iter().enumerate() {
        let x = 80.0 + i as f32 * 90.0;
        let idx = b.add_note(x, s, o, NoteKind::Filled, 0.5, true);
        indices.push(idx);
    }
    b.add_beam(indices[0], indices[1], 4.0);
    b.add_beam(indices[2], indices[3], 4.0);
    b.add_beam(indices[4], indices[5], 4.0);
    b.add_beam(indices[6], indices[7], 4.0);
    b.add_barline(810.0);
    b.build()
}

pub fn corpus_mixed_durations() -> (GrayImage, GroundTruth) {
    let mut b = ScoreBuilder::new(900, 220, 16.0, 60, 'G');
    b.add_staff();
    b.add_clef();
    b.add_note(120.0, 'C', 5, NoteKind::Whole, 4.0, false);
    b.add_barline(220.0);
    b.add_note(280.0, 'D', 5, NoteKind::Open, 2.0, true);
    b.add_note(380.0, 'E', 5, NoteKind::Open, 2.0, true);
    b.add_barline(450.0);
    b.add_note(490.0, 'C', 4, NoteKind::Filled, 1.0, true);
    b.add_note(560.0, 'D', 4, NoteKind::Filled, 1.0, true);
    b.add_note(630.0, 'E', 4, NoteKind::Filled, 1.0, true);
    b.add_note(700.0, 'F', 4, NoteKind::Filled, 1.0, true);
    b.add_barline(770.0);
    b.build()
}

// === Noise-Simulation ===

#[derive(Debug, Clone, Copy)]
pub struct NoiseProfile {
    pub salt_pepper: f32,
    pub gauss_blur_sigma: f32,
    pub rotation_deg: f32,
}

impl NoiseProfile {
    pub const CLEAN: Self = Self { salt_pepper: 0.0, gauss_blur_sigma: 0.0, rotation_deg: 0.0 };
    pub const SCAN_LIGHT: Self = Self { salt_pepper: 0.005, gauss_blur_sigma: 0.5, rotation_deg: 0.3 };
    pub const SCAN_MEDIUM: Self = Self { salt_pepper: 0.012, gauss_blur_sigma: 0.8, rotation_deg: 0.5 };
    pub const SCAN_HEAVY: Self = Self { salt_pepper: 0.02, gauss_blur_sigma: 1.0, rotation_deg: 0.8 };
    pub const PHOTOCOPY: Self = Self { salt_pepper: 0.04, gauss_blur_sigma: 1.0, rotation_deg: 1.5 };
}

pub fn apply_noise(img: &GrayImage, profile: NoiseProfile) -> GrayImage {
    let (w, h) = (img.width(), img.height());
    let mut out = img.clone();

    if profile.salt_pepper > 0.0 {
        let mut state = 12345u64;
        for y in 0..h {
            for x in 0..w {
                state = state
                    .wrapping_mul(6364136223846793005)
                    .wrapping_add(1442695040888963407);
                let r = (state >> 32) as u32 & 0xFFFF;
                let f = r as f32 / 65535.0;
                if f < profile.salt_pepper {
                    let val = if (state & 1) == 0 { 0u8 } else { 255u8 };
                    out.put_pixel(x, y, Luma([val]));
                }
            }
        }
    }

    if profile.gauss_blur_sigma > 0.0 {
        out = imageproc::filter::gaussian_blur_f32(&out, profile.gauss_blur_sigma);
    }

    if profile.rotation_deg.abs() > 0.05 {
        out = rotate_subtle(&out, profile.rotation_deg);
    }

    out
}

fn rotate_subtle(img: &GrayImage, angle_deg: f32) -> GrayImage {
    let (w, h) = (img.width(), img.height());
    let rad = angle_deg.to_radians();
    let cos = rad.cos();
    let sin = rad.sin();
    let cx = w as f32 / 2.0;
    let cy = h as f32 / 2.0;
    let mut out = ImageBuffer::from_pixel(w, h, Luma([255u8]));
    for y in 0..h {
        for x in 0..w {
            let dx = x as f32 - cx;
            let dy = y as f32 - cy;
            let sx = cos * dx + sin * dy + cx;
            let sy = -sin * dx + cos * dy + cy;
            if sx >= 0.0 && sy >= 0.0 && sx < w as f32 && sy < h as f32 {
                let p = img.get_pixel(sx as u32, sy as u32);
                out.put_pixel(x, y, *p);
            }
        }
    }
    out
}

// === Backwards-compat ===

pub fn add_scanner_noise(img: &GrayImage, noise_level: f32) -> GrayImage {
    apply_noise(img, NoiseProfile { salt_pepper: noise_level, gauss_blur_sigma: 0.8, rotation_deg: 0.0 })
}

pub struct SyntheticScore {
    pub image: GrayImage,
    pub expected_pitches: Vec<(char, i8, i8)>,
}

pub fn c_major_scale_treble() -> SyntheticScore {
    let (image, gt) = corpus_basic_quarters();
    let expected_pitches = gt
        .noteheads
        .iter()
        .map(|n| (n.step, n.alter, n.octave))
        .collect();
    SyntheticScore { image, expected_pitches }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_quarters_has_8_notes() {
        let (_, gt) = corpus_basic_quarters();
        assert_eq!(gt.noteheads.len(), 8);
        assert_eq!(gt.stems.len(), 8);
    }

    #[test]
    fn beam_corpus_has_beams() {
        let (_, gt) = corpus_eighth_beams();
        assert_eq!(gt.beams.len(), 4);
    }

    #[test]
    fn mixed_durations_has_one_whole() {
        let (_, gt) = corpus_mixed_durations();
        assert_eq!(gt.noteheads.iter().filter(|n| matches!(n.kind, NoteKind::Whole)).count(), 1);
        assert_eq!(gt.bars.len(), 3);
    }

    #[test]
    fn legacy_c_major_compat() {
        let s = c_major_scale_treble();
        assert_eq!(s.expected_pitches.len(), 8);
    }
}
