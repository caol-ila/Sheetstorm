# Feature-Spezifikation: Setlist-Verwaltung

> **Meilenstein:** MS2  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Kapellenverwaltung, Notenbank, Spielmodus), Issue #XXX (UX-Design Setlist — Wanda)  
> **UX-Referenz:** `docs/ux-specs/setlist.md` (TBD)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien-feature-level)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Berechtigungsmatrix](#6-berechtigungsmatrix)
7. [Edge Cases](#7-edge-cases)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Die Setlist-Verwaltung ist das **organisatorische Rückgrat des Musikbetriebs** in Sheetstorm. Sie ermöglicht Kapellen, Konzerte, Proben und Marschmusik-Auftritte systematisch zu planen und durchzuführen — mit nahtlosem Übergang im Spielmodus, Platzhaltern für noch nicht digitalisierte Stücke und professionellem Timing für Konzertprogramme.

**Kernwert:** Eine Kapelle kann am Vorabend des Konzerts die Setlist zusammenstellen, am Konzerttag auf allen Tablets synchronisieren und mit einem Tap durch das gesamte Programm spielen — ohne manuelle Stücksuche, ohne Unterbrechung.

### 1.2 Das Kernproblem

**Status Quo:**
- Konzertprogramme werden als Word-Dokument oder auf Papier erstellt
- Musiker bekommen eine Liste per E-Mail oder WhatsApp
- Im Konzert wird manuell das nächste Stück auf dem Tablet gesucht
- Geschätzte Dauer und Timing werden in Excel berechnet
- Noch nicht eingescannte Stücke werden als "TODO: Polka XY" notiert

**Sheetstorm-Lösung:**
- Setlists sind digitale, teilbare, durchspielbare Programme
- Platzhalter ermöglichen vollständige Programmplanung, auch wenn Noten noch fehlen
- Timing-Kalkulation mit Start-/Endzeiten für jedes Stück
- Nahtloser Übergang im Spielmodus (kein manuelles Suchen)
- GEMA-konforme Export-Basis (MS2)

### 1.3 Scope MS2

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Setlist erstellen, bearbeiten, löschen | GEMA-Meldung generieren (separate Spec) |
| Stücke hinzufügen, umsortieren (Drag & Drop) | Setlist-Vorlagen / Templates |
| Platzhalter-Einträge ohne Stück-Referenz | Automatische Setlist-Generierung per AI |
| Metadaten: Name, Datum, Typ, Beschreibung | Setlist-Teilen außerhalb der Kapelle |
| Setlist-Modus im Player (nahtloser Übergang) | Dirigenten-Synchronisation (Song-Broadcast ist separate Spec) |
| Geschätzte Dauer pro Eintrag | Historische Aufführungs-Statistiken |
| Berechnete Start-/Endzeiten, Gesamtdauer | Setlist-Import aus externen Formaten |
| Stück in mehreren Setlists verwendbar | Mehrere Setlists gleichzeitig spielen |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | Eine Woche vor dem Konzert | Setlist erstellen, Stücke zusammenstellen, Reihenfolge festlegen |
| Notenwart | Während der Setlist-Erstellung | Fehlende Stücke als Platzhalter eintragen, später ersetzen |
| Musiker | Am Konzerttag auf der Bühne | Setlist-Modus starten, durch das Programm spielen ohne Unterbrechung |
| Admin | Nach dem Konzert | Aufführungsdaten für GEMA-Meldung exportieren |

---

## 2. User Stories (INVEST-konform)

### US-01: Setlist erstellen

> *Als Dirigent möchte ich eine neue Setlist mit Namen und Datum erstellen, damit ich ein Konzertprogramm zusammenstellen kann.*

**Akzeptanzkriterien:**
1. Dirigent kann auf "+ Neue Setlist" tippen (Setlists-Tab)
2. Pflichtfeld: **Name** (1–120 Zeichen, nicht leer)
3. Pflichtfeld: **Typ** (Auswahl: Konzert, Probe, Marschmusik)
4. Optional: **Datum** (ISO 8601 Date, für zukünftige Termine/Konzerte)
5. Optional: **Beschreibung** (max. 500 Zeichen, Markdown-Support)
6. Optional: **Startzeit** (HH:MM, für Timing-Kalkulation)
7. Nach Erstellen: Leere Setlist erscheint in der Setlist-Übersicht
8. Setlist ist initial leer (0 Einträge)
9. Ersteller wird als Autor protokolliert (Audit-Log)
10. **Fehlerfall:** Wenn Name leer → Validierungsfehler, Speichern blockiert

**INVEST:**
- **I**: Unabhängig von Stück-Hinzufügen (nächste US)
- **N**: Startzeit optional, kann später hinzugefügt werden
- **V**: Basis für alle weiteren Setlist-Funktionen
- **E**: ~2-3 Tage (Backend + Frontend CRUD)
- **S**: Nur Erstellung, kein Stück-Hinzufügen
- **T**: Setlist mit Name + Typ in DB prüfbar

---

### US-02: Stücke zur Setlist hinzufügen

> *Als Dirigent möchte ich Stücke aus der Notenbank zur Setlist hinzufügen, damit ich ein vollständiges Konzertprogramm zusammenstellen kann.*

**Akzeptanzkriterien:**
1. Dirigent öffnet Setlist-Detail-Ansicht
2. Button "+ Stück hinzufügen" öffnet Noten-Picker (Modal/Sheet)
3. Noten-Picker zeigt alle Stücke der Kapelle (Cursor-Pagination, Suche nach Titel/Komponist)
4. Nach Auswahl: Stück wird an das Ende der Setlist angehängt
5. Position wird automatisch vergeben (letzte Position + 1)
6. Jedes Stück kann **mehrfach** in derselben Setlist vorkommen (z.B. Zugabe)
7. Jedes Stück kann in **mehreren verschiedenen Setlists** verwendet werden
8. Hinzugefügtes Stück zeigt: Titel, Komponist, Thumbnail (erste Seite)
9. Optional: Geschätzte Dauer kann pro Eintrag manuell eingegeben werden (Format: MM:SS oder Minuten)
10. Setlist-Übersicht zeigt Anzahl der Einträge
11. **Fehlerfall:** Wenn Stück gelöscht wird, bleibt Setlist-Eintrag mit Hinweis "Stück nicht verfügbar"

**INVEST:**
- **I**: Kann nach Setlist-Erstellung jederzeit erfolgen
- **N**: Bulk-Add kann für MS2 entfallen
- **V**: Ohne Stücke ist Setlist wertlos
- **E**: ~3 Tage (Picker-UI + Relation)
- **S**: Nur einzelnes Hinzufügen
- **T**: Setlist-Eintrag mit Piece-Referenz in DB prüfbar

---

### US-03: Platzhalter-Einträge erstellen

> *Als Notenwart möchte ich Platzhalter für noch nicht digitalisierte Stücke in eine Setlist eintragen, damit ich das vollständige Konzertprogramm planen kann, auch wenn noch nicht alle Noten eingescannt sind.*

**Akzeptanzkriterien:**
1. Dirigent/Notenwart kann auf "+ Platzhalter hinzufügen" tippen (Setlist-Detail)
2. Pflichtfeld: **Titel** (1–150 Zeichen, z.B. "Polka: Im Frühling")
3. Optional: **Komponist** (max. 100 Zeichen)
4. Optional: **Geschätzte Dauer** (MM:SS oder Minuten)
5. Optional: **Notizen** (max. 250 Zeichen, z.B. "Noten liegen beim Dirigenten")
6. Platzhalter wird an das Ende der Setlist angehängt
7. Visuell unterscheidbar von echten Stücken (Icon, Badge "Platzhalter")
8. Platzhalter kann später durch echtes Stück ersetzt werden ("In Stück umwandeln"-Button öffnet Stück-Picker)
9. Im Spielmodus: Platzhalter wird übersprungen (mit Hinweis "Dieses Stück ist noch nicht digitalisiert")
10. Setlist-Export (GEMA) enthält Platzhalter mit Titel/Komponist
11. **Fehlerfall:** Wenn Titel leer → Validierungsfehler

**INVEST:**
- **I**: Unabhängig von echten Stück-Referenzen
- **N**: Notizen optional
- **V**: Kritisch für schrittweisen Digitalisierungsprozess
- **E**: ~2 Tage
- **S**: Nur Platzhalter-Erstellung
- **T**: Setlist-Eintrag ohne Piece-Referenz in DB prüfbar

---

### US-04: Setlist-Reihenfolge ändern

> *Als Dirigent möchte ich die Reihenfolge der Stücke in einer Setlist per Drag & Drop ändern, damit ich das Konzertprogramm flexibel anpassen kann.*

**Akzeptanzkriterien:**
1. In der Setlist-Detail-Ansicht kann jeder Eintrag per Drag & Drop verschoben werden
2. Drag-Handle (⋮⋮) links neben jedem Eintrag
3. Drop-Zone visuell hervorgehoben beim Dragging
4. Nach Drop: Positionen werden neu berechnet und gespeichert
5. Änderungen werden sofort persistiert (Auto-Save mit Undo-Toast)
6. Touch-Gesten auf Mobile: Long-Press → Drag
7. Keyboard-Unterstützung: Tab + Pfeiltasten + Enter (Accessibility)
8. **Fehlerfall:** Wenn Netzwerkfehler beim Speichern → Rollback auf alte Reihenfolge mit Fehler-Toast

**INVEST:**
- **I**: Funktioniert unabhängig von anderen Features
- **N**: Keyboard-Support kann MS3 sein
- **V**: Dirigenten ändern häufig Last-Minute die Reihenfolge
- **E**: ~2-3 Tage (primär Frontend-Logik)
- **S**: Nur Drag & Drop
- **T**: Neue Positions-Werte in DB prüfbar

---

### US-05: Konzertprogramm mit Timing

> *Als Dirigent möchte ich für jedes Stück eine geschätzte Dauer eingeben und die berechneten Start-/Endzeiten sehen, damit ich ein zeitlich präzises Konzertprogramm planen kann.*

**Akzeptanzkriterien:**
1. Pro Setlist-Eintrag: Eingabefeld "Geschätzte Dauer" (Format: MM:SS oder nur Minuten, z.B. "3:45" oder "4")
2. Setlist hat optional eine **Startzeit** (HH:MM, z.B. "20:00")
3. Wenn Startzeit gesetzt: Automatische Berechnung der Start-/Endzeiten für alle Einträge
4. Anzeige pro Eintrag: "Start: 20:03 — Ende: 20:07" (basierend auf kumulierter Dauer)
5. Gesamtdauer der Setlist wird berechnet und oben angezeigt (z.B. "Gesamtdauer: 1h 42min")
6. Optionale **Pauseneinträge**: Spezialtyp "Pause" mit fixer Dauer (z.B. "15 Minuten Pause")
7. Pauseneinträge sind keine Stücke/Platzhalter, nur für Timing
8. Bei fehlender Dauer: Eintrag wird mit "?" markiert, Timing-Berechnung stoppt dort
9. Timing-Ansicht umschaltbar (Toggle "Timing anzeigen" in Setlist-Detail)
10. **Fehlerfall:** Wenn Dauer negativ oder > 60 Minuten → Validierungsfehler (Warnung)

**INVEST:**
- **I**: Kann nach Setlist-Erstellung hinzugefügt werden
- **N**: Pausen optional, können auch als Platzhalter gelöst werden
- **V**: Konzertveranstalter verlangen oft genaue Timing-Angaben
- **E**: ~3-4 Tage (Timing-Logik + UI)
- **S**: Nur Timing, kein GEMA-Export
- **T**: Berechnete Zeiten gegen erwartete Werte prüfbar

---

### US-06: Setlist-Modus im Player

> *Als Musiker möchte ich eine Setlist im Spielmodus öffnen und automatisch zum nächsten Stück wechseln, damit ich während des Konzerts nicht manuell nach Noten suchen muss.*

**Akzeptanzkriterien:**
1. Musiker öffnet Setlist-Detail und tippt auf "Spielen" (▶️)
2. Spielmodus startet mit dem ersten Stück der Setlist (erste Seite, korrekte Stimme)
3. Zusätzliche Navigation: "Vorheriges Stück" (⏮) und "Nächstes Stück" (⏭) Buttons
4. Bei letzter Seite des Stücks: Automatischer Übergang zum nächsten Stück (optional konfigurierbar: Manuell / Automatisch)
5. Übergang < 200ms (Preloading der nächsten Seiten)
6. Progress-Indikator: "Stück 3 von 8"
7. Platzhalter werden übersprungen mit Toast-Hinweis "Stück nicht verfügbar"
8. Bei letztem Stück der Setlist: "Ende der Setlist"-Hinweis, kein Auto-Wechsel
9. Setlist-Modus kann jederzeit verlassen werden (❌ oben links)
10. Nach Verlassen: Zurück zur Setlist-Übersicht
11. **Fehlerfall:** Wenn Stück keine passende Stimme hat → Fallback-Logik wie im normalen Spielmodus (siehe MS1 Stimmenauswahl-Spec)

**INVEST:**
- **I**: Baut auf Spielmodus MS1 auf, erweitert ihn
- **N**: Auto-Wechsel kann konfigurierbar sein
- **V**: Hauptnutzen der Setlist-Funktion
- **E**: ~4-5 Tage (Player-Integration + Preloading)
- **S**: Nur Durchspielen, keine Synchronisation
- **T**: E2E-Test: Setlist mit 3 Stücken durchspielen

---

### US-07: Setlist bearbeiten und löschen

> *Als Dirigent möchte ich Setlists bearbeiten, duplizieren und löschen, damit ich meine Konzertprogramme pflegen kann.*

**Akzeptanzkriterien:**
1. Dirigent kann in Setlist-Detail auf "Bearbeiten" (✏️) tippen
2. Änderbar: Name, Typ, Datum, Beschreibung, Startzeit
3. Einträge hinzufügen/entfernen/umsortieren (wie US-02 bis US-04)
4. "Duplizieren"-Funktion: Erstellt Kopie mit "(Kopie)" im Namen, gleichem Inhalt
5. "Löschen"-Funktion: Sicherheitsabfrage "Wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden."
6. Nach Löschen: Setlist verschwindet aus Übersicht, verknüpfte Termine zeigen "Setlist gelöscht"
7. Audit-Log: Wer hat wann was geändert/gelöscht
8. Einzelne Einträge löschbar per Swipe-Geste (iOS/Android) oder Kontextmenü (Desktop)
9. **Fehlerfall:** Wenn Setlist während Bearbeitung von anderem Nutzer gelöscht wurde → "Diese Setlist existiert nicht mehr"

**INVEST:**
- **I**: Unabhängig von anderen Setlist-Features
- **N**: Duplizieren kann MS3 sein
- **V**: Standard CRUD-Operationen
- **E**: ~2 Tage
- **S**: Nur Edit/Delete
- **T**: Änderungen in DB prüfbar

---

### US-08: Setlist-Übersicht

> *Als Musiker möchte ich alle Setlists meiner Kapelle sehen, filtern und durchsuchen, damit ich schnell die richtige Setlist finde.*

**Akzeptanzkriterien:**
1. Setlists-Tab zeigt alle Setlists der aktuellen Kapelle (neueste zuerst)
2. Jede Kachel zeigt: Name, Typ (Icon), Datum, Anzahl Einträge, Gesamtdauer (wenn vorhanden)
3. Suche nach Name (Echtzeitfilter, Client-seitig wenn < 100 Setlists, sonst Server)
4. Filter: Nach Typ (Konzert / Probe / Marschmusik), Nach Datum (Vergangen / Zukünftig)
5. Sortierung: Datum aufsteigend/absteigend, Name A-Z/Z-A
6. Tap auf Kachel → Setlist-Detail
7. "Spielen"-Button direkt auf Kachel (Quick-Action)
8. Vergangene Setlists visuell gedämpft (opacity 0.7) oder separiert
9. Leerzustand: "Noch keine Setlists erstellt. Erstelle deine erste Setlist für Proben oder Konzerte."
10. Cursor-Pagination wenn > 50 Setlists

**INVEST:**
- **I**: Kann parallel zu anderen US entwickelt werden
- **N**: Erweiterte Filter können später hinzugefügt werden
- **V**: Einstiegspunkt in Setlist-Feature
- **E**: ~3 Tage
- **S**: Nur Übersicht + Filter
- **T**: Liste lädt alle Setlists mit korrekten Metadaten

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Testbar durch |
|----|-----------|---------------|
| **AC-01** | Dirigent kann Setlist mit Name, Typ, Datum erstellen | Integration-Test: POST /api/v1/kapellen/{id}/setlists |
| **AC-02** | Stücke können per Picker hinzugefügt werden | E2E-Test: Setlist erstellen → 3 Stücke hinzufügen → gespeichert |
| **AC-03** | Platzhalter-Einträge (ohne Piece-Referenz) können erstellt werden | Unit-Test: SetlistEntry mit piece_id=null, title gesetzt |
| **AC-04** | Drag & Drop Umsortierung speichert neue Positionen korrekt | Integration-Test: PATCH positions → DB-Prüfung |
| **AC-05** | Geschätzte Dauer pro Eintrag wird in Gesamtdauer summiert | Unit-Test: Timing-Kalkulation mit 5 Einträgen |
| **AC-06** | Start-/Endzeiten werden basierend auf Startzeit + Dauer berechnet | Unit-Test: Startzeit 20:00, 3 Stücke → Endzeiten korrekt |
| **AC-07** | Setlist-Modus startet mit erstem Stück und ermöglicht Vor/Zurück | E2E-Test: Setlist mit 3 Stücken durchspielen |
| **AC-08** | Platzhalter werden im Spielmodus übersprungen | E2E-Test: Setlist mit Platzhalter → Skip mit Hinweis |
| **AC-09** | Setlist kann bearbeitet, dupliziert, gelöscht werden | Integration-Tests: PATCH, POST duplicate, DELETE |
| **AC-10** | Setlist-Übersicht zeigt alle Setlists mit Filter + Suche | Widget-Test: Liste rendert, Filter funktioniert |
| **AC-11** | Preloading im Setlist-Modus: Nächstes Stück lädt im Hintergrund | Performance-Test: Messung Übergangszeit < 200ms |
| **AC-12** | Stück kann in mehreren Setlists gleichzeitig verwendet werden | Integration-Test: Piece in 3 Setlists → alle anzeigen |
| **AC-13** | Pauseneinträge können für Timing erstellt werden | Unit-Test: SetlistEntry mit type='pause' |
| **AC-14** | Audit-Log protokolliert Ersteller und Änderungen | Integration-Test: Setlist erstellen → Audit-Eintrag prüfen |
| **AC-15** | Berechtigungen: Nur Dirigent/Admin/Notenwart darf Setlists bearbeiten | Auth-Test: Musiker versucht POST → 403 Forbidden |

---

## 4. API-Contract

**Base Path:** `/api/v1/kapellen/{bandId}/setlists`  
**Auth:** Bearer JWT  
**Pagination:** Cursor-based (siehe MS1 Pattern)

### 4.1 GET /api/v1/kapellen/{bandId}/setlists

**Beschreibung:** Alle Setlists der Kapelle abrufen

**Query-Parameter:**
```
?cursor={string}          // Pagination-Cursor (optional)
?limit={int}              // Max. Anzahl (default: 30, max: 100)
?typ={string}             // Filter: "konzert" | "probe" | "marschmusik"
?datum_von={date}         // Filter: Ab Datum (ISO 8601)
?datum_bis={date}         // Filter: Bis Datum (ISO 8601)
?suche={string}           // Suche nach Name
?sortierung={string}      // "datum_asc" | "datum_desc" | "name_asc" | "name_desc"
```

**Response 200 OK:**
```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Frühjahrskonzert 2026",
      "typ": "konzert",
      "datum": "2026-05-15",
      "startzeit": "20:00",
      "beschreibung": "Traditionelles Konzert im Festzelt",
      "anzahl_eintraege": 12,
      "gesamtdauer_minuten": 95,
      "erstellt_von": {
        "id": "user-123",
        "name": "Maria Dirigentin"
      },
      "erstellt_am": "2026-03-20T10:30:00Z",
      "aktualisiert_am": "2026-03-22T15:45:00Z"
    }
  ],
  "gesamt": 45,
  "cursor": {
    "naechste": "eyJpZCI6InNldGxpc3QtNDUiLCJkYXR1bSI6IjIwMjYtMDUtMTUifQ==",
    "vorherige": null
  }
}
```

**Fehler:**
- `401 Unauthorized` — Kein gültiges Token
- `403 Forbidden` — Keine Mitgliedschaft in dieser Kapelle
- `404 Not Found` — Kapelle existiert nicht

---

### 4.2 POST /api/v1/kapellen/{bandId}/setlists

**Beschreibung:** Neue Setlist erstellen

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body:**
```json
{
  "name": "Frühjahrskonzert 2026",
  "typ": "konzert",
  "datum": "2026-05-15",
  "startzeit": "20:00",
  "beschreibung": "Traditionelles Konzert im Festzelt"
}
```

**Felder:**
- `name` (string, required, 1-120 Zeichen)
- `typ` (enum, required): `"konzert"` | `"probe"` | `"marschmusik"`
- `datum` (string, optional, ISO 8601 Date)
- `startzeit` (string, optional, Format: "HH:MM")
- `beschreibung` (string, optional, max. 500 Zeichen, Markdown)

**Response 201 Created:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Frühjahrskonzert 2026",
  "typ": "konzert",
  "datum": "2026-05-15",
  "startzeit": "20:00",
  "beschreibung": "Traditionelles Konzert im Festzelt",
  "anzahl_eintraege": 0,
  "gesamtdauer_minuten": 0,
  "erstellt_von": {
    "id": "user-123",
    "name": "Maria Dirigentin"
  },
  "erstellt_am": "2026-03-28T14:30:00Z",
  "aktualisiert_am": "2026-03-28T14:30:00Z"
}
```

**Fehler:**
- `400 Bad Request` — Validierungsfehler (Name leer, Typ ungültig)
- `401 Unauthorized`
- `403 Forbidden` — Keine Berechtigung (Musiker darf nicht erstellen)

---

### 4.3 GET /api/v1/kapellen/{bandId}/setlists/{setlistId}

**Beschreibung:** Setlist-Details mit allen Einträgen abrufen

**Response 200 OK:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Frühjahrskonzert 2026",
  "typ": "konzert",
  "datum": "2026-05-15",
  "startzeit": "20:00",
  "beschreibung": "Traditionelles Konzert im Festzelt",
  "anzahl_eintraege": 3,
  "gesamtdauer_minuten": 12,
  "erstellt_von": {
    "id": "user-123",
    "name": "Maria Dirigentin"
  },
  "erstellt_am": "2026-03-28T14:30:00Z",
  "aktualisiert_am": "2026-03-28T15:00:00Z",
  "eintraege": [
    {
      "id": "entry-1",
      "position": 1,
      "typ": "stueck",
      "stueck": {
        "id": "piece-456",
        "titel": "Böhmische Liebe",
        "komponist": "Karel Komzák",
        "thumbnail_url": "https://cdn.sheetstorm.app/pieces/456/thumb.jpg"
      },
      "geschaetzte_dauer_sekunden": 240,
      "startzeit_berechnet": "20:00",
      "endzeit_berechnet": "20:04"
    },
    {
      "id": "entry-2",
      "position": 2,
      "typ": "platzhalter",
      "platzhalter": {
        "titel": "Polka: Im Frühling",
        "komponist": "Unbekannt",
        "notizen": "Noten liegen beim Dirigenten"
      },
      "geschaetzte_dauer_sekunden": 180,
      "startzeit_berechnet": "20:04",
      "endzeit_berechnet": "20:07"
    },
    {
      "id": "entry-3",
      "position": 3,
      "typ": "pause",
      "pause": {
        "titel": "Pause",
        "dauer_sekunden": 900
      },
      "geschaetzte_dauer_sekunden": 900,
      "startzeit_berechnet": "20:07",
      "endzeit_berechnet": "20:22"
    }
  ]
}
```

**Fehler:**
- `404 Not Found` — Setlist existiert nicht
- `403 Forbidden` — Keine Berechtigung

---

### 4.4 PATCH /api/v1/kapellen/{bandId}/setlists/{setlistId}

**Beschreibung:** Setlist-Metadaten bearbeiten

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body (alle Felder optional):**
```json
{
  "name": "Frühjahrskonzert 2026 (geändert)",
  "typ": "konzert",
  "datum": "2026-05-16",
  "startzeit": "19:30",
  "beschreibung": "Aktualisierte Beschreibung"
}
```

**Response 200 OK:** (wie GET, aktualisierte Daten)

**Fehler:**
- `400 Bad Request` — Validierungsfehler
- `403 Forbidden`
- `404 Not Found`

---

### 4.5 DELETE /api/v1/kapellen/{bandId}/setlists/{setlistId}

**Beschreibung:** Setlist löschen

**Berechtigung:** Dirigent, Admin

**Response 204 No Content**

**Fehler:**
- `403 Forbidden`
- `404 Not Found`

---

### 4.6 POST /api/v1/kapellen/{bandId}/setlists/{setlistId}/eintraege

**Beschreibung:** Eintrag (Stück, Platzhalter oder Pause) zur Setlist hinzufügen

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body (Variante A — Stück):**
```json
{
  "typ": "stueck",
  "stueck_id": "piece-456",
  "geschaetzte_dauer_sekunden": 240
}
```

**Request Body (Variante B — Platzhalter):**
```json
{
  "typ": "platzhalter",
  "platzhalter": {
    "titel": "Polka: Im Frühling",
    "komponist": "Unbekannt",
    "notizen": "Noten liegen beim Dirigenten"
  },
  "geschaetzte_dauer_sekunden": 180
}
```

**Request Body (Variante C — Pause):**
```json
{
  "typ": "pause",
  "pause": {
    "titel": "Pause",
    "dauer_sekunden": 900
  }
}
```

**Felder:**
- `typ` (enum, required): `"stueck"` | `"platzhalter"` | `"pause"`
- `stueck_id` (uuid, required wenn typ=stueck)
- `platzhalter.titel` (string, required wenn typ=platzhalter, 1-150 Zeichen)
- `platzhalter.komponist` (string, optional, max. 100 Zeichen)
- `platzhalter.notizen` (string, optional, max. 250 Zeichen)
- `pause.titel` (string, optional, default: "Pause")
- `pause.dauer_sekunden` (int, required wenn typ=pause)
- `geschaetzte_dauer_sekunden` (int, optional, für stueck/platzhalter)
- `position` (int, optional) — Wenn nicht angegeben: ans Ende anhängen

**Response 201 Created:**
```json
{
  "id": "entry-123",
  "position": 4,
  "typ": "stueck",
  "stueck": {
    "id": "piece-456",
    "titel": "Böhmische Liebe",
    "komponist": "Karel Komzák",
    "thumbnail_url": "https://cdn.sheetstorm.app/pieces/456/thumb.jpg"
  },
  "geschaetzte_dauer_sekunden": 240,
  "startzeit_berechnet": "20:22",
  "endzeit_berechnet": "20:26"
}
```

**Fehler:**
- `400 Bad Request` — Validierung fehlgeschlagen (Titel leer bei Platzhalter, ungültiger Typ)
- `404 Not Found` — Stück existiert nicht (wenn stueck_id ungültig)
- `403 Forbidden`

---

### 4.7 PATCH /api/v1/kapellen/{bandId}/setlists/{setlistId}/eintraege/{entryId}

**Beschreibung:** Eintrag bearbeiten (z.B. Dauer ändern, Platzhalter-Info aktualisieren)

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body (Beispiel — Platzhalter):**
```json
{
  "platzhalter": {
    "titel": "Polka: Neuer Titel",
    "komponist": "Bekannter Komponist"
  },
  "geschaetzte_dauer_sekunden": 200
}
```

**Response 200 OK:** (aktualisierter Eintrag)

---

### 4.8 DELETE /api/v1/kapellen/{bandId}/setlists/{setlistId}/eintraege/{entryId}

**Beschreibung:** Eintrag aus Setlist entfernen

**Berechtigung:** Dirigent, Admin, Notenwart

**Response 204 No Content**

**Fehler:**
- `403 Forbidden`
- `404 Not Found`

---

### 4.9 PATCH /api/v1/kapellen/{bandId}/setlists/{setlistId}/eintraege/positionen

**Beschreibung:** Reihenfolge mehrerer Einträge ändern (Batch-Update nach Drag & Drop)

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body:**
```json
{
  "positionen": [
    { "id": "entry-1", "position": 2 },
    { "id": "entry-2", "position": 1 },
    { "id": "entry-3", "position": 3 }
  ]
}
```

**Response 200 OK:**
```json
{
  "erfolgreich": true,
  "aktualisierte_eintraege": 3
}
```

**Fehler:**
- `400 Bad Request` — Duplikate, lückenhafte Positionen, ungültige IDs
- `403 Forbidden`

---

### 4.10 POST /api/v1/kapellen/{bandId}/setlists/{setlistId}/duplizieren

**Beschreibung:** Setlist duplizieren (inkl. aller Einträge)

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body (optional):**
```json
{
  "name": "Frühjahrskonzert 2026 (Kopie)",
  "datum": "2026-05-20"
}
```

**Response 201 Created:** (wie POST /setlists)

---

### 4.11 POST /api/v1/kapellen/{bandId}/setlists/{setlistId}/eintraege/{entryId}/in-stueck-umwandeln

**Beschreibung:** Platzhalter durch echtes Stück ersetzen

**Berechtigung:** Dirigent, Admin, Notenwart

**Request Body:**
```json
{
  "stueck_id": "piece-789"
}
```

**Response 200 OK:** (aktualisierter Eintrag, nun mit Stück-Referenz)

**Fehler:**
- `400 Bad Request` — Eintrag ist kein Platzhalter
- `404 Not Found` — Stück existiert nicht

---

### 4.12 GET /api/v1/kapellen/{bandId}/setlists/{setlistId}/spielmodus

**Beschreibung:** Metadaten für Setlist-Modus abrufen (optimiert für Player)

**Query-Parameter:**
```
?stimme_id={uuid}  // Optional: Nutzer-bevorzugte Stimme
```

**Response 200 OK:**
```json
{
  "setlist": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Frühjahrskonzert 2026",
    "anzahl_eintraege": 3
  },
  "stuecke": [
    {
      "eintrag_id": "entry-1",
      "position": 1,
      "stueck_id": "piece-456",
      "titel": "Böhmische Liebe",
      "stimme": {
        "id": "voice-1",
        "name": "Trompete 1 in B"
      },
      "seiten": [
        {
          "id": "page-1",
          "bild_url": "https://cdn.sheetstorm.app/pages/1/full.jpg",
          "vorschau_url": "https://cdn.sheetstorm.app/pages/1/thumb.jpg"
        }
      ]
    },
    {
      "eintrag_id": "entry-2",
      "position": 2,
      "typ": "platzhalter",
      "titel": "Polka: Im Frühling",
      "uebersprungen": true
    }
  ],
  "preload_urls": [
    "https://cdn.sheetstorm.app/pages/2/full.jpg",
    "https://cdn.sheetstorm.app/pages/3/full.jpg"
  ]
}
```

**Beschreibung:**
- Liefert alle Stücke mit aufgelöster Stimme (Fallback-Logik wie in MS1)
- Platzhalter haben `uebersprungen: true`
- `preload_urls` enthält die ersten 3-5 Seiten für Preloading

---

## 5. Datenmodell

### 5.1 SQL Schema

```sql
-- Setlist-Tabelle
CREATE TABLE setlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    band_id UUID NOT NULL REFERENCES bands(id) ON DELETE CASCADE,
    
    name VARCHAR(120) NOT NULL CHECK (LENGTH(TRIM(name)) > 0),
    typ VARCHAR(20) NOT NULL CHECK (typ IN ('konzert', 'probe', 'marschmusik')),
    datum DATE,
    startzeit TIME,  -- HH:MM für Timing-Kalkulation
    beschreibung TEXT CHECK (LENGTH(beschreibung) <= 500),
    
    -- Metadaten
    erstellt_von UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    erstellt_am TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Indizes
    CONSTRAINT setlists_band_id_idx FOREIGN KEY (band_id) REFERENCES bands(id),
    CONSTRAINT setlists_erstellt_von_idx FOREIGN KEY (erstellt_von) REFERENCES users(id)
);

CREATE INDEX idx_setlists_band_id ON setlists(band_id);
CREATE INDEX idx_setlists_datum ON setlists(datum) WHERE datum IS NOT NULL;
CREATE INDEX idx_setlists_typ ON setlists(typ);


-- Setlist-Einträge (Stücke, Platzhalter, Pausen)
CREATE TABLE setlist_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setlist_id UUID NOT NULL REFERENCES setlists(id) ON DELETE CASCADE,
    
    position INTEGER NOT NULL,  -- 1-basiert, bestimmt Reihenfolge
    typ VARCHAR(20) NOT NULL CHECK (typ IN ('stueck', 'platzhalter', 'pause')),
    
    -- Referenz auf echtes Stück (NULL wenn Platzhalter/Pause)
    piece_id UUID REFERENCES pieces(id) ON DELETE SET NULL,
    
    -- Platzhalter-Daten (nur gefüllt wenn typ='platzhalter')
    platzhalter_titel VARCHAR(150) CHECK (typ != 'platzhalter' OR LENGTH(TRIM(platzhalter_titel)) > 0),
    platzhalter_komponist VARCHAR(100),
    platzhalter_notizen VARCHAR(250),
    
    -- Pausen-Daten (nur gefüllt wenn typ='pause')
    pause_titel VARCHAR(100),
    pause_dauer_sekunden INTEGER CHECK (typ != 'pause' OR pause_dauer_sekunden > 0),
    
    -- Timing (für alle Typen optional)
    geschaetzte_dauer_sekunden INTEGER CHECK (geschaetzte_dauer_sekunden > 0),
    
    -- Metadaten
    erstellt_am TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT setlist_entries_unique_position UNIQUE (setlist_id, position),
    CONSTRAINT setlist_entries_stueck_check CHECK (
        (typ = 'stueck' AND piece_id IS NOT NULL) OR
        (typ = 'platzhalter' AND platzhalter_titel IS NOT NULL) OR
        (typ = 'pause' AND pause_dauer_sekunden IS NOT NULL)
    )
);

CREATE INDEX idx_setlist_entries_setlist_id ON setlist_entries(setlist_id);
CREATE INDEX idx_setlist_entries_piece_id ON setlist_entries(piece_id) WHERE piece_id IS NOT NULL;
CREATE INDEX idx_setlist_entries_position ON setlist_entries(setlist_id, position);


-- Audit-Log für Setlist-Änderungen
CREATE TABLE setlist_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setlist_id UUID NOT NULL REFERENCES setlists(id) ON DELETE CASCADE,
    
    aktion VARCHAR(50) NOT NULL,  -- 'erstellt', 'bearbeitet', 'geloescht', 'eintrag_hinzugefuegt', etc.
    benutzer_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    details JSONB,  -- z.B. { "alt": {...}, "neu": {...} }
    
    zeitstempel TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_setlist_audits_setlist_id ON setlist_audits(setlist_id);
CREATE INDEX idx_setlist_audits_zeitstempel ON setlist_audits(zeitstempel);
```

### 5.2 Domain-Entities (C#)

**Neue Entity: `Setlist.cs`**
```csharp
public class Setlist : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;
    
    public string Name { get; set; } = string.Empty;
    public SetlistTyp Typ { get; set; }
    public DateOnly? Datum { get; set; }
    public TimeOnly? Startzeit { get; set; }
    public string? Beschreibung { get; set; }
    
    public Guid ErstelltVon { get; set; }
    public Musician Ersteller { get; set; } = null!;
    
    public ICollection<SetlistEntry> Eintraege { get; set; } = new List<SetlistEntry>();
    
    // Berechnete Properties
    public int AnzahlEintraege => Eintraege.Count;
    public int? GesamtdauerMinuten => Eintraege
        .Where(e => e.GeschaetzteDauerSekunden.HasValue)
        .Sum(e => e.GeschaetzteDauerSekunden) / 60;
}

public enum SetlistTyp
{
    Konzert,
    Probe,
    Marschmusik
}
```

**Neue Entity: `SetlistEntry.cs`**
```csharp
public class SetlistEntry : BaseEntity
{
    public Guid SetlistId { get; set; }
    public Setlist Setlist { get; set; } = null!;
    
    public int Position { get; set; }
    public SetlistEntryTyp Typ { get; set; }
    
    // Referenz auf echtes Stück (null wenn Platzhalter/Pause)
    public Guid? PieceId { get; set; }
    public Piece? Piece { get; set; }
    
    // Platzhalter-Daten
    public string? PlatzhalterTitel { get; set; }
    public string? PlatzhalterKomponist { get; set; }
    public string? PlatzhalterNotizen { get; set; }
    
    // Pausen-Daten
    public string? PauseTitel { get; set; }
    public int? PauseDauerSekunden { get; set; }
    
    // Timing
    public int? GeschaetzteDauerSekunden { get; set; }
    
    // Berechnete Zeiten (nur wenn Setlist.Startzeit gesetzt)
    public TimeOnly? StartzeitBerechnet { get; set; }
    public TimeOnly? EndzeitBerechnet { get; set; }
}

public enum SetlistEntryTyp
{
    Stueck,
    Platzhalter,
    Pause
}
```

**Neue Entity: `SetlistAudit.cs`**
```csharp
public class SetlistAudit : BaseEntity
{
    public Guid SetlistId { get; set; }
    public Setlist Setlist { get; set; } = null!;
    
    public string Aktion { get; set; } = string.Empty;
    public Guid BenutzerId { get; set; }
    public Musician Benutzer { get; set; } = null!;
    
    public JsonDocument? Details { get; set; }  // JSONB
    public DateTime Zeitstempel { get; set; } = DateTime.UtcNow;
}
```

### 5.3 Beziehungen

```
Band 1───N Setlist
Setlist 1───N SetlistEntry
SetlistEntry N───1 Piece (optional)
Musician 1───N Setlist (erstellt_von)
Setlist 1───N SetlistAudit
```

**Wichtig:**
- Ein Piece kann in **mehreren SetlistEntries** referenziert werden (keine 1:1-Beziehung)
- Wenn ein Piece gelöscht wird: `ON DELETE SET NULL` → SetlistEntry bleibt, piece_id wird NULL (wie Platzhalter behandelt)
- Wenn eine Setlist gelöscht wird: Alle SetlistEntries werden gelöscht (CASCADE)

---

## 6. Berechtigungsmatrix

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|-------|----------|-----------|----------------|---------|
| Setlist erstellen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Setlist bearbeiten (eigene) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Setlist bearbeiten (fremde) | ✅ | ✅ | ⚠️ Nur Metadaten | ❌ | ❌ |
| Setlist löschen (eigene) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Setlist löschen (fremde) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Einträge hinzufügen/entfernen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Einträge umsortieren | ✅ | ✅ | ✅ | ❌ | ❌ |
| Platzhalter erstellen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Setlist ansehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Setlist-Modus spielen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Setlist duplizieren | ✅ | ✅ | ✅ | ❌ | ❌ |
| Audit-Log einsehen | ✅ | ✅ | ❌ | ❌ | ❌ |

**Notizen:**
- **Notenwart** darf nur Metadaten fremder Setlists ändern (Name, Beschreibung), nicht die Einträge selbst — Grund: Notenwarte pflegen Noten, Dirigenten planen Programme
- **Alle** Mitglieder dürfen Setlists ansehen und im Spielmodus nutzen
- **Registerführer** und **Musiker** dürfen keine Setlists erstellen/bearbeiten (nur Konsumenten)

---

## 7. Edge Cases

### E-01: Stück wird während Setlist-Erstellung gelöscht
**Szenario:** Dirigent fügt Stück A zu Setlist hinzu. Notenwart löscht Stück A. Dirigent öffnet Setlist-Detail.

**Erwartetes Verhalten:**
- SetlistEntry bleibt erhalten, `piece_id` wird auf NULL gesetzt (ON DELETE SET NULL)
- Eintrag wird wie Platzhalter behandelt mit Hinweis "Stück nicht mehr verfügbar"
- Optional: Rote Badge "Fehlendes Stück"
- Dirigent kann Eintrag löschen oder durch anderes Stück ersetzen (In-Stück-umwandeln-Button)

---

### E-02: Setlist ohne Stücke spielen
**Szenario:** Musiker versucht, leere Setlist im Spielmodus zu öffnen.

**Erwartetes Verhalten:**
- Fehlermeldung: "Diese Setlist enthält keine spielbaren Stücke."
- "Spielen"-Button ist disabled (visuell gedimmt)

---

### E-03: Setlist mit nur Platzhaltern spielen
**Szenario:** Setlist enthält nur Platzhalter, keine echten Stücke.

**Erwartetes Verhalten:**
- Spielmodus startet, zeigt aber sofort: "Alle Stücke in dieser Setlist sind Platzhalter. Keine Noten verfügbar."
- Liste der Platzhalter anzeigen mit Hinweis "Noch nicht digitalisiert"

---

### E-04: Timing-Kalkulation mit fehlenden Dauer-Angaben
**Szenario:** Setlist hat Startzeit 20:00. Stück 1: 4 Min., Stück 2: keine Angabe, Stück 3: 5 Min.

**Erwartetes Verhalten:**
- Stück 1: Start 20:00, Ende 20:04
- Stück 2: Start 20:04, Ende "?" (unbekannt)
- Stück 3: Start "?", Ende "?" (kann nicht berechnet werden, da vorherige Dauer fehlt)
- Hinweis oben: "Timing unvollständig — 1 Stück ohne Dauer-Angabe"

---

### E-05: Drag & Drop bei Netzwerkfehler
**Szenario:** Dirigent verschiebt Stück 3 an Position 1. Netzwerk fällt aus, PATCH schlägt fehl.

**Erwartetes Verhalten:**
- Optimistic Update im UI (sofortige Anzeige)
- Nach Fehler: Rollback auf alte Positionen
- Error-Toast: "Reihenfolge konnte nicht gespeichert werden. Erneut versuchen?"
- Retry-Button im Toast

---

### E-06: Zwei Nutzer bearbeiten gleichzeitig Setlist
**Szenario:** Dirigent A fügt Stück hinzu. Dirigent B löscht gleichzeitig anderes Stück.

**Erwartetes Verhalten:**
- Backend: Optimistic Locking via `aktualisiert_am` Timestamp
- Wenn Konflikt: Letzter Schreiber gewinnt (Last-Write-Wins)
- Optional: WebSocket-Broadcast an andere Nutzer "Setlist wurde von {Name} geändert" → Reload-Hinweis

---

### E-07: Setlist mit 100+ Einträgen (Performance)
**Szenario:** Marschmusik-Setlist mit 150 Einträgen (gesamtes Repertoire).

**Erwartetes Verhalten:**
- Virtualisierung im UI (nur sichtbare Einträge rendern)
- Preloading im Spielmodus beschränkt auf nächste 5 Stücke (nicht alle 150)
- Cursor-Pagination in API wenn > 100 Einträge (optional)

---

### E-08: Platzhalter in Stück umwandeln — Stück existiert nicht mehr
**Szenario:** Notenwart klickt "In Stück umwandeln", wählt Stück. Stück wird zwischen Auswahl und API-Call gelöscht.

**Erwartetes Verhalten:**
- API-Response: 404 Not Found
- Fehlermeldung: "Das ausgewählte Stück ist nicht mehr verfügbar."
- Platzhalter bleibt unverändert

---

### E-09: Setlist spielen ohne passende Stimme
**Szenario:** Musiker (Klarinette) öffnet Setlist. Stück 2 hat keine Klarinetten-Stimme.

**Erwartetes Verhalten:**
- Fallback-Logik wie in MS1 Stimmenauswahl-Spec
- Wenn keine Stimme verfügbar: Stück wird übersprungen mit Hinweis "Keine passende Stimme für dein Instrument"
- Optionaler Button "Andere Stimme wählen"

---

### E-10: Setlist mit Pausen — Timing über Mitternacht
**Szenario:** Setlist startet 23:45, enthält 3 Stücke à 20 Min. → Ende 00:45 (nächster Tag).

**Erwartetes Verhalten:**
- Zeiten korrekt berechnen: 23:45 → 00:05 → 00:25 → 00:45
- Keine Fehler bei Tag-Wechsel
- Optional: Warnung "Konzert endet nach Mitternacht"

---

## 8. Abhängigkeiten

### 8.1 Von MS1

| Feature | Abhängigkeit | Grund |
|---------|-------------|-------|
| **Kapellenverwaltung** | Benötigt `bands`-Tabelle und Rollensystem | Setlists gehören zu Kapellen, Berechtigungen basieren auf Rollen |
| **Notenbank** | Benötigt `pieces`-Tabelle | Setlist-Einträge referenzieren Stücke |
| **Spielmodus** | Erweiterung des bestehenden Players | Setlist-Modus baut auf Player-Logik auf |
| **Stimmenauswahl** | Fallback-Logik | Im Setlist-Modus müssen Stimmen aufgelöst werden |
| **Authentifizierung** | JWT-Auth | API-Endpunkte sind geschützt |
| **Konfigurationssystem** | Optional: Setlist-Modus-Einstellungen in User-Config | Z.B. "Auto-Wechsel aktivieren" |

### 8.2 Von MS2 (parallel)

| Feature | Beziehung | Details |
|---------|-----------|---------|
| **Konzertplanung** | Setlist wird mit Termin verknüpft | Termine haben optional `setlist_id` (siehe separate Spec) |
| **GEMA-Meldung** | Setlist als Datenquelle | GEMA-Export liest Setlist-Einträge aus |
| **Dirigenten-Mastersteuerung** | Song-Broadcast nutzt Setlist-Context | Dirigent broadcasted Stück aus Setlist |

### 8.3 Für MS3+

| Feature | Vorbereitung | Details |
|---------|-------------|---------|
| **Setlist-Vorlagen** | Datenmodell erlaubt Duplikation | MS3: Templates als spezielle Setlists |
| **AI-Setlist-Generierung** | Metadaten (Typ, Dauer) vorhanden | MS3: "Erstelle Setlist für 60 Min Marschmusik" |
| **Cloud-Sync** | Setlists sind kapellen-gebunden | MS3: Offline-Setlists synchronisieren |

---

## 9. Definition of Done

### 9.1 Funktionale Anforderungen

- [ ] Dirigent kann Setlist mit Name, Typ, Datum erstellen
- [ ] Stücke können per Picker hinzugefügt werden
- [ ] Platzhalter-Einträge (ohne Stück-Referenz) können erstellt werden
- [ ] Drag & Drop Umsortierung funktioniert auf Touch und Desktop
- [ ] Geschätzte Dauer pro Eintrag kann eingegeben werden
- [ ] Start-/Endzeiten werden basierend auf Startzeit + Dauer berechnet
- [ ] Gesamtdauer wird summiert und angezeigt
- [ ] Pauseneinträge können für Timing erstellt werden
- [ ] Setlist-Modus im Player: Nahtloser Übergang zwischen Stücken
- [ ] Platzhalter werden im Spielmodus übersprungen (mit Hinweis)
- [ ] Vor/Zurück-Navigation im Setlist-Modus
- [ ] Preloading der nächsten Seiten (< 200ms Übergangszeit)
- [ ] Setlist kann bearbeitet, dupliziert, gelöscht werden
- [ ] Platzhalter kann in Stück umgewandelt werden
- [ ] Setlist-Übersicht mit Filter, Suche, Sortierung
- [ ] Berechtigungen: Nur Dirigent/Admin/Notenwart darf Setlists bearbeiten
- [ ] Audit-Log protokolliert alle Änderungen

### 9.2 Testing

- [ ] **Unit-Tests:**
  - Timing-Kalkulation (Startzeit + Dauer → Endzeit)
  - Gesamtdauer-Summierung (inkl. Pausen)
  - Position-Update-Logik (Drag & Drop)
  - Berechtigungs-Checks
- [ ] **Integration-Tests:**
  - POST /setlists → Setlist erstellt
  - POST /eintraege → Stück hinzugefügt
  - PATCH /positionen → Reihenfolge geändert
  - DELETE /setlists → Setlist gelöscht
  - Audit-Log-Einträge werden korrekt erstellt
- [ ] **Widget-Tests:**
  - Setlist-Übersicht rendert alle Setlists
  - Setlist-Detail zeigt alle Einträge
  - Drag & Drop UI funktioniert
  - Filter + Suche funktionieren
- [ ] **E2E-Tests:**
  - Setlist erstellen → 3 Stücke hinzufügen → Umsortieren → Spielen
  - Setlist mit Platzhalter erstellen → Im Spielmodus öffnen → Platzhalter wird übersprungen
  - Setlist mit Timing → Alle Zeiten korrekt berechnet
- [ ] **Performance-Tests:**
  - Übergangszeit im Setlist-Modus < 200ms (mit Preloading)
  - Setlist mit 100 Einträgen lädt in < 2s
- [ ] **3-Reviewer Code Review:** Sonnet 4.6, Opus 4.6, GPT 5.4 — Stark reviewed Reviews
- [ ] **UX-Review** von Wanda für alle Setlist-Screens

### 9.3 Dokumentation

- [ ] API-Dokumentation (Swagger/OpenAPI) ist vollständig
- [ ] DB-Migrationen sind dokumentiert
- [ ] User-Flows sind in UX-Spec dokumentiert (Wanda)
- [ ] Edge Cases sind getestet und dokumentiert

### 9.4 Non-Funktionale Anforderungen

- [ ] Mobile-responsive (Phone, Tablet, Desktop)
- [ ] Touch-Gesten und Keyboard-Shortcuts funktionieren
- [ ] Dark Mode / Light Mode für alle Screens
- [ ] i18n-Strings externalisiert (Deutsch für MS2)
- [ ] Offline-Unterstützung: Setlists werden lokal gecacht (Client-DB)
- [ ] Accessibility: WCAG 2.1 AA (Keyboard-Navigation, Screen Reader)

### 9.5 Deployment

- [ ] Backend deployed auf Production
- [ ] Frontend deployed (iOS, Android, Web, Windows)
- [ ] Monitoring: Application Insights trackt Setlist-API-Calls
- [ ] Fehler-Tracking: Sentry captured Setlist-Errors

---

**Ende der Spezifikation**

---

**Nächste Schritte:**
1. UX-Design: Wanda erstellt `docs/ux-specs/setlist.md` (Wireframes, User-Flows)
2. Backend-Implementierung: Banner erstellt SetlistsController, Service, Repository
3. Frontend-Implementierung: Romanoff erstellt Setlist-Screens (Übersicht, Detail, Player-Integration)
4. Testing: Test-Agents erstellen Unit/Integration/E2E-Tests
5. Review: 3-Reviewer Code Review + UX-Review

---

**Approval:** Thomas
