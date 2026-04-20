# Feature-Spezifikation: Annotationen (3 Sichtbarkeitsebenen)

> **Issue:** #38  
> **Meilenstein:** MS1  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Implementierung  
> **Depends on:** #37 (UX Annotationen — Wanda), #25 (Spielmodus-Spec), #29 (Stimmenauswahl-Spec)  
> **Blocked by:** —  
> **UX-Referenz:** `docs/ux-specs/annotationen.md`

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien)
4. [API-Spezifikation](#4-api-spezifikation)
5. [Datenmodell](#5-datenmodell)
6. [Sichtbarkeitsregeln & Berechtigungen](#6-sichtbarkeitsregeln--berechtigungen)
7. [Sync-Verhalten (Real-time)](#7-sync-verhalten-real-time)
8. [Edge Cases & Fehlerszenarien](#8-edge-cases--fehlerszenarien)
9. [Abhängigkeiten & Nicht-im-Scope](#9-abhängigkeiten--nicht-im-scope)
10. [Definition of Done](#10-definition-of-done)

---

## 1. Feature-Überblick

### Beschreibung

Annotationen sind das **Notizen-Werkzeug** für Sheetstorm. Sie ermöglichen Musikern, ihre Noten zu kommentieren — mit **drei fundamentalen Sichtbarkeitsebenen**, die die zentrale Designentscheidung darstellen:

- **Privat (Blau):** Nur für meine Augen — persönliche Atemzeichen, Fingersätze, Übe-Notizen
- **Stimme (Grün):** Sichtbar und bearbeitbar für alle mit meiner Stimme — Register-Absprachen
- **Orchester (Orange):** Sichtbar für alle Kapellenmitglieder; bearbeitbar nur für Dirigent/Admin — Dirigenten-Anweisungen

**Designprinzip:** „Farbe = Reichweite". Mit einem Blick sieht der Musiker, wen seine Annotation erreicht. Das ist das Alleinstellungsmerkmal von Sheetstorm gegenüber Konkurrenz (Newzik, forScore, MobileSheets).

### Ziel

Musiker sollen während des Spielens oder der Probe **nahtlos ihre Noten annotieren** können — ohne Performance-Einbußen. Annotationen sollen sich in den Spielmodus integrieren wie ein natürliches Werkzeug, nicht wie ein Feature.

### Scope MS1 (In-Scope)

- ✅ SVG-basierte Annotationen mit relativen Positionen (% der Seitengröße)
- ✅ **3 Sichtbarkeitsebenen:** Privat / Stimme / Orchester
- ✅ Werkzeuge: Stift, Text, Textmarker, Stempel, Radierer, Auswahl
- ✅ Stylus-First mit automatischer Stift-Erkennung
- ✅ Long-Press zum Aktivieren des Annotationsmodus
- ✅ Ebenen-Picker (Flyout zur Wahl der Sichtbarkeit)
- ✅ Undo / Redo
- ✅ Sync via SignalR für Stimmen- und Orchester-Ebene
- ✅ Layer-Toggle: Annotations-Ebenen ein-/ausblendbar im Spielmodus
- ✅ Farb-Kodierung mit Icons für Barrierefreiheit
- ✅ Annotation löschen + Long-Press-Kontextmenü
- ✅ Datenbankspeicherung (lokal + Server für Stimme/Orchester)

### Out-of-Scope MS1 (Später)

- ❌ Audio-Notizen (Sprachaufnahmen)
- ❌ Freihand-zu-Text-OCR (Handschrifterkennung)
- ❌ Kollaboratives Editing (mehrere gleichzeitig auf einer Annotation)
- ❌ Export von Annotationen als PDF
- ❌ Annotations-Suche
- ❌ Spezielle Bogenzeichen (Streicher-Bogen-Symbole) — nur allgemeine Stempel
- ❌ Seiten-Verknüpfung (Annotations mit verknüpften Aktionen)

---

## 2. User Stories

### US-01: Private Notizen schreiben

> **Als** Musiker  
> **möchte ich** schnell private Notizen (Atemzeichen, Fingersätze) in meine Noten schreiben  
> **damit** ich meine persönlichen Helfer habe und andere Musiker sie nicht sehen.

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert offline, kein Server nötig
- **N**egotiable: Verschiedene Werkzeuge optional
- **V**aluable: Fundamentales Nutzer-Bedürfnis
- **E**stimatable: ~1–2 Sprints
- **S**mall: Nur Privat-Ebene + Speichern
- **T**estable: ✅ Annotation existiert lokal, wird nicht synchronisiert

**Akzeptanzkriterien:**
1. Langdrücken (600ms) auf eine Notenseite aktiviert den Annotationsmodus
2. Toolbar erscheint mit Ebenen-Picker, standardmäßig auf "Privat" (blau)
3. Stift-Werkzeug ist vorausgewählt
4. Zeichnungen mit dem Stift werden sofort auf der Seite sichtbar
5. Text-Werkzeug erlaubt Eingabe von bis zu 200 Zeichen
6. Textmarker-Werkzeug erzeugt halbtransparente Highlights (40% Opazität)
7. Private Annotationen werden **nur lokal** in SQLite gespeichert
8. Private Annotationen werden synchronisiert zwischen Geräten desselben Nutzers (via Konto-Cloud)
9. Nach Beenden des Annotationsmodus wird die Annotation sofort persistent
10. Undo-Stack funktioniert unbegrenzt während der Session

---

### US-02: Stimmen-Annotationen schreiben & synchronisieren

> **Als** Registerführer  
> **möchte ich** Anmerkungen schreiben, die alle mit meiner Stimme sehen  
> **damit** wir als Register Phrasierung und Dynamik absprechen können.

**Kriterien (INVEST):**
- **I**ndependent: Läuft unabhängig von Orchester-Layer
- **N**egotiable: Automatische Broadcastings nur über Signal
- **V**aluable: Kernfeature für Ensemble-Proben
- **E**stimatable: ~2 Sprints (Sync-Logik, Server-Broadcasting)
- **S**mall: Fokus auf Sync-Verhalten
- **T**estable: ✅ Mehrere Nutzer mit gleicher Stimme sehen die Annotation in Echtzeit

**Akzeptanzkriterien:**
1. Im Annotationsmodus kann der Nutzer die Ebene auf "Stimme" (grün) wechseln
2. Eine Annotation auf Stimme-Ebene wird lokal sofort gespeichert
3. Ein SignalR-Event wird sofort an den Server gesendet: `{type: "annotation_added", layer: "voice", voiceId: "...", stuckId: "...", seitenNr: "...", data: SVG-Pfad}`
4. Der Server broadcastet das Event an alle Nutzer mit identischer `voiceId` in der gleichen Kapelle
5. Empfänger-Clients rendern die neue Annotation in Echtzeit (< 500ms Latenz in LAN-Umgebung)
6. Keine Toast-Benachrichtigung beim Empfang — stille Anzeige
7. Annotation kann von jedem mit der gleichen Stimme bearbeitet oder gelöscht werden
8. Löschen einer Stimmen-Annotation sendet Delete-Event an alle Empfänger
9. Bei Offline: Annotation wird lokal gecacht, bei nächster Verbindung synchronisiert

---

### US-03: Orchester-Anweisungen (Dirigent)

> **Als** Dirigent  
> **möchte ich** während der Probe schnell Anweisungen in die Noten schreiben  
> **damit** alle meine Hinweise (Tempo, Dynamik, Wiederholungen) sehen.

**Kriterien (INVEST):**
- **I**ndependent: Nur für Dirigent/Admin-Rollen
- **N**egotiable: Berechtigungen konfigurierbar
- **V**aluable: Kritisch für Probenleitung
- **E**stimatable: ~2 Sprints
- **S**mall: Broadcasting-Logik ähnlich Stimme-Layer
- **T**estable: ✅ Alle Kapellenmitglieder sehen die Orchester-Annotation

**Akzeptanzkriterien:**
1. Im Annotationsmodus kann nur Dirigent/Admin die Ebene auf "Orchester" (orange) setzen
2. Andere Rollen sehen die Orchester-Ebene ausgegraut + Schloss-Icon
3. Orchester-Annotation wird sofort lokal gespeichert
4. SignalR-Event wird an Server gesendet: `{type: "annotation_added", layer: "orchestra", kapellenId: "...", ...}`
5. Server broadcastet an **alle aktiven Mitglieder** der Kapelle
6. Musiker können Orchester-Annotationen **nicht löschen**, nur ausblenden
7. Nur Dirigent/Admin können eine Orchester-Annotation löschen (mit Bestätigung)
8. Musiker können Orchester-Layer im Spielmodus-Overlay ein-/ausblenden (non-destruktiv)

---

### US-04: Annotations-Werkzeuge & Stempel

> **Als** Musiker  
> **möchte ich** verschiedene Markierungstypen verwenden (Stift, Marker, Stempel)  
> **damit** meine Annotationen klar und professionell sind.

**Kriterien (INVEST):**
- **I**ndependent: Jedes Werkzeug ist unabhängig
- **N**egotiable: Komplexere Werkzeuge optional
- **V**aluable: UX-Verbesserung durch Vielfalt
- **E**stimatable: ~1 Sprint
- **S**mall: Toolbox ist isoliert
- **T**estable: ✅ Jedes Werkzeug erzeugt die erwartete Annotation

**Akzeptanzkriterien:**
1. **Stift (✏️):** Freihand-Zeichnungen, drucksensitiv wenn Hardware unterstützt
2. **Text (📝):** Textnotizen bis 200 Zeichen, platzierbar per Tap
3. **Textmarker (🖊):** Halbtransparentes Highlight (40%), Farbe = Ebene
4. **Stempel (🎵):** Vordefinierte Symbole: Dynamik (pp, p, mp, mf, f, ff, fff), Artikulation (., >, ^, ~), Navigation (D.C., D.S., Coda), Atemzeichen (', V, ,)
5. **Radierer (🧹):** Freihand-Radierer, nur für eigene Annotationen
6. **Auswahl (↕️):** Selektieren, verschieben, kopieren von Annotation-Elementen
7. Strichparameter: Dicke (4 Voreinstellungen), Opazität einstellbar
8. Apple-Pencil-Doppeltipp wechselt zwischen letztem Werkzeug und Radierer
9. Werkzeugauswahl wird in der Session beibehalten

---

### US-05: Layer-Toggle im Spielmodus

> **Als** Dirigent vor einem Konzert  
> **möchte ich** die Annotations-Layer ausblendbar machen  
> **damit** die Musiker während des Auftritts saubere Noten sehen.

**Kriterien (INVEST):**
- **I**ndependent: Non-destruktiv, keine Datenverluste
- **N**egotiable: Konfigurierbar pro Stück oder global
- **V**aluable: Qualitäts-Feature für Auftritte
- **E**stimatable: ~1 Sprint
- **S**mall: Nur Render-Logik beeinflussend
- **T**estable: ✅ Toggles funktionieren, Daten bleiben erhalten

**Akzeptanzkriterien:**
1. Im Spielmodus-Overlay gibt es ein Annotations-Icon (🎨 oder Ebenen-Symbol)
2. Tap öffnet Flyout mit 3 Toggles: Privat, Stimme, Orchester
3. Jedes Toggle zeigt Icon + Label + visuellen Zustand (checkmark / leer)
4. Ein Tap togglet die Sichtbarkeit einzelner Ebene
5. Sichtbarkeitszustand wird pro Stück gespeichert (nicht global)
6. Ausblenden ≠ Löschen — Daten bleiben auf Server/lokal erhalten
7. Nächster Stück-Aufruf zeigt wieder alle Layer sichtbar (Default) — oder speichert als Nutzer-Preference
8. Musiker darf alle Ebenen ausblenden, sieht dann nur die reinen Noten

---

## 3. Akzeptanzkriterien

### Rendering & Performance

| # | Kriterium | Ziel | Messmethode |
|---|-----------|------|-------------|
| AC-01 | Stift-Latenz (Touch bis Render) | < 50ms | Frame-Timing Flutter DevTools |
| AC-02 | Seitenwechsel mit Annotations-Layer | < 16ms (1 Frame @60fps) | DevTools, ≥ Mid-Range-Tablet |
| AC-03 | Annotations-Cache pro Seite | < 2MB | Heap-Profil |
| AC-04 | SVG-Rendering (100 Elemente) | < 50ms | Benchmark-Test |
| AC-05 | Undo/Redo-Operation | < 200ms | Zeitmessung |

### Funktionalität Stift & Werkzeuge

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-06 | Stift-Linie ist kontinuierlich | Keine Lücken bei normaler Schreibgeschwindigkeit |
| AC-07 | Drucksensitivität | Liniendicke variiert mit Druck (falls Hardware unterstützt) |
| AC-08 | Textmarker-Opazität | Exakt 40% — Test mit Farbmeter |
| AC-09 | Stempel-Größe anpassbar | Drag am Handle, 0.5x bis 2x Standardgröße |
| AC-10 | Radierer funktioniert nur auf eigenen Annotations | Stimmen/Orchester-Ebenen sind geschützt |

### Sichtbarkeitsebenen

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-11 | Privat-Annotation sichtbar nur für Schreiber | Andere Nutzer sehen sie nicht im Overlay |
| AC-12 | Stimme-Annotation sichtbar für alle mit gleicher Stimme | Kapellenübergreifend? Nein — nur gleiche Kapelle |
| AC-13 | Orchester-Annotation sichtbar für alle in Kapelle | Auch Musiker ohne Stimmen-Match sehen es |
| AC-14 | Ebene-Wechsel ist möglich | Long-Press auf Annotation → "Ebene wechseln" → wählt Ziel |
| AC-15 | Farb-Kodierung korrekt | Privat=Blau RGB(59,130,246), Stimme=Grün RGB(34,197,94), Orchester=Orange RGB(249,115,22) |

### Sync & Real-time (SignalR)

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-16 | Stimmen-Annotation End-to-End-Latenz | < 500ms in LAN-Umgebung |
| AC-17 | Orchester-Annotation Broadcasting | An alle Kapellenmitglieder, nicht nur aktive Spielmodus-Nutzer |
| AC-18 | Offline-Verhalten (Privat) | Funktioniert offline, Sync bei Verbindung |
| AC-19 | Offline-Verhalten (Stimme/Orchester) | Lokal gecacht, bei nächster Verbindung hochgeladen |
| AC-20 | Conflict Resolution | Gleichzeitiges Bearbeiten → Last-Write-Wins mit Timestamp |
| AC-21 | Disconnect-Handling | Automatischer Reconnect, kein manueller Reload nötig |

### Undo / Redo

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-22 | Undo-Stack | Unbegrenzt während Session |
| AC-23 | Undo bei Stimmen-Annotation | Sendet Delete-Event an andere Nutzer |
| AC-24 | Undo bei Orchester-Annotation | Nur Dirigent kann undo, andere sehen sofortige Anzeige |
| AC-25 | Toast nach Undo | "Rückgängig gemacht" 2 Sekunden, nicht blockierend |
| AC-26 | Undo nach App-Neustart | Letzter persistierter Zustand, nicht volle History |

### Barrierefreiheit & Design

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-27 | Farbe + Icon + Pattern | Nicht nur Farbe zur Unterscheidung |
| AC-28 | WCAG 2.1 AAA Kontrast | Alle Layer-Farben auch auf Nachtmodus-Hintergrund lesbar |
| AC-29 | Touch-Targets | ≥ 44×44px für alle Toolbar-Buttons |
| AC-30 | Annotationsmodus-Beendigung | 4 Wege: [Fertig]-Button, 3-Finger-Tap, Stift weglegen, 3min Auto-Exit |

### UX & Integration

| # | Kriterium | Anforderung |
|---|-----------|-------------|
| AC-31 | Annotations-Icon in Overlay | Sichtbar in Spielmodus-Overlay, ändert Puls bei neuer Orchester-Annotation |
| AC-32 | Layer-Toggle funktioniert non-destruktiv | Ausblenden speichert Zustand, Löschen ist explizit |
| AC-33 | Ebenen-Flyout bei Long-Press auf Annotation | 4 Optionen: Bearbeiten, Kopieren, Ebene wechseln, Löschen |
| AC-34 | Bestätigung vor Löschung | Nur für Stimmen/Orchester-Annotationen (destructive für andere) |
| AC-35 | Nachtmodus mit Annotationen | Farben sichtbar auf schwarzem Hintergrund |

---

## 4. API-Spezifikation

### REST Endpoints

#### 4.1 Annotation erstellen

**POST** `/api/stuecke/{stuckId}/annotationen`

```json
{
  "ebene": "privat|stimme|orchester",
  "seiteNr": 3,
  "svgPfad": "M10,10 L20,20 L30,10",
  "bbox": { "x": 10.5, "y": 12.3, "width": 40, "height": 25 },
  "werkzeugTyp": "stift|text|marker|stempel|radierer",
  "text": "optional für Text-Werkzeug",
  "farbWert": "optional — wird von Ebene bestimmt"
}
```

**Response (201 Created):**
```json
{
  "id": "annot_abc123def456",
  "ebene": "privat",
  "seiteNr": 3,
  "erstellt": "2026-03-28T14:32:10Z",
  "ersteller": {
    "id": "user_123",
    "name": "Max Mustermann",
    "stimme": "2. Klarinette"
  },
  "svgPfad": "M10,10 L20,20 L30,10",
  "bbox": { "x": 10.5, "y": 12.3, "width": 40, "height": 25 },
  "sichtbarkeitEbene": "privat",
  "kannBearbeitet": true,
  "kannGelöscht": true
}
```

**Berechtigungslogik:**
- Privat: Immer erlaubt für logged-in User
- Stimme: Nur für User mit dieser Stimme in dieser Kapelle
- Orchester: Nur für Dirigent/Admin

---

#### 4.2 Annotation abrufen (Seite)

**GET** `/api/stuecke/{stuckId}/seiten/{seiteNr}/annotationen?ebenen=privat,stimme,orchester`

**Response (200 OK):**
```json
{
  "seiteNr": 3,
  "annotationen": [
    {
      "id": "annot_abc123def456",
      "ebene": "privat",
      "ersteller": {
        "id": "user_123",
        "name": "Max Mustermann"
      },
      "svgPfad": "M10,10 L20,20 L30,10",
      "bbox": { "x": 10.5, "y": 12.3, "width": 40, "height": 25 },
      "werkzeugTyp": "stift",
      "erstellt": "2026-03-28T14:32:10Z",
      "kannBearbeitet": true,
      "kannGelöscht": true
    },
    {
      "id": "annot_def456ghi789",
      "ebene": "stimme",
      "ersteller": {
        "id": "user_456",
        "name": "Anna Schmidt"
      },
      "svgPfad": "...",
      "werkzeugTyp": "text",
      "text": "mf → f",
      "erstellt": "2026-03-28T13:15:45Z",
      "kannBearbeitet": true,
      "kannGelöscht": true
    }
  ]
}
```

**Filterung:** Query-Parameter `ebenen` bestimmt, welche Layer abgerufen werden. Standard: alle für den Nutzer sichtbaren.

---

#### 4.3 Annotation löschen

**DELETE** `/api/annotationen/{annotationId}`

**Response (204 No Content)**

**Berechtigungslogik:**
- Privat: Nur Ersteller
- Stimme: Jeder mit dieser Stimme
- Orchester: Nur Dirigent/Admin
- Toast-Bestätigung für Stimmen/Orchester (destructive)

---

#### 4.4 Annotation bearbeiten (Ebene wechseln)

**PUT** `/api/annotationen/{annotationId}`

```json
{
  "ebene": "privat|stimme|orchester"
}
```

**Response (200 OK):** Aktualisierte Annotation

**Logik:** Verschiebt Annotation in andere Ebene, sendet SignalR-Event an betroffene Nutzer.

---

### SignalR Events (Real-time)

#### Ausgehend (Client → Server → Clients)

**Event: annotation_added**
```json
{
  "type": "annotation_added",
  "annotationId": "annot_abc123",
  "stuckId": "stuck_001",
  "seiteNr": 3,
  "ebene": "stimme",
  "ersteller": {
    "id": "user_123",
    "name": "Max Mustermann",
    "stimme": "2. Klarinette"
  },
  "svgPfad": "M10,10 L20,20 L30,10",
  "bbox": { "x": 10.5, "y": 12.3, "width": 40, "height": 25 },
  "werkzeugTyp": "stift",
  "erstellt": "2026-03-28T14:32:10Z"
}
```

**Event: annotation_deleted**
```json
{
  "type": "annotation_deleted",
  "annotationId": "annot_abc123",
  "ebene": "stimme",
  "stuckId": "stuck_001",
  "seiteNr": 3,
  "loschendVon": {
    "id": "user_123",
    "name": "Max Mustermann"
  }
}
```

**Event: annotation_layer_changed**
```json
{
  "type": "annotation_layer_changed",
  "annotationId": "annot_abc123",
  "vonEbene": "stimme",
  "zuEbene": "orchester",
  "aendertVon": {
    "id": "user_123",
    "name": "Max Mustermann"
  }
}
```

**Broadcasting-Logik:**
- Stimme-Events: An alle User mit `voiceId` in der Kapelle
- Orchester-Events: An alle User in der Kapelle
- Privat-Events: Nur lokal, kein SignalR
- Verwaiste Nutzer (nicht in Kapelle mehr): Keine Events

---

## 5. Datenmodell

### Tabelle: `annotationen`

```sql
CREATE TABLE annotationen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stuck_id UUID NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
  seite_nr INT NOT NULL,
  ebene VARCHAR(50) NOT NULL CHECK (ebene IN ('privat', 'stimme', 'orchester')),
  ersteller_id UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  
  -- SVG-Daten
  svg_pfad TEXT NOT NULL,
  
  -- Bounding Box (relative Positionen in %)
  bbox_x DECIMAL(5,2) NOT NULL,
  bbox_y DECIMAL(5,2) NOT NULL,
  bbox_width DECIMAL(5,2) NOT NULL,
  bbox_height DECIMAL(5,2) NOT NULL,
  
  -- Werkzeug-Metadaten
  werkzeug_typ VARCHAR(50) NOT NULL CHECK (werkzeug_typ IN ('stift', 'text', 'marker', 'stempel', 'radierer', 'auswahl')),
  text_inhalt VARCHAR(200),
  farb_wert VARCHAR(10) NOT NULL, -- Hex, z.B. "#3B82F6"
  
  -- Stempel-spezifisch
  stempel_kategorie VARCHAR(50),
  stempel_wert VARCHAR(50),
  
  -- Timestamps
  erstellt_am TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  aktualisiert_am TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Indizes
  INDEX idx_stuck_seite (stuck_id, seite_nr),
  INDEX idx_ersteller (ersteller_id),
  INDEX idx_ebene (ebene),
  UNIQUE KEY uk_annotation (id)
);
```

### Tabelle: `annotation_undo_stack`

```sql
CREATE TABLE annotation_undo_stack (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  stuck_id UUID NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
  
  -- Undo-Stack als JSON-Array (Operationen)
  undo_stack JSONB NOT NULL, -- [{op: "create", annotationId: "...", data: {...}}, ...]
  
  -- Zeigt auf aktuellen Index im Stack
  stack_index INT NOT NULL DEFAULT 0,
  
  -- Lifetime: Nach App-Neustart verworfen
  session_id VARCHAR(255) NOT NULL,
  erstellt_am TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_nutzer_session (nutzer_id, session_id)
);
```

### Tabelle: `annotation_sichtbarkeit` (Pro-Stück-Preference)

```sql
CREATE TABLE annotation_sichtbarkeit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  stuck_id UUID NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
  
  privat_sichtbar BOOLEAN DEFAULT true,
  stimme_sichtbar BOOLEAN DEFAULT true,
  orchester_sichtbar BOOLEAN DEFAULT true,
  
  aktualisiert_am TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY uk_nutzer_stuck (nutzer_id, stuck_id)
);
```

### Tabelle: `annotation_audit_log`

```sql
CREATE TABLE annotation_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  annotation_id UUID NOT NULL,
  stuck_id UUID NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
  aktion VARCHAR(50) NOT NULL CHECK (aktion IN ('erstellt', 'geloescht', 'ebene_gewechselt', 'undone', 'redone')),
  nutzer_id UUID NOT NULL REFERENCES nutzer(id) ON DELETE CASCADE,
  
  -- Snapshot vor der Änderung (JSON)
  snapshot_vorher JSONB,
  
  -- Neue Werte (JSON)
  snapshot_nachher JSONB,
  
  erstellt_am TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_annotation (annotation_id),
  INDEX idx_stuck (stuck_id),
  INDEX idx_aktion (aktion)
);
```

---

## 6. Sichtbarkeitsregeln & Berechtigungen

### Matrix: Wer sieht was?

| Ebene | Schreiber | Andere mit gleicher Stimme | Dirigent/Admin | Andere Musiker |
|-------|-----------|----------------------------|----------------|----------------|
| **Privat** | ✅ Ja | ❌ Nein | ❌ Nein | ❌ Nein |
| **Stimme** | ✅ Ja (Lesen & Schreiben) | ✅ Ja (Lesen & Schreiben) | ✅ Ja (Lesen, Schreiben nur wenn gleiche Stimme) | ❌ Nein |
| **Orchester** | ✅ Ja (nur Dirigent/Admin) | ✅ Ja (Lesen nur) | ✅ Ja (Lesen & Schreiben) | ✅ Ja (Lesen nur) |

### Regeln

1. **Privat-Ebene:**
   - Nur lokal gespeichert (keine Server-Sync)
   - Wird zwischen eigenen Geräten synchronisiert via Cloud-Backup
   - Für Aushilfen (mit temporärem Token): Privat bleibt auf dem Gerät

2. **Stimme-Ebene:**
   - Stimme bestimmt sich aus `nutzer.standard_stimme_pro_kapelle`
   - Wenn Nutzer mehrere Stimmen spielen kann: Annotation gehört zur **gerade aktiven** Stimme
   - Nur sichtbar für Nutzer mit **exakt gleicher** Stimmen-ID in der **gleichen Kapelle**
   - Jeder mit dieser Stimme kann bearbeiten/löschen

3. **Orchester-Ebene:**
   - Nur Dirigent oder Admin darf schreiben
   - Alle Kapellenmitglieder dürfen lesen
   - Read-Only für normale Musiker
   - Musiker können ausblenden, aber nicht löschen
   - Löschen sendet Notification an alle (subtile Pulsierung)

4. **Kapellen-Isolation:**
   - Annotationen gehören zu `stuck_id`, der zu einer Kapelle gehört
   - Nutzer kann nur Annotationen sehen, wenn er Mitglied der Kapelle ist
   - Server-Validierung: `SELECT kapelle_id FROM stuecke WHERE id = $1` vor Zugriff

5. **Rollen-Check (Server-seitig):**
   ```
   GET /api/stuecke/{stuckId}/annotationen:
     → Vor Query: `rolle_in_kapelle(user_id, kapelle_id)` prüfen
     → Filter SELECT nach Sichtbarkeitsergebnis (Privat nur wenn User = Ersteller, etc.)
   
   POST /api/annotationen:
     → Vor INSERT: Ebene-Berechtigungsprüfung
     → Privat: Immer OK
     → Stimme: `user_stimme_id == annotation_ebene_stimme_id` AND `user_kapelle_id == stuck_kapelle_id`
     → Orchester: `user_rolle IN ('dirigent', 'admin')`
   ```

---

## 7. Sync-Verhalten (Real-time)

### 7.1 Privat — Lokale + Cloud-Backup

1. **Schreiben (Lokal):** Annotation wird sofort in lokaler SQLite gespeichert
2. **Render:** SVG-Layer wird sofort auf dem Bildschirm angezeigt
3. **Cloud-Sync:** Im Hintergrund (nicht blockierend) zum Server
4. **Multi-Gerät:** Wenn Nutzer auf Gerät B einloggt, werden Privat-Annotationen vom Cloud-Backup abgerufen
5. **Offline:** Funktioniert vollständig offline, Sync bei Verbindung

---

### 7.2 Stimme — Real-time SignalR Broadcast

**Happy Path:**

```
Nutzer A zeichnet auf Stimme-Ebene
  ↓
Lokal gespeichert (sofort sichtbar)
  ↓
SignalR Event: annotation_added
  ↓
Server validiert: Nutzer A hat diese Stimme in dieser Kapelle
  ↓
Server broadcastet an alle User mit gleicher Stimme + Kapelle
  ↓
Nutzer B+C (gleiche Stimme) erhalten Event
  ↓
SVG-Layer wird sofort aktualisiert (kein Toast, kein Sound)
```

**Latenz-Ziel:** < 500ms End-to-End in LAN (W-LAN in Probenraum)

**Offline-Szenario:**
- Annotation wird lokal gecacht
- Bei Reconnect: Wird asynchron hochgeladen
- Andere Nutzer sehen sie nach dem Sync

**Konflikt-Auflösung:**
- Gleichzeitige Edits → Last-Write-Wins basierend auf Server-Timestamp
- Beide Versionen können im Audit-Log abgerufen werden

---

### 7.3 Orchester — Broadcast an alle

Identisch wie Stimme, aber mit erweitererter Broadcasting:

```
Dirigent schreibt auf Orchester-Ebene
  ↓
Lokal gespeichert
  ↓
SignalR Event: annotation_added (layer: "orchester")
  ↓
Server validiert: User hat Dirigent/Admin-Rolle
  ↓
Server broadcastet an ALLE Mitglieder der Kapelle
  ↓
Auch offline-Nutzer erhalten das Event beim nächsten Connect
```

**Besonderheit:** Neue Orchester-Annotation → Subtile Pulsierung des Annotations-Icons (nur Pulsierung, kein Toast, kein Sound)

---

### 7.4 Delete-Handling im Sync

**Wenn Annotation gelöscht wird:**
- `annotation_deleted` Event wird broadcastet
- Empfänger entfernen die Annotation sofort aus ihrem Layer
- Wenn User gerade diese Annotation bearbeitet: Toast "Annotation wurde von anderem Nutzer gelöscht"
- Undo des Löschens sendet `annotation_added` Event (Rekonstruktion)

---

## 8. Edge Cases & Fehlerszenarien

### 8.1 Offline-Szenarien

| Szenario | Verhalten |
|----------|-----------|
| Privat-Annotation offline erstellen | Lokal gespeichert, später gesynct |
| Stimme-Annotation offline erstellen | Gecacht, Sync bei Verbindung, andere sehen es nach Sync |
| Orchester-Annotation offline (normaler User) | Kann nicht erstellt werden (nur Dirigent) — Fehler: "Offline: Orchester-Ebene nicht verfügbar" |
| Stimmen-Annotation erhalten während Offline | Wird in Queue gepuffert, beim Reconnect angezeigt |

---

### 8.2 Berechtigungsprobleme

| Szenario | Verhalten |
|----------|-----------|
| User versucht Orchester-Ebene zu wählen (keine Admin-Rolle) | Ebene-Flyout zeigt "Orchester" ausgegraut + Schloss-Icon |
| User wird aus Kapelle entfernt während Annotationen offen | Beim nächsten Laden: Annotationen dieser Kapelle unsichtbar, kein Crash |
| User ändert Stimme, hat alte Stimmen-Annotationen | Alte Annotationen bleiben sichtbar (historisch), neue gehören zur neuen Stimme |

---

### 8.3 Große Seiten / Performance-Limits

| Szenario | Verhalten |
|----------|-----------|
| > 1000 Annotationen auf einer Seite | Pre-Caching auf aktuell sichtbare + ±1 Seite beschränkt; Render < 16ms garantiert durch SVG-Optimierung |
| > 100 gleichzeitige Nutzer zeichnen (Orchestra-Ebene) | Server pusht Events sequenziell; Clients verarbeiten asynchron (kein Blockieren des UX) |
| SVG-Pfad > 10MB (korrupt / extrem lang) | Validierung: Max. 100KB pro Annotation; größere abgelehnt mit Fehler "Annotation zu groß" |

---

### 8.4 Netzwerk-Fehler

| Szenario | Verhalten |
|----------|-----------|
| Signalr Disconnect während Annotation | Lokal gespeichert, Sync bei Reconnect; kein Datenverlust |
| Server-500-Error beim Upload | Retry 3x mit Exponential Backoff; nach 3 Versuchen: Toast "Sync fehlgeschlagen — später erneut versuchen" |
| Gleichzeitig auf zwei Geräten zeichnen | Last-Write-Wins auf Server; bei Konflikt: Notification "Deine Änderung wurde überschrieben" |

---

### 8.5 Nachtmodus & Annotationen

| Szenario | Verhalten |
|----------|-----------|
| Privat-Annotation (blau) im Nachtmodus | Farbe angepasst zu Hellblau (RGB 147, 197, 253) für Kontrast auf schwarzem Hintergrund |
| Orchester-Annotation (orange) auf Sepia-Modus | Farbe angepasst zu leuchtendem Orange (RGB 254, 167, 87) für Lesbarkeit |
| Sehr dunkle Nutzer-Annotation auf Nachtmodus | WCAG AAA Kontrast-Check; Fallback auf hellere Variante wenn nötig |

---

### 8.6 Stempel & Text-Länge

| Szenario | Verhalten |
|----------|-----------|
| User tippt > 200 Zeichen | Eingabe-Feld limitiert auf 200 (keine weiteren Zeichen möglich) |
| Stempel-Text mit Sonderzeichen (♭, ♯, etc.) | Unicode-Unterstützung; wird korrekt gespeichert und angezeigt |
| Stempel wird während des Zeichnens gelöscht (von Admin) | Nutzer sieht Fehler "Stempel nicht verfügbar"; kann Stempel nicht mehr platzieren, bestehende bleiben |

---

### 8.7 Undo / Redo über Grenzen

| Szenario | Verhalten |
|----------|-----------|
| Undo nach App-Neustart | Undo-Stack ist Session-lokal; nach Neustart: nicht möglich. Letzter persistierter Zustand wird geladen. |
| Redo auf gelöschter Annotation | Wenn Annotation nach Undo von anderem Nutzer gelöscht wurde: Redo erzeugt neue Annotation mit neuem ID |
| Undo auf Stimmen-Annotation als anderer User | Toast auf eigenem Device: "Andere Person hat Undo durchgeführt", Annotation ist weg |

---

## 9. Abhängigkeiten & Nicht-im-Scope

### Abhängigkeiten (Blocking)

- **#25 (Spielmodus-Spec):** Annotations-Layer wird im Spielmodus angezeigt
- **#29 (Stimmenauswahl-Spec):** Stimmen-Identität wird für Stimmen-Ebene-Berechtigungen genutzt
- **#37 (UX Annotationen — Wanda):** Design, Wireframes, Interaction Patterns

### Blockierend

- **#7 (Backend-Setup):** ASP.NET Core, PostgreSQL, SignalR Grundinfrastruktur
- **#8 (Flutter Scaffolding):** Projekt-Setup, SQLite/Drift, Riverpod State Management

### Abhängigkeiten (Nice-to-Have)

- **#36 (Konfigurationssystem):** Einstellungen für Annotations-Werkzeuge (Stift-Dicke, Opazität) — kann auch später kommen

---

### Nicht im Scope MS1

- ❌ **Audio-Notizen:** Sprachaufnahmen / Sprachmemos
- ❌ **Handschrift-Erkennung:** Freihand-Text zu OCR-Text
- ❌ **Kollaboratives Live-Editing:** Mehrere Nutzer bearbeiten gleichzeitig eine Annotation
- ❌ **PDF-Export mit Annotationen:** Exportieren als annotiertes PDF
- ❌ **Annotations-Suche:** Text-Suche in Annotations-Inhalten
- ❌ **Spezialisierte Bogenzeichen:** Nur allgemeine Stempel, keine Streicher-Bogen-Symbole (MS1)
- ❌ **Seiten-Verknüpfung:** Annotations mit programmierten Aktionen (Jump zu Seite X, etc.)
- ❌ **Mehrsprachige Stempel:** Nur englisch/deutsch als Standard
- ❌ **Lehrer-Modus (Benotung):** Nur Lese/Schreib-Berechtigungen, keine Benotungs-Feature

---

## 10. Definition of Done

### Funktional

- [ ] Alle 5 User Stories implementiert und E2E-getestet
- [ ] Private Annotationen lokal gespeichert, Multi-Gerät-Cloud-Sync funktioniert
- [ ] Stimmen-Annotationen über SignalR in Echtzeit synchronisiert
- [ ] Orchester-Annotationen broadcastet an alle Kapellenmitglieder
- [ ] Layer-Toggle funktioniert non-destruktiv
- [ ] Undo/Redo funktioniert über 50+ Operationen
- [ ] Ebene wechseln funktioniert korrekt mit Permissions-Check
- [ ] Long-Press-Kontextmenü funktioniert (Bearbeiten, Kopieren, Ebene wechseln, Löschen)
- [ ] Alle 7 Werkzeuge funktionieren (Stift, Text, Marker, Stempel, Radierer, Auswahl, undo/redo)
- [ ] Stempel-Katalog ist vollständig (Dynamik, Artikulation, Atemzeichen, Navigation)

### Qualität (Test-Coverage ≥ 80%)

- [ ] Unit Tests für Fallback-Algorithmus und Permissions-Logik (≥ 95% Coverage)
- [ ] Integration Tests für SignalR Sync (3 Nutzer, 2 Kapellen Szenarios)
- [ ] E2E Tests: Private Annotation → Cloud-Sync → Anderen Gerät sichtbar
- [ ] E2E Tests: Stimmen-Annotation erstellen → Andere User sieht es in < 500ms
- [ ] Performance-Tests: Seitenwechsel < 16ms mit 100 Annotationen
- [ ] Offline-Test: Private Annotation offline → Sync bei Verbindung

### UX & Accessibility

- [ ] UX-Review bestätigt Bedienbarkeit (Wanda Review)
- [ ] Alle 30 Akzeptanzkriterien getestet
- [ ] WCAG 2.1 AAA Kontrast in Standard/Nacht/Sepia-Modus
- [ ] Barrierefreiheit: Screen Reader kann Annotations-Ebenen unterscheiden
- [ ] Touch-Targets ≥ 44×44px
- [ ] Kein Jank bei Overlay-Animation (< 16ms)

### Sicherheit

- [ ] Server-seitige Permissions-Enforcement (nicht nur Frontend)
- [ ] SQL-Injection-Test: Keine Vulnerabilities in Annotation-Queries
- [ ] XSS-Test: SVG-Pfade werden sanitized
- [ ] CSRF-Token vorhanden für alle POST/PUT/DELETE Requests
- [ ] Audit-Log dokumentiert alle Änderungen

### Technisch

- [ ] Migrationen schreiben (PostgreSQL, SQLite)
- [ ] SignalR-Hub implementiert und getestet
- [ ] Error-Handling für alle API-Endpoints
- [ ] Logging für Debug-Zwecke (strukturiert)
- [ ] Git-Commit mit aussagekräftiger Message

### Dokumentation

- [ ] API-Dokumentation aktualisiert (OpenAPI/Swagger)
- [ ] Deployment-Guide für SignalR-Konfiguration
- [ ] Troubleshooting-Guide für häufige Probleme (Offline, Sync-Fehler)

### Deployment

- [ ] Migrations auf Staging-Env erfolgreich
- [ ] Feature-Flag optional (wenn noch nicht 100% stable)
- [ ] Monitoring: SignalR-Latenz-Metriken (AppInsights)
- [ ] Skalierbarkeit: Kann 1000 gleichzeitige Annotations-Edits pro Kapelle handhaben

---

## Anhang: Design Tokens & Farbwerte

### Annotations-Ebenen-Farben

| Ebene | Hex | RGB | Name |
|-------|-----|-----|------|
| Privat | #3B82F6 | RGB(59, 130, 246) | Blau |
| Stimme | #22C55E | RGB(34, 197, 94) | Grün |
| Orchester | #F97316 | RGB(249, 115, 22) | Orange |

### Nachtmodus-Varianten

| Ebene | Hex | RGB | Beschreibung |
|-------|-----|-----|-------------|
| Privat (Nacht) | #93C5FD | RGB(147, 197, 253) | Hellblau für Kontrast |
| Stimme (Nacht) | #86EFAC | RGB(134, 239, 172) | Hellgrün |
| Orchester (Nacht) | #FEA757 | RGB(254, 167, 87) | Helles Orange |

### Sepia-Varianten

Alle Farben werden auf warmem Sepia-Hintergrund (RGB 238, 216, 174) getestet — WCAG AAA Kontrast erforderlich.

---

**Status:** Ready for Implementation  
**Nächster Schritt:** Code Review mit Stark + Wanda UX-Sign-Off (#37)
