// MusicXML 4.0 Score-Partwise Export.
//
// Output ist plain UTF-8-XML — kompatibel mit OSMD, MuseScore, Verovio.

use omr_core::{Clef, Measure, Result, Score};
use std::fmt::Write;

/// Exportiere einen Score als Score-Partwise MusicXML 4.0.
pub fn export(score: &Score) -> Result<String> {
    let mut out = String::new();
    write_doctype(&mut out);
    let _ = writeln!(out, r#"<score-partwise version="4.0">"#);
    let _ = write!(out, "{}", work_section(&score.work_title, &score.composer));
    let _ = write!(out, "{}", part_list(&score.parts));

    for part in &score.parts {
        let _ = writeln!(out, r#"  <part id="{}">"#, part.id);
        for (i, m) in part.measures.iter().enumerate() {
            let _ = write!(out, "{}", measure_xml(m, i == 0));
        }
        let _ = writeln!(out, "  </part>");
    }
    let _ = writeln!(out, "</score-partwise>");
    Ok(out)
}

fn write_doctype(out: &mut String) {
    let _ = writeln!(out, r#"<?xml version="1.0" encoding="UTF-8" standalone="no"?>"#);
    let _ = writeln!(
        out,
        r#"<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">"#
    );
}

fn work_section(title: &str, composer: &str) -> String {
    let mut s = String::new();
    if !title.is_empty() || !composer.is_empty() {
        let _ = writeln!(s, "  <work>");
        if !title.is_empty() {
            let _ = writeln!(s, "    <work-title>{}</work-title>", xml_escape(title));
        }
        let _ = writeln!(s, "  </work>");
    }
    if !composer.is_empty() {
        let _ = writeln!(s, "  <identification>");
        let _ = writeln!(s, "    <creator type=\"composer\">{}</creator>", xml_escape(composer));
        let _ = writeln!(s, "    <encoding>");
        let _ = writeln!(s, "      <software>Sheetstorm OMR</software>");
        let _ = writeln!(s, "      <encoding-date>{}</encoding-date>", today());
        let _ = writeln!(s, "    </encoding>");
        let _ = writeln!(s, "  </identification>");
    }
    s
}

fn part_list(parts: &[omr_core::Part]) -> String {
    let mut s = String::new();
    let _ = writeln!(s, "  <part-list>");
    for p in parts {
        let _ = writeln!(s, "    <score-part id=\"{}\">", xml_escape(&p.id));
        let _ = writeln!(s, "      <part-name>{}</part-name>", xml_escape(&p.name));
        let _ = writeln!(s, "    </score-part>");
    }
    let _ = writeln!(s, "  </part-list>");
    s
}

fn measure_xml(m: &Measure, first: bool) -> String {
    let mut s = String::new();
    let _ = writeln!(s, "    <measure number=\"{}\">", m.number);
    if first {
        let _ = writeln!(s, "      <attributes>");
        let _ = writeln!(s, "        <divisions>{}</divisions>", m.divisions);
        if let Some(k) = m.key_signature {
            let _ = writeln!(s, "        <key>");
            let _ = writeln!(s, "          <fifths>{}</fifths>", k.fifths);
            let _ = writeln!(s, "        </key>");
        }
        if let Some(t) = m.time_signature {
            let _ = writeln!(s, "        <time>");
            let _ = writeln!(s, "          <beats>{}</beats>", t.beats);
            let _ = writeln!(s, "          <beat-type>{}</beat-type>", t.beat_type);
            let _ = writeln!(s, "        </time>");
        }
        if let Some(c) = m.clef {
            let (sign, line) = clef_to_sign_line(c);
            let _ = writeln!(s, "        <clef>");
            let _ = writeln!(s, "          <sign>{}</sign>", sign);
            let _ = writeln!(s, "          <line>{}</line>", line);
            let _ = writeln!(s, "        </clef>");
        }
        let _ = writeln!(s, "      </attributes>");
    }
    for n in &m.notes {
        let _ = writeln!(s, "      <note>");
        if n.in_chord {
            let _ = writeln!(s, "        <chord/>");
        }
        if n.is_rest {
            let _ = writeln!(s, "        <rest/>");
        } else {
            let _ = writeln!(s, "        <pitch>");
            let _ = writeln!(s, "          <step>{}</step>", n.step.as_str());
            if n.alter != 0 {
                let _ = writeln!(s, "          <alter>{}</alter>", n.alter);
            }
            let _ = writeln!(s, "          <octave>{}</octave>", n.octave);
            let _ = writeln!(s, "        </pitch>");
        }
        let _ = writeln!(s, "        <duration>{}</duration>", n.duration);
        let _ = writeln!(s, "        <voice>{}</voice>", n.voice);
        let base_dur = match n.augmentation_dots {
            1 => (n.duration as f32 / 1.5) as u32,
            2 => (n.duration as f32 / 1.75) as u32,
            _ => n.duration,
        };
        let _ = writeln!(s, "        <type>{}</type>", duration_to_type(base_dur, m.divisions));
        for _ in 0..n.augmentation_dots {
            let _ = writeln!(s, "        <dot/>");
        }
        let _ = writeln!(s, "      </note>");
    }
    // Sprungmarken als <barline> mit <repeat>/<ending> ausgeben
    write_jump_marks(&mut s, &m.jump_marks);
    let _ = writeln!(s, "    </measure>");
    s
}

fn write_jump_marks(s: &mut String, marks: &[omr_core::JumpMark]) {
    use omr_core::JumpMark;
    for mark in marks {
        match mark {
            JumpMark::RepeatStart => {
                let _ = writeln!(s, "      <barline location=\"left\">");
                let _ = writeln!(s, "        <bar-style>heavy-light</bar-style>");
                let _ = writeln!(s, "        <repeat direction=\"forward\"/>");
                let _ = writeln!(s, "      </barline>");
            }
            JumpMark::RepeatEnd => {
                let _ = writeln!(s, "      <barline location=\"right\">");
                let _ = writeln!(s, "        <bar-style>light-heavy</bar-style>");
                let _ = writeln!(s, "        <repeat direction=\"backward\"/>");
                let _ = writeln!(s, "      </barline>");
            }
            JumpMark::Volta { number } => {
                let _ = writeln!(s, "      <barline location=\"left\">");
                let _ = writeln!(s, "        <ending number=\"{}\" type=\"start\"/>", number);
                let _ = writeln!(s, "      </barline>");
            }
            JumpMark::Coda => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><coda/></direction-type>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::Segno => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><segno/></direction-type>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::Fine => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><words>Fine</words></direction-type>");
                let _ = writeln!(s, "        <sound fine=\"yes\"/>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::DaCapo => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><words>D.C.</words></direction-type>");
                let _ = writeln!(s, "        <sound dacapo=\"yes\"/>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::DcAlFine => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><words>D.C. al Fine</words></direction-type>");
                let _ = writeln!(s, "        <sound dacapo=\"yes\"/>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::DsAlCoda => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><words>D.S. al Coda</words></direction-type>");
                let _ = writeln!(s, "        <sound dalsegno=\"segno\"/>");
                let _ = writeln!(s, "      </direction>");
            }
            JumpMark::DsAlFine => {
                let _ = writeln!(s, "      <direction placement=\"above\">");
                let _ = writeln!(s, "        <direction-type><words>D.S. al Fine</words></direction-type>");
                let _ = writeln!(s, "        <sound dalsegno=\"segno\"/>");
                let _ = writeln!(s, "      </direction>");
            }
        }
    }
}

fn clef_to_sign_line(c: Clef) -> (&'static str, u32) {
    match c {
        Clef::Treble => ("G", 2),
        Clef::Bass => ("F", 4),
        Clef::Alto => ("C", 3),
        Clef::Tenor => ("C", 4),
    }
}

fn duration_to_type(d: u32, divisions: u32) -> &'static str {
    // d == divisions = quarter note. Größere Werte = längere Noten.
    let q = d as f32 / divisions.max(1) as f32;
    if q >= 4.0 { "whole" }
    else if q >= 2.0 { "half" }
    else if q >= 1.0 { "quarter" }
    else if q >= 0.5 { "eighth" }
    else if q >= 0.25 { "16th" }
    else { "32nd" }
}

fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

fn today() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let days_since_epoch = secs / 86400;
    let (y, m, d) = days_to_ymd(days_since_epoch as i64);
    format!("{:04}-{:02}-{:02}", y, m, d)
}

fn days_to_ymd(days: i64) -> (i32, u32, u32) {
    // Simple Calendar-Berechnung ab 1970-01-01.
    let mut y = 1970i32;
    let mut d = days as i64;
    while d >= 365 + (is_leap(y) as i64) {
        d -= 365 + (is_leap(y) as i64);
        y += 1;
    }
    let month_lens = [31u32, 28 + is_leap(y) as u32, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    let mut m = 0;
    while m < 12 && d >= month_lens[m] as i64 {
        d -= month_lens[m] as i64;
        m += 1;
    }
    (y, (m + 1) as u32, (d + 1) as u32)
}

fn is_leap(y: i32) -> bool {
    (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{Measure, NoteheadKind, Part, PitchStep, Point, ScoreNote, TimeSignature};

    #[test]
    fn export_minimal_score() {
        let score = Score {
            work_title: "Test".into(),
            composer: "Anon.".into(),
            parts: vec![Part {
                id: "P1".into(),
                name: "Stimme".into(),
                measures: vec![Measure {
                    number: 1,
                    divisions: 4,
                    notes: vec![ScoreNote {
                        midi: 60,
                        step: PitchStep::C,
                        alter: 0,
                        octave: 4,
                        duration: 4,
                        onset: 0,
                        voice: 1,
                        kind: NoteheadKind::Filled,
                        center: Point { x: 0.0, y: 0.0 },
                        augmentation_dots: 0,
                        in_chord: false,
            is_rest: false,
                    }],
                    time_signature: Some(TimeSignature { beats: 4, beat_type: 4 }),
                    key_signature: Some(omr_core::KeySignature { fifths: 0 }),
                    clef: Some(Clef::Treble),
                    ..Default::default()
                }],
            }],
        };
        let xml = export(&score).unwrap();
        assert!(xml.contains("<step>C</step>"));
        assert!(xml.contains("<octave>4</octave>"));
        assert!(xml.contains("<duration>4</duration>"));
        assert!(xml.contains("<beats>4</beats>"));
        assert!(xml.contains("<sign>G</sign>"));
    }
}
