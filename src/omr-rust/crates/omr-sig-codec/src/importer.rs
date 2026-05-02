//! MusicXML ΓåÆ Sig Importer.
//!
//! Parst eine `score-partwise` MusicXML-Datei und baut daraus einen SIG auf.
//! F├╝r jede `<part>` wird `system_idx` hochgez├ñhlt. Noten ohne `<pitch>`
//! (Pausen) werden als `RestInter` behandelt und ├╝bersprungen (noch nicht
//! als vollst├ñndiger RestInter modelliert).

use omr_core::{NoteheadKind, PitchStep, Point, Rect};
use omr_sig::{
    grade::Grade,
    inter::{InterKind, InterMeta},
    inters::{ClefInter, ClefType, HeadInter, KeySignatureInter, RestInter, TimeSignatureInter},
    sig::Sig,
};
use quick_xml::{events::Event, Reader};

use crate::{id_mapping::IdMapping, CodecError};

/// Importiert MusicXML und liefert `(Sig, IdMapping)`.
pub(crate) fn import(
    xml: &str,
    default_divisions: u32,
) -> Result<(Sig, IdMapping), CodecError> {
    let mut sig = Sig::new();
    let mut id_mapping = IdMapping::new();
    let mut reader = Reader::from_str(xml);

    // State-Flags
    let mut in_attributes = false;
    let mut in_note = false;
    let mut in_pitch = false;
    let mut in_key = false;
    let mut in_time = false;
    let mut in_clef = false;

    // Kontext
    let mut part_idx: u32 = 0;
    let mut measure_number: u32 = 1;
    let mut current_tag: Option<String> = None;

    // Attribut-Akkumulation (pro <attributes>-Block)
    let mut divisions: u32 = default_divisions;
    let mut key_fifths: Option<i8> = None;
    let mut time_beats: Option<u8> = None;
    let mut time_beat_type: Option<u8> = None;
    let mut clef_sign: Option<String> = None;
    let mut clef_line: Option<u8> = None;

    // Noten-Akkumulation (pro <note>)
    let mut note_xml_id: Option<String> = None;
    let mut note_step: Option<PitchStep> = None;
    let mut note_octave: Option<i8> = None;
    let mut note_alter: i8 = 0;
    let mut note_duration: u32 = default_divisions;
    let mut note_is_rest: bool = false;
    let mut note_x_counter: u32 = 0; // synthetische x-Position pro Takt

    // Tracking: welche (part_idx, measure_number) bekamen bereits Attribute-Inters?
    let mut attrs_created_for: Option<(u32, u32)> = None;

    let mut buf = Vec::new();
    loop {
        buf.clear();
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let name = tag_name(e.name().as_ref());
                current_tag = Some(name.clone());

                match name.as_str() {
                    "part" => {
                        // part_idx bleibt w├ñhrend der Verarbeitung dieser Part konstant
                    }
                    "measure" => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"number" {
                                if let Ok(s) = std::str::from_utf8(&attr.value) {
                                    measure_number = s.trim().parse().unwrap_or(1);
                                }
                            }
                        }
                        note_x_counter = 0;
                    }
                    "attributes" => {
                        in_attributes = true;
                        // Reset Akkumulatoren f├╝r diesen Attribut-Block
                        key_fifths = None;
                        time_beats = None;
                        time_beat_type = None;
                        clef_sign = None;
                        clef_line = None;
                    }
                    "key" => in_key = true,
                    "time" => in_time = true,
                    "clef" => in_clef = true,
                    "note" => {
                        in_note = true;
                        note_xml_id = None;
                        note_step = None;
                        note_octave = None;
                        note_alter = 0;
                        note_duration = divisions;
                        note_is_rest = false;
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"id" {
                                note_xml_id =
                                    Some(String::from_utf8_lossy(&attr.value).into_owned());
                            }
                        }
                    }
                    "pitch" => in_pitch = true,
                    "rest" => {
                        if in_note {
                            note_is_rest = true;
                        }
                    }
                    _ => {}
                }
            }

            Ok(Event::Empty(ref e)) => {
                let name = tag_name(e.name().as_ref());
                if name == "rest" && in_note {
                    note_is_rest = true;
                }
            }

            Ok(Event::Text(ref t)) => {
                let cow = t.unescape().map_err(|e| CodecError::XmlParse(e.to_string()))?;
                let text = cow.trim();
                if text.is_empty() {
                    continue;
                }
                match current_tag.as_deref() {
                    Some("divisions") if in_attributes => {
                        divisions = text
                            .parse()
                            .unwrap_or(default_divisions)
                            .max(1);
                    }
                    Some("fifths") if in_key => {
                        key_fifths = text.parse().ok();
                    }
                    Some("beats") if in_time => {
                        time_beats = text.parse().ok();
                    }
                    Some("beat-type") if in_time => {
                        time_beat_type = text.parse().ok();
                    }
                    Some("sign") if in_clef => {
                        clef_sign = Some(text.to_string());
                    }
                    Some("line") if in_clef => {
                        clef_line = text.parse().ok();
                    }
                    Some("step") if in_pitch => {
                        note_step = Some(parse_step(text)?);
                    }
                    Some("octave") if in_pitch => {
                        note_octave = text.parse().ok();
                    }
                    Some("alter") if in_pitch => {
                        // alter kann Dezimalzahl sein (z.B. "-1.0") ΓåÆ parse als f32, dann runden
                        note_alter = text
                            .parse::<f32>()
                            .map(|f| f.round() as i8)
                            .unwrap_or(0);
                    }
                    Some("duration") if in_note && !in_attributes => {
                        note_duration = text.parse().unwrap_or(divisions);
                    }
                    _ => {}
                }
            }

            Ok(Event::End(ref e)) => {
                let name = tag_name(e.name().as_ref());
                current_tag = None;

                match name.as_str() {
                    "pitch" => in_pitch = false,
                    "key" => in_key = false,
                    "time" => in_time = false,
                    "clef" => in_clef = false,

                    "attributes" => {
                        in_attributes = false;
                        let key = (part_idx, measure_number);
                        if attrs_created_for != Some(key) {
                            attrs_created_for = Some(key);
                            emit_attribute_inters(
                                &mut sig,
                                part_idx,
                                measure_number,
                                clef_sign.as_deref(),
                                clef_line,
                                key_fifths,
                                time_beats,
                                time_beat_type,
                            )?;
                        }
                    }

                    "note" => {
                        in_note = false;
                        in_pitch = false;

                        if note_is_rest {
                            // RestInter erstellen
                            let id = sig.next_inter_id();
                            let x = measure_number * 1000 + note_x_counter * 10 + 50;
                            let bounds = Rect {
                                x,
                                y: part_idx * 100 + 10,
                                w: 8,
                                h: 8,
                            };
                            let mut meta =
                                InterMeta::new(id, InterKind::Rest, bounds, Grade::new(1.0));
                            meta.system_idx = Some(part_idx);
                            meta.measure_number = Some(measure_number);
                            let rest = RestInter { meta, duration: note_duration };
                            sig.add_inter(Box::new(rest));
                            note_x_counter += 1;
                        } else {
                            let step = note_step.ok_or_else(|| {
                                CodecError::MissingElement("step".to_string())
                            })?;
                            let octave = note_octave.unwrap_or(4);
                            let midi = pitch_to_midi(step, octave, note_alter);

                            let id = sig.next_inter_id();
                            let x = measure_number * 1000 + note_x_counter * 10 + 50;
                            let bounds = Rect {
                                x,
                                y: part_idx * 100 + 10,
                                w: 8,
                                h: 8,
                            };
                            let mut meta =
                                InterMeta::new(id, InterKind::Head, bounds, Grade::new(1.0));
                            meta.system_idx = Some(part_idx);
                            meta.measure_number = Some(measure_number);

                            let head = HeadInter {
                                meta,
                                center: Point {
                                    x: x as f32 + 4.0,
                                    y: part_idx as f32 * 100.0 + 14.0,
                                },
                                notehead_kind: NoteheadKind::Filled,
                                midi,
                                step,
                                octave,
                                alter: note_alter,
                                augmentation_dots: 0,
                                duration: note_duration,
                            };
                            let added_id = sig.add_inter(Box::new(head));

                            if let Some(ref xml_id) = note_xml_id {
                                id_mapping.insert(added_id, xml_id.clone());
                            }
                            note_x_counter += 1;
                        }
                    }

                    "measure" => {}
                    "part" => {
                        part_idx += 1;
                        // attrs_created_for per-part zur├╝cksetzen, damit n├ñchste Part
                        // ihre eigenen Attribute-Inters bekommt
                        attrs_created_for = None;
                    }
                    _ => {}
                }
            }

            Ok(Event::Eof) => break,
            Err(e) => return Err(CodecError::XmlParse(e.to_string())),
            _ => {}
        }
    }

    Ok((sig, id_mapping))
}

/// Erstellt Clef-, KeySignature- und TimeSignature-Inters f├╝r einen
/// Attribut-Block und f├╝gt sie dem SIG hinzu.
fn emit_attribute_inters(
    sig: &mut Sig,
    part_idx: u32,
    measure_number: u32,
    clef_sign: Option<&str>,
    clef_line: Option<u8>,
    key_fifths: Option<i8>,
    time_beats: Option<u8>,
    time_beat_type: Option<u8>,
) -> Result<(), CodecError> {
    let base_x = measure_number * 1000;
    let y = part_idx * 100;

    // ClefInter
    if let Some(sign) = clef_sign {
        let clef_type = parse_clef_type(sign, clef_line);
        let id = sig.next_inter_id();
        let bounds = Rect { x: base_x, y, w: 10, h: 20 };
        let mut meta = InterMeta::new(id, InterKind::Clef, bounds, Grade::new(1.0));
        meta.system_idx = Some(part_idx);
        meta.measure_number = Some(measure_number);
        sig.add_inter(Box::new(ClefInter {
            meta,
            clef_type,
            line: clef_line.unwrap_or(2),
        }));
    }

    // KeySignatureInter
    if let Some(fifths) = key_fifths {
        let id = sig.next_inter_id();
        let bounds = Rect { x: base_x + 15, y, w: 10, h: 20 };
        let mut meta = InterMeta::new(id, InterKind::KeySignature, bounds, Grade::new(1.0));
        meta.system_idx = Some(part_idx);
        meta.measure_number = Some(measure_number);
        sig.add_inter(Box::new(KeySignatureInter { meta, fifths }));
    }

    // TimeSignatureInter
    if let (Some(beats), Some(beat_type)) = (time_beats, time_beat_type) {
        if beats == 0 || beat_type == 0 {
            return Err(CodecError::InvalidTimeSig(format!("{}/{}", beats, beat_type)));
        }
        let id = sig.next_inter_id();
        let bounds = Rect { x: base_x + 30, y, w: 10, h: 20 };
        let mut meta = InterMeta::new(id, InterKind::TimeSignature, bounds, Grade::new(1.0));
        meta.system_idx = Some(part_idx);
        meta.measure_number = Some(measure_number);
        sig.add_inter(Box::new(TimeSignatureInter { meta, beats, beat_type }));
    }

    Ok(())
}

/// Konvertiert `<sign>` + optionale `<line>` zu `ClefType`.
fn parse_clef_type(sign: &str, line: Option<u8>) -> ClefType {
    match sign {
        "G" => ClefType::Treble,
        "F" => ClefType::Bass,
        "C" => match line {
            Some(1) => ClefType::Soprano,
            Some(3) => ClefType::Alto,
            Some(4) => ClefType::Tenor,
            _ => ClefType::Alto,
        },
        "percussion" | "Percussion" => ClefType::Percussion,
        "TAB" | "Tab" => ClefType::Tab,
        _ => ClefType::Treble,
    }
}

/// Konvertiert einen Pitch-Step-String ("C".."B") zu `PitchStep`.
fn parse_step(s: &str) -> Result<PitchStep, CodecError> {
    match s {
        "C" => Ok(PitchStep::C),
        "D" => Ok(PitchStep::D),
        "E" => Ok(PitchStep::E),
        "F" => Ok(PitchStep::F),
        "G" => Ok(PitchStep::G),
        "A" => Ok(PitchStep::A),
        "B" => Ok(PitchStep::B),
        other => Err(CodecError::InvalidStep(other.to_string())),
    }
}

/// Berechnet MIDI-Nummer aus Step, Oktave und Alter.
/// C4 = 60, C(-1) = 0.
pub(crate) fn pitch_to_midi(step: PitchStep, octave: i8, alter: i8) -> u8 {
    let base: i16 = match step {
        PitchStep::C => 0,
        PitchStep::D => 2,
        PitchStep::E => 4,
        PitchStep::F => 5,
        PitchStep::G => 7,
        PitchStep::A => 9,
        PitchStep::B => 11,
    };
    let midi = 12 * (octave as i16 + 1) + base + alter as i16;
    midi.clamp(0, 127) as u8
}

/// Hilfsfunktion: raw tag-name bytes ΓåÆ String (ohne Namespace-Pr├ñfix).
fn tag_name(bytes: &[u8]) -> String {
    let s = std::str::from_utf8(bytes).unwrap_or("");
    // Namespace-Pr├ñfix abschneiden (z.B. "xml:id" ΓåÆ "id")
    if let Some(pos) = s.rfind(':') {
        s[pos + 1..].to_string()
    } else {
        s.to_string()
    }
}
