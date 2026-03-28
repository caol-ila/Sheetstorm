### 2026-03-28: Konfigurationskonzept & Technologie-Entscheidung
**By:** Stark (Lead / Architect)
**What:**
- `docs/konfigurationskonzept.md` erstellt: 3-Ebenen-Konfigurationssystem (Kapelle → Nutzer → Gerät) mit Override-Regeln, Policy-System, Datenmodell (JSONB), Sync-Strategie, Admin-Berechtigungen, vollständigem Settings-Tree.
- `docs/technologie-entscheidung.md` erstellt: 5 Frontend-Stacks evaluiert, 3 Backend-Optionen, DB-Entscheidung, Echtzeit-Metronom-Technologie.

**Key Decisions:**
1. **Frontend: Flutter (Dart)** — Beste Canvas-/Touch-/Stift-Engine für Cross-Platform. Dart ist C#-ähnlich (Thomas' Lernkurve: ~2 Wochen). 95%+ Code-Sharing über alle Plattformen.
2. **Backend: ASP.NET Core 9 (C#)** — Thomas' Expertise, Performance-Leader, nativer UDP-Server für Metronom.
3. **Datenbank: PostgreSQL 16 (Server) + SQLite/Drift (Client)** — JSONB für flexible Config, relationale Power für Berechtigungen, Offline-Cache.
4. **Echtzeit: WiFi UDP Multicast (primär) + SignalR WebSocket (Fallback)** — <5ms LAN-Latenz für Metronom.
5. **Config-System: 3-Ebenen mit Policy-Override** — Kapelle setzt Rahmen, Nutzer personalisiert, Gerät optimiert. Policies können Override verbieten.
6. **Hosting: Azure Ökosystem** — App Service, Blob Storage, CDN, Application Insights.
7. **Fallback-Trigger:** Flutter-Eignung wird nach M1 Sprint 2 (Spielmodus-Prototype) evaluiert. Umschwenken auf React Native oder MAUI falls Performance-Ziele nicht erreicht.

**Why:** Thomas hat ein Konfigurationskonzept und Tech-Stack-Empfehlung angefordert. Die Entscheidung balanciert Thomas' .NET-Hintergrund (Backend bleibt C#) mit den technischen Anforderungen (Flutter für best-in-class Touch/Canvas UI).
