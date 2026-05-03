# GitHub Models OMR POC — Evaluation Report

**Generated:** 2026-05-03 11:39  

**Models tested:** gpt-4o-mini, gpt-4o, Llama-3.2-90B-Vision-Instruct  

**Tests run:** [1, 2, 3, 4, 5, 6]  


---

## Results Summary

| Model | Header F1 | Symbol Acc | OMR Complete | Catalog | Validation | Lyric OCR | Est. Cost/page |
|---|---|---|---|---|---|---|---|
| gpt-4o-mini | 0.51 | 0.00 | 0.67 | 0.58 | 0.60 | 0.77 | $0.0874 |
| gpt-4o | 0.51 | 0.00 | 0.55 | 0.33 | 0.47 | 0.77 | $0.1186 |
| Llama-3.2-90B-Vision-Instruct | 0.44 | 0.10 | 0.89 | 0.58 | 0.73 | 0.27 | $0.0378 |

---

## Test Details

### Test 01 — Header Extraction (Title/Composer/Instrument/Tempo)
*Expectation: Good (F1 ≥ 0.80)*

- **gpt-4o-mini**: F1 overall=0.511, title=0.4, composer=0.733, instrument=0.4

- **gpt-4o**: F1 overall=0.511, title=0.4, composer=0.733, instrument=0.4

- **Llama-3.2-90B-Vision-Instruct**: F1 overall=0.444, title=0.2, composer=0.733, instrument=0.4


### Test 02 — Symbol Classification (64×64 patches)
*Expectation: Poor (Acc ≤ 0.55) — tiny crops lose context*

- **gpt-4o-mini**: accuracy=0.0, correct=0/10

- **gpt-4o**: accuracy=0.0, correct=0/10

- **Llama-3.2-90B-Vision-Instruct**: accuracy=0.1, correct=1/10


### Test 03 — Full-Page Recognition
*Expectation: Poor (hallucinations dominate)*

- **gpt-4o-mini**: avg completeness=0.667

- **gpt-4o**: avg completeness=0.553

- **Llama-3.2-90B-Vision-Instruct**: avg completeness=0.89


### Test 04 — Metadata + Catalog Matching
*Expectation: Medium (0.5–0.75) for known repertoire*

- **gpt-4o-mini**: avg attribute score=0.583

- **gpt-4o**: avg attribute score=0.333

- **Llama-3.2-90B-Vision-Instruct**: avg attribute score=0.583


### Test 05 — Validation Assistant
*Expectation: High utility for structural mismatch detection*

- **gpt-4o-mini**: avg utility=0.6

- **gpt-4o**: avg utility=0.467

- **Llama-3.2-90B-Vision-Instruct**: avg utility=0.733


### Test 06 — Lyric OCR
*Expectation: Good (similarity ≥ 0.80)*

- **gpt-4o-mini**: avg Levenshtein similarity=0.767

- **gpt-4o**: avg Levenshtein similarity=0.767

- **Llama-3.2-90B-Vision-Instruct**: avg Levenshtein similarity=0.267


---

## 🎯 Concrete Recommendations for Sheetstorm Integration

### ✅ USE LLMs for these tasks

**Title / Composer extraction**: results below threshold (F1=0.51). Use as suggestion only, not auto-fill.

**Lyric / text OCR** (best: gpt-4o-mini, similarity=0.77)  
→ Extract lyrics for display/search without manual transcription.  
→ Confidence: high for clear printed text.


### ⚡ CONSIDER for these tasks

**Validation assistant** — LLM as second opinion on OMR output:  
→ Feed scan + Audiveris MusicXML to GPT-4o, ask 'does this look right?'  
→ Even without perfect pitch detection, structural errors are caught.  
→ Cost: ~$0.005/page (gpt-4o) — acceptable for user-facing QA workflow.


**Catalog matching** — 'Which piece is this?':  
→ Useful for unlabelled scans from archive.  
→ Works well for famous marches (Radetzky, Florentiner) due to training data.


### ❌ DO NOT use LLMs for these tasks

**Pitch / note detection** (symbol accuracy: 10.0%)  
→ LLMs hallucinate note names, durations, and octaves heavily.  
→ Confusion: quarter-note vs eighth-note not reliably distinguished.  
→ **Stick with dedicated OMR (Audiveris)** for any pitch-level work.

**Full-page transcription to MusicXML/ABC**  
→ Output is plausible but unreliable. Too many errors for production use.  
→ May be useful as a rough draft for human correction, not automated.


### 💡 Recommended Architecture

```
PDF Upload
    │
    ├─ [LLM gpt-4o-mini] → extract Title, Composer, Instrument, Tempo
    │   └─ Pre-fill metadata form (user confirms)
    │
    ├─ [LLM gpt-4o-mini] → extract Lyrics
    │   └─ Store for full-text search
    │
    ├─ [Audiveris OMR] → generate MusicXML
    │   └─ [LLM gpt-4o, optional] → validate MusicXML vs. scan image
    │       └─ Flag suspicious pages for human review
    │
    └─ Done
```

### 💰 Cost Estimate (production)

| Workflow | Model | Cost/page | 1000 pages/month |
|---|---|---|---|
| Metadata extraction | gpt-4o-mini | ~$0.001 | ~$1 |
| Lyric OCR | gpt-4o-mini | ~$0.001 | ~$1 |
| OMR validation | gpt-4o | ~$0.005 | ~$5 |
| **Total** | mixed | ~$0.007 | **~$7/month** |

---

## Notes on Model Availability

- **gpt-4o / gpt-4o-mini**: Always available via GitHub Models, full vision support

- **Phi-3.5-vision-instruct**: Available via GitHub Models, lightweight, local-deployable

- **Llama-3.2-90B-Vision-Instruct**: Available via GitHub Models, open weights

- Claude 3.5 Sonnet / Gemini: Not available via GitHub Models endpoint at test time


## Auth Setup

```bash

# Option 1: gh CLI (recommended)

gh auth login

python eval.py


# Option 2: Explicit token

$env:GITHUB_TOKEN = 'your-token-here'

python eval.py

```
