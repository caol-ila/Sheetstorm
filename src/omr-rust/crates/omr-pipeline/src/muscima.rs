// MUSCIMA++ Ground-Truth Loader (MuNG-Format).
//
// MUSCIMA++ ist ein Korpus aus 140 handschriftlichen Notenseiten mit
// pixel-genauen Annotationen für ~91k Symbole. Annotationen werden im
// "Music Notation Graph" (MuNG) Format als XML geliefert.
//
// XML-Schema (siehe `CVC-MUSCIMA_Schema.xsd` im Release):
//   <Nodes dataset="MUSCIMA-pp_2.0" document="...">
//     <Node>
//       <Id>0</Id>
//       <ClassName>noteheadFull</ClassName>
//       <Top>372</Top>
//       <Left>494</Left>
//       <Width>29</Width>
//       <Height>20</Height>
//       <Mask>0:15 1:10 0:14 ...</Mask>     <!-- RLE Pixelmaske, optional -->
//       <Inlinks>3 7 12</Inlinks>            <!-- optional, IDs eingehender Kanten -->
//       <Outlinks>730 575 ...</Outlinks>     <!-- optional, IDs ausgehender Kanten -->
//     </Node>
//     ...
//   </Nodes>
//
// Klassennamen (Auswahl, vollständige Liste in
// `v2.0/specifications/mff-muscima-mlclasses-annot.xml`):
//   noteheadFull, noteheadHalf, noteheadWhole, noteheadFullSmall,
//   stem, beam, barline, barlineHeavy, measureSeparator,
//   gClef, fClef, cClef, keySignature, augmentationDot, slur, tie,
//   accidentalSharp, accidentalFlat, accidentalNatural, volta, ...
//
// Quellen:
//   * Spec & Download: https://github.com/OMR-Research/muscima-pp
//   * Paper: Hajič jr. & Pecina, "The MUSCIMA++ Dataset for Handwritten OMR",
//     ICDAR 2017, https://arxiv.org/abs/1703.04824
//   * MuNG Annotator-Doku: https://muscimarker.readthedocs.io/
//
// Lizenz-Hinweis: MUSCIMA++ ist CC-BY-NC-SA 4.0 (NonCommercial!) und
// damit NICHT mit Apache-2.0 redistributable. Dieser Loader-Code ist
// Apache-2.0 — er enthält keine Daten. Daten müssen von Endanwendern
// separat besorgt werden, siehe `tests/fixtures/muscima_plus/README.md`.

use omr_core::Rect;
use quick_xml::events::Event;
use quick_xml::Reader;
use std::path::{Path, PathBuf};

/// Eine einzelne Symbol-Annotation aus einer MuNG-Datei.
#[derive(Debug, Clone)]
pub struct MuscimaSymbol {
    pub id: u32,
    /// Klassenname laut MUSCIMA++ Vokabular, z.B. `"noteheadFull"`.
    pub class_name: String,
    /// Bounding-Box in Pixelkoordinaten der Original-Seite.
    pub bbox: Rect,
    /// Optionale binäre Pixel-Maske (Länge = bbox.w * bbox.h, row-major).
    /// `None` falls die XML keine `<Mask>` enthält oder das Decoding
    /// übersprungen wurde.
    pub mask: Option<Vec<bool>>,
    /// Eingehende Kanten im MuNG (IDs anderer Nodes).
    pub inlinks: Vec<u32>,
    /// Ausgehende Kanten im MuNG (IDs anderer Nodes).
    pub outlinks: Vec<u32>,
}

impl MuscimaSymbol {
    /// Mittelpunkt der Bounding-Box.
    pub fn center(&self) -> (f32, f32) {
        (self.bbox.cx(), self.bbox.cy())
    }
}

/// Vollständige Annotation einer MUSCIMA++-Seite.
///
/// Die Symbole werden nach Klassen-Familien gruppiert, damit die Pipeline
/// gegen die für sie relevanten Untermengen evaluiert werden kann.
#[derive(Debug, Clone, Default)]
pub struct MuscimaAnnotation {
    /// Pfad zum zugehörigen PNG-Bild (gleicher Basename, `.png` statt `.xml`).
    pub image_path: PathBuf,
    /// Document-Name aus dem XML (z.B. `CVC-MUSCIMA_W-01_N-10_D-ideal`).
    pub document: String,

    pub noteheads_full: Vec<MuscimaSymbol>,
    pub noteheads_half: Vec<MuscimaSymbol>,
    pub noteheads_whole: Vec<MuscimaSymbol>,
    pub stems: Vec<MuscimaSymbol>,
    pub beams: Vec<MuscimaSymbol>,
    pub bars: Vec<MuscimaSymbol>,
    pub clefs: Vec<MuscimaSymbol>,
    pub key_signatures: Vec<MuscimaSymbol>,
    pub augmentation_dots: Vec<MuscimaSymbol>,
    pub slurs: Vec<MuscimaSymbol>,
    pub ties: Vec<MuscimaSymbol>,
    pub voltas: Vec<MuscimaSymbol>,
    pub accidentals: Vec<MuscimaSymbol>,
    /// Alle übrigen Symbole, die keiner der obigen Familien zugeordnet wurden.
    pub other: Vec<MuscimaSymbol>,
}

impl MuscimaAnnotation {
    /// Alle Noteheads (full + half + whole) als kombinierte Liste.
    pub fn all_noteheads(&self) -> impl Iterator<Item = &MuscimaSymbol> {
        self.noteheads_full
            .iter()
            .chain(self.noteheads_half.iter())
            .chain(self.noteheads_whole.iter())
    }

    /// Anzahl aller Symbole (über alle Kategorien hinweg).
    pub fn total_symbols(&self) -> usize {
        self.noteheads_full.len()
            + self.noteheads_half.len()
            + self.noteheads_whole.len()
            + self.stems.len()
            + self.beams.len()
            + self.bars.len()
            + self.clefs.len()
            + self.key_signatures.len()
            + self.augmentation_dots.len()
            + self.slurs.len()
            + self.ties.len()
            + self.voltas.len()
            + self.accidentals.len()
            + self.other.len()
    }
}

#[derive(Debug)]
pub enum MuscimaError {
    Io {
        path: PathBuf,
        source: std::io::Error,
    },
    Xml {
        path: PathBuf,
        message: String,
    },
    InvalidMask {
        id: u32,
        message: String,
    },
}

impl std::fmt::Display for MuscimaError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MuscimaError::Io { path, source } => {
                write!(f, "I/O-Fehler beim Lesen von {}: {}", path.display(), source)
            }
            MuscimaError::Xml { path, message } => {
                write!(f, "XML-Parse-Fehler in {}: {}", path.display(), message)
            }
            MuscimaError::InvalidMask { id, message } => {
                write!(f, "Ungültige Maske in Node #{id}: {message}")
            }
        }
    }
}

impl std::error::Error for MuscimaError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            MuscimaError::Io { source, .. } => Some(source),
            _ => None,
        }
    }
}

/// Lädt eine MUSCIMA++ MuNG-Annotation aus einer XML-Datei.
///
/// Das zugehörige PNG wird als gleichnamige Datei mit `.png`-Endung im
/// gleichen Verzeichnis erwartet (übliches Layout in
/// `tests/fixtures/muscima_plus/`).
///
/// `decode_masks = false` überspringt das Dekodieren der RLE-Pixelmasken
/// (deutlich schneller und speicherschonender, falls nur die Bounding-Boxen
/// gebraucht werden).
pub fn load_muscima_xml(path: &Path) -> Result<MuscimaAnnotation, MuscimaError> {
    load_muscima_xml_with_options(path, false)
}

pub fn load_muscima_xml_with_options(
    path: &Path,
    decode_masks: bool,
) -> Result<MuscimaAnnotation, MuscimaError> {
    let xml = std::fs::read_to_string(path).map_err(|e| MuscimaError::Io {
        path: path.to_path_buf(),
        source: e,
    })?;

    let mut reader = Reader::from_str(&xml);
    reader.config_mut().trim_text(true);

    let mut ann = MuscimaAnnotation::default();
    ann.image_path = path.with_extension("png");

    let mut buf = Vec::new();

    // Per-Node State
    let mut in_node = false;
    let mut current_field: Option<&'static str> = None;
    let mut id: u32 = 0;
    let mut class_name = String::new();
    let mut top: u32 = 0;
    let mut left: u32 = 0;
    let mut width: u32 = 0;
    let mut height: u32 = 0;
    let mut mask_str = String::new();
    let mut inlinks_str = String::new();
    let mut outlinks_str = String::new();

    fn map_field(tag: &[u8]) -> Option<&'static str> {
        match tag {
            b"Id" => Some("Id"),
            b"ClassName" => Some("ClassName"),
            b"Top" => Some("Top"),
            b"Left" => Some("Left"),
            b"Width" => Some("Width"),
            b"Height" => Some("Height"),
            b"Mask" => Some("Mask"),
            b"Inlinks" => Some("Inlinks"),
            b"Outlinks" => Some("Outlinks"),
            _ => None,
        }
    }

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = e.name();
                if name.as_ref() == b"Nodes" {
                    if let Some(attr) = e.attributes().flatten().find(|a| a.key.as_ref() == b"document") {
                        if let Ok(s) = std::str::from_utf8(&attr.value) {
                            ann.document = s.to_string();
                        }
                    }
                } else if name.as_ref() == b"Node" {
                    in_node = true;
                    id = 0;
                    class_name.clear();
                    top = 0;
                    left = 0;
                    width = 0;
                    height = 0;
                    mask_str.clear();
                    inlinks_str.clear();
                    outlinks_str.clear();
                } else if in_node {
                    current_field = map_field(name.as_ref());
                }
            }
            Ok(Event::Text(t)) => {
                if let Some(field) = current_field {
                    let text = t.unescape().map_err(|e| MuscimaError::Xml {
                        path: path.to_path_buf(),
                        message: e.to_string(),
                    })?;
                    match field {
                        "Id" => id = text.trim().parse().unwrap_or(0),
                        "ClassName" => class_name = text.trim().to_string(),
                        "Top" => top = text.trim().parse().unwrap_or(0),
                        "Left" => left = text.trim().parse().unwrap_or(0),
                        "Width" => width = text.trim().parse().unwrap_or(0),
                        "Height" => height = text.trim().parse().unwrap_or(0),
                        "Mask" => mask_str.push_str(&text),
                        "Inlinks" => inlinks_str.push_str(&text),
                        "Outlinks" => outlinks_str.push_str(&text),
                        _ => {}
                    }
                }
            }
            Ok(Event::End(e)) => {
                let name = e.name();
                if name.as_ref() == b"Node" && in_node {
                    let mask = if decode_masks && !mask_str.is_empty() {
                        Some(decode_rle_mask(&mask_str, width, height, id)?)
                    } else {
                        None
                    };
                    let sym = MuscimaSymbol {
                        id,
                        class_name: class_name.clone(),
                        bbox: Rect {
                            x: left,
                            y: top,
                            w: width,
                            h: height,
                        },
                        mask,
                        inlinks: parse_id_list(&inlinks_str),
                        outlinks: parse_id_list(&outlinks_str),
                    };
                    classify_into(&mut ann, sym);
                    in_node = false;
                    current_field = None;
                } else if in_node && map_field(name.as_ref()).is_some() {
                    current_field = None;
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => {
                return Err(MuscimaError::Xml {
                    path: path.to_path_buf(),
                    message: e.to_string(),
                });
            }
            _ => {}
        }
        buf.clear();
    }

    Ok(ann)
}

fn parse_id_list(s: &str) -> Vec<u32> {
    s.split_whitespace().filter_map(|t| t.parse().ok()).collect()
}

/// Sortiert ein Symbol in das passende Familien-Bucket der Annotation ein.
fn classify_into(ann: &mut MuscimaAnnotation, sym: MuscimaSymbol) {
    match sym.class_name.as_str() {
        "noteheadFull" | "noteheadFullSmall" => ann.noteheads_full.push(sym),
        "noteheadHalf" | "noteheadHalfSmall" | "noteheadEmpty" => ann.noteheads_half.push(sym),
        "noteheadWhole" => ann.noteheads_whole.push(sym),
        "stem" => ann.stems.push(sym),
        "beam" => ann.beams.push(sym),
        "barline" | "barlineHeavy" | "measureSeparator" => ann.bars.push(sym),
        "gClef" | "fClef" | "cClef" => ann.clefs.push(sym),
        "keySignature" => ann.key_signatures.push(sym),
        "augmentationDot" => ann.augmentation_dots.push(sym),
        "slur" => ann.slurs.push(sym),
        "tie" => ann.ties.push(sym),
        "volta" => ann.voltas.push(sym),
        "accidentalSharp"
        | "accidentalFlat"
        | "accidentalNatural"
        | "accidentalDoubleSharp"
        | "accidentalDoubleFlat" => ann.accidentals.push(sym),
        _ => ann.other.push(sym),
    }
}

/// Dekodiert die MUSCIMA++ RLE-Pixelmaske.
///
/// Format: alternierende `value:count` Paare, durch Leerzeichen getrennt.
/// `value` ist 0 oder 1, `count` die Anzahl aufeinanderfolgender Pixel.
/// Die Sequenz ist row-major (Zeilen-zuerst, links-nach-rechts).
fn decode_rle_mask(s: &str, w: u32, h: u32, id: u32) -> Result<Vec<bool>, MuscimaError> {
    let total = (w as usize) * (h as usize);
    let mut out = Vec::with_capacity(total);
    for token in s.split_whitespace() {
        let mut parts = token.splitn(2, ':');
        let value: u8 = parts
            .next()
            .and_then(|v| v.parse().ok())
            .ok_or_else(|| MuscimaError::InvalidMask {
                id,
                message: format!("token ohne value: '{token}'"),
            })?;
        let count: usize = parts
            .next()
            .and_then(|v| v.parse().ok())
            .ok_or_else(|| MuscimaError::InvalidMask {
                id,
                message: format!("token ohne count: '{token}'"),
            })?;
        let bit = value != 0;
        out.extend(std::iter::repeat(bit).take(count));
    }
    if out.len() != total {
        return Err(MuscimaError::InvalidMask {
            id,
            message: format!("decoded {} pixels, expected {}", out.len(), total),
        });
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rle_decode_simple() {
        // 3x2 = 6 pixels: 0:2 1:3 0:1
        let mask = decode_rle_mask("0:2 1:3 0:1", 3, 2, 0).unwrap();
        assert_eq!(mask, vec![false, false, true, true, true, false]);
    }

    #[test]
    fn rle_decode_size_mismatch() {
        // 4 pixels declared, only 3 decoded.
        let res = decode_rle_mask("0:1 1:2", 2, 2, 42);
        assert!(matches!(res, Err(MuscimaError::InvalidMask { id: 42, .. })));
    }

    #[test]
    fn parse_id_list_works() {
        assert_eq!(parse_id_list(""), Vec::<u32>::new());
        assert_eq!(parse_id_list("1 2 3"), vec![1, 2, 3]);
        assert_eq!(parse_id_list("  10\t20\n30 "), vec![10, 20, 30]);
    }

    #[test]
    fn parse_minimal_xml() {
        let xml = r#"<?xml version="1.0" encoding="utf-8"?>
<Nodes dataset="MUSCIMA-pp_2.0" document="TEST_DOC">
    <Node>
        <Id>0</Id>
        <ClassName>noteheadFull</ClassName>
        <Top>10</Top>
        <Left>20</Left>
        <Width>30</Width>
        <Height>40</Height>
        <Outlinks>5 7</Outlinks>
    </Node>
    <Node>
        <Id>1</Id>
        <ClassName>stem</ClassName>
        <Top>5</Top>
        <Left>22</Left>
        <Width>2</Width>
        <Height>50</Height>
    </Node>
    <Node>
        <Id>2</Id>
        <ClassName>barline</ClassName>
        <Top>0</Top>
        <Left>500</Left>
        <Width>3</Width>
        <Height>100</Height>
    </Node>
</Nodes>"#;
        let tmp = std::env::temp_dir().join("test_muscima_minimal.xml");
        std::fs::write(&tmp, xml).unwrap();
        let ann = load_muscima_xml(&tmp).unwrap();
        std::fs::remove_file(&tmp).ok();

        assert_eq!(ann.document, "TEST_DOC");
        assert_eq!(ann.noteheads_full.len(), 1);
        assert_eq!(ann.stems.len(), 1);
        assert_eq!(ann.bars.len(), 1);
        assert_eq!(ann.noteheads_full[0].bbox.x, 20);
        assert_eq!(ann.noteheads_full[0].bbox.y, 10);
        assert_eq!(ann.noteheads_full[0].outlinks, vec![5, 7]);
        assert_eq!(ann.total_symbols(), 3);
    }
}
