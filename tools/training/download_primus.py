"""
download_primus.py

Lädt das PrIMuS-Datenset (Printed Images of Music Staves) herunter.
Das ist DAS GROSSE öffentliche Datenset für gedruckte Notation:

PrIMuS:
  Repository: https://grfia.dlsi.ua.es/primus/
  Lizenz:     CC-BY-NC-SA 4.0 (für Forschung kostenlos, keine kommerzielle Nutzung)
  Stats:      87.678 incipits, ~6 GB komprimiert, ~20 GB entpackt
  Format:     Pro Sample: PNG-Bild (1 Notenzeile) + Semantische Annotation
              im Plain-Text-Format

Camera-PrIMuS:
  Camera-augmentationsversion mit ähnlichen Effekten wie reale Scans:
  Skew, JPEG-Compression, Lighting-Variations, Smudges.

Zwei Varianten verfügbar:
  - "Sub-corpora" mit ~22.000 incipits (kleiner, schneller)
  - Full-Corpus mit allen 87.678 incipits

Aufruf:
    python download_primus.py \\
        --output data/primus \\
        --variant subset           # oder 'full' fuer alles
        --extract-symbols          # nach download in patches umwandeln

⚠️ LIZENZ: PrIMuS ist NC (non-commercial). Sheetstorm darf das Modell mit
PrIMuS-Daten trainieren NUR für nicht-kommerzielle Forschung. Für
kommerzielle Nutzung: nur Bravura-Synth + User-Annotations.
"""
from __future__ import annotations
import argparse
import io
import os
import sys
import urllib.request
import zipfile
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Bekannte PrIMuS-URLs (Stand 2024 — können sich aendern):
# Subset (~22k incipits, "primus_subset.tgz"): kleiner, schneller download
# Full (~87k): grosser corpus
PRIMUS_URLS = {
    "subset": "https://grfia.dlsi.ua.es/primus/packages/primusCalvoRizoAppliedSciences2018.tgz",
    "camera": "https://grfia.dlsi.ua.es/primus/packages/CameraPrIMuS.tgz",
}


def try_download(url: str, dest: Path) -> bool:
    if dest.exists() and dest.stat().st_size > 100_000:
        print(f"  Bereits vorhanden: {dest} ({dest.stat().st_size // 1048576} MB)")
        return True
    print(f"  Download {url}\n  -> {dest}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(url, timeout=120) as resp:
            total = int(resp.headers.get("Content-Length", 0))
            with dest.open("wb") as out:
                downloaded = 0
                chunk_size = 1024 * 1024
                while True:
                    chunk = resp.read(chunk_size)
                    if not chunk: break
                    out.write(chunk)
                    downloaded += len(chunk)
                    if total > 0:
                        pct = 100.0 * downloaded / total
                        print(f"\r    {downloaded // 1048576} / {total // 1048576} MB ({pct:.1f}%%)", end="")
                print()
        return True
    except Exception as e:
        print(f"\n  FEHLER: {e}", file=sys.stderr)
        if dest.exists() and dest.stat().st_size < 100_000:
            dest.unlink()
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=Path("data/primus"))
    ap.add_argument("--variant", default="subset", choices=["subset", "camera", "both"])
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)

    targets = []
    if args.variant in ("subset", "both"):
        targets.append(("subset", PRIMUS_URLS["subset"], args.output / "primus_subset.tgz"))
    if args.variant in ("camera", "both"):
        targets.append(("camera", PRIMUS_URLS["camera"], args.output / "primus_camera.tgz"))

    for name, url, path in targets:
        print(f"\n[{name}]")
        if not try_download(url, path):
            print(f"  Konnte {name} nicht laden — Skript-Template laesst sich erweitern.")

    print("\n=== Anleitung Symbol-Extraktion (next steps) ===")
    print("PrIMuS-Format pro Sample:")
    print("  package_AA_NNN/")
    print("    package_AA_NNN.png         # Notenzeile als PNG")
    print("    package_AA_NNN.semantic    # 'gClef.G2 + keySignature.GM ...'")
    print("    package_AA_NNN.agnostic    # Symbol-Sequence ohne Position")
    print()
    print("Fuer CNN-Training: pro Sample bbox-detection auf PNG laufen lassen, ")
    print("Patches mit Klassen-Label (aus semantic) extrahieren -> data/training/<class>/")


if __name__ == "__main__":
    main()
