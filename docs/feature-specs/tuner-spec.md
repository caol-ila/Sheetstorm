# Feature-Spezifikation: Stimmgerät (Tuner)

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Konfigurationssystem, Stimmenauswahl, Kapellenverwaltung)  
> **UX-Referenz:** `docs/ux-specs/tuner.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Technische Architektur](#6-technische-architektur)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Der chromatische Tuner ermöglicht es Musikern, ihr Instrument direkt in der Sheetstorm-App zu stimmen — ohne separates physisches Stimmgerät. Über das Geräte-Mikrofon erkennt die App Töne in Echtzeit, zeigt die Cent-Abweichung vom Sollton an und berücksichtigt dabei den Kammerton und das persönliche Instrumentenprofil des Musikers.

**Kernwert:** Musiker haben alles auf einem Gerät — Noten und Stimmgerät. Kein Wechsel zwischen Apps, kein Einschalten eines separaten Geräts.

### 1.2 Das Kernproblem

**Status Quo:**
- Musiker benötigen ein separates Stimmgerät (physisch oder separate App)
- Kammerton-Einstellungen (440/442 Hz) müssen auf jedem Gerät separat konfiguriert werden
- Transpositions-Instrumente (Bb-Klarinette, Eb-Alto-Saxophon, F-Horn) müssen manuell auf den klingenden Ton umrechnen

**Sheetstorm-Lösung:**
- Integrierter Tuner im App-Kontext
- Kammerton-Kalibrierung persistent per Kapelle/Gerät konfigurierbar
- Automatische Transposition basierend auf dem Instrumentenprofil des Nutzers

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Chromatischer Tuner via Mikrofon | Stroboskop-Tuner |
| FFT-basierte Frequenz-Erkennung | Gitarren-Tuner (chromatisch reicht) |
| Anzeige: Ton, Cent-Abweichung, Hz | Automatisches Stimmen (motorisiert) |
| Kammerton-Kalibrierung (A3, default 442 Hz) | MIDI-Output für Stimmton |
| Transpositions-Support: Bb, Eb, F | Polyphoner Tuner (nur Monophon) |
| Mikrofon-Zugriffsmanagement | BLE-Stimmgerät-Kopplung |
| Einblendbar im Spielmodus | Stimmton-Generator (Referenzton-Ausgabe) |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Musiker (Klarinette Bb) | Vor der Probe | Instrument stimmen, App zeigt transponiert |
| Dirigent | Einstimmen der Kapelle | Kammerton auf 442 Hz stellen |
| Musiker (Horn F) | Schnelles Nachstimmen in der Pause | Tuner direkt aus Spielmodus öffnen |
| Musiker (allgemein) | Erstes Mal mit App | Automatische Transposition basierend auf gespeichertem Instrument |

---

## 2. User Stories

### US-01: Instrument via Mikrofon stimmen

> *Als Musiker möchte ich mein Instrument per Mikrofon stimmen können, damit ich kein separates Stimmgerät benötige.*

**Akzeptanzkriterien:**
1. Tuner-Tab oder Tuner-Button im Spielmodus öffnet die Tuner-Ansicht
2. App fragt beim ersten Start nach Mikrofon-Berechtigung (plattformkonform)
3. Bei verweigerten Berechtigungen: verständliche Fehlermeldung + Link zu Geräteeinstellungen
4. Ton-Erkennung startet automatisch sobald Tuner-Ansicht sichtbar ist
5. Anzeige: **erkannter Ton** (z.B. „A"), **Oktave** (z.B. „4"), **Frequenz in Hz**, **Cent-Abweichung** (±50 Cent Skala)
6. Visueller Indikator: Zeiger/Balken bewegt sich in Echtzeit; Grün wenn ±5 Cent, Gelb bis ±15 Cent, Rot außerhalb
7. Latenz Audio-zu-Anzeige: **< 20ms** (gemessen auf Referenzgeräten)
8. Tuner stoppt automatisch wenn Ansicht verlassen wird (Mikrofon-Freigabe)

**INVEST:**
- **I**: Unabhängig von Transposition und Kammerton (funktioniert auch ohne)
- **N**: Kern-Funktion, alle weiteren US bauen darauf auf
- **V**: Direkter Mehrwert ohne weitere Konfiguration
- **E**: ~4 Tage (FFT-Algorithmus + Platform Channel + UI)
- **S**: Nur Erkennung und Anzeige, kein Speichern
- **T**: Frequenz-Erkennung automatisiert testbar mit synthetischem Audiosignal

---

### US-02: Kammerton kalibrieren

> *Als Dirigent möchte ich den Kammerton (A4-Referenzfrequenz) für meine Kapelle einstellen, damit alle Musiker auf dieselbe Frequenz stimmen.*

**Akzeptanzkriterien:**
1. Kammerton einstellbar in Tuner-Einstellungen: Bereich **430–450 Hz**, Schrittweite 0,5 Hz
2. Default: **442 Hz** (üblich für Blaskapellen; konfigurierbar per Kapelle im Konfigurationssystem)
3. Kammerton-Einstellung wird in der **Kapellen-Konfiguration** gespeichert (nicht nur lokal)
4. Alle Musiker der Kapelle erhalten die Kapellen-Konfiguration beim nächsten Sync
5. Nutzer kann kapellenweiten Kammerton lokal überschreiben (Geräte-Konfiguration)
6. Aktuell eingestellter Kammerton ist immer sichtbar in der Tuner-Ansicht (z.B. „A = 442 Hz")
7. Kammerton-Änderung wirkt sofort, kein App-Neustart erforderlich

---

### US-03: Transpositions-Instrument stimmen

> *Als Klarinettist (Bb-Instrument) möchte ich den klingenden Ton transponiert angezeigt bekommen, damit ich direkt meine Noten lesen kann ohne mental umrechnen zu müssen.*

**Akzeptanzkriterien:**
1. Transpositions-Einstellung wird aus dem **Instrumentenprofil** des Nutzers übernommen (MS1 Kapellenverwaltung/Stimmenauswahl)
2. Unterstützte Transpositions-Typen: **Bb** (eine Großsekunde nach oben: Klarinette, Trompete, Sopran-Sax, Tenor-Sax), **Eb** (eine kleine Terz nach oben: Alt-Sax, Bariton-Sax), **F** (eine Quinte nach oben: Horn, Englisch Horn)
3. Transpositions-Modus wird in der Tuner-Ansicht klar angezeigt (z.B. „Bb-Instrument")
4. Nutzer kann Transposition manuell in der Tuner-Ansicht überschreiben (temporär, ohne Profil-Update)
5. Kein Transpositions-Modus (C-Instrumente) ist Standard wenn kein Instrument konfiguriert
6. Beispiel Bb: Klingendes A4 → Anzeige B4 (einen Ton höher)

---

### US-04: Tuner im Spielmodus verwenden

> *Als Musiker möchte ich den Tuner direkt aus dem Spielmodus öffnen können, damit ich mein Instrument schnell nachstimmen kann ohne die Notenseite zu verlassen.*

**Akzeptanzkriterien:**
1. Tuner ist über ein Icon/Button im Spielmodus-Overlay erreichbar (ein Tap)
2. Tuner öffnet als **Bottom Sheet** oder **Overlay** — die Noten bleiben im Hintergrund sichtbar
3. Tuner-Ansicht kann mit einem Wisch oder Tap auf „X" geschlossen werden
4. Beim Schließen kehrt der Spielmodus in den exakten Zustand zurück (gleiche Seite, gleicher Zoom)
5. Wake Lock bleibt während Tuner-Nutzung aktiv (Bildschirm geht nicht aus)
6. Auf Tablets: Tuner kann als Sidebar neben den Noten angezeigt werden (Split-View)

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | Tuner erkennt Töne im Bereich C2–C7 (alle üblichen Blasinstrument-Töne) | Automatisierter Test mit synthetischem Signal |
| AC-02 | Audio-zu-Anzeige Latenz < 20ms auf Referenzgeräten (Snapdragon 665+, iPhone 11+) | Gemessen mit Hochgeschwindigkeitskamera oder Audio-Test-Rig |
| AC-03 | Frequenz-Genauigkeit: ±1 Cent bei reinen Tönen | Unit-Test: synthetische Sinuswelle, definierte Frequenz |
| AC-04 | Transposition Bb, Eb, F: angezeigte Note korrekt (6 Testfälle je Typ) | Unit-Tests |
| AC-05 | Kammerton-Änderung wirkt innerhalb von 100ms auf die Anzeige | UI-Test |
| AC-06 | Mikrofon-Freigabe bei Verlassen der Tuner-Ansicht (keine Hintergrundaufnahme) | Platform-Test: Audio-Berechtigung überwachen |
| AC-07 | Tuner funktioniert Offline (keine Netzwerkverbindung nötig) | Offline-Test |
| AC-08 | Kammerton-Default aus Kapellen-Konfiguration korrekt geladen | Integration-Test |
| AC-09 | Auf iOS: AVAudioEngine-Integration (CoreAudio via Platform Channel) | Geräte-Test |
| AC-10 | Auf Android: Oboe-Integration (Platform Channel) | Geräte-Test |
| AC-11 | Auf Windows/Web: Web Audio API oder Betriebssystem-Mikrofon | Platform-Test |

---

## 4. API-Contract

Der Tuner läuft **vollständig client-seitig** — kein Backend-Aufruf für die Frequenz-Erkennung.

### 4.1 Konfiguration lesen/schreiben (bestehende Konfigurationssystem-Endpunkte)

```
GET  /api/v1/kapellen/{kapelleId}/konfiguration
     → Enthält: { tuner: { kammerton: 442.0 } }

PUT  /api/v1/kapellen/{kapelleId}/konfiguration
     Body: { tuner: { kammerton: 442.5 } }
     → Kapellen-Kammerton global setzen (Admin/Dirigent)

GET  /api/v1/nutzer/konfiguration
     → Enthält: { tuner: { kammerton_override: null, transposition: "Bb" } }

PUT  /api/v1/nutzer/konfiguration
     Body: { tuner: { kammerton_override: 441.0 } }
     → Persönliche Überschreibung
```

**Keine eigenen Tuner-Endpunkte** — nutzt das bestehende Konfigurationssystem aus MS1.

---

## 5. Datenmodell

### 5.1 Konfigurationssystem-Erweiterung (MS1-kompatibel)

Kein neues Datenbankschema. Tuner-Einstellungen werden in der bestehenden Konfigurationsstruktur gespeichert (MS1 `konfigurationssystem-spec.md`):

**Kapellen-Konfiguration (JSON-Feld `config`):**
```json
{
  "tuner": {
    "kammerton": 442.0
  }
}
```

**Nutzer-/Geräte-Konfiguration:**
```json
{
  "tuner": {
    "kammerton_override": null,
    "transposition_override": null
  }
}
```

**Transposition** wird aus dem Instrumentenprofil (`nutzer_instrumente.transposition`) übernommen — kein separates Feld.

---

## 6. Technische Architektur

### 6.1 FFT-Algorithmus (Client-Seitig)

```
Mikrofon-Input (PCM, 44100 Hz, Mono)
  ↓
Windowing (Hann-Window, 2048 Samples)
  ↓
FFT (Real FFT, O(N log N))
  ↓
Peak-Erkennung (Parabolic Interpolation für Sub-Bin-Genauigkeit)
  ↓
Harmonische Analyse (Grundton vs. Oberton-Erkennung)
  ↓
Nearest-Note + Cent-Berechnung
  ↓
Glättung (Exponentieller Moving Average, α=0.3)
  ↓
Anzeige-Update
```

### 6.2 Platform Channels

| Plattform | Native Audio API | Channel-Name |
|-----------|-----------------|--------------|
| iOS | AVAudioEngine (CoreAudio) | `com.sheetstorm/tuner` |
| Android | Oboe (NDK) | `com.sheetstorm/tuner` |
| Windows | WASAPI | `com.sheetstorm/tuner` |
| Web | Web Audio API (JS) | Web interop, kein Channel |

### 6.3 Latenz-Budget (< 20ms)

| Schritt | Budget |
|---------|--------|
| Audio-Buffer-Latenz | ≤ 5ms |
| FFT-Berechnung | ≤ 3ms |
| Note-Berechnung | ≤ 1ms |
| Flutter UI-Update (1 Frame @60fps) | ≤ 16ms |
| **Gesamt** | **< 20ms** |

### 6.4 Transpositions-Tabelle

| Instrument-Typ | Transposition | Notierung → Klingend |
|----------------|---------------|----------------------|
| Bb (Klarinette, Trompete, Sopran-Sax) | +2 Halbtöne | C4 → Bb3 klingend |
| Eb (Alt-Sax, Bariton-Sax) | +3 Halbtöne | C4 → Eb3 klingend |
| F (Horn, Englisch Horn) | +7 Halbtöne | C4 → F3 klingend |
| C (Flöte, Oboe, Fagott, Posaune) | 0 | C4 → C4 klingend |

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 Mikrofon-Berechtigung verweigert
- **Szenario:** Nutzer verweigert Mikrofon-Zugriff beim ersten Request.
- **Verhalten:** Tuner zeigt Erklärungsscreen mit Button „Berechtigung erteilen" → öffnet Geräteeinstellungen. Kein Crash, kein leerer Screen.

### 7.2 Lauter Umgebungslärm
- **Szenario:** Probe läuft, mehrere Instrumente spielen gleichzeitig.
- **Verhalten:** Tuner zeigt unsichere Erkennung (Glättung reduziert Flackern), optionaler Hinweis „Stimmen im ruhigen Umfeld empfohlen". Kein falscher Ton wird als „richtig" angezeigt.

### 7.3 Sehr tiefe oder sehr hohe Töne
- **Szenario:** Kontrabass-Klarinette (tiefstes C) oder Piccolo (höchstes C).
- **Verhalten:** Frequenz-Bereich C1–C8 wird unterstützt. Außerhalb des Bereichs: Anzeige „Ton außerhalb Bereich", kein Absturz.

### 7.4 Kein Ton
- **Szenario:** Nutzer öffnet Tuner, spielt aber noch nicht.
- **Verhalten:** Anzeige bleibt leer oder zeigt „—". Kein Flackern, kein Fehlerton.

### 7.5 Kammerton-Bereich überschritten
- **Szenario:** Nutzer versucht Kammerton auf 500 Hz zu setzen.
- **Verhalten:** Eingabe wird auf 450 Hz geclampt, Validierungshinweis angezeigt.

### 7.6 Instrumentenprofil nicht konfiguriert
- **Szenario:** Neuer Nutzer, noch kein Instrument im Profil gesetzt.
- **Verhalten:** Tuner läuft im C-Modus (keine Transposition). Hinweis: „Instrument in Profil eintragen für automatische Transposition" (nicht-blockierend).

### 7.7 Plattform ohne Mikrofon-Unterstützung
- **Szenario:** App läuft auf einem Gerät ohne Mikrofon (z.B. älteres Tablet).
- **Verhalten:** Tuner-Tab wird ausgegraut mit Hinweis „Kein Mikrofon verfügbar".

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Konfigurationssystem (MS1) | Kammerton-Einstellung wird dort gespeichert | MS1 |
| Stimmenauswahl / Instrumentenprofil (MS1) | Transposition aus Instrumentenprofil | MS1 |
| Kapellenverwaltung (MS1) | Kapellen-Kammerton als Kapellen-Config | MS1 |

### 8.2 Parallele Features (keine Blockierung)

| Feature | Beziehung |
|---------|-----------|
| Spielmodus (MS1) | Tuner läuft als Overlay, Spielmodus-Code wird nicht verändert |
| Echtzeit-Metronom (MS3) | Gleicher Probenbetrieb-Kontext, aber technisch unabhängig |

### 8.3 Aus-Scope-Abhängigkeiten (zukünftige Meilensteine)

- Stimmton-Generator (Referenzton abspielen): MS5 oder später
- BLE-Pedal/Hardware-Stimmgerät: MS5 oder später

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Mikrofon-Tuner erkenn Töne in Echtzeit, Anzeige korrekt
- [ ] US-02: Kammerton konfigurierbar (430–450 Hz), persistent per Kapelle
- [ ] US-03: Transposition Bb, Eb, F korrekt berechnet
- [ ] US-04: Tuner aus Spielmodus erreichbar (Bottom Sheet / Sidebar)
- [ ] Alle AC-01 bis AC-11 erfüllt
- [ ] Latenz < 20ms gemessen und dokumentiert

### Qualität
- [ ] Unit-Tests FFT-Algorithmus: ≥ 10 Frequenz-Testfälle
- [ ] Unit-Tests Transposition: alle 4 Typen × 12 Töne = 48 Tests
- [ ] Integration-Test: Kammerton aus Kapellen-Config korrekt geladen
- [ ] Platform-Tests: iOS, Android, Windows (je ein Gerät)
- [ ] Kein Memory Leak bei langem Tuner-Betrieb (> 10 Minuten)
- [ ] Code Coverage ≥ 80% für Tuner-Logik

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Keine UI-Elemente überlagern die Cent-Anzeige
- [ ] Dark Mode korrekt
- [ ] Accessibility: Cent-Abweichung auch als Screenreader-Text

### Deployment
- [ ] Mikrofon-Berechtigung in App-Manifests (iOS Info.plist, Android Manifest)
- [ ] Performance-Messung auf Referenzgerät dokumentiert
- [ ] Swagger-Doku für Konfigurationssystem-Erweiterungen aktualisiert
