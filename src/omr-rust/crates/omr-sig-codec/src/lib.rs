//! omr-sig-codec ΓÇö bidirektionale Konvertierung zwischen MusicXML und Sig.
//!
//! # ├£berblick
//!
//! Dieser Crate implementiert den vollst├ñndigen Import (MusicXML ΓåÆ SIG) und
//! Export (SIG ΓåÆ MusicXML), einschlie├ƒlich stabiler ID-Erhaltung via
//! [`IdMapping`].
//!
//! # Beispiel
//!
//! ```no_run
//! use omr_sig_codec::SigCodec;
//!
//! let xml = r#"<score-partwise>...</score-partwise>"#;
//! let codec = SigCodec::new();
//! let sig = codec.import_musicxml(xml).unwrap();
//! let out = codec.export_musicxml(&sig).unwrap();
//! ```

pub mod exporter;
pub mod id_mapping;
pub mod importer;

#[cfg(test)]
mod tests {
    use super::*;
    use omr_sig::{inters::HeadInter, Inter};

    // ΓöÇΓöÇ Hilfsfunktionen ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

    /// Minimales XML mit einem Takt und einer Note C4.
    fn xml_one_note(note_id: &str, step: &str, octave: i8, alter: i8) -> String {
        let alter_tag = if alter != 0 {
            format!("<alter>{}</alter>", alter)
        } else {
            String::new()
        };
        format!(
            r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note id="{id}">
        <pitch><step>{step}</step>{alter}<octave>{oct}</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
    </measure>
  </part>
</score-partwise>"#,
            id = note_id,
            step = step,
            alter = alter_tag,
            oct = octave,
        )
    }

    fn count_occurrences(xml: &str, pattern: &str) -> usize {
        let mut count = 0;
        let mut pos = 0;
        while let Some(idx) = xml[pos..].find(pattern) {
            count += 1;
            pos += idx + pattern.len();
        }
        count
    }

    // ΓöÇΓöÇ Tests ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

    #[test]
    fn import_simple_score() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note id="n1">
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
      <note id="n2">
        <pitch><step>G</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
    </measure>
  </part>
</score-partwise>"#;
        let sig = SigCodec::new().import_musicxml(xml).unwrap();
        // 1 Clef + 1 Key + 1 Time + 2 Heads
        assert_eq!(sig.inter_count(), 5);
    }

    #[test]
    fn export_preserves_pitches() {
        let xml = xml_one_note("n1", "E", 5, 0);
        let codec = SigCodec::new();
        let sig = codec.import_musicxml(&xml).unwrap();
        let out = codec.export_musicxml(&sig).unwrap();
        assert!(out.contains("<step>E</step>"), "Expected E step in: {}", out);
        assert!(out.contains("<octave>5</octave>"), "Expected octave 5 in: {}", out);
    }

    #[test]
    fn roundtrip_minimal_score() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>2</fifths></key>
        <time><beats>3</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note id="n1">
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
      <note id="n2">
        <pitch><step>G</step><octave>4</octave></pitch>
        <duration>4</duration>
        <type>quarter</type>
      </note>
    </measure>
  </part>
</score-partwise>"#;
        let result = SigCodec::new().roundtrip(xml).unwrap();
        // Gleiche Anzahl Takte und Noten
        assert_eq!(
            count_occurrences(xml, "<measure"),
            count_occurrences(&result, "<measure"),
            "measure count mismatch"
        );
        assert_eq!(
            count_occurrences(xml, "<note"),
            count_occurrences(&result, "<note"),
            "note count mismatch"
        );
        assert!(result.contains("<step>C</step>"));
        assert!(result.contains("<step>G</step>"));
    }

    #[test]
    fn import_handles_multiple_parts() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
  <part id="P2">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>F</sign><line>4</line></clef>
      </attributes>
      <note><pitch><step>G</step><octave>2</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
</score-partwise>"#;
        let sig = SigCodec::new().import_musicxml(xml).unwrap();
        // 2 Parts ├ù (1 Clef + 1 Key + 1 Time + 1 Head) = 8 Inters
        assert_eq!(sig.inter_count(), 8);

        let heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
        assert_eq!(heads.len(), 2);
        let mut system_idxs: Vec<u32> =
            heads.iter().filter_map(|h| h.meta.system_idx).collect();
        system_idxs.sort();
        assert_eq!(system_idxs, vec![0, 1], "Parts should have distinct system_idx");
    }

    #[test]
    fn import_preserves_note_ids() {
        let xml = xml_one_note("note_abc", "D", 4, 0);
        let (sig, mapping) = SigCodec::new().import_musicxml_with_mapping(&xml).unwrap();

        let heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
        assert_eq!(heads.len(), 1);
        let head_id = heads[0].id();
        assert_eq!(
            mapping.xml_id_for(head_id),
            Some("note_abc"),
            "Expected xml_id 'note_abc' for the imported head"
        );
        assert_eq!(mapping.inter_id_for("note_abc"), Some(head_id));
    }

    #[test]
    fn export_with_keysig_writes_fifths() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>3</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
    </measure>
  </part>
</score-partwise>"#;
        let codec = SigCodec::new();
        let sig = codec.import_musicxml(xml).unwrap();
        let out = codec.export_musicxml(&sig).unwrap();
        assert!(out.contains("<fifths>3</fifths>"), "Expected fifths=3 in: {}", out);
    }

    #[test]
    fn export_with_timesig_writes_beats() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>3</beats><beat-type>8</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
    </measure>
  </part>
</score-partwise>"#;
        let codec = SigCodec::new();
        let sig = codec.import_musicxml(xml).unwrap();
        let out = codec.export_musicxml(&sig).unwrap();
        assert!(out.contains("<beats>3</beats>"), "Expected beats=3 in: {}", out);
        assert!(out.contains("<beat-type>8</beat-type>"), "Expected beat-type=8 in: {}", out);
    }

    #[test]
    fn import_sets_pitch_correctly_c4() {
        let xml = xml_one_note("n1", "C", 4, 0);
        let sig = SigCodec::new().import_musicxml(&xml).unwrap();
        let heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
        assert_eq!(heads.len(), 1);
        let h = heads[0];
        assert_eq!(h.midi, 60, "C4 should be MIDI 60, got {}", h.midi);
        assert_eq!(h.step, omr_core::PitchStep::C);
        assert_eq!(h.octave, 4);
        assert_eq!(h.alter, 0);
    }

    #[test]
    fn import_sets_pitch_correctly_bb3() {
        // Bb3 = BΓÖ¡3 = step=B, alter=-1, octave=3 ΓåÆ MIDI 58
        let xml = xml_one_note("n1", "B", 3, -1);
        let sig = SigCodec::new().import_musicxml(&xml).unwrap();
        let heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
        assert_eq!(heads.len(), 1);
        let h = heads[0];
        assert_eq!(h.midi, 58, "Bb3 should be MIDI 58, got {}", h.midi);
        assert_eq!(h.step, omr_core::PitchStep::B);
        assert_eq!(h.octave, 3);
        assert_eq!(h.alter, -1);
    }

    #[test]
    fn empty_sig_exports_minimal_xml() {
        let sig = omr_sig::sig::Sig::new();
        let out = SigCodec::new().export_musicxml(&sig).unwrap();
        assert!(out.contains("<score-partwise"), "Missing score-partwise");
        assert!(out.contains("<measure"), "Missing measure");
        assert!(out.contains("</score-partwise>"), "Missing closing tag");
    }

    #[test]
    fn import_midi_calculation_multiple_notes() {
        // G4 = MIDI 67, A5 = MIDI 81
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note id="n1"><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
      <note id="n2"><pitch><step>A</step><octave>5</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
</score-partwise>"#;
        let sig = SigCodec::new().import_musicxml(xml).unwrap();
        let mut heads: Vec<&HeadInter> = sig.typed_inters::<HeadInter>().collect();
        heads.sort_by_key(|h| h.meta.bounds.x);
        assert_eq!(heads.len(), 2);
        assert_eq!(heads[0].midi, 67, "G4 = MIDI 67");
        assert_eq!(heads[1].midi, 81, "A5 = MIDI 81");
    }

    #[test]
    fn export_multipart_writes_separate_parts() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
  <part id="P2">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>F</sign><line>4</line></clef>
      </attributes>
      <note><pitch><step>F</step><octave>2</octave></pitch><duration>4</duration></note>
    </measure>
  </part>
</score-partwise>"#;
        let codec = SigCodec::new();
        let sig = codec.import_musicxml(xml).unwrap();
        let out = codec.export_musicxml(&sig).unwrap();
        // Zwei separate <part>-Elemente
        assert_eq!(count_occurrences(&out, "<part "), 2, "Expected 2 parts in output");
        assert!(out.contains("<step>C</step>"), "Missing C5");
        assert!(out.contains("<step>F</step>"), "Missing F2");
    }

    #[test]
    fn import_rest_creates_rest_inter() {
        let xml = r#"<?xml version="1.0"?>
<score-partwise>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <rest/>
        <duration>4</duration>
        <type>quarter</type>
      </note>
    </measure>
  </part>
</score-partwise>"#;
        let sig = SigCodec::new().import_musicxml(xml).unwrap();
        // 3 Attribute-Inters + 1 RestInter
        assert_eq!(sig.inter_count(), 4);
        use omr_sig::inter::InterKind;
        let rests: Vec<_> = sig.inters_of_kind(InterKind::Rest).collect();
        assert_eq!(rests.len(), 1, "Expected 1 RestInter");
    }
}

pub use id_mapping::IdMapping;

use omr_sig::sig::Sig;

/// Fehler beim MusicXML Γåö Sig Codec.
#[derive(thiserror::Error, Debug)]
pub enum CodecError {
    /// XML-Syntaxfehler.
    #[error("XML parse error: {0}")]
    XmlParse(String),
    /// Pflicht-Element fehlt.
    #[error("Missing required element: {0}")]
    MissingElement(String),
    /// Taktangabe ung├╝ltig (z.B. beats=0).
    #[error("Invalid time signature: {0}")]
    InvalidTimeSig(String),
    /// Unbekannter Pitch-Step (nicht CΓÇôB).
    #[error("Invalid pitch step: {0}")]
    InvalidStep(String),
}

/// Bidirektionaler MusicXML Γåö SIG Codec.
pub struct SigCodec {
    /// Divisions pro Viertelnote (default: 4).
    pub divisions: u32,
}

impl Default for SigCodec {
    fn default() -> Self {
        Self::new()
    }
}

impl SigCodec {
    /// Erstellt einen neuen Codec mit divisions=4.
    pub fn new() -> Self {
        Self { divisions: 4 }
    }

    /// Importiert MusicXML als String zu einem neuen Sig.
    ///
    /// Stable IDs aus MusicXML `<note id="..."/>` werden in der
    /// zur├╝ckgegebenen `IdMapping` gespeichert (via
    /// [`import_musicxml_with_mapping`]).
    pub fn import_musicxml(&self, xml: &str) -> Result<Sig, CodecError> {
        importer::import(xml, self.divisions).map(|(sig, _)| sig)
    }

    /// Importiert MusicXML und liefert zus├ñtzlich das ID-Mapping.
    pub fn import_musicxml_with_mapping(
        &self,
        xml: &str,
    ) -> Result<(Sig, IdMapping), CodecError> {
        importer::import(xml, self.divisions)
    }

    /// Exportiert einen Sig als MusicXML-String.
    ///
    /// Heads werden sortiert nach `(system_idx, measure_number, bbox.x)`.
    pub fn export_musicxml(&self, sig: &Sig) -> Result<String, CodecError> {
        exporter::export(sig, self.divisions)
    }

    /// Round-trip: import dann export. Gibt das exportierte XML zur├╝ck.
    pub fn roundtrip(&self, xml: &str) -> Result<String, CodecError> {
        let sig = self.import_musicxml(xml)?;
        self.export_musicxml(&sig)
    }
}
