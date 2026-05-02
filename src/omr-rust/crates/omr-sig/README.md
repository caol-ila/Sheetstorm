# omr-sig — Symbol Interpretation Graph

> Multi-Hypothesen-Architektur für OMR (Optical Music Recognition).

## Idee

Klassische OMR-Pipelines treffen früh harte Entscheidungen ("dies ist ein Notenkopf,
jenes nicht"). Bei mehrdeutigen Bildern verlieren wir dadurch wichtige Alternativen.

Das **Symbol Interpretation Graph (SIG)** modelliert stattdessen jede mögliche
Interpretation als Knoten (`Inter`) und Beziehungen als Kanten (`Relation`).

- **Konflikte** (`Exclusion`): die beiden Inters dürfen nicht gleichzeitig wahr sein
- **Unterstützungen** (`Support`): wenn beide wahr sind, verstärken sie sich gegenseitig

Über iterative Reduktion wird die konsistenteste Hypothesen-Menge gefunden.

## Inspiration

Das SIG-Konzept stammt aus [Audiveris](https://github.com/Audiveris/audiveris)
(Java, Apache-2.0). Diese Crate baut die Idee in Rust nach und erweitert sie um
mehrere Sheetstorm-spezifische Features.

## Iteration 1 — Foundation (dieser PR)

Was diese Crate **liefert**:

| Modul | Inhalt |
|---|---|
| [`grade`](src/grade.rs) | `Grade` (clamped float in [0,1]), `GradeImpacts` (geometric mean), `contextual_grade()` |
| [`inter`](src/inter.rs) | `Inter` Trait, `InterId`, `InterKind` (24 Varianten), `InterMeta`, `Provenance` |
| [`relation`](src/relation.rs) | `Relation` Struct, `RelationKind` (50+ Varianten), `Exclusion`/`Support` Variant-Enum |
| [`sig`](src/sig.rs) | `Sig` Hauptstruktur, `add_inter`/`add_relation`/`reduce()` mit Greedy-Conflict-Resolver |
| [`history`](src/history.rs) | `History` (Op-Log), `EditOperationKind` für Undo/Redo |

Was diese Crate **nicht** liefert (folgt in späteren Iterationen):
- Migration der bestehenden Detektoren (templates, stems, beams, ...) auf SIG
- Music-Theory-Edges (Key/Voice-Leading/Phrase) — separate Crate `omr-music-theory`
- Persistenz (SQLite + Spatial-Index) — separate Crate `omr-sig-store`
- ML-Integration (Multi-Hypothesis-Distributions, Music-Language-Model) — separate Crate `omr-sig-ml`
- Bidirektionaler MusicXML/MEI-Codec — Erweiterung von `omr-musicxml`

## Erweiterungen über Audiveris hinaus

| # | Feature | Audiveris? | Status in dieser Iteration |
|---|---------|------------|---------------------------|
| 1 | Multi-Hypothesis-Inter mit `Distribution<T>` | ❌ | Geplant für `omr-sig-ml` |
| 2 | Tonality-/Key-Consistency-Edges | ❌ | RelationKind bereits definiert, Implementierung in `omr-music-theory` |
| 3 | Voice-Leading- & Harmony-Edges | ❌ | RelationKind bereits definiert |
| 4 | Metric/Rhythm-Constraint-Edges | ❌ (nur lokal) | `MeasureBudget` RelationKind bereits definiert |
| 5 | Scope-Relations für Direktiven (`f`, `cresc.`, `Allegro`) | ❌ | `DynamicScope`, `TempoScope`, `PedalScope`, `OctaveScope` definiert |
| 6 | Repeat-/Volta-/DC-DS-Strukturgraph | ❌ | `RepeatBlock`, `AlternateEnding`, `Anacrusis`, `DaCapo`, `DalSegno`, `Coda` definiert |
| 7 | Cross-Part-Relations (Trumpet 1 ↔ Trumpet 2) | ❌ | `CrossPartAlignment`, `SamePieceConsensus`, `MotifMatch` definiert |
| 8 | Provenance & Frozen-Flag pro Inter | ❌ | ✅ Implementiert in `InterMeta` + `Relation` |
| 9 | Operations-Log (Event-Sourcing) | ❌ | ✅ Foundation in `history` Modul |
| 10 | Bidirektionale Sync MEI/MusicXML ⟷ SIG | ❌ (Export-only) | Geplant für `omr-sig-codec` |

## Beispiel — Konflikt-Auflösung

```rust
use omr_sig::{Sig, Relation, RelationKind, ExclusionCause};

let mut sig = Sig::new();
let head_a = mk_head_inter(&mut sig, grade=0.9);  // "wahrscheinlicher Head"
let head_b = mk_head_inter(&mut sig, grade=0.4);  // "schwach detected, gleicher Pixel"

// Mutual-Exclusion: zwei Inters belegen dieselbe Region
sig.add_relation(Relation::exclusion(
    RelationKind::HeadStem,  // beliebige Kind
    head_a, head_b,
    ExclusionCause::BoundsOverlap,
));

let report = sig.reduce();
// head_b wird gelöscht (niedrigerer Grade), head_a bleibt
```

## Beispiel — Frozen-Inter überlebt Reduktion

```rust
let user_confirmed = sig.next_inter_id();
let meta = InterMeta::new(user_confirmed, InterKind::Head, bounds, Grade::new(0.4))
    .freeze();  // ← User hat bestätigt
sig.add_inter(Box::new(MyInter { meta }));

// Auch wenn ein "stärkerer" Inter im Konflikt steht: der frozen Inter überlebt.
// Der "stärkere" wird stattdessen entfernt.
```

## Beispiel — Support hebt Contextual Grade

```rust
let head = mk_inter(&mut sig, grade=0.6);
let stem = mk_inter(&mut sig, grade=0.6);

// Head und Stem stützen sich gegenseitig (geometrische Nähe).
sig.add_relation(Relation::support(
    RelationKind::HeadStem,
    head, stem,
    SupportImpacts::symmetric(2.0, SupportKind::Geometric),
));

sig.contextualize();
// head.effective_grade() ist nun > 0.6 (durch Stem-Support)
// stem.effective_grade() ist nun > 0.6 (durch Head-Support)
```

## Tests

```powershell
cd src/omr-rust
cargo test -p omr-sig
# 20 tests passed
```

## Roadmap

Sieh `~/.copilot/session-state/<session>/plan.md` für die Migration-Strategie über
6 Phasen hinweg. Diese Crate ist Phase 1.
