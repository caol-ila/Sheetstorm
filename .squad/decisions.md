# Squad Decisions

## Active Decisions

### 2026-03-28T10:31Z: Code Review Policy
**By:** Thomas (via Copilot)  
**Decision:** Alle Codeänderungen müssen von 3 verschiedenen Reviewern überprüft werden, die unterschiedliche AI-Modelle verwenden: Claude Sonnet 4.6, Claude Opus 4.6, und GPT 5.4. Der Lead (Stark) überprüft die Reviews und entscheidet, welche Änderungsvorschläge umgesetzt werden, welche später kommen, und welche verworfen werden.

### 2026-03-28T10:31Z: Sprache & Internationalisierung
**Decision:** Start mit Deutsch. Mehrsprachigkeit ist möglich, aber nicht Priorität. German-first, i18n-Architektur für später.

### 2026-03-28T10:31Z: Meilenstein-Strategie
**Decision:** Jeder Meilenstein muss ein vollständiges Delivery mit End-Nutzer-Mehrwert sein. Priorität: (1) Import & Spielmodus + Kapellenverwaltung, (2) Vereinsleben-Features, (3) Erweiterungen & Optimierungen. Alles muss getestet, UX-Flows validiert und die App deploybar sein bei jedem Meilenstein.

### 2026-03-28T10:31Z: Plattform & Touch
**Decision:** Die App soll im Browser, als mobile App (Handy/Tablet) und als Desktop-Anwendung laufen. Touch-Unterstützung ist Pflicht. Fokus auf ablenkungsfreies Spielen.

### 2026-03-28T10:42Z: App-Name
**Decision:** Der Name der Anwendung ist **Sheetstorm**.

### 2026-03-28T10:44Z: GitHub Workflow
**Decision:** Aufgaben als GitHub Issues tracken. Alle Änderungen als Pull Requests. Code-Review-Ergebnisse als Kommentare im PR posten.

### 2026-03-28T11:00Z: UX Review Pflicht
**Decision:** Alle Frontend-Änderungen bzw. Dinge mit denen ein Nutzer interagiert sollen einen UX-Review haben, der verifiziert dass alles funktioniert wie erwartet und sich perfekt bedienen lässt.

### 2026-03-28T11:00Z: Konfigurationskonzept im Meilenstein 1
**Decision:** Das Konfigurationskonzept (User/Gerät/Kapelle-Ebenen) soll Teil des ersten Meilensteins sein und eine sehr gute UX haben.

### 2026-03-28T11:19Z: Externe Abhängigkeiten — immer Web-Suche
**Decision:** Bei allen externen Dependencies (Bibliotheken, Frameworks, Tools) IMMER eine aktuelle Web-Suche nach der neuesten stabilen Version durchführen. Nie auf vorhandenes Wissen verlassen. Es wird immer mit den neuesten stable Versionen gebaut.

### 2026-03-28T11:22Z: Entscheidungen via PR
**Decision:** Entscheidungen die Thomas treffen soll, werden als Dokumente in einem PR bereitgestellt — nicht inline im Chat. Thomas reviews und entscheidet im PR.

### 2026-03-28T11:26Z: Immer neueste Modellversionen
**Decision:** Immer die neueste verfügbare Version jedes AI-Modells verwenden. Keine veralteten Versionen.

---

### Spezifikation & Meilensteinplanung
**By:** Stark (Lead / Architect)  
**Date:** 2026-03-28

#### Datenmodell
Persönliche Sammlung = Stück mit Musiker-ID statt Kapelle-ID (gleiche Mechanismen, kein separates System)

#### Annotationen
SVG-Layer mit relativen Positionen, 3 Sichtbarkeitsebenen: Privat (Grün) / Stimme (Blau) / Orchester (Orange)

#### AI-Architektur
Adapter-Pattern, Fallback-Kette User→Kapelle→keine AI

#### Metronom-Sync
WiFi UDP primär, WebSocket Fallback, Timestamps statt Live-Kommandos

#### Meilenstein-Abhängigkeiten
M4 (Lehre) kann parallel zu M2/M3 starten — nur Kern-Abhängigkeit

---

### Technologie-Stack (v2)
**Frontend:** Flutter 3.35.4 (Dart) — eigene Rendering-Engine, beste Canvas/Touch/Stift für Cross-Platform, 95%+ Code-Sharing  
**Backend:** ASP.NET Core 10 (.NET 10 LTS) — Performance-Leader, nativer UDP für Metronom  
**Server-DB:** PostgreSQL 18.3 — JSONB für Config, relationale Power für Permissions  
**Client-DB:** SQLite 3.51.3 via Drift 2.32.1 — Offline-Cache  
**Realtime:** UDP Multicast (LAN, <5ms) + SignalR WebSocket (Fallback)  
**Hosting:** Azure Ökosystem (App Service, Blob, CDN, AppInsights)  
**State:** Riverpod 3.0 (Offline-Persistence, Auto-Retry)  
**PDF:** pdfrx (all platforms)  
**Monitoring:** AppInsights + OpenTelemetry

**Fallback:** Flutter-Eignung evaluiert nach MS1 Sprint 2. Umschwenken auf Avalonia 12 (C#/XAML, Skia-Engine) falls Performance-Ziele nicht erreicht.

---

### Marktpositionierung & Preismodell
**Positioning:** Einzige All-in-One-Lösung mit professioneller Notenanzeige + Vereinsverwaltung + AI-Upload + Blasmusik-spezifisches Stimmen-Mapping

**Pricing (transparent, öffentlich):**
- Free: Bis 15 Mitglieder, 1 Kapelle
- Starter: ~39€/Jahr/Kapelle (bis 40 Mitglieder)
- Pro: ~99€/Jahr/Kapelle (unbegrenzt, AI inklusive)
- Pro+AI: ~149€/Jahr/Kapelle (zentraler AI-Key)

**Evidenz:** Konzertmeister (33-99€/Jahr) akzeptiert, Intransparenz erzeugt Misstrauen, BAND App zeigt virales Potenzial von Aushilfen-Links.

---

### Feature-Priorisierung

#### P0 (MVP, unverhandelbar)
1. Professioneller PDF-Viewer mit Performance-Modus + Half-Page-Turn
2. Stimmen-Mapping mit Fallback-Logik
3. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester)
4. 1-Klick Zu-/Absage System
5. Offline-Unterstützung für heruntergeladene Noten
6. Cross-Platform: Web + iOS + Android

#### P1 (Kurz nach Launch)
7. Bluetooth-Pedal-Support
8. Ensemble-Setlist-Sharing
9. AI-Upload mit Labeling-Flow
10. Aushilfen-Link ohne Registrierung
11. Dirigenten-Masterfunktion

#### P2 (Spätere Releases)
12. BYOK AI-Keys
13. Echtzeit-Metronom-Sync
14. IMSLP-Integration
15. Lehre-Modul

---

### UX-Kernpatterns (aus Konkurrenzanalyse)

#### MUST HAVE
- **Performance-Modus:** Vollbild, alle UI versteckt (forScore, MobileSheets Standard)
- **Half-Page-Turn:** Verhindert „Page-Jump-Schock" — day-1-Feature (forScore, Newzik)
- **3-Ebenen-Annotationen:** Privat/Stimme/Orchester (differenzierer vs. Konkurrenz)
- **Stylus-First:** Stift berührt = annotieren, kein Menü-Umweg (forScore Standard)
- **1-Klick Stimmenneuverteilung:** Fallback-Logik automatische Ersatzmusiker-Vorschlag (Notabl Pattern)
- **Asymmetrische Tap-Zonen:** 40% zurück / 60% weiter (ergonomisch)
- **Kontextmenü 5 Optionen Max:** Nachtmodus, Half-Page-Turn, Schriftgröße, Annotations-Layer, Helligkeit
- **Auto-Save ohne Speichern-Button:** Undo-Toast 5 Sekunden
- **Keine Einstellung erfordert Neustart**
- **Onboarding 5 Fragen Max:** Alle überspringbar

#### SHOULD HAVE
- **Web = Admin, App = Performance:** Notenwart verwaltet am PC, Musiker spielt am Tablet (Newzik Pattern)
- **Aushilfen-Link ohne Registrierung:** Temporärer Token, nur zugewiesene Stimme (Musicorum Pattern)
- **Split-View Tablet/Desktop:** Navigation links, Inhalt rechts
- **Bottom-Navigation 4 Tabs:** Bibliothek, Setlists, Kalender, Profil
- **Deep-Link-Schema:** sheetstorm://bibliothek/[id], sheetstorm://aushilfe/[token]

---

### Konfigurationssystem (3-Ebenen)

**Ebenen:** Kapelle (Blau) → Nutzer (Grün) → Gerät (Orange)  
**Override:** Gerät > Nutzer > Kapelle > Default (mit Policy-Blockierung)

**MUST HAVEs:**
- Auto-Save mit Undo-Toast
- Farbkodierung (Blau/Grün/Orange) mit Icon + Pattern (barrierefreiheit)
- Kontextuelle Einstellungen im Spielmodus (5 max)
- Geräte-Einstellungen werden NICHT synchronisiert
- Intelligente Defaults pro Gerätetyp
- Onboarding max 5 Fragen
- Transparente Vererbungshierarchie („Standard von Kapelle")
- Erzwungene Einstellungen mit Schloss-Icon

---

### Marktforschung Key Insights

**17+ Wettbewerber analysiert:**  
Marschpat, Notabl, Newzik, forScore, MobileSheets, Konzertmeister, BAND, Glissandoo, Musicorum + weitere

**Zentrale Marktlücken:**
1. Keine Kombination aus professioneller Notenanzeige + Vereinsverwaltung + AI-Upload
2. Intelligentes Stimmen-Mapping mit Fallback-Logik existiert nirgendwo
3. AI-gestützter Multi-Lied-Upload mit Labeling ist ein Novum
4. Multi-Kapellen-Zugehörigkeit wird von keinem Wettbewerber unterstützt
5. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester) als Kernkonzept fehlt überall
6. Echtzeit-Metronom-Sync im Notenkontext nicht integriert
7. Lehre-Modul im Vereinskontext nicht existent

**Anti-Patterns zu vermeiden:**
- Zu viele Display-Modi ohne gute Defaults (MobileSheets)
- Notenverwaltung als Datei-Ablage ohne Struktur (Konzertmeister)
- Preis nur „auf Anfrage" → Misstrauen (Newzik Ensemble, notabl)
- App-Absturz-Risiko bei Live → Performance-Tests + Offline-Fallback Pflicht

**Architektur-Evidenz:** Offline-First (Outdoor, schlechtes WLAN), Web+App-Split (Newzik erfolgreich), Cross-Platform (Konzertmeister im DACH erfolgreich)

---

### SheetHappens-Vergleich (aus Feature-Gap-Analyse)

**Baseline:** 57 SheetHappens-Features analysiert  
- ✅ 16 in Sheetstorm-Spec
- ⚠️ 11 teilweise
- ❌ 25 fehlend
- 🆕 5 Sheetstorm-exklusiv

**Wichtigste Erkenntnisse:**
- GEMA-Reporting: Gesetzliche Pflicht, SheetHappens hat komplettes Datenmodell
- Conductor Mode (Song-Broadcast): Killer-Feature für Proben
- Offline-Architektur: Nur Anforderung, nicht architektonisch spezifiziert
- Server-WebP-Konvertierung: Vereinfacht Cross-Platform

**Sheetstorm-Vorteile:** Auto-Rotation, Auto-Zoom, Schichtplanung, Kalenderansicht, Cloud-Storage-Sync

---

### Top 10 Recommendations (aktueller Stand)

1. **GEMA-Meldung** (gesetzliche Pflicht, kein Konkurrent hat es)
2. **1-Klick-Stimmenneuverteilung** (Alltags-Workflow)
3. **Zweiseitenansicht** (kleiner Aufwand, große UX-Wirkung)
4. **Chat / Gruppen-Messaging** (WhatsApp-Ablösung)
5. **Kalender-Sync bidirektional**
6. **Wiederkehrende Termine**
7. **Erweiterte Stempel-Bibliothek**
8. **Media Links (YouTube/Spotify)**
9. **CSV/Excel-Migrations-Import**
10. **Dirigenten-Modus Song-Broadcast**

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
