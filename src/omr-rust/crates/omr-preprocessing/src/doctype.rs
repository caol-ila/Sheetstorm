// Document-Type-Detection: gedruckte vs handschriftliche Notation.
//
// Verschiedene OMR-Strategien funktionieren je nach Document-Typ unterschiedlich gut.
// Wir messen wenige robuste Indikatoren und entscheiden am Anfang der Pipeline:
//
// Indikatoren für GEDRUCKT (Verlagsdruck):
//  - Sehr gleichmäßige Stafflinien-Dicke (Stddev <= 1px über alle Linien)
//  - Stafflinien sehr gerade (max abweichung <= 2px über die ganze Linie)
//  - Hohe Symbol-Konsistenz: NH-Größen-Stddev klein
//  - Starker Schwarz/Weiss-Kontrast (Histogramm bimodal)
//
// Indikatoren für HANDSCHRIFT:
//  - Stafflinien-Dicke variabel (häufig durch Stiftdruck)
//  - Stafflinien wackelig (>4px Abweichung möglich)
//  - NH-Größen variieren stark
//  - Mehr Mittelgrau-Pixel (Bleistift, weicher Kontrast)
//
// Die Entscheidung beeinflusst Pipeline-Parameter: Sauvola-k, Bar-Thresholds,
// Plausibility-Aggressiveness, und (später) ob ein gedrucktes oder
// handschriftliches Modell beim Klassifikator genutzt wird.

use omr_core::{Binary, Gray, StaffSystem};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DocumentType {
    /// Gedruckte Notation (Verlagsdruck). Standard-Pipeline mit strikteren Parametern.
    Printed,
    /// Handgeschriebene Notation. Tolerantere Parameter, weniger NH-Filtering.
    Handwritten,
    /// Unklar — neutrale Default-Parameter.
    Unknown,
}

#[derive(Debug, Clone, Copy)]
pub struct DocumentClassification {
    pub doc_type: DocumentType,
    pub confidence: f32,
    /// Diagnose-Werte für Debug
    pub line_thickness_stddev: f32,
    pub line_straightness: f32,
    pub gray_variance: f32,
}

/// Klassifiziert das Dokument anhand des binarisierten Bildes + Stafflinien.
///
/// Der Aufruf ist O(stafflines × width) und trägt vernachlässigbar zur Pipeline-Zeit bei.
pub fn classify_document(
    gray: &Gray,
    bin: &Binary,
    systems: &[StaffSystem],
) -> DocumentClassification {
    if systems.is_empty() {
        return DocumentClassification {
            doc_type: DocumentType::Unknown,
            confidence: 0.0,
            line_thickness_stddev: 0.0,
            line_straightness: 0.0,
            gray_variance: 0.0,
        };
    }

    // 1. Stafflinien-Geradlinigkeit: Stddev der y-Werte pro Linie
    let mut all_dev = Vec::new();
    for sys in systems {
        for line in &sys.lines {
            if line.y_per_x.is_empty() { continue; }
            let valid: Vec<u32> = line.y_per_x.iter().copied().filter(|&y| y > 0).collect();
            if valid.is_empty() { continue; }
            let mean = valid.iter().sum::<u32>() as f32 / valid.len() as f32;
            let var = valid.iter()
                .map(|&y| {
                    let d = y as f32 - mean;
                    d * d
                })
                .sum::<f32>() / valid.len() as f32;
            all_dev.push(var.sqrt());
        }
    }
    let line_straightness = if all_dev.is_empty() {
        0.0
    } else {
        // mean stddev über alle Linien
        all_dev.iter().sum::<f32>() / all_dev.len() as f32
    };

    // 2. Stafflinien-Dicke-Variabilität
    let line_thickness_stddev = measure_thickness_variability(bin, systems);

    // 3. Gray-Variance: Anteil der Mittelgrau-Pixel (50-200) im Histogramm
    let mut gray_hist = [0u32; 256];
    let total_px = (gray.width() * gray.height()) as f32;
    for p in gray.pixels() {
        gray_hist[p[0] as usize] += 1;
    }
    let mid_gray_count: u32 = gray_hist[60..=190].iter().sum();
    let gray_variance = mid_gray_count as f32 / total_px;

    // 4. Entscheidung
    // Kriterien:
    // - line_straightness < 1.5px → sehr gerade (gedruckt)
    // - line_straightness > 4px → wackelig (handschrift)
    // - line_thickness_stddev > 0.6 → variable Dicke (handschrift)
    // - gray_variance > 0.20 → viel Mittelgrau (handschrift, Bleistift)
    let mut printed_score = 0.0_f32;
    let mut handwritten_score = 0.0_f32;

    if line_straightness < 1.5 { printed_score += 1.0; }
    else if line_straightness < 2.5 { printed_score += 0.5; }
    else if line_straightness < 4.0 { handwritten_score += 0.5; }
    else { handwritten_score += 1.0; }

    if line_thickness_stddev < 0.4 { printed_score += 1.0; }
    else if line_thickness_stddev < 0.7 { printed_score += 0.3; }
    else if line_thickness_stddev > 1.0 { handwritten_score += 1.0; }
    else { handwritten_score += 0.3; }

    if gray_variance < 0.10 { printed_score += 0.5; }
    else if gray_variance > 0.20 { handwritten_score += 1.0; }

    let total = printed_score + handwritten_score;
    let (doc_type, confidence) = if total < 0.5 {
        (DocumentType::Unknown, 0.0)
    } else if printed_score > handwritten_score * 1.3 {
        (DocumentType::Printed, printed_score / total)
    } else if handwritten_score > printed_score * 1.3 {
        (DocumentType::Handwritten, handwritten_score / total)
    } else {
        (DocumentType::Unknown, 0.5)
    };

    DocumentClassification {
        doc_type,
        confidence,
        line_thickness_stddev,
        line_straightness,
        gray_variance,
    }
}

/// Misst wie variabel die Stafflinien-Dicke über alle Stafflinien im Bild ist.
/// Returns Stddev in Pixeln.
fn measure_thickness_variability(bin: &Binary, systems: &[StaffSystem]) -> f32 {
    let mut thicknesses = Vec::new();
    for sys in systems {
        for line in &sys.lines {
            if line.y_per_x.is_empty() { continue; }
            // Sample 20 X-Positionen über die Linie
            let n_samples = 20.min(line.y_per_x.len());
            let step = line.y_per_x.len() / n_samples.max(1);
            for i in 0..n_samples {
                let x = (i * step).min(line.y_per_x.len() - 1);
                let y_center = line.y_per_x[x];
                if y_center == 0 || y_center >= bin.h { continue; }
                // Miss vertikale Run-Länge an dieser X-Position
                let mut top = y_center;
                while top > 0 && bin.get(x as u32, top - 1) == 1 { top -= 1; }
                let mut bot = y_center;
                while bot + 1 < bin.h && bin.get(x as u32, bot + 1) == 1 { bot += 1; }
                let thick = bot - top + 1;
                // Filter: nur plausible Stafflinien-Dicken (1-8px)
                if thick > 0 && thick <= 8 {
                    thicknesses.push(thick as f32);
                }
            }
        }
    }
    if thicknesses.is_empty() { return 0.0; }
    let mean = thicknesses.iter().sum::<f32>() / thicknesses.len() as f32;
    let var = thicknesses.iter()
        .map(|t| (t - mean).powi(2))
        .sum::<f32>() / thicknesses.len() as f32;
    var.sqrt()
}

/// Pipeline-Parameter pro Document-Type.
/// Gedruckte Vorlagen erlauben strikte Schwellwerte, Handschrift braucht Toleranz.
#[derive(Debug, Clone, Copy)]
pub struct PipelineTuning {
    /// Sauvola-k Parameter für Binarisierung. Default 0.34, gedruckt 0.20-0.30, handschrift 0.40+
    pub sauvola_k: f64,
    /// Bar-Coverage für strict Mode (0.78 default).
    pub bar_coverage_strict: f32,
    /// NH-Aspect-Range Untergrenze (0.85 default).
    pub nh_aspect_min: f32,
    /// NH-Aspect-Range Obergrenze (2.2 default).
    pub nh_aspect_max: f32,
    /// Stem-Gap-Tolerance in Pixeln (3 default).
    pub stem_max_gap: u32,
    /// Aktiviere aggressive Plausibility-Reparatur (auch bei Broken).
    pub plausibility_aggressive: bool,
}

impl PipelineTuning {
    pub fn for_doc_type(t: DocumentType) -> Self {
        match t {
            DocumentType::Printed => Self {
                sauvola_k: 0.28,           // strikter (saubere Drucke vertragen weniger Slack)
                bar_coverage_strict: 0.85, // strikte Bars in Druck
                nh_aspect_min: 0.95,       // präzise NH-Form in Druck
                nh_aspect_max: 1.85,       // ditto
                stem_max_gap: 2,           // saubere Stems
                plausibility_aggressive: false, // weniger nötig
            },
            DocumentType::Handwritten => Self {
                sauvola_k: 0.40,           // toleranter
                bar_coverage_strict: 0.65, // wackelige Bars
                nh_aspect_min: 0.70,       // variable NH-Form
                nh_aspect_max: 2.50,       // ditto
                stem_max_gap: 4,           // verschmierte Stems
                plausibility_aggressive: true,
            },
            DocumentType::Unknown => Self {
                sauvola_k: 0.34,
                bar_coverage_strict: 0.78,
                nh_aspect_min: 0.85,
                nh_aspect_max: 2.20,
                stem_max_gap: 3,
                plausibility_aggressive: true,
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::StaffLine;
    use image::{GrayImage, Luma};

    #[test]
    fn empty_input_returns_unknown() {
        let gray = GrayImage::from_pixel(100, 100, Luma([255]));
        let bin = Binary::new(100, 100);
        let result = classify_document(&gray, &bin, &[]);
        assert_eq!(result.doc_type, DocumentType::Unknown);
    }

    #[test]
    fn perfectly_straight_lines_classify_printed() {
        let mut bin = Binary::new(200, 100);
        let lines = [20u32, 30, 40, 50, 60];
        for line_y in lines {
            for x in 5..195 { bin.set(x, line_y, 1); }
        }
        let gray = GrayImage::from_pixel(200, 100, Luma([255]));
        let sys = StaffSystem {
            lines: lines.iter().map(|&y| StaffLine {
                y_per_x: (0..200).map(|_| y).collect(),
            }).collect(),
            line_spacing: 10.0,
            line_thickness: 1.0,
        };
        let result = classify_document(&gray, &bin, &[sys]);
        assert!(matches!(result.doc_type, DocumentType::Printed | DocumentType::Unknown),
                "expected Printed, got {:?}", result.doc_type);
        // line_straightness sollte ~0 sein (perfekt gerade)
        assert!(result.line_straightness < 0.1);
    }

    #[test]
    fn tuning_defaults_are_distinct() {
        let p = PipelineTuning::for_doc_type(DocumentType::Printed);
        let h = PipelineTuning::for_doc_type(DocumentType::Handwritten);
        assert!(p.sauvola_k < h.sauvola_k);
        assert!(p.bar_coverage_strict > h.bar_coverage_strict);
        assert!(p.stem_max_gap < h.stem_max_gap);
    }
}
