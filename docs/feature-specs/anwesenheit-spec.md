# Feature-Spezifikation: Anwesenheitsstatistiken

> **Issue:** [TBD]  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** Konzertplanung / Terminverwaltung (TerminTeilnahme-System)  
> **Meilenstein:** MS2  
> **UX-Referenz:** `docs/ux-design.md` §[TBD] — Anwesenheitsstatistiken

---

## 1. Feature-Überblick

Anwesenheitsstatistiken ermöglichen es Dirigenten und Admins, die Teilnahme von Musikern über verschiedene Dimensionen hinweg zu analysieren — pro Musiker, Register, Zeitraum und Termin-Typ. Das Feature liefert **visualisierte Einblicke** (Charts, Trends, Heatmaps) und ermöglicht den **Export** von Berichten (CSV, PDF).

### 1.1 Ziel

Kapellen-Leitungen sollen fundierte Entscheidungen treffen können: Welcher Musiker hat wie viele Proben/Konzerte besucht? Welches Register ist am zuverlässigsten? Gibt es Trends über die Zeit? Musiker sollen ihre eigene Anwesenheitsquote transparent einsehen können.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Visualisierung: Balken, Linien, Pie-Charts | Predictive Analytics (ML-basiert) |
| Dimensionen: Musiker, Register, Zeitraum, Typ | Individuelle Anwesenheits-Warnungen |
| Trends: Anwesenheitsquote über Monate | SMS/Push-Benachrichtigungen |
| Register-Analyse: Heatmap/Tabelle | Automatische Konzertbesetzung |
| Export: CSV (Rohdaten) + PDF (formatiert) | Vergleich mit anderen Kapellen |
| Datenschutz: Rollen-basierte Sichtbarkeit | GEMA-Meldungen basierend auf Anwesenheit |
| Zeitraum-Filter (Monat, Quartal, Jahr) | Korrelation mit Wetter/Feiertagen |
| Termin-Typ-Filter (Probe, Konzert, Marschmusik) | Externe Kalender-Integration |

### 1.3 Kontext & Datenquelle

**Datenbasis:** Anwesenheitsstatistiken bauen auf dem **TerminTeilnahme-System** aus der Konzertplanung auf. Keine eigenen Entities — Server-side Aggregation der bestehenden Zu-/Absage-Daten.

**Visualisierung:** Flutter Charts Library (z.B. fl_chart oder syncfusion_flutter_charts).

**Zielgruppen:**
- **Admin/Dirigent:** Vollständige Übersicht über alle Musiker
- **Musiker:** Nur eigene Statistik sichtbar

---

## 2. User Stories

### US-01: Anwesenheitsquote pro Musiker

> *Als Dirigent möchte ich die Anwesenheitsquote aller Musiker über einen definierten Zeitraum sehen, damit ich erkennen kann, wer regelmäßig fehlt.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt bestehende TerminTeilnahme-Daten, keine neuen Erfassungsmechanismen
- **N**egotiable: Visualisierung als Balkendiagramm oder Tabellenansicht
- **V**aluable: Kerneinsicht für Kapellen-Management — essenziell für MS2
- **E**stimatable: ~0,5 Sprint
- **S**mall: Nur Anzeige — keine Editier-Logik
- **T**estable: ✅ API liefert Quote, Frontend zeigt Chart

**Akzeptanzkriterien:**
1. Dirigent/Admin sieht auf Statistik-Dashboard: "Anwesenheit pro Musiker"
2. Musiker-Liste mit Spalten: Name, Teilnahmen, Absagen, Quote (%)
3. Quote = (Teilnahmen / (Teilnahmen + Absagen)) × 100
4. Sortierbar nach Quote (auf-/absteigend)
5. Zeitraum-Filter: Letzte 30 Tage, Letztes Quartal, Aktuelles Jahr, Benutzerdefiniert
6. Nur Termine mit Status „Zugesagt" oder „Abgesagt" zählen (Nicht-Beantwortet = ausgeschlossen)
7. Musiker-Rolle sieht nur eigene Statistik
8. Leeres State: "Keine Termine im gewählten Zeitraum"

---

### US-02: Register-Analyse

> *Als Admin möchte ich sehen, welches Register die höchste und niedrigste Anwesenheitsquote hat, damit ich gezielt intervenieren kann.*

**Kriterien (INVEST):**
- **I**ndependent: Baut auf TerminTeilnahme + Register-Zuordnung
- **N**egotiable: Heatmap oder Balkendiagramm
- **V**aluable: Hilfreich für Registerführer-Steuerung
- **E**stimatable: ~0,5 Sprint
- **S**small: Nur Aggregation + Anzeige
- **T**estable: ✅ Register-Quoten korrekt berechnet

**Akzeptanzkriterien:**
1. Ansicht: "Anwesenheit pro Register"
2. Register-Liste mit: Register-Name, Mitglieder-Anzahl, Durchschnittsquote (%)
3. Sortierbar nach Quote
4. Drill-down: Klick auf Register zeigt Musiker-Details dieses Registers
5. Zeitraum-Filter (wie US-01)
6. Registerführer sieht nur das eigene Register
7. Farbcodierung: Grün (>80%), Gelb (60–80%), Rot (<60%)

---

### US-03: Trend-Analyse über Zeit

> *Als Dirigent möchte ich die Anwesenheitsentwicklung über die letzten Monate als Liniendiagramm sehen, damit ich Trends erkenne.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt TerminTeilnahme mit Zeitstempel
- **N**egotiable: Linien- oder Flächendiagramm
- **V**aluable: Frühwarnsystem für sinkende Beteiligung
- **E**stimatable: ~0,5 Sprint
- **S**mall: Nur Visualisierung
- **T**estable: ✅ Trend über Monate korrekt dargestellt

**Akzeptanzkriterien:**
1. Ansicht: "Anwesenheitstrend"
2. X-Achse: Zeit (Monate), Y-Achse: Anwesenheitsquote (%)
3. Datenpunkte: Monatliche Durchschnittsquote über alle Musiker
4. Zeitraum-Auswahl: 3, 6, 12 Monate
5. Optional: Einzelne Musiker als separate Linien (Admin/Dirigent)
6. Musiker sieht nur eigene Trendlinie
7. Legende mit Farbzuordnung
8. Interaktiv: Hover zeigt exakte Werte

---

### US-04: Termin-Typ-Filter

> *Als Dirigent möchte ich Anwesenheit getrennt nach Termin-Typ (Probe, Konzert, Marschmusik) filtern, damit ich sehe, wo die Beteiligung unterschiedlich ist.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert Termin-Typ-Attribut in Terminen
- **N**egotiable: Filter-Chips oder Dropdown
- **V**aluable: Einblick in unterschiedliches Engagement-Level
- **E**stimatable: ~0,3 Sprint
- **S**mall: UI-Filter + Backend-Query-Parameter
- **T**estable: ✅ Filter liefert korrekte Subset-Daten

**Akzeptanzkriterien:**
1. Filter-Chips: „Alle", „Proben", „Konzerte", „Marschmusik"
2. Multi-Select möglich (z.B. nur Proben + Konzerte)
3. Filter wirkt auf alle Statistik-Ansichten (Musiker, Register, Trend)
4. Default: "Alle Typen"
5. Anzeige: „23 Proben, 5 Konzerte analysiert"
6. Persistenz: Filter bleibt beim Wechsel zwischen Tabs erhalten

---

### US-05: Export (CSV + PDF)

> *Als Admin möchte ich Anwesenheitsdaten als CSV oder PDF exportieren, damit ich sie offline analysieren oder archivieren kann.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt bestehende Statistik-API
- **N**egotiable: PDF-Layout kann simpel sein (MS2), erweitert in MS3
- **V**aluable: Wichtig für Vorstands-Berichte und Archivierung
- **E**stimatable: ~0,7 Sprint (PDF-Generierung Server-side)
- **S**mall: Nur Export-Logik
- **T**estable: ✅ CSV/PDF Download funktioniert, Inhalte korrekt

**Akzeptanzkriterien:**
1. Button „Exportieren" mit Dropdown: „CSV", „PDF"
2. **CSV:** Rohdaten als Tabelle (UTF-8, Semikolon-Separator)
   - Spalten: Musiker-Name, Register, Teilnahmen, Absagen, Quote (%), Zeitraum
   - Keine Charts, nur Daten
3. **PDF:** Formatierter Bericht mit:
   - Header: Kapellen-Name, Zeitraum, Generierungsdatum
   - Abschnitte: Musiker-Tabelle, Register-Übersicht, Trend-Chart (als Grafik)
   - Footer: Seite X von Y
4. Dateiname: `Anwesenheit_{Kapellenname}_{Zeitraum}.csv` / `.pdf`
5. Server-side Generierung (kein Client-side PDF-Rendering)
6. Zeitraum und Filter werden in Export übernommen
7. Download-Link verfügbar für 24h (dann automatisch gelöscht)
8. Fehlerfall: „Export fehlgeschlagen, bitte erneut versuchen"

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Validierung |
|----|-----------|-------------|
| AC-01 | Anwesenheitsquote = Teilnahmen / (Teilnahmen + Absagen), gerundet auf 1 Dezimalstelle | Unit-Test: Verschiedene Kombinationen |
| AC-02 | Nicht-beantwortete Termine zählen nicht in Statistik | Integration-Test: API filtert korrekt |
| AC-03 | Musiker sieht nur eigene Daten, Admin/Dirigent sehen alle | Berechtigungstest: 403 bei unauthorisiertem Zugriff |
| AC-04 | Zeitraum-Filter: „Benutzerdefiniert" erlaubt Datum-Auswahl von-bis | UI-Test: Date-Picker funktioniert |
| AC-05 | Charts sind interaktiv (Hover zeigt Details, Klick = Drill-down) | E2E-Test |
| AC-06 | Export-Dateien enthalten nur Daten aus gewähltem Filter/Zeitraum | Test: CSV-Inhalt mit API-Response vergleichen |
| AC-07 | PDF-Generierung dauert < 5 Sekunden für 100 Termine | Performance-Test |
| AC-08 | Heatmap zeigt Register × Termin-Matrix mit Farbcodierung | UI-Review: Wanda-Approval |
| AC-09 | Leere-State-Handling: Sinnvolle Meldung wenn 0 Termine vorhanden | E2E-Test |
| AC-10 | DSGVO-konform: Keine Weitergabe von Anwesenheitsdaten an Dritte | Security-Review |

---

## 4. API-Contract

**Base Path:** `/api/v1/kapellen/{kapelle_id}/statistiken`  
**Auth:** Bearer JWT (alle Endpunkte erfordern Authentifizierung)

### 4.1 Statistik-Endpunkte

```
GET    /api/v1/kapellen/{kapelle_id}/statistiken/musiker          → Anwesenheit pro Musiker
GET    /api/v1/kapellen/{kapelle_id}/statistiken/register         → Anwesenheit pro Register
GET    /api/v1/kapellen/{kapelle_id}/statistiken/trends           → Zeitverlauf (Trend)
POST   /api/v1/kapellen/{kapelle_id}/statistiken/export           → CSV/PDF Export (async)
GET    /api/v1/kapellen/{kapelle_id}/statistiken/export/{job_id}  → Export-Status / Download
```

### 4.2 Query-Parameter (alle Endpunkte)

| Parameter | Typ | Default | Beschreibung |
|-----------|-----|---------|--------------|
| `zeitraum_von` | ISO-Date | Vor 30 Tagen | Start-Datum (inklusiv) |
| `zeitraum_bis` | ISO-Date | Heute | End-Datum (inklusiv) |
| `termin_typen` | String[] | ["alle"] | Filter: `probe`, `konzert`, `marschmusik` |
| `musiker_id` | UUID | — | Nur für Musiker-Rolle (automatisch eigene ID) |

### 4.3 GET /statistiken/musiker

**Request:**
```
GET /api/v1/kapellen/uuid-123/statistiken/musiker?zeitraum_von=2026-01-01&zeitraum_bis=2026-03-31&termin_typen=probe,konzert
Authorization: Bearer {JWT}
```

**Response 200:**
```json
{
  "zeitraum": {
    "von": "2026-01-01",
    "bis": "2026-03-31"
  },
  "termin_typen": ["probe", "konzert"],
  "gesamt_termine": 23,
  "musiker": [
    {
      "musiker_id": "uuid",
      "name": "Anna Musterfrau",
      "register": "Klarinetten",
      "teilnahmen": 20,
      "absagen": 3,
      "quote": 87.0,
      "trend": "steigend"
    },
    {
      "musiker_id": "uuid",
      "name": "Max Beispiel",
      "register": "Trompeten",
      "teilnahmen": 15,
      "absagen": 8,
      "quote": 65.2,
      "trend": "fallend"
    }
  ]
}
```

**Fehlercodes:**
- `403` — Nicht berechtigt (Musiker versucht fremde Statistiken abzurufen)
- `404` — Kapelle nicht gefunden
- `422` — Ungültige Query-Parameter (z.B. zeitraum_von > zeitraum_bis)

---

### 4.4 GET /statistiken/register

**Response 200:**
```json
{
  "zeitraum": {
    "von": "2026-01-01",
    "bis": "2026-03-31"
  },
  "register": [
    {
      "register_id": "uuid",
      "name": "Klarinetten",
      "mitglieder_anzahl": 8,
      "quote": 82.5,
      "farbe": "#4A90D9"
    },
    {
      "register_id": "uuid",
      "name": "Trompeten",
      "mitglieder_anzahl": 6,
      "quote": 68.3,
      "farbe": "#E74C3C"
    }
  ]
}
```

---

### 4.5 GET /statistiken/trends

**Response 200:**
```json
{
  "zeitraum": {
    "von": "2025-10-01",
    "bis": "2026-03-31"
  },
  "granularitaet": "monat",
  "datenpunkte": [
    {
      "periode": "2025-10",
      "quote": 75.5,
      "termine_anzahl": 8
    },
    {
      "periode": "2025-11",
      "quote": 78.2,
      "termine_anzahl": 6
    },
    {
      "periode": "2025-12",
      "quote": 71.0,
      "termine_anzahl": 4
    },
    {
      "periode": "2026-01",
      "quote": 80.1,
      "termine_anzahl": 9
    },
    {
      "periode": "2026-02",
      "quote": 83.5,
      "termine_anzahl": 7
    },
    {
      "periode": "2026-03",
      "quote": 85.0,
      "termine_anzahl": 6
    }
  ]
}
```

**Query-Parameter:**
- `granularitaet`: `monat` (default), `quartal`, `jahr`

---

### 4.6 POST /statistiken/export

**Request:**
```json
{
  "format": "pdf",
  "zeitraum_von": "2026-01-01",
  "zeitraum_bis": "2026-03-31",
  "termin_typen": ["probe", "konzert"],
  "include_charts": true
}
```

**Response 202 Accepted:**
```json
{
  "job_id": "uuid",
  "status": "in_progress",
  "erstellt_am": "2026-03-28T10:00:00Z",
  "schaetzung": "~10 Sekunden"
}
```

**GET /statistiken/export/{job_id} — Response 200 (wenn fertig):**
```json
{
  "job_id": "uuid",
  "status": "completed",
  "download_url": "https://storage.../anwesenheit_uuid.pdf",
  "expires_at": "2026-03-29T10:00:00Z",
  "dateigroesse_bytes": 245678
}
```

**Fehlercodes:**
- `400` — Ungültiges Format oder Parameter
- `404` — Job nicht gefunden
- `500` — Export-Generierung fehlgeschlagen

---

## 5. Datenmodell

### 5.1 Datenquelle: TerminTeilnahme (aus Konzertplanung)

```sql
-- Keine neuen Tabellen erforderlich!
-- Statistiken basieren auf Aggregation von:

CREATE TABLE termin_teilnahme (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    termin_id       UUID NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
    musiker_id      UUID NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    status          VARCHAR(20) NOT NULL,  -- 'zugesagt', 'abgesagt', 'offen'
    antwort_am      TIMESTAMPTZ,
    bemerkung       VARCHAR(500),
    erstellt_am     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (termin_id, musiker_id)
);

-- Termine haben Typ-Attribut:
CREATE TABLE termine (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    titel           VARCHAR(200) NOT NULL,
    typ             VARCHAR(50) NOT NULL,  -- 'probe', 'konzert', 'marschmusik', ...
    beginn          TIMESTAMPTZ NOT NULL,
    ende            TIMESTAMPTZ,
    ort             VARCHAR(200),
    -- ...
);
```

### 5.2 Export-Jobs (temporär)

```sql
CREATE TYPE export_status AS ENUM ('in_progress', 'completed', 'failed');

CREATE TABLE statistik_export_jobs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    erstellt_von    UUID NOT NULL REFERENCES musiker(id),
    format          VARCHAR(10) NOT NULL,  -- 'csv', 'pdf'
    parameter       JSONB NOT NULL,        -- Filter, Zeitraum, etc.
    status          export_status NOT NULL DEFAULT 'in_progress',
    datei_url       TEXT,
    dateigroesse    INTEGER,
    erstellt_am     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    abgeschlossen_am TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ NOT NULL   -- 24h nach Fertigstellung
);

CREATE INDEX idx_export_jobs_kapelle ON statistik_export_jobs(kapelle_id, erstellt_am DESC);
CREATE INDEX idx_export_jobs_expires ON statistik_export_jobs(expires_at) WHERE status = 'completed';
```

**Hinweis:** Export-Jobs werden nach Ablauf automatisch gelöscht (Cron-Job).

---

## 6. Berechtigungsmatrix

> **Prinzip:** Server-side Berechtigungsprüfung. Musiker sehen nur eigene Daten, alle anderen Rollen haben erweiterte Sichtbarkeit basierend auf ihrer Funktion.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|
| **Anwesenheit — Alle Musiker** | | | | | |
| Alle Musiker-Statistiken anzeigen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigene Statistik anzeigen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Register-Statistiken** | | | | | |
| Alle Register-Statistiken anzeigen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigenes Register anzeigen | ✅ | ✅ | ❌ | ✅ | ❌ |
| **Trends** | | | | | |
| Kapellen-weite Trends anzeigen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigene Trendlinie anzeigen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Export** | | | | | |
| Vollständige Daten exportieren | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigene Daten exportieren | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Filter/Zeitraum** | | | | | |
| Zeitraum-Filter setzen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Termin-Typ-Filter setzen | ✅ | ✅ | ✅ | ✅ | ✅ |

**Spezialfall Registerführer:**
- Sieht Statistiken aller Musiker **nur im eigenen Register**
- Request mit `register_id`-Filter erforderlich
- Server validiert: Ist der Nutzer Registerführer für dieses Register?

---

## 7. Edge Cases

### 7.1 Musiker ohne Zu-/Absagen im Zeitraum

**Szenario:** Ein Musiker wurde erst nach dem gewählten Zeitraum eingeladen, oder er hat bislang auf keinen Termin geantwortet.

**Verhalten:**
- Musiker erscheint in Liste mit Quote = `null` oder "—"
- Fußnote: "Keine Rückmeldungen im gewählten Zeitraum"
- Sortierung: Null-Werte ans Ende der Liste

---

### 7.2 Kapelle mit 0 Terminen

**Szenario:** Kapelle ist neu oder hat im gewählten Zeitraum keine Termine.

**Verhalten:**
- Empty State: "Keine Termine im gewählten Zeitraum. Statistiken werden angezeigt, sobald Termine erfasst sind."
- Export-Funktion deaktiviert (Button ausgegraut)
- Keine 404-Fehler — nur UI-Hinweis

---

### 7.3 Termin mit Typ "Sonstiges" oder fehlendem Typ

**Szenario:** Ein Termin hat keinen oder einen nicht-klassifizierten Typ.

**Verhalten:**
- Typ = `sonstiges` (Fallback)
- Filter "Alle" schließt auch "Sonstiges" ein
- Typ-Filter zeigt nur bekannte Typen (`probe`, `konzert`, `marschmusik`)
- "Sonstiges" kann durch API-Parameter `typ=sonstiges` explizit gefiltert werden

---

### 7.4 PDF-Generierung schlägt fehl

**Szenario:** Server-Fehler beim PDF-Rendering (z.B. zu viele Daten, Chart-Lib-Fehler).

**Verhalten:**
- `POST /statistiken/export` → `202 Accepted`
- `GET /statistiken/export/{job_id}` → Status = `failed`
- Response:
  ```json
  {
    "job_id": "uuid",
    "status": "failed",
    "fehler": "PDF-Generierung fehlgeschlagen. Bitte verkleinere den Zeitraum oder versuche CSV.",
    "timestamp": "2026-03-28T10:05:00Z"
  }
  ```
- Frontend: Fehlermeldung + Vorschlag "Stattdessen CSV exportieren?"
- Admin/Dirigent erhält zusätzlich Fehlerbericht per E-Mail (optional, konfigurierbar)

---

### 7.5 Musiker verlässt Kapelle während Export läuft

**Szenario:** Musiker startet Export, wird dann aus Kapelle entfernt, Job ist noch in Bearbeitung.

**Verhalten:**
- Export wird **trotzdem fertiggestellt** (Job bereits gestartet)
- Bei Abruf via `GET /statistiken/export/{job_id}` → `403 Forbidden` (nicht mehr Mitglied)
- Export-Datei wird nach 24h automatisch gelöscht (auch wenn nicht heruntergeladen)

---

### 7.6 Zeitraum-Filter: Von-Datum nach Bis-Datum

**Szenario:** Nutzer vertauscht die Daten, z.B. `zeitraum_von=2026-03-31`, `zeitraum_bis=2026-01-01`.

**Verhalten:**
- API validiert: `zeitraum_von` muss ≤ `zeitraum_bis`
- `422 Unprocessable Entity`:
  ```json
  {
    "fehler": "UNGUELTIGE_ZEITRAUM",
    "nachricht": "Das Von-Datum muss vor oder gleich dem Bis-Datum liegen."
  }
  ```
- Frontend: Date-Picker verhindert diese Konstellation bereits (UI-Validation)

---

### 7.7 Registerführer versucht, alle Register zu sehen

**Szenario:** Registerführer (kein Admin/Dirigent) ruft `/statistiken/register` ohne `register_id`-Filter.

**Verhalten:**
- **Option A (streng):** `403 Forbidden` — nur eigenes Register erlaubt
- **Option B (liberal):** Response enthält nur das eigene Register
- **Empfehlung:** Option B (Filter automatisch anwenden) — weniger verwirrend für Nutzer
- API setzt implizit `register_id` = das Register, für das der Nutzer Registerführer ist

---

### 7.8 Multi-Register-Mitgliedschaft

**Szenario:** Ein Musiker ist mehreren Registern zugeordnet (z.B. Klarinette + Saxophon).

**Verhalten:**
- In `/statistiken/musiker`: Musiker wird **einmal** gelistet, Register-Spalte zeigt: "Klarinetten, Saxophone"
- In `/statistiken/register`: Musiker zählt in beiden Registern (Quote-Berechnung erfolgt pro Register-Ansicht)
- Register-Statistik ist **nicht** addiert über alle Register eines Musikers, sondern pro Register isoliert betrachtet

---

## 8. Abhängigkeiten

### 8.1 Funktionale Abhängigkeiten

- **Konzertplanung / Terminverwaltung:** Das Zu-/Absage-System (`termin_teilnahme`) muss vollständig implementiert sein.
- **Kapellenverwaltung:** Register-Zuordnungen müssen existieren.
- **Auth/Onboarding:** JWT-Token müssen Rollen-Informationen enthalten.

### 8.2 Technische Abhängigkeiten

- **Flutter Charts Library:** `fl_chart` (MIT-Lizenz) oder `syncfusion_flutter_charts` (kostenlos für bis zu 5 Entwickler)
- **PDF-Generierung (Server-side):** 
  - .NET: `QuestPDF` (FOSS) oder `iText` (Lizenz prüfen)
  - Node.js: `Puppeteer` oder `PDFKit`
- **CSV-Export:** Standard-Library (kein Drittanbieter erforderlich)

### 8.3 Datenschutz-Abhängigkeiten

- **DSGVO-konform:** Keine Weitergabe von Anwesenheitsdaten an externe Services
- **Server-side Rendering:** Charts werden als Bilder in PDF eingebettet — kein Client-side Export von Rohdaten
- **Export-Datei-Speicherung:** Temporäre S3/Azure-Storage-URLs mit kurzer Ablaufzeit (24h)

---

## 9. Definition of Done

Eine Anwesenheitsstatistik-Implementierung gilt als **Done**, wenn alle folgenden Kriterien erfüllt sind:

### Funktional
- [ ] Alle 5 User Stories (US-01 bis US-05) vollständig implementiert
- [ ] Alle Akzeptanzkriterien (AC-01 bis AC-10) durch Tests abgedeckt
- [ ] Alle Edge Cases (7.1–7.8) implementiert und getestet
- [ ] API-Contract vollständig implementiert (alle Endpunkte aus §4)
- [ ] Berechtigungsmatrix (§6) server-seitig durchgesetzt

### Qualität
- [ ] Unit-Test-Coverage ≥ 80% für Statistik-Aggregation
- [ ] Integration-Tests für alle API-Endpunkte (Happypath + Fehlerfälle)
- [ ] E2E-Test: Vollständiger Flow von Filter-Auswahl → Chart-Anzeige → Export-Download
- [ ] Performance: `/statistiken/musiker` mit 100 Musikern in < 300ms (API 95. Pz.)
- [ ] Performance: PDF-Export mit 100 Terminen in < 5s
- [ ] Keine bekannten Security-Issues (OWASP Top 10 geprüft)

### UX / Design
- [ ] UX-Review durch Wanda bestätigt
- [ ] Charts sind interaktiv (Hover, Drill-down) und barrierefrei (WCAG 2.1 AA)
- [ ] Touch-Targets ≥ 44×44 px
- [ ] Fehlermeldungen sind verständlich und handlungsleitend
- [ ] Empty States (keine Daten) sind sinnvoll gestaltet
- [ ] Farbcodierung ist nicht alleiniger Indikator (auch Text/Symbole)

### Technisch
- [ ] Server-side Aggregation (kein Transfer von Rohdaten ans Frontend)
- [ ] Export-Jobs werden automatisch nach 24h gelöscht (Cron-Job)
- [ ] Zeitraum-Filter validiert (Von ≤ Bis)
- [ ] API-Dokumentation (OpenAPI/Swagger) aktuell
- [ ] DSGVO-konform: Nur autorisierte Nutzer sehen Statistiken

### Deployment
- [ ] Feature-Flag vorhanden (Rollout steuerbar)
- [ ] Monitoring-Alerts für PDF-Generierungs-Fehler
- [ ] Changelog-Eintrag erstellt

---

*Erstellt von Hill (Product Manager) · Sheetstorm MS2*
