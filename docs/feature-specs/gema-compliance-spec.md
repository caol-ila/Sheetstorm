# Feature-Spezifikation: GEMA & Compliance

> **Issue:** TBD  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** Setlist-Feature (MS1), AI-Adapter-Pattern (MS1)  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD (Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien)
4. [API Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [AI-Integration](#6-ai-integration)
7. [Berechtigungsmatrix](#7-berechtigungsmatrix)
8. [Edge Cases](#8-edge-cases)
9. [Abhängigkeiten](#9-abhängigkeiten)
10. [Definition of Done](#10-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Das Kernproblem

**Rechtliche Pflicht:** Jede öffentliche Aufführung urheberrechtlich geschützter Musik in Deutschland, Österreich und der Schweiz muss bei der zuständigen Verwertungsgesellschaft (GEMA, AKM, SUISA) gemeldet werden. 

Das heutige Problem:
- Dirigenten und Vorstände müssen nach jedem Konzert manuell eine Liste der aufgeführten Werke erstellen
- GEMA-Werknummern müssen auf der GEMA-Website recherchiert werden (umständliche Suche)
- Fehlerhafte oder fehlende Meldungen führen zu Bußgeldern und Lizenzproblemen
- Die Frist für die Meldung beträgt in der Regel **14 Tage nach der Aufführung**
- Export-Formate sind komplex (GEMA-XML mit Pflichtfeldern wie Werktitel, Urheber, Verlag, Werknummer, Aufführungsdatum)

**Unser Ansatz:** Automatische Generierung der GEMA-Meldung aus einer bestehenden Setlist → AI-gestützte Werknummern-Suche → Export in Zielformat → Erinnerung vor Fristablauf.

### 1.2 Ziel

Vereinsvorstände und Dirigenten können mit einem Tap eine vollständige GEMA-Meldung erstellen, Werknummern automatisch recherchieren lassen und das Ergebnis direkt im geforderten Format exportieren — ohne manuelle Recherche oder Excel-Frickelei.

### 1.3 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| GEMA-Meldung aus Setlist generieren | Online-Einreichung direkt über GEMA API |
| GEMA-Werknummern-Suche mit AI | Abrechnung von Tantiemen |
| Export: GEMA-XML, CSV, PDF | AKM/SUISA-spezifische XML-Formate |
| Verwertungsgesellschaft-Konfiguration (GEMA, SUISA, AKM) | GVL-Meldung (Leistungsschutzrechte) |
| Erinnerungen (Push + In-App) für ausstehende Meldungen | Automatische Berechnung von GEMA-Gebühren |
| Manuelle Nachbearbeitung der Meldung | Import aus GEMA-Datenbank |
| Historie: vergangene Meldungen einsehen | Mehrsprachige Meldungen (nur DE für MS2) |

### 1.4 Kontext

#### Was ist eine GEMA-Meldung?

Eine GEMA-Meldung (offiziell: **Musikfolge**) ist eine strukturierte Liste aller bei einer Veranstaltung aufgeführten Werke. Sie enthält:

- **Veranstaltungsdaten:** Datum, Ort, Art der Veranstaltung (Konzert, Fest, etc.), Veranstalter
- **Werkliste:** Für jedes aufgeführte Werk:
  - Werktitel
  - Komponist(en) / Urheber
  - Verlag
  - **GEMA-Werknummer** (falls vorhanden)
  - Bearbeiter (bei Arrangements)
  - Dauer der Aufführung (optional, aber empfohlen)

#### GEMA-Werknummer

Eine eindeutige 9-stellige Kennung, die jedem im GEMA-Repertoire registrierten Werk zugeordnet ist (z.B. `123456789`). Sie dient der eindeutigen Identifikation und beschleunigt die Bearbeitung. Nicht alle Werke haben eine GEMA-Werknummer (z.B. gemeinfreie Werke oder Werke aus dem Ausland, die nicht im GEMA-Repertoire registriert sind).

#### Verwertungsgesellschaften

- **GEMA (Deutschland):** Gesellschaft für musikalische Aufführungs- und mechanische Vervielfältigungsrechte
- **AKM (Österreich):** Staatlich genehmigte Gesellschaft der Autoren, Komponisten und Musikverleger
- **SUISA (Schweiz):** Schweizerische Gesellschaft für die Rechte der Urheber musikalischer Werke

Alle drei haben ähnliche Anforderungen, aber unterschiedliche Export-Formate und Fristen.

### 1.5 Marktdifferenzierung

**Keiner der bekannten Wettbewerber (forScore, MobileSheets, Konzertmeister, BAND, Notion, StaffPad) bietet eine GEMA-Compliance-Funktion.** Dies ist ein Alleinstellungsmerkmal für Sheetstorm im DACH-Raum.

---

## 2. User Stories

### US-01: GEMA-Meldung aus Setlist generieren

> *Als Dirigent möchte ich nach einem Konzert mit einem Tap eine GEMA-Meldung aus der verwendeten Setlist erstellen, damit ich nicht manuell eine Werkliste tippen muss.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert eine bestehende Setlist, aber keine Werknummern-Recherche
- **N**egotiable: Export-Format kann variieren (XML, CSV, PDF)
- **V**aluable: Reduziert manuelle Arbeit von 30 Minuten auf unter 1 Minute
- **E**stimatable: ~1 Sprint
- **S**mall: Fokus auf Generierung — Export ist US-03
- **T**estable: ✅ Meldung enthält alle Werke aus der Setlist mit Metadaten

**Akzeptanzkriterien:**
1. Nach einem Konzert kann der Dirigent/Admin auf "+ GEMA-Meldung erstellen" tippen (aus Setlist-Detailansicht)
2. Dialog öffnet sich: **Veranstaltungsdaten** eingeben
   - Datum (vorausgefüllt: Konzertdatum aus Setlist, falls vorhanden)
   - Ort (vorausgefüllt: Kapellen-Ort, editierbar)
   - Veranstaltungsart (Dropdown: "Konzert", "Fest", "Gottesdienst", "Sonstiges")
   - Veranstalter (vorausgefüllt: Kapellenname, editierbar)
3. Eine neue `GemaMeldung`-Entität wird erstellt mit Status "Entwurf"
4. Für jedes Stück in der Setlist wird ein `GemaMeldungEintrag` erstellt:
   - Werktitel (aus Stück-Metadaten)
   - Komponist (aus Stück-Metadaten)
   - Verlag (aus Stück-Metadaten, falls vorhanden)
   - GEMA-Werknummer (leer oder aus Stück-Metadaten, falls vorhanden)
   - Bearbeiter (aus Stück-Metadaten, falls Arrangement)
5. Die Meldung ist nach Erstellung editierbar (Werke hinzufügen, entfernen, Metadaten ändern)
6. **Fehlerfall:** Setlist ist leer → Fehlermeldung "Setlist enthält keine Stücke"
7. **Fehlerfall:** Veranstaltungsdatum liegt mehr als 60 Tage zurück → Warnung "Frist möglicherweise überschritten"

---

### US-02: AI-gestützte GEMA-Werknummern-Suche

> *Als Notenwart möchte ich für ein Stück automatisch die GEMA-Werknummer recherchieren lassen, damit ich nicht die GEMA-Website manuell durchsuchen muss.*

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert unabhängig von der Meldungs-Erstellung (auch bei Stück-Metadaten-Bearbeitung)
- **N**egotiable: Anzahl der Provider (zunächst nur ein AI-Provider)
- **V**aluable: GEMA-Recherche dauert aktuell 2-5 Minuten pro Werk — AI reduziert dies auf Sekunden
- **E**stimatable: ~1 Sprint (AI-Adapter-Pattern bereits etabliert)
- **S**mall: Fokus auf Suche — Validierung ist separate Concern
- **T**estable: ✅ AI liefert Werknummer oder "nicht gefunden"

**Akzeptanzkriterien:**
1. In der GEMA-Meldung kann der Nutzer auf "🔍 Werknummer suchen" neben einem Eintrag tippen
2. AI-Provider erhält als Input:
   - Werktitel
   - Komponist(en)
   - Verlag (falls vorhanden)
3. AI durchsucht das GEMA-Repertoire (via API oder Web-Scraping, TBD)
4. Ergebnis: Liste von Vorschlägen mit:
   - Werknummer
   - Werktitel (GEMA-Schreibweise)
   - Komponist(en)
   - Verlag
   - Konfidenz-Score (0-100%)
5. Nutzer kann einen Vorschlag auswählen → Werknummer wird übernommen
6. Nutzer kann Vorschlag ablehnen → Werknummer bleibt leer (manuelle Eingabe möglich)
7. **Bulk-Suche:** Button "Alle fehlenden Werknummern suchen" → AI sucht für alle Einträge ohne Werknummer
8. **Fehlerfall:** Werk nicht im GEMA-Repertoire gefunden → Hinweis "Keine Werknummer gefunden. Möglicherweise gemeinfrei oder nicht GEMA-registriert."
9. **Fehlerfall:** AI-Provider nicht erreichbar → Fehlermeldung "AI-Suche vorübergehend nicht verfügbar. Bitte später erneut versuchen."
10. **Audit-Log:** Jede AI-Suche wird protokolliert (Timestamp, Input, Output, akzeptierter Vorschlag)

**AI-Provider-Strategie:**
- **Phase 1 (MS2):** Azure OpenAI mit Web-Search-Fähigkeit (via Bing) oder GEMA-Repertoire-Scraping
- **Phase 2 (MS3+):** Direkter GEMA-API-Zugang (falls GEMA eine öffentliche API bereitstellt)

---

### US-03: Export in GEMA-XML, CSV, PDF

> *Als Admin möchte ich die fertige GEMA-Meldung als GEMA-XML, CSV oder PDF exportieren, damit ich sie bei der GEMA einreichen oder archivieren kann.*

**Kriterien (INVEST):**
- **I**ndependent: Export funktioniert unabhängig von AI-Suche
- **N**egotiable: Anzahl der Export-Formate (XML ist Pflicht, CSV/PDF nice-to-have)
- **V**aluable: Ohne Export keine Einreichung → Feature wäre nutzlos
- **E**stimatable: ~0.5 Sprints
- **S**mall: Reines Transformation-Feature
- **T**estable: ✅ Export entspricht GEMA-XML-Schema

**Akzeptanzkriterien:**
1. Button "Exportieren" öffnet Format-Auswahl: GEMA-XML, CSV, PDF
2. **GEMA-XML:**
   - Basiert auf dem offiziellen GEMA-XML-Schema (Version 2.0, Stand 2024)
   - Pflichtfelder: `<Veranstaltung>`, `<Werkliste>`, jedes Werk mit `<Werktitel>`, `<Urheber>`, `<Aufführungsdatum>`
   - Optionale Felder: `<GEMAWerknummer>`, `<Verlag>`, `<Bearbeiter>`, `<Dauer>`
   - Encoding: UTF-8 mit BOM (GEMA-Anforderung)
   - Dateiname: `GEMA_Meldung_{Kapellenname}_{Datum}.xml`
3. **CSV:**
   - Spalten: Werktitel, Komponist, Verlag, GEMA-Werknummer, Bearbeiter, Dauer
   - Header-Zeile enthalten
   - Encoding: UTF-8 mit BOM (Excel-Kompatibilität)
   - Dateiname: `GEMA_Meldung_{Kapellenname}_{Datum}.csv`
4. **PDF:**
   - Kopfzeile: Kapellenname, Veranstaltungsdatum, Ort, Veranstalter
   - Tabelle: Werktitel, Komponist, Verlag, GEMA-Werknummer
   - Fußzeile: "Erstellt mit Sheetstorm am {Datum}"
   - Dateiname: `GEMA_Meldung_{Kapellenname}_{Datum}.pdf`
5. Export-Datei wird in System-Download-Ordner gespeichert (Desktop/Mobile) oder per Share-Sheet geteilt (Mobile)
6. Nach erfolgreichem Export: Status der Meldung wechselt von "Entwurf" zu "Exportiert" (Timestamp wird gespeichert)
7. **Fehlerfall:** Pflichtfelder fehlen (Werktitel oder Komponist leer) → Validierungsfehler mit Liste der unvollständigen Einträge
8. **Fehlerfall:** Export schlägt fehl (Dateisystem-Fehler) → Fehlermeldung mit Retry-Option

**GEMA-XML-Beispiel (vereinfacht):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GEMAMeldung xmlns="http://www.gema.de/schema/v2" version="2.0">
  <Veranstaltung>
    <Veranstalter>Blaskapelle Musterstadt</Veranstalter>
    <Datum>2026-03-20</Datum>
    <Ort>Stadthalle Musterstadt</Ort>
    <Art>Konzert</Art>
  </Veranstaltung>
  <Werkliste>
    <Werk>
      <Werktitel>An der schönen blauen Donau</Werktitel>
      <Urheber>Johann Strauss (Sohn)</Urheber>
      <Verlag>Musikverlag XY</Verlag>
      <GEMAWerknummer>123456789</GEMAWerknummer>
      <Dauer>PT8M30S</Dauer>
    </Werk>
    <Werk>
      <Werktitel>Böhmischer Traum</Werktitel>
      <Urheber>Karel Komzák</Urheber>
      <Verlag/>
      <GEMAWerknummer/>
      <Bearbeiter>Max Mustermann</Bearbeiter>
      <Dauer>PT4M15S</Dauer>
    </Werk>
  </Werkliste>
</GEMAMeldung>
```

---

### US-04: Verwertungsgesellschaft konfigurieren

> *Als Admin einer österreichischen Kapelle möchte ich die zuständige Verwertungsgesellschaft auf AKM umstellen, damit Exporte im richtigen Format erfolgen.*

**Kriterien (INVEST):**
- **I**ndependent: Konfiguration ist pro Kapelle, keine globale Einstellung
- **N**egotiable: Anzahl der unterstützten Gesellschaften (GEMA, AKM, SUISA für MS2; mehr in MS3+)
- **V**aluable: Macht Sheetstorm international nutzbar (DACH-Raum)
- **E**stimatable: ~0.5 Sprints
- **S**mall: Primär Konfiguration + Format-Switch
- **T**estable: ✅ Export-Format ändert sich entsprechend der Auswahl

**Akzeptanzkriterien:**
1. In Kapellen-Einstellungen gibt es einen Abschnitt "Verwertungsgesellschaft"
2. Dropdown-Auswahl:
   - **GEMA (Deutschland)** — Export: GEMA-XML
   - **AKM (Österreich)** — Export: CSV (AKM hat kein XML-Format)
   - **SUISA (Schweiz)** — Export: CSV (SUISA hat kein XML-Format)
   - **Keine** — Export nur als CSV/PDF (für Kapellen außerhalb DACH)
3. Default: GEMA (Deutschland)
4. Änderung ist nur für Admins möglich
5. Änderung wirkt sich auf alle **zukünftigen** GEMA-Meldungen aus (bestehende behalten ihr ursprüngliches Format)
6. Export-Dialog zeigt nur die für die gewählte Gesellschaft relevanten Formate:
   - GEMA: XML, CSV, PDF
   - AKM: CSV, PDF
   - SUISA: CSV, PDF
   - Keine: CSV, PDF
7. **Fehlerfall:** Nutzer wählt AKM, hat aber bereits GEMA-Meldungen mit XML exportiert → Hinweis "Bestehende Meldungen bleiben im ursprünglichen Format."

**Hinweis für MS3+:** AKM und SUISA könnten eigene XML-Formate einführen — dann würde dieser Switch erweitert.

---

### US-05: Erinnerung an ausstehende Meldungen

> *Als Dirigent möchte ich 7 Tage nach einem Konzert eine Erinnerung erhalten, falls ich die GEMA-Meldung noch nicht erstellt habe, damit ich die Frist nicht versäume.*

**Kriterien (INVEST):**
- **I**ndependent: Erinnerungssystem ist unabhängig von der Meldungs-Erstellung
- **N**egotiable: Zeitpunkt der Erinnerung konfigurierbar (MS3+)
- **V**aluable: Verhindert Bußgelder durch vergessene Meldungen
- **E**estimatable: ~0.5 Sprints (Notification-Infrastruktur bereits vorhanden)
- **S**mall: Reines Notification-Feature
- **T**estable: ✅ Notification wird nach Ablauf der Frist ausgelöst

**Akzeptanzkriterien:**
1. **Trigger:** 7 Tage nach dem Konzertdatum (aus Setlist) prüft das System, ob eine GEMA-Meldung mit Status "Exportiert" existiert
2. Falls nicht: **Push-Notification** wird an Dirigent und Admin gesendet:
   - Titel: "🔔 GEMA-Meldung ausstehend"
   - Text: "Konzert '{Setlist-Name}' am {Datum} benötigt eine GEMA-Meldung. Frist: {Datum + 14 Tage}."
3. **In-App-Badge:** Roter Badge auf Setlist-Tab mit Anzahl der überfälligen Meldungen
4. Tap auf Notification führt direkt zur Setlist → "+ GEMA-Meldung erstellen"
5. **Wiederholung:** Wenn nach 12 Tagen (2 Tage vor Fristende) immer noch keine Meldung existiert → zweite Erinnerung
6. Nach Export (Status "Exportiert") → Erinnerungen stoppen
7. Nutzer kann Erinnerung für eine Setlist deaktivieren (z.B. bei Probe-Setlists ohne öffentliche Aufführung)
8. **Fehlerfall:** Push-Notification-Berechtigung fehlt → In-App-Hinweis "Bitte aktiviere Benachrichtigungen, um Erinnerungen zu erhalten"

**Notification-Timing:**
- 1. Erinnerung: **Tag 7** nach Konzert (Mitte der Frist)
- 2. Erinnerung: **Tag 12** nach Konzert (2 Tage vor Fristende bei 14-Tage-Frist)

**Konfiguration (MS3+):** Admin kann Fristen pro Verwertungsgesellschaft anpassen.

---

### US-06: GEMA-Meldungs-Historie

> *Als Admin möchte ich alle vergangenen GEMA-Meldungen einsehen können, damit ich nachvollziehen kann, welche Werke wann gemeldet wurden.*

**Kriterien (INVEST):**
- **I**ndependent: Historie ist reines Read-Feature
- **N**egotiable: Filter-Optionen (z.B. nach Jahr) können MS3+ sein
- **V**aluable: Erforderlich für Audit und Nachweispflicht (7-Jahres-Aufbewahrungspflicht)
- **E**stimatable: ~0.5 Sprints
- **S**mall: Primär List-View mit Detail-View
- **T**estable: ✅ Alle Meldungen werden korrekt angezeigt

**Akzeptanzkriterien:**
1. Neuer Tab/Seite: "GEMA-Meldungen" (unter Kapellen-Kontext)
2. Liste aller Meldungen, sortiert nach Erstelldatum (neueste zuerst)
3. Jede Zeile zeigt:
   - Veranstaltungsdatum
   - Veranstaltungsort
   - Anzahl der Werke
   - Status: "Entwurf", "Exportiert"
   - Export-Datum (falls exportiert)
4. Tap öffnet Detail-View mit vollständiger Werkliste
5. In Detail-View: "Erneut exportieren"-Button (erstellt neue Export-Datei)
6. **Filterung:** Nach Status (Entwurf / Exportiert)
7. **Suchfunktion:** Suche nach Veranstaltungsort oder Werktitel
8. **Löschen:** Admin kann Meldungen im Status "Entwurf" löschen (Exportierte können nicht gelöscht werden)
9. **Fehlerfall:** Keine Meldungen vorhanden → Empty-State "Noch keine GEMA-Meldungen erstellt"

---

## 3. Akzeptanzkriterien

### Feature-Level Akzeptanzkriterien (Übergreifend)

| ID | Kriterium | Priorität | Testfall |
|----|-----------|-----------|----------|
| **AC-01** | GEMA-Meldung kann aus jeder Setlist mit Status "Abgeschlossen" erstellt werden | P0 | Setlist mit 5 Werken → Meldung enthält alle 5 Werke |
| **AC-02** | AI-Werknummern-Suche liefert mindestens 1 Vorschlag für 80% der bekannten GEMA-Werke | P0 | Testset mit 100 bekannten Werken → Mind. 80 Vorschläge |
| **AC-03** | GEMA-XML-Export entspricht dem offiziellen GEMA-XML-Schema v2.0 | P0 | Export wird von GEMA-Validator akzeptiert |
| **AC-04** | Export-Formate (XML, CSV, PDF) sind korrekt formatiert und lesbar | P0 | Export in Excel/Adobe Reader öffnen |
| **AC-05** | Erinnerungen werden zum richtigen Zeitpunkt (Tag 7, Tag 12) ausgelöst | P1 | Manueller Test mit Zeitstempel-Manipulation |
| **AC-06** | Verwertungsgesellschaft-Wechsel wirkt sich auf Export-Format aus | P1 | GEMA → AKM: XML verschwindet aus Export-Optionen |
| **AC-07** | GEMA-Meldung kann nachträglich bearbeitet werden (Entwurf-Status) | P1 | Werk hinzufügen/entfernen, Metadaten ändern |
| **AC-08** | Exportierte Meldungen sind unveränderlich (Read-Only) | P1 | "Bearbeiten"-Button ist nach Export deaktiviert |
| **AC-09** | Historie zeigt alle Meldungen der letzten 7 Jahre | P2 | Meldungen älter als 7 Jahre werden automatisch archiviert |
| **AC-10** | Manuelle Werknummern-Eingabe ist ohne AI-Suche möglich | P0 | Feld ist editierbar, auch wenn AI keinen Vorschlag liefert |

---

## 4. API Contract

### 4.1 Übersicht

**Basis-URL:** `/api/v1/kapellen/{kapelleId}/gema-meldungen`

**Authentifizierung:** Bearer JWT (in `Authorization`-Header)

**Pagination:** Cursor-basiert (alle Listen-Endpoints)

**Content-Type:** `application/json` (POST/PUT), `application/xml` oder `text/csv` oder `application/pdf` (Export)

**Rollen:** Admin, Dirigent (Vollzugriff); Notenwart, Registerführer, Musiker (Read-Only)

---

### 4.2 Endpoints

#### 4.2.1 GEMA-Meldung erstellen

**POST** `/api/v1/kapellen/{kapelleId}/gema-meldungen`

Erstellt eine neue GEMA-Meldung aus einer Setlist.

**Request Body:**

```json
{
  "setlistId": "550e8400-e29b-41d4-a716-446655440000",
  "veranstaltung": {
    "datum": "2026-03-20",
    "ort": "Stadthalle Musterstadt",
    "art": "Konzert",
    "veranstalter": "Blaskapelle Musterstadt"
  }
}
```

**Response (201 Created):**

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "kapelleId": "123e4567-e89b-12d3-a456-426614174000",
  "setlistId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "Entwurf",
  "veranstaltung": {
    "datum": "2026-03-20",
    "ort": "Stadthalle Musterstadt",
    "art": "Konzert",
    "veranstalter": "Blaskapelle Musterstadt"
  },
  "eintraege": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "werktitel": "An der schönen blauen Donau",
      "komponist": "Johann Strauss (Sohn)",
      "verlag": "Musikverlag XY",
      "gemaWerknummer": null,
      "bearbeiter": null,
      "dauer": "PT8M30S"
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440003",
      "werktitel": "Böhmischer Traum",
      "komponist": "Karel Komzák",
      "verlag": null,
      "gemaWerknummer": null,
      "bearbeiter": "Max Mustermann",
      "dauer": "PT4M15S"
    }
  ],
  "erstelltAm": "2026-03-21T10:30:00Z",
  "exportiertAm": null
}
```

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 400 | Setlist ist leer oder ungültige Veranstaltungsdaten |
| 403 | Nutzer hat keine Berechtigung (nicht Dirigent/Admin) |
| 404 | Setlist nicht gefunden |

---

#### 4.2.2 GEMA-Meldung abrufen

**GET** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}`

**Response (200 OK):**

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "kapelleId": "123e4567-e89b-12d3-a456-426614174000",
  "setlistId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "Exportiert",
  "veranstaltung": {
    "datum": "2026-03-20",
    "ort": "Stadthalle Musterstadt",
    "art": "Konzert",
    "veranstalter": "Blaskapelle Musterstadt"
  },
  "eintraege": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "werktitel": "An der schönen blauen Donau",
      "komponist": "Johann Strauss (Sohn)",
      "verlag": "Musikverlag XY",
      "gemaWerknummer": "123456789",
      "bearbeiter": null,
      "dauer": "PT8M30S"
    }
  ],
  "erstelltAm": "2026-03-21T10:30:00Z",
  "exportiertAm": "2026-03-21T11:15:00Z"
}
```

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 403 | Nutzer gehört nicht zur Kapelle |
| 404 | Meldung nicht gefunden |

---

#### 4.2.3 GEMA-Meldung bearbeiten

**PUT** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}`

Bearbeitet eine Meldung im Status "Entwurf". Exportierte Meldungen sind unveränderlich.

**Request Body:**

```json
{
  "veranstaltung": {
    "ort": "Neue Stadthalle"
  },
  "eintraege": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "gemaWerknummer": "123456789"
    }
  ]
}
```

**Response (200 OK):** Vollständige aktualisierte Meldung (wie in 4.2.2)

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 400 | Meldung ist bereits exportiert (Status = "Exportiert") |
| 403 | Nutzer hat keine Berechtigung (nicht Dirigent/Admin) |
| 404 | Meldung nicht gefunden |

---

#### 4.2.4 GEMA-Meldung löschen

**DELETE** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}`

Löscht eine Meldung im Status "Entwurf". Exportierte Meldungen können nicht gelöscht werden.

**Response (204 No Content)**

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 400 | Meldung ist bereits exportiert |
| 403 | Nutzer hat keine Berechtigung (nicht Admin) |
| 404 | Meldung nicht gefunden |

---

#### 4.2.5 GEMA-Meldungen auflisten

**GET** `/api/v1/kapellen/{kapelleId}/gema-meldungen`

Listet alle GEMA-Meldungen der Kapelle mit Cursor-Pagination.

**Query-Parameter:**

- `cursor` (optional): Pagination-Cursor
- `limit` (optional): Anzahl der Ergebnisse (Default: 20, Max: 100)
- `status` (optional): Filter nach Status ("Entwurf" oder "Exportiert")

**Response (200 OK):**

```json
{
  "data": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "status": "Exportiert",
      "veranstaltung": {
        "datum": "2026-03-20",
        "ort": "Stadthalle Musterstadt",
        "art": "Konzert"
      },
      "anzahlWerke": 12,
      "erstelltAm": "2026-03-21T10:30:00Z",
      "exportiertAm": "2026-03-21T11:15:00Z"
    }
  ],
  "pagination": {
    "nextCursor": "eyJpZCI6IjY2MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMSJ9",
    "hasMore": true
  }
}
```

---

#### 4.2.6 GEMA-Werknummer suchen (AI)

**POST** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}/eintraege/{eintragId}/werknummer-suchen`

Startet eine AI-gestützte Suche nach der GEMA-Werknummer.

**Request Body:**

```json
{
  "werktitel": "An der schönen blauen Donau",
  "komponist": "Johann Strauss (Sohn)",
  "verlag": "Musikverlag XY"
}
```

**Response (200 OK):**

```json
{
  "vorschlaege": [
    {
      "gemaWerknummer": "123456789",
      "werktitel": "An der schönen blauen Donau, Walzer, op. 314",
      "komponist": "Strauss, Johann (Sohn)",
      "verlag": "Musikverlag XY GmbH",
      "konfidenz": 95
    },
    {
      "gemaWerknummer": "987654321",
      "werktitel": "An der schönen blauen Donau (Bearbeitung)",
      "komponist": "Strauss, Johann (Sohn)",
      "verlag": "Edition Z",
      "konfidenz": 60
    }
  ]
}
```

**Response (404 Not Found):**

```json
{
  "error": "WERK_NICHT_GEFUNDEN",
  "message": "Keine GEMA-Werknummer gefunden. Möglicherweise gemeinfrei oder nicht GEMA-registriert."
}
```

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 403 | Nutzer hat keine Berechtigung (nicht Dirigent/Admin/Notenwart) |
| 404 | Eintrag nicht gefunden oder Werk nicht im GEMA-Repertoire |
| 503 | AI-Provider nicht erreichbar |

---

#### 4.2.7 Alle fehlenden Werknummern suchen (Bulk)

**POST** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}/werknummern-bulk-suchen`

Startet AI-Suche für alle Einträge ohne Werknummer. Asynchron (Background-Job).

**Response (202 Accepted):**

```json
{
  "jobId": "990e8400-e29b-41d4-a716-446655440099",
  "status": "IN_PROGRESS",
  "startedAt": "2026-03-21T12:00:00Z"
}
```

**Status-Polling:**

**GET** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}/werknummern-jobs/{jobId}`

**Response (200 OK — Job läuft noch):**

```json
{
  "jobId": "990e8400-e29b-41d4-a716-446655440099",
  "status": "IN_PROGRESS",
  "bearbeitet": 5,
  "gesamt": 12,
  "startedAt": "2026-03-21T12:00:00Z"
}
```

**Response (200 OK — Job abgeschlossen):**

```json
{
  "jobId": "990e8400-e29b-41d4-a716-446655440099",
  "status": "COMPLETED",
  "bearbeitet": 12,
  "gesamt": 12,
  "gefunden": 9,
  "nichtGefunden": 3,
  "startedAt": "2026-03-21T12:00:00Z",
  "completedAt": "2026-03-21T12:02:30Z"
}
```

---

#### 4.2.8 GEMA-Meldung exportieren

**GET** `/api/v1/kapellen/{kapelleId}/gema-meldungen/{meldungId}/export?format={format}`

Exportiert die Meldung in das gewünschte Format.

**Query-Parameter:**

- `format`: `xml`, `csv`, oder `pdf`

**Response (200 OK):**

- Content-Type: `application/xml`, `text/csv`, oder `application/pdf`
- Content-Disposition: `attachment; filename="GEMA_Meldung_Blaskapelle_Musterstadt_2026-03-20.xml"`

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 400 | Format nicht unterstützt für gewählte Verwertungsgesellschaft |
| 403 | Nutzer hat keine Berechtigung |
| 422 | Pflichtfelder fehlen (z.B. Werktitel oder Komponist leer) |

---

#### 4.2.9 Verwertungsgesellschaft konfigurieren

**PUT** `/api/v1/kapellen/{kapelleId}/einstellungen/verwertungsgesellschaft`

Ändert die zuständige Verwertungsgesellschaft.

**Request Body:**

```json
{
  "verwertungsgesellschaft": "GEMA"
}
```

Zulässige Werte: `"GEMA"`, `"AKM"`, `"SUISA"`, `"KEINE"`

**Response (200 OK):**

```json
{
  "verwertungsgesellschaft": "GEMA",
  "unterstuetzteFormate": ["xml", "csv", "pdf"]
}
```

**Fehler:**

| Code | Bedeutung |
|------|-----------|
| 400 | Ungültiger Wert |
| 403 | Nutzer ist kein Admin |

---

### 4.3 Fehlerbehandlung

Alle Fehler folgen dem Standard-Fehlerformat:

```json
{
  "error": "ERROR_CODE",
  "message": "Menschenlesbare Fehlerbeschreibung",
  "details": {
    "field": "gemaWerknummer",
    "reason": "Feld ist ungültig"
  }
}
```

**Standard-Fehlercodes:**

| Code | HTTP Status | Beschreibung |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | JWT fehlt oder ungültig |
| `FORBIDDEN` | 403 | Nutzer hat keine Berechtigung |
| `NOT_FOUND` | 404 | Ressource nicht gefunden |
| `VALIDATION_ERROR` | 400 | Eingabedaten sind ungültig |
| `MELDUNG_ALREADY_EXPORTED` | 400 | Meldung ist bereits exportiert und unveränderlich |
| `WERK_NICHT_GEFUNDEN` | 404 | GEMA-Werk nicht gefunden |
| `AI_PROVIDER_UNAVAILABLE` | 503 | AI-Service nicht erreichbar |
| `EXPORT_FORMAT_NOT_SUPPORTED` | 400 | Export-Format für Verwertungsgesellschaft nicht unterstützt |
| `MISSING_REQUIRED_FIELDS` | 422 | Pflichtfelder fehlen für Export |

---

## 5. Datenmodell

### 5.1 Tabelle: `gema_meldungen`

Speichert GEMA-Meldungen pro Kapelle.

```sql
CREATE TABLE gema_meldungen (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    setlist_id UUID NOT NULL REFERENCES setlists(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Entwurf', 'Exportiert')),
    
    -- Veranstaltungsdaten
    veranstaltung_datum DATE NOT NULL,
    veranstaltung_ort VARCHAR(200) NOT NULL,
    veranstaltung_art VARCHAR(50) NOT NULL CHECK (veranstaltung_art IN ('Konzert', 'Fest', 'Gottesdienst', 'Sonstiges')),
    veranstalter VARCHAR(200) NOT NULL,
    
    -- Metadaten
    erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    erstellt_von UUID NOT NULL REFERENCES users(id),
    exportiert_am TIMESTAMPTZ,
    exportiert_von UUID REFERENCES users(id),
    
    CONSTRAINT fk_kapelle FOREIGN KEY (kapelle_id) REFERENCES kapellen(id),
    CONSTRAINT fk_setlist FOREIGN KEY (setlist_id) REFERENCES setlists(id),
    CONSTRAINT fk_erstellt_von FOREIGN KEY (erstellt_von) REFERENCES users(id),
    CONSTRAINT fk_exportiert_von FOREIGN KEY (exportiert_von) REFERENCES users(id)
);

CREATE INDEX idx_gema_meldungen_kapelle ON gema_meldungen(kapelle_id);
CREATE INDEX idx_gema_meldungen_status ON gema_meldungen(status);
CREATE INDEX idx_gema_meldungen_datum ON gema_meldungen(veranstaltung_datum DESC);
```

---

### 5.2 Tabelle: `gema_meldung_eintraege`

Speichert einzelne Werke innerhalb einer GEMA-Meldung.

```sql
CREATE TABLE gema_meldung_eintraege (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meldung_id UUID NOT NULL REFERENCES gema_meldungen(id) ON DELETE CASCADE,
    
    -- Werkdaten
    werktitel VARCHAR(300) NOT NULL,
    komponist VARCHAR(200) NOT NULL,
    verlag VARCHAR(200),
    gema_werknummer VARCHAR(20),
    bearbeiter VARCHAR(200),
    dauer INTERVAL, -- ISO 8601 Duration (z.B. 'PT8M30S' für 8:30 Minuten)
    
    -- Reihenfolge in der Meldung
    reihenfolge INT NOT NULL,
    
    -- Metadaten
    erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_meldung FOREIGN KEY (meldung_id) REFERENCES gema_meldungen(id),
    CONSTRAINT uq_meldung_reihenfolge UNIQUE (meldung_id, reihenfolge)
);

CREATE INDEX idx_gema_eintraege_meldung ON gema_meldung_eintraege(meldung_id);
CREATE INDEX idx_gema_eintraege_werknummer ON gema_meldung_eintraege(gema_werknummer) WHERE gema_werknummer IS NOT NULL;
```

---

### 5.3 Tabelle: `kapelle_einstellungen`

Erweitert die bestehende Kapellen-Konfiguration um Verwertungsgesellschaft.

```sql
ALTER TABLE kapelle_einstellungen
ADD COLUMN verwertungsgesellschaft VARCHAR(20) NOT NULL DEFAULT 'GEMA'
    CHECK (verwertungsgesellschaft IN ('GEMA', 'AKM', 'SUISA', 'KEINE'));
```

---

### 5.4 Tabelle: `gema_ai_suchen` (Audit-Log)

Protokolliert alle AI-Suchen für Nachvollziehbarkeit und Qualitätssicherung.

```sql
CREATE TABLE gema_ai_suchen (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meldung_id UUID NOT NULL REFERENCES gema_meldungen(id) ON DELETE CASCADE,
    eintrag_id UUID NOT NULL REFERENCES gema_meldung_eintraege(id) ON DELETE CASCADE,
    
    -- Input
    input_werktitel VARCHAR(300) NOT NULL,
    input_komponist VARCHAR(200),
    input_verlag VARCHAR(200),
    
    -- Output
    ai_provider VARCHAR(50) NOT NULL, -- 'AzureOpenAI', 'GEMA-API', etc.
    vorschlaege JSONB, -- Array von Vorschlägen mit Konfidenz
    ausgewaehlte_werknummer VARCHAR(20),
    
    -- Metadaten
    durchgefuehrt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    durchgefuehrt_von UUID NOT NULL REFERENCES users(id),
    dauer_ms INT, -- Performance-Tracking
    
    CONSTRAINT fk_meldung FOREIGN KEY (meldung_id) REFERENCES gema_meldungen(id),
    CONSTRAINT fk_eintrag FOREIGN KEY (eintrag_id) REFERENCES gema_meldung_eintraege(id),
    CONSTRAINT fk_user FOREIGN KEY (durchgefuehrt_von) REFERENCES users(id)
);

CREATE INDEX idx_ai_suchen_meldung ON gema_ai_suchen(meldung_id);
CREATE INDEX idx_ai_suchen_eintrag ON gema_ai_suchen(eintrag_id);
CREATE INDEX idx_ai_suchen_datum ON gema_ai_suchen(durchgefuehrt_am DESC);
```

---

### 5.5 Tabelle: `gema_werknummern_jobs` (Bulk-Suche)

Speichert Status von Bulk-Suche-Jobs.

```sql
CREATE TABLE gema_werknummern_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meldung_id UUID NOT NULL REFERENCES gema_meldungen(id) ON DELETE CASCADE,
    
    status VARCHAR(20) NOT NULL CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED')),
    bearbeitet INT NOT NULL DEFAULT 0,
    gesamt INT NOT NULL,
    gefunden INT NOT NULL DEFAULT 0,
    nicht_gefunden INT NOT NULL DEFAULT 0,
    
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    CONSTRAINT fk_meldung FOREIGN KEY (meldung_id) REFERENCES gema_meldungen(id)
);

CREATE INDEX idx_jobs_meldung ON gema_werknummern_jobs(meldung_id);
CREATE INDEX idx_jobs_status ON gema_werknummern_jobs(status);
```

---

## 6. AI-Integration

### 6.1 Adapter-Pattern

Analog zum Noten-Import verwenden wir ein Adapter-Pattern für AI-Provider. Dies ermöglicht den Wechsel zwischen verschiedenen Anbietern ohne Änderung der Business-Logik.

**Interface: `IGEMAWerknummernSuche`**

```csharp
public interface IGEMAWerknummernSuche
{
    Task<List<WerknummernVorschlag>> SucheWerknummerAsync(
        string werktitel,
        string komponist,
        string? verlag = null,
        CancellationToken cancellationToken = default
    );
}

public class WerknummernVorschlag
{
    public string GEMAWerknummer { get; set; }
    public string Werktitel { get; set; }
    public string Komponist { get; set; }
    public string? Verlag { get; set; }
    public int Konfidenz { get; set; } // 0-100
}
```

**Implementierungen:**

1. **`AzureOpenAIWerknummernSuche`** (MS2)
   - Verwendet GPT-4 mit Web-Search-Plugin (Bing)
   - Sucht GEMA-Datenbank via Web-Scraping oder GEMA-Website-Suche
   - Prompt: "Finde die GEMA-Werknummer für '{werktitel}' von {komponist}. Gib nur verifizierte Ergebnisse aus der offiziellen GEMA-Datenbank zurück."

2. **`GEMADirectAPISuche`** (MS3+ — falls GEMA API bereitstellt)
   - Direkte Abfrage der GEMA-API
   - Höhere Zuverlässigkeit als Web-Search

3. **`MockWerknummernSuche`** (Testing)
   - Liefert vordefinierte Test-Daten

**Dependency Injection (ASP.NET Core):**

```csharp
services.AddScoped<IGEMAWerknummernSuche, AzureOpenAIWerknummernSuche>();
```

---

### 6.2 AI-Provider-Konfiguration

**Umgebungsvariablen:**

```bash
GEMA_AI_PROVIDER=AzureOpenAI
AZURE_OPENAI_ENDPOINT=https://sheetstorm-ai.openai.azure.com
AZURE_OPENAI_API_KEY=xxx
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
```

**Fallback:** Wenn AI nicht verfügbar ist, wird manuelle Eingabe erzwungen (keine Blockierung des Features).

---

### 6.3 Prompt-Engineering (Azure OpenAI)

**System-Prompt:**

```
Du bist ein Assistent für die GEMA-Werknummern-Recherche. Deine Aufgabe ist es, anhand von Werktitel, Komponist und optional Verlag die korrekte GEMA-Werknummer zu finden. Nutze die offizielle GEMA-Datenbank oder GEMA-Website als Quelle. Gib nur verifizierte Ergebnisse zurück. Falls du unsicher bist, gib mehrere Vorschläge mit Konfidenz-Score (0-100%).

Ausgabeformat (JSON):
{
  "vorschlaege": [
    {
      "gemaWerknummer": "123456789",
      "werktitel": "An der schönen blauen Donau, Walzer, op. 314",
      "komponist": "Strauss, Johann (Sohn)",
      "verlag": "Musikverlag XY GmbH",
      "konfidenz": 95
    }
  ]
}

Falls keine Werknummer gefunden wird, gib zurück:
{
  "vorschlaege": [],
  "hinweis": "Werk möglicherweise gemeinfrei oder nicht GEMA-registriert."
}
```

**User-Prompt:**

```
Finde die GEMA-Werknummer für:
- Werktitel: "An der schönen blauen Donau"
- Komponist: "Johann Strauss (Sohn)"
- Verlag: "Musikverlag XY"
```

---

### 6.4 Rate Limiting & Kosten

**Rate Limits:**
- **Einzelsuche:** Max. 10 Anfragen pro Minute pro Nutzer
- **Bulk-Suche:** Max. 1 Job pro Meldung gleichzeitig

**Kosten-Schätzung (Azure OpenAI GPT-4):**
- Pro Anfrage: ~$0.005 (Input + Output Tokens)
- 100 Werke → ~$0.50
- 1000 Kapellen × 10 Konzerte/Jahr × 12 Werke/Konzert = 120.000 Anfragen/Jahr → ~$600/Jahr

**Optimierung:** Caching von häufig angefragten Werken (z.B. "Böhmischer Traum" wird von vielen Kapellen gespielt).

---

## 7. Berechtigungsmatrix

| Rolle | Meldung erstellen | Meldung bearbeiten (Entwurf) | Meldung exportieren | Meldung löschen (Entwurf) | Werknummer suchen (AI) | Meldungs-Historie einsehen | Verwertungsgesellschaft konfigurieren |
|-------|-------------------|----------------------------|---------------------|------------------------|----------------------|--------------------------|-------------------------------------|
| **Admin** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Dirigent** | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Notenwart** | ❌ | ❌ | ❌ | ❌ | ✅ (Read-Only: Vorschläge anzeigen, aber nicht übernehmen) | ✅ | ❌ |
| **Registerführer** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Musiker** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |

**Erklärung:**
- **Meldung erstellen/bearbeiten/exportieren:** Nur Dirigent und Admin (verantwortlich für Aufführungen)
- **Löschen:** Nur Admin (Datenschutz/Audit-Sicherheit)
- **Werknummer suchen:** Notenwart kann AI-Vorschläge sehen, aber nicht übernehmen (nur Dirigent/Admin können Meldung ändern)
- **Historie:** Alle Rollen können Historie einsehen (Transparenz)
- **Verwertungsgesellschaft konfigurieren:** Nur Admin (organisatorische Entscheidung)

---

## 8. Edge Cases

### 8.1 Setlist ohne GEMA-Meldung erforderlich

**Problem:** Nutzer erstellt Setlist für eine Probe (keine öffentliche Aufführung) → GEMA-Meldung nicht nötig, aber Erinnerung wird trotzdem ausgelöst.

**Lösung:** Neues Feld `setlists.erfordert_gema_meldung` (Boolean, Default: `true`). Admin/Dirigent kann bei Erstellung deaktivieren.

---

### 8.2 Werk ist gemeinfrei (keine GEMA-Werknummer)

**Problem:** Beethoven, Mozart, etc. haben keine GEMA-Werknummer → AI findet nichts.

**Lösung:** 
- Hinweis: "Werk möglicherweise gemeinfrei. GEMA-Meldung kann ohne Werknummer erfolgen."
- GEMA-Werknummer bleibt leer (erlaubt im GEMA-XML-Schema)
- Export validiert nicht auf Pflicht-Werknummer

---

### 8.3 Bearbeitung/Arrangement eines gemeinfreien Werks

**Problem:** "Radetzky-Marsch" (gemeinfrei) wurde von Max Mustermann arrangiert → Bearbeiter ist GEMA-pflichtig, aber Original-Komponist (Johann Strauss Sr.) nicht.

**Lösung:**
- Feld `gema_meldung_eintraege.bearbeiter` wird ausgefüllt
- GEMA-XML enthält sowohl `<Urheber>` (Original-Komponist) als auch `<Bearbeiter>`
- AI-Suche berücksichtigt Bearbeiter-Namen

---

### 8.4 Setlist wird nach Meldungs-Erstellung geändert

**Problem:** Nutzer erstellt GEMA-Meldung, fügt danach ein Werk zur Setlist hinzu → Meldung ist veraltet.

**Lösung:**
- Meldung ist **Snapshot** der Setlist zum Zeitpunkt der Erstellung
- Bei Änderung der Setlist nach Meldungs-Erstellung: **Warnung** "Die verknüpfte Setlist wurde geändert. Bitte prüfe die GEMA-Meldung."
- Dirigent kann Meldung manuell aktualisieren (neues Werk hinzufügen)

---

### 8.5 Exportierte Meldung muss korrigiert werden

**Problem:** Nutzer exportiert Meldung, bemerkt danach einen Fehler (z.B. falsche Werknummer).

**Lösung:**
- **Status "Exportiert" bleibt unveränderlich** (Audit-Sicherheit)
- Nutzer kann **neue Meldung** mit korrigierten Daten erstellen (neuer Export)
- Historie zeigt beide Versionen (alte + neue)
- Hinweis: "Eine überarbeitete Version dieser Meldung existiert (siehe Meldung #{ID})"

---

### 8.6 Mehrere Kapellen verwenden dasselbe Werk

**Problem:** Viele Kapellen spielen "Böhmischer Traum" → AI wird hunderte Male für dasselbe Werk angefragt.

**Lösung:**
- **Globaler Werknummern-Cache** (Tabelle `gema_werknummern_cache`)
- Vor AI-Anfrage: Prüfung, ob Werk bereits gecacht ist
- Cache enthält: Werktitel (normalisiert), Komponist, GEMA-Werknummer
- Normalisierung: Kleinschreibung, Sonderzeichen entfernen, Leerzeichen trimmen
- Cache-Invalidierung: Manuell oder nach 365 Tagen (GEMA-Daten ändern sich selten)

**Tabelle:**

```sql
CREATE TABLE gema_werknummern_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    werktitel_normalisiert VARCHAR(300) NOT NULL,
    komponist_normalisiert VARCHAR(200) NOT NULL,
    gema_werknummer VARCHAR(20) NOT NULL,
    werktitel_original VARCHAR(300) NOT NULL,
    komponist_original VARCHAR(200) NOT NULL,
    verlag VARCHAR(200),
    erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cache UNIQUE (werktitel_normalisiert, komponist_normalisiert)
);

CREATE INDEX idx_cache_lookup ON gema_werknummern_cache(werktitel_normalisiert, komponist_normalisiert);
```

---

### 8.7 AI liefert mehrere gleich wahrscheinliche Vorschläge

**Problem:** AI findet 2 Versionen eines Werks (z.B. Original + Arrangement) mit ähnlicher Konfidenz.

**Lösung:**
- Nutzer sieht alle Vorschläge sortiert nach Konfidenz
- Bei Konfidenz < 80%: Gelbe Warnung "Bitte Auswahl überprüfen"
- Bei Konfidenz < 50%: Rote Warnung "Unsicherer Vorschlag — manuelle Recherche empfohlen"
- Nutzer kann "Keine Auswahl" wählen → Werknummer bleibt leer

---

### 8.8 Export schlägt fehl (Dateisystem-Problem)

**Problem:** Kein Speicherplatz oder keine Schreibberechtigung → Export kann nicht gespeichert werden.

**Lösung:**
- Fehlermeldung: "Export fehlgeschlagen. Bitte prüfe deine Speicherberechtigung und versuche es erneut."
- Status bleibt "Entwurf" (Export wird nicht als erfolgt markiert)
- Retry-Button
- Fallback: "Als E-Mail senden" (Export wird an registrierte E-Mail-Adresse gesendet)

---

### 8.9 GEMA-XML-Schema ändert sich

**Problem:** GEMA veröffentlicht neue XML-Schema-Version → bisherige Exporte sind nicht mehr kompatibel.

**Lösung:**
- **Versionierung:** Feld `gema_meldungen.export_schema_version` (Default: "2.0")
- Bei neuer Schema-Version: Migration aller Entwürfe auf neue Version
- Exportierte Meldungen behalten alte Version (Snapshot-Prinzip)
- UI zeigt Hinweis: "Dieses Export-Format basiert auf GEMA-XML-Schema v2.0"

---

### 8.10 Nutzer wechselt Verwertungsgesellschaft nach Erstellung von Meldungen

**Problem:** Kapelle ist von Deutschland nach Österreich umgezogen → alte GEMA-Meldungen, neue AKM-Pflicht.

**Lösung:**
- Bestehende Meldungen behalten ihr ursprüngliches Format (GEMA-XML)
- Neue Meldungen verwenden AKM-Format (CSV)
- Hinweis bei Wechsel: "Bestehende Meldungen bleiben im bisherigen Format. Nur neue Meldungen nutzen das geänderte Format."
- Export-Dialog zeigt jeweils verfügbare Formate basierend auf Meldungs-Erstellungsdatum

---

## 9. Abhängigkeiten

### 9.1 Interne Abhängigkeiten

| Abhängigkeit | Status | Beschreibung |
|--------------|--------|-------------|
| **Setlist-Feature** | ✅ MS1 | GEMA-Meldung wird aus Setlist generiert |
| **Stück-Metadaten** | ✅ MS1 | Werktitel, Komponist, Verlag müssen in `stuecke`-Tabelle vorhanden sein |
| **Notification-System** | ✅ MS1 | Push-Notifications für Erinnerungen |
| **AI-Adapter-Pattern** | ✅ MS1 | Bereits etabliert für Noten-Import |
| **Berechtigungssystem** | ✅ MS1 | Rollenbasierte Zugriffskontrolle (Admin, Dirigent, etc.) |
| **PDF-Export** | 🔶 MS1/MS2 | PDF-Generierung (z.B. für Noten) — falls bereits vorhanden, wiederverwendbar |

### 9.2 Externe Abhängigkeiten

| Abhängigkeit | Kritikalität | Beschreibung |
|--------------|-------------|-------------|
| **Azure OpenAI** | Hoch | AI-Provider für Werknummern-Suche |
| **GEMA-Website** | Mittel | Web-Scraping für Werknummern (falls keine API) |
| **GEMA-API** | Niedrig | Falls verfügbar — MS3+ |
| **SMTP-Server** | Mittel | E-Mail-Versand für Erinnerungen |

### 9.3 Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|-----------|
| **Azure OpenAI nicht verfügbar** | Niedrig | Hoch | Fallback auf manuelle Eingabe; Cache reduziert Anfragen |
| **GEMA-Website ändert Struktur** | Mittel | Hoch | Web-Scraping ist fehleranfällig → langfristig auf GEMA-API migrieren |
| **GEMA-XML-Schema ändert sich** | Niedrig | Mittel | Versionierung + Migration |
| **AI liefert falsche Werknummern** | Mittel | Hoch | Konfidenz-Score + manuelle Review-Möglichkeit; Audit-Log für Qualitätsprüfung |

---

## 10. Definition of Done

### 10.1 Funktionale DoD

- [ ] GEMA-Meldung kann aus einer Setlist mit einem Tap erstellt werden
- [ ] Alle Werke aus der Setlist erscheinen als Einträge in der Meldung
- [ ] AI-Werknummern-Suche liefert Vorschläge mit Konfidenz-Score (≥80% für bekannte Werke)
- [ ] Export-Formate (GEMA-XML, CSV, PDF) sind korrekt formatiert und validierbar
- [ ] GEMA-XML entspricht dem offiziellen GEMA-XML-Schema v2.0
- [ ] Export-Dateien werden korrekt gespeichert (Desktop) oder geteilt (Mobile)
- [ ] Verwertungsgesellschaft-Konfiguration wirkt sich auf verfügbare Export-Formate aus
- [ ] Erinnerungen werden zum richtigen Zeitpunkt (Tag 7, Tag 12) ausgelöst
- [ ] Push-Notifications und In-App-Badge funktionieren
- [ ] Meldungs-Historie zeigt alle vergangenen Meldungen mit Filterung nach Status
- [ ] Exportierte Meldungen sind unveränderlich (Read-Only)
- [ ] Bulk-Werknummern-Suche läuft asynchron ohne UI-Blockierung
- [ ] Cache reduziert redundante AI-Anfragen für häufige Werke
- [ ] Alle Berechtigungen entsprechen der Berechtigungsmatrix

### 10.2 Technische DoD

- [ ] Alle API-Endpoints entsprechen dem API-Contract (Abschnitt 4)
- [ ] Datenbank-Schema ist implementiert und migriert
- [ ] AI-Adapter-Pattern ist implementiert mit Interface `IGEMAWerknummernSuche`
- [ ] Azure OpenAI-Integration funktioniert mit Web-Search
- [ ] Cursor-basierte Pagination ist für alle Listen-Endpoints implementiert
- [ ] Rate Limiting (10 Anfragen/Min) ist implementiert
- [ ] Audit-Log für AI-Suchen ist vollständig
- [ ] Fehlerbehandlung entspricht dem Standard-Fehlerformat
- [ ] Validierung: Pflichtfelder (Werktitel, Komponist) werden geprüft
- [ ] Export-Dateinamen folgen dem Muster `GEMA_Meldung_{Kapellenname}_{Datum}.{format}`
- [ ] PDF-Export enthält Kopfzeile, Tabelle und Fußzeile
- [ ] CSV-Export ist Excel-kompatibel (UTF-8 mit BOM)
- [ ] GEMA-XML hat korrekte Encoding-Deklaration (UTF-8 mit BOM)

### 10.3 Test-DoD

- [ ] Unit-Tests für alle Business-Logik (Meldungs-Erstellung, Export, Validierung)
- [ ] Integration-Tests für API-Endpoints (alle CRUD-Operationen)
- [ ] E2E-Tests für Haupt-User-Journey:
  1. Setlist erstellen
  2. GEMA-Meldung generieren
  3. Werknummer suchen (mit Mock-AI)
  4. Export als XML/CSV/PDF
  5. Erinnerung auslösen
- [ ] Test-Coverage ≥ 80% für Backend-Logik
- [ ] GEMA-XML wird mit GEMA-Validator getestet (falls öffentlich verfügbar)
- [ ] AI-Suche wird mit Test-Repertoire (100 bekannte Werke) getestet → ≥80% Trefferquote
- [ ] Load-Tests: 100 gleichzeitige Meldungs-Erstellungen
- [ ] Performance-Test: Bulk-Suche für 50 Werke < 2 Minuten

### 10.4 UX-DoD

- [ ] UX-Design in `docs/ux-specs/gema-compliance.md` dokumentiert (Wanda)
- [ ] Mobile-optimierte Ansichten (Phone, Tablet)
- [ ] Desktop-Ansichten (Web)
- [ ] Alle Fehlermeldungen sind nutzerfreundlich und actionable
- [ ] Konfidenz-Indikator (Ampelsystem: Grün ≥80%, Gelb 50-79%, Rot <50%) ist visuell klar
- [ ] Empty-States für leere Meldungs-Historie
- [ ] Loading-Spinner während AI-Suche und Export
- [ ] Success-Toast nach erfolgreichem Export
- [ ] Accessibility: Screen-Reader-Support, Tastaturnavigation

### 10.5 Dokumentations-DoD

- [ ] API-Dokumentation (Swagger/OpenAPI) ist generiert und aktuell
- [ ] README-Update: GEMA-Feature beschrieben
- [ ] Nutzer-Handbuch: "Wie erstelle ich eine GEMA-Meldung?" (inkl. Screenshots)
- [ ] Admin-Handbuch: "Verwertungsgesellschaft konfigurieren"
- [ ] Entwickler-Doku: AI-Adapter-Pattern, GEMA-XML-Schema-Referenz
- [ ] Datenbank-Migrations-Log aktualisiert

### 10.6 Deployment-DoD

- [ ] Feature-Flag `gema_compliance_enabled` ist konfigurierbar
- [ ] Azure OpenAI-Credentials sind in Key Vault gespeichert
- [ ] Monitoring: Application Insights-Tracking für AI-Anfragen (Erfolg/Fehler/Dauer)
- [ ] Alerting: Wenn AI-Provider für >5 Minuten nicht erreichbar → Alarm
- [ ] Backup: GEMA-Meldungen werden täglich gesichert (Retention: 7 Jahre)
- [ ] DSGVO-Compliance: Audit-Logs enthalten keine personenbezogenen Daten außer User-ID

---

## Anhang: GEMA-XML-Schema (Referenz)

Das offizielle GEMA-XML-Schema (Version 2.0) ist unter [www.gema.de](https://www.gema.de) verfügbar (Login erforderlich). Für MS2 verwenden wir eine vereinfachte Version basierend auf öffentlich verfügbaren Informationen.

**Minimales valides GEMA-XML:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GEMAMeldung xmlns="http://www.gema.de/schema/v2" version="2.0">
  <Veranstaltung>
    <Veranstalter>Blaskapelle Musterstadt e.V.</Veranstalter>
    <Datum>2026-03-20</Datum>
    <Ort>Stadthalle Musterstadt</Ort>
    <Art>Konzert</Art>
  </Veranstaltung>
  <Werkliste>
    <Werk>
      <Werktitel>An der schönen blauen Donau</Werktitel>
      <Urheber>Strauss, Johann (Sohn)</Urheber>
      <Verlag>Musikverlag XY GmbH</Verlag>
      <GEMAWerknummer>123456789</GEMAWerknummer>
      <Dauer>PT8M30S</Dauer>
    </Werk>
  </Werkliste>
</GEMAMeldung>
```

**Pflichtfelder:**
- `<Veranstalter>`, `<Datum>`, `<Ort>`, `<Art>` (Veranstaltung)
- `<Werktitel>`, `<Urheber>` (Werk)

**Optionale Felder:**
- `<GEMAWerknummer>`, `<Verlag>`, `<Bearbeiter>`, `<Dauer>` (Werk)

**Dauer-Format:** ISO 8601 Duration (z.B. `PT8M30S` für 8 Minuten 30 Sekunden)

---

**Ende der Feature-Spezifikation: GEMA & Compliance**
