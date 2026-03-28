# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28 — Marktanalyse abgeschlossen

**Wettbewerber-Landschaft:**
- 17+ Produkte analysiert in 9 Kategorien (Sheet Music, Blasmusik, Vereinsverwaltung, Setlist, Lehre, AI/OCR, Echtzeit-Sync)
- Markt ist stark fragmentiert — kein All-in-One-Produkt existiert
- **Stärkste Wettbewerber für unseren Use Case:** Marschpat (Blasmusik-Noten), Notabl (Musikverein All-in-One), Newzik (Ensemble-Kollaboration), Konzertmeister (Vereinsorganisation)
- forScore und MobileSheets dominieren bei Notenanzeige, sind aber reine Einzelmusiker-Tools

**Zentrale Marktlücken identifiziert:**
1. Kein Produkt kombiniert professionelle Notenanzeige + Vereinsverwaltung + AI-Upload
2. Intelligentes Stimmen-Mapping mit Fallback-Logik existiert nirgendwo
3. AI-gestützter Multi-Lied-Upload mit Labeling ist ein Novum
4. Multi-Kapellen-Zugehörigkeit wird von keinem Wettbewerber unterstützt
5. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester) als Kernkonzept fehlt überall
6. Echtzeit-Metronom-Sync im Notenkontext existiert nicht integriert
7. Lehre-Modul im Vereinskontext existiert nicht

**Wichtige Muster:**
- Blasmusik-Markt (DACH) hat eigene Anbieter (Marschpat, Notabl, Glissandoo, Musicorum) — internationaler Markt ist anders strukturiert
- Preismodelle: Mix aus Einmalkauf (forScore, MobileSheets), Abo (Newzik, Marschpat), Freemium (Glissandoo, Konzertmeister), und Open Source (BNote)
- Cross-Platform ist Pflicht — Kapellenmitglieder nutzen gemischte Geräte
- DSGVO-Konformität ist im DACH-Raum ein entscheidender Faktor
- BYOK (Bring Your Own Key) für AI-Dienste ist ein Alleinstellungsmerkmal ohne Konkurrenz
