// Per-line Rectification
use image::{GrayImage, ImageBuffer, Luma};
use omr_core::StaffSystem;

pub const NORMALIZED_SPACING: f32 = 32.0;
const PADDING: u32 = 16;

#[derive(Debug, Clone)]
pub struct RectifiedSystem {
    pub image: GrayImage,
    pub angle_rad: f32,
    pub scale: f32,
}

pub fn rectify_all_systems(img: &GrayImage, systems: &[StaffSystem]) -> Vec<RectifiedSystem> {
    systems.iter().map(|sys| rectify_system(img, sys)).collect()
}

pub fn rectify_system(img: &GrayImage, system: &StaffSystem) -> RectifiedSystem {
    let img_w = img.width();
    let img_h = img.height();
    if system.lines.is_empty() || img_w == 0 || img_h == 0 {
        return RectifiedSystem { image: img.clone(), angle_rad: 0.0, scale: 1.0 };
    }
    let spacing = system.line_spacing.max(1.0);
    let scale = NORMALIZED_SPACING / spacing;
    let angle = estimate_skew(system);
    let top_y = system.lines.first().map(|l| l.mean_y()).unwrap_or(0.0);
    let bot_y = system.lines.last().map(|l| l.mean_y()).unwrap_or(img_h as f32);
    let sys_h = (bot_y - top_y).max(1.0);
    let out_w = (img_w as f32 * scale).round() as u32;
    let out_h = (sys_h * scale).round() as u32 + 2 * PADDING;
    let cx = img_w as f32 * 0.5;
    let cy = (top_y + bot_y) * 0.5;
    let out_cx = out_w as f32 * 0.5;
    let out_cy = out_h as f32 * 0.5;
    let cos_a = angle.cos();
    let sin_a = angle.sin();
    let fwd = [
        scale * cos_a, scale * sin_a,
        -scale * cos_a * cx - scale * sin_a * cy + out_cx,
        -scale * sin_a, scale * cos_a,
        scale * sin_a * cx - scale * cos_a * cy + out_cy,
        0.0, 0.0, 1.0_f32,
    ];
    let inv = invert_affine_3x3(&fwd);
    let image = warp_affine(img, &inv, out_w, out_h);
    RectifiedSystem { image, angle_rad: angle, scale }
}

pub(crate) fn mat3_mul(a: &[f32; 9], b: &[f32; 9]) -> [f32; 9] {
    let mut c = [0.0f32; 9];
    for r in 0..3 {
        for col in 0..3 {
            for k in 0..3 { c[r * 3 + col] += a[r * 3 + k] * b[k * 3 + col]; }
        }
    }
    c
}

pub(crate) fn invert_affine_3x3(m: &[f32; 9]) -> [f32; 9] {
    let (a, b, tx) = (m[0], m[1], m[2]);
    let (c, d, ty) = (m[3], m[4], m[5]);
    let det = a * d - b * c;
    if det.abs() < 1e-12 { return [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]; }
    let inv_det = 1.0 / det;
    let ia = d * inv_det; let ib = -b * inv_det;
    let ic = -c * inv_det; let id_ = a * inv_det;
    let itx = -(ia * tx + ib * ty); let ity = -(ic * tx + id_ * ty);
    [ia, ib, itx, ic, id_, ity, 0.0, 0.0, 1.0]
}

fn estimate_skew(system: &StaffSystem) -> f32 {
    let mid_idx = system.lines.len() / 2;
    let line = &system.lines[mid_idx];
    let yy = &line.y_per_x;
    if yy.len() < 2 { return 0.0; }
    let step = (yy.len() / 200).max(1);
    let (mut sum_x, mut sum_y, mut sum_xx, mut sum_xy, mut n) =
        (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    for (xi, &yi) in yy.iter().enumerate().step_by(step) {
        let (xf, yf) = (xi as f64, yi as f64);
        sum_x += xf; sum_y += yf; sum_xx += xf * xf; sum_xy += xf * yf; n += 1.0;
    }
    let denom = n * sum_xx - sum_x * sum_x;
    if denom.abs() < 1e-12 { return 0.0; }
    (((n * sum_xy - sum_x * sum_y) / denom) as f32).atan()
}

fn warp_affine(src: &GrayImage, inv: &[f32; 9], out_w: u32, out_h: u32) -> GrayImage {
    let sw = src.width(); let sh = src.height();
    let mut out: GrayImage = ImageBuffer::from_pixel(out_w.max(1), out_h.max(1), Luma([255u8]));
    let (a, b, tx) = (inv[0], inv[1], inv[2]);
    let (c, d, ty) = (inv[3], inv[4], inv[5]);
    for oy in 0..out_h {
        for ox in 0..out_w {
            let sx = a * ox as f32 + b * oy as f32 + tx;
            let sy = c * ox as f32 + d * oy as f32 + ty;
            if sx < 0.0 || sy < 0.0 || sx >= (sw - 1) as f32 || sy >= (sh - 1) as f32 { continue; }
            let x0 = sx.floor() as u32; let y0 = sy.floor() as u32;
            let x1 = (x0 + 1).min(sw - 1); let y1 = (y0 + 1).min(sh - 1);
            let (fx, fy) = (sx - x0 as f32, sy - y0 as f32);
            let p00 = src.get_pixel(x0, y0)[0] as f32; let p10 = src.get_pixel(x1, y0)[0] as f32;
            let p01 = src.get_pixel(x0, y1)[0] as f32; let p11 = src.get_pixel(x1, y1)[0] as f32;
            let val = p00*(1.0-fx)*(1.0-fy) + p10*fx*(1.0-fy) + p01*(1.0-fx)*fy + p11*fx*fy;
            out.put_pixel(ox, oy, Luma([val.round() as u8]));
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{StaffLine, StaffSystem};

    fn make_horizontal_system(img_w: u32, top_y: u32, spacing: f32) -> StaffSystem {
        let lines: Vec<StaffLine> = (0..5)
            .map(|i| StaffLine {
                y_per_x: vec![top_y + (i as f32 * spacing) as u32; img_w as usize],
            })
            .collect();
        StaffSystem { lines, line_spacing: spacing, line_thickness: 2.0 }
    }

    fn make_skewed_system(img_w: u32, top_y: u32, spacing: f32, slope: f32) -> StaffSystem {
        let lines: Vec<StaffLine> = (0..5)
            .map(|i| StaffLine {
                y_per_x: (0..img_w)
                    .map(|x| top_y + (i as f32 * spacing) as u32 + (x as f32 * slope) as u32)
                    .collect(),
            })
            .collect();
        StaffSystem { lines, line_spacing: spacing, line_thickness: 2.0 }
    }

    #[test]
    fn rectify_horizontal_system_no_skew() {
        let img_w = 200u32; let img_h = 200u32;
        let img: GrayImage = ImageBuffer::from_pixel(img_w, img_h, Luma([200u8]));
        let system = make_horizontal_system(img_w, 60, 16.0);
        let result = rectify_system(&img, &system);
        assert!(result.angle_rad.abs() < 0.01);
        assert!((result.scale - NORMALIZED_SPACING / 16.0).abs() < 0.01);
    }

    #[test]
    fn rectify_scaled_system_normalizes_spacing() {
        let img_w = 200u32; let img_h = 300u32;
        let img: GrayImage = ImageBuffer::from_pixel(img_w, img_h, Luma([200u8]));
        let spacing = 20.0f32;
        let system = make_horizontal_system(img_w, 50, spacing);
        let result = rectify_system(&img, &system);
        let expected_scale = NORMALIZED_SPACING / spacing;
        assert!((result.scale - expected_scale).abs() < 0.01);
        let expected_w = (img_w as f32 * expected_scale).round() as u32;
        assert_eq!(result.image.width(), expected_w);
    }

    #[test]
    fn rectify_skewed_system_corrects_angle() {
        let img_w = 300u32; let img_h = 300u32;
        let img: GrayImage = ImageBuffer::from_pixel(img_w, img_h, Luma([200u8]));
        let slope = 0.05f32;
        let system = make_skewed_system(img_w, 80, 16.0, slope);
        let result = rectify_system(&img, &system);
        let expected_angle = slope.atan();
        assert!((result.angle_rad - expected_angle).abs() < 0.005,
            "angle {} expected {}", result.angle_rad, expected_angle);
    }

    #[test]
    fn rectify_all_systems_returns_correct_count() {
        let img_w = 200u32; let img_h = 400u32;
        let img: GrayImage = ImageBuffer::from_pixel(img_w, img_h, Luma([200u8]));
        let systems = vec![
            make_horizontal_system(img_w, 40, 16.0),
            make_horizontal_system(img_w, 200, 16.0),
        ];
        let results = rectify_all_systems(&img, &systems);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn transform_matrix_is_invertible() {
        let m = [2.0f32, 0.5, 10.0, -0.5, 2.0, 5.0, 0.0, 0.0, 1.0];
        let inv = invert_affine_3x3(&m);
        let prod = mat3_mul(&m, &inv);
        let identity = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0f32];
        for (a, b) in prod.iter().zip(identity.iter()) {
            assert!((a - b).abs() < 1e-4, "prod[i]={} expected {}", a, b);
        }
    }

    #[test]
    fn to_original_round_trips() {
        let fwd = [1.5f32, 0.0, 20.0, 0.0, 1.5, 30.0, 0.0, 0.0, 1.0];
        let inv = invert_affine_3x3(&fwd);
        let (px, py) = (50.0f32, 70.0f32);
        let dx = fwd[0]*px + fwd[1]*py + fwd[2];
        let dy = fwd[3]*px + fwd[4]*py + fwd[5];
        let rx = inv[0]*dx + inv[1]*dy + inv[2];
        let ry = inv[3]*dx + inv[4]*dy + inv[5];
        assert!((rx - px).abs() < 1e-3); assert!((ry - py).abs() < 1e-3);
    }
}
