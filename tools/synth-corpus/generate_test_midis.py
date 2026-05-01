"""
generate_test_midis.py — erzeugt Test-MIDIs aus music21-Corpus + synthetisch.

Quellen:
  1) music21-Corpus: Bach-Choräle (PD), Beethoven, Mozart (eingebaut in music21)
  2) Synthetisch: Tonleitern + Arpeggios in verschiedenen Tonarten/Taktarten

Aufruf:
    python generate_test_midis.py --target data/midi --count 20

Output: data/midi/<name>.mid für jeden generierten Track.
"""
from __future__ import annotations
import argparse
import io
import sys
from pathlib import Path

# Windows-cp1252-Stdout: re-encode auf UTF-8 damit Print mit Sonderzeichen geht
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

try:
    from music21 import corpus, stream, note as m21note, meter, key, instrument, tempo
except ImportError:
    print("FEHLER: pip install music21", file=sys.stderr)
    sys.exit(2)


def export_corpus_pieces(target: Path, max_pieces: int) -> int:
    """Lädt einige Corpus-Stücke und schreibt sie als MIDI."""
    written = 0
    candidates = [
        # Bach-Choräle (4-Stimmig — mehrere Stimmen pro File)
        "bach/bwv66.6", "bach/bwv7.7", "bach/bwv8.6",
        # Mozart
        "mozart/k545/movement1",
        # Frescobaldi (PD orchestra)
        "essenFolksong/altdeu10",
    ]
    for piece_id in candidates:
        if written >= max_pieces:
            break
        try:
            score = corpus.parse(piece_id)
            safe = piece_id.replace("/", "_")
            out = target / f"corpus-{safe}.mid"
            score.write("midi", fp=str(out))
            print(f"  ok  {out.name}")
            written += 1
        except Exception as e:
            print(f"  err {piece_id}: {e}")
    return written


def make_scale(tonic_midi: int, mode: str = "major", duration_quarter: float = 0.5,
               octave_count: int = 1) -> stream.Stream:
    """Tonleiter aufwärts + abwärts."""
    s = stream.Stream()
    intervals = [0, 2, 4, 5, 7, 9, 11, 12] if mode == "major" else [0, 2, 3, 5, 7, 8, 10, 12]
    for oct_offset in range(octave_count):
        for iv in intervals:
            n = m21note.Note(midi=tonic_midi + oct_offset * 12 + iv, quarterLength=duration_quarter)
            s.append(n)
    for oct_offset in range(octave_count - 1, -1, -1):
        for iv in reversed(intervals):
            n = m21note.Note(midi=tonic_midi + oct_offset * 12 + iv, quarterLength=duration_quarter)
            s.append(n)
    return s


def make_arpeggio(root_midi: int, beats: int = 16) -> stream.Stream:
    """Triade-Arpeggio (root, third, fifth, octave) im Loop."""
    s = stream.Stream()
    pattern = [root_midi, root_midi + 4, root_midi + 7, root_midi + 12]
    for i in range(beats):
        n = m21note.Note(midi=pattern[i % 4], quarterLength=0.25)
        s.append(n)
    return s


def make_simple_march(target_midi: int = 60) -> stream.Stream:
    """Einfacher 4/4-Marsch im klassischen Stil mit Triolen + Punktierungen."""
    s = stream.Stream()
    s.append(meter.TimeSignature("4/4"))
    s.append(tempo.MetronomeMark(number=120))
    pattern = [
        # Takt 1: Achtel-Achtel-Viertel
        (target_midi, 0.5), (target_midi + 2, 0.5), (target_midi + 4, 1.0),
        (target_midi + 5, 0.5), (target_midi + 7, 0.5), (target_midi + 4, 1.0),
        # Takt 2
        (target_midi + 7, 0.75), (target_midi + 9, 0.25), (target_midi + 7, 0.5), (target_midi + 4, 0.5),
        (target_midi, 1.0), (target_midi - 1, 1.0),
    ]
    for midi_num, dur in pattern:
        s.append(m21note.Note(midi=midi_num, quarterLength=dur))
    return s


def export_synthetic_pieces(target: Path, count: int) -> int:
    """Generiert synthetische einfache MIDIs."""
    pieces = [
        ("scale-c-major-eighths",   lambda: make_scale(60, "major", 0.5, 2)),
        ("scale-g-major-quarters",  lambda: make_scale(67, "major", 1.0, 1)),
        ("scale-d-minor-eighths",   lambda: make_scale(62, "minor", 0.5, 1)),
        ("scale-bb-major-eighths",  lambda: make_scale(70, "major", 0.5, 1)),
        ("arpeggio-c",              lambda: make_arpeggio(60, 32)),
        ("arpeggio-f",              lambda: make_arpeggio(65, 32)),
        ("march-c",                 lambda: make_simple_march(60)),
        ("march-bb",                lambda: make_simple_march(70)),
    ]
    written = 0
    for name, builder in pieces:
        if written >= count:
            break
        try:
            s = builder()
            outer = stream.Score()
            part = stream.Part()
            part.insert(0, instrument.Trumpet())
            for el in s:
                part.append(el)
            outer.append(part)
            out = target / f"synth-{name}.mid"
            outer.write("midi", fp=str(out))
            print(f"  ok {out.name}")
            written += 1
        except Exception as e:
            print(f"  fail {name}: {e}")
    return written


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=Path, required=True)
    ap.add_argument("--count", type=int, default=10)
    args = ap.parse_args()

    args.target.mkdir(parents=True, exist_ok=True)
    print(f"Generiere bis zu {args.count} Test-MIDIs in {args.target}")

    print("\n[Corpus-Pieces]")
    n_corpus = export_corpus_pieces(args.target, args.count)

    if n_corpus < args.count:
        print("\n[Synthetic-Pieces]")
        export_synthetic_pieces(args.target, args.count - n_corpus)

    final = list(args.target.glob("*.mid"))
    print(f"\nFertig — {len(final)} MIDIs in {args.target}")


if __name__ == "__main__":
    main()
