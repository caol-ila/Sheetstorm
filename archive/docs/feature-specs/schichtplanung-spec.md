# Feature-Spezifikation: Schichtplanung (Basic)

> **Issue:** TBD  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2025-01-28  
> **Status:** Entwurf  
> **Abhängigkeiten:** Kapellenverwaltung, Konzertplanung (Termine)  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD durch Wanda

---

## 1. Feature-Überblick

Die Schichtplanung (Basic) ermöglicht es Kapellen, bei Vereinsfesten und anderen Events Schichten für organisatorische Aufgaben zu definieren und Mitglieder zuzuweisen. Musiker können sich selbst für offene Schichten eintragen oder von Admins/Dirigenten zugewiesen werden.

### 1.1 Ziel

Blaskapellen veranstalten neben Konzerten auch Vereinsfeste (Sommerfest, Weihnachtsmarkt-Stand, Frühschoppen), bei denen organisatorische Aufgaben wie Ausschank, Kasse, Aufbau und Abbau koordiniert werden müssen. Diese Feature ermöglicht es, Schichtpläne zu erstellen und besetzt zu bekommen — ohne die Komplexität einer professionellen Schichtplanungs-Software.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Schichtplan für Event erstellen | Wiederkehrende Schichten |
| Schichten definieren (Name, Zeit, Personen) | Schichttausch zwischen Musikern |
| Selbsteintragung durch Musiker | Präferenz-Verwaltung |
| Zuweisung durch Admin/Dirigent | Automatische Schichtzuteilung |
| Übersicht offener/besetzter Schichten | Arbeitszeit-Tracking |
| Push-Benachrichtigung bei Schichten | Schichtplan-Vorlagen |
| Schichtplan mit Termin verknüpfen (optional) | Verfügbarkeitsabfrage |
| Schichtzuweisung entfernen | Externe Export (PDF, iCal) |
| Übersicht eigene Schichten | Schicht-Kommentare / Chat |

### 1.3 Kontext & Differenzierung

**Use Case:** Vereinsfeste sind ein häufiger und zeitaufwendiger Bestandteil des Vereinslebens. Bestehende Lösungen sind entweder zu komplex (Schichtplanungs-Software für Firmen) oder fehlen ganz (Excel-Listen per E-Mail).

**Bewusst "Basic":** Einfachheit ist das Kernprinzip. Keine komplexe Schichtlogik, keine Arbeitszeitgesetze, kein Fahrtkostenmanagement — nur eine einfache Zuordnung von Personen zu Zeitslots mit klarer Übersicht.

**Optional verknüpft:** Schichtpläne können eigenständig existieren oder mit einem Termin aus der Konzertplanung verknüpft sein. So lassen sich z.B. zu einem "Sommerfest"-Termin direkt die Schichten organisieren.

---

## 2. User Stories

### US-01: Schichtplan erstellen

> *Als Admin oder Dirigent möchte ich einen Schichtplan für ein Vereinsfest anlegen, damit ich die organisatorischen Aufgaben koordinieren kann.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert nur eine bestehende Kapelle
- **N**egotiable: Verknüpfung mit Termin ist optional
- **V**aluable: Ohne Schichtplan keine strukturierte Aufgabenverteilung
- **E**stimatable: ~1 Sprint
- **S**mall: Nur Erstellen des Rahmens — Schichten werden separat hinzugefügt
- **T**estable: ✅ Schichtplan existiert in DB mit Name und Datum

**Akzeptanzkriterien:**
1. Admin/Dirigent kann unter "Termine" oder in separatem "Schichtplanung"-Bereich einen neuen Schichtplan erstellen
2. Pflichtfelder: **Name** (z.B. "Sommerfest 2026", max. 100 Zeichen), **Datum** (YYYY-MM-DD)
3. Optionale Felder: Beschreibung (max. 500 Zeichen), Verknüpfung zu einem Termin (Dropdown)
4. Wenn ein Termin verknüpft wird, wird Datum automatisch aus Termin übernommen (überschreibbar)
5. Nach Erstellen: Leerer Schichtplan mit 0 Schichten
6. Schichtplan erscheint in der Schichtplan-Übersicht der Kapelle
7. **Fehlerfall:** Wenn Name leer ist → Validierungsfehler
8. **Fehlerfall:** Wenn Datum fehlt → Validierungsfehler

---

### US-02: Schichten definieren

> *Als Admin oder Dirigent möchte ich konkrete Schichten zu einem Schichtplan hinzufügen, damit Musiker wissen, welche Aufgaben wann anfallen.*

**Kriterien (INVEST):**
- **I**ndependent: Baut auf bestehendem Schichtplan auf
- **N**egotiable: Zeitraum kann flexibel sein (nur Start oder Start+Ende)
- **V**aluable: Ohne definierte Schichten keine Zuweisungen möglich
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Definition — Zuweisung erfolgt separat
- **T**estable: ✅ Schicht mit Zeitraum und Kapazität existiert in DB

**Akzeptanzkriterien:**
1. Admin/Dirigent kann im Schichtplan auf "+ Schicht hinzufügen" tippen
2. Pflichtfelder: **Name** (z.B. "Ausschank Bar", max. 80 Zeichen), **Von** (Zeit HH:MM), **Bis** (Zeit HH:MM), **Benötigte Personen** (1–99)
3. Optionale Felder: Beschreibung/Hinweis (max. 200 Zeichen)
4. Zeitraum wird validiert: "Bis" muss nach "Von" liegen
5. Zeitraum bezieht sich auf das Datum des Schichtplans (nur Uhrzeiten eingeben)
6. Schichten können sich zeitlich überschneiden (z.B. zwei parallele Aufgaben)
7. Admin/Dirigent kann Schichten nachträglich bearbeiten und löschen
8. Schichten löschen: Nur möglich wenn keine Zuweisungen bestehen; andernfalls Warnhinweis mit Option "Zuweisungen entfernen und löschen"
9. Anzahl offener Plätze wird automatisch berechnet: `benötigte_personen - aktuelle_zuweisungen`
10. **Fehlerfall:** "Bis"-Zeit liegt vor "Von"-Zeit → Validierungsfehler "Endzeit muss nach Startzeit liegen"
11. **Fehlerfall:** Benötigte Personen = 0 → Validierungsfehler "Mindestens 1 Person erforderlich"

---

### US-03: Selbsteintragung in Schichten

> *Als Musiker möchte ich mich selbst für eine offene Schicht eintragen, damit ich bei Vereinsfesten mithelfe und meine Verfügbarkeit zeige.*

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert unabhängig von Admin-Zuweisungen
- **N**egotiable: First-come, first-served ohne Präferenz-System
- **V**aluable: Musiker können eigenverantwortlich beitragen
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Eintragung — keine Tausch- oder Präferenz-Logik
- **T**estable: ✅ Musiker erscheint in Schichtzuweisung nach Self-Signup

**Akzeptanzkriterien:**
1. Musiker sieht alle Schichtpläne seiner Kapelle in einer Übersicht
2. Offene Schichten (noch freie Plätze) werden visuell hervorgehoben (z.B. grüner Badge "X Plätze frei")
3. Musiker kann auf eine Schicht tippen und "+ Ich bin dabei" wählen
4. Self-Signup ist nur möglich, wenn noch Kapazität verfügbar ist
5. Nach Eintragung erscheint der Musiker sofort in der Schicht-Detailansicht
6. Musiker kann sich selbst wieder austragen (nur eigene Self-Signups, nicht Admin-Zuweisungen)
7. Wenn ein Musiker sich austrägt, wird ein Platz wieder frei
8. Ein Musiker kann sich nur einmal pro Schicht eintragen
9. Ein Musiker kann sich für mehrere Schichten im selben Schichtplan eintragen
10. **Fehlerfall:** Kapazität erreicht → Button "Ich bin dabei" wird zu "Voll" (disabled) + Info "Keine Plätze mehr frei"
11. **Fehlerfall:** Musiker versucht doppelte Eintragung → Fehlermeldung "Du bist bereits für diese Schicht eingetragen"

---

### US-04: Zuweisung durch Admin/Dirigent

> *Als Admin oder Dirigent möchte ich Musiker gezielt Schichten zuweisen, damit kritische Positionen besetzt sind — auch wenn sich niemand selbst einträgt.*

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert parallel zur Selbsteintragung
- **N**egotiable: Keine automatische Konfliktprüfung bei Mehrfachzuweisungen
- **V**aluable: Garantiert Besetzung wichtiger Schichten
- **E**stimatable: ~0.5 Sprints
- **S**small: Nur Zuweisung — keine Präferenz- oder Optimierungs-Logik
- **T**estable: ✅ Zugewiesener Musiker erscheint mit "zugewiesen"-Badge in der Schicht

**Akzeptanzkriterien:**
1. Admin/Dirigent sieht in Schicht-Detailansicht eine Liste aller Kapellenmitglieder
2. Admin/Dirigent kann über "+ Person zuweisen" Mitglieder auswählen und hinzufügen
3. Zuweisung ignoriert Kapazitätslimit **nicht** — auch Admin muss freie Plätze beachten
4. Zugewiesene Musiker können sich selbst **nicht** austragen — nur Admin/Dirigent kann Zuweisung entfernen
5. Zugewiesene Musiker werden visuell von Self-Signups unterschieden (z.B. "zugewiesen" vs. "selbst")
6. Admin/Dirigent kann jede Zuweisung (eigen und fremde Self-Signups) entfernen
7. Mehrfachzuweisung zu überschneidenden Schichten ist technisch möglich, aber Admin erhält Warnung "Musiker X ist bereits zur gleichen Zeit in Schicht Y eingeteilt"
8. Zugewiesene Musiker erhalten Push-Benachrichtigung über die Zuweisung
9. **Fehlerfall:** Kapazität erreicht → Admin kann trotzdem Warnung überschreiben (z.B. "Notfall-Zuweisung") — wird vermerkt
10. **Fehlerfall:** Musiker ist bereits zugewiesen → Fehlermeldung "Musiker X ist bereits in dieser Schicht"

---

### US-05: Übersicht Schichtplan

> *Als Admin, Dirigent oder Musiker möchte ich sehen, welche Schichten offen sind und wer wo eingeteilt ist, damit ich den Überblick behalte.*

**Kriterien (INVEST):**
- **I**ndependent: Nur lesend — keine Abhängigkeit zu Änderungsoperationen
- **N**egotiable: Filter-Optionen (z.B. "nur offene") sind optional
- **V**aluable: Zentrale Anlaufstelle für alle Beteiligten
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Darstellung — keine Änderungslogik
- **T**estable: ✅ Übersicht zeigt korrekte Anzahl freier/besetzter Plätze

**Akzeptanzkriterien:**
1. Jedes Kapellenmitglied kann die Schichtplan-Übersicht sehen
2. Übersicht zeigt alle Schichtpläne der Kapelle (sortiert nach Datum, neueste zuerst)
3. Jeder Schichtplan zeigt: Name, Datum, Anzahl Schichten, Anzahl offener Plätze gesamt
4. Beim Tap auf einen Schichtplan öffnet sich die Detailansicht mit allen Schichten
5. Schicht-Detailansicht zeigt: Name, Zeitraum, X/Y Plätze besetzt, Liste der zugewiesenen Musiker (Name + Badge "selbst" oder "zugewiesen")
6. Offene Plätze sind visuell hervorgehoben (z.B. "3 Plätze frei" in grün)
7. Vollständig besetzte Schichten zeigen "Voll" (z.B. grauer Badge)
8. Musiker können Filter "Nur meine Schichten" aktivieren → zeigt nur Schichten, denen sie zugewiesen sind
9. Musiker sehen eigene Schichten auch auf der Startseite / Dashboard ("Deine nächsten Schichten")
10. Admin/Dirigent sieht zusätzlich: Gesamtstatistik (z.B. "12 von 25 Schichten besetzt")

---

### US-06: Push-Benachrichtigungen

> *Als Musiker möchte ich benachrichtigt werden, wenn neue Schichten verfügbar sind oder ich zugewiesen wurde, damit ich nichts verpasse.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt vorhandene Push-Infrastruktur
- **N**egotiable: In-App-Benachrichtigungen sind Minimum; Push optional
- **V**aluable: Erhöht Teilnahme und rechtzeitige Rückmeldung
- **E**stimatable: ~0.3 Sprints (wenn Push-System besteht)
- **S**mall: Nur Trigger-Definition — Push-Infrastruktur ist vorhanden
- **T**estable: ✅ Musiker erhält Benachrichtigung nach Zuweisung

**Akzeptanzkriterien:**
1. Musiker erhält Push-Benachrichtigung, wenn:
   - Ein neuer Schichtplan für die Kapelle erstellt wird
   - Neue Schichten zu einem Schichtplan hinzugefügt werden (wenn Plätze offen)
   - Admin/Dirigent den Musiker einer Schicht zuweist
2. Benachrichtigung enthält: Schichtplan-Name, Schicht-Name, Zeitraum
3. Tap auf Benachrichtigung öffnet die Schicht-Detailansicht
4. Musiker kann Benachrichtigungen pro Kapelle in den Settings deaktivieren ("Schichtplanungs-Benachrichtigungen")
5. Keine Benachrichtigung bei Self-Signup (Musiker hat selbst gehandelt)
6. Keine doppelte Benachrichtigung, wenn mehrere Schichten gleichzeitig hinzugefügt werden → eine gebündelte Nachricht "3 neue Schichten verfügbar"

---

## 3. Akzeptanzkriterien (Feature-Level)

Diese Kriterien gelten übergreifend für das gesamte Schichtplanungs-Feature:

| ID | Kriterium | Testbar durch |
|----|-----------|---------------|
| AC-01 | Schicht-Zuweisung erfolgt in < 2 Sekunden (Tap bis Bestätigung) | E2E-Test: Stopwatch |
| AC-02 | Self-Signup respektiert Kapazitätslimit (kein Überbuchung) | Integration-Test: Concurrent-Request-Test |
| AC-03 | Admin-Zuweisung überschreibt nicht versehentlich Self-Signups | Integration-Test |
| AC-04 | Push-Benachrichtigungen erreichen Musiker innerhalb von 60 Sekunden | E2E-Test: Push-Delivery |
| AC-05 | Schichtplan-Übersicht lädt in < 1 Sekunde (bis 100 Schichten) | Performance-Test |
| AC-06 | Zeitkonflikte werden erkannt und gewarnt (nicht blockiert) | Business-Logic-Test |
| AC-07 | Gelöschte Schichtpläne entfernen alle Zuweisungen (Cascade) | DB-Constraint-Test |
| AC-08 | Audit-Log erfasst alle Zuweisungen/Austragungen mit Zeitstempel | DB-Test |
| AC-09 | Musiker sehen nur Schichtpläne ihrer eigenen Kapelle (Kontext-Isolation) | Integration-Test: Multi-Kapellen-Leak |
| AC-10 | Schichtplan kann optional mit Termin verknüpft werden | Integration-Test |

---

## 4. API-Contract

**Base Path:** `/api/v1/kapellen/{kapelle_id}/schichtplaene`  
**Auth:** Bearer JWT (alle Endpunkte erfordern Authentifizierung)

### 4.1 Schichtplan-CRUD

```
POST   /api/v1/kapellen/{kapelle_id}/schichtplaene                    → Schichtplan erstellen (Admin, Dirigent)
GET    /api/v1/kapellen/{kapelle_id}/schichtplaene                    → Alle Schichtpläne der Kapelle (alle Rollen)
GET    /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}   → Schichtplan-Details (alle Rollen)
PUT    /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}   → Schichtplan aktualisieren (Admin, Dirigent)
DELETE /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}   → Schichtplan löschen (Admin, Dirigent)
```

**POST /api/v1/kapellen/{kapelle_id}/schichtplaene — Request:**
```json
{
  "name": "Sommerfest 2026",
  "datum": "2026-07-15",
  "beschreibung": "Schichtplan für unser großes Sommerfest am Sportplatz.",
  "termin_id": "uuid-des-termins"  // optional
}
```

**POST /api/v1/kapellen/{kapelle_id}/schichtplaene — Response 201:**
```json
{
  "id": "uuid",
  "kapelle_id": "uuid",
  "termin_id": "uuid-des-termins",
  "name": "Sommerfest 2026",
  "datum": "2026-07-15",
  "beschreibung": "Schichtplan für unser großes Sommerfest am Sportplatz.",
  "anzahl_schichten": 0,
  "anzahl_zuweisungen": 0,
  "offene_plaetze": 0,
  "erstellt_am": "2026-03-28T10:00:00Z",
  "erstellt_von": "uuid"
}
```

**GET /api/v1/kapellen/{kapelle_id}/schichtplaene — Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Sommerfest 2026",
      "datum": "2026-07-15",
      "anzahl_schichten": 8,
      "anzahl_zuweisungen": 15,
      "offene_plaetze": 5,
      "erstellt_am": "2026-03-28T10:00:00Z"
    }
  ],
  "gesamt": 3,
  "cursor": "eyJ..."
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (Name leer, Datum ungültig)
- `403` — Nicht berechtigt (z.B. Musiker versucht Schichtplan zu erstellen)
- `404` — Schichtplan oder Kapelle nicht gefunden
- `409` — Konflikt (z.B. ungültiger Termin)

---

### 4.2 Schichten-CRUD

```
POST   /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten              → Schicht hinzufügen (Admin, Dirigent)
GET    /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten              → Alle Schichten eines Plans (alle Rollen)
GET    /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten/{schicht_id} → Schicht-Details (alle Rollen)
PUT    /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten/{schicht_id} → Schicht aktualisieren (Admin, Dirigent)
DELETE /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten/{schicht_id} → Schicht löschen (Admin, Dirigent)
```

**POST schichten — Request:**
```json
{
  "name": "Ausschank Bar",
  "von": "14:00",
  "bis": "18:00",
  "benoetigte_personen": 3,
  "beschreibung": "Getränke ausschenken und abkassieren"
}
```

**POST schichten — Response 201:**
```json
{
  "id": "uuid",
  "schichtplan_id": "uuid",
  "name": "Ausschank Bar",
  "von": "14:00",
  "bis": "18:00",
  "benoetigte_personen": 3,
  "beschreibung": "Getränke ausschenken und abkassieren",
  "anzahl_zuweisungen": 0,
  "offene_plaetze": 3,
  "erstellt_am": "2026-03-28T10:05:00Z"
}
```

**GET schichten/{schicht_id} — Response 200:**
```json
{
  "id": "uuid",
  "schichtplan_id": "uuid",
  "name": "Ausschank Bar",
  "von": "14:00",
  "bis": "18:00",
  "benoetigte_personen": 3,
  "beschreibung": "Getränke ausschenken und abkassieren",
  "anzahl_zuweisungen": 2,
  "offene_plaetze": 1,
  "zuweisungen": [
    {
      "id": "uuid",
      "musiker_id": "uuid",
      "musiker_name": "Anna Musterfrau",
      "typ": "selbst",
      "zugewiesen_am": "2026-03-28T11:00:00Z",
      "zugewiesen_von": null
    },
    {
      "id": "uuid",
      "musiker_id": "uuid",
      "musiker_name": "Max Mustermann",
      "typ": "zugewiesen",
      "zugewiesen_am": "2026-03-28T11:30:00Z",
      "zugewiesen_von": "uuid-admin"
    }
  ],
  "erstellt_am": "2026-03-28T10:05:00Z"
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (Zeit ungültig, Personen = 0)
- `403` — Nicht berechtigt
- `404` — Schicht oder Schichtplan nicht gefunden
- `409` — Konflikt (z.B. Schicht löschen mit bestehenden Zuweisungen ohne Force-Flag)

---

### 4.3 Zuweisungen-API

```
POST   /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten/{schicht_id}/zuweisungen              → Zuweisung hinzufügen
DELETE /api/v1/kapellen/{kapelle_id}/schichtplaene/{schichtplan_id}/schichten/{schicht_id}/zuweisungen/{zuweisung_id} → Zuweisung entfernen
GET    /api/v1/kapellen/{kapelle_id}/schichtplaene/meine-schichten                                                  → Eigene Schichten (alle Rollen)
```

**POST zuweisungen — Request (Self-Signup):**
```json
{
  "typ": "selbst"
}
```

**POST zuweisungen — Request (Admin-Zuweisung):**
```json
{
  "typ": "zugewiesen",
  "musiker_id": "uuid-des-musikers"
}
```

**POST zuweisungen — Response 201:**
```json
{
  "id": "uuid",
  "schicht_id": "uuid",
  "musiker_id": "uuid",
  "musiker_name": "Anna Musterfrau",
  "typ": "selbst",
  "zugewiesen_am": "2026-03-28T11:00:00Z",
  "zugewiesen_von": null
}
```

**DELETE zuweisungen/{zuweisung_id} — Response 204 (No Content)**

**GET meine-schichten — Response 200:**
```json
{
  "items": [
    {
      "schichtplan_id": "uuid",
      "schichtplan_name": "Sommerfest 2026",
      "schichtplan_datum": "2026-07-15",
      "schicht_id": "uuid",
      "schicht_name": "Ausschank Bar",
      "schicht_von": "14:00",
      "schicht_bis": "18:00",
      "typ": "selbst",
      "zugewiesen_am": "2026-03-28T11:00:00Z"
    }
  ],
  "gesamt": 3,
  "cursor": "eyJ..."
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (z.B. Typ fehlt)
- `403` — Nicht berechtigt (z.B. Musiker versucht Admin-Zuweisung; Musiker versucht fremde Self-Signup zu löschen)
- `404` — Schicht oder Zuweisung nicht gefunden
- `409` — Kapazität erreicht (Self-Signup); Musiker bereits zugewiesen
- `422` — Zeitkonflikt-Warnung (nur bei Admin-Zuweisung, nicht blockierend, nur Info im Response)

---

## 5. Datenmodell

### 5.1 Schichtplan

```sql
CREATE TABLE schichtplaene (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    termin_id       UUID         REFERENCES termine(id) ON DELETE SET NULL,  -- optional
    name            VARCHAR(100) NOT NULL,
    datum           DATE         NOT NULL,
    beschreibung    VARCHAR(500),
    erstellt_am     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    erstellt_von    UUID         NOT NULL REFERENCES musiker(id)
);

CREATE INDEX idx_schichtplaene_kapelle ON schichtplaene(kapelle_id, datum DESC);
CREATE INDEX idx_schichtplaene_termin  ON schichtplaene(termin_id) WHERE termin_id IS NOT NULL;
```

### 5.2 Schicht

```sql
CREATE TABLE schichten (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schichtplan_id       UUID         NOT NULL REFERENCES schichtplaene(id) ON DELETE CASCADE,
    name                 VARCHAR(80)  NOT NULL,
    von                  TIME         NOT NULL,
    bis                  TIME         NOT NULL,
    benoetigte_personen  INTEGER      NOT NULL CHECK (benoetigte_personen > 0),
    beschreibung         VARCHAR(200),
    erstellt_am          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT check_zeit_von_bis CHECK (bis > von)
);

CREATE INDEX idx_schichten_plan ON schichten(schichtplan_id, von);
```

### 5.3 Schichtzuweisung

```sql
CREATE TYPE schicht_zuweisung_typ AS ENUM ('selbst', 'zugewiesen');

CREATE TABLE schicht_zuweisungen (
    id              UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
    schicht_id      UUID                      NOT NULL REFERENCES schichten(id) ON DELETE CASCADE,
    musiker_id      UUID                      NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    typ             schicht_zuweisung_typ     NOT NULL,
    zugewiesen_am   TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    zugewiesen_von  UUID                      REFERENCES musiker(id),  -- NULL bei Self-Signup
    UNIQUE (schicht_id, musiker_id)
);

CREATE INDEX idx_zuweisungen_schicht  ON schicht_zuweisungen(schicht_id);
CREATE INDEX idx_zuweisungen_musiker  ON schicht_zuweisungen(musiker_id, zugewiesen_am DESC);
```

### 5.4 Audit-Log (erweitert um Schichtplanung)

```sql
-- Verwendung der bestehenden audit_log-Tabelle aus Kapellenverwaltung
-- Neue Aktionen:
-- - 'schichtplan.erstellt', 'schichtplan.geaendert', 'schichtplan.geloescht'
-- - 'schicht.erstellt', 'schicht.geaendert', 'schicht.geloescht'
-- - 'zuweisung.hinzugefuegt', 'zuweisung.entfernt'
```

---

## 6. Berechtigungsmatrix

> **Prinzip:** RBAC pro Kapelle. Admin und Dirigent haben volle Kontrolle über Schichtplanung. Alle anderen Rollen können lesen und sich selbst eintragen.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|
| **Schichtplan** | | | | | |
| Schichtplan erstellen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schichtplan bearbeiten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schichtplan löschen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schichtplan-Übersicht sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Schichten** | | | | | |
| Schicht hinzufügen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schicht bearbeiten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schicht löschen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Schichten sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Zuweisungen** | | | | | |
| Self-Signup (sich selbst eintragen) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Eigene Self-Signup austragen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Andere Musiker zuweisen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Zuweisungen entfernen (alle) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigene Schichten sehen | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 7. Edge Cases

| Szenario | Verhalten | Begründung |
|----------|-----------|------------|
| **Musiker wird aus Kapelle entfernt** | Alle Schichtzuweisungen werden automatisch entfernt (CASCADE) | Verhindert "Geister-Zuweisungen" |
| **Schichtplan wird gelöscht** | Alle Schichten und Zuweisungen werden gelöscht (CASCADE) | Soft-Delete ist nicht erforderlich — Schichtplanung ist temporär |
| **Schicht-Kapazität wird reduziert** | Wenn bereits mehr Zuweisungen bestehen als neue Kapazität → Warnhinweis "X Personen sind bereits eingeteilt. Kapazität kann nicht unter die aktuelle Anzahl gesenkt werden." | Verhindert ungültige Zustände |
| **Termin wird gelöscht** | Verknüpfter Schichtplan bleibt bestehen, termin_id wird auf NULL gesetzt (SET NULL) | Schichtplanung kann eigenständig existieren |
| **Musiker hat überlappende Schichten** | Warnung bei Admin-Zuweisung, aber nicht blockierend | Flexibilität — manche Aufgaben können parallel erledigt werden |
| **Schicht liegt in der Vergangenheit** | Lesezugriff normal; Self-Signup/Admin-Zuweisung blockiert mit Hinweis "Diese Schicht liegt in der Vergangenheit" | Verhindert nachträgliche Änderungen |
| **Musiker versucht sich zweimal einzutragen (Race Condition)** | DB-Unique-Constraint verhindert doppelte Eintragung; zweiter Request → 409 Conflict | Technische Absicherung |
| **Admin weist Musiker zu, obwohl Kapazität erreicht** | Request wird mit 409 abgelehnt — auch Admin muss Kapazität respektieren | Konsistenz; bei Bedarf Kapazität erhöhen |
| **Schicht ohne Beschreibung** | Erlaubt — Beschreibung ist optional | Nicht jede Schicht braucht lange Erklärung |
| **Schichtplan ohne Termin-Verknüpfung** | Vollständig gültig — Schichtplanung funktioniert standalone | Use Case: Vereinsfeste die keine "Konzert-Termine" sind |

---

## 8. Abhängigkeiten

### 8.1 Technische Abhängigkeiten

| Feature | Abhängigkeit | Status | Bemerkung |
|---------|-------------|--------|-----------|
| Kapellenverwaltung | Muss existieren | ✅ MS1 | Schichtpläne gehören zu Kapellen |
| Authentifizierung | JWT-Auth | ✅ MS1 | Bearer Token für alle Requests |
| Push-Benachrichtigungen | Push-Service | ⚠️ TBD | Optional — kann mit In-App-Notifications starten |
| Termine (Konzertplanung) | Optional verknüpfbar | 🔲 MS2 | Verknüpfung ist optional; Schichtplanung funktioniert standalone |

### 8.2 UX-Abhängigkeiten

- **Wanda (UX Designer):** Screens für Schichtplan-Erstellung, Schicht-Übersicht, Self-Signup-Flow, Admin-Zuweisung
- **UX-Spec:** Sollte vor Implementierung vorliegen, um Konsistenz mit restlicher App zu gewährleisten

### 8.3 API-Abhängigkeiten

- **Pagination:** Nutzt Cursor-Pagination (wie Kapellenverwaltung)
- **Error Handling:** Nutzt bestehende Fehlercode-Struktur (400, 403, 404, 409, 422)

---

## 9. Definition of Done

### 9.1 Backend

- [ ] Datenmodell implementiert (PostgreSQL)
- [ ] Migrations für Tabellen `schichtplaene`, `schichten`, `schicht_zuweisungen`
- [ ] REST-API vollständig (alle Endpunkte aus §4)
- [ ] RBAC-Logik implementiert und getestet
- [ ] Kapazitätslimit wird bei Self-Signup und Admin-Zuweisung geprüft
- [ ] DB-Constraints verhindern Doppelzuweisungen (UNIQUE-Constraint)
- [ ] Cascade-Delete funktioniert (Kapelle → Schichtplan → Schichten → Zuweisungen)
- [ ] Audit-Log schreibt alle Zuweisungen/Austragungen
- [ ] API-Tests (Integration): 80%+ Coverage
- [ ] Performance-Test: GET /schichtplaene < 1 Sekunde (bis 100 Schichten)

### 9.2 Frontend

- [ ] Schichtplan-Übersicht (Liste aller Pläne)
- [ ] Schichtplan-Detailansicht (alle Schichten)
- [ ] Schicht-Detailansicht (Zuweisungen, offene Plätze)
- [ ] Admin-Flow: Schichtplan + Schichten erstellen
- [ ] Admin-Flow: Musiker zuweisen / Zuweisungen entfernen
- [ ] Musiker-Flow: Self-Signup / Austragen
- [ ] Übersicht "Meine Schichten" (Dashboard-Widget + eigene Seite)
- [ ] Kapazitätslimit wird visuell dargestellt (z.B. "3/5 Plätze besetzt")
- [ ] Warnhinweise bei Zeitkonflikten (Admin-Zuweisung)
- [ ] Fehlerbehandlung für 409 (Kapazität erreicht, doppelte Zuweisung)
- [ ] Responsive Design (Mobile first)

### 9.3 Push-Benachrichtigungen

- [ ] Trigger: Neuer Schichtplan erstellt → alle Kapellenmitglieder
- [ ] Trigger: Neue Schichten hinzugefügt → alle Kapellenmitglieder (gebündelt)
- [ ] Trigger: Admin-Zuweisung → betroffener Musiker
- [ ] Deep-Link: Benachrichtigung öffnet Schicht-Detailansicht
- [ ] Settings: Schichtplanungs-Benachrichtigungen können pro Kapelle deaktiviert werden

### 9.4 Testing

- [ ] Unit-Tests: Business-Logic (Kapazitätsprüfung, RBAC, Zeitvalidierung)
- [ ] Integration-Tests: API-Endpunkte (inkl. Race-Conditions bei Self-Signup)
- [ ] E2E-Tests: Admin erstellt Schichtplan → Musiker trägt sich ein → Admin weist zu
- [ ] E2E-Tests: Self-Signup respektiert Kapazitätslimit
- [ ] E2E-Tests: Push-Benachrichtigung bei Zuweisung
- [ ] Performance-Tests: Concurrent Self-Signups (10+ gleichzeitig)

### 9.5 Dokumentation

- [ ] API-Dokumentation aktualisiert (Swagger/OpenAPI)
- [ ] Benutzer-Doku: "Wie erstelle ich einen Schichtplan?"
- [ ] Benutzer-Doku: "Wie trage ich mich für Schichten ein?"
- [ ] Release-Notes: Feature-Announcement für MS2

### 9.6 Review & Sign-Off

- [ ] Code-Review durch Banner (Backend) + Romanoff (Frontend)
- [ ] UX-Review durch Wanda (Flows stimmen mit Design überein)
- [ ] Product-Review durch Hill (Feature-Spec erfüllt)
- [ ] QA-Sign-Off (keine kritischen Bugs)

---

## 10. Nicht-funktionale Anforderungen

### 10.1 Performance

- GET /schichtplaene: < 1 Sekunde (bis 100 Schichtpläne)
- GET /schichten/{id}: < 500ms (inkl. Zuweisungen)
- POST /zuweisungen (Self-Signup): < 2 Sekunden

### 10.2 Skalierung

- Pro Kapelle: Bis zu 1000 Schichtpläne
- Pro Schichtplan: Bis zu 100 Schichten
- Pro Schicht: Bis zu 50 Zuweisungen

### 10.3 Sicherheit

- Alle Endpunkte: JWT-Auth erforderlich
- RBAC: Admin/Dirigent für Management-Operationen
- Kapellen-Kontext-Isolation: Schichtpläne nur für Mitglieder der Kapelle sichtbar
- Audit-Log: Alle Zuweisungen/Austragungen mit Zeitstempel und Akteur

### 10.4 DSGVO

- Beim Verlassen einer Kapelle: Alle Schichtzuweisungen werden entfernt
- Beim Account-Löschung: Alle Schichtzuweisungen werden anonymisiert (musiker_id → NULL + Name → "Gelöschter Nutzer") — nur für historische Schichtpläne

---

## 11. Out of Scope (MS3+)

Diese Features sind bewusst **nicht** in MS2, aber potenzielle Erweiterungen für MS3:

- **Schichttausch:** Musiker können Schichten untereinander tauschen
- **Präferenz-System:** Musiker geben Präferenzen an → Admin bekommt Vorschläge
- **Automatische Schichtzuteilung:** Algorithmus verteilt Musiker fair auf Schichten
- **Wiederkehrende Schichten:** Vorlagen für jährlich wiederkehrende Events
- **Verfügbarkeitsabfrage:** Admin fragt vor Schichtplanung Verfügbarkeit ab
- **PDF-Export:** Schichtplan als PDF für Aushang
- **iCal-Export:** Schichten im persönlichen Kalender
- **Schicht-Kommentare:** Musiker können Fragen/Hinweise zu Schichten posten
- **Arbeitszeit-Tracking:** Erfassung geleisteter Stunden für Vereinsstatistik
- **Schichtplan-Vorlagen:** Vordefinierte Schichtpläne für typische Events

---

**Ende der Feature-Spezifikation Schichtplanung (Basic)**
