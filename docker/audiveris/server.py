"""
Sheetstorm Audiveris HTTP Wrapper.

Endpoints:
- GET  /health         → "ok"
- POST /recognize      → multipart 'pdf' file, returns MusicXML

Implementation:
- Schreibt PDF in temp-Dir
- Ruft `audiveris -batch -export -output <tmp>` auf
- Sucht nach .xml-Datei im Output, liest + sendet zurück
- Räumt auf

Robustheit: Audiveris ist langsam (5-60s pro PDF), daher request-timeout 5min.
"""
import os
import shutil
import subprocess
import tempfile
import logging
from pathlib import Path
from flask import Flask, request, jsonify, Response
from waitress import serve

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("audiveris-server")

app = Flask(__name__)

@app.get("/health")
def health():
    return "ok", 200

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
            "audiveris", "-batch",
            "-export", "-output", str(out_dir),
            str(in_path),
        ]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        except subprocess.TimeoutExpired:
            log.error("Audiveris timeout")
            return jsonify({"error": "audiveris timeout"}), 504

        if res.returncode != 0:
            log.error("Audiveris exit %d: %s", res.returncode, res.stderr[-1000:])
            return jsonify({"error": "audiveris failed", "stderr": res.stderr[-1000:]}), 500

        # Audiveris legt MusicXML als .mxl (gezippt) oder .xml ab
        xml_files = list(out_dir.rglob("*.xml")) + list(out_dir.rglob("*.mxl"))
        if not xml_files:
            return jsonify({"error": "no MusicXML produced"}), 500

        # Größtes .xml (oder erstes .mxl) zurückgeben
        xml_files.sort(key=lambda p: p.stat().st_size, reverse=True)
        out_file = xml_files[0]
        log.info("Recognize: success, %s (%d bytes)", out_file.name, out_file.stat().st_size)

        if out_file.suffix == ".mxl":
            mime = "application/vnd.recordare.musicxml"
            data = out_file.read_bytes()
            return Response(data, mimetype=mime)
        else:
            return Response(out_file.read_bytes(), mimetype="application/vnd.recordare.musicxml+xml")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    log.info("Audiveris-Server hört auf :%d", port)
    serve(app, host="0.0.0.0", port=port, threads=2, expose_tracebacks=False)
