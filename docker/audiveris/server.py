"""
Sheetstorm Audiveris HTTP Wrapper.

Copyright (C) 2026 Sheetstorm contributors.

This file is part of Sheetstorm and is licensed under the GNU Affero
General Public License v3.0 (AGPL-3.0-only). See ../LICENSE.md and
LICENSE.AGPL.txt for details.

This wrapper invokes the Audiveris OMR engine (also AGPL-3.0) over its
batch CLI and exposes a small HTTP API so the rest of Sheetstorm can talk
to it without linking against AGPL Java code.

Endpoints:
- GET  /health         → "ok"
- POST /recognize      → multipart 'pdf' file, returns MusicXML (plain XML)

Implementation:
- Schreibt PDF in temp-Dir
- Ruft `Audiveris -batch -export -output <tmp>` auf
- Audiveris liefert .mxl (gezippte MusicXML); wir packen es aus und liefern das
  unkomprimierte plain MusicXML, damit OSMD im Browser es direkt rendern kann.
- Räumt auf

Robustheit: Audiveris ist langsam (5-60s pro PDF), daher request-timeout 5min.
"""
import os
import shutil
import subprocess
import tempfile
import logging
import zipfile
from pathlib import Path
from flask import Flask, request, jsonify, Response
from waitress import serve

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("audiveris-server")

app = Flask(__name__)

@app.get("/health")
def health():
    """Detail-Status: Audiveris-CLI verfügbar? PDF→XML-Pipeline ready?"""
    cli_ok = False
    cli_version = None
    try:
        res = subprocess.run(["Audiveris", "-help"], capture_output=True, text=True, timeout=10)
        cli_ok = res.returncode == 0 or ("Usage" in (res.stdout + res.stderr))
        # Audiveris -version würde besser passen, aber -help hat den Banner mit Version
        for line in (res.stdout + res.stderr).splitlines():
            if "Audiveris" in line and any(c.isdigit() for c in line):
                cli_version = line.strip()
                break
    except Exception as e:
        cli_version = f"error: {e}"
    return jsonify({
        "ok": cli_ok,
        "audiveris": cli_version,
        "tessdata": os.environ.get("TESSDATA_PREFIX"),
    }), (200 if cli_ok else 503)


def extract_plain_musicxml(file_path: Path) -> bytes | None:
    """Falls .mxl: ZIP entpacken, das eigentliche .xml-Rootfile lesen."""
    if file_path.suffix.lower() == ".mxl":
        try:
            with zipfile.ZipFile(file_path, "r") as zf:
                # MXL hat META-INF/container.xml mit <rootfile full-path="..."/>
                names = zf.namelist()
                root = None
                if "META-INF/container.xml" in names:
                    container = zf.read("META-INF/container.xml").decode("utf-8", errors="ignore")
                    import re
                    m = re.search(r'full-path="([^"]+)"', container)
                    if m:
                        root = m.group(1)
                # Fallback: erstes .xml im Archiv ausserhalb META-INF
                if root is None:
                    for n in names:
                        if n.endswith(".xml") and not n.startswith("META-INF/"):
                            root = n
                            break
                if root is None:
                    log.error("MXL hat kein XML-Rootfile: %s", names)
                    return None
                log.info("MXL entpackt: rootfile=%s", root)
                return zf.read(root)
        except zipfile.BadZipFile:
            # .mxl war wider Erwarten kein ZIP (manche Audiveris-Versionen schreiben raw .xml mit Endung .mxl)
            return file_path.read_bytes()
    return file_path.read_bytes()


@app.post("/recognize")
def recognize():
    if "pdf" not in request.files:
        return jsonify({"error": "missing 'pdf' file"}), 400
    f = request.files["pdf"]

    with tempfile.TemporaryDirectory() as tmp:
        in_path = Path(tmp) / "input.pdf"
        out_dir = Path(tmp) / "out"
        out_dir.mkdir()
        f.save(in_path)
        log.info("Recognize: %s (%d bytes)", in_path, in_path.stat().st_size)

        cmd = [
            "Audiveris", "-batch",
            "-export", "-output", str(out_dir),
            str(in_path),
        ]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except subprocess.TimeoutExpired:
            log.error("Audiveris timeout (>600s)")
            return jsonify({"error": "audiveris timeout", "kind": "timeout"}), 504

        if res.returncode != 0:
            tail = (res.stderr or res.stdout)[-2000:]
            log.error("Audiveris exit %d: %s", res.returncode, tail)
            return jsonify({"error": "audiveris failed", "kind": "engine-error", "exit_code": res.returncode, "stderr": tail}), 500

        # Audiveris legt MusicXML als .mxl (gezippt) oder .xml ab
        files = list(out_dir.rglob("*.mxl")) + list(out_dir.rglob("*.xml"))
        # OMR-internen 'omr.zip' Output ignorieren
        files = [p for p in files if not p.name.endswith(".omr")]
        if not files:
            log.error("Audiveris produzierte keine MusicXML; out_dir=%s", list(out_dir.rglob("*")))
            return jsonify({"error": "no MusicXML produced"}), 500

        # Größtes File zuerst (Hauptscore vor Annexen)
        files.sort(key=lambda p: p.stat().st_size, reverse=True)
        out_file = files[0]
        log.info("Recognize: success, %s (%d bytes)", out_file.name, out_file.stat().st_size)

        body = extract_plain_musicxml(out_file)
        if body is None:
            return jsonify({"error": "could not extract musicxml"}), 500
        log.info("Returning %d bytes plain MusicXML", len(body))
        return Response(body, mimetype="application/vnd.recordare.musicxml+xml")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    log.info("Audiveris-Server hört auf :%d", port)
    # 4 Threads: Audiveris-Calls sind langlaufend (30-60 s) und CPU-bound;
    # mit nur 2 Threads stauen sich Requests bei mehreren parallelen
    # Erkennungen auf. 4 ist ein guter Kompromiss zwischen Durchsatz und
    # Speicher (jeder Audiveris-Worker zieht ~500 MB).
    serve(app, host="0.0.0.0", port=port, threads=4, expose_tracebacks=False)

