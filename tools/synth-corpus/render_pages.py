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
    """Verovio rendert SVG. SVG -> PNG via Playwright headless Chromium (kein cairo nötig)."""
    try:
        import verovio
    except ImportError:
        print("FEHLER: pip install verovio", file=sys.stderr)
        sys.exit(2)

    tk = verovio.toolkit()
    tk.setOptions({
        "scale": 100,
        "pageWidth": 2100,
        "pageHeight": 2970,
        "header": "auto",
        "footer": "none",
        "spacingNonLinear": 0.55,
        # Dickere Staff-Lines + dickere Stems → besser für unsere Pipeline
        # (die für gescannte Optik mit 2-3px Staff-Lines tuned ist).
        "staffLineWidth": 0.30,    # default ~0.15
        "stemWidth": 0.40,         # default ~0.20
        "barLineWidth": 0.40,      # default ~0.30
    })
    if not tk.loadFile(str(xml_path)):
        print(f"  Verovio konnte {xml_path.name} nicht laden", file=sys.stderr)
        return 0

    n_pages = tk.getPageCount()
    written = 0
    for p in range(1, n_pages + 1):
        svg = tk.renderToSVG(p)
        out_svg = out_dir / f"{xml_path.stem}-page{p}.svg"
        out_svg.write_text(svg, encoding="utf-8")
        written += 1
    return written


def svg_dir_to_png_via_playwright(svg_dir: Path, png_dir: Path, dpi: int = 300):
    """Rendert alle SVGs in svg_dir zu PNGs via Playwright headless Chromium.

    Verwendet die globale Playwright-Installation (npm install im e2e-Ordner).
    """
    try:
        from playwright.sync_api import sync_playwright  # type: ignore
    except ImportError:
        print("WARN: playwright (Python) nicht installiert. SVGs bleiben ungerendert.", file=sys.stderr)
        print("       pip install playwright + playwright install chromium", file=sys.stderr)
        return 0

    png_dir.mkdir(parents=True, exist_ok=True)
    svgs = sorted(svg_dir.glob("*.svg"))
    if not svgs:
        return 0

    written = 0
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        for svg_path in svgs:
            try:
                svg_text = svg_path.read_text(encoding="utf-8")
                page = browser.new_page(viewport={"width": 2480, "height": 3508})
                # 2480x3508 = A4 bei 300dpi
                html = f"""<!DOCTYPE html><html><head><style>
                    body, html {{ margin: 0; padding: 0; background: white; }}
                    svg {{ display: block; width: 2100px; height: auto; }}
                </style></head><body>{svg_text}</body></html>"""
                page.set_content(html)
                page.wait_for_load_state("networkidle", timeout=10_000)
                out_png = png_dir / svg_path.with_suffix(".png").name
                page.screenshot(path=str(out_png), full_page=True, omit_background=False)
                page.close()
                written += 1
            except Exception as e:
                print(f"  ERR playwright {svg_path.name}: {e}", file=sys.stderr)
        browser.close()
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

    # Falls Engine nur SVG erzeugt hat: via Playwright zu PNG rastern
    n_svg = len(list(args.output.glob("*.svg")))
    n_png_existing = len(list(args.output.glob("*.png")))
    if n_svg > 0 and n_png_existing < n_svg:
        print(f"\n[SVG -> PNG via Playwright] {n_svg - n_png_existing} fehlende PNGs rastern...")
        n_rastered = svg_dir_to_png_via_playwright(args.output, args.output, args.dpi)
        print(f"  -> {n_rastered} PNGs erzeugt")

    n_png_final = len(list(args.output.glob("*.png")))
    print(f"\nFertig - {n_png_final} PNG-Seiten in {args.output}")


if __name__ == "__main__":
    main()
