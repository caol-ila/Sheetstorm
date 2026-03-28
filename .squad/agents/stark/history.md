# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28: Spezifikation & Meilensteinplanung erstellt

**Architektur-Entscheidungen:**
- Datenmodell: Kern-Entitäten sind Musiker, Kapelle, Mitgliedschaft (N:M mit Rollen), Stück, Stimme, Notenblatt. Persönliche Sammlung nutzt die gleichen Mechanismen wie Kapellen-Noten (Kapelle-ID = null, Musiker-ID gesetzt).
- Annotationssystem: SVG-Layer über Notenbildern mit relativen Positionen (%). Drei Sichtbarkeitsebenen (lokal/stimme/orchester) als Enum im Datenmodell.
- AI-Integration: Adapter-Pattern für Provider-Austauschbarkeit. Fallback-Kette: User-Key → Kapellen-Key → keine AI.
- Echtzeit-Metronom: WiFi UDP als primärer Kanal für niedrigste Latenz, WebSocket als Fallback. Clock-Sync via NTP-ähnlichem Protokoll, Beats als Timestamps statt "jetzt spielen"-Kommandos.
- API: REST mit JWT, Cursor-basierte Pagination, versioniert (/api/v1/).
- i18n: Alle Strings externalisiert ab Tag 1, auch wenn nur Deutsch. Kein Hardcoding.

**Meilenstein-Struktur:**
- 5 Meilensteine: Kern → Organisation → Tools → Lehre → Verfeinerung
- M4 (Lehre) kann parallel zu M2/M3 gestartet werden (nur M1-Abhängigkeit)
- Jeder Meilenstein hat eigene Definition of Done mit Testing und UX-Validierung

**Offene Punkte:**
- Tech-Stack noch nicht entschieden (wird nach Evaluierung festgelegt)
- Lehre-Modul: Details von Thomas ausstehend
- AI-Provider: Azure Vision als Minimum, weitere zu evaluieren
