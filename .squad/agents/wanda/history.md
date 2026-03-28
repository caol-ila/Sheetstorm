# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28 — UX-Konkurrenzanalyse: 14 Apps analysiert

**Durchgeführte Analyse:** Systematische UX-Research von 14 Konkurrenz-Apps (forScore, MobileSheets, Newzik, Marschpat, Notabl, Glissandoo, Konzertmeister, Musicorum, BandHelper, Musicnotes, SongBook, BAND App, Vereinsplaner, WePlayIn.Band). Ergebnis in `docs/ux-research-konkurrenz.md`.

**Kernerkenntnisse:**

1. **forScore setzt den UX-Goldstandard** für digitale Notenblätter — ablenkungsfreier Performance-Modus, Half-Page-Turn, Pencil-First Annotation, vielfältige Import-Wege. Das ist unsere Messlatte für den PDF-Viewer.

2. **Newzik ist der stärkste Inspiration-Geber für Ensemble-Workflows** — Echtzeit-Annotation-Sync, Layer-System (Privat/Public/Shared), Projekt-basierte Verteilung, Web=Admin/App=Performance Trennung. Aber: Kein Android, kein Stimmen-spezifisches Layer.

3. **Unser 3-Ebenen-Annotationssystem (Privat/Stimme/Orchester) ist ein genuiner Differenzierer** — kein Wettbewerber bietet das. Newzik kommt mit 2 Ebenen am nächsten.

4. **Marschpat versteht Blasmusik, aber versagt bei Annotationen** — Zero Annotation Support auf Notenblättern. Das ist für uns eine klare Chance: Blasmusik-Kontext + echte Annotations = winning combo.

5. **Musicorum's "Aushilfen-Link ohne Registrierung"** ist eine brillante UX-Idee, die wir übernehmen sollten. Temporärer Zugang für Ersatzmusiker = extrem pragmatisch.

6. **Notabl's 1-Klick-Stimmenneuverteilung** bei Absagen ist ein Must-Have-Pattern für Blaskapellen.

7. **Konzertmeister perfektioniert die 1-Klick Zu-/Absage** — großer Button, sofortige Anwesenheitsübersicht. Das muss unser Minimum sein.

8. **Der Markt ist fragmentiert: Vereine brauchen 2-3 Apps** (Noten + Verwaltung + Chat). Wir sind die All-in-One-Lösung.

9. **Cross-Platform ist Pflicht** — forScore (nur Apple) und Newzik (nur iOS+Web) verlieren dadurch Blaskapellen-Mitglieder mit Android.

10. **Anti-Pattern: Keine transparenten Preise** (Notabl) und **separate Lizenzen pro Plattform** (MobileSheets) frustrieren Vereine.

**Design-Inspirationsquellen:** Mobbin.com, PageFlows.com, UXLibrary.org für reale App-Screenshots und User Flows.

**Entscheidungsvorschlag eingereicht:** `.squad/decisions/inbox/wanda-ux-research.md` — 7 konkrete UX-Entscheidungen mit Begründung.
