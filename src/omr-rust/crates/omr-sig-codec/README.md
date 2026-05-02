# omr-sig-codec

Bidirektionaler MusicXML ↔ SIG Codec für den Sheetstorm OMR-Stack.

## Überblick

Dieser Crate implementiert:

- **Import**: MusicXML (`score-partwise`) → SIG (`omr-sig`)  
  Erzeugt `ClefInter`, `KeySignatureInter`, `TimeSignatureInter`, `HeadInter` und `RestInter`.
  Stabile IDs aus `<note id="..."/>` werden via `IdMapping` erhalten.

- **Export**: SIG → MusicXML  
  Sortiert Heads nach `(system_idx, measure_number, bbox.x)`.
  Jedes `system_idx` wird als separate `<part>` ausgegeben.

- **Round-Trip**: import → export, inhaltlich äquivalentes XML.

## Schnellstart

```rust
use omr_sig_codec::SigCodec;

let xml = r#"<score-partwise version="4.0">
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
    </measure>
  </part>
</score-partwise>"#;

let codec = SigCodec::new();

// Import
let sig = codec.import_musicxml(xml).unwrap();
assert_eq!(sig.inter_count(), 4); // 1 Clef + 1 Key + 1 Time + 1 Head

// Export
let out = codec.export_musicxml(&sig).unwrap();
assert!(out.contains("<step>C</step>"));

// Round-Trip
let roundtripped = codec.roundtrip(xml).unwrap();
assert!(roundtripped.contains("<step>C</step>"));
```

## Stable-ID Mapping

```rust
let (sig, mapping) = codec.import_musicxml_with_mapping(xml).unwrap();
// mapping.xml_id_for(inter_id) → Some("n1")
// mapping.inter_id_for("n1")   → Some(InterId(...))
```

## Tests

```powershell
cd src/omr-rust
cargo test -p omr-sig-codec
```
