# OMR-Test-Datensätze — Recherche 2026

> **Status:** Research-Bericht • **Datum:** 2026 • **Autor:** Research-Agent
> **Kontext:** Sheetstorm OMR-Engine Test-Korpus-Erweiterung
> **Ziel-Lizenz:** Apache-2.0 (Repo) → kompatible Daten-Lizenzen finden

## Executive Summary

Sheetstorm benötigt mehr Test-Daten mit Ground-Truth in fünf Kategorien (Bild→XML, Bild→MIDI, Staff-Removal, Brass/Concert Band, deutsche Volksmusik).

**Top 3 sofort einbindbare Datensätze (Apache-2.0-kompatibel):**

| # | Dataset | Lizenz | Größe | Sofort-Nutzen |
|---|---------|--------|-------|---------------|
| 1 | **OpenScore Lieder Corpus v3** | CC0 | ~1.300 Lieder, MusicXML+PDF | Image→MusicXML-Paare, deutsche Lieder, perfekter Sheetstorm-Fit |
| 2 | **CVC-MUSCIMA** | CC-BY 4.0 | 1.000 Seiten Staff-Removal-Pairs | Phase-2 U-Net Staff-Removal-Training |
| 3 | **Sheet Music Benchmark (SMB)** | CC-BY 4.0 (Zenodo) | 685 Seiten, Humdrum **kern, ISMIR 2025 | Standardisiertes OMR-Eval-Set inkl. OMR-NED-Metrik |

**Wichtigste Erkenntnisse:**
- ✅ **PrIMuS / DoReMi / GrandStaff** sind alle CC-BY 4.0 → direkt nutzbar
- ✅ **DeepScores V2** ist CC-BY 4.0 → für Phase-3 ML-Training
- ⚠️ **MUSCIMA++ / Camera-PrIMuS / MAPS / MusicNet** sind NC-Varianten → nur lokal, NICHT ins CI-Repo
- ❌ **Wikifonia** ist tot (Copyright-Klagen, keine legale Quelle mehr)
- ⚠️ **Mutopia** ist gemischt (PD + CC-BY-SA); pro-File-Filter nötig
- 🔴 **Lücke:** Es gibt **keinen** dedizierten Brass-/Concert-Band-Korpus mit Image→XML-Pairs → Eigenes Mini-Korpus (10–20 Vereins-PDFs) labeln nötig

---

## Vergleichs-Tabelle (alle untersuchten Datensätze)

| Dataset | Kat. | Lizenz | Apache-OK? | Format | Größe | Anwendung |
|---------|------|--------|------------|--------|-------|-----------|
| **OpenScore Lieder Corpus** | A, E | **CC0** | ✅ JA | MuseScore→MusicXML, PDF, MIDI | ~1.300 Lieder (Schubert/Schumann/Brahms/Wolf) | Image→XML, deutsche Lieder, Pipeline-E2E |
| **OpenScore String Quartets** | A | **CC0** | ✅ JA | MusicXML, PDF | Haydn/Mozart/Beethoven Quartette | Polyphon/Multi-Stimmen Test |
| **OpenScore Bach 371 Chorales** | A, E | **CC0** | ✅ JA | MuseScore, MusicXML | 371 Choräle | Choralbuch-ähnliches Repertoire |
| **CVC-MUSCIMA** | C | **CC-BY 4.0** | ✅ JA | PNG-Pairs (mit/ohne Notenlinien) | 1.000 Seiten, 50 Schreiber | Staff-Removal-Training (Phase 2) |
| **Sheet Music Benchmark (SMB)** | A | **CC-BY 4.0** (Zenodo) | ✅ JA | Image + Humdrum **kern | 685 Seiten (mono, pianoform, quartet) | Standard-Benchmark, OMR-NED-Metrik |
| **PrIMuS (synthetic)** | A | **CC-BY 4.0** | ✅ JA | PNG + semantic encoding | ~87k mono-Inzipits | E2E mono OMR Sanity-Check |
| **DoReMi** | A | **CC-BY 4.0** | ✅ JA | PNG + MusicXML, Symbol-Annot. | ~6.500 Seiten | Symbol-Detection, Layout |
| **GrandStaff** | A | **CC-BY 4.0** | ✅ JA | Image + **kern, pianoform | ~53k Systeme | Polyphon/Pianoform-Test |
| **DeepScores V2** | A, C | **CC-BY 4.0** | ✅ JA | PNG + COCO-style XML | ~255k Seiten, ~80M Symbol-Inst. | ML-Training Phase 3 |
| **MAESTRO v3** | B | **CC-BY 4.0** | ✅ JA | MIDI + Audio (kein Score-Image!) | ~200h Klavier | ⚠️ kein Image, nur Audio-MIDI |
| **Mutopia Project** | A, D, E | **gemischt PD / CC-BY-SA / CC-BY** | ⚠️ pro File | LilyPond, PDF, MusicXML, MIDI | ~2.300 Stücke | PD-Subset filterbar, brass/wind dünn |
| **Humdrum kernScores** | A | überwiegend **PD** | ✅ JA (PD) | **kern (kein Image!) | ~10.000 Stücke | Symbolische GT (Image muss gerendert werden) |
| **MUSCIMA++** | A | **CC-BY-NC-SA 4.0** | ❌ Repo / ✅ lokal | PNG + MuNG XML | 140 handgeschr. Seiten | Handwriting (lokal nutzen, nicht CI) |
| **Camera-PrIMuS** | A | **CC-BY-NC-SA 4.0** | ❌ Repo | PNG (camera) + sem. Encoding | ~87k | NC-Constraint blockiert Repo-Nutzung |
| **MAPS** | B | **CC-BY-NC-SA 2.0 FR** | ❌ Repo | Audio + MIDI (kein Score) | ~31GB | Nur Audio-MIDI |
| **MusicNet** | B | **CC-BY-NC 4.0** (Labels) | ❌ Repo | Audio + MIDI Alignment | 330 Stücke | NC-Restriktion |
| **Bach10** | B | nicht-kommerz. Forschung | ❌ Repo | Multi-Track Audio + MIDI | 10 Choräle | Lizenz unklar/restriktiv |
| **SEILS** | A | LICENSE.txt im Repo (nicht CC-Standard) | ⚠️ prüfen | Mensural-Notation + sym. | 30 Madrigale | Out-of-scope (alte Notation) |
| **Wikifonia** | A, E | ❌ tot (Copyright) | ❌ NEIN | — | — | Nicht nutzen |
| **BandMusic PDF Library** | D | meist PD (US) | ⚠️ pro File | NUR PDF (kein XML!) | ~3.000 Bandstücke | Image-Quelle, GT muss selbst erstellt werden |
| **IMSLP "For brass band"** | D | gemischt PD / CC | ⚠️ pro File | PDF, manchmal MusicXML | ~hunderte | Image-Quelle, GT meist fehlend |

**Legende Kategorien:** A=Image→XML/MEI · B=Image→MIDI · C=Staff-Removal · D=Brass/Concert Band · E=Deutsche Volksmusik/Lieder

---

## Detail-Befunde pro relevantem Dataset

### 🥇 OpenScore Lieder Corpus (Kat. A, E)
- **URL:** https://github.com/OpenScore/Lieder · Zenodo: https://zenodo.org/records/15450144
- **Lizenz:** **CC0** (Public Domain Dedication) → ideal, kein Attribution-Pflicht
- **Inhalt:** Über 1.300 deutsche Lieder (Schubert, Schumann, Brahms, Wolf) als `.mscx` (MuseScore), batch-konvertierbar zu MusicXML/PDF/MIDI via `corpus_conversion.py`
- **Sheetstorm-Fit:** ⭐⭐⭐⭐⭐ — deutsche Lieder = perfektes Vereins-Repertoire-Proxy. Wir können MusicXML als GT verwenden und PDFs synthetisch rendern (oder die offiziellen PDFs nutzen) → **echte gepaarte Image→XML-Daten**.
- **Download:** `git clone` (groß, evtl. Git-LFS), keine Auth, kein Captcha
- **Pipeline-Stufe:** End-to-End Pipeline Test (`tests/integration/`), Lieder-spezifische Eval-Suite

### 🥇 CVC-MUSCIMA (Kat. C)
- **URL:** https://www.cvc.uab.es/cvcmuscima/
- **Lizenz:** **CC-BY 4.0**
- **Inhalt:** 1.000 Seiten handgeschr. Musik, 20 Stücke × 50 Schreiber. **Pairs:** mit/ohne Notenlinien, ground-truth Staff-Pixel-Masken
- **Sheetstorm-Fit:** ⭐⭐⭐⭐ — exakt unsere Phase-2 U-Net-Anforderung. Genau das Zielformat für Staff-Removal-Modell-Training.
- **Download:** ZIP via Webformular (eine Email-Notification)
- **Pipeline-Stufe:** `staff_removal/` Modul-Tests, U-Net-Training Phase 2

### 🥇 Sheet Music Benchmark (SMB) (Kat. A)
- **URL:** https://zenodo.org/records/17706531
- **Lizenz:** **CC-BY 4.0** (Zenodo-default; LICENSE-Datei im Bundle prüfen)
- **Inhalt:** 685 Seiten, gemischt monophon / pianoform / Streichquartett. **Format:** Image + Humdrum **kern. Inkl. neue Metrik **OMR-NED** (Normalized Edit Distance).
- **Sheetstorm-Fit:** ⭐⭐⭐⭐⭐ — explizit als ISMIR-2025-Standardbenchmark designed. Wir bekommen direkt vergleichbare Zahlen mit der Forschungs-Community.
- **Download:** Zenodo HTTP, kein Login
- **Pipeline-Stufe:** Master-Eval-Set (`tests/benchmark/smb/`), OMR-NED in unsere Reports einbauen

### PrIMuS (synthetic) (Kat. A)
- **URL:** https://grfia.dlsi.ua.es/primus/
- **Lizenz:** **CC-BY 4.0** (Originaldatensatz; **nicht** zu verwechseln mit Camera-PrIMuS, das CC-BY-NC-SA ist!)
- **Inhalt:** ~87.000 monophone Inzipits, Image + semantisches Encoding + agnostisches Encoding
- **Sheetstorm-Fit:** ⭐⭐⭐ — synthetisch, monophon → Sanity-Check-Niveau. Aber große Menge → gut für Statistik-relevante Eval.
- **Pipeline-Stufe:** Mono-Pipeline Regression-Tests

### DoReMi (Kat. A)
- **URL:** https://github.com/steinbergmedia/DoReMi (auch tianweiy-Mirror)
- **Lizenz:** **CC-BY 4.0**
- **Inhalt:** ~6.500 Seiten synthetische Notationen mit MusicXML + Symbol-Bounding-Boxes, hochauflösend
- **Sheetstorm-Fit:** ⭐⭐⭐⭐ — Symbol-Detection-relevant, gute Mid-Size für Layout-Analyse
- **Pipeline-Stufe:** Symbol-Detection-Tests, Layout-Eval

### GrandStaff (Kat. A — pianoform)
- **URL:** https://grfia.dlsi.ua.es/sheet-music-transformer/
- **Lizenz:** **CC-BY 4.0**
- **Inhalt:** ~53.000 polyphone pianoform-Systeme, Image + **kern
- **Sheetstorm-Fit:** ⭐⭐⭐⭐ — pianoform ≈ Klavier-Akkord-Auszug, wichtig für mehrstimmige System-Tests (Stimmen 1+2 in einem Notensystem)
- **Pipeline-Stufe:** Pianoform/Polyphon-Tests (z.B. zwei Stimmen pro Stab)

### DeepScores V2 (Kat. A, C)
- **URL:** https://zenodo.org/record/4012193 / https://deepscores.com
- **Lizenz:** **CC-BY 4.0** (laut deepscores.com und arxiv 2011.02703)
- **Inhalt:** ~255.000 Seiten synthetisch, ~80 Mio. Symbol-Instanzen mit COCO-style Annotations
- **Sheetstorm-Fit:** ⭐⭐⭐ (Phase 3) — riesig (mehrere GB), nicht für CI, aber ideal als ML-Trainings-Backbone für Phase 3
- **Caveat:** Sehr groß → Git-LFS oder externer Storage nötig

### OpenScore String Quartets (Kat. A — polyphon)
- **URL:** https://github.com/openscore/string-quartets
- **Lizenz:** **CC0**
- **Inhalt:** Haydn/Mozart/Beethoven-Quartette als MusicXML
- **Sheetstorm-Fit:** ⭐⭐⭐ — Multi-Stimmen-Partitur (4 Instrumente in System-Stack) ≈ Brass-Quartett-Setup
- **Pipeline-Stufe:** Multi-Staff Layout-Test

### OpenScore Bach 371 Chorales (Kat. A, E)
- **URL:** https://github.com/openscore/bach-371-chorales
- **Lizenz:** **CC0**
- **Inhalt:** Alle 371 Choräle, 4-stimmig SATB
- **Sheetstorm-Fit:** ⭐⭐⭐⭐ — choralbuch-ähnlich, sehr ähnlich zu lutherischen/katholischen Chorälen die Vereine spielen. Saubere 4-Stimmen-Notation.
- **Pipeline-Stufe:** Choral-spezifische Tests

### Mutopia Project (Kat. A, D)
- **URL:** https://www.mutopiaproject.org
- **Lizenz:** **gemischt** — PD, CC-BY-SA 4.0, CC-BY 3.0 — pro Datei prüfen!
- **Inhalt:** ~2.300 Stücke, primär Klavier/Solo, Brass-Band-Sektion DÜNN
- **Sheetstorm-Fit:** ⭐⭐ — Apache-Kompatibilität pro File prüfen. CC-BY-SA ist OK für Repo (kein NC), aber SA bedeutet ggf. Pflicht zur Lizenz-Beibehaltung im abgeleiteten Korpus.
- **Aktion:** Kleine Sub-Selektion (PD only) ziehen, GT-Validierung manuell

### Humdrum kernScores (Kat. A — symbolisch)
- **URL:** https://kern.humdrum.org / https://github.com/humdrum-tools/humdrum-data
- **Lizenz:** überwiegend **Public Domain** (klassische Komponisten >70J tot)
- **Inhalt:** ~10.000 **kern-Stücke (Bach, Beethoven, Mozart, Chopin, …)
- **Sheetstorm-Fit:** ⭐⭐⭐ — KEIN Image enthalten. Aber: Wir können via Verovio/MuseScore selbst rendern → synthetic Image+GT-Pairs in beliebiger Stilqualität
- **Pipeline-Stufe:** Synthetic-Render-Augmentation

### MUSCIMA++ (Kat. A — handwritten)
- **URL:** https://muscima.readthedocs.io
- **Lizenz:** ❌ **CC-BY-NC-SA 4.0** → **NICHT ins Apache-Repo committen**
- **Status:** Loader-Code ist da, Daten lokal nutzen (`~/.local/share/sheetstorm/datasets/muscima++/` außerhalb Repo). Hinweis im README dokumentieren.

### Camera-PrIMuS (Kat. A — camera)
- **URL:** https://grfia.dlsi.ua.es/primus/
- **Lizenz:** ❌ **CC-BY-NC-SA 4.0**
- **Notiz:** Vorsicht — wird oft mit dem CC-BY-Original-PrIMuS verwechselt!

### MAPS / MusicNet / Bach10 (Kat. B)
- ❌ Alle **NC**-restriktiv. Kein Apache-Fit.
- **Alternative für Score-Following:** OpenScore Lieder + selbst rendern + MIDI aus MusicXML extrahieren = saubere Image+MIDI-Pairs unter CC0!

### Audiveris omr-dataset-tools / apacha/OMR-Datasets
- **URL:** https://github.com/Audiveris/omr-dataset-tools, https://github.com/apacha/OMR-Datasets
- **Wert:** Meta-Repos / Linkmaps zu vielen anderen Datasets, gute Übersicht der Symbol-Klassifier-Datensätze

---

## Empfehlung Roadmap

### Sofort einbinden (Sprint +1)

| Dataset | Repo-Pfad-Vorschlag | Pipeline-Stufe |
|---------|---------------------|----------------|
| **OpenScore Lieder Corpus** (Subset 50–100 Lieder) | `tests/fixtures/openscore-lieder/` | E2E-Pipeline auf MusicXML-GT |
| **Sheet Music Benchmark** | `tests/benchmark/smb/` | Master-Eval mit OMR-NED |
| **PrIMuS** (Subset 500 Inzipits) | `tests/fixtures/primus-mono/` | Mono-Regression-Tests |

**Konkrete Schritte:**
1. `tests/fixtures/datasets.toml` mit Download-URLs + erwarteten SHA256-Hashes anlegen
2. `scripts/fetch-datasets.ps1` (PowerShell, da Windows) für CI-fähigen Download mit Cache
3. `tests/benchmark/run_omr_ned.rs` (Metrik-Implementierung gemäß SMB-Paper)
4. Lizenz-Manifest `docs/datasets-licenses.md` mit Attributions-Zeilen

### Mittelfrist (Phase 2 — U-Net Staff-Removal)

| Dataset | Zweck |
|---------|-------|
| **CVC-MUSCIMA** | Staff-Removal-Pairs als Trainingsbasis |
| **DoReMi** | Symbol-Detection-Augment, Mid-Size |
| **GrandStaff** | Pianoform-Polyphon-Eval |
| **OpenScore Bach Chorales** | Choralbuch-Spezialfall |

### Langfrist (Phase 3 — Eigenes ML-Model)

| Dataset | Zweck |
|---------|-------|
| **DeepScores V2** | Synthetic-Pretraining (255k Seiten) |
| **Eigenes Vereins-Korpus (NEW)** | Fine-Tuning auf Brass-Band-Stil |
| **MUSCIMA++** (lokal, nicht ins Repo) | Handwriting-Branch |

### Nicht nutzen

| Dataset | Grund |
|---------|-------|
| **MUSCIMA++ in CI** | CC-BY-NC-SA 4.0 ❌ → nur lokal, Hinweis im README |
| **Camera-PrIMuS** | CC-BY-NC-SA → in CI nicht nutzbar |
| **MAPS / MusicNet / Bach10** | NC-Lizenz, zudem Audio-fokussiert, geringer OMR-Wert |
| **Wikifonia** | Tot, juristisch grau |
| **SEILS** | Mensural-Notation, out-of-scope für Vereinskontext |

---

## Lücken-Analyse

### Was fehlt absolut?

1. **Echtes Brass-Band-/Concert-Band-Repertoire mit Image+XML-Pairs**
   - Es existiert **kein bekannter Korpus** dieser Art unter Apache-kompatibler Lizenz
   - IMSLP / BandMusic PDF Library = nur PDFs ohne GT
   - Mutopia hat dünne Brass-Sektion und gemischte Lizenzen

2. **Deutsche Volkslieder mit Scan+XML-Pairs**
   - Zupfgeigenhansl (1909) ist PD, aber **kein digitales MusicXML-Korpus existiert** öffentlich
   - Deutsches Volksliedarchiv hat keine Bulk-MusicXML-Distribution

3. **Handgeschriebene moderne Vereinsblätter**
   - MUSCIMA++ ist NC und stilistisch alt (klassisch, kein Vereinslayout)

### Empfehlung: Eigenes Sheetstorm-Korpus aufbauen

**Vorschlag: "Sheetstorm Reference Corpus v1"** (`tests/fixtures/sheetstorm-ref/`)

| Subset | Größe | Quelle | Aufwand |
|--------|-------|--------|---------|
| `brass-band-modern` | 10–20 PDFs | Eigene Vereins-PDFs (Mendocino etc.), manuell mit MuseScore zu MusicXML | ~30–60 min/PDF × 20 = ~15h |
| `volkslied-german` | 30–50 Lieder | OpenScore Lieder Subset (CC0) + Eigen-Renderung | ~5h Skript-Setup |
| `chorale-german` | 20 Choräle | OpenScore Bach (CC0) + EG/GL-Rendering aus PD-LilyPond | ~10h |
| `handwritten-band` | 5–10 Seiten | Eigene Sammlung (mit Erlaubnis), CC-BY publizieren | ~10h Scan+Annot. |

**Lizenz-Empfehlung für eigenes Korpus:** **CC-BY 4.0** — kompatibel zu Apache, attribution-friendly, sharing-bereit für Forschung.

**Tooling:** `scripts/build-reference-corpus.ps1` mit Verovio/MuseScore-CLI für Image-Render aus MusicXML, `tests/tools/musicxml-to-png.rs` für deterministische Renderings.

---

## Anhang: Quellen + URLs

### Primärquellen
- OpenScore: https://github.com/OpenScore · https://openscore.cc
- CVC-MUSCIMA: https://www.cvc.uab.es/cvcmuscima/
- Sheet Music Benchmark: https://zenodo.org/records/17706531
- PrIMuS / Camera-PrIMuS / GrandStaff: https://grfia.dlsi.ua.es/
- DeepScores V2: https://zenodo.org/record/4012193 · arXiv:2011.02703
- DoReMi: https://github.com/steinbergmedia/DoReMi
- MUSCIMA++: https://muscima.readthedocs.io
- Humdrum kernScores: https://kern.humdrum.org
- Mutopia: https://www.mutopiaproject.org
- IMSLP brass band: https://imslp.org/wiki/Category:For_brass_band
- BandMusic PDF Library: https://bandmusicpdf.org

### Audio/MIDI-Datasets (NC, nur Referenz)
- MAPS: https://www.tsi.telecom-paristech.fr/aao/en/2010/07/07/the-maps-database/
- MusicNet: https://homes.cs.washington.edu/~thickstn/musicnet.html
- MAESTRO: https://magenta.tensorflow.org/datasets/maestro
- Bach10: https://labsites.rochester.edu/haque/bach10.html

### Meta-Ressourcen
- apacha/OMR-Datasets: https://github.com/apacha/OMR-Datasets
- Audiveris omr-dataset-tools: https://github.com/Audiveris/omr-dataset-tools

### Lizenz-Texte
- CC0: https://creativecommons.org/publicdomain/zero/1.0/
- CC-BY 4.0: https://creativecommons.org/licenses/by/4.0/
- CC-BY-NC-SA 4.0 (inkompatibel): https://creativecommons.org/licenses/by-nc-sa/4.0/

---

## STATUS: DONE_WITH_CONCERNS

**WORKS:**
- 21 Datensätze recherchiert in 5 Kategorien
- Apache-2.0-Kompatibilität pro Dataset klar markiert
- Top-3-Sofortempfehlung mit konkreten Repo-Pfad-Vorschlägen
- Lücken-Analyse + konkreter Vorschlag für Eigen-Korpus mit Aufwandschätzung

**RISK:**
- **DeepScores V2 Lizenz-Verifikation:** Web-Suche bestätigt CC-BY 4.0, aber LICENSE-Datei im Zenodo-Download muss vor Einbindung verifiziert werden (Web-Quellen ≠ verbindlich)
- **Mutopia pro-File-Lizenzen:** Keine Bulk-Filterung möglich; manuelles Sichten der ausgewählten Files nötig
- **SMB-Lizenz:** Auf Zenodo-Default CC-BY 4.0 angenommen — LICENSE.txt im Download bestätigen
- **OpenScore Lieder:** CC0 ist gut etabliert, aber pro-File-Header (`Copyright`) im MusicXML auf CC0-Vermerk prüfen, falls in einzelnen Imports Edits durch Dritte mit anderer Lizenz erfolgten

**FOLLOW_UP:**
1. **Sprint +1:** OpenScore Lieder Subset + SMB einbinden (Tests/Benchmark)
2. **Sprint +2:** OMR-NED-Metrik in Rust implementieren (gemäß SMB-Paper)
3. **Sprint +2:** `scripts/fetch-datasets.ps1` mit SHA256-Cache
4. **Mittelfristig:** Eigenes Sheetstorm Reference Corpus v1 anstoßen (~40–50h Arbeit, 10–20 Vereins-PDFs labeln)
5. **Vor Phase 2:** CVC-MUSCIMA-Download via Email-Form anfragen
6. **Vor Phase 3:** Storage-Strategie für DeepScores V2 (mehrere GB → externer S3/Git-LFS, nicht in Hauptrepo)
