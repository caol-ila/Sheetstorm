# Sheetstorm — Technologie-Entscheidung

> **Version:** 3.0  
> **Autor:** Stark (Lead / Architect)  
> **Datum:** 2026-03-28  
> **Aktualisiert:** 2026-03-28 (v3 — alle Versionen per `web_search` verifiziert)  
> **Status:** Zur Abstimmung via PR  
> **Methodik:** Jede Version per Web-Suche validiert. Keine Training-Data-Versionen.

---

## 1. Zusammenfassung der Entscheidung

| Komponente | Technologie | Version (verifiziert) |
|------------|-------------|----------------------|
| **Frontend** | Flutter (Dart) | 3.41.5 / Dart 3.11.0 |
| **State Management** | Riverpod | 3.3.1 (flutter_riverpod) |
| **PDF-Rendering** | pdfrx | 2.2.24 |
| **Client-DB** | SQLite via Drift | Drift 2.32.1 / SQLite 3.51.3 |
| **Backend** | ASP.NET Core (.NET 10 LTS, C# 14) | 10.0.5 |
| **Server-DB** | PostgreSQL | 18.3 |
| **Echtzeit (LAN)** | WiFi UDP Multicast | Custom (ASP.NET Core) |
| **Echtzeit (Remote)** | SignalR WebSocket | @microsoft/signalr 10.0.0 |
| **BLE (Fußpedal)** | flutter_blue_plus | 1.34.5 |
| **AI-OCR** | Azure AI Vision | Image Analysis 4.0 GA |
| **File Storage** | Azure Blob Storage + CDN | Aktuell |
| **CI/CD** | GitHub Actions | Aktuell |
| **Hosting** | Azure (App Service, Blob, CDN) | Aktuell |
| **Monitoring** | Application Insights + OpenTelemetry | Nativ in .NET 10 |

---

## 2. Frontend-Evaluierung

### Bewertungskriterien

Jedes Framework wurde auf 5 Kriterien bewertet (je 0–5 Punkte):
1. **Plattform-Support** — Android, iOS, Windows, Web (alle 4 benötigt)
2. **Canvas/PDF-Rendering** — Hochauflösende Notenblätter, SVG-Overlay, Seitenwechsel < 100ms
3. **Touch/Stylus** — Palm Rejection, Ink-Input, Fußpedal (BLE HID)
4. **Echtzeit-Fähigkeit** — Platform Channels, Audio-Latenz, UDP-Support
5. **Ökosystem & Lernkurve** — Für Thomas (C#/.NET-Hintergrund), Community, Packages

### Bewertungsmatrix

| Kriterium | Flutter 3.41 | .NET MAUI 10 | React Native 0.84 | KMP/Compose 1.10.3 | Avalonia 11.3 | Tauri v2.10 |
|-----------|:------------:|:------------:|:------------------:|:-------------------:|:-------------:|:-----------:|
| Plattform-Support | 5 | 4 | 3.5 | 4 | 4 | 3.5 |
| Canvas/PDF | 5 | 3 | 3.5 | 3 | 3 | 2.5 |
| Touch/Stylus | 5 | 3.5 | 3.5 | 3.5 | 3 | 2 |
| Echtzeit | 4 | 4.5 | 3.5 | 3.5 | 4 | 3 |
| Ökosystem/Lernkurve | 4.5 | 4.5 | 3 | 3 | 4 | 3 |
| **Gesamt** | **4.70** | **3.90** | **3.40** | **3.40** | **3.60** | **2.80** |

### Framework-Analyse im Detail

#### ✅ Flutter 3.41.5 / Dart 3.11.0 — GEWÄHLT (Score: 4.70)

**Aktuelle Version:** Flutter 3.41.5 (März 2026) mit Dart 3.11.0 (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- **Eigene Rendering-Engine (Impeller 2.0):** Kein WebView, kein nativer Widget-Wrapper. Pixelgenaue Kontrolle über Canvas — ideal für Notenblatt-Rendering mit SVG-Overlay. Impeller 2.0 in Flutter 3.41 nutzt AOT-Shader-Compilation, Metal (iOS) und Vulkan (Android) für ruckelfreies Rendering.
- **Plattform-Support:** Android ✅, iOS ✅, Windows Desktop ✅ (GA seit 2022), Web ✅ (Wasm in Arbeit, CanvasKit stable). Alle 4 Zielplattformen mit einer Codebase.
- **Touch/Stylus:** GestureDetector, CustomPainter, Listener — volle Kontrolle über Touch-Events, Pointer-Typ-Erkennung (Stylus vs. Finger), Palm Rejection via `PointerDeviceKind`.
- **PDF-Rendering:** pdfrx 2.2.24 (PDFium-basiert, alle Plattformen, aktiv gepflegt).
- **BLE-Support:** flutter_blue_plus 1.34.5 — Fußpedal-Integration via Bluetooth HID.
- **Dart ≈ C#:** Ähnliche Syntax (statisch typisiert, null safety, async/await, Klassen). Thomas' geschätzte Lernkurve: ~2 Wochen.
- **State Management:** Riverpod 3.3.1 — Offline-Persistence, Auto-Retry, typsichere Providers.
- **Community:** >1M aktive Entwickler, >167K GitHub Stars.
- **Flutter 3.41 Highlights:** Public Release Windows (transparente Quartals-Releases), Decoupling von Material/Cupertino-Bibliotheken, plattformspezifisches Asset-Bundling, Swift Package Manager (statt CocoaPods), Gradle 9 / Kotlin DSL auf Android.

**Schwächen:**
- **Audio-Latenz:** 1-2ms Platform Channel Overhead pro Aufruf. Für Sheetstorm akzeptabel, weil Metronom-Timing serverseitig (ASP.NET Core UDP) läuft und Flutter nur UI rendert.
- **Dart-Ökosystem kleiner als C#/.NET:** Weniger Enterprise-Libraries, aber für unsere Anforderungen alles vorhanden.

**Risiko-Mitigation:** Performance-Benchmark nach M1 Sprint 2 (Spielmodus-Prototype). Falls Seitenwechsel >200ms oder Stift-Latenz >50ms → Eskalation und Re-Evaluierung.

#### ❌ .NET MAUI 10 (.NET 10 LTS) — Score: 3.90

**Aktuelle Version:** .NET MAUI 10.0.5 (März 2026), .NET 10 LTS (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- Thomas' Komfort-Zone (C#, Visual Studio)
- Performance-Verbesserungen in .NET 10 (NativeAOT, schnellere Cold Starts)
- Blazor Hybrid für Web-Story
- Gute Desktop-Unterstützung (Windows, macOS)

**Schwächen:**
- **Kein einheitlicher InkCanvas:** Touch/Stift-Support ist plattformabhängig, kein konsistentes API wie Flutters CustomPainter
- **PDF-Rendering:** Kein natives MAUI PDF-Package auf dem Level von pdfrx. Abhängig von Drittanbietern (Telerik, Syncfusion — kostenpflichtig)
- **Blazor WASM:** ~15MB Download für Web-App — zu schwer für schnellen Start
- **Mobile-UX:** MAUI-Apps fühlen sich auf Mobile "weniger nativ" an als Flutter (keine eigene Rendering-Engine, Wrapper über native Widgets)

**Fazit:** Gute Option für Desktop-Apps, aber für unseren canvas-intensiven, touch-first Use Case hinter Flutter.

#### ❌ React Native 0.84.x — Score: 3.40

**Aktuelle Version:** React Native 0.84.x (Februar 2026) (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- Riesiges Ökosystem (npm)
- New Architecture (ab 0.82) mit synchronem Layout und Concurrent Rendering
- Gute Mobile-Story (iOS/Android)

**Schwächen:**
- **Windows:** react-native-windows existiert, aber signifikante Feature-Lücken vs. iOS/Android
- **Web:** react-native-web hat Einschränkungen bei Canvas-intensiven UIs
- **Lernkurve:** Thomas müsste JavaScript/TypeScript + React lernen (signifikanter Aufwand)
- **PDF/Canvas:** Keine native PDF-Rendering-Lösung auf dem Niveau von pdfrx

**Fazit:** Starkes Mobile-Framework, aber Desktop/Web-Story zu schwach und erhebliche Lernkurve für Thomas.

#### ❌ Kotlin Compose Multiplatform 1.10.3 — Score: 3.40

**Aktuelle Version:** Compose Multiplatform 1.10.3 (März 2026), Kotlin 2.1.x (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- iOS Support jetzt stable (seit 1.8.0)
- Starker Canvas-Support (Compose Canvas API)
- Kotlin ist gut lesbar für C#-Entwickler

**Schwächen:**
- **Kein multiplatform PDF-Package:** Kritischer Blocker — PDF muss plattformübergreifend gerendert werden
- **JRE-Abhängigkeit auf Desktop:** Verteilung schwieriger
- **Web:** Wasm-Support noch experimentell, noch nicht produktionsreif
- **Ökosystem:** Kleiner als Flutter für multiplatform-spezifische Packages

**Fazit:** Vielversprechend für die Zukunft, aber das fehlende PDF-Ökosystem ist ein Dealbreaker.

#### ❌ Avalonia UI 11.3.12 — Score: 3.60

**Aktuelle Version:** Avalonia 11.3.12 stable (Februar 2026), 12.0.0-rc1 in Preview (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- C#/XAML — Thomas' native Sprache
- Skia-basierte Rendering-Engine (wie Flutter)
- Guter Desktop-Support (Windows, macOS, Linux)
- Avalonia 12 bringt verbessertes Mobile-Targeting

**Schwächen:**
- **Mobile zu jung:** iOS/Android-Support ist funktional, aber das Ökosystem (Packages, Community-Erfahrung) ist deutlich kleiner
- **PDF-Rendering:** AvaloniaPdfViewer ist 0.0.2-pre — nicht produktionsreif
- **BLE/Fußpedal:** Kein dediziertes Avalonia-Package, müsste über .NET-Libraries gemacht werden
- **Community:** ~14K GitHub Stars vs. Flutters >167K — weniger Packages, weniger Stack Overflow Antworten

**Fazit:** Spannend für Desktop-first C#-Apps. Für unseren mobile-first, PDF-intensiven Use Case zu unreif. Bleibt als **Fallback-Option A** falls Flutter scheitert.

#### ❌ Tauri v2.10.3 — Score: 2.80

**Aktuelle Version:** Tauri v2.10.3 (März 2026) (verifiziert via Web-Suche, Stand 2026-03-28)

**Stärken:**
- Leichtgewichtig (Rust-Backend, kleine Binary-Größe)
- Web-Technologien im Frontend (HTML/CSS/JS)
- Mobile-Support in Tauri v2

**Schwächen:**
- **WebView = Dealbreaker:** Auf Mobile verwendet Tauri den System-WebView. Für canvas-intensive Touch-Apps mit <100ms Seitenwechsel und Stylus-Support nicht ausreichend.
- **Keine eigene Rendering-Engine:** Abhängig von WebView-Implementierung des OS
- **PDF in WebView:** Plattformabhängig, keine konsistente Performance
- **Touch/Stylus:** WebView-Touch-Events sind weniger präzise als native Gesture-APIs

**Fazit:** Hervorragend für Desktop-Utilities, aber für unseren Use Case (Touch, Canvas, Echtzeit) nicht geeignet.

---

## 3. Backend

### ✅ ASP.NET Core 10 (.NET 10 LTS, C# 14) — GEWÄHLT

**Aktuelle Version:** .NET 10.0.5 / ASP.NET Core 10 (Release: November 2025, Patch 10.0.5: März 2026, LTS bis November 2028) (verifiziert via Web-Suche, Stand 2026-03-28)

**Begründung:**
1. **Thomas' Expertise:** C# ist seine Stärke. Kein Onboarding nötig.
2. **Performance:** ASP.NET Core ist einer der schnellsten Web-Frameworks (TechEmpower Benchmarks Top-10).
3. **UDP-Server:** Nativer UDP-Socket-Support in C# für Metronom-Multicast — kein Workaround nötig.
4. **SignalR:** Eingebauter WebSocket-Fallback für Echtzeit-Features, 100K+ Concurrent Connections pro Server.
5. **LTS:** .NET 10 ist Long-Term-Support bis November 2028.
6. **OpenTelemetry:** Natives Monitoring in .NET 10, nahtlose Integration mit Application Insights.
7. **Entity Framework Core:** Typsicheres ORM für PostgreSQL mit JSONB-Support.

### Verworfene Alternativen

| Alternative | Warum nicht |
|-------------|-------------|
| Node.js / Express | Thomas müsste JS lernen. UDP weniger ergonomisch. Kein nativer Typ-Safety. |
| Go / Gin | Performant, aber Thomas müsste Go lernen. Kein ORM auf EF-Core-Niveau. |
| Rust / Actix | Höchste Performance, aber steilste Lernkurve. Für Backend overkill. |
| Spring Boot (Java/Kotlin) | Solide, aber JVM-Overhead. Thomas ist in C#, nicht Java, zuhause. |

---

## 4. Datenbanken

### Server: PostgreSQL 18.3 — GEWÄHLT

**Aktuelle Version:** PostgreSQL 18.3 (Februar 2026) (verifiziert via Web-Suche, Stand 2026-03-28)

**Begründung:**
- **JSONB:** Ideal für flexibles Config-Speichermodell (3-Ebenen-Konfiguration)
- **Relationale Power:** Rollen, Berechtigungen, Mitgliedschaften — klassisch relational
- **Async I/O:** Neu in PostgreSQL 18 — bessere Performance bei vielen gleichzeitigen Verbindungen
- **64-bit Transaction IDs:** Kein Transaction-ID-Wraparound mehr bei Langzeitbetrieb
- **Volltextsuche:** Eingebaut — für Noten-/Stücksuche ohne Elasticsearch
- **Entity Framework Core Support:** Npgsql ist ausgereift und stabil

### Client: SQLite 3.51.3 via Drift 2.32.1 — GEWÄHLT

**Aktuelle Version:** SQLite 3.51.3 (März 2026), Drift 2.32.1 (März 2026) (verifiziert via Web-Suche, Stand 2026-03-28)

> **Hinweis:** SQLite 3.52.0 wurde am 6. März 2026 released, aber wegen Rückwärtskompatibilitätsproblemen zurückgezogen. 3.51.3 bleibt die empfohlene stabile Version bis 3.53.0 erscheint.

**Begründung:**
- **Offline-Cache:** Noten, Config, Annotationen offline verfügbar
- **Drift:** Typsichere Queries in Dart, Auto-Updating Streams (reaktive UI), Schema-Migrationen
- **Plattform-Support:** Android, iOS, Windows, macOS, Linux, Web (Wasm)
- **Performance:** SQLite ist der schnellste eingebettete DB-Engine
- **Drift 2.32.1:** Migration zu sqlite3 v3.x, verbesserte Web-Kompatibilität

---

## 5. Echtzeit-Metronom-Architektur

### Anforderungen
- Synchroner Taktschlag bei allen Musikern (< 5ms Abweichung im LAN)
- Funktioniert im lokalen Netzwerk (Proberaum) UND remote (Internet)
- Musikalisch tauglich: Kein hörbarer Versatz

### Technologie-Vergleich

| Technologie | Latenz (LAN) | Latenz (Internet) | Zuverlässigkeit | Komplexität | Eignung |
|-------------|:------------:|:------------------:|:---------------:|:-----------:|:-------:|
| **WiFi UDP Multicast** | < 5ms | N/A (nur LAN) | Mittel (kein Ack) | Mittel | ✅ Primär (LAN) |
| **SignalR WebSocket** | 25–50ms | 50–150ms | Hoch (TCP) | Gering | ✅ Fallback (Remote) |
| **WebRTC DataChannel** | 10–50ms | 50–100ms | Hoch | Hoch (STUN/TURN) | ❌ Zu komplex |
| **BLE Broadcast** | 5–30ms | N/A (10m Reichweite) | Mittel (Interferenz) | Mittel | ❌ Reichweite zu gering |

### Entscheidung: Dual-Layer-Architektur

```
Proberaum (LAN):
  Dirigent → ASP.NET Core UDP-Server → WiFi UDP Multicast → Alle Clients
  Latenz: < 5ms

Remote (Internet):
  Dirigent → ASP.NET Core SignalR Hub → WebSocket → Alle Clients
  Latenz: < 50ms (tolerierbar für Remote-Proben)
```

### Clock-Synchronisation

- **Protokoll:** NTP-ähnlich (Client sendet Ping, Server antwortet mit Timestamp, Client berechnet Offset)
- **Beats als Timestamps:** Server sendet `{beat_nr, scheduled_time}` — Client spielt zum geplanten Zeitpunkt, nicht "jetzt"
- **Kompensation:** Jeder Client hat konfigurierbaren Latenz-Offset (Geräte-Config)
- **Auto-Detection:** App erkennt automatisch, ob UDP-Multicast verfügbar ist → sonst WebSocket

### Warum nicht WebRTC

- **Overhead:** ICE/STUN/TURN-Handshake für einfache Taktschlag-Nachrichten überdimensioniert
- **NAT-Traversal:** In Vereins-Netzwerken oft problematisch
- **Server-Architektur:** Wir brauchen ohnehin einen zentralen Server (ASP.NET Core) — kein P2P-Vorteil
- **Signaling-Server nötig:** Zusätzliche Komplexität ohne Gewinn für unseren Use Case

### Warum nicht BLE

- **Reichweite:** ~10m praktisch — zu wenig für größere Proberäume/Konzerthallen
- **Interferenz:** Bei 40+ Geräten in einem Raum Zuverlässigkeitsprobleme
- **Latenz-Spikes:** Bei Crowding unvorhersagbar
- **Bereits WiFi vorhanden:** Proberäume haben WiFi, BLE bringt keinen Zusatznutzen

---

## 6. File Storage

### Azure Blob Storage + CDN — GEWÄHLT

**Begründung:**
- **Azure-Ökosystem:** Passt zum ASP.NET Core Backend
- **CDN:** Schneller Download der Notenbilder weltweit
- **Skalierung:** Automatisch, keine Capacity-Planung nötig
- **Kosten:** Pay-per-Use, für Bilder/PDFs sehr günstig
- **SAS-Tokens:** Sichere, zeitlich begrenzte Download-URLs für Clients

---

## 7. Hosting & Infrastruktur

| Komponente | Service | Begründung |
|------------|---------|-------------|
| Backend API | Azure App Service | Managed, Auto-Scaling, Slots für Blue/Green Deployment |
| Datenbank | Azure Database for PostgreSQL Flexible Server | Managed PostgreSQL 18, Backups, HA |
| File Storage | Azure Blob Storage + Azure CDN | Notenbilder, Thumbnails |
| Monitoring | Application Insights + OpenTelemetry | Nativ in .NET 10, End-to-End Tracing |
| CI/CD | GitHub Actions | Thomas nutzt GitHub, nahtlose Integration |
| Secrets | Azure Key Vault | AI-Keys, Connection Strings |

---

## 8. Versions-Referenz

Alle Versionen per Web-Suche validiert (28. März 2026). Keine Version stammt aus Training-Data.

### Frontend-Stack

| Technologie | Version | Verifiziert via | Release-Datum | Support bis |
|-------------|---------|:---------------:|:-------------:|:-----------:|
| **Flutter** | 3.41.5 | web_search: "Flutter 3.41 latest patch version March 2026" | Feb 2026 (3.41.0), Patches bis Mär 2026 | Laufend (Quarterly Releases) |
| **Dart** | 3.11.0 | web_search: "Dart SDK latest stable version 2025 2026" | Feb 2026 | Gekoppelt an Flutter |
| **flutter_riverpod** | 3.3.1 | web_search: "flutter riverpod latest version 2026 pub.dev" | Mär 2026 | Laufend |
| **pdfrx** | 2.2.24 | web_search: "pdfrx flutter package latest version 2026" | Jan 2026 | Laufend |
| **Drift** | 2.32.1 | web_search: "drift flutter database package latest version 2026" | Mär 2026 | Laufend |
| **flutter_blue_plus** | 1.34.5 | web_search: "flutter_blue_plus latest version 2026 pub.dev" | Nov 2024 | Laufend |

### Backend-Stack

| Technologie | Version | Verifiziert via | Release-Datum | Support bis |
|-------------|---------|:---------------:|:-------------:|:-----------:|
| **ASP.NET Core / .NET** | 10.0.5 (LTS) | web_search: "ASP.NET Core .NET 10 LTS latest version 2026" | Nov 2025 (GA), Mär 2026 (Patch) | Nov 2028 |
| **C#** | 14 | Gekoppelt an .NET 10 | Nov 2025 | Nov 2028 |
| **SignalR** | @microsoft/signalr 10.0.0 | web_search: "SignalR ASP.NET Core latest version 2026" | Nov 2025 | Gekoppelt an .NET 10 |

### Datenbanken

| Technologie | Version | Verifiziert via | Release-Datum | Support bis |
|-------------|---------|:---------------:|:-------------:|:-----------:|
| **PostgreSQL** | 18.3 | web_search: "PostgreSQL latest stable version 2026" | Feb 2026 | ~Nov 2030 |
| **SQLite** | 3.51.3 | web_search: "SQLite latest version 2026" + "SQLite 3.52.0 release" (3.52.0 zurückgezogen) | Mär 2026 | Laufend (Support bis mindestens 2050) |

### Evaluierte Frontend-Frameworks (nicht gewählt)

| Technologie | Version | Verifiziert via | Release-Datum |
|-------------|---------|:---------------:|:-------------:|
| **.NET MAUI** | 10.0.5 (.NET 10 LTS) | web_search: ".NET MAUI latest stable version 2025 2026" | Nov 2025 (GA), Mär 2026 (Patch) |
| **React Native** | 0.84.x | web_search: "React Native latest stable version 2025 2026" | Feb 2026 |
| **Compose Multiplatform** | 1.10.3 | web_search: "Compose Multiplatform latest stable version 2025 2026" | Mär 2026 |
| **Kotlin** | 2.1.x | web_search: "Kotlin Multiplatform latest version 2025 2026" | 2025–2026 |
| **Avalonia UI** | 11.3.12 (stable) | web_search: "Avalonia UI latest stable version 2025 2026" | Feb 2026 |
| **Tauri** | v2.10.3 | web_search: "Tauri latest stable version 2025 2026" | Mär 2026 |

### Cloud / AI

| Technologie | Version | Verifiziert via | Status |
|-------------|---------|:---------------:|:------:|
| **Azure AI Vision** | Image Analysis 4.0 GA | web_search: "Azure AI Vision API latest version 2026" | GA (Preview-APIs retired Mär 2025) |
| **Azure Blob Storage** | Aktuell | Managed Service | GA |
| **Application Insights** | Aktuell | Nativ in .NET 10 | GA |

---

## 9. Fallback-Strategie

### Trigger für Re-Evaluierung

Nach M1 Sprint 2 (Spielmodus-Prototype) werden folgende Metriken gemessen:

| Metrik | Akzeptabel | Eskalation |
|--------|:----------:|:----------:|
| Seitenwechsel (Noten) | < 200ms | ≥ 200ms |
| Stift-Latenz (Annotation) | < 50ms | ≥ 50ms |
| Cold Start | < 4s | ≥ 4s |
| Speicherverbrauch (Spielmodus) | < 300MB | ≥ 300MB |

### Fallback-Reihenfolge

1. **Avalonia UI 12** — C#/XAML, Skia-Engine, Thomas' native Sprache. Desktop stark, Mobile wachsend.
2. **.NET MAUI 10** — C#, Visual Studio, Thomas' Expertise. Weniger Touch/Canvas-Kontrolle.
3. **React Native** — Nur als letzte Option. Erfordert JavaScript-Onboarding.

---

## 10. Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client (Dart 3.11)                     │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Spielmodus│  │  Upload  │  │  Config  │  │  Kalender │    │
│  │ (pdfrx,  │  │  Labeling│  │  3-Ebenen │  │  Termine  │    │
│  │  Canvas, │  │  AI-OCR  │  │  System   │  │  Setlists │    │
│  │  SVG)    │  │          │  │          │  │          │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │            Riverpod 3.3 (State Management)            │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │         Drift 2.32 (SQLite — Offline Cache)           │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────┐  ┌────────────────────────────────┐    │
│  │ Platform Channels │  │    BLE (Fußpedal / Tuner)      │    │
│  │ (Audio: CoreAudio/│  │    flutter_blue_plus 1.34       │    │
│  │  Oboe)            │  │                                │    │
│  └──────────────────┘  └────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
              HTTPS (REST) │ + WebSocket (SignalR) + UDP
                          │
┌─────────────────────────────────────────────────────────────┐
│              ASP.NET Core 10 Backend (C# 14)                 │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ REST API │  │ SignalR  │  │ UDP Mcast│  │ AI Adapter│    │
│  │ (JWT,    │  │ Hub      │  │ Server   │  │ (Azure,   │    │
│  │  RBAC)   │  │ (Metro-  │  │ (Metro-  │  │  OpenAI,  │    │
│  │          │  │  nom     │  │  nom LAN)│  │  Google)  │    │
│  │          │  │  Fallback│  │          │  │          │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │    Entity Framework Core + Npgsql (PostgreSQL 18)     │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │     Azure Blob Storage + CDN (Notenbilder)            │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

*Dieses Dokument wird via PR zur Abstimmung vorgelegt. Änderungen erfordern Thomas' Freigabe.*
