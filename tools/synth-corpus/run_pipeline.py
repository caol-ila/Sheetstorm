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


def run(cmd: list[str], desc: str) -> bool:
    print(f"\n=== {desc} ===")
    print("  $ " + " ".join(str(c) for c in cmd))
    try:
        r = subprocess.run(cmd, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  FEHLER: {e}", file=sys.stderr)
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
    args = ap.parse_args()

    midi_dir = args.data_root / "midi"
    xml_dir = args.data_root / "musicxml"
    pages_dir = args.data_root / "pages"
    aug_dir = args.data_root / "augmented"
    report = args.data_root / "report.json"

    py = sys.executable
    steps = [
        ([py, str(HERE / "download_midis.py"), "--target", str(midi_dir),
          "--max", str(args.max_midis)],
         "Step 1: MIDI-Download"),
        ([py, str(HERE / "midi_to_parts.py"),
          "--input", str(midi_dir), "--output", str(xml_dir)],
         "Step 2: MIDI -> MusicXML pro Stimme + Ground-Truth-JSON"),
        ([py, str(HERE / "render_pages.py"),
          "--input", str(xml_dir), "--output", str(pages_dir)],
         "Step 3: MusicXML -> PNG-Seiten"),
        ([py, str(HERE / "augment.py"),
          "--input", str(pages_dir), "--output", str(aug_dir),
          "--variants", str(args.variants)],
         "Step 4: Augmentation (Noise/Skew/JPEG)"),
        ([py, str(HERE / "validate.py"),
          "--pages", str(aug_dir), "--truth", str(xml_dir),
          "--report", str(report), "--server", args.server,
          "--limit", str(args.limit)],
         "Step 5: Pipeline-Validation gegen Ground-Truth"),
    ]
    for cmd, desc in steps:
        if not run(cmd, desc):
            print(f"\nAbgebrochen bei: {desc}", file=sys.stderr)
            sys.exit(1)
    print(f"\n✓ Fertig — Report: {report}")


if __name__ == "__main__":
    main()
