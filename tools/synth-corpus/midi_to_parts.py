"""
midi_to_parts.py — splittet MIDI-Dateien in MusicXML pro Track/Stimme.

Voraussetzung: pip install music21

Ausgabe pro MIDI:
    OUTPUT/{midi_name}-{track_name}-{voice_idx}.musicxml

Plus Ground-Truth-JSON pro Track:
    OUTPUT/{midi_name}-{track_name}-{voice_idx}.gt.json
mit allen Notes (midi, onset_in_quarters, duration_in_quarters).
"""
from __future__ import annotations
import argparse
import json
import re
import sys
from pathlib import Path

try:
    from music21 import converter, midi, instrument, pitch as m21pitch
except ImportError:
    print("FEHLER: pip install music21", file=sys.stderr)
    sys.exit(2)


def safe_filename(s: str) -> str:
    s = re.sub(r"[^\w\-]+", "_", s).strip("_")
    return s or "track"


def split_midi(midi_path: Path, out_dir: Path) -> list[Path]:
    """Lädt eine MIDI-Datei und schreibt pro Track/Voice eine MusicXML."""
    out_dir.mkdir(parents=True, exist_ok=True)
    score = converter.parse(str(midi_path))
    name = safe_filename(midi_path.stem)
    written: list[Path] = []

    parts = list(score.parts)
    if not parts:
        print(f"  WARN: keine Parts in {midi_path.name}", file=sys.stderr)
        return written

    for idx, part in enumerate(parts):
        # Instrument-Name aus Part holen
        instr = part.getInstrument(returnDefault=True)
        instr_name = (instr.partName or instr.instrumentName
                      or f"track{idx}").strip()
        if not instr_name or instr_name == "None":
            instr_name = f"track{idx}"

        # Eigenes Score-Objekt mit nur diesem Part
        single = part.makeNotation(inPlace=False)
        if single is None:
            single = part

        out_xml = out_dir / f"{name}-{safe_filename(instr_name)}-{idx:02d}.musicxml"
        out_gt = out_dir / f"{name}-{safe_filename(instr_name)}-{idx:02d}.gt.json"

        try:
            single.write("musicxml", fp=str(out_xml))
        except Exception as e:
            print(f"  ERR write musicxml: {e}", file=sys.stderr)
            continue

        # Ground-Truth: alle Notes mit (midi, onset, duration) als Quarter-Lengths
        notes_gt = []
        for n in part.flatten().notes:
            try:
                if n.isChord:
                    for p in n.pitches:
                        notes_gt.append({
                            "midi": p.midi,
                            "step": p.step,
                            "alter": int(p.alter or 0),
                            "octave": p.octave,
                            "onset_q": float(n.offset),
                            "duration_q": float(n.duration.quarterLength),
                            "in_chord": True,
                        })
                else:
                    p = n.pitch
                    notes_gt.append({
                        "midi": p.midi,
                        "step": p.step,
                        "alter": int(p.alter or 0),
                        "octave": p.octave,
                        "onset_q": float(n.offset),
                        "duration_q": float(n.duration.quarterLength),
                        "in_chord": False,
                    })
            except Exception:
                continue

        gt_doc = {
            "source_midi": midi_path.name,
            "track_index": idx,
            "instrument": instr_name,
            "n_notes": len(notes_gt),
            "notes": notes_gt,
        }
        out_gt.write_text(json.dumps(gt_doc, indent=2, ensure_ascii=False), encoding="utf-8")
        written.append(out_xml)
        print(f"  {out_xml.name}: {len(notes_gt)} Notes")

    return written


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=Path, required=True, help="Verzeichnis mit MIDI-Dateien")
    ap.add_argument("--output", type=Path, required=True, help="Zielverzeichnis für MusicXML+GT")
    ap.add_argument("--ext", default=".mid,.midi", help="MIDI-Dateiendungen")
    args = ap.parse_args()

    exts = [e.strip().lower() for e in args.ext.split(",")]
    midi_files = sorted([p for p in args.input.rglob("*") if p.suffix.lower() in exts])
    print(f"Gefundene MIDIs: {len(midi_files)}")

    total = 0
    for m in midi_files:
        print(f"[{m.name}]")
        try:
            written = split_midi(m, args.output)
            total += len(written)
        except Exception as e:
            print(f"  FEHLER: {e}", file=sys.stderr)
    print(f"\nFertig — {total} MusicXML-Dateien in {args.output}")


if __name__ == "__main__":
    main()
