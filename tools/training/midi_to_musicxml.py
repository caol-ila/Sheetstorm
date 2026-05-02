"""
midi_to_musicxml.py

Konvertiert MIDI-Dateien zu MusicXML, aufgeteilt nach Instrument/Track.

Pro MIDI wird pro Instrument-Track eine eigene MusicXML-Datei erzeugt.
Tempo, Time-Signature und Note-On/Off werden korrekt übernommen.

Aufruf:
    python midi_to_musicxml.py --input-dir data/midi --output-dir data/midi_xml
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from tqdm import tqdm

try:
    from music21 import converter, stream, instrument as m21instrument
    from music21 import midi as m21midi
    from music21.midi.translate import midiFileToStream
except ImportError as e:
    print(f"ERROR: {e}\n  pip install music21", file=sys.stderr)
    sys.exit(2)


# Instrument names that get their own part in the exported MusicXML
_UNNAMED = "Part"


def _safe_instrument_name(inst: m21instrument.Instrument | None, idx: int) -> str:
    """Return a filesystem-safe instrument label."""
    if inst is None:
        return f"track{idx:02d}"
    name = (
        getattr(inst, "partName", None)
        or getattr(inst, "instrumentName", None)
        or getattr(inst, "partAbbreviation", None)
        or _UNNAMED
    )
    # Sanitize for filesystem
    safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in str(name))
    return safe or f"track{idx:02d}"


def midi_to_musicxml_parts(midi_path: Path, output_dir: Path) -> list[Path]:
    """
    Parse *midi_path*, split into per-instrument parts, save as MusicXML.
    Returns list of generated MusicXML paths.
    """
    try:
        score = converter.parse(str(midi_path))
    except Exception as e:
        print(f"  WARN: cannot parse {midi_path.name}: {e}", file=sys.stderr)
        return []

    # Flatten to get all Part objects
    parts = score.parts
    if not parts:
        # Some MIDI files come back as a flat Score without Parts
        # Try treating the whole score as one part
        parts = [score]

    stem = midi_path.stem
    generated: list[Path] = []

    for idx, part in enumerate(parts):
        # Determine instrument name from the part
        inst = None
        try:
            instruments = part.getElementsByClass(m21instrument.Instrument)
            if instruments:
                inst = instruments[0]
        except Exception:
            pass

        inst_name = _safe_instrument_name(inst, idx)
        out_name = f"{stem}__{inst_name}.musicxml"
        out_path = output_dir / out_name

        if out_path.exists():
            generated.append(out_path)
            continue

        # Build a single-part score preserving tempo & time-sig from the original
        single = stream.Score()

        # Copy tempo/time-sig markings from score header
        for el in score.flat.getElementsByClass(["MetronomeMark", "TimeSignature"]):
            try:
                single.insert(el.offset, el)
            except Exception:
                pass

        single.append(part)

        try:
            single.write("musicxml", fp=str(out_path))
            generated.append(out_path)
        except Exception as e:
            print(f"  WARN: write failed {out_name}: {e}", file=sys.stderr)

    return generated


def main() -> None:
    ap = argparse.ArgumentParser(description="MIDI → MusicXML per instrument")
    ap.add_argument("--input-dir", type=Path, default=Path("data/midi"))
    ap.add_argument("--output-dir", type=Path, default=Path("data/midi_xml"))
    ap.add_argument("--max-parts", type=int, default=4,
                    help="Max instrument parts per MIDI (0 = unlimited)")
    args = ap.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    midi_files = (
        list(args.input_dir.glob("*.mid"))
        + list(args.input_dir.glob("*.midi"))
        + list(args.input_dir.glob("*.MID"))
    )

    if not midi_files:
        print(f"No MIDI files found in {args.input_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Processing {len(midi_files)} MIDI files → {args.output_dir}")

    total_xml = 0
    for midi_path in tqdm(midi_files, desc="MIDI→XML"):
        parts = midi_to_musicxml_parts(midi_path, args.output_dir)
        if args.max_parts > 0:
            parts = parts[: args.max_parts]
        total_xml += len(parts)

    all_xml = list(args.output_dir.glob("*.musicxml"))
    print(f"\nDone — {len(all_xml)} MusicXML files in {args.output_dir}")


if __name__ == "__main__":
    main()
