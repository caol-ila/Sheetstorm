"""
download_or_generate_midis.py

Strategie C: music21 Built-in Corpus (Public Domain) + generierte Skalen/Akkorde.

Exportiert MIDI-Dateien aus dem music21-Corpus (Bach, Beethoven, Mozart, etc.)
und generiert zusätzlich einfache melodische Sequenzen via mido.

Aufruf:
    python download_or_generate_midis.py --output data/midi --count 30
"""
from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

from tqdm import tqdm

try:
    import music21
    from music21 import corpus, midi as m21midi, stream, note, tempo, meter, instrument
    HAS_MUSIC21 = True
except ImportError:
    HAS_MUSIC21 = False
    print("music21 not available", file=sys.stderr)

try:
    import mido
    HAS_MIDO = True
except ImportError:
    HAS_MIDO = False

# ─── music21 corpus paths (built-in public domain scores) ─────────────────────
# These are bundled with music21 and are all public domain.
CORPUS_PATHS = [
    # Bach
    "bach/bwv1.6",
    "bach/bwv10.7",
    "bach/bwv103.6",
    "bach/bwv108.6",
    "bach/bwv11.6",
    "bach/bwv112.5",
    "bach/bwv116.6",
    "bach/bwv12.7",
    "bach/bwv120.8",
    "bach/bwv121.6",
    "bach/bwv122.6",
    "bach/bwv123.6",
    "bach/bwv124.6",
    "bach/bwv125.6",
    "bach/bwv126.6",
    "bach/bwv127.5",
    "bach/bwv128.5",
    "bach/bwv13.6",
    "bach/bwv130.6",
    "bach/bwv133.6",
    # Beethoven
    "beethoven/opus18no1",
    "beethoven/opus59no1",
    # Handel
    "handel/hwv56/movement1-01",
    "handel/hwv56/movement1-02",
    "handel/hwv56/movement1-03",
    "handel/hwv56/movement1-04",
    "handel/hwv56/movement1-05",
    # Miscellaneous
    "schoenberg/opus19",
    "monteverdi/madrigal.3.1",
    "monteverdi/madrigal.3.2",
    "monteverdi/madrigal.3.3",
    "monteverdi/madrigal.3.4",
    "monteverdi/madrigal.3.5",
    "monteverdi/madrigal.3.6",
]

# ─── Simple generated pieces (via mido) ───────────────────────────────────────
SCALE_PATTERNS = {
    "C_major_scale": [60, 62, 64, 65, 67, 69, 71, 72, 71, 69, 67, 65, 64, 62, 60],
    "G_major_scale": [55, 57, 59, 60, 62, 64, 66, 67, 66, 64, 62, 60, 59, 57, 55],
    "D_major_arpeggio": [62, 66, 69, 74, 69, 66, 62, 66, 69, 74, 73, 71, 69, 66, 62],
    "F_major_melody": [65, 67, 69, 70, 72, 70, 69, 67, 65, 64, 62, 60, 62, 64, 65],
    "A_minor_scale": [57, 59, 60, 62, 64, 65, 67, 69, 67, 65, 64, 62, 60, 59, 57],
    "Bb_major_scale": [58, 60, 62, 63, 65, 67, 69, 70, 69, 67, 65, 63, 62, 60, 58],
    "Eb_major_melody": [63, 65, 67, 68, 70, 68, 67, 65, 63, 62, 60, 58, 60, 62, 63],
    "trumpet_fanfare": [
        60, 64, 67, 72, 67, 64, 60, 64, 67, 72, 67, 64,
        60, 62, 64, 65, 67, 65, 64, 62, 60,
    ],
    "march_theme": [
        55, 55, 62, 62, 64, 62, 60, 59, 60, 62,
        55, 55, 67, 67, 65, 64, 62, 60, 59, 57,
    ],
    "waltz_melody": [
        60, 64, 67, 64, 60, 64, 62, 65, 69, 65,
        62, 65, 64, 67, 71, 67, 64, 67,
    ],
}


def generate_midi_from_pattern(
    pattern_name: str,
    notes: list[int],
    output_path: Path,
    ticks_per_beat: int = 480,
    bpm: int = 120,
    note_duration_beats: float = 0.5,
) -> None:
    """Generate a simple MIDI file from a note pattern using mido."""
    mid = mido.MidiFile(ticks_per_beat=ticks_per_beat)
    track = mido.MidiTrack()
    mid.tracks.append(track)

    # Tempo meta-message
    microseconds_per_beat = int(60_000_000 / bpm)
    track.append(mido.MetaMessage("set_tempo", tempo=microseconds_per_beat, time=0))
    track.append(mido.MetaMessage("time_signature", numerator=4, denominator=4, time=0))
    track.append(mido.MetaMessage("track_name", name=pattern_name, time=0))

    ticks = int(ticks_per_beat * note_duration_beats)
    velocity = 80

    for pitch in notes:
        track.append(mido.Message("note_on", note=pitch, velocity=velocity, time=0))
        track.append(mido.Message("note_off", note=pitch, velocity=0, time=ticks))

    track.append(mido.MetaMessage("end_of_track", time=0))
    mid.save(str(output_path))


def export_corpus_midi(corpus_path: str, output_dir: Path) -> bool:
    """Export a music21 corpus piece to MIDI. Returns True if successful."""
    try:
        score = corpus.parse(corpus_path)
        # Sanitize filename
        safe_name = corpus_path.replace("/", "_").replace(".", "_")
        out_file = output_dir / f"corpus_{safe_name}.mid"
        if out_file.exists():
            return True
        mf = m21midi.translate.music21ObjectToMidiFile(score)
        mf.open(str(out_file), "wb")
        mf.write()
        mf.close()
        return True
    except Exception as e:
        print(f"  WARN: corpus.parse({corpus_path!r}) failed: {e}", file=sys.stderr)
        return False


def main() -> None:
    ap = argparse.ArgumentParser(description="Download/generate MIDI corpus")
    ap.add_argument("--output", type=Path, default=Path("data/midi"),
                    help="Output directory for MIDI files")
    ap.add_argument("--count", type=int, default=30,
                    help="Target number of MIDI files")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    random.seed(args.seed)

    exported = 0

    # Phase 1: music21 built-in corpus
    if HAS_MUSIC21:
        print("Phase 1: Exporting music21 built-in corpus (public domain)...")
        corpus_list = CORPUS_PATHS[:]
        random.shuffle(corpus_list)
        for path in tqdm(corpus_list, desc="Corpus"):
            if exported >= args.count:
                break
            ok = export_corpus_midi(path, args.output)
            if ok:
                exported += 1
        print(f"  Corpus-Phase: {exported} MIDIs exported")
    else:
        print("music21 not installed — skipping corpus phase", file=sys.stderr)

    # Phase 2: Generated patterns via mido
    if HAS_MIDO and exported < args.count:
        print("Phase 2: Generating simple melodic patterns via mido...")
        remaining = args.count - exported
        patterns = list(SCALE_PATTERNS.items())
        # Repeat patterns with different BPMs if needed
        extended: list[tuple[str, list[int]]] = []
        for bpm in [80, 100, 120, 140]:
            for name, notes in patterns:
                extended.append((f"{name}_bpm{bpm}", notes))

        for idx, (name, notes) in enumerate(extended[:remaining]):
            bpm = int(name.split("_bpm")[-1]) if "_bpm" in name else 120
            out_file = args.output / f"gen_{name}.mid"
            if not out_file.exists():
                generate_midi_from_pattern(name, notes, out_file, bpm=bpm)
            exported += 1

        print(f"  Generated-Phase: now {exported} total MIDIs")
    elif not HAS_MIDO:
        print("mido not available — cannot generate patterns", file=sys.stderr)

    # Summary
    all_midis = list(args.output.glob("*.mid")) + list(args.output.glob("*.midi"))
    print(f"\nDone — {len(all_midis)} MIDI files in {args.output}")
    for f in sorted(all_midis):
        print(f"  {f.name}")


if __name__ == "__main__":
    main()
