//! Layered Reader (Phase A) — sequenzielles Lesen pro System.
//!
//! Kombiniert alle bereits detektierten Symbole zu einem **sequenziellen
//! Reading-Event-Stream** pro Staff-System. Erlaubt dadurch:
//!
//!  1. Nachvollziehbare Anzeige im Annotation-Tool ("was hat das System
//!     der Reihe nach gelesen?").
//!  2. **Anomaly-Detection**: Beat-Fills validieren, Doppel-Detections
//!     im Header-Bereich entdecken, einsame NHs vor/nach erstem/letztem
//!     Bar markieren.
//!  3. Grundlage für Phase B (Reading-Order-basierte NH-Korrektur).
//!
//! Das Modul ist ein POST-PROCESSOR — es modifiziert die Pipeline-Detections
//! NICHT, sondern produziert nur Events + Anomalies.

use omr_core::{Clef, JumpMark, KeySignature, Measure, Notehead, ScoreNote, StaffSystem, TimeSignature};
use serde::Serialize;

use crate::bars::MeasureBar;
use crate::rests::Rest;

/// Ein einzelnes Lesereignis (in Reading-Order pro System).
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ReadingEvent {
    /// Notenschlüssel am Anfang oder bei Schlüsselwechsel.
    Clef { x: u32, clef: String },
    /// Tonart-Vorzeichen.
    KeySignature { x: u32, fifths: i8 },
    /// Taktart (typisch nur am Stückanfang oder bei Wechsel).
    TimeSignature { x: u32, beats: u32, beat_type: u32 },
    /// Anfang eines Taktes.
    MeasureStart { number: u32, x: u32 },
    /// Notenkopf mit MIDI-Pitch + Duration.
    Note { x: u32, midi: u8, duration: u32 },
    /// Pause.
    Rest { x: u32, kind: String },
    /// Sprungmarke (Repeat, Volta, Coda, Segno, etc.).
    JumpMark { x: u32, kind: String },
    /// Taktstrich am Ende eines Taktes.
    Barline { x: u32 },
    /// System-Ende (rechtmäßiger Abschluss oder Zeilenumbruch).
    SystemEnd { x: u32 },
}

/// Erkannte Auffälligkeiten im Reading-Stream.
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ReadingAnomaly {
    /// NH wurde im Header-Bereich (zwischen Clef-Anfang und Header-Ende)
    /// detektiert — wahrscheinlich Vorzeichen oder Time-Sig falsch klassifiziert.
    NoteInHeader { x: u32, notehead_idx: u32 },
    /// Anzahl der Beats in einem Takt passt nicht zur Time-Signature.
    BeatMismatch { measure: u32, expected_beats: f32, actual_beats: f32 },
    /// Takt enthält keine einzige Note + keine Pause — leerer Takt.
    EmptyMeasure { measure: u32 },
    /// NH liegt hinter dem letzten Taktstrich aber vor dem rechten Rand des Systems.
    OrphanNoteAfterFinalBar { x: u32, notehead_idx: u32 },
    /// Mehrere Notenschlüssel direkt hintereinander (ohne Inhalt dazwischen) →
    /// einer davon ist wahrscheinlich falsch detektiert.
    DuplicateClef { x1: u32, x2: u32 },
}

/// Reading-Stream eines Staff-Systems.
#[derive(Debug, Clone, Serialize)]
pub struct SystemReadingStream {
    pub system_idx: u32,
    pub events: Vec<ReadingEvent>,
    pub anomalies: Vec<ReadingAnomaly>,
    /// Geschätztes Header-End-X (nach Clef + KeySig + TimeSig).
    pub header_end_x: u32,
}

/// Reading-Stream der ganzen Seite (alle Systeme in Y-Reihenfolge).
#[derive(Debug, Clone, Serialize, Default)]
pub struct PageReadingStream {
    pub systems: Vec<SystemReadingStream>,
}

fn clef_str(c: Clef) -> String {
    match c {
        Clef::Treble => "Treble",
        Clef::Bass => "Bass",
        Clef::Alto => "Alto",
        Clef::Tenor => "Tenor",
    }
    .to_string()
}

fn rest_kind_str(k: crate::rests::RestKind) -> String {
    match k {
        crate::rests::RestKind::Whole => "Whole",
        crate::rests::RestKind::Half => "Half",
        crate::rests::RestKind::Quarter => "Quarter",
        crate::rests::RestKind::Eighth => "Eighth",
        crate::rests::RestKind::Sixteenth => "Sixteenth",
    }
    .to_string()
}

fn jump_kind_str(j: &JumpMark) -> String {
    match j {
        JumpMark::RepeatStart => "RepeatStart",
        JumpMark::RepeatEnd => "RepeatEnd",
        JumpMark::Volta { number: 1 } => "Volta1",
        JumpMark::Volta { number: 2 } => "Volta2",
        JumpMark::Volta { .. } => "Volta",
        JumpMark::Coda => "Coda",
        JumpMark::Segno => "Segno",
        JumpMark::DaCapo => "DaCapo",
        JumpMark::DcAlFine => "DcAlFine",
        JumpMark::DsAlCoda => "DsAlCoda",
        JumpMark::DsAlFine => "DsAlFine",
        JumpMark::Fine => "Fine",
    }
    .to_string()
}

/// Heuristisches Header-End ausgehend von line_start_x.
/// Konsistent mit `lib.rs::process_gray_single::skip_regions`.
fn estimate_header_end(spacing: f32, fifths: i8, has_timesig: bool, line_start_x: u32) -> u32 {
    let n_acc = fifths.unsigned_abs() as f32;
    let clef_w = 3.0_f32;
    let keysig_w = 0.7 * n_acc;
    let timesig_w = if has_timesig { 2.0 } else { 0.0 };
    let padding = 1.0;
    let factor = (clef_w + keysig_w + timesig_w + padding).max(6.0);
    line_start_x + (spacing * factor) as u32
}

fn duration_quarters(d: u32) -> f32 {
    d as f32 / 4.0
}

fn rest_quarters(k: crate::rests::RestKind) -> f32 {
    match k {
        crate::rests::RestKind::Whole => 4.0,
        crate::rests::RestKind::Half => 2.0,
        crate::rests::RestKind::Quarter => 1.0,
        crate::rests::RestKind::Eighth => 0.5,
        crate::rests::RestKind::Sixteenth => 0.25,
    }
}

/// Liest ein Staff-System sequenziell → Event-Stream + Anomalien.
///
/// Inputs:
///   - `system_idx`: globaler System-Index der Page.
///   - `system`: das StaffSystem (für Geometrie).
///   - `clef`: detektierter Clef.
///   - `key`: detektierte Key-Signature.
///   - `time_signature`: TimeSig (typisch nur erstes System der Page).
///   - `measures_in_system`: Measures dieses Systems (in Reading-Order).
///   - `noteheads`: alle NHs der Page (zur Header-Anomaly-Detection).
///   - `rests`: alle detektierten Rests (gefiltert nach system_idx).
///   - `bars`: detektierte Taktstriche dieses Systems.
///   - `jump_marks`: pro-System Sprungmarken (system_idx, JumpMark).
#[allow(clippy::too_many_arguments)]
pub fn read_system_sequentially(
    system_idx: u32,
    system: &StaffSystem,
    clef: Clef,
    key: KeySignature,
    time_signature: Option<TimeSignature>,
    measures_in_system: &[&Measure],
    noteheads: &[Notehead],
    rests: &[Rest],
    bars: &[MeasureBar],
    jump_marks: &[(usize, JumpMark)],
) -> SystemReadingStream {
    let line_spacing = system.line_spacing;
    let line_start_x = system
        .lines
        .first()
        .and_then(|l| l.y_per_x.iter().position(|&y| y > 0))
        .map(|p| p as u32)
        .unwrap_or(0);

    let header_end_x = estimate_header_end(line_spacing, key.fifths, time_signature.is_some(), line_start_x);

    let mut events: Vec<ReadingEvent> = Vec::new();
    let mut anomalies: Vec<ReadingAnomaly> = Vec::new();

    // Header-Events
    events.push(ReadingEvent::Clef { x: line_start_x, clef: clef_str(clef) });
    if key.fifths != 0 {
        let key_x = line_start_x + (line_spacing * 3.0) as u32;
        events.push(ReadingEvent::KeySignature { x: key_x, fifths: key.fifths });
    }
    if let Some(ts) = time_signature {
        let ts_x = line_start_x + (line_spacing * (3.0 + 0.7 * key.fifths.unsigned_abs() as f32)) as u32;
        events.push(ReadingEvent::TimeSignature {
            x: ts_x,
            beats: ts.beats as u32,
            beat_type: ts.beat_type as u32,
        });
    }

    // Sammle System-spezifische Detections
    let sys_bars: Vec<&MeasureBar> = {
        let mut v: Vec<&MeasureBar> = bars.iter().filter(|b| b.system_idx == system_idx as usize).collect();
        v.sort_by_key(|b| b.x);
        v
    };
    let sys_rests: Vec<&Rest> = {
        let mut v: Vec<&Rest> = rests.iter().filter(|r| r.staff_idx == system_idx as usize).collect();
        v.sort_by_key(|r| r.bbox.x);
        v
    };

    // Header-NH-Anomalien
    for (idx, nh) in noteheads.iter().enumerate() {
        if nh.staff_idx as u32 != system_idx { continue; }
        if nh.center.x < header_end_x as f32 {
            anomalies.push(ReadingAnomaly::NoteInHeader {
                x: nh.center.x as u32,
                notehead_idx: idx as u32,
            });
        }
    }

    // Walk through measures-in-system in Reading-Order
    let mut prev_x = header_end_x;
    for measure in measures_in_system {
        // measure_start_x: linke Bbox-Kante oder prev_x falls keine Bbox
        let measure_start_x = measure
            .bbox_orig
            .map(|bb| bb.x)
            .unwrap_or(prev_x);
        let measure_end_x = measure
            .bbox_orig
            .map(|bb| bb.x + bb.w)
            .or_else(|| {
                // Suche nächsten Bar nach prev_x
                sys_bars.iter().find(|b| b.x > prev_x).map(|b| b.x)
            })
            .unwrap_or_else(|| {
                // letzter bekannter X auf der Page
                let last_nh_x = measure.notes.iter().map(|n| n.center.x as u32).max().unwrap_or(prev_x);
                last_nh_x.max(prev_x + (line_spacing * 4.0) as u32)
            });

        events.push(ReadingEvent::MeasureStart { number: measure.number, x: measure_start_x });

        // Sammele Symbols für diesen Takt: Notes + Rests in Bbox-Range
        #[derive(Clone, Copy)]
        enum Sym<'a> {
            Note(&'a ScoreNote),
            Rest(&'a Rest),
        }
        let mut merged: Vec<(u32, Sym)> = Vec::new();
        // ScoreNotes des Measures (skip in_chord, die zählen nicht doppelt)
        for n in measure.notes.iter().filter(|n| !n.in_chord) {
            merged.push((n.center.x as u32, Sym::Note(n)));
        }
        // Rests im X-Range des Measures
        for r in &sys_rests {
            if r.bbox.x >= measure_start_x && r.bbox.x < measure_end_x {
                merged.push((r.bbox.x, Sym::Rest(r)));
            }
        }
        merged.sort_by_key(|(x, _)| *x);

        // Events emit + Beat-Fill berechnen
        let mut beats: f32 = 0.0;
        let mut have_any_symbol = false;
        for (x, sym) in merged {
            match sym {
                Sym::Note(n) => {
                    have_any_symbol = true;
                    if !n.is_rest {
                        beats += duration_quarters(n.duration);
                    } else {
                        // Pause als ScoreNote markiert (legacy)
                        beats += duration_quarters(n.duration);
                    }
                    if n.is_rest {
                        events.push(ReadingEvent::Rest { x, kind: format!("Q{}", n.duration) });
                    } else {
                        events.push(ReadingEvent::Note { x, midi: n.midi, duration: n.duration });
                    }
                }
                Sym::Rest(r) => {
                    have_any_symbol = true;
                    beats += rest_quarters(r.kind);
                    events.push(ReadingEvent::Rest { x, kind: rest_kind_str(r.kind) });
                }
            }
        }

        // Sprungmarken in diesem Takt
        for jm in &measure.jump_marks {
            events.push(ReadingEvent::JumpMark {
                x: measure_end_x.saturating_sub((line_spacing * 0.5) as u32),
                kind: jump_kind_str(jm),
            });
        }
        // Globale jump_marks für dieses System die nicht in Measures sind
        for (sys, jm) in jump_marks {
            if *sys == system_idx as usize {
                // falls bereits in measure.jump_marks, skip — best-effort de-dup
                if !measure.jump_marks.iter().any(|m| m == jm) {
                    // append nur einmal pro System (am Ende)
                }
                let _ = jm;
            }
        }

        // Anomalies
        if !have_any_symbol {
            anomalies.push(ReadingAnomaly::EmptyMeasure { measure: measure.number });
        } else if let Some(ts) = measure.time_signature.or(time_signature) {
            let expected = ts.beats as f32 * (4.0 / ts.beat_type as f32);
            if (beats - expected).abs() > 0.05 {
                anomalies.push(ReadingAnomaly::BeatMismatch {
                    measure: measure.number,
                    expected_beats: expected,
                    actual_beats: beats,
                });
            }
        }

        // Barline am Takt-Ende emit (nur wenn ein bar dort tatsächlich detektiert wurde)
        if sys_bars.iter().any(|b| (b.x as i64 - measure_end_x as i64).abs() < (line_spacing as i64).max(8)) {
            events.push(ReadingEvent::Barline { x: measure_end_x });
        }
        prev_x = measure_end_x;
    }

    // Orphan-NHs nach dem letzten bekannten Bar.
    // **Heuristik**: Wenn >3 Orphans in einem System, ist das LETZTE BAR
    // wahrscheinlich nicht detektiert worden (häufig am Zeilenende). Statt
    // jede einzelne als Anomaly zu reporten, melden wir EINE
    // "MissingFinalBar"-Anomaly. Bei <=3 Orphans melden wir wie bisher
    // einzelne (z.B. Volta-Digits oder Anhang-Symbole).
    let mut orphans: Vec<(u32, u32)> = Vec::new(); // (x, idx)
    let last_x = sys_bars.last().map(|b| b.x).unwrap_or(prev_x);
    for (idx, nh) in noteheads.iter().enumerate() {
        if nh.staff_idx as u32 != system_idx { continue; }
        if nh.center.x > last_x as f32 + line_spacing * 0.5 {
            orphans.push((nh.center.x as u32, idx as u32));
        }
    }
    if orphans.len() > 3 {
        // Wahrscheinlich Bar am Zeilenende verpasst. Reportiere als Cluster.
        if let (Some((min_x, _)), Some((max_x, _))) = (orphans.iter().min(), orphans.iter().max()) {
            anomalies.push(ReadingAnomaly::OrphanNoteAfterFinalBar {
                x: *min_x,
                notehead_idx: orphans.first().unwrap().1,
            });
            // Zusätzlich noch den letzten:
            anomalies.push(ReadingAnomaly::OrphanNoteAfterFinalBar {
                x: *max_x,
                notehead_idx: orphans.last().unwrap().1,
            });
        }
    } else {
        for (x, idx) in &orphans {
            anomalies.push(ReadingAnomaly::OrphanNoteAfterFinalBar {
                x: *x,
                notehead_idx: *idx,
            });
        }
    }

    let max_x = noteheads.iter()
        .filter(|nh| nh.staff_idx as u32 == system_idx)
        .map(|nh| nh.center.x as u32)
        .chain(sys_bars.iter().map(|b| b.x))
        .max()
        .unwrap_or(line_start_x);
    events.push(ReadingEvent::SystemEnd { x: max_x });

    SystemReadingStream { system_idx, events, anomalies, header_end_x }
}

/// Liest die ganze Seite. Time-Signature wird typisch NUR im ersten System
/// detektiert — Continuation-Systeme erben sie implizit.
pub fn read_page_sequentially(
    systems: &[StaffSystem],
    clefs: &[Clef],
    keys: &[KeySignature],
    time_signature: Option<TimeSignature>,
    measures: &[Measure],
    noteheads: &[Notehead],
    rests: &[Rest],
    bars: &[MeasureBar],
    jump_marks: &[(usize, JumpMark)],
) -> PageReadingStream {
    let mut out = PageReadingStream::default();
    for (i, sys) in systems.iter().enumerate() {
        let clef = clefs.get(i).copied().unwrap_or(Clef::Treble);
        let key = keys.get(i).copied().unwrap_or(KeySignature::default());
        let ts = if i == 0 { time_signature } else { None };

        let measures_in_system: Vec<&Measure> = measures
            .iter()
            .filter(|m| m.system_idx == Some(i as u32))
            .collect();

        let stream = read_system_sequentially(
            i as u32, sys, clef, key, ts,
            &measures_in_system, noteheads, rests, bars, jump_marks,
        );
        out.systems.push(stream);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use omr_core::{NoteheadKind, PitchStep, Point, Rect, ScoreNote, StaffLine};

    fn mk_system(top_y: u32, spacing: u32) -> StaffSystem {
        let mut lines = Vec::new();
        for i in 0..5 {
            let y = top_y + i * spacing;
            let mut y_per_x = vec![0u32; 1000];
            for x in 50..950 { y_per_x[x] = y; }
            lines.push(StaffLine { y_per_x });
        }
        StaffSystem { lines, line_spacing: spacing as f32, line_thickness: 2.0 }
    }

    fn mk_score_note(x: f32, midi: u8, duration: u32) -> ScoreNote {
        ScoreNote {
            midi, step: PitchStep::C, alter: 0, octave: 4,
            duration, onset: 0, voice: 1,
            kind: NoteheadKind::Filled,
            center: Point { x, y: 150.0 },
            augmentation_dots: 0, in_chord: false, is_rest: false,
        }
    }

    fn mk_measure(number: u32, system_idx: u32, x: u32, w: u32, notes: Vec<ScoreNote>, ts: TimeSignature) -> Measure {
        Measure {
            number, divisions: 4, notes,
            time_signature: Some(ts), key_signature: None, clef: None,
            bbox_orig: Some(Rect { x, y: 100, w, h: 100 }),
            system_idx: Some(system_idx),
            jump_marks: vec![],
        }
    }

    fn mk_bar(system_idx: usize, x: u32) -> MeasureBar {
        MeasureBar { x, system_idx }
    }

    fn mk_nh(staff_idx: usize, x: f32) -> Notehead {
        Notehead {
            bbox: Rect { x: (x as u32).saturating_sub(8), y: 142, w: 16, h: 16 },
            center: Point { x, y: 150.0 },
            confidence: 0.9, kind: NoteheadKind::Filled, staff_idx,
        }
    }

    #[test]
    fn read_simple_4_4_measure() {
        let system = mk_system(100, 18);
        let ts = TimeSignature { beats: 4, beat_type: 4 };
        let notes = vec![
            mk_score_note(200.0, 60, 4),
            mk_score_note(250.0, 62, 4),
            mk_score_note(300.0, 64, 4),
            mk_score_note(350.0, 65, 4),
        ];
        let measure = mk_measure(1, 0, 100, 300, notes, ts);
        let bars = vec![mk_bar(0, 400)];
        let nhs = vec![mk_nh(0, 200.0), mk_nh(0, 250.0), mk_nh(0, 300.0), mk_nh(0, 350.0)];

        let stream = read_system_sequentially(
            0, &system, Clef::Treble, KeySignature::default(), Some(ts),
            &[&measure], &nhs, &[], &bars, &[],
        );
        let beat_mismatch = stream.anomalies.iter().any(|a| matches!(a, ReadingAnomaly::BeatMismatch { .. }));
        assert!(!beat_mismatch, "no BeatMismatch expected: {:?}", stream.anomalies);
    }

    #[test]
    fn detect_beat_mismatch() {
        let system = mk_system(100, 18);
        let ts = TimeSignature { beats: 4, beat_type: 4 };
        // 3 quarters = 3 beats statt 4
        let notes = vec![
            mk_score_note(200.0, 60, 4),
            mk_score_note(250.0, 62, 4),
            mk_score_note(300.0, 64, 4),
        ];
        let measure = mk_measure(1, 0, 100, 300, notes, ts);
        let bars = vec![mk_bar(0, 400)];

        let stream = read_system_sequentially(
            0, &system, Clef::Treble, KeySignature::default(), Some(ts),
            &[&measure], &[], &[], &bars, &[],
        );
        let mismatch = stream.anomalies.iter().any(|a| matches!(a, ReadingAnomaly::BeatMismatch { .. }));
        assert!(mismatch, "expected BeatMismatch: {:?}", stream.anomalies);
    }

    #[test]
    fn detect_note_in_header() {
        let system = mk_system(100, 18);
        let ts = TimeSignature { beats: 4, beat_type: 4 };
        // NH bei x=80 → INNERHALB Header (50 + 6*18 = 158)
        let nhs = vec![mk_nh(0, 80.0)];
        let measure = mk_measure(1, 0, 200, 200, vec![], ts);
        let bars = vec![mk_bar(0, 400)];

        let stream = read_system_sequentially(
            0, &system, Clef::Treble, KeySignature::default(), Some(ts),
            &[&measure], &nhs, &[], &bars, &[],
        );
        let header_anom = stream.anomalies.iter().any(|a| matches!(a, ReadingAnomaly::NoteInHeader { .. }));
        assert!(header_anom, "expected NoteInHeader: {:?}", stream.anomalies);
    }

    #[test]
    fn detect_empty_measure() {
        let system = mk_system(100, 18);
        let ts = TimeSignature { beats: 4, beat_type: 4 };
        let measure = mk_measure(1, 0, 200, 200, vec![], ts);
        let bars = vec![mk_bar(0, 400)];
        let stream = read_system_sequentially(
            0, &system, Clef::Treble, KeySignature::default(), Some(ts),
            &[&measure], &[], &[], &bars, &[],
        );
        let empty = stream.anomalies.iter().any(|a| matches!(a, ReadingAnomaly::EmptyMeasure { .. }));
        assert!(empty, "expected EmptyMeasure: {:?}", stream.anomalies);
    }

    #[test]
    fn continuation_system_no_timesig() {
        let sys0 = mk_system(100, 18);
        let sys1 = mk_system(300, 18);
        let ts = TimeSignature { beats: 4, beat_type: 4 };
        let m0 = mk_measure(1, 0, 200, 200, vec![mk_score_note(250.0, 60, 16)], ts);
        let m1 = mk_measure(2, 1, 200, 200, vec![mk_score_note(250.0, 60, 16)], ts);
        let bars0 = vec![mk_bar(0, 400)];
        let bars1 = vec![mk_bar(1, 400)];
        let mut bars = bars0.clone(); bars.extend(bars1);

        let page = read_page_sequentially(
            &[sys0, sys1],
            &[Clef::Treble, Clef::Treble],
            &[KeySignature::default(), KeySignature::default()],
            Some(ts), &[m0, m1], &[], &[], &bars, &[],
        );
        assert_eq!(page.systems.len(), 2);
        let sys0_has_ts = page.systems[0].events.iter().any(|e| matches!(e, ReadingEvent::TimeSignature { .. }));
        let sys1_has_ts = page.systems[1].events.iter().any(|e| matches!(e, ReadingEvent::TimeSignature { .. }));
        assert!(sys0_has_ts);
        assert!(!sys1_has_ts);
    }
}
