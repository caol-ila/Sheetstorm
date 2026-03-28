# Anforderungsvergleich: SheetHappens → Sheetstorm

> **Erstellt:** 2026-03-28
> **Aktualisiert:** 2026-03-28 (v2 — Abgleich gegen spezifikation.md v2)
> **Autor:** Fury (Business Analyst)
> **Status:** Zur Entscheidung durch Thomas
> **Zweck:** Systematischer Vergleich des Vorgänger-Projekts SheetHappens mit dem aktuellen Sheetstorm-Projekt, um fehlende Anforderungen zu identifizieren und Übernahme-Empfehlungen auszusprechen.

---

## Was ist SheetHappens?

SheetHappens ist ein voll spezifiziertes und teilweise implementiertes Vorgänger-Projekt mit identischem Kernziel: **Cross-Platform Notenmanagement für Blaskapellen**. Das Projekt umfasst:

- **36 Spezifikationsdokumente** (16 Kapitel + 20 Feature-Specs)
- **12 Architecture Decision Records (ADRs)**
- **8 Meilensteine** (MS0–MS3 implementiert, MS4–MS8 geplant)
- **Gewählter Tech-Stack:** C# 13 / .NET 10, MAUI Blazor Hybrid + Blazor WASM PWA, PostgreSQL, Redis, Azure Blob Storage, SignalR, .NET Aspire
- **20 Entities** im Datenmodell mit vollständiger ER-Beschreibung
- **Implementierungsstatus:** Auth, Band-Management, Sheet Upload + AI-Extraktion, Library, Viewer, Annotations, Conductor Hub — alles lauffähig

---

## Vergleichstabelle — Alle Features

### Legende

- ✅ **Ja** — Feature ist in Sheetstorm vollständig spezifiziert
- ⚠️ **Teilweise** — Grundkonzept vorhanden, aber SheetHappens geht deutlich weiter
- ❌ **Nein** — Feature fehlt in Sheetstorm komplett
- 🆕 **Sheetstorm-exklusiv** — Feature existiert nur in Sheetstorm

---

### Kernbereich: Notenverwaltung

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 1 | Zentrale Notenablage pro Band | ✅ Voll spezifiziert + implementiert | ✅ F1.1 | ✅ Ja | — |
| 2 | PDF-Upload mit AI-Metadaten-Erkennung | ✅ GPT-4o Vision, Pipeline spezifiziert | ✅ F1.2 + F1.3 | ✅ Ja | — |
| 3 | MIDI-Upload + Parsing | ✅ DryWetMIDI, Track-Analyse | ❌ Nur PDF/Bilder/Fotos | ❌ Nein | 🟡 Mittel — Ergänzung als Importformat |
| 4 | BYOK AI-Lizenzierung (User/Band/Platform) | ✅ 3-stufiger Fallback | ✅ F1.4 (2-stufig: User/Kapelle) | ⚠️ Teilweise | 🟢 Niedrig — Platform-Default als 3. Stufe ergänzen |
| 5 | Stimmenauswahl + Fallback-Logik | ✅ VoiceFallbackRules + SongVoiceFallbacks | ✅ F1.5 | ⚠️ Teilweise | 🟡 Mittel — Song-Level-Overrides übernehmen |
| 6 | Labeling-Workflow (Multi-Lied-Upload) | ✅ Spezifiziert | ✅ F1.2 | ✅ Ja | — |
| 7 | Berechtigungen für Noteneinpflege | ✅ Rollenbasiert | ✅ F1.6 | ✅ Ja | — |
| 8 | Server-seitige WebP-Konvertierung | ✅ ADR-007, PdfPig + SkiaSharp | ❌ Nicht spezifiziert | ❌ Nein | 🔴 Hoch — Plattformunabhängige Anzeige |
| 9 | Voice Assignments (Dirigent weist Stimmen zu) | ✅ VoiceAssignment-Entity | ❌ Nur Selbst-Auswahl | ❌ Nein | 🟡 Mittel — Für Besetzungsplanung wichtig |
| 10 | Duplikat-Erkennung (SHA-256 Hash) | ✅ FileHash-Feld | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — Nice-to-have |

### Kernbereich: Notenanzeige & Spielmodus

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 11 | Fokus-/Spielmodus (Vollbild) | ✅ PerformanceLayout implementiert | ✅ F2.1 | ✅ Ja | — |
| 12 | Auto-Rotation (schräge Fotos gerade richten) | ❌ Konvertiert zu WebP, keine Auto-Rotation | ✅ F2.2 | 🆕 | Sheetstorm-Vorteil |
| 13 | Auto-Zoom (optimale Darstellung) | ❌ Pinch-to-Zoom, „fit width" | ✅ F2.3 | 🆕 | Sheetstorm-Vorteil |
| 14 | Dark Mode / Sepia / High Contrast | ✅ Im Viewer spezifiziert | ❌ Nicht in Spec (nur Gap-Analyse) | ❌ Nein | 🟡 Mittel — Für dunkle Auftrittsorte |
| 15 | Bluetooth-Fußpedal-Support | ✅ HID-Profile, konfigurierbare Keys, Learn Mode | ✅ F-SM-03 (Must, MS1) | ✅ Ja | — |
| 16 | Thumbnail-Leiste für Schnellnavigation | ✅ Spezifiziert | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — UX-Verbesserung |
| 17 | Zoom-Level pro Song speichern | ✅ Spezifiziert | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig |
| 18 | Bildschirm-Helligkeit im Viewer | ✅ Spezifiziert | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig |
| 19 | Batterie-Anzeige im Viewer | ✅ Spezifiziert | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig |

### Kernbereich: Annotationen

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 20 | Annotationen (Freihand, Text, Highlight) | ✅ 6 Typen + Stylus-Support | ✅ F2.4 | ✅ Ja | — |
| 21 | Sichtbarkeitsebenen | ✅ 4 Ebenen (Personal/Instrument/Section/Band) | ✅ 3 Ebenen (Lokal/Stimme/Orchester) | ⚠️ Teilweise | 🟢 Niedrig — 4. Ebene „Instrument" evaluieren |
| 22 | AI-Annotation-Analyse + Cross-Part-Propagation | ✅ AnnotationProposals, AI-Interpretation | ❌ Nicht spezifiziert | ❌ Nein | 🟡 Mittel — Innovatives Feature |
| 23 | Stift-/Stylus-Support (Drucksensitivität) | ✅ Apple Pencil, Surface Pen, S Pen Details | ⚠️ Erwähnt in F2.4, nicht detailliert | ⚠️ Teilweise | 🟢 Niedrig — Detail-Spec ergänzen |
| 24 | Echtzeit-Sync von Annotationen (SignalR) | ✅ Spezifiziert | ❌ Nicht spezifiziert | ❌ Nein | 🟡 Mittel — Für Proben wichtig |

### Kernbereich: Kapellen- & Mitgliederverwaltung

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 25 | Band/Kapelle erstellen + verwalten | ✅ Invite-Code, Logo, AI-Config | ✅ F3.1 | ✅ Ja | — |
| 26 | Multi-Kapellen-Zugehörigkeit | ✅ Multi-Band | ✅ F3.2 | ✅ Ja | — |
| 27 | Rollensystem | ✅ 6 Rollen (Admin, Conductor, SectionLeader, Member, Teacher, Student) | ✅ 7 Rollen (+Notenwart) | ✅ Ja | Sheetstorm hat „Notenwart" extra — gut |
| 28 | Registerverwaltung (Instrumentengruppen) | ✅ BandInstrumentVoices | ✅ Registerführer-Rolle | ✅ Ja | — |
| 29 | Invite-Code (8 Zeichen) | ✅ Implementiert | ⚠️ „Einladung per Link oder E-Mail" | ⚠️ Teilweise | 🟢 Niedrig — Invite-Code ist pragmatischer |

### Kernbereich: Setlist & Events

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 30 | Setlist-Verwaltung | ✅ Drag & Drop, Notes pro Entry | ✅ F4.1 | ✅ Ja | — |
| 31 | Events mit Attendance | ✅ Going/NotGoing/Maybe | ✅ F5.1 | ✅ Ja | — |
| 32 | Schichtplanung (Feste) | ❌ Nur EventType „Festival", keine Schichten | ✅ F5.2 | 🆕 | Sheetstorm-Vorteil |
| 33 | Kalenderansicht | ❌ Nur Liste/Karten | ✅ F5.3 (Monat/Woche/Agenda) | 🆕 | Sheetstorm-Vorteil |
| 34 | iCal-Export | ❌ Nicht spezifiziert | ✅ F5.3 | 🆕 | Sheetstorm-Vorteil |

### Kernbereich: Conductor Mode & Echtzeit

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 35 | Conductor Mode (Song-Broadcast) | ✅ SignalR ConductorHub, implementiert | ❌ Nicht in Spec | ❌ Nein | 🔴 Hoch — Killer-Feature für Proben |
| 36 | Local Hotspot / Relay Mode | ✅ Embedded Kestrel, mDNS | ❌ Nicht spezifiziert | ❌ Nein | 🟡 Mittel — Für Proben ohne Internet |
| 37 | Echtzeit-Metronom (synchronisiert) | ✅ Metronom im Viewer integriert | ✅ F7.2 | ✅ Ja | — |
| 38 | Push-Notifications (OS-Level) | ✅ MAUI Local Notifications | ❌ Nur „Push-Benachrichtigungen" erwähnt | ⚠️ Teilweise | 🟢 Niedrig |

### Kernbereich: Persönliche Sammlung & Sync

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 39 | Persönliche Notensammlung | ✅ BandId nullable = personal | ✅ F6.1 | ✅ Ja | — |
| 40 | Cloud-Storage-Sync (OneDrive, Dropbox) | ❌ Nur Azure Blob | ✅ F6.2 | 🆕 | Sheetstorm-Vorteil |
| 41 | Offline-Modus (SQLite, IndexedDB) | ✅ Detailliert spezifiziert + ADR | ⚠️ Anforderungen definiert, keine Architektur | ⚠️ Teilweise | 🔴 Hoch — Offline-Architektur spezifizieren |
| 42 | Push/Pull Sync-Mechanismus | ✅ Detailliert, Conflict Resolution | ⚠️ „Sync bei Verbindung" erwähnt | ⚠️ Teilweise | 🟡 Mittel — Sync-Strategie ausarbeiten |

### Kernbereich: Tools

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 43 | Stimmgerät (Tuner) | ✅ FFT, Transposition, Referenzton | ✅ F7.1 | ✅ Ja | — |
| 44 | Metronom (standalone) | ✅ Tap-Tempo, Subdivisions, Speed Trainer | ✅ F7.2 (Basis) | ⚠️ Teilweise | 🟢 Niedrig — Speed-Trainer ergänzen |
| 45 | Speed-Hot-Buttons (Original / −10% / −25%) | ✅ Im Viewer integriert | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — Nettes Übungsfeature |
| 46 | Virtual Band (Playback) | ✅ Geplant (post-v1.0) | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — Zukunftsfeature |

### Kernbereich: Lehre-Modul

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 47 | Lehrer/Schüler-Rollen | ✅ Detailliert mit Dashboard | ✅ F8.1 | ✅ Ja | — |
| 48 | Lernpfade (stufenweise Freischaltung) | ✅ 5 Entities, Unlock-Criteria, Cloning | ⚠️ F8.2 (Grundkonzept) | ⚠️ Teilweise | 🟡 Mittel — Detail-Spec von SheetHappens übernehmen |
| 49 | Übungsaufgaben (Practice Tasks) | ✅ Frequency, Rating, Lifecycle | ❌ Nur „Noten freischalten" | ❌ Nein | 🟡 Mittel — Strukturierte Übungsplanung |
| 50 | Übungsprotokolle (Practice Logs) | ✅ Dauer, Selbstbewertung, Notizen | ❌ Nur „Fortschritt markieren" | ❌ Nein | 🟡 Mittel — Lernfortschritt messbar machen |
| 51 | Audio-Aufnahmen bei Übungen | ✅ Blob Storage, Inline-Playback | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — Für Fernunterricht |

### Zusätzliche SheetHappens-Features (nicht in Sheetstorm)

| # | Feature | SheetHappens | Sheetstorm | Status | Empfehlung |
|---|---------|-------------|-----------|:------:|------------|
| 52 | GEMA-/Verwertungsgesellschaft-Meldung | ✅ 8 Societies, XML/CSV/PDF-Export | ❌ Nicht spezifiziert | ❌ Nein | 🔴 Hoch — Gesetzliche Pflicht für Vereine |
| 53 | Konzertberichte (Concert Reports) | ✅ ConcertReport-Entity, Snapshot-Daten | ❌ Nicht spezifiziert | ❌ Nein | 🔴 Hoch — Gehört zu GEMA-Meldung |
| 54 | Notenmarkt-Integration (Marketplace) | ✅ 5 Provider, Affiliate, Lizenzverwaltung | ❌ Nicht spezifiziert | ❌ Nein | 🟢 Niedrig — Langfrist-Feature |
| 55 | Media Links (YouTube / Spotify pro Song) | ✅ AI-Vorschläge, Embed/Deep-Link | ❌ Nicht spezifiziert | ❌ Nein | 🟡 Mittel — Hilfreich beim Üben |
| 56 | Internationalisierung (i18n) | ✅ .resx, 6 Sprachen geplant | ❌ „Deutsch first, i18n-Architektur später" | ❌ Nein | 🟢 Niedrig — i18n-ready Architektur vorsehen |
| 57 | Registrierung + JWT Auth | ✅ Implementiert, Refresh Tokens | ⚠️ Erwähnt, nicht spezifiziert | ⚠️ Teilweise | 🟡 Mittel — Auth-Spec ausarbeiten |

---

## Zusammenfassung der Gaps

| Kategorie | Gesamt | ✅ Ja | ⚠️ Teilweise | ❌ Nein | 🆕 Sheetstorm-exklusiv |
|-----------|:------:|:-----:|:------------:|:------:|:---------------------:|
| Notenverwaltung | 10 | 4 | 2 | 4 | 0 |
| Notenanzeige & Spielmodus | 9 | 1 | 0 | 7 | 1 |
| Annotationen | 5 | 1 | 2 | 2 | 0 |
| Kapellenverwaltung | 5 | 4 | 1 | 0 | 0 |
| Setlist & Events | 5 | 2 | 0 | 0 | 3 |
| Conductor & Echtzeit | 4 | 1 | 1 | 2 | 0 |
| Persönliche Sammlung & Sync | 4 | 1 | 2 | 0 | 1 |
| Tools | 4 | 1 | 1 | 2 | 0 |
| Lehre-Modul | 5 | 1 | 1 | 3 | 0 |
| Zusätzliche Features | 6 | 0 | 1 | 5 | 0 |
| **Gesamt** | **57** | **16** | **11** | **25** | **5** |

**Sheetstorm hat 5 exklusive Features**, die SheetHappens fehlen:
- Auto-Rotation für schräge Fotos
- Auto-Zoom (intelligente Darstellungsoptimierung)
- Schichtplanung für Feste
- Kalenderansicht (Monat/Woche/Agenda)
- Cloud-Storage-Sync (OneDrive/Dropbox)

---

## Detaillierte Gap-Analyse — Die wichtigsten Lücken

### 🔴 Hoch-Priorität

#### Gap 1: GEMA-/Verwertungsgesellschaft-Meldung

**Was SheetHappens hat:** Vollständiges Konzertberichts-System mit automatischer Generierung aus Setlists, Unterstützung für 8 Verwertungsgesellschaften (GEMA, SUISA, AKM, ASCAP, BMI, PRS, SACEM, SIAE), Export als XML (GEMA Musikfolge), CSV und PDF. AI-gestützte Suche nach GEMA-Werknummern. Erinnerung an ausstehende Meldungen.

**Was Sheetstorm hat:** Nichts.

**Warum relevant:** Jeder Musikverein in DACH ist gesetzlich verpflichtet, Konzertprogramme an die zuständige Verwertungsgesellschaft zu melden. Heute machen die meisten das manuell — ein enormer Schmerzpunkt. Automatisierung aus der Setlist heraus wäre ein echter Differentiator.

**Empfehlung:** In Spezifikation aufnehmen, Meilenstein 2 (nach Setlists/Events). Datenmodell von SheetHappens (ConcertReport, ConcertReportEntry) als Vorlage nutzen.

---

#### Gap 2: Conductor Mode (Echtzeit-Stückauswahl)

**Was SheetHappens hat:** Dirigent aktiviert Conductor Mode, wählt ein Stück aus einer Setlist → SignalR broadcast an alle verbundenen Geräte → jeder Musiker bekommt ein Notification-Dialog mit „Jetzt öffnen" / „Ablehnen" → Viewer öffnet automatisch die richtige Stimme. Verbundene Musiker-Zähler, Auto-Reconnect, verpasste Signale werden nachgeliefert.

**Was Sheetstorm hat:** Gap-Analyse erwähnt „Dirigenten-Mastersteuerung" als mittlere Priorität, aber keine Spezifikation.

**Warum relevant:** Bei Marschmusik, Standkonzerten und schnellen Programmwechseln spart der Conductor Mode erheblich Zeit. Der Dirigent wählt das nächste Stück — alle Tablets wechseln gleichzeitig. Kein Suchen, kein Blättern.

**Empfehlung:** In Spezifikation aufnehmen, Meilenstein 2. SheetHappens' SignalR-basierte Architektur als Referenz.

---

#### Gap 3: Bluetooth-Fußpedal-Support

**Was SheetHappens hat:** HID-Profil-basiert (OS-Pairing), konfigurierbares Key-Mapping für Page Down/Up/Home/End, „Learn Mode" zum Zuordnen beliebiger Tasten, kompatibel mit AirTurn, PageFlip, Donner, iRig BlueTurn.

**Was Sheetstorm hat:** Gap-Analyse als 🔴 Hoch eingestuft, aber nicht in der Spezifikation.

**Warum relevant:** Blasmusiker haben beide Hände am Instrument. Fußpedal ist für viele der Hauptgrund für den Umstieg auf digitale Noten.

**Empfehlung:** In Spezifikation aufnehmen, MS1. SheetHappens' Spec (features/07-pedals.md) als Vorlage.

---

#### Gap 4: Offline-Architektur (Detail-Spezifikation)

**Was SheetHappens hat:** Detaillierte Offline-Architektur mit SQLite (MAUI) + IndexedDB (Blazor WASM), Push/Pull-Sync, Conflict Resolution (Last-Write-Wins), Download-Queue, Storage-Management, Service Worker für PWA, „Update available"-Badge, mDNS für lokale Entdeckung.

**Was Sheetstorm hat:** Anforderungstabelle (Abschnitt 8), welche Features offline funktionieren, aber keine Architektur-Spezifikation für Sync, Caching, Conflict Resolution.

**Empfehlung:** Offline-Architektur spezifizieren. SheetHappens' ADR-012 und Spec features/08-offline.md + features/12-sync.md als Referenz.

---

#### Gap 5: Server-seitige WebP-Konvertierung

**Was SheetHappens hat:** Alle PDFs werden bei Import zu WebP-Bildern konvertiert (2048px, Quality 90, PdfPig + SkiaSharp). Der Viewer zeigt auf allen Plattformen nur Bilder an — nie PDFs direkt. Konsistente Darstellung, einfaches Offline-Caching.

**Was Sheetstorm hat:** Nicht spezifiziert. F2.1 definiert Seitenwechsel, aber nicht das Display-Format.

**Empfehlung:** Als Architektur-Entscheidung evaluieren. Vereinfacht Cross-Platform-Rendering erheblich.

---

### 🟡 Mittel-Priorität

#### Gap 6: Song-Level Voice Fallback Overrides

SheetHappens erlaubt pro Stück individuelle Fallback-Regeln (SongVoiceFallback-Entity). Sheetstorm hat nur globale Fallback-Logik. Relevant, wenn z.B. ein Arrangement keine 2. Klarinette hat und stattdessen die Altsaxophon-Stimme genutzt werden soll — aber nur für dieses eine Stück.

#### Gap 7: Voice Assignments durch Dirigenten

Der Dirigent kann in SheetHappens Musikern aktiv Stimmen zuweisen (VoiceAssignment), global oder pro Stück. Sheetstorm hat nur Selbst-Auswahl durch den Musiker. Für Besetzungsplanung bei Konzerten relevant.

#### Gap 8: Practice Tasks & Logs im Lehre-Modul

SheetHappens hat strukturierte Übungsaufgaben mit Frequenz (täglich/wöchentlich), Fälligkeitsdatum, Lehrernotizen, Bewertung (1–5), und Übungsprotokolle mit Dauer, Selbstbewertung und optionaler Audio-Aufnahme. Sheetstorm definiert nur „Noten freischalten" und „Fortschritt markieren".

#### Gap 9: Lernpfade — Detail-Spezifikation

SheetHappens definiert 5 zusätzliche Entities (LearningPath, Steps, Items, Enrollments, StepProgress) mit stufenweiser Freischaltung, verschiedenen Unlock-Kriterien (Alle Tasks fertig, Rating-Schwelle, Lehrer-Genehmigung, zeitbasiert), und Template-Cloning. Sheetstorm hat nur ein Grundkonzept.

#### Gap 10: Media Links (YouTube/Spotify)

Pro Stück können YouTube- und Spotify-Links gespeichert werden. AI schlägt passende Links vor (YouTube Data API, Spotify Web API). „Listen"-Button auf Setlist-Einträgen. Hilfreich beim Üben und zur Referenz.

#### Gap 11: AI-Annotation-Analyse

SheetHappens analysiert Annotationen per AI (z.B. „Takte 12–16 gestrichen") und erstellt automatisch Vorschläge (AnnotationProposals) für andere Stimmen. Registerführer/Dirigent prüft und akzeptiert/verwirft.

#### Gap 12: Echtzeit-Sync von Annotationen

Annotationen werden über SignalR in Echtzeit an alle Musiker derselben Stimme/Band propagiert. Sheetstorm definiert Sichtbarkeitsebenen, aber keinen Echtzeit-Sync.

#### Gap 13: Auth-Spezifikation ausarbeiten

SheetHappens hat JWT + Refresh Tokens, Passwort-Anforderungen, Token-Expiry, Secure Storage spezifiziert. Sheetstorm erwähnt JWT in der API-Struktur, hat aber keine Auth-Spec.

#### Gap 14: Local Hotspot / Relay Mode

Dirigenten-Gerät als lokaler Server (Embedded Kestrel auf Port 5150, mDNS-Broadcast). Für Proben und Auftritte ohne Internet. Alle Musiker verbinden sich über lokales WLAN.

---

### 🟢 Niedrig-Priorität

| # | Feature | Bemerkung |
|---|---------|-----------|
| 15 | MIDI-Upload als zusätzliches Importformat | Ergänzung, nicht kritisch |
| 16 | 3. AI-Fallback-Stufe (Platform Default) | Kleiner Architektur-Punkt |
| 17 | Dark Mode / Sepia im Viewer | Bereits in Gap-Analyse, Entscheidung ausstehend |
| 18 | Thumbnail-Leiste, Zoom-Speicherung | UX-Details für Viewer |
| 19 | Batterie-Anzeige, Helligkeit im Viewer | Performance-UX |
| 20 | 4. Annotations-Ebene „Instrument" | Feingranularität der Sichtbarkeit |
| 21 | Speed-Trainer-Modus für Metronom | Übungsfeature |
| 22 | Virtual Band (Playback) | Zukunftsfeature |
| 23 | Audio-Aufnahmen in Übungsprotokollen | Für Fernunterricht |
| 24 | Invite-Code statt E-Mail-Einladung | Pragmatischer Beitrittsmechanismus |
| 25 | i18n-ready Architektur (.resx) | Architekturelle Vorbereitung |
| 26 | Notenmarkt-Integration | Langfrist-Feature |
| 27 | Duplikat-Erkennung (File Hash) | Nice-to-have |

---

## Sheetstorm-Vorteile gegenüber SheetHappens

Sheetstorm hat auch Features, die SheetHappens fehlen:

| # | Feature | Bedeutung |
|---|---------|-----------|
| 1 | **Auto-Rotation** für schräge Fotos | Wichtig für Kamera-Uploads — AI-basierte Erkennung und Korrektur |
| 2 | **Auto-Zoom** mit intelligenter Bereichserkennung | Optimale Darstellung ohne manuelles Anpassen |
| 3 | **Schichtplanung** für Feste/Veranstaltungen | Vereinsleben-Feature, das SheetHappens komplett fehlt |
| 4 | **Kalenderansicht** (Monat/Woche/Agenda) + iCal-Export | Bessere Terminübersicht |
| 5 | **Cloud-Storage-Sync** (OneDrive/Dropbox) für persönliche Sammlung | Alternative zu zentralem Blob Storage |
| 6 | **Notenwart**-Rolle (spezialisiert auf Notenpflege) | Feinere Rollengranularität als SheetHappens |

---

## Empfehlungen für Thomas

### Sofort in Spezifikation aufnehmen (🔴 Hoch)

> **Update v2:** Bluetooth-Fußpedal (Gap 3) ist jetzt ✅ F-SM-03. Verbleibende 🔴-Gaps:

1. **GEMA-Meldung / Konzertberichte** — Gesetzliche Pflicht, hoher Schmerzpunkt, klarer Differentiator. SheetHappens-Datenmodell als Vorlage nutzen.
2. **Conductor Mode** — Killer-Feature für Proben und Konzerte. SignalR-basiert, technisch gut machbar. SheetHappens hat ConductorHub vollständig implementiert.
3. **Offline-Architektur** — Detailliert spezifizieren statt nur Anforderungen listen. SheetHappens' Ansatz (SQLite + IndexedDB) als Referenz.
4. **Server-seitige WebP-Konvertierung** — Architektur-Entscheidung, die alle Plattformen vereinheitlicht.

### Zur Evaluierung (🟡 Mittel)

6. **Voice Assignments** + **Song-Level Fallbacks** — Wertvolle Erweiterung unserer Stimmenlogik.
7. **Lehre-Modul: Practice Tasks & Logs** — Unsere Grundspec deutlich aufwerten.
8. **Media Links** (YouTube/Spotify) — Geringer Aufwand, hoher Nutzwert beim Üben.
9. **AI-Annotation-Analyse** — Innovativ, aber komplex. Als „Could" für spätere Meilensteine.
10. **Local Relay Mode** — Für Proben ohne Internet. Technisch anspruchsvoll (Embedded Server).

### Bewusst nicht übernehmen

- **Marketplace-Integration** — Zu komplex, unklare API-Verfügbarkeit, Lizenzfragen.
- **Virtual Band** — Zukunftsmusik, selbst SheetHappens plant es erst post-v1.0.
- **i18n** — Unsere Deutsch-first-Strategie ist richtig. i18n-ready Architektur reicht vorerst.

### Aus SheetHappens' Tech-Stack lernen

SheetHappens hat sich für **.NET 10 + MAUI Blazor Hybrid + Blazor WASM** entschieden — derselbe Tech-Stack, den unser Architect (Stark) evaluiert. Wenn wir denselben Stack wählen, können wir:
- SheetHappens' **ADRs als Referenz** nutzen (12 Architektur-Entscheidungen dokumentiert)
- **Code-Patterns** übernehmen (Clean Architecture, CQRS-lite, SignalR-Hubs)
- **Testcontainers-Setup** und CI-Pipeline als Vorlage verwenden

> ⚠️ **Wichtig:** SheetHappens ist kein Fork-Kandidat. Es ist ein separates Projekt mit eigener Struktur. Aber seine Spezifikationen und Architektur-Entscheidungen sind wertvolle Referenzdokumente für Sheetstorm.

---

*Dieses Dokument dient als Entscheidungsgrundlage. Thomas entscheidet, welche Gaps in die Spezifikation aufgenommen werden.*
