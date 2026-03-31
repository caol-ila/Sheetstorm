# Feature-Spezifikation: Auto-Scroll / Reflow

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Spielmodus-Spec #25, Konfigurationssystem)  
> **UX-Referenz:** `docs/ux-specs/auto-scroll.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Scroll-Algorithmen](#6-scroll-algorithmen)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Im Spielmodus scrollt die App automatisch durch die Noten — entweder BPM-basiert (synchron zum Metronom) oder manuell mit einstellbarer Geschwindigkeit. Der Musiker muss das Tablet nicht anfassen und kann sich vollständig auf das Spielen konzentrieren.

**Kernwert:** „Hände-frei spielen." Kein Wischen, kein Tap, kein Unterbrechen des Spiels. Besonders für Stehpulte, Orchesterproben und Marschmusik von hohem Wert.

### 1.2 Das Kernproblem

**Status Quo:**
- Musiker am Stehpult müssen zwischen Spielen und Blättern wechseln
- Fußpedale lösen nur Seitenumbrüche aus, kein kontinuierliches Scrollen
- BPM-basiertes Scrollen existiert in keiner etablierten App (Wettbewerbsvorteil)

**Sheetstorm-Lösung:**
- Kontinuierliches, gleichmäßiges Scrollen durch die Noten
- Optionale BPM-Kopplung: Scroll-Geschwindigkeit basiert auf Taktart + BPM + Noten-Layout
- Pause-Geste: Einmal tippen → Scroll pausiert, nochmals tippen → weiter

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Kontinuierliches Scrollen (manuell einstellbar) | Automatische Takt-Erkennung aus PDF (AI) |
| BPM-basiertes Scrollen (Kopplung an Metronom) | Face-Gesten-Steuerung |
| Scroll-Pause/Fortsetzen (Tap) | Eye-Tracking |
| Scroll-Geschwindigkeit anpassen während Scrollen | Automatische Notenumbruch-Generierung |
| Seiten-Übergang (Page-Flip Modus) vs. Continuous-Scroll | Noten-Reflow (Zeilenumbruch berechnen) |
| Einstellung: Vorlauf-Zeit (Scroll startet n Takte früher) | MIDI-Tempo-Input |
| Sync mit Echtzeit-Metronom (MS3 Feature) | Dirigenten-gesteuerter Auto-Scroll |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Solist (Klavier/Gitarre) | Üben zuhause | Hände-frei durch Stücke scrollen |
| Musiker (Blaskapelle) | Probe am Stehpult | BPM-synchron scrollen, kein Antippen |
| Dirigent | Partitur in der Probe | Manuell mit Scroll-Kontrolle |
| Musiker (Marsch) | Laufendes Konzert | Scroll läuft automatisch, keine Hände |

---

## 2. User Stories

### US-01: Manuellen Auto-Scroll aktivieren und steuern

> *Als Musiker möchte ich im Spielmodus einen automatischen Scroll mit einstellbarer Geschwindigkeit aktivieren, damit ich hände-frei durch meine Noten scrollen kann.*

**Akzeptanzkriterien:**
1. Spielmodus-Overlay enthält Auto-Scroll-Button (Pfeil-Icon)
2. Tap auf Button: Auto-Scroll aktiviert, Overlay verschwindet (Focus-First)
3. Scroll startet mit einstellbarer Verzögerung (Default: 3 Sekunden nach Aktivierung)
4. Während Scroll: einmal Tippen → Scroll pausiert mit Animation (Pause-Icon erscheint kurz)
5. Nochmals Tippen → Scroll weiter
6. Scrollen ist **kontinuierlich und gleichmäßig** (kein Rucken, kein Frame-Drop)
7. Scroll-Geschwindigkeit einstellbar: 3 Stufen-Preset (Langsam / Mittel / Schnell) + Fein-Slider (1–10 Skala)
8. Einstellungen persist per Stück (nicht global — jedes Stück hat eigene Scroll-Einstellung)
9. Auto-Scroll deaktiviert wenn Stück-Ende erreicht

---

### US-02: BPM-basiertes Scrollen (Metronom-Kopplung)

> *Als Musiker möchte ich, dass der Auto-Scroll an das Metronom des Dirigenten gekoppelt wird, damit ich automatisch im Takt der Probe durch die Noten scrolle.*

**Akzeptanzkriterien:**
1. Wenn Echtzeit-Metronom aktiv (MS3): Option „An Metronom koppeln" in Auto-Scroll-Einstellungen
2. Scroll-Geschwindigkeit berechnet sich aus: BPM × Taktart × Takte-pro-Systemzeile (manuell konfigurierbar)
3. Nutzer gibt an: **Anzahl Takte pro sichtbarer Zeile** (default: 4, einstellbar 1–8)
4. BPM-Änderung durch Dirigenten → Scroll-Geschwindigkeit passt sich sofort an (innerhalb 1 Beat)
5. Wenn Metronom gestoppt → Auto-Scroll pausiert automatisch
6. Wenn Metronom neugestartet → Auto-Scroll läuft weiter vom aktuellen Scroll-Position
7. Ohne laufendes Metronom: BPM manuell eingeben (eigenes lokales BPM für Scroll-Kalkulation)

---

### US-03: Scroll-Vorlauf konfigurieren

> *Als Musiker möchte ich einstellen können, dass der Scroll etwas früher beginnt als der aktuelle Takt anzeigt, damit ich die kommenden Noten bereits sehen kann.*

**Akzeptanzkriterien:**
1. Einstellung: **Vorlauf-Takte** (0, 1, 2, 4 Takte) — scrollt so, dass N Takte im Voraus sichtbar
2. Default: 2 Takte Vorlauf (Musiker braucht Vorschau)
3. Vorlauf-Konfiguration gilt nur im BPM-Modus
4. Im manuellen Modus: kein Vorlauf (scrollt genau so schnell wie eingestellt)

---

### US-04: Page-Flip Modus (ganzseitige Umblätterung)

> *Als Musiker möchte ich wählen können ob die App kontinuierlich scrollt oder seitenweise umblättert, weil ich je nach Notenformat das eine oder das andere bevorzuge.*

**Akzeptanzkriterien:**
1. Umschalter in Auto-Scroll-Einstellungen: **Kontinuierlich** vs. **Seitenweise**
2. Im Seitenweise-Modus: komplette Seite wird gezeigt, nach Ablauf der Seiten-Zeit → Flip-Animation zum nächsten Blatt
3. Seiten-Zeit berechnet aus: Takte × Taktdauer (BPM) ODER manuell konfigurierbare Sekunden pro Seite
4. Flip-Animation identisch zur manuellen Umblätterung (MS1 Spielmodus)
5. Pause/Weiter-Geste funktioniert auch im Seitenweise-Modus

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | Scroll startet innerhalb 100ms nach Aktivierung (nach Verzögerung) | UI-Test |
| AC-02 | Kontinuierliches Scrollen ohne sichtbares Rucken auf Referenzgeräten | Frame-Rate-Test: ≥ 58fps während Scroll |
| AC-03 | BPM-Änderung → Scroll-Geschwindigkeit angepasst innerhalb 1 Beat | Integration-Test mit Metronom |
| AC-04 | Pause-Geste reagiert in ≤ 100ms | UI-Reaktionszeit-Test |
| AC-05 | Scroll-Einstellung pro Stück persistent (überlebt App-Neustart) | DB-Test |
| AC-06 | Seitenweise-Modus: korrekte Seiten-Zeit-Kalkulation (BPM-basiert) | Unit-Test: BPM=120, 4/4, 4 Takte = 8 Sekunden/Seite |
| AC-07 | Vorlauf-Takte korrekt implementiert (Scroll-Position = aktuelle Takt + N Takte) | Unit-Test |
| AC-08 | Auto-Scroll läuft weiter wenn Display-Timeout aktiv (Wake Lock) | Geräte-Test |
| AC-09 | Memory: kein Leak bei langlaufendem Scroll (> 1 Stunde) | Memory-Test |
| AC-10 | Scroll funktioniert korrekt bei sehr langen Stücken (> 100 Seiten) | Integration-Test |

---

## 4. API-Contract

Auto-Scroll ist eine **client-seitige Feature** — kein Backend-API nötig für die Scroll-Logik selbst.

### 4.1 Scroll-Einstellungen (im Konfigurationssystem)

```
GET  /api/v1/nutzer/konfiguration
     → enthält: { spielmodus: { auto_scroll: { ... } } }

PUT  /api/v1/nutzer/konfiguration
     Body: { spielmodus: { auto_scroll: { modus: "bpm", takte_pro_zeile: 4, vorlauf_takte: 2 } } }
```

### 4.2 Stück-spezifische Scroll-Einstellung (Lokal in Drift)

Kein Server-API — scroll-Einstellungen pro Stück werden **lokal** in der Client-DB gespeichert.

---

## 5. Datenmodell

### 5.1 Lokale Client-DB (Drift/SQLite)

```sql
-- Scroll-Einstellungen pro Stück (lokal, kein Sync)
CREATE TABLE scroll_einstellungen (
  stueck_id           TEXT        PRIMARY KEY,  -- UUID als Text
  modus               TEXT        NOT NULL DEFAULT 'manuell',  -- 'manuell' | 'bpm' | 'seite'
  geschwindigkeit     REAL        NOT NULL DEFAULT 5.0,  -- 1.0–10.0 für manuell
  takte_pro_zeile     INTEGER     NOT NULL DEFAULT 4,    -- für BPM-Kalkulation
  vorlauf_takte       INTEGER     NOT NULL DEFAULT 2,    -- Vorschau-Takte
  startverzoegerung_s REAL        NOT NULL DEFAULT 3.0,  -- Sekunden bis Start
  metronom_kopplung   INTEGER     NOT NULL DEFAULT 0,    -- BOOLEAN: 0/1
  geaendert_am        INTEGER     NOT NULL               -- Unix timestamp
);
```

### 5.2 Konfigurationssystem-Erweiterung (MS1-kompatibel, globale Defaults)

```json
{
  "spielmodus": {
    "auto_scroll": {
      "standard_modus": "manuell",
      "standard_geschwindigkeit": 5.0,
      "standard_vorlauf_takte": 2,
      "metronom_kopplung_default": false
    }
  }
}
```

---

## 6. Scroll-Algorithmen

### 6.1 Manueller Scroll (Kontinuierlich)

```
Scroll-Geschwindigkeit (Pixel/Sekunde) = 
  (geschwindigkeit_stufe / 10) × MAX_SCROLL_SPEED

MAX_SCROLL_SPEED = Bildschirm-Höhe / 10  (1 Bildschirmhöhe pro 10 Sekunden bei Stufe 10)

Implementierung: Flutter AnimationController mit LinearCurve
Update: 60fps (kein Rucken), vsync-Aligned
```

### 6.2 BPM-basierter Scroll

```
Grundrechnung:
  Taktdauer (ms) = 60000 / BPM
  Takt-Zeile-Dauer (ms) = Taktdauer × Anzahl_Takte_pro_Zeile
  
Scroll-Höhe pro Zeile (px):
  ≈ (Noten-Seiten-Höhe_px / geschätzte_Zeilenanzahl)
  
Scroll-Geschwindigkeit (px/s) = Scroll-Höhe_pro_Zeile / (Takt-Zeile-Dauer / 1000)

Beispiel (120 BPM, 4/4, 4 Takte/Zeile, A4-Seite 1123px hoch, 10 Zeilen):
  Taktdauer = 500ms
  Zeilendauer = 500ms × 4 = 2000ms = 2s
  Zeilenhöhe = 1123 / 10 = 112px
  Scroll = 112 / 2 = 56 px/s
```

### 6.3 Vorlauf-Kompensation

```
Scroll-Position-Offset = Vorlauf_Takte × Zeilenhöhe
→ Scroll zeigt immer N Takte im Voraus
→ Kein Zurücksetzen — einfach Start-Position um Offset nach vorne
```

### 6.4 BPM-Änderung während laufendem Scroll

```
Neues BPM empfangen:
1. Neue Scroll-Geschwindigkeit berechnen (s.o.)
2. AnimationController.duration aktualisieren
3. Animation fortsetzen von aktueller Position
4. Kein Ruckeln, kein Reset — smooth transition
```

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 BPM-Modus aber kein Metronom aktiv
- **Szenario:** Nutzer hat BPM-Kopplung aktiviert, aber Dirigent hat Metronom noch nicht gestartet.
- **Verhalten:** Lokal eingegebenes BPM wird für Scroll verwendet. Hinweis: „Kein Metronom aktiv — lokales BPM: 120". Sobald Metronom startet → automatisch übernommen.

### 7.2 Stück endet mitten im Scroll
- **Szenario:** Auto-Scroll erreicht letzte Note auf letzter Seite.
- **Verhalten:** Scroll hält genau am Ende an (kein Over-Scroll). Toast: „Ende erreicht". Auto-Scroll deaktiviert sich automatisch.

### 7.3 Sehr kurze Stücke (1–2 Seiten)
- **Szenario:** Mitspieler hat nur ein kurzes 1-seitiges Stück.
- **Verhalten:** Auto-Scroll aktivierbar, aber sofort am Ende. Kein Fehler, kein Absturz.

### 7.4 PDF mit sehr unterschiedlichen Seitenhöhen (z.B. gemischte Quer-/Hochformat-Seiten)
- **Szenario:** Stück wechselt von Hochformat zu Querformat innerhalb des PDFs.
- **Verhalten:** Scroll-Geschwindigkeit wird pro Seite neu berechnet (Seitenhöhe variable). BPM-Modus: Zeilenhöhe neu kalibriert bei Seitenwechsel.

### 7.5 Nutzer scrollt manuell während Auto-Scroll läuft
- **Szenario:** Musiker wischt manuell während Auto-Scroll läuft.
- **Verhalten:** Manuelle Geste übernimmt sofort. Auto-Scroll pausiert. Toast: „Auto-Scroll pausiert — tippe zum Fortsetzen". Keine abrupten Sprünge.

### 7.6 Gerät-Rotation während Auto-Scroll
- **Szenario:** Tablet wird von Hochformat zu Querformat gedreht.
- **Verhalten:** Auto-Scroll pausiert während Rotation (< 300ms), dann weiter. Scroll-Position bleibt korrekt (relative Position, nicht absoluter Pixel-Wert).

### 7.7 App wechselt in Hintergrund
- **Szenario:** Musiker bekommt Anruf, App geht in Hintergrund.
- **Verhalten:** Auto-Scroll pausiert im Hintergrund (keine sinnlose CPU-Nutzung). Bei Rückkehr in Vordergrund: Toast „Auto-Scroll pausiert — tippe zum Fortsetzen".

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Spielmodus (MS1 #25) | Auto-Scroll ist Erweiterung des Spielmodus | MS1 |
| Konfigurationssystem (MS1) | Globale Defaults für Auto-Scroll | MS1 |

### 8.2 Optionale Kopplung (kein Block)

| Feature | Beziehung |
|---------|-----------|
| Echtzeit-Metronom (MS3) | BPM-Kopplung nutzt Metronom-BPM — aber Fallback auf lokales BPM |
| Fußpedal (MS1 Spielmodus) | Pedal kann alternativ für Pause/Weiter des Scrolls genutzt werden (via bestehende HID-Schnittstelle) |

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Manueller Auto-Scroll aktivierbar, Geschwindigkeit einstellbar
- [ ] US-02: BPM-basierter Scroll korrekt kalkuliert, Metronom-Kopplung
- [ ] US-03: Vorlauf-Takte konfigurierbar
- [ ] US-04: Seitenweise-Modus (Page-Flip) implementiert
- [ ] Alle AC-01 bis AC-10 erfüllt

### Qualität
- [ ] Unit-Tests: BPM-Scroll-Kalkulation (alle Taktarten × 5 BPM-Werte)
- [ ] Unit-Tests: Vorlauf-Kompensation
- [ ] Integration-Tests: Metronom-BPM-Wechsel → Scroll-Anpassung
- [ ] Widget-Test: Pause/Weiter-Geste
- [ ] Scroll-Performance: ≥ 58fps auf Referenzgerät (Snapdragon 665+)
- [ ] Memory-Test: Kein Leak bei 1-Stunden-Scroll
- [ ] Code Coverage ≥ 80%

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Scroll ist visuell flüssig (Animations-Review)
- [ ] Pause/Weiter klar kommuniziert (nicht verwirrend)
- [ ] Dark Mode korrekt

### Deployment
- [ ] Performance-Messung auf Referenzgerät dokumentiert
- [ ] Scroll-Konfiguration in Konfigurationssystem-Doku ergänzt
