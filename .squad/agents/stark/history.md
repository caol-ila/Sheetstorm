# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** Flutter (Dart) Frontend + ASP.NET Core 9 Backend + PostgreSQL + SQLite (Client)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design, Technologie-Entscheidung
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
- Lehre-Modul: Details von Thomas ausstehend
- AI-Provider: Azure Vision als Minimum, weitere zu evaluieren

### 2026-03-28: Konfigurationskonzept & Technologie-Entscheidung

**Konfigurationskonzept (3-Ebenen-Modell):**
- Ebene 1 (Kapelle): AI-Keys, Berechtigungen, Branding, Policies, Standard-Sprache. Nur Admin darf ändern, Dirigent teilweise.
- Ebene 2 (Nutzer): Theme, Sprache, Instrumente, Standard-Stimme pro Kapelle, Benachrichtigungen, persönliche AI-Keys. Synchronisiert über alle Geräte.
- Ebene 3 (Gerät): Display, Audio/Tuner, Touch, Offline-Speicher. Bleibt lokal auf dem Gerät.
- Override-Regel: Gerät > Nutzer > Kapelle > System-Default. Kapelle kann Policies setzen die Override verbieten (forceLocale, allowUserKeys=false).
- Speicherung: JSONB in PostgreSQL (Server), SQLite (Client-Cache). Config pro Ebene als eigene Tabelle.
- Sync: Kapelle = Server→Client, Nutzer = bidirektional (Last-Write-Wins per Feld), Gerät = lokal (Server-Backup optional).
- Multi-Kapellen: Kapellen-Config gilt nur im aktiven Kapellen-Kontext. Nutzer-/Geräte-Config ist kapellen-unabhängig.
- Audit-Trail für Kapellen-Config-Änderungen.

**Technologie-Entscheidung:**
- Frontend: Flutter (Dart) — Beste Cross-Platform-Engine für touch-first, canvas-intensive Apps. Dart ähnlich C#, Thomas Lernkurve ~2 Wochen.
- Backend: ASP.NET Core 9 (C#) — Thomas' Expertise, Performance-Leader, UDP-Kontrolle für Metronom.
- Server-DB: PostgreSQL 16 (JSONB für Config, relationale Power für Rollen/Berechtigungen).
- Client-DB: SQLite via Drift (Offline-Cache, typsichere Queries).
- File Storage: Azure Blob Storage + CDN.
- Echtzeit: WiFi UDP Multicast (primär, <5ms LAN) + SignalR WebSocket (Fallback/Remote).
- CI/CD: GitHub Actions. Hosting: Azure Ökosystem.
- Fallback-Trigger: Wenn Flutter Spielmodus-Prototype (M1 Sprint 2) Seitenwechsel >200ms oder Stift-Latenz >50ms zeigt → React Native oder MAUI evaluieren.

**Bewertete und verworfene Alternativen:**
- .NET MAUI + Blazor: Thomas' Komfort, aber schwächeres Touch/Stift-Ökosystem, Blazor WASM zu schwer für Web.
- React Native: Gutes Ökosystem, aber Desktop/Web-Story schwach, Lernkurve für Thomas.
- Next.js + Capacitor: Web-first, aber WebView-Performance auf Mobile kritisch für Seitenwechsel <100ms.
- Electron + React Native: Zwei Projekte = doppelter Aufwand, nicht tragbar für kleines Team.
- BaaS (Supabase/Firebase): Kein Custom-UDP für Metronom möglich → Dealbreaker als alleiniges Backend.
