# OMR Phase 3 — Sheet Music Transformer Cloud-Backstop (FUTURE, opt-in)

> **Status**: Phase 3 — geplant, **nicht in aktueller Roadmap** (Q3/Q4 2026 frühestens).
> **Stand**: 2026-04-30
> **Abhängigkeit**: Phase 2 (HoG+SVM Klassifikator + U-Net Staff-Removal) muss umgesetzt sein

## Motivation

Auch nach Phase 2 wird die klassische OMR-Pipeline an Grenzen stoßen, insbesondere bei:
- **Historischen Notations­formen** (Mensural, Neumen, alte Drucke)
- **Stark verzierter Notation** (Ornamente, Mikrotonalität, alternative Notenkopf-Formen)
- **Sehr verschmierte oder beschädigte Scans** wo selbst Sauvola+Despeckle versagt
- **Polyphone Klavierpartituren** mit komplexem Voice-Crossing
- **Chord-Symbol-Lead-Sheets** (Jazz, Pop) mit grafischen Akkord-Annotationen

In diesen Fällen kann ein **End-to-End Transformer-Modell** als zweite Meinung
deutlich besser performen — auf Kosten von Cloud-Inference und Privacy-Trade-Offs.

## Konzept: Cloud-Backstop

```
┌─────────────────────────────────────────────────────────────┐
│ Sheetstorm Pipeline                                          │
├─────────────────────────────────────────────────────────────┤
│  Local Pipeline (Phase 1+2)                                  │
│   1. Preprocessing (Apache, lokal, ~50ms)                    │
│   2. Staff-Detection + U-Net-Removal (Apache, lokal, ~250ms) │
│   3. Symbol-Detection + HoG/SVM-Klassifikator (Apache, ~100ms)│
│   4. MusicXML-Konstruktion + Plausibilisierung               │
│                          │                                    │
│                          ▼                                    │
│   ┌──────────────────────────────────────────────────┐       │
│   │  Plausibility-Check                              │       │
│   │  >70% Takte plausibel?                           │       │
│   └──────┬─────────────────────────────┬─────────────┘       │
│          │ Ja                          │ Nein                 │
│          ▼                             ▼                      │
│   Local Result          ┌─────────────────────────────┐      │
│   (default)             │  User-Prompt:               │      │
│                         │  "Erkennung schwierig.       │      │
│                         │   Cloud-Service nutzen?     │      │
│                         │   [Ja, opt-in] [Nein]"      │      │
│                         └──────┬──────────────────────┘      │
│                                │                              │
│                                ▼                              │
│                      ┌─────────────────────────┐              │
│                      │ Cloud-Inference         │              │
│                      │ (HuggingFace o.ä.)      │              │
│                      │ Sheet Music Transformer │              │
│                      │ ~5-15s pro Seite        │              │
│                      └─────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Modelle / Backends

### Sheet Music Transformer (SMT / SMT++)
- **Lizenz**: MIT (Code), Modell-Weights MIT
- **Repo**: https://github.com/antoniorv6/SMT
- **Paper**: Ríos-Vila et al. arXiv:2402.07596 (ICDAR 2024)
- **Stärken**: Polyphon (Pianoform), End-to-End, SER 3–5%
- **Schwächen**: GPU-abhängig (~5-15s CPU, <1s auf GPU), nur **Bild → Kern-Format** (nicht direkt MusicXML)
- **Deployment**: HuggingFace Inference Endpoint, eigenes Modal/Replicate-Hosting, oder selbstgehostet

### Alternativen
| Modell | Lizenz | Domäne | Anmerkung |
|---|---|---|---|
| **PrIMuS CRNN** | MIT | monophon | nur einzelne Stimmen — limitiert für Vereinsblätter |
| **DOLPHIN** | unklar | hybrid | wissenschaftlich, kein klarer Code-Release |
| **OEMER** | MIT (Code), Weights tlw. NC | hybrid (U-Net + Klassifier) | **Phase 2 nutzt OEMER schon partiell** für Staff-Removal |

Empfehlung: **SMT++ für Phase 3**, weil polyphon + MIT + arXiv-publiziert.

## Architektur-Optionen

### Option A: SaaS-Cloud-Service (empfohlen)
- Sheetstorm-Backend ruft HuggingFace Inference API auf
- User-opt-in einmalig + pro Stück bestätigt
- Vorteil: keine Modell-Weights im Repo, immer aktuell
- Nachteil: Privacy (Notenblatt verlässt das Gerät), Kosten

### Option B: Selbst-Hosting via Docker-Sidecar
- Wie Audiveris-Sidecar: separater Container mit SMT-Inference
- `docker/smt/` parallel zu `docker/audiveris/`
- Vorteil: keine Daten-Exfiltration
- Nachteil: 4-8 GB RAM, GPU-empfohlen, Komplexität

### Option C: WebAssembly-Browser-Inference
- ONNX-Runtime im Browser via WASM
- Vorteil: Privacy + Offline
- Nachteil: Modelle ~500MB, lange Initial-Ladezeit

## Trigger-Bedingungen für Cloud-Pfad

Cloud-Backstop wird AUTOMATISCH vorgeschlagen wenn:
1. **Plausibility < 50%** der Takte (zu viele Σ-duration-Fehler)
2. **NH-Recall geschätzt < 60%** (zu wenige NHs für Page)
3. **Manuell durch User**: "Diese Erkennung war schlecht — Cloud versuchen?"

## User-Experience

```
┌──────────────────────────────────────────────────────┐
│ Notenerkennung abgeschlossen                          │
│                                                       │
│ ⚠️ Qualitäts-Hinweis: Nur 38% der Takte konnten       │
│    sauber erkannt werden. Mögliche Ursachen:         │
│    - Schwierige Handschrift                          │
│    - Beschädigter Scan                               │
│    - Komplexe Notation (Chord-Symbole, Ornamente)    │
│                                                       │
│ Optionen:                                             │
│  ▢ Trotzdem so übernehmen                             │
│  ▢ Cloud-Service nutzen (verlässt das Gerät, ~10s)   │
│    [Ja, einmal] [Ja, immer] [Nie fragen]             │
│  ▢ Manuell korrigieren (Korrektur-Modus)              │
└──────────────────────────────────────────────────────┘
```

Privacy-Hinweis sollte deutlich sein:
- "Dein Notenblatt wird an einen externen Cloud-Service geschickt"
- "Verschlüsselt via HTTPS, aber Daten verlassen dein Gerät"
- "Setting unter Settings → Privacy → Cloud-OMR"

## Roadmap-Einordnung

| Phase | Ziel | Status |
|---|---|---|
| **Phase 1** (PR #136) | Auto-Rotation, Plausibility, Visual-Debug, Stem-Recall | ✅ DONE |
| **Phase 2** (Sub-PRs in #136 oder Folge-PR) | HoG+SVM-Klassifikator + U-Net Staff-Removal | 🚧 In Arbeit |
| **Phase 3** (Q3-Q4 2026) | **Sheet Music Transformer Cloud-Backstop** | 📋 SPEC ONLY (dieses Dokument) |
| Phase 4 (2027) | WebAssembly-Inference, Symbol-Library mit 300 Klassen | 🔮 Vision |

## Implementierungs-Schritte (für Phase 3)

1. **Spike**: SMT++ lokal aufsetzen, Inference-Latenz messen
2. **API-Design**: REST-Endpoint `POST /api/v1/omr/cloud-recognize`
3. **HuggingFace-Integration**: SMT auf HF deployen oder Modal/Replicate
4. **MusicXML-Konversion**: Kern → MusicXML (das ist eigene kleine Aufgabe)
5. **UI-Flow**: Settings + Trigger-Prompt + Privacy-Banner
6. **Cost-Modell**: pro Seite ~$0.01 bei HF Inference, ggf. Limit pro User
7. **Telemetry**: messen wie oft Cloud-Backstop genutzt wird → besser Phase 2 optimieren

## Out-of-Scope für Phase 3

- ❌ Eigenes Training eines Transformer-Modells (zu hohe Kosten, Daten-Aufwand)
- ❌ Polyphone Voice-Splitting in Phase-3-MVP (kommt später)
- ❌ Ornamentation-Detection (Triller, Vorschlag, Mordent) — Phase 4

## Quellen

- Sheet Music Transformer: Ríos-Vila et al., arXiv:2402.07596 (ICDAR 2024)
- SMT++ Pianoform: ResearchGate-Preprint 2024
- Repo: https://github.com/antoniorv6/SMT (MIT)
- HuggingFace Inference Endpoints: https://huggingface.co/inference-endpoints
- OMR-NED Metric (für Phase-3-Evaluation): Sheet Music Benchmark, Thickstun et al. 2025
