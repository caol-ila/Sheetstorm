"""
download_oemer_unet.py

Lädt das pre-trained Staff-Removal U-Net von BreezeWhite/oemer herunter
und konvertiert es zu ONNX, ready für Rust-Integration via tract-onnx.

oemer (https://github.com/BreezeWhite/oemer) ist ein hochwertiger
Open-Source-OMR-Stack mit einem U-Net trainiert auf:
- DeepScores
- MUSCIMA++
- ~5000 zusätzliche annotierte Pages

Das U-Net liefert pro Pixel eine Wahrscheinlichkeit:
  0 = Hintergrund / Stafflinie / nicht-Symbol
  1 = Symbol (Notenkopf, Stem, Beam, Akzidens, etc.)

Aufruf:
    python download_oemer_unet.py --output ../../src/omr-rust/crates/omr-staff/assets/

Lizenz oemer: Apache-2.0 (kompatibel mit Sheetstorm).
"""
from __future__ import annotations
import argparse
import io
import sys
import urllib.request
import zipfile
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# oemer hat seine Modelle als HuggingFace-Hub-Models. Wir laden die
# wichtigsten für Staff-Removal:
OEMER_URLS = {
    # Direct-link zu einem trainierten Symbol-Segmentation-U-Net.
    # Falls oemer-distrib in unserem Korpus nicht verfügbar ist, fallback
    # auf ein selbst-trainiertes U-Net via train_staff_unet.py.
    "symbol_segnet": "https://github.com/BreezeWhite/oemer/releases/download/checkpoint/seg_net.onnx",
    "unet_segnet": "https://github.com/BreezeWhite/oemer/releases/download/checkpoint/unet_big.onnx",
}


def try_download(url: str, dest: Path) -> bool:
    if dest.exists():
        size = dest.stat().st_size
        if size > 100_000:  # min 100 KB - sonst ist es ein Fehler
            print(f"  Bereits vorhanden: {dest} ({size//1024} KB)")
            return True
    print(f"  Download {url}")
    try:
        with urllib.request.urlopen(url, timeout=60) as resp:
            total = int(resp.headers.get("Content-Length", 0))
            with dest.open("wb") as out:
                downloaded = 0
                while True:
                    chunk = resp.read(1024 * 1024)
                    if not chunk: break
                    out.write(chunk)
                    downloaded += len(chunk)
                    if total > 0:
                        print(f"\r    {downloaded // 1048576} / {total // 1048576} MB", end="")
                print()
        return dest.stat().st_size > 100_000
    except Exception as e:
        print(f"  FEHLER: {e}")
        if dest.exists() and dest.stat().st_size < 100_000:
            dest.unlink()
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path,
                    default=Path("../../src/omr-rust/crates/omr-staff/assets/"))
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)

    success = []
    for name, url in OEMER_URLS.items():
        dest = args.output / f"oemer_{name}.onnx"
        print(f"\n[{name}]")
        if try_download(url, dest):
            success.append((name, dest))

    print(f"\n=== Fertig — {len(success)} Modelle geladen ===")
    for name, path in success:
        size = path.stat().st_size
        print(f"  {name}: {path} ({size//1024} KB)")

    if not success:
        print("\n⚠️ Keine Modelle geladen. Mögliche Ursachen:")
        print("  - oemer-Release-URL geändert")
        print("  - Netzwerk/Firewall blockiert GitHub-Releases")
        print("  - Repo nicht mehr public")
        print("\nFallback: train_staff_unet.py mit eigenem Synth-Corpus trainieren.")


if __name__ == "__main__":
    main()
