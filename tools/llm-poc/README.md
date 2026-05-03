# GitHub Models OMR POC — Vision LLM Evaluation

## Was ist das?

Systematische Evaluation von LLM-Vision-Modellen (GitHub Models / Azure AI Foundry) für Optical Music Recognition (OMR) im Kontext von Sheetstorm.

**Kernfrage:** Was können GPT-4o, Phi-3.5-vision, Llama-3.2-90B und Co. zuverlässig auf Notenbildern leisten?

## Schnellstart

```bash
cd tools/llm-poc

# Abhängigkeiten installieren
pip install -e .

# Oder direkt:
pip install openai pymupdf Pillow python-Levenshtein

# Auth (Option 1: gh CLI — empfohlen)
gh auth login

# Auth (Option 2: Token direkt)
$env:GITHUB_TOKEN = "github_pat_..."   # PowerShell
export GITHUB_TOKEN="github_pat_..."   # bash/zsh

# Alle Tests ausführen (alle 4 Modelle)
cd poc
python eval.py

# Nur bestimmte Modelle
python eval.py --models gpt-4o-mini gpt-4o

# Nur bestimmte Tests
python eval.py --test 1 4 5 6

# Einzelnen Test direkt ausführen
python tests/test_01_header_extraction.py
```

## Ergebnisse

Siehe `reports/llm-poc-summary.md` für den vollständigen Report.  
Rohdaten: `reports/llm-poc-results.json`

## Test-Struktur

| Test | Aufgabe | Erwartung | Metrik |
|------|---------|-----------|--------|
| 01 | Header-Extraction (Titel, Komponist, Instrument, Tempo) | ✅ Gut (F1 ≥ 0.80) | Token-F1 |
| 02 | Symbol-Klassifikation (64×64 Patches) | ❌ Schlecht (Acc ≤ 0.55) | Accuracy + Confusion Matrix |
| 03 | Full-Page-Recognition → ABC/MusicXML | ❌ Schlecht (Halluzinationen) | Completeness-Score |
| 04 | Metadata + Katalog-Matching | ⚡ Mittel (0.50–0.75) | Attribut-Score |
| 05 | Validation-Assistant (OMR-Output prüfen) | ✅ Potenziell sehr gut | Utility-Score |
| 06 | Lyric/Text-OCR | ✅ Gut (Sim ≥ 0.80) | Levenshtein-Similarity |

## Getestete Modelle

| Modell | Typ | Vision | Kosten |
|--------|-----|--------|--------|
| `gpt-4o` | OpenAI premium | ✅ | $0.005/1K prompt tokens |
| `gpt-4o-mini` | OpenAI cheap | ✅ | $0.00015/1K prompt tokens |
| `Phi-3.5-vision-instruct` | Microsoft small | ✅ | ~$0.0001/1K |
| `Llama-3.2-90B-Vision-Instruct` | Meta open | ✅ | ~$0.00034/1K |

## Auth-Troubleshooting

**Problem:** `AuthError: No GitHub token found`

```bash
# Prüfen ob gh CLI authentifiziert ist:
gh auth status

# Neu anmelden:
gh auth login --scopes "models:read"

# Manuell:
$env:GITHUB_TOKEN = (gh auth token)
```

**Problem:** `BadRequestError: Model does not support vision`

Einige Modelle im GitHub Models Katalog unterstützen kein image-input trotz Bezeichnung. Das Script fängt das ab und markiert die Ergebnisse entsprechend.

**Problem:** `RateLimitError`

GitHub Models hat Rate-Limits (besonders für Free-Tier). Das Script wartet automatisch und retried 3×. Bei persistenten Fehlern: warten und neu ausführen.

## Datenbasis

Tests nutzen PDFs aus `src/.filestore/` (Radetzky-Marsch, Florentiner Marsch, ANGELS, etc.).  
Die Dateien sind Teil des Sheetstorm-Repositories und werden nicht durch dieses Tool verändert.

## Struktur

```
tools/llm-poc/
├── README.md                    — Diese Datei
├── pyproject.toml               — Abhängigkeiten
├── poc/
│   ├── client.py                — GitHubModelsClient (OpenAI-API-kompatibel)
│   ├── eval.py                  — Aggregator + Report-Generator
│   └── tests/
│       ├── test_01_header_extraction.py
│       ├── test_02_symbol_classification.py
│       ├── test_03_full_page_recognition.py
│       ├── test_04_metadata_extraction.py
│       ├── test_05_validation_assistant.py
│       └── test_06_lyric_ocr.py
└── reports/
    ├── llm-poc-results.json     — Rohdaten (nach eval.py-Lauf)
    └── llm-poc-summary.md       — Markdown-Report (nach eval.py-Lauf)
```
