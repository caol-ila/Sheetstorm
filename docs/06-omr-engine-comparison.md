# OMR-Engine-Vergleich: Sheetstorm-OMR vs Audiveris

Sheetstorm hat **zwei OMR-Engines** die parallel laufen koennen:

| Engine | Sprache | Speed | Output | Wann nutzen? |
|--------|---------|-------|--------|--------------|
| **Sheetstorm-OMR** | Rust | ~1s/Seite | MusicXML + Detections-JSON + SIG | Default; schnell, mit Bbox-Daten |
| **Audiveris** | Java (5.10) | 5-60s/Seite | MusicXML | Vergleich; ausgereift, vollständige Texte/Lyrics |

## Schnellstart

### Nur Sheetstorm-OMR (Default, schnell)
```powershell
.\scripts\start-with-sheetstorm-omr.ps1
```

### Nur Audiveris (Vergleichs-Engine)
```powershell
.\scripts\start-with-audiveris.ps1
```
> Erster Start dauert 5-10 min wegen Docker-Image-Build (Java + Audiveris + Tesseract = ~1 GB).

### Beide parallel (Comparison-Mode)
```powershell
# Sheetstorm-OMR ist Default-Engine, Audiveris parallel verfuegbar
.\scripts\start-comparison.ps1

# Audiveris ist Default-Engine
.\scripts\start-comparison.ps1 -Engine audiveris
```

## Manuell via AppHost

```powershell
dotnet run --project src/Sheetstorm.AppHost -- \
    --enable-audiveris \         # startet Audiveris-Container
    --enable-omr \               # startet Sheetstorm-OMR-Container
    --use-engine=audiveris       # waehlt Audiveris als Active fuer Web-UI
```

Auswahl-Logik:
- Wenn `--use-engine` gesetzt: genau diese Engine
- Sonst: Sheetstorm-OMR wenn beide laufen, sonst die einzig laufende

Env-Vars (alternativ zu CLI-Flags):
- `SHEETSTORM_ENABLE_AUDIVERIS=true`
- `SHEETSTORM_ENABLE_OMR=true`
- `SHEETSTORM_USE_ENGINE=audiveris|sheetstorm|stub`

## API-Vergleich

Beide Engines exponieren dieselbe HTTP-API:
- `GET /health`
- `POST /recognize` — multipart `pdf` field, returns plain MusicXML

Sheetstorm-OMR zusaetzlich:
- `POST /detections` — Detections-JSON mit Bboxes + SIG-Summary
- `POST /omr` — SIG als JSON-Object

## Direkter Vergleich auf einem PDF

Mit beiden Engines parallel:
```powershell
# Audiveris
curl -X POST -F "pdf=@./mein-stueck.pdf" http://localhost:8081/recognize -o audiveris.mxml

# Sheetstorm-OMR
curl -X POST -F "file=@./mein-stueck.pdf" http://localhost:8091/recognize -o sheetstorm.mxml

# Vergleich
diff audiveris.mxml sheetstorm.mxml
```

## Web-UI

Im Web-UI (https://localhost:7070) wird die OMR-Engine via `Omr:Provider`
ausgewählt. Dieser Wert wird vom AppHost basierend auf den Flags gesetzt:
- `--use-engine=sheetstorm` → `Omr__Provider=sheetstorm`
- `--use-engine=audiveris` → `Omr__Provider=audiveris`
- ohne Wahl → automatisch nach laufenden Containern

Der Wechsel erfordert einen Web-Restart (oder Aspire Restart-Command auf dem Web-Container).

## Architektur

```
                         ┌──────────────────────┐
                         │  Sheetstorm.Web      │
                         │  (Blazor)            │
                         └────────┬─────────────┘
                                  │ IOmrEngine (DI)
                                  ▼
                ┌─────────────────┴─────────────────┐
                ▼                                   ▼
      ┌──────────────────┐              ┌────────────────────┐
      │ AudiverisOmr     │              │ SheetstormOmr      │
      │ Engine           │              │ Engine             │
      └────────┬─────────┘              └────────┬───────────┘
               │ http://audiveris:8080            │ http://sheetstorm-omr:8091
               ▼                                  ▼
      ┌──────────────────┐              ┌────────────────────┐
      │ Audiveris        │              │ omr-server (Rust)  │
      │ Container        │              │ Container          │
      │ (Java 21 + 5.10) │              │ (omr-rust crates)  │
      └──────────────────┘              └────────────────────┘
```

## Bekannte Limitationen

### Audiveris
- Liefert **nur MusicXML**, keine Bbox-Daten / Detections-JSON
- Annotation-Tool kann Audiveris-Output **nicht editieren** (keine Bboxes)
- Lizenz: AGPL-3.0 (deshalb separate Container, kein Linking)

### Sheetstorm-OMR
- Pitch-/Duration-Erkennung noch nicht so robust wie Audiveris
- Texte/Lyrics werden noch nicht via OCR detected (Audiveris nutzt Tesseract)

## Wann was?

- **Production**: Sheetstorm-OMR (schnell, mit Annotation-Workflow)
- **Vergleichs-Tests**: Audiveris als Ground-Truth-Annaeherung
- **Entwicklung**: Stub (kein Container, schnell)
