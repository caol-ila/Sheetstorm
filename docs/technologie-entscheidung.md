# Technologie-Entscheidung — Sheetstorm

> Version: 1.0  
> Status: Entscheidung  
> Autor: Stark (Lead / Architect)  
> Datum: 2026-03-28  
> Referenz: docs/spezifikation.md, docs/anforderungen.md, docs/konfigurationskonzept.md

---

## 1. Entscheidungsrahmen

### 1.1 Nicht-verhandelbare Anforderungen

Aus der Spezifikation ergeben sich harte Kriterien, die jeder Stack erfüllen **muss**:

| # | Anforderung | Warum kritisch |
|---|------------|----------------|
| R1 | Multi-Plattform: Web, iOS, Android, Desktop (Win/Mac) | Musiker nutzen gemischte Geräte |
| R2 | Touch-first mit Stift-Support (Apple Pencil, Surface Pen, S Pen) | Annotationen sind Kernfeature |
| R3 | Hochqualitative PDF/Bild-Darstellung mit Zoom, Rotation, Seitenwechsel <100ms | Spielmodus ist das Herzstück |
| R4 | Offline-Fähigkeit mit lokalem Storage und Sync | Probenräume haben oft kein Internet |
| R5 | Echtzeit-Fähigkeit (UDP/WebSocket für Metronom, <20ms Jitter) | Musikalische Synchronisation |
| R6 | Audio-Processing (Tuner: Mikrofon-Zugriff, FFT) | Integriertes Stimmgerät |
| R7 | Cloud-Storage-Integration (OneDrive, Dropbox OAuth2) | Persönliche Notensammlung |
| R8 | AI-API-Integration (REST zu Azure Vision et al.) | OCR/Metadaten-Erkennung |
| R9 | i18n-Architektur | Deutsch first, Erweiterung später |
| R10 | Thomas hat .NET-Hintergrund | Produktivität des Hauptentwicklers |

### 1.2 Bewertungsskala

- ⭐⭐⭐⭐⭐ = Exzellent, nativ/erstklassig unterstützt
- ⭐⭐⭐⭐ = Gut, mit geringem Aufwand machbar
- ⭐⭐⭐ = Machbar, aber Kompromisse nötig
- ⭐⭐ = Schwierig, erhebliche Workarounds
- ⭐ = Sehr problematisch, kaum empfehlenswert

---

## 2. Frontend-Stack-Evaluierung

### 2.1 Option A: .NET MAUI + Blazor Hybrid

**Konzept:** C# und .NET überall. Blazor-Komponenten für UI, MAUI für native Plattform-Integration.

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| Sheet Music Rendering | ⭐⭐⭐ | PDF via native Views, Bild via SkiaSharp. Canvas-Annotationen über Blazor möglich, aber weniger Ökosystem für SVG-Overlay als Web-Stacks. |
| Real-Time (Metronom) | ⭐⭐⭐⭐ | Nativer UDP-Zugriff über .NET Sockets. Gute Low-Level-Kontrolle. |
| Offline/Sync | ⭐⭐⭐⭐ | SQLite natürlich eingebunden, EF Core. Gute Unterstützung. |
| Touch/Stift | ⭐⭐⭐ | Touch-Support vorhanden, aber Stift-Unterstützung (insb. Apple Pencil) weniger ausgereift als native Frameworks. |
| Developer Productivity | ⭐⭐⭐⭐⭐ | Thomas' Heimat. C# everywhere, bekannte Tools (Visual Studio, Rider). |
| Community/Musik-Libraries | ⭐⭐ | Sehr kleine Community für Musik-Apps. Wenige NuGet-Pakete für Audio-Processing/Sheet Music. NAudio existiert, aber Desktop-fokussiert. |
| Mobile Performance | ⭐⭐⭐ | MAUI hat Verbesserungen gemacht, aber Startup-Zeit und UI-Rendering noch hinter Flutter/Native. |
| Desktop/Browser | ⭐⭐⭐ | Desktop gut (WinUI/Mac Catalyst). Web via Blazor WASM möglich, aber WASM-Bundle groß (~15 MB) und Performance suboptimal für bildlastige Apps. |
| Code-Sharing | ⭐⭐⭐⭐⭐ | Nahezu 100% C#-Code-Sharing möglich. |

**Stärken:** Einheitliche Sprache, Thomas' Expertise, guter nativer Zugriff.  
**Risiken:** Kleines Ökosystem für Musik-Apps, Blazor WASM im Browser hat Performance-Grenzen, MAUI-Community kleiner als React Native/Flutter.

---

### 2.2 Option B: React Native / Expo

**Konzept:** JavaScript/TypeScript, gemeinsame Codebasis für iOS, Android. Web via React Native Web oder separatem Next.js.

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| Sheet Music Rendering | ⭐⭐⭐⭐ | react-native-pdf, react-native-canvas, SVG-Libraries gut verfügbar. Web hat ohnehin DOM-Zugriff. |
| Real-Time (Metronom) | ⭐⭐⭐ | WebSocket gut, UDP braucht native Module (react-native-udp). Audio-Scheduling über Web Audio API (Web) oder native Module (Mobile). Bridge-Overhead möglich. |
| Offline/Sync | ⭐⭐⭐⭐ | AsyncStorage, WatermelonDB, SQLite-Bindings. Gutes Ökosystem. |
| Touch/Stift | ⭐⭐⭐⭐ | react-native-gesture-handler ist exzellent. Stift via PanResponder/GestureHandler gut. |
| Developer Productivity | ⭐⭐⭐ | Thomas müsste JS/TS lernen. Hot Reload ist produktiv, aber Lernkurve für .NET-Entwickler. |
| Community/Musik-Libraries | ⭐⭐⭐⭐ | Großes npm-Ökosystem, Web Audio API, tone.js, pitchy (Tuner). Viele Beispiele. |
| Mobile Performance | ⭐⭐⭐⭐ | New Architecture (TurboModules, Fabric) deutlich verbessert. JSI reduziert Bridge-Overhead. |
| Desktop/Browser | ⭐⭐⭐ | React Native Web ist limitiert. Separates Web-Projekt oder Electron nötig → Code-Split. |
| Code-Sharing | ⭐⭐⭐ | ~70–80% Sharing zwischen iOS/Android. Web braucht separate Arbeit. Desktop-Story unklar. |

**Stärken:** Riesiges Ökosystem, gute Musik-Libraries, schnelle Iteration.  
**Risiken:** Kein echtes Desktop/Browser-Story ohne zweites Framework. Thomas' Lernkurve. Bridge-Overhead bei Audio.

---

### 2.3 Option C: Flutter

**Konzept:** Dart, ein Framework für Mobile, Web und Desktop. Eigene Rendering-Engine (Skia/Impeller).

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| Sheet Music Rendering | ⭐⭐⭐⭐⭐ | CustomPaint (Skia/Impeller) für Annotationen, pdf_render für PDFs, canvas-basiert → volle Kontrolle über Rendering. Flutter's eigene Engine rendert pixel-perfekt auf allen Plattformen. |
| Real-Time (Metronom) | ⭐⭐⭐⭐ | UDP über dart:io (Mobile/Desktop). Platform Channels für native Audio. Dart-Isolates für Background-Processing. |
| Offline/Sync | ⭐⭐⭐⭐⭐ | Drift (SQLite), Hive, Isar — hervorragende lokale Datenbank-Libraries. Offline-first ist ein starkes Flutter-Pattern. |
| Touch/Stift | ⭐⭐⭐⭐⭐ | Flutter hat erstklassige Gesture-Erkennung, Stylus-Support, Pressure-Sensitivity. CustomPainter für Freihand-Zeichnung. |
| Developer Productivity | ⭐⭐⭐⭐ | Dart ist C#-ähnlich (stark typisiert, OOP, async/await, null-safety). Thomas wird sich schnell einarbeiten. Hot Reload ist extrem produktiv. |
| Community/Musik-Libraries | ⭐⭐⭐ | Kleinere Community als JS, aber wachsend. flutter_audio, pitch_detector verfügbar. FFT-Libraries existieren. Weniger Auswahl als npm, aber ausreichend. |
| Mobile Performance | ⭐⭐⭐⭐⭐ | Ahead-of-Time-kompiliert, eigene Rendering-Engine, kein Bridge-Overhead. Impeller (neue Engine) liefert 120fps. |
| Desktop/Browser | ⭐⭐⭐⭐ | Desktop-Support (Windows, macOS, Linux) ist stable. Web-Support funktioniert, Rendering via CanvasKit (Skia-in-WASM) — gut für unseren Use Case (Canvas-basiert). Bundle-Größe ~2–3 MB. |
| Code-Sharing | ⭐⭐⭐⭐⭐ | ~95–98% Code-Sharing zwischen allen Plattformen. Ein Codebase, ein Build-System. |

**Stärken:** Beste plattformübergreifende UI-Konsistenz, eigene Rendering-Engine (perfekt für Noten-Darstellung), Dart nahe an C#, exzellente Touch/Stift-Unterstützung.  
**Risiken:** Dart ist eine neue Sprache (aber ähnlich zu C#). Musik-Library-Ökosystem kleiner als JS. Google-Abhängigkeit.

---

### 2.4 Option D: Next.js (Web) + Capacitor/Tauri (Native)

**Konzept:** Web-first mit Next.js/React. Mobile via Capacitor (WebView-Wrapper), Desktop via Tauri (Rust + WebView).

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| Sheet Music Rendering | ⭐⭐⭐⭐ | PDF.js, Canvas API, SVG nativ im Browser. Web-Technologie ist stark für Dokument-Rendering. |
| Real-Time (Metronom) | ⭐⭐ | WebSocket ja, aber UDP nur über Capacitor-Plugin (begrenzt). Web Audio API für Timing, aber Jitter-Probleme im Browser (~20–50ms). |
| Offline/Sync | ⭐⭐⭐ | Service Workers, IndexedDB. Funktioniert, aber PWA-Offline ist weniger robust als native Lösungen. Capacitor hilft. |
| Touch/Stift | ⭐⭐⭐ | Pointer Events API, aber WebView-Layer kann Touch-Latenz hinzufügen. Stift-Pressure via PointerEvent.pressure. |
| Developer Productivity | ⭐⭐⭐ | Neues Ökosystem für Thomas. React/TS-Lernkurve. Aber Web-Dev-Tooling ist exzellent. |
| Community/Musik-Libraries | ⭐⭐⭐⭐⭐ | Web hat das größte Ökosystem: tone.js, pitchfinder, PDF.js, Fabric.js (Canvas). |
| Mobile Performance | ⭐⭐ | WebView-basiert (Capacitor) = Browser in App. Merkbarer Performance-Unterschied zu nativen Apps. Seitenwechsel <100ms wird schwierig. |
| Desktop/Browser | ⭐⭐⭐⭐⭐ | Browser ist die Heimat. Tauri für Desktop ist schnell und schlank. |
| Code-Sharing | ⭐⭐⭐⭐ | 100% Code-Sharing da alles Web. Aber: WebView-Performance-Kompromisse auf Mobile. |

**Stärken:** Maximales Code-Sharing, riesiges Web-Ökosystem, Browser-Support natürlich exzellent.  
**Risiken:** Mobile Performance leidet unter WebView. Metronom-Latenz via WebView kritisch. Touch-Latenz ein Thema. Kein nativer UDP.

---

### 2.5 Option E: Electron + React (Desktop) + React Native (Mobile)

**Konzept:** Zwei Projekte: React Native für Mobile, Electron + React für Desktop/Web.

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| Sheet Music Rendering | ⭐⭐⭐⭐ | Gute Libraries für beide Welten (react-native-pdf, PDF.js). |
| Real-Time (Metronom) | ⭐⭐⭐ | Electron hat Node.js-Zugriff (UDP direkt). Mobile braucht Native Modules. |
| Offline/Sync | ⭐⭐⭐⭐ | Gute Libraries auf beiden Seiten. |
| Touch/Stift | ⭐⭐⭐ | Mobile gut, Desktop/Electron mittelmäßig (DOM-basiert). |
| Developer Productivity | ⭐⭐ | Zwei Projekte pflegen = doppelter Aufwand. Thomas müsste JS/TS lernen. |
| Community/Musik-Libraries | ⭐⭐⭐⭐ | Großes npm-Ökosystem für beide. |
| Mobile Performance | ⭐⭐⭐⭐ | React Native nativ, gut. |
| Desktop/Browser | ⭐⭐⭐⭐ | Electron funktioniert, aber RAM-Hunger (~200–400 MB). |
| Code-Sharing | ⭐⭐ | ~50–60% Sharing. Business-Logik teilbar, UI muss doppelt gebaut werden. |

**Stärken:** Jede Plattform bekommt ein passendes Tool.  
**Risiken:** Zwei Projekte = doppelter Maintenance-Aufwand. Für ein kleines Team (Thomas + AI-Agents) nicht tragbar.

---

### 2.6 Frontend-Vergleichsmatrix

| Kriterium (Gewicht) | MAUI+Blazor | React Native | **Flutter** | Next.js+Cap. | Electron+RN |
|---------------------|:-----------:|:------------:|:-----------:|:------------:|:-----------:|
| Sheet Music (20%) | ⭐⭐⭐ | ⭐⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Real-Time (15%) | ⭐⭐⭐⭐ | ⭐⭐⭐ | **⭐⭐⭐⭐** | ⭐⭐ | ⭐⭐⭐ |
| Offline/Sync (10%) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Touch/Stift (15%) | ⭐⭐⭐ | ⭐⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐⭐ | ⭐⭐⭐ |
| Dev Productivity (15%) | **⭐⭐⭐⭐⭐** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Community/Musik (10%) | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐⭐⭐ |
| Mobile Perf. (5%) | ⭐⭐⭐ | ⭐⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐ | ⭐⭐⭐⭐ |
| Desktop/Browser (5%) | ⭐⭐⭐ | ⭐⭐⭐ | **⭐⭐⭐⭐** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Code-Sharing (5%) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | **⭐⭐⭐⭐⭐** | ⭐⭐⭐⭐ | ⭐⭐ |
| **Gewichteter Score** | **3.45** | **3.50** | **4.40** | **3.20** | **3.15** |

---

## 3. Backend-Evaluierung

### 3.1 Option A: ASP.NET Core

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| API-Performance | ⭐⭐⭐⭐⭐ | Einer der schnellsten Web-Frameworks (TechEmpower Benchmarks). |
| Auth (JWT, OAuth2) | ⭐⭐⭐⭐⭐ | ASP.NET Identity, eingebauter JWT-Support, OAuth2-Middleware. |
| Real-Time | ⭐⭐⭐⭐⭐ | SignalR (WebSocket + Fallbacks), raw UDP via .NET Sockets. |
| File Storage | ⭐⭐⭐⭐ | Azure Blob Storage SDK, S3-kompatibel, Streaming-Upload. |
| Database | ⭐⭐⭐⭐⭐ | EF Core (PostgreSQL, SQLite), Dapper für Performance-kritisches. |
| Thomas' Expertise | ⭐⭐⭐⭐⭐ | Heimvorteil. Bekannte Patterns, bekannte Tools. |
| Hosting | ⭐⭐⭐⭐ | Azure, AWS, Docker. Etwas höherer Ops-Aufwand als BaaS. |
| Echtzeit-Metronom-Server | ⭐⭐⭐⭐⭐ | Kestrel + UDP-Socket-Server in einem Prozess. Volle Kontrolle. |

### 3.2 Option B: Node.js / Bun

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| API-Performance | ⭐⭐⭐⭐ | Gut, aber single-threaded. Bun verbessert Performance signifikant. |
| Auth | ⭐⭐⭐⭐ | Passport.js, jose (JWT). Gutes Ökosystem. |
| Real-Time | ⭐⭐⭐⭐ | Socket.io, ws, dgram (UDP). |
| File Storage | ⭐⭐⭐⭐ | AWS SDK, Azure SDK, multer für Upload. |
| Database | ⭐⭐⭐⭐ | Prisma, Drizzle, TypeORM. |
| Thomas' Expertise | ⭐⭐ | Neue Sprache, neues Ökosystem. |
| Hosting | ⭐⭐⭐⭐⭐ | Überall deploybar, Vercel/Railway/Fly.io. |
| Echtzeit-Metronom-Server | ⭐⭐⭐ | UDP möglich, aber single-threaded = Risiko bei vielen gleichzeitigen Sessions. |

### 3.3 Option C: Supabase / Firebase (BaaS)

| Kriterium | Bewertung | Begründung |
|-----------|:---------:|-----------|
| API-Performance | ⭐⭐⭐⭐ | Managed, autoskalierend. |
| Auth | ⭐⭐⭐⭐⭐ | Out-of-the-box Auth mit Social Login, JWT, Row-Level-Security. |
| Real-Time | ⭐⭐⭐ | Supabase Realtime (PostgreSQL Changes). Aber: Kein UDP, kein Custom-Protokoll für Metronom. |
| File Storage | ⭐⭐⭐⭐⭐ | Eingebauter File Storage mit Policies. |
| Database | ⭐⭐⭐⭐⭐ | Supabase = PostgreSQL. Firebase = Firestore (Document DB). |
| Thomas' Expertise | ⭐⭐⭐ | Supabase hat gute Docs, aber anderes Paradigma (Row-Level-Security statt API-Controller). |
| Hosting | ⭐⭐⭐⭐⭐ | Fully managed, kein Ops-Aufwand. |
| Echtzeit-Metronom-Server | ⭐ | **Dealbreaker.** BaaS bietet keine Custom-UDP-Server. Metronom braucht separaten Server → Hybrid-Architektur nötig. |

### 3.4 Backend-Entscheidung

**BaaS alleine reicht nicht.** Der Echtzeit-Metronom-Server braucht UDP-Kontrolle und Custom-Timing-Logik. Das geht mit keinem BaaS. Wir brauchen einen Custom-Server — mindestens für den Metronom-Dienst.

**ASP.NET Core ist die klare Wahl:**
- Thomas' Expertise ist hier. Keine Lernkurve.
- Performance-Leader unter den Web-Frameworks.
- UDP-Server nativ möglich (kein separater Service nötig).
- SignalR liefert WebSocket-Fallback für den Metronom.
- EF Core für PostgreSQL ist ausgereift.

**Hybride Nutzung von Supabase:** Supabase Auth und Storage **können** als zusätzliche Services genutzt werden, wenn Thomas den Ops-Aufwand reduzieren will. Aber der Kern-API-Server bleibt ASP.NET Core.

---

## 4. Datenbank-Entscheidung

### 4.1 Anforderungen

- **Server:** Relationale Daten (Musiker, Kapellen, Stücke, Rollen) + JSONB für Konfigurationen
- **Client:** Offline-Cache für Noten, Annotationen, Konfigurationen
- **Sync:** Bidirektionale Synchronisation für Annotationen und Konfigurationen

### 4.2 Entscheidung: PostgreSQL (Server) + SQLite (Client)

| Komponente | Technologie | Begründung |
|-----------|------------|-----------|
| **Server-DB** | PostgreSQL | JSONB für flexible Config-Speicherung (siehe Konfigurationskonzept). Volle relationale Power für Berechtigungen und Mitgliedschaften. EF Core hat erstklassigen PostgreSQL-Support. |
| **Client-DB** | SQLite (Drift/sqflite) | Leichtgewichtig, in jeder Plattform eingebaut. Perfekt für Offline-Cache. Drift (Flutter) bietet typsichere Queries. |
| **File Storage** | Azure Blob Storage / S3 | Notenblatt-Bilder und PDFs. CDN für schnelle Auslieferung. |
| **Cache** | Redis (optional) | Session-Cache, Rate-Limiting. Nur wenn Performance-Bedarf entsteht. |

**Warum nicht Document DB?**
MongoDB/Firestore wären für Sheet-Music-Metadaten denkbar, aber:
- Unser Datenmodell ist stark relational (Musiker ↔ Kapelle ↔ Stücke ↔ Stimmen).
- JSONB in PostgreSQL gibt uns die Flexibilität einer Document DB für Config, **ohne** auf JOIN-Power zu verzichten.
- Ein Datenbanksystem weniger = weniger Ops.

---

## 5. Echtzeit-Metronom — Technologie-Entscheidung

### 5.1 Anforderungen

- Synchronisation auf <20ms Abweichung zwischen Geräten
- 5–30+ Geräte gleichzeitig im lokalen Netzwerk
- Dirigent als Controller (Start/Stop/Tempo-Änderung)
- Offline-Standalone-Modus (lokales Metronom)

### 5.2 Evaluierung

| Technologie | Latenz | Plattform-Support | Implementierung | Eignung |
|------------|--------|-------------------|-----------------|---------|
| **WiFi UDP Multicast** | ⭐⭐⭐⭐⭐ (<5ms LAN) | Mobil + Desktop | Custom-Server, dart:io auf Client | **Primär für lokales Netz** |
| **WebSocket** | ⭐⭐⭐ (20–80ms) | Alle Plattformen | ASP.NET Core SignalR | **Fallback für Remote** |
| **WebRTC Data Channels** | ⭐⭐⭐⭐ (5–20ms) | Web, Mobile (mit Plugin) | Komplex, P2P-Setup, STUN/TURN | Overkill für diesen Use Case |
| **Bluetooth Low Energy** | ⭐⭐ (50–200ms) | Mobil | Platform-spezifisch, Pairing nötig | Zu hohe Latenz, zu komplex |
| **WiFi Direct** | ⭐⭐⭐ (10–30ms) | Android (gut), iOS (schlecht) | Platform-spezifisch | iOS-Support zu schwach |

### 5.3 Entscheidung: WiFi UDP (Primär) + WebSocket (Fallback)

```
┌───────────────────────────────────────────────────┐
│                  Metronom-Architektur               │
│                                                     │
│  ┌─────────────────┐                               │
│  │  Dirigent-App    │                               │
│  │  (Controller)    │                               │
│  └────────┬─────────┘                               │
│           │                                         │
│           ▼                                         │
│  ┌─────────────────┐     NTP-like Clock Sync       │
│  │  ASP.NET Core    │◄────────────────────────────  │
│  │  Metronom-Server │                               │
│  │                  │                               │
│  │  ┌──────────┐   │     UDP Multicast (LAN)       │
│  │  │ UDP      │───│──────────────────────────────▶ │
│  │  │ Sender   │   │                               │
│  │  └──────────┘   │                               │
│  │  ┌──────────┐   │     WebSocket (Remote)        │
│  │  │ SignalR   │───│──────────────────────────────▶ │
│  │  │ Hub      │   │                               │
│  │  └──────────┘   │                               │
│  └─────────────────┘                               │
│                                                     │
│  Client-Seite:                                     │
│  1. Clock-Sync beim Session-Start (RTT messen)     │
│  2. Beats als Master-Clock-Timestamps empfangen    │
│  3. Lokale Audio-Engine plant Beats voraus          │
│  4. Visuelles + akustisches + haptisches Feedback  │
└───────────────────────────────────────────────────┘
```

**Warum nicht WebRTC?** WebRTC löst das Problem "P2P-Kommunikation über NAT" — aber im Probenraum sind alle im selben WiFi. UDP Multicast ist simpler, schneller und braucht keinen STUN/TURN-Server. Für Remote-Sessions reicht WebSocket.

---

## 6. Gesamtarchitektur — ENTSCHEIDUNG

### 6.1 Empfohlener Tech-Stack

```
┌─────────────────────────────────────────────────────────────┐
│                        SHEETSTORM                            │
│                                                              │
│  FRONTEND                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Flutter (Dart)                                         │ │
│  │  → iOS, Android, Web, Windows, macOS                    │ │
│  │  → Ein Codebase, ~95% Code-Sharing                      │ │
│  │  → CustomPainter für Annotations-Layer                  │ │
│  │  → pdf_render für Notenblatt-Darstellung                │ │
│  │  → Drift (SQLite) für Offline-Storage                   │ │
│  │  → flutter_riverpod für State Management                │ │
│  │  → go_router für Navigation                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  BACKEND                                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ASP.NET Core 9 (C#)                                    │ │
│  │  → REST API mit JWT-Auth                                │ │
│  │  → SignalR für WebSocket-Echtzeit                       │ │
│  │  → UDP-Server für Metronom (lokales Netz)               │ │
│  │  → EF Core + PostgreSQL                                 │ │
│  │  → Azure Blob Storage für Notenblatt-Dateien            │ │
│  │  → AI-Service-Adapter (Azure Vision, OpenAI, etc.)      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  DATENBANK                                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Server: PostgreSQL 16 (JSONB für Config)               │ │
│  │  Client: SQLite via Drift (Offline-Cache)               │ │
│  │  Files:  Azure Blob Storage + CDN                       │ │
│  │  Cache:  Redis (optional, ab Skalierungsbedarf)         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ECHTZEIT                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Metronom:  WiFi UDP Multicast (primär)                 │ │
│  │             SignalR WebSocket (Fallback/Remote)          │ │
│  │  Clock-Sync: NTP-ähnliches Protokoll                    │ │
│  │  Notifications: Firebase Cloud Messaging (FCM)          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  INFRASTRUKTUR                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Hosting:  Azure App Service / Azure Container Apps     │ │
│  │  CI/CD:    GitHub Actions                               │ │
│  │  Storage:  Azure Blob Storage                           │ │
│  │  CDN:      Azure CDN / Cloudflare                       │ │
│  │  Monitoring: Application Insights                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Begründung der Entscheidung

**Frontend: Flutter statt .NET MAUI**

Das ist die schwerste Entscheidung. MAUI wäre Thomas' Komfortzone — aber die technischen Anforderungen sprechen klar für Flutter:

1. **Sheet Music Rendering:** Flutter's CustomPainter + Skia/Impeller gibt uns volle Canvas-Kontrolle für den SVG-Annotations-Layer. MAUI hat hier weniger Ökosystem.
2. **Touch/Stift:** Flutter hat die beste Touch-Gesture-Erkennung aller Cross-Platform-Frameworks. Für eine Touch-first App mit Stift-Annotationen ist das entscheidend.
3. **Plattform-Abdeckung:** Ein Codebase für iOS, Android, Web, Windows, macOS. MAUI kann Web nur über Blazor WASM (15+ MB Bundle, Performance-Sorgen).
4. **Dart ≈ C#:** Dart ist stark typisiert, hat async/await, null-safety, OOP — Thomas wird sich in 1–2 Wochen produktiv fühlen. Die Syntax-Unterschiede sind kosmetisch.
5. **Performance:** Ahead-of-Time-kompiliert, eigene Engine, kein Bridge. Seitenwechsel <100ms ist garantierbar.

**Kompromiss:** Thomas verliert seine C#-Heimat im Frontend. Aber er behält sie im Backend (ASP.NET Core). Das ist der richtige Trade-off: Das Frontend braucht die beste UI-Engine, das Backend braucht Thomas' Expertise.

**Backend: ASP.NET Core**

Keine Diskussion nötig. Thomas' Expertise + Performance-Leader + UDP-Kontrolle für Metronom + EF Core für PostgreSQL. Perfekte Wahl.

**Warum nicht Full-Flutter + Firebase/Supabase?**
Der Metronom-Server braucht Custom-UDP-Logik. BaaS kann das nicht. Ein Custom-Backend ist unvermeidlich — und wenn wir schon eins brauchen, dann richtig: ASP.NET Core gibt uns volle Kontrolle über API, Auth, Real-Time und File-Handling.

### 6.3 Lernkurve für Thomas

| Technologie | Einarbeitungszeit | Strategie |
|------------|-------------------|-----------|
| **Dart/Flutter** | 1–2 Wochen Grundlagen, 4 Wochen produktiv | C#-zu-Dart-Guide erstellen, Flutter-Codelabs durcharbeiten |
| **ASP.NET Core** | Sofort produktiv | Heimvorteil |
| **PostgreSQL** | Minimal (wenn SQL-Erfahrung vorhanden) | EF Core abstrahiert vieles |
| **Drift (SQLite für Flutter)** | 1 Woche | Ähnlich zu EF Core, Code-Generator-basiert |

### 6.4 Projekt-Struktur

```
sheetstorm/
├── app/                          ← Flutter-Frontend (alle Plattformen)
│   ├── lib/
│   │   ├── core/                 Business-Logik, Models, Services
│   │   ├── features/             Feature-Module (Noten, Kapelle, Tools, ...)
│   │   ├── ui/                   Shared UI-Komponenten
│   │   ├── config/               Config-Resolution (3-Ebenen-Modell)
│   │   └── l10n/                 i18n-Ressourcen
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── windows/
│   └── macos/
│
├── server/                       ← ASP.NET Core Backend
│   ├── Sheetstorm.Api/           REST API + SignalR
│   ├── Sheetstorm.Core/          Domain-Models, Interfaces
│   ├── Sheetstorm.Data/          EF Core, Repositories
│   ├── Sheetstorm.AI/            AI-Provider-Adapter
│   ├── Sheetstorm.Metronome/     UDP + Clock-Sync-Service
│   └── Sheetstorm.Tests/         Unit + Integration Tests
│
├── docs/                         ← Dokumentation
├── infrastructure/               ← IaC (Terraform/Bicep)
└── .github/workflows/            ← CI/CD
```

---

## 7. Risiken & Mitigationen

| Risiko | Auswirkung | Mitigation |
|--------|-----------|------------|
| Dart-Lernkurve für Thomas | Langsamerer Start | C#↔Dart-Comparison-Guide erstellen. Dart ist die ähnlichste Sprache zu C#. |
| Flutter Web-Performance für große PDFs | Spielmodus könnte ruckeln | CanvasKit-Renderer nutzen, Lazy Loading, Tile-basiertes Rendering. |
| Weniger Musik-Libraries in Dart | Mehr eigene Arbeit für Tuner/Audio | FFT via Platform Channels an native Libraries (Core Audio/AAudio) delegieren. |
| Zwei Sprachen (Dart + C#) | Kontext-Wechsel | Klare Trennung: Dart = UI/Client, C# = Server/API. Kein Mischmasch. |
| Flutter Web Bundle-Größe (~2–3 MB) | Langsamer Erstaufruf | CDN, Caching, Code-Splitting wo möglich. Für eine App akzeptabel. |

---

## 8. Alternativen und wann wir umschwenken

Wenn Flutter sich **innerhalb von M1** als ungeeignet herausstellt (z.B. PDF-Rendering-Probleme, Touch-Latenz, Stift-Support), ist der Fallback-Plan:

1. **Fallback A: React Native + Expo** — Größeres Ökosystem, aber Web/Desktop-Story schwächer
2. **Fallback B: .NET MAUI** — Thomas' Komfort, aber Kompromisse bei UI-Rendering und Web

**Trigger für Umschwenken:**
- Seitenwechsel >200ms auf Zielgeräten
- Stift-Latenz >50ms (nicht akzeptabel für Annotationen)
- PDF-Rendering-Qualität unter forScore/MobileSheets-Niveau
- Flutter Web nicht nutzbar für den Spielmodus

Entscheidungspunkt: **Ende M1 Sprint 2** (nach Prototype des Spielmodus).

---

## 9. Zusammenfassung der Entscheidungen

| Bereich | Entscheidung | Begründung (ein Satz) |
|---------|-------------|----------------------|
| **Frontend** | Flutter (Dart) | Beste Cross-Platform-Engine für touch-first, canvas-intensive Apps mit einer Codebasis. |
| **Backend** | ASP.NET Core 9 (C#) | Thomas' Expertise + Performance + UDP-Kontrolle für Metronom. |
| **Server-DB** | PostgreSQL 16 | JSONB für Config, relationale Power für Berechtigungen, EF Core. |
| **Client-DB** | SQLite via Drift | Leichtgewichtiger Offline-Cache mit typsicheren Queries. |
| **File Storage** | Azure Blob Storage | Notenblatt-Bilder/PDFs, CDN-fähig, Azure-Ökosystem. |
| **Echtzeit** | WiFi UDP + SignalR | UDP für <5ms LAN-Latenz, SignalR als Remote-Fallback. |
| **Auth** | JWT + ASP.NET Identity | Bewährt, sicher, bekannt. |
| **CI/CD** | GitHub Actions | Standard, gute Flutter- und .NET-Integration. |
| **Hosting** | Azure | Konsistentes Ökosystem (App Service, Blob, CDN, AI). |
| **Monitoring** | Application Insights | Azure-nativ, gute .NET-Integration. |

---

*Diese Technologie-Entscheidung ist verbindlich für Meilenstein 1. Anpassungen werden nach dem Spielmodus-Prototype (M1 Sprint 2) evaluiert.*
