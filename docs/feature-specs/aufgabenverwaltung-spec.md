# Feature-Spezifikation: Aufgabenverwaltung / To-Do-Listen

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Kapellenverwaltung, Auth), MS2 (Konzertplanung, Kalender)  
> **UX-Referenz:** `docs/ux-specs/aufgabenverwaltung.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Berechtigungsmatrix](#6-berechtigungsmatrix)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Die Aufgabenverwaltung ermöglicht es Dirigenten, Admins und Registerführern, kapelleninterne Aufgaben zu erstellen, Mitgliedern zuzuweisen und den Erledigungsstatus zu verfolgen. Mit Fälligkeitsdaten, optionalen Erinnerungen und der Möglichkeit zur Verknüpfung mit Proben-Terminen wird die Probe-Verwaltung aus WhatsApp-Gruppen in Sheetstorm gebracht.

**Kernwert:** „Was bis zur nächsten Probe erledigt sein muss, ist für alle sichtbar — und wird nicht vergessen." Kein Durchwühlen von WhatsApp-Chats, keine handgeschriebenen To-Do-Zettel.

### 1.2 Das Kernproblem

**Status Quo:**
- Aufgaben werden in WhatsApp-Gruppen oder Vereins-Mails verteilt
- Kein Überblick wer was erledigt hat
- Fälligkeitserinnerungen gehen in der Chat-Flut unter
- Keine Verknüpfung mit Proben-Terminen

**Sheetstorm-Lösung:**
- Strukturierte Aufgaben mit Zuweisung und Status
- Erinnerungen direkt in der App (Push-Notification optional)
- Verknüpfung mit Konzertplanung-Terminen (MS2)
- Übersicht für Dirigent: Was ist erledigt, was steht aus

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Aufgaben erstellen (Titel, Beschreibung, Fälligkeitsdatum) | Aufgaben-Templates / Vorlagen |
| Aufgaben einem oder mehreren Mitgliedern zuweisen | Wiederkehrende Aufgaben (Recurring Tasks) |
| Status-Tracking: Offen → In Bearbeitung → Erledigt | Gantt-Chart / Projektmanagement-Ansichten |
| Erinnerungen (In-App + Push) bei Fälligkeit | E-Mail-Erinnerungen |
| Verknüpfung mit Kalender-Terminen (MS2) | Unteraufgaben / Checklisten |
| Kommentare / Notizen zur Aufgabe | Dateianhänge |
| Aufgaben filtern und durchsuchen | Externe Kalender-Sync (Google/Apple) |
| Überblick: Meine Aufgaben / Kapellen-Aufgaben | Aufgaben zwischen Kapellen teilen |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | Nach der Probe | Aufgaben an Musiker und Registerführer verteilen |
| Admin | Vor dem Konzert | Organisationsaufgaben tracken (Notenständer, Kostüme) |
| Registerführer | Zwischen den Proben | Aufgaben an sein Register zuweisen |
| Musiker | App öffnen | „Was muss ich bis wann erledigen?" |
| Dirigent | Übersichtsansicht | „Was ist noch offen, was ist erledigt?" |

---

## 2. User Stories

### US-01: Aufgabe erstellen

> *Als Dirigent möchte ich eine Aufgabe mit Titel, Beschreibung und Fälligkeitsdatum erstellen, damit ich klare Erwartungen an Kapellenmitglieder kommunizieren kann.*

**Akzeptanzkriterien:**
1. Aufgaben-Tab oder „+ Neue Aufgabe" öffnet Erstellungs-Formular
2. Pflichtfeld: **Titel** (1–200 Zeichen)
3. Optional: **Beschreibung** (max. 2000 Zeichen, Markdown-Support)
4. Optional: **Fälligkeitsdatum** (Datum + Uhrzeit, ISO 8601)
5. Optional: **Priorität** (Niedrig / Mittel / Hoch), Default: Mittel
6. Optional: **Verknüpfter Termin** (aus Kalender/Konzertplanung MS2)
7. Status initial: **Offen**
8. Ersteller wird als Autor protokolliert
9. **Fehlerfall:** Titel leer → Speichern blockiert, Validierungshinweis

---

### US-02: Aufgabe zuweisen

> *Als Dirigent möchte ich eine Aufgabe einem oder mehreren Mitgliedern meiner Kapelle zuweisen, damit klar ist wer die Verantwortung hat.*

**Akzeptanzkriterien:**
1. Beim Erstellen oder Bearbeiten: Mitglieder-Suche (Name, Instrument)
2. Mehrfachzuweisung möglich (0–N Mitglieder)
3. Zuweisung an „Alle" möglich (Kapellen-Aufgabe — jeder ist verantwortlich)
4. Zugewiesene Mitglieder erhalten In-App-Benachrichtigung
5. Zugewiesene Mitglieder können Aufgabe in „Meine Aufgaben" sehen
6. Zuweisung ändern: Admin und Dirigent können jederzeit umzuweisen
7. Mitglied kann sich selbst von Zuweisung entfernen (mit Kommentar-Pflicht)

---

### US-03: Status-Tracking

> *Als Musiker möchte ich den Status meiner Aufgaben aktualisieren (Offen / In Bearbeitung / Erledigt), damit Dirigent und Team sehen, dass ich dran bin.*

**Akzeptanzkriterien:**
1. Status-Workflow: **Offen** → **In Bearbeitung** → **Erledigt**
2. Rückwärts-Übergänge erlaubt (Erledigt → Offen, z.B. wenn Aufgabe erneut aufkommt)
3. Nur zugewiesene Mitglieder UND Ersteller können Status ändern
4. Status-Änderung wird in der Aufgaben-History protokolliert (Wer, Wann, Von → Nach)
5. Bei Erledigung: optionales Kommentar-Feld
6. Dirigent erhält Benachrichtigung wenn alle Zugewiesenen „Erledigt" gesetzt haben
7. Aufgaben-Liste zeigt farbkodierten Status (Rot = Offen, Gelb = In Bearbeitung, Grün = Erledigt)

---

### US-04: Erinnerungen erhalten

> *Als Musiker möchte ich vor Fälligkeitsdaten eine Erinnerung erhalten, damit ich Aufgaben nicht vergesse.*

**Akzeptanzkriterien:**
1. Standard-Erinnerungen: **24 Stunden** und **1 Stunde** vor Fälligkeit (konfigurierbar)
2. In-App: Benachrichtigungs-Center innerhalb der App
3. Push-Notification: opt-in (Nutzer muss explizit zustimmen, plattformkonform)
4. Erinnerungen nur für zugewiesene Mitglieder, nicht kapellenweit
5. Erinnerungs-Einstellungen pro Aufgabe überschreibbar (z.B. nur 1-Stunden-Erinnerung)
6. Wenn Aufgabe bereits erledigt: keine Erinnerung (System prüft Status vor Versand)
7. Nutzer kann Erinnerungen global deaktivieren (Geräte-Einstellungen)

---

### US-05: Aufgaben-Übersicht und Suche

> *Als Dirigent möchte ich eine Übersicht aller offenen und erledigten Aufgaben meiner Kapelle sehen, damit ich den Fortschritt im Blick habe.*

**Akzeptanzkriterien:**
1. **Meine Aufgaben**: Alle mir zugewiesenen offenen Aufgaben, sortiert nach Fälligkeit
2. **Kapellen-Aufgaben**: Alle Aufgaben der Kapelle (Admin/Dirigent/Registerführer: alle sehen; Musiker: nur zugewiesene)
3. Filter: Status, Priorität, Fälligkeit, Ersteller, Zugewiesener
4. Suche: Freitext in Titel und Beschreibung
5. Sortierung: Fälligkeit, Erstellt, Priorität, Status
6. Pagination: Cursor-basiert (keine Offset-Pagination)
7. Erledigte Aufgaben nach 30 Tagen automatisch in „Archiv" verschoben (nicht gelöscht)

---

### US-06: Aufgabe mit Termin verknüpfen

> *Als Dirigent möchte ich eine Aufgabe mit einem Probe- oder Konzerttermin verknüpfen, damit klar ist bis zu welchem Termin sie erledigt sein muss.*

**Akzeptanzkriterien:**
1. Beim Erstellen/Bearbeiten: optionale Verknüpfung mit einem Termin (aus MS2 Konzertplanung/Kalender)
2. Verknüpfter Termin erscheint in der Aufgaben-Ansicht als klickbarer Link
3. Termin-Datum wird als Vorschlag für das Fälligkeitsdatum übernommen (überschreibbar)
4. Im Termin-Detail (Konzertplanung MS2): Liste der verknüpften offenen Aufgaben sichtbar
5. Wenn Termin gelöscht: Aufgabe bleibt, Verknüpfung wird aufgelöst (kein Cascade-Delete)

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | Aufgabe erstellt und zugewiesen in ≤ 5 Sekunden (UX-Ziel) | UX-Zeitmessung |
| AC-02 | Erinnerung wird innerhalb 5 Minuten vor dem geplanten Zeitpunkt ausgelöst | Integration-Test |
| AC-03 | Status-Änderung erscheint bei anderen Nutzern in ≤ 5 Sekunden | E2E-Test (WebSocket oder Polling) |
| AC-04 | Aufgaben-History vollständig (kein Verlust bei Race Conditions) | Datenbank-Integritäts-Test |
| AC-05 | Push-Notification nicht gesendet wenn Aufgabe bereits erledigt | Test: Status = Erledigt → Erinnerungs-Job prüft |
| AC-06 | Filter + Suche in ≤ 500ms bei 1000 Aufgaben | Performance-Test |
| AC-07 | Cursor-Pagination korrekt (kein doppelter Eintrag, kein verpasster) | API-Test |
| AC-08 | Archivierung erledigter Aufgaben nach 30 Tagen korrekt (automatischer Job) | DB-Test |
| AC-09 | Termin-Verknüpfung bleibt valide wenn Termin aktualisiert wird | Integration-Test MS2 |
| AC-10 | Berechtigung korrekt: Musiker sieht nur seine Aufgaben | API-Test: Musiker-Token, fremde Aufgabe |

---

## 4. API-Contract

### 4.1 Aufgaben CRUD

```
GET    /api/v1/kapellen/{id}/aufgaben
       ?status=offen,in_bearbeitung
       &zugewiesen_an=mich           // Kurzschreibweise für eigene Aufgaben
       &prioritaet=hoch
       &cursor={cursor}
       &limit=20
       → { aufgaben: [...], naechster_cursor: "...", total: 42 }

POST   /api/v1/kapellen/{id}/aufgaben
       Body: AufgabeCreateDto
       → 201 Created, AufgabeDto

GET    /api/v1/kapellen/{id}/aufgaben/{aufgabeId}
       → AufgabeDto (mit History)

PATCH  /api/v1/kapellen/{id}/aufgaben/{aufgabeId}
       Body: AufgabePatchDto  // Titel, Beschreibung, Fälligkeit, Priorität, Termin-ID
       → 200 OK, AufgabeDto

DELETE /api/v1/kapellen/{id}/aufgaben/{aufgabeId}
       → 204 No Content (Soft-Delete, nur Ersteller/Admin)
```

### 4.2 Status-Management

```
PUT /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/status
    Body: { status: "in_bearbeitung" | "erledigt" | "offen", kommentar?: "..." }
    Auth: Zugewiesener oder Ersteller
    → 200 OK, { status, geaendert_am, geaendert_von }
```

### 4.3 Zuweisung

```
PUT    /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/zuweisungen
       Body: { mitglied_ids: ["uuid", "uuid"] }  // vollständige Ersetzung
       Auth: Admin, Dirigent, Registerführer, Ersteller
       → 200 OK

DELETE /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/zuweisungen/mich
       Body: { kommentar: "Nicht zuständig" }
       → 204 No Content
```

### 4.4 Kommentare

```
GET    /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/kommentare
       → [{ id, text, ersteller, erstellt_am }]

POST   /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/kommentare
       Body: { text: "..." }
       → 201 Created

DELETE /api/v1/kapellen/{id}/aufgaben/{aufgabeId}/kommentare/{kommentarId}
       Auth: Ersteller des Kommentars oder Admin
       → 204 No Content
```

---

## 5. Datenmodell

```sql
-- Aufgaben-Tabelle
CREATE TABLE aufgaben (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  kapelle_id        UUID        NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
  titel             TEXT        NOT NULL CHECK (char_length(titel) BETWEEN 1 AND 200),
  beschreibung      TEXT        CHECK (char_length(beschreibung) <= 2000),
  status            TEXT        NOT NULL DEFAULT 'offen'
                                  CHECK (status IN ('offen', 'in_bearbeitung', 'erledigt')),
  prioritaet        TEXT        NOT NULL DEFAULT 'mittel'
                                  CHECK (prioritaet IN ('niedrig', 'mittel', 'hoch')),
  faellig_am        TIMESTAMPTZ,
  termin_id         UUID        REFERENCES termine(id) ON DELETE SET NULL,
  erstellt_von      UUID        NOT NULL REFERENCES nutzer(id),
  erstellt_am       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  geaendert_am      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  geloescht_am      TIMESTAMPTZ,          -- Soft-Delete
  archiviert_am     TIMESTAMPTZ,          -- 30-Tage-Archivierung

  INDEX idx_aufgaben_kapelle_status (kapelle_id, status) WHERE geloescht_am IS NULL,
  INDEX idx_aufgaben_faellig (faellig_am) WHERE status != 'erledigt'
);

-- Zuweisungen (N:M)
CREATE TABLE aufgaben_zuweisungen (
  aufgabe_id        UUID        NOT NULL REFERENCES aufgaben(id) ON DELETE CASCADE,
  nutzer_id         UUID        NOT NULL REFERENCES nutzer(id),
  zugewiesen_am     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  zugewiesen_von    UUID        NOT NULL REFERENCES nutzer(id),
  
  PRIMARY KEY (aufgabe_id, nutzer_id)
);

-- Status-History (Audit-Log)
CREATE TABLE aufgaben_history (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  aufgabe_id        UUID        NOT NULL REFERENCES aufgaben(id) ON DELETE CASCADE,
  aktion            TEXT        NOT NULL,  -- 'erstellt', 'status_geaendert', 'zugewiesen', 'kommentar'
  von_status        TEXT,
  zu_status         TEXT,
  nutzer_id         UUID        NOT NULL REFERENCES nutzer(id),
  kommentar         TEXT,
  erstellt_am       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  INDEX idx_aufgaben_history_aufgabe (aufgabe_id, erstellt_am DESC)
);

-- Kommentare
CREATE TABLE aufgaben_kommentare (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  aufgabe_id        UUID        NOT NULL REFERENCES aufgaben(id) ON DELETE CASCADE,
  nutzer_id         UUID        NOT NULL REFERENCES nutzer(id),
  text              TEXT        NOT NULL CHECK (char_length(text) BETWEEN 1 AND 2000),
  erstellt_am       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  geloescht_am      TIMESTAMPTZ
);

-- Erinnerungen
CREATE TABLE aufgaben_erinnerungen (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  aufgabe_id        UUID        NOT NULL REFERENCES aufgaben(id) ON DELETE CASCADE,
  nutzer_id         UUID        NOT NULL REFERENCES nutzer(id),
  erinnerung_am     TIMESTAMPTZ NOT NULL,
  gesendet          BOOLEAN     NOT NULL DEFAULT FALSE,
  gesendet_am       TIMESTAMPTZ,
  
  INDEX idx_erinnerungen_pending (erinnerung_am) WHERE gesendet = FALSE
);
```

---

## 6. Berechtigungsmatrix

| Aktion | Admin | Dirigent | Registerführer | Notenwart | Musiker |
|--------|-------|----------|----------------|-----------|---------|
| Aufgabe erstellen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Beliebige Aufgabe bearbeiten | ✅ | ✅ | Nur eigene | ❌ | ❌ |
| Aufgabe jedem zuweisen | ✅ | ✅ | Nur eigenem Register | ❌ | ❌ |
| Aufgabe löschen | ✅ | Nur eigene | Nur eigene | ❌ | ❌ |
| Status eigener Aufgaben ändern | ✅ | ✅ | ✅ | ✅ | ✅ |
| Alle Kapellen-Aufgaben sehen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Nur zugewiesene Aufgaben sehen | — | — | — | ✅ | ✅ |
| Kommentare schreiben | ✅ | ✅ | ✅ | ✅ (eigene) | ✅ (eigene) |
| Eigenen Kommentar löschen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fremden Kommentar löschen | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 Zugewiesenes Mitglied verlässt die Kapelle
- **Szenario:** Mitglied mit offenen Aufgaben verlässt die Kapelle oder wird entfernt.
- **Verhalten:** Zuweisung wird entfernt. Aufgabe bleibt bestehen aber ohne Zuweisung. Ersteller erhält Benachrichtigung „Mitglied X hat die Kapelle verlassen — Aufgabe [Titel] ist nun niemandem zugewiesen."

### 7.2 Fälligkeitsdatum in der Vergangenheit bei Erstellung
- **Szenario:** Dirigent erstellt Aufgabe mit gestern als Fälligkeitsdatum (Tippfehler oder rückwirkend).
- **Verhalten:** Keine Blockierung. Warnung: „Das Fälligkeitsdatum liegt in der Vergangenheit." Speichern möglich. Erinnerungen werden nicht rückwirkend gesendet.

### 7.3 Race Condition bei gleichzeitiger Status-Änderung
- **Szenario:** Zwei Nutzer setzen gleichzeitig Status von „Offen" auf „In Bearbeitung".
- **Verhalten:** Optimistic Concurrency: letzter Schreiber gewinnt. History zeigt beide Aktionen. Kein Datenverlust, kein inkonsistenter State.

### 7.4 Sehr viele Aufgaben (> 1000 pro Kapelle)
- **Szenario:** Aktive Kapelle mit vielen Aufgaben über lange Zeit.
- **Verhalten:** Pagination (Cursor-basiert) verhindert Performance-Probleme. Archivierung nach 30 Tagen hält aktive Datenmenge klein. Suche auf Datenbankindex, nicht In-Memory.

### 7.5 Erinnerungs-Versand schlägt fehl (Push-Fehler)
- **Szenario:** Push-Token ungültig (Nutzer hat App deinstalliert).
- **Verhalten:** Push-Fehler wird still geloggt (kein Absturz). In-App-Benachrichtigung als Fallback (erscheint beim nächsten App-Öffnen). Token wird als ungültig markiert (kein erneuter Versand).

### 7.6 Termin gelöscht, Aufgabe verknüpft
- **Szenario:** Konzertplanung-Termin wird gelöscht, darauf referenzierende Aufgaben existieren.
- **Verhalten:** `ON DELETE SET NULL` — Aufgabe bleibt, `termin_id = null`. Toast in Aufgaben-Detail: „Verknüpfter Termin wurde gelöscht."

### 7.7 Musiker versucht Aufgabe zu sehen, die er nicht sehen darf
- **Szenario:** Musiker ruft `/aufgaben/{id}` für eine Aufgabe auf, die einem anderen Mitglied zugewiesen ist.
- **Verhalten:** 403 Forbidden (nicht 404, um Sicherheit nicht zu gefährden, aber auch nicht 404 um unnötige Verwirrung zu vermeiden — Kapellen-interne Ressource). Richtlinie: konsistent mit anderen Kapellen-Ressourcen.

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Kapellenverwaltung + Rollen (MS1) | Berechtigungsmatrix, Mitglieder-Referenzen | MS1 |
| Auth + JWT (MS1) | Nutzer-Identifikation für Zuweisung | MS1 |
| Push-Notification-Infrastruktur | Erinnerungen (FCM/APNs) | MS3 (Infrastruktur) |

### 8.2 Optionale Kopplung

| Feature | Beziehung |
|---------|-----------|
| Konzertplanung / Kalender (MS2) | Termin-Verknüpfung — MS3 nutzt MS2-Termine falls vorhanden |
| Kommunikation/Chat (MS2) | Aufgaben könnten aus Chat heraus erstellt werden (späteres Feature) |

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Aufgabe erstellen (alle Felder, Validierung)
- [ ] US-02: Zuweisung an Mitglieder, Mehrfachzuweisung
- [ ] US-03: Status-Tracking (Offen/In Bearbeitung/Erledigt) mit History
- [ ] US-04: Erinnerungen (In-App + Push opt-in)
- [ ] US-05: Übersicht, Filter, Suche, Meine Aufgaben
- [ ] US-06: Termin-Verknüpfung
- [ ] Alle AC-01 bis AC-10 erfüllt

### Qualität
- [ ] Unit-Tests: Berechtigungsmatrix (alle Rollen × alle Aktionen)
- [ ] Unit-Tests: Erinnerungs-Job (kein Versand wenn erledigt)
- [ ] Integration-Tests: Aufgabe erstellen → zuweisen → Status ändern → Benachrichtigung
- [ ] Integration-Tests: Mitglied verlässt Kapelle → Zuweisung bereinigt
- [ ] Performance-Test: Filter + Suche bei 1000 Aufgaben ≤ 500ms
- [ ] Code Coverage ≥ 80%

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Farbkodierung Status klar und zugänglich (WCAG AA)
- [ ] „Meine Aufgaben" auf Startseite oder prominent zugänglich
- [ ] Dark Mode korrekt

### Deployment
- [ ] Archivierungs-Job (30-Tage-Erledigt → Archiv) konfiguriert + getestet
- [ ] Push-Notification-Infrastruktur (FCM + APNs) dokumentiert
- [ ] Swagger-Dokumentation für alle Endpunkte
- [ ] DB-Migrationen getestet
