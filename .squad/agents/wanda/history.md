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

### 2026-03-28 — Vollständiges UX-Design v2.0 erstellt

**Durchgeführte Arbeit:** Zwei umfassende UX-Design-Dokumente erstellt (v2-Überarbeitung mit verbessertem Modell):

1. **`docs/ux-design.md`** (neu) — Vollständiges UX-Design-Dokument:
   - 5 Design-Prinzipien (Focus-First, Touch-Native, Responsive, Accessibility, Progressive Disclosure)
   - 7 User Personas (Dirigent, Musiker Probe/Auftritt, Notenwart, Admin, Lehrer, Schüler) mit Kontext, Zielen, Frustrationen und UX-Implikationen
   - 8 vollständige Screen Flows mit ASCII-Wireframes (Spielmodus, Import, Bibliothek, Setlist, Kapellenverwaltung, Vereinsleben, Annotationen, Tuner)
   - Navigation & IA (Bottom-Tabs Mobile, Sidebar Desktop, Deep-Link-Hierarchie)
   - Responsive Breakpoints (Phone/Tablet/Desktop) mit adaptiver Zoom-Strategie
   - Interaction Patterns (Seitenwechsel, Annotationsgesten, Feedback, Fußpedal)
   - Design Tokens (Farben, Typografie, Spacing, Elevation, Animation, Icons)

2. **`docs/ux-konfiguration.md`** (v2 Überarbeitung) — UX für 3-Ebenen-Konfiguration:
   - Ebenenmodell (Kapelle/Blau → Nutzer/Grün → Gerät/Orange) mit Vererbungslogik
   - Vollständige Settings-Navigation inkl. Suchfunktion
   - Admin-Dashboard mit Handlungsbedarf-Widget
   - Alle 3 Einstellungsebenen mit Phone + Desktop Wireframes
   - Interaction Patterns (Auto-Save + Undo-Toast, kein Neustart, Vererbungsanzeige mit Lock)
   - Onboarding-Wizard (5 Schritte, max. 3 Minuten)
   - Kontextuelle Spielmodus-Einstellungen (max. 5 Optionen, Notenblatt bleibt sichtbar)
   - 6 Edge Cases (Ersteinrichtung, Multi-Kapellen-Konflikt, Offline, AI-Key fehlt, Aushilfen, Gerätewechsel)
   - 5 vollständige Key-Screen-Wireframes (Phone + Desktop)

**Neue Erkenntnisse aus v2-Überarbeitung:**

1. **Asymmetrische Tap-Zonen im Spielmodus** (40% zurück / 60% weiter) sind ergonomisch sinnvoll — rechts wird häufiger getippt, der Daumen liegt natürlich rechts.

2. **Tuner muss aus 1 Meter Abstand lesbar sein** — Erkannter Ton mindestens 72sp. Das ist eine echte Accessibility-Anforderung für Blaskapellen-Proben.

3. **Aushilfen-Link** ist sowohl UX-Feature als auch Verwaltungs-Feature — muss in beiden Kontexten (Bibliothek-Detail UND Mitgliederverwaltung) zugänglich sein.

4. **Onboarding-Regel:** Maximal 5 Fragen, alle skipbar, keine Zahlungsinformationen. Musiker sollen in unter 3 Minuten spielbereit sein.

5. **Deep-Link-Hierarchie** definiert — `sheetstorm://aushilfe/[token]` für Aushilfen-Zugang ohne Account ist ein wichtiger Edge-Case für das URL-Schema.

6. **Kontextuelle Spielmodus-Einstellungen:** Maximal 5 Optionen (Nachtmodus, Half-Page-Turn, Schriftgröße, Ebenen-Toggle, Helligkeit) — Notenblatt bleibt immer sichtbar dahinter.

7. **Gerät-Einstellungen nie synchronisieren** — intelligente Defaults pro Gerätetyp beim ersten Login (neu auf diesem Gerät). Phone und Tablet brauchen verschiedene Defaults.

**Entscheidungsvorschlag eingereicht:** `.squad/decisions/inbox/wanda-v2-ux.md` — Zusammenfassung der wichtigsten UX-Entscheidungen aus v2.

### 2026-03-28 — v2 Complete Relaunch Abgeschlossen

**Scribe-Koordination:** Alle Inbox-Dateien in `decisions.md` konsolidiert. Session Log geschrieben: `.squad/log/2026-03-28T11-55-v2-relaunch.md`

**Team-Status nach v2-Relaunch:**
- Fury (Analyst): Marktanalyse v2 + Gap-Analyse v2 + PR #1 ✅
- Stark (Lead/Architect): Spezifikation v2 + Meilensteine + Config + Tech-Stack ✅
- Wanda (UX): UX-Design v2 + UX-Konfiguration ✅
- Entscheidungen: 16 Directives + Policy-Entscheidungen in decisions.md dokumentiert
- Next: Thomas Review im PR, danach MS1 Implementierung
