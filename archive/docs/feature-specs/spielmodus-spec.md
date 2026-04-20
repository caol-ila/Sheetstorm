# Feature-Spezifikation: Spielmodus (Performance Mode)

> **Issue:** #25  
> **Meilenstein:** MS1  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Draft — Wanda UX (#24) in Arbeit  
> **Depends on:** #24 (UX Spielmodus), #7 (Backend), #8 (Flutter Scaffolding)  
> **Blocked by:** —  
> **UX-Referenz:** `docs/ux-design.md` §3.1, §5.2, §5.3, §6.1, §6.4

---

## 1. Feature-Überblick

### Beschreibung

Der Spielmodus ist **das wichtigste Feature von Sheetstorm**. Er ist der Grund, warum Musiker die App öffnen. Alles andere ist Infrastruktur — der Spielmodus ist das Produkt.

Im Spielmodus sieht der Musiker ausschließlich seine Noten, vollflächig, ohne jede Ablenkung. Er blättert mit einem Tap, Swipe oder Fußpedal. Die App verschwindet hinter den Noten.

**Focus-First-Prinzip:** Kein UI-Element, das nicht unmittelbar zum Spielen beiträgt, ist im Spielmodus sichtbar. Overlay-Elemente erscheinen nur auf explizite Anforderung (Tap in die Mitte).

### Scope MS1 (In-Scope)

- ✅ Vollbild-Notenanzeige (PDF, Bild)
- ✅ Seitenwechsel (Tap, Swipe, Tastatur)
- ✅ Half-Page-Turn (Hochformat)
- ✅ Zwei-Seiten-Modus (Tablet Querformat)
- ✅ Auto-Zoom & Auto-Rotation
- ✅ Overlay-UI (Stimme wechseln, Nachtmodus, Sperren, Einstellungen)
- ✅ Nacht-/Bühnenmodus
- ✅ Bildschirm-Timeout deaktiviert
- ✅ UI-Lock (nur Tap-Zonen wirken)
- ✅ Fußpedal (Bluetooth HID/MIDI)
- ✅ Canvas-Layer für Annotationen (Anzeige)
- ✅ Performance: <16ms Render-Zeit für Seitenwechsel

### Out-of-Scope MS1 (Später)

- ❌ Auto-Scroll / Reflow (MS3)
- ❌ Face-Gesten (MS5)
- ❌ Link Points / Wiederholungsmarken (MS1 Should — eigene Spec)
- ❌ Annotationen editieren im Spielmodus (eigene Spec #32)
- ❌ MIDI-Steuerung (über HID hinaus)

---

## 2. User Stories

### US-01: Ablenkungsfreie Notenansicht

**Als** Musiker auf der Bühne  
**möchte ich** meine Noten vollflächig und ohne ablenkende UI-Elemente sehen  
**damit** ich mich vollständig auf das Spielen konzentrieren kann.

**Akzeptanzkriterien:**
- [ ] AC-01: Beim Aktivieren des Spielmodus sind **alle** UI-Elemente (Navigation, Header, Bottom-Bar) ausgeblendet
- [ ] AC-02: Das Notenblatt füllt den gesamten Viewport aus — 0px Padding auf allen Seiten
- [ ] AC-03: Der Bildschirm-Timeout ist im Spielmodus automatisch deaktiviert (Wake Lock API / iOS UIApplication.shared.isIdleTimerDisabled)
- [ ] AC-04: Benachrichtigungen erscheinen **nicht** als Pop-up während des Spielens — werden stumm gesammelt
- [ ] AC-05: Im UI-Lock-Modus reagiert die App **nur** auf die definierten Tap-Zonen (links, rechts) — alle anderen Touches werden ignoriert

---

### US-02: Seiten blättern (Tap, Swipe, Tastatur)

**Als** Musiker  
**möchte ich** durch Tippen oder Wischen durch meine Noten blättern  
**damit** ich beim Spielen nicht absetzen muss.

**Akzeptanzkriterien:**
- [ ] AC-06: Tap in die **rechte 60%** des Bildschirms → nächste Seite
- [ ] AC-07: Tap in die **linke 40%** des Bildschirms → vorherige Seite
- [ ] AC-08: Wisch nach links → nächste Seite; Wisch nach rechts → vorherige Seite
- [ ] AC-09: Tastatur-Pfeiltasten → / ← und Leertaste → nächste Seite (Desktop/Laptop)
- [ ] AC-10: Mausrad runter/hoch → nächste/vorherige Seite (Desktop)
- [ ] AC-11: Seitenwechsel-Render-Zeit **< 16ms** (ein Frame bei 60fps) — gemessen von Touch-End bis vollständigem Bild auf Bildschirm
- [ ] AC-12: Tap in die **Mitte** des Bildschirms (±20% von Mitte in jede Richtung) → Overlay ein-/ausblenden, **keine** Seitennavigation

---

### US-03: Half-Page-Turn

**Als** Blasmusiker im Konzert  
**möchte ich** beim Umblättern gleichzeitig die untere Hälfte der aktuellen und die obere Hälfte der nächsten Seite sehen  
**damit** ich keine Noten verpasse und der Übergang fließend wirkt.

**Akzeptanzkriterien:**
- [ ] AC-13: Im Half-Page-Turn-Modus zeigt die obere Hälfte des Bildschirms die **untere Hälfte der aktuellen Seite** und die untere Hälfte des Bildschirms zeigt die **obere Hälfte der nächsten Seite**
- [ ] AC-14: Die Teilung ist durch eine **subtile horizontale Linie** markiert (kein scharfer Kontrast — dezent)
- [ ] AC-15: Half-Page-Turn ist im **Hochformat Standard** und deaktiviert im Querformat (dort gilt Zwei-Seiten-Modus)
- [ ] AC-16: Konfigurierbar: An/Aus per Kontextmenü im Spielmodus und in den Nutzereinstellungen
- [ ] AC-17: Teilungsverhältnis konfigurierbar: 40/60, 50/50, 60/40 — Default: 50/50
- [ ] AC-18: Half-Page-Turn funktioniert mit Fußpedal-Auslösung identisch wie mit Tap
- [ ] AC-19: Übergangsanimation: max. 200ms, einfaches Slide oder Cross-Fade — **kein Bounce, kein Spring**
- [ ] AC-20: Erste Seite eines Stücks und letzte Seite werden korrekt behandelt (kein "leere Hälfte"-Artefakt bei Seite 1 rückwärts oder letzter Seite vorwärts)

---

### US-04: Fußpedal (Bluetooth HID)

**Als** Blasmusiker  
**möchte ich** mit einem Bluetooth-Fußpedal durch meine Noten blättern  
**damit** ich beide Hände am Instrument behalten kann.

**Akzeptanzkriterien:**
- [ ] AC-21: Bluetooth HID-Geräte (Fußpedale, Page Turner) werden automatisch erkannt und registriert
- [ ] AC-22: Explizit getestete und bestätigte Geräte: **AirTurn BT-105**, **PageFlip Cicada**, **iRig BlueTurn** — andere HID-Tastaturen-Emulationen ebenfalls unterstützt
- [ ] AC-23: Default-Belegung: Rechts-Pedal = Nächste Seite, Links-Pedal = Vorherige Seite
- [ ] AC-24: Beim ersten Verbinden eines unbekannten Geräts: **Kalibrierungsschritt** — kurzer Dialog „Rechtes Pedal drücken → Aktion zuweisen, Linkes Pedal → Aktion zuweisen"
- [ ] AC-25: Konfigurierbare Tasten-Zuordnung (vorwärts, rückwärts, Half-Page-Turn umschalten) in den Gerät-Einstellungen
- [ ] AC-26: Fußpedal-Aktionen funktionieren auch im UI-Lock-Modus
- [ ] AC-27: Pairing-Anleitung mit gerätespezifischen Screenshots in den Gerät-Einstellungen (Bluetooth)
- [ ] AC-28: Verbindungsverlust wird stumm gemeldet (kurzes Symbol in der Statusleiste, kein Pop-up während des Spielens)
- [ ] AC-29: Verbindungslatenz Fußpedal → Seitenwechsel: **< 50ms** (HID-Protokoll-Latenz + Render)

---

### US-05: Nacht-/Bühnenmodus

**Als** Musiker bei Abendauftritten oder in dunklen Konzertsälen  
**möchte ich** die Noten auf schwarzem Hintergrund in weiß sehen  
**damit** ich nicht geblendet werde und die Noten trotzdem gut lesbar sind.

**Akzeptanzkriterien:**
- [ ] AC-30: Nachtmodus invertiert Notenbilder: schwarze Noten auf weißem Papier → weiße Noten auf schwarzem Hintergrund — **keine einfache CSS-Invertierung**, sondern kontrolliertes Rendering
- [ ] AC-31: Schnellumschalt-Button `🌙` in der unteren Overlay-Leiste — ein Tap ein/aus
- [ ] AC-32: Nachtmodus-Status wird als Nutzereinstellung gespeichert und beim nächsten Start übernommen
- [ ] AC-33: **Sepia-Modus** als dritte Option (warmer gelb-brauner Ton) — umschaltbar über Einstellungen
- [ ] AC-34: Im Nachtmodus: Helligkeit der Noten einstellbar (Slider in den Spielmodus-Einstellungen, Bereich: 60%–100%)
- [ ] AC-35: Annotationen passen ihre Farben an: Privat = Hellgrün, Stimme = Hellblau, Orchester = Hellorange (höherer Kontrast auf dunklem Hintergrund)
- [ ] AC-36: WCAG 2.1 **AAA** Kontrast in allen drei Modi (Standard, Nacht, Sepia)

---

### US-06: Stimme wechseln im Spielmodus

**Als** Musiker  
**möchte ich** jederzeit aus dem Spielmodus heraus die angezeigte Stimme wechseln  
**damit** ich im Probenalltag schnell zwischen Stimmen wechseln kann (z.B. als Einspringer).

**Akzeptanzkriterien:**
- [ ] AC-37: Stimme-Wechseln-Button `🎵 Stimme` in der unteren Overlay-Leiste → öffnet Bottom-Sheet
- [ ] AC-38: Bottom-Sheet zeigt zuerst **„Meine Instrumente"** (eigene Instrumente des Nutzers) mit visueller Hervorhebung der aktuell gewählten Stimme
- [ ] AC-39: Darunter getrennt: **„Andere Stimmen"** — alle weiteren verfügbaren Stimmen alphabetisch sortiert
- [ ] AC-40: Stimme wechseln lädt die neue Stimme auf **Seite 1** — Scroll-Position wird **nicht** beibehalten (Seiten-Nummerierung kann abweichen)
- [ ] AC-41: Animation beim Stimme-Wechsel: altes Blatt verschwindet → neues erscheint (300ms Cross-Fade)
- [ ] AC-42: Stimme wechseln setzt **nicht** die Standard-Stimme des Nutzers — nur temporär für diese Session

---

## 3. Technische Anforderungen & Rendering

### 3.1 PDF- und Bildanzeige

**Rendering-Stack:**
- **PDF:** `pdfrx` (alle Plattformen — Flutter-native, basierend auf PDFium/CGPDFDocument)
- **Bilder:** Flutter `Image` Widget mit Memory-Caching
- **Canvas-Layer:** Flutter `CustomPainter` für Annotationen-Overlay (SVG-Pfade mit relativen Positionen in %)

**Rendering-Anforderungen:**

| Metrik | Ziel | Messmethode |
|--------|------|-------------|
| Initial Page Load (erste Seite) | < 500ms | Zeit bis erstes Pixel sichtbar |
| Seitenwechsel (gecacht) | **< 16ms** (1 Frame @60fps) | Frame-Timing in Flutter DevTools |
| Seitenwechsel (nicht gecacht) | < 100ms | Zeit von Touch-End bis Bild sichtbar |
| Half-Page-Turn Animation | < 200ms | Animationsdauer |
| Fußpedal-Latenz | < 50ms | HID-Event bis Render-Start |
| Speicher pro Seite (gecacht) | < 4MB | Heap-Profil |
| Gleichzeitig gecachte Seiten | Min. 5 (aktuelle ±2) | Konfigurierbar |

**Pre-Caching-Strategie:**
```
[Seite N-2] [Seite N-1] [Seite N ← aktuell] [Seite N+1] [Seite N+2]
     gecacht      gecacht    im Viewport         pre-render    pre-render
```
- Beim Seitenwechsel: N+3 wird asynchron geladen, N-3 wird aus Cache verdrängt (LRU)
- Maximale Cache-Größe: 20MB (konfigurierbar je Gerätetyp)

### 3.2 Canvas für Annotationen-Overlay

```
Stack:
  └── PDF/Image Widget (Background)
  └── CustomPainter: AnnotationLayer (Foreground)
        └── SVG-Pfade mit rel. Koordinaten (x%, y%)
        └── Sichtbarkeits-Filter: Privat | Stimme | Orchester
```

- Annotationen werden als **separater Layer** gerendert — niemals ins PDF-Rendering eingebettet
- Positionen in **relativen Prozentwerten** (x%, y%) — resolutionsunabhängig
- Kein Re-Render des PDF bei Annotations-Änderungen (Layer unabhängig)

### 3.3 Auto-Rotation

**Algorithmus:**
1. Beim ersten Laden einer Seite: Notenlinie-Erkennung via einfacher Horizontale-Linie-Heuristik
2. Berechnung des Rotationswinkels (Abweichung von horizontal)
3. Rotation wird als Transform auf das Widget angewendet (nicht auf das Bild selbst)
4. Ergebnis wird gecacht — kein Re-Compute bei erneutem Anzeigen

**Akzeptanzkriterien Auto-Rotation:**
- [ ] AC-43: Notenlinien werden als horizontal erkannt (±3° Toleranz = keine Korrektur)
- [ ] AC-44: Korrektur bis ±45° Rotation möglich (schräg eingescannte Seiten)
- [ ] AC-45: Manuelles Override via Pinch-Rotation möglich (persönlicher Override, gespeichert pro Seite)
- [ ] AC-46: Auto-Rotation läuft **asynchron** — Seite wird zuerst unkorrigiert angezeigt, dann wird die Rotation sanft eingeblendet (< 300ms)

### 3.4 Auto-Zoom

**Algorithmus (aus ux-design.md §5.3):**
1. Seite in Originalauflösung laden
2. Seitenbreite auf verfügbare Viewport-Breite skalieren
3. Wenn Seite Hochformat und Viewport Querformat: auf Höhe skalieren
4. Notensystem (obere Linie bis untere Linie) soll mindestens 8px hoch sein
5. Nutzer kann mit Pinch-to-Zoom manuell anpassen (persönlicher Override, gespeichert pro Stück)

**Akzeptanzkriterien Auto-Zoom:**
- [ ] AC-47: Notenblatt füllt die volle Bildschirmbreite ohne horizontales Scrollen
- [ ] AC-48: Kein Inhalt wird abgeschnitten — alle Notenlinien sind sichtbar
- [ ] AC-49: Bei sehr schmalen Noten (A5-Format) auf breitem Tablet: Noten werden zentriert mit weißem/schwarzem Rand links/rechts — **kein** Über-Zoom
- [ ] AC-50: Manueller Pinch-to-Zoom Override wird pro Stück gespeichert
- [ ] AC-51: Zoom-Reset: Doppeltap setzt auf Auto-Zoom zurück

---

## 4. Kontextuelle Settings im Spielmodus

**Overlay-Architektur:**

```
Tap-Mitte → Overlay erscheint:

Oben (44px):
  ← Zurück  |  Stück 3/12  |  ⚙

Unten (44px):
  🎵 Stimme  |  🌙  |  🔒 Sperren
```

**⚙ Einstellungen (max. 5 Optionen — Entscheidung aus decisions.md):**

| # | Einstellung | Typ | Gespeichert als |
|---|-------------|-----|-----------------|
| 1 | Half-Page-Turn | Toggle An/Aus | Nutzer-Einstellung |
| 2 | Nachtmodus | Tri-State: Standard/Nacht/Sepia | Nutzer-Einstellung |
| 3 | Annotationslayer | Multi-Toggle: Privat/Stimme/Orchester | Nutzer-Session |
| 4 | Helligkeit | Slider 10%–100% | Gerät-Einstellung |
| 5 | Schriftgröße (Zoom) | Slider (Override) | Stück-spezifisch |

**Vererbungshierarchie (Konfigurationssystem §decisions.md):**
- Gerät > Nutzer > Kapelle > Default
- Erzwungene Kapellen-Einstellungen zeigen Schloss-Icon 🔒
- Farbkodierung: Blau (Kapelle), Grün (Nutzer), Orange (Gerät)

**Akzeptanzkriterien Overlay:**
- [ ] AC-52: Overlay erscheint mit Fade-In in 150ms — **kein** Slide, kein Bounce
- [ ] AC-53: Overlay verschwindet automatisch nach 4 Sekunden ohne Interaktion
- [ ] AC-54: Overlay-Tap stoppt den 4-Sekunden-Timer (solange der Nutzer interagiert, bleibt das Overlay)
- [ ] AC-55: Alle Overlay-Touch-Targets sind **mindestens 44×44px** — Buttons in der unteren Leiste mindestens **64px hoch**
- [ ] AC-56: Keine nicht-essenzielle Animation im Spielmodus (Performance-Modus-Regel aus decisions.md)

---

## 5. Verhalten je Gerät & Format

### 5.1 Phone Hochformat (< 600px Breite)

- **Default-Modus:** Half-Page-Turn aktiv
- **Tap-Zonen:** Links 40% / Rechts 60% (asymmetrisch — rechts häufiger)
- **Overlay:** Obere + untere Leiste (44px je)
- **Mindest-Touch-Target:** 64×64px für Seitenwechsel-Zonen

### 5.2 Tablet Querformat (600–1024px, Landscape)

- **Default-Modus:** Zwei-Seiten-Modus (zwei Notenblätter nebeneinander)
- **Tap-Zonen:** Linke Seite + Rechte Seite je als Tap-Zonen
- **Half-Page-Turn:** Deaktiviert (nicht sinnvoll bei 2-Up)
- **Mindestgröße für 2-Up:** 10" Diagonale — bei kleineren Geräten automatisch auf Single-Page

### 5.3 Desktop (> 1024px)

- **Default-Modus:** Zwei-Seiten + optionale Setlist-Sidebar (links, 240px)
- **Tastatur-Steuerung:** Pfeiltasten + Leertaste für Seitenwechsel
- **Maus:** Mausrad für Seitenwechsel

### 5.4 Orientation Change

**Edge Case: Gerät wird während des Spielens gedreht**

- [ ] AC-57: Orientation Change löst automatisch Layout-Wechsel aus (Hoch→Quer: Half-Page-Turn → Zwei-Seiten-Modus und umgekehrt)
- [ ] AC-58: Die aktuelle Seite bleibt nach Rotation korrekt sichtbar — kein Jump zu Seite 1
- [ ] AC-59: Rotation-Animation (System-Level) ist kurz und stört das Spielen minimal — App kann System-Rotation-Animation durch sofortiges Neu-Rendern ersetzen
- [ ] AC-60: Falls Gerät im UI-Lock-Modus: Orientation Change ist **erlaubt** (System-Level) — nur Tap-Zonen sind gesperrt

---

## 6. Edge Cases

### 6.1 Sehr große PDFs

| Szenario | Verhalten |
|----------|-----------|
| PDF > 50 Seiten | Pre-Caching auf ±5 Seiten beschränkt, explizite Speicher-Grenze |
| PDF > 200MB (unkomprimiert) | Warnung beim Download: „Großes Dokument (X MB) — Download fortsetzen?" |
| Einzelne Seite > 50MP (Bild) | Automatische Downsampling auf max. 4096×4096px — Original bleibt gespeichert |
| Korrupte PDF-Seite | Fehlerseite zeigt: „Seite konnte nicht geladen werden — [Überspringen]" — Spielmodus bleibt funktionsfähig |

### 6.2 Querformat/Hochformat-Wechsel während des Spielens

Behandelt in AC-57 bis AC-60 (Abschnitt 5.4).

### 6.3 Erste und letzte Seite

| Szenario | Verhalten |
|----------|-----------|
| Tap „zurück" auf Seite 1 | Keine Aktion + kurze haptische Vibration (wenn aktiviert) |
| Tap „weiter" auf letzter Seite | In Setlist: nächstes Stück laden; Einzelstück: kurze Vibration/Ton-Ende-Indikation |
| Half-Page-Turn auf Seite 1 | Obere Hälfte zeigt Leerraum (App-Hintergrund), untere Hälfte zeigt erste Seite — kein Crash |
| Half-Page-Turn auf letzter Seite | Obere Hälfte zeigt letzte Seite (untere Hälfte), untere Hälfte zeigt Leerraum |

### 6.4 Offline / Noten nicht geladen

| Szenario | Verhalten |
|----------|-----------|
| Noten nicht heruntergeladen | Spielmodus startet nicht — Fehlermeldung: „Noten nicht verfügbar. Bitte zuerst herunterladen." |
| Teilweiser Download (Seiten 1–5 vorhanden) | Spielmodus öffnet mit Seiten 1–5; fehlende Seiten zeigen Ladespinner |
| Verbindungsabbruch während des Spielens | Bereits gecachte Seiten bleiben verfügbar — kein Interrupt |

### 6.5 Stück ohne Stimme

| Szenario | Verhalten |
|----------|-----------|
| Kein Stimmen-Mapping vorhanden | Spielmodus zeigt die erste verfügbare Seite ohne Stimmen-Filter |
| Nutzer-Stimme nicht in diesem Stück vorhanden | Fallback-Logik (→ Stimmenauswahl-Spec #29) — zeigt nächstliegende Stimme |

### 6.6 Performance auf Mid-Range-Tablets

**Zielgerät:** Android Tablet mit Snapdragon 665 / 4GB RAM (Mid-Range 2023)

- [ ] AC-61: Seitenwechsel < 16ms auf Zielgerät (Flutter `--profile` Build)
- [ ] AC-62: Kein Frame-Drop (Jank) beim Öffnen des Overlays
- [ ] AC-63: Memory-Footprint im Spielmodus < 150MB (ohne Annotationen-Cache)
- [ ] AC-64: App-Start bis erste Note sichtbar: < 3 Sekunden (Cold Start auf Zielgerät)

---

## 7. API & Datenfluss

### 7.1 Endpunkte (Spielmodus)

| Methode | Endpunkt | Beschreibung |
|---------|----------|--------------|
| `GET` | `/api/v1/stuecke/{id}/stimmen/{stimmeId}/seiten` | Seiten-Metadaten + Download-URLs |
| `GET` | `/api/v1/stuecke/{id}/stimmen/{stimmeId}/seiten/{n}` | Einzelne Seite (Redirect zu CDN-URL) |
| `GET` | `/api/v1/stuecke/{id}/annotationen?stimmeId=&ebene=` | Annotationen für aktuelle Stimme/Ebene |
| `GET` | `/api/v1/nutzer/einstellungen/spielmodus` | Nutzer-spezifische Spielmodus-Einstellungen |
| `PUT` | `/api/v1/nutzer/einstellungen/spielmodus` | Spielmodus-Einstellungen speichern |

### 7.2 Offline-Verhalten

- Seiten werden bei Download als Binärdateien lokal gespeichert (SQLite via Drift + Dateisystem)
- Spielmodus liest primär aus lokalem Cache — Server wird nur für initiales Laden kontaktiert
- Annotationen werden lokal geschrieben und asynchron synchronisiert

### 7.3 Datenmodell (Spielmodus-relevant)

```
SpielmordusEinstellungen {
  nutzer_id: UUID
  half_page_turn: bool  [default: true]
  farbmodus: Enum { standard, nacht, sepia }  [default: standard]
  helligkeit: float  [0.6–1.0, default: 1.0]
  zoom_override: float?  [null = Auto-Zoom]
  annotations_layer_privat: bool  [default: true]
  annotations_layer_stimme: bool  [default: true]
  annotations_layer_orchester: bool  [default: true]
  updated_at: DateTime
}

SeitenCache {
  seite_id: UUID
  stueck_id: UUID
  stimme_id: UUID
  seiten_nummer: int
  datei_pfad: String  [lokaler Pfad]
  auto_rotation_winkel: float  [Grad, gecacht]
  zoom_override: float?  [null = Auto-Zoom, Nutzer-Override]
  cached_at: DateTime
  datei_groesse: int  [Bytes]
}
```

---

## 8. Abhängigkeiten

| Abhängigkeit | Typ | Status |
|-------------|-----|--------|
| #24 — UX Spielmodus (Wanda) | Informiert | 🟡 In Arbeit |
| #7 — Backend Scaffolding (Banner) | Blockierend | ✅ Done |
| #8 — Flutter Scaffolding (Romanoff) | Blockierend | ✅ Done |
| #29 — Stimmenauswahl-Spec | Eng gekoppelt | ✅ Diese Session |
| #32 — Annotationen UX (Wanda) | Informiert | 🟡 In Arbeit |
| Fußpedal-Spec (Teil dieser Spec) | Enthalten | — |

---

## 9. Definition of Done

### Funktional
- [ ] Alle 64 Akzeptanzkriterien aus Abschnitt 2–6 bestanden
- [ ] Half-Page-Turn funktioniert auf Phone Hochformat
- [ ] Zwei-Seiten-Modus funktioniert auf Tablet Querformat
- [ ] Fußpedal mit AirTurn BT-105 oder PageFlip Cicada getestet
- [ ] Nachtmodus korrekte Invertierung ohne CSS-Artefakte
- [ ] Stimme-Wechsel im Spielmodus ohne App-Neustart

### Performance
- [ ] Seitenwechsel < 16ms auf Mid-Range-Tablet (Snapdragon 665, 4GB RAM) im Profile-Build
- [ ] Kein Jank (> 16ms Frame) beim Overlay-Öffnen
- [ ] Memory < 150MB im Spielmodus (Profil-Messung)
- [ ] Cold Start bis erste Note < 3 Sekunden

### UX / Accessibility
- [ ] WCAG 2.1 AAA Kontrast in allen Farbmodi
- [ ] Alle Touch-Targets ≥ 44×44px (Overlay), ≥ 64px (Tap-Zonen)
- [ ] UI-Review durch Wanda abgenommen (#24)
- [ ] Test mit Handschuhen auf Tablet (Blasmusik-Szenario)

### Technisch
- [ ] Flutter DevTools: Keine Memory Leaks beim Seitenwechsel (100 Seiten durch-geblättert)
- [ ] pdfrx: Große PDFs (>50 Seiten, >100MB) getestet
- [ ] Orientation Change ohne App-Crash oder Seiten-Jump getestet
- [ ] Offline-Modus: Spielmodus funktioniert ohne Netzwerk

### Tests (Parker — Issue #26)
- [ ] Unit Tests: Pre-Caching-Logik, Auto-Zoom-Algorithmus, Fallback-Seite
- [ ] Widget Tests: Tap-Zonen (40/60), Half-Page-Turn Rendering, Overlay-Verhalten
- [ ] Integration Tests: Vollständiger Spielmodus-Flow (Bibliothek → Spielmodus → Stimme wechseln → zurück)
- [ ] Performance Tests: Seitenwechsel-Timing auf Zielgerät

---

*Erstellt von Hill (Product Manager) — Issue #25*  
*Wanda's UX-Spec (#24) fließt ein sobald verfügbar — AC werden ggf. aktualisiert*
