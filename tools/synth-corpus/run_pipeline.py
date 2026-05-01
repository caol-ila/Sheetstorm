"""
run_pipeline.py — End-to-End: download → split → render → augment → validate.

Ausführung:
    python run_pipeline.py --max-midis 5

Default-Verzeichnisse: data/midi, data/musicxml, data/pages, data/augmented
"""
from __future__ import annotations
import argparse
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent


def run(cmd: list[str], desc: str, allow_fail: bool = False) -> bool:
    print(f"\n=== {desc} ===")
    print("  $ " + " ".join(str(c) for c in cmd))
    try:
        subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        msg = f"  FEHLER: {e}"
        if allow_fail:
            print(msg + "  (skip - allow_fail)")
            return True
        print(msg, file=sys.stderr)
        return False
    except FileNotFoundError as e:
        print(f"  FEHLER: {e}", file=sys.stderr)
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-root", type=Path, default=HERE / "data")
    ap.add_argument("--max-midis", type=int, default=10)
    ap.add_argument("--variants", type=int, default=3)
    ap.add_argument("--server", default="http://localhost:8091")
    ap.add_argument("--limit", type=int, default=20, help="Validate nur N Seiten")
    ap.add_argument("--use-generator", action="store_true", default=True,
                    help="Nutzt generate_test_midis.py statt download_midis.py (Default)")
    ap.add_argument("--skip-render", action="store_true",
                    help="Skip Step 3+4+5 (nur MIDI -> MusicXML + GT-JSON)")
    args = ap.parse_args()

    midi_dir = args.data_root / "midi"
    xml_dir = args.data_root / "musicxml"
    pages_dir = args.data_root / "pages"
    aug_dir = args.data_root / "augmented"
    report = args.data_root / "report.json"

    py = sys.executable
    step1_cmd = [py, str(HERE / "generate_test_midis.py"),
                 "--target", str(midi_dir), "--count", str(args.max_midis)]
    steps = [
        (step1_cmd, "Step 1: Test-MIDI-Generierung (Corpus + Synthetic)", False),
        ([py, str(HERE / "midi_to_parts.py"),
          "--input", str(midi_dir), "--output", str(xml_dir)],
         "Step 2: MIDI -> MusicXML pro Stimme + Ground-Truth-JSON", False),
    ]
    if not args.skip_render:
        steps.extend([
            ([py, str(HERE / "render_pages.py"),
              "--input", str(xml_dir), "--output", str(pages_dir)],
             "Step 3: MusicXML -> PNG-Seiten (optional - benoetigt ImageMagick/MuseScore)", True),
            ([py, str(HERE / "augment.py"),
              "--input", str(pages_dir), "--output", str(aug_dir),
              "--variants", str(args.variants)],
             "Step 4: Augmentation (Noise/Skew/JPEG)", True),
            ([py, str(HERE / "validate.py"),
              "--pages", str(aug_dir), "--truth", str(xml_dir),
              "--report", str(report), "--server", args.server,
              "--limit", str(args.limit)],
             "Step 5: Pipeline-Validation gegen Ground-Truth", True),
        ])
    for cmd, desc, allow_fail in steps:
        if not run(cmd, desc, allow_fail=allow_fail):
            print(f"\nAbgebrochen bei: {desc}", file=sys.stderr)
            sys.exit(1)
    print(f"\nFertig - Report: {report}")
    print(f"  MIDIs:    {len(list(midi_dir.glob('*.mid')))}")
    print(f"  MusicXML: {len(list(xml_dir.glob('*.musicxml')))}")
    print(f"  GT-JSON:  {len(list(xml_dir.glob('*.gt.json')))}")
    print(f"  PNGs:     {len(list(pages_dir.glob('*.png'))) if pages_dir.exists() else 0}")
    print(f"  Augment:  {len(list(aug_dir.glob('*.png'))) if aug_dir.exists() else 0}")


if __name__ == "__main__":
    main()
