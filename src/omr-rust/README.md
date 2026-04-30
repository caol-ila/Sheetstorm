# Sheetstorm OMR Engine — Rust Implementation

> **Status:** v0.2 — Hardening for Real Scans
> **Lizenz:** Apache-2.0 (clean-room, kein Audiveris-Code)

Eigene Optical-Music-Recognition-Pipeline für Sheetstorm, geschrieben in
Rust. Pipeline-basierter Aufbau mit klassischen CV-Algorithmen, designed
um **drop-in-kompatibel mit dem Audiveris-Container** zu sein
(`/health`, `POST /recognize`).

## Architektur

```
sheetstorm-omr (workspace root)
├── crates/
│   ├── omr-core/             — Image-Buffer, Geometrie, Fehler-Typen
│   ├── omr-preprocessing/    — Sauvola-Binarisierung, Deskewing, Noise-Removal
│   ├── omr-staff/            — Staff-Line Detection (Stable Paths) + Removal
│   ├── omr-symbols/          — Connected-Components, Notehead-Erkennung,
│   │                          Stem/Beam, Pitch/Duration-Estimation
│   ├── omr-musicxml/         — MusicXML 4.0 Score-Partwise Export
│   ├── omr-pipeline/         — Glue-Code, orchestriert alle Stufen
│   └── omr-server/           — Axum-HTTP-Server (Audiveris-kompatibel)
├── tests/                    — Integration-Tests + Quality-Bench
└── Cargo.toml
```

## Algorithmen

Siehe `docs/15-omr-pipeline-spec.md` und `docs/16-omr-algorithm-research.md`
im Hauptrepo für die ausführliche Spezifikation. Kurzfassung:

| Stufe | Algorithmus | Quelle |
|-------|-------------|--------|
| Binarisierung | Sauvola (window=25, k=0.34) | Sauvola/Pietikäinen 2000 |
| Deskewing | Hough auf Stafflines | Klassisch |
| Staff-Detection | Stable Paths | Cardoso 2009 |
| Staff-Removal | Run-Length-basiert | Klassisch |
| Symbole | Connected Components + HOG-Filter | Klassisch |
| Noteheads | NCC-Template-Matching + Sub-Pixel-Interp. | Lewis 1995 |
| MusicXML | Score-Partwise v4.0 | W3C |

**Kein Audiveris-Code wird verwendet** (Audiveris ist AGPL-3.0). Diese
Engine ist clean-room geschrieben — Algorithmen aus wissenschaftlicher
Literatur, keinerlei Code-Übernahme aus Audiveris/oemer/homr/MuseScore-OMR.

## Build

```bash
cd src/omr-rust
cargo build --release
cargo test
```

Binary läuft als HTTP-Server analog zum Audiveris-Container:

```bash
cargo run --release --bin omr-server -- --port 8091
# oder via env: OMR_PORT=8091 OMR_HOST=0.0.0.0 cargo run --release
curl http://localhost:8091/health
curl -F file=@score.pdf http://localhost:8091/recognize
```

## Performance-Ziele

| Metrik | Ziel | Audiveris-Baseline |
|--------|------|-------------------|
| Latenz pro A4 | < 5 s | ~30-60 s |
| Speicher | < 256 MB | ~1 GB |
| Note-Accuracy (sauberer Druck) | > 80 % | 70-85 % |

## Integration in Sheetstorm

In `Sheetstorm.AppHost`/`AppHost.cs`:

```csharp
var omrEngine = builder.AddContainer("sheetstorm-omr", "sheetstorm-omr:latest")
    .WithEndpoint(targetPort: 8091, name: "http");
```

In Sheetstorm.Web `appsettings.json`:

```json
{
  "Omr": {
    "Provider": "sheetstorm",  // oder "audiveris" als Fallback
    "BaseUrl": "http://sheetstorm-omr:8091"
  }
}
```
