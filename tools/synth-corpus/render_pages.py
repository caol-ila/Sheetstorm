"""
render_pages.py — rendert MusicXML zu PNG/PDF mittels Verovio (default) oder MuseScore CLI.

Voraussetzung:
    pip install verovio cairosvg Pillow

Aufruf:
    python render_pages.py --input data/musicxml --output data/pages --dpi 300

Output: pro {name}.musicxml entstehen {name}-page1.png, {name}-page2.png, ...
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path


def render_with_verovio(xml_path: Path, out_dir: Path, dpi: int = 300):
    try:
        import verovio
        import cairosvg
    except ImportError:
        print("FEHLER: pip install verovio cairosvg", file=sys.stderr)
        sys.exit(2)

    tk = verovio.toolkit()
    tk.setOptions({
        "scale": 50,
        "pageWidth": 2100,    # in 1/100 mm
        "pageHeight": 2970,   # = A4
        "header": "auto",
        "footer": "none",
        "spacingNonLinear": 0.55,
    })
    if not tk.loadFile(str(xml_path)):
        print(f"  Verovio konnte {xml_path.name} nicht laden", file=sys.stderr)
        return 0

    n_pages = tk.getPageCount()
    written = 0
    for p in range(1, n_pages + 1):
        svg = tk.renderToSVG(p)
        out_png = out_dir / f"{xml_path.stem}-page{p}.png"
        # SVG → PNG via cairosvg (DPI hochsetzen für gute Qualität)
        try:
            cairosvg.svg2png(
                bytestring=svg.encode("utf-8"),
                write_to=str(out_png),
                output_width=int(2100 / 25.4 * dpi / 100),
                output_height=int(2970 / 25.4 * dpi / 100),
            )
            written += 1
        except Exception as e:
            print(f"  ERR svg2png ({xml_path.stem} p{p}): {e}", file=sys.stderr)
    return written


def render_with_musescore(xml_path: Path, out_dir: Path, mscore_exe: str):
    """Alternative: MuseScore CLI (besseres Layout, Standard-Notensatz-Optik)."""
    import subprocess
    out_pattern = str(out_dir / f"{xml_path.stem}.png")
    try:
        subprocess.run(
            [mscore_exe, "-O", out_pattern, str(xml_path)],
            check=True, capture_output=True, timeout=60,
        )
        # MuseScore generiert {name}-1.png, {name}-2.png, ...
        return len(list(out_dir.glob(f"{xml_path.stem}-*.png")))
    except subprocess.CalledProcessError as e:
        print(f"  MuseScore-Fehler: {e.stderr.decode(errors='ignore')[:200]}", file=sys.stderr)
        return 0
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        print(f"  MuseScore-Fehler: {e}", file=sys.stderr)
        return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--engine", choices=["verovio", "musescore"], default="verovio")
    ap.add_argument("--mscore-exe", default=r"C:\Program Files\MuseScore 4\bin\MuseScore4.exe")
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    xml_files = sorted(args.input.rglob("*.musicxml"))
    print(f"Gefundene MusicXML: {len(xml_files)}")

    total_pages = 0
    for xml in xml_files:
        print(f"[{xml.name}] (engine={args.engine})")
        if args.engine == "verovio":
            n = render_with_verovio(xml, args.output, args.dpi)
        else:
            n = render_with_musescore(xml, args.output, args.mscore_exe)
        total_pages += n
        print(f"  -> {n} Seite(n)")
    print(f"\nFertig — {total_pages} PNG-Seiten in {args.output}")


if __name__ == "__main__":
    main()
