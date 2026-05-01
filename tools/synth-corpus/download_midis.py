"""
download_midis.py — sammelt Public-Domain-Blasmusik-MIDIs aus offenen Archiven.

Funktioniert ohne Web-Crawl: nutzt die kuratierte Liste in PD_MIDI_URLS
(URLs die direkt eine .mid-Datei zurueckgeben). Fuegt einfach neue URLs hinzu.

Aufruf:
    python download_midis.py --target data/midi --max 50
"""
from __future__ import annotations
import argparse
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("FEHLER: pip install requests", file=sys.stderr)
    sys.exit(2)


# Kuratierte Liste von Public-Domain-Blasmusik-MIDIs.
# Format: (display_name, direct_url)
# WICHTIG: nur URLs die direkt .mid liefern (kein HTML-Wrapper).
PD_MIDI_URLS: list[tuple[str, str]] = [
    # Sousa-Märsche (Public Domain, vor 1929)
    ("sousa-stars-and-stripes-forever",
     "https://www.musictheoryteachers.com/wp-content/uploads/2020/05/stars_and_stripes_forever.mid"),
    ("sousa-washington-post",
     "https://upload.wikimedia.org/wikipedia/commons/3/3b/Washington_Post_March_-_Sousa.mid"),
    # Klassische Märsche
    ("filmore-american-patrol",
     "https://upload.wikimedia.org/wikipedia/commons/a/a4/American_Patrol.mid"),
    # Public-Domain-Klassik (orchestral)
    ("bach-air-on-g-string",
     "https://upload.wikimedia.org/wikipedia/commons/9/91/Air_G_string.mid"),
    ("mozart-eine-kleine-nachtmusik",
     "https://upload.wikimedia.org/wikipedia/commons/9/9d/Mozart_-_Eine_kleine_Nachtmusik_-_1._Allegro.mid"),
    # … hier weitere kuratierte URLs einfuegen
]


def download_one(name: str, url: str, target: Path, timeout: int = 60) -> Path | None:
    out = target / f"{name}.mid"
    if out.exists():
        print(f"  {out.name}: bereits vorhanden, skip")
        return out
    try:
        r = requests.get(url, timeout=timeout, headers={"User-Agent": "sheetstorm-synth-corpus/1.0"})
        r.raise_for_status()
        # Sanity: MIDI-Files starten mit "MThd"
        if not r.content[:4] == b"MThd":
            print(f"  {name}: kein MIDI (header: {r.content[:8]!r}), skip")
            return None
        out.write_bytes(r.content)
        print(f"  {out.name}: {len(r.content)} bytes")
        return out
    except Exception as e:
        print(f"  {name}: Fehler {e}", file=sys.stderr)
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=Path, required=True)
    ap.add_argument("--max", type=int, default=999)
    args = ap.parse_args()

    args.target.mkdir(parents=True, exist_ok=True)
    print(f"Lade max. {args.max} MIDIs nach {args.target}")
    n = 0
    for name, url in PD_MIDI_URLS[: args.max]:
        result = download_one(name, url, args.target)
        if result:
            n += 1
        time.sleep(0.5)
    print(f"\nFertig — {n} MIDIs heruntergeladen.")
    print(f"\nTipp: zusaetzliche MIDIs einfach manuell nach {args.target} kopieren.")
    print("Empfohlen: IMSLP, Mutopia, BandMusic-PDF-Library (Links siehe README.md).")


if __name__ == "__main__":
    main()
