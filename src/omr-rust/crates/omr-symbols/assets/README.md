# Bravura Font Asset & Symbol-Templates

Dieses Verzeichnis enthält die Bravura-Schriftdatei sowie deren Lizenz.
Die Datei wird vom Modul `omr_symbols::templates` per `include_bytes!` eingebettet
und zur Generierung von SMuFL-basierten Trainings-Patches für den OMR-Patch-Klassifikator genutzt.

## Dateien

| Datei                  | Quelle | Lizenz |
|------------------------|--------|--------|
| `Bravura.otf`          | <https://github.com/steinbergmedia/bravura> Tag `bravura-1.380` | SIL Open Font License 1.1 |
| `BRAVURA-LICENSE.txt`  | OFL.txt aus demselben Release | SIL OFL 1.1 |

Bravura ist ein SMuFL-Standard-Musik-Font von Steinberg Media Technologies GmbH.
Die SIL Open Font License ist mit Apache-2.0 kompatibel — das Font-Binary darf zusammen
mit der Lizenzdatei (siehe `BRAVURA-LICENSE.txt`) ausgeliefert werden, der Font-Name
„Bravura" darf nicht für eine modifizierte Variante wiederverwendet werden.

## Trainings-Workflow

1. **Templates generieren** (deterministisch, kein ML-Framework nötig):

   ```rust
   use omr_symbols::templates::write_corpus_to_disk;
   write_corpus_to_disk("training-data/symbol-patches", 32, 30, 42)?;
   ```

   Output-Layout:

   ```
   training-data/symbol-patches/
     notehead_filled/0000.png … 0029.png
     notehead_open/   …
     notehead_whole/  …
     coda/            …
     segno/           …
     dynamic_p/       …
     dynamic_mp/      …
     dynamic_mf/      …
     dynamic_f/       …
     noise/           …
   ```

2. **Klassifikator trainieren** — geschieht außerhalb dieses Crates
   (z. B. in einem dedizierten Hauptthread / Pipeline-Stage). Das Modul `templates`
   liefert ausschließlich Trainings-Daten, **keine Modell-Weights**.

## Augmentation pro Symbol

| Parameter          | Bereich         |
|--------------------|-----------------|
| Skalierung         | 0.8x – 1.2x     |
| Rotation           | -3° – +3°       |
| Salt-Pepper-Noise  | 0 % – 2 %       |
| Gauss-Blur σ       | 0 – 0.8         |
| Horizontal-Shift   | -3 – +3 px      |

Mit 30 Varianten pro Klasse × 10 Klassen ergibt das 300 Patches.
Ein zusätzlicher Augmentations-Pass im Trainings-Pipeline-Stage
kann die Sample-Zahl auf ca. 3000 erhöhen.

## Determinismus

Alle Operationen sind seed-deterministisch (`ChaCha8Rng`). Gleicher Seed →
bitidentischer Korpus. Siehe `tests/template_render.rs`.
