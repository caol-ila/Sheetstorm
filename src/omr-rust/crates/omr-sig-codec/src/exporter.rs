//! Sig → MusicXML Exporter.
//!
//! Schreibt alle Inters eines SIG als `score-partwise` MusicXML 4.0.
//! Heads werden sortiert nach `(system_idx, measure_number, bbox.x)`.
//! Jedes eindeutige `system_idx` wird als separate `<part>` ausgegeben.

use omr_sig::{
    inter::InterKind,
    inters::{ClefInter, ClefType, HeadInter, KeySignatureInter, TimeSignatureInter},
    sig::Sig,
};
use std::fmt::Write;

use crate::CodecError;

/// Exportiert einen SIG als MusicXML-String.
pub(crate) fn export(sig: &Sig, divisions: u32) -> Result<String, CodecError> {
    // Sammle alle Heads, sortiert nach (system_idx, measure_number, x)
    let mut heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
    heads.sort_by_key(|h| {
        (
            h.meta.system_idx.unwrap_or(0),
            h.meta.measure_number.unwrap_or(0),
            h.meta.bounds.x,
        )
    });

    let clefs: Vec<&ClefInter> = sig.typed_inters::<ClefInter>().collect();
    let key_sigs: Vec<&KeySignatureInter> = sig.typed_inters::<KeySignatureInter>().collect();
    let time_sigs: Vec<&TimeSignatureInter> = sig.typed_inters::<TimeSignatureInter>().collect();

    // Eindeutige system_idx-Werte → Parts
    let mut system_idxs: Vec<u32> = {
        let mut idxs: Vec<u32> = heads
            .iter()
            .filter_map(|h| h.meta.system_idx)
            .chain(clefs.iter().filter_map(|c| c.meta.system_idx))
            .collect();
        idxs.sort();
        idxs.dedup();
        idxs
    };
    if system_idxs.is_empty() {
        system_idxs.push(0);
    }

    let mut out = String::new();
    writeln!(out, r#"<?xml version="1.0" encoding="UTF-8"?>"#).unwrap();
    writeln!(out, r#"<score-partwise version="4.0">"#).unwrap();
    writeln!(out, "  <part-list>").unwrap();
    for &sys in &system_idxs {
        writeln!(
            out,
            "    <score-part id=\"P{idx}\"><part-name>Part {idx}</part-name></score-part>",
            idx = sys + 1
        )
        .unwrap();
    }
    writeln!(out, "  </part-list>").unwrap();

    for &sys in &system_idxs {
        writeln!(out, "  <part id=\"P{}\">", sys + 1).unwrap();

        // Takt-Nummern für diese Part (aus Heads und Attribut-Inters)
        let mut measure_numbers: Vec<u32> = heads
            .iter()
            .filter(|h| h.meta.system_idx == Some(sys))
            .filter_map(|h| h.meta.measure_number)
            .chain(
                clefs
                    .iter()
                    .filter(|c| c.meta.system_idx == Some(sys))
                    .filter_map(|c| c.meta.measure_number),
            )
            .collect();
        measure_numbers.sort();
        measure_numbers.dedup();

        if measure_numbers.is_empty() {
            // Leere Part: minimaler Platzhalter-Takt
            writeln!(out, "    <measure number=\"1\">").unwrap();
            writeln!(out, "      <attributes>").unwrap();
            writeln!(out, "        <divisions>{}</divisions>", divisions).unwrap();
            writeln!(out, "      </attributes>").unwrap();
            writeln!(out, "    </measure>").unwrap();
        } else {
            for &m_num in &measure_numbers {
                writeln!(out, "    <measure number=\"{}\">", m_num).unwrap();

                // Attribute-Inters für diesen Takt?
                let clef = clefs
                    .iter()
                    .find(|c| c.meta.system_idx == Some(sys) && c.meta.measure_number == Some(m_num));
                let ks = key_sigs
                    .iter()
                    .find(|k| k.meta.system_idx == Some(sys) && k.meta.measure_number == Some(m_num));
                let ts = time_sigs
                    .iter()
                    .find(|t| t.meta.system_idx == Some(sys) && t.meta.measure_number == Some(m_num));

                if clef.is_some() || ks.is_some() || ts.is_some() {
                    writeln!(out, "      <attributes>").unwrap();
                    writeln!(out, "        <divisions>{}</divisions>", divisions).unwrap();

                    if let Some(k) = ks {
                        writeln!(out, "        <key>").unwrap();
                        writeln!(out, "          <fifths>{}</fifths>", k.fifths).unwrap();
                        writeln!(out, "        </key>").unwrap();
                    }
                    if let Some(t) = ts {
                        writeln!(out, "        <time>").unwrap();
                        writeln!(out, "          <beats>{}</beats>", t.beats).unwrap();
                        writeln!(out, "          <beat-type>{}</beat-type>", t.beat_type).unwrap();
                        writeln!(out, "        </time>").unwrap();
                    }
                    if let Some(c) = clef {
                        let (sign, line) = clef_type_to_sign_line(c.clef_type);
                        writeln!(out, "        <clef>").unwrap();
                        writeln!(out, "          <sign>{}</sign>", sign).unwrap();
                        writeln!(out, "          <line>{}</line>", line).unwrap();
                        writeln!(out, "        </clef>").unwrap();
                    }
                    writeln!(out, "      </attributes>").unwrap();
                }

                // Noten für diesen Takt, sortiert nach x
                let measure_heads: Vec<&&HeadInter> = heads
                    .iter()
                    .filter(|h| {
                        h.meta.system_idx == Some(sys) && h.meta.measure_number == Some(m_num)
                    })
                    .collect();

                for head in measure_heads {
                    writeln!(out, "      <note>").unwrap();
                    writeln!(out, "        <pitch>").unwrap();
                    writeln!(out, "          <step>{}</step>", head.step.as_str()).unwrap();
                    if head.alter != 0 {
                        writeln!(out, "          <alter>{}</alter>", head.alter).unwrap();
                    }
                    writeln!(out, "          <octave>{}</octave>", head.octave).unwrap();
                    writeln!(out, "        </pitch>").unwrap();
                    writeln!(out, "        <duration>{}</duration>", head.duration).unwrap();
                    writeln!(out, "        <voice>1</voice>").unwrap();
                    writeln!(
                        out,
                        "        <type>{}</type>",
                        duration_to_type(head.duration, divisions)
                    )
                    .unwrap();
                    writeln!(out, "      </note>").unwrap();
                }

                writeln!(out, "    </measure>").unwrap();
            }
        }

        writeln!(out, "  </part>").unwrap();
    }

    writeln!(out, "</score-partwise>").unwrap();
    Ok(out)
}

fn clef_type_to_sign_line(ct: ClefType) -> (&'static str, u8) {
    match ct {
        ClefType::Treble => ("G", 2),
        ClefType::Bass => ("F", 4),
        ClefType::Alto => ("C", 3),
        ClefType::Tenor => ("C", 4),
        ClefType::Soprano => ("C", 1),
        ClefType::Percussion => ("percussion", 0),
        ClefType::Tab => ("TAB", 0),
    }
}

fn duration_to_type(d: u32, divisions: u32) -> &'static str {
    if divisions == 0 {
        return "quarter";
    }
    let q = d as f32 / divisions as f32;
    if q >= 4.0 {
        "whole"
    } else if q >= 2.0 {
        "half"
    } else if q >= 1.0 {
        "quarter"
    } else if q >= 0.5 {
        "eighth"
    } else if q >= 0.25 {
        "16th"
    } else {
        "32nd"
    }
}
