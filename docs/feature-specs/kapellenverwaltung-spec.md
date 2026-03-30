# Feature-Spezifikation: Kapellenverwaltung

> **Issue:** #15  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** #14 (UX-Design Kapellenverwaltung — Wanda), #7 (Backend-Setup — Banner), #8 (Frontend-Setup — Romanoff)  
> **Meilenstein:** MS1  
> **UX-Referenz:** `docs/ux-design.md` §3.5 — Kapellenverwaltung (Wanda, bis vollständige UX-Spec in `docs/ux-specs/kapellenverwaltung.md` vorliegt)

---

## 1. Feature-Überblick

Die Kapellenverwaltung ist das **organisatorische Herzstück** von Sheetstorm. Sie ermöglicht es, Blaskapellen als eigenständige Einheiten zu verwalten — mit Mitgliedern, Rollen, Instrumenten-Registern und Einladungssystem.

### 1.1 Ziel

Ein Vereinsvorstand (Admin) soll eine Kapelle anlegen, Mitglieder einladen, Rollen vergeben und Register verwalten können — sodass alle anderen Features (Noten, Setlists, Termine) auf einer klar strukturierten Organisationsebene aufsetzen. Musiker können mehreren Kapellen gleichzeitig angehören und nahtlos zwischen ihnen wechseln.

Zusätzlich erhält jeder Nutzer bei der Registrierung automatisch eine persönliche Bibliothek — **„Meine Musik"** — die wie eine Kapelle funktioniert, in der der Nutzer alleiniger Admin ist. „Meine Musik" bietet dieselben Features wie eine reguläre Kapelle (Noten, Setlists etc.), ist aber rein persönlich: Andere Nutzer können nicht eingeladen werden.

Der **Einstiegsscreen** nach Login und Onboarding ist die **Kapellen-/Band-Auswahl** — der Nutzer wählt zuerst „Meine Musik" oder eine seiner Kapellen, dann sieht er alles im gewählten Kontext. Beitritte zu Kapellen erfordern eine **Genehmigung** durch berechtigte Personen (kein Auto-Join).

### 1.2 Scope MS1

| Im Scope | Außerhalb Scope (MS2+) |
|----------|------------------------|
| „Meine Musik" — Persönliche Bibliothek als Kapelle | GEMA-Konfiguration |
| Kapelle erstellen & bearbeiten | Anwesenheitsstatistiken |
| Mitglieder einladen (E-Mail + Link) | Nachrichten-Board / Pinnwand |
| Beitrittsanfrage mit Genehmigung (kein Auto-Join) | Aufgabenverwaltung |
| Rollen zuweisen (5 Rollen) | Dirigenten-Mastersteuerung |
| Multi-Kapellen-Wechsel + Kapellen-Auswahl als Einstieg | Inventarverwaltung |
| Instrument-Register verwalten | Externe Kalender-Sync |
| Mitglied entfernen / verlassen | Umfragen / Abstimmungen |
| Einladung widerrufen | |
| Kapellen-Dashboard (Übersicht) | |

### 1.3 Kontext & Marktdifferenzierung

**Alleinstellungsmerkmal:** Multi-Kapellen-Zugehörigkeit wird von keinem bekannten Wettbewerber (forScore, MobileSheets, Konzertmeister, BAND) vollständig unterstützt. Sheetstorm ist hier Pionier.

**Rollensystem:** Blasmusik-spezifisch mit Registerführer als eigenständiger Rolle — kein Wettbewerber hat diese Granularität.

---

## 2. User Stories

### US-00: „Meine Musik" — Persönliche Bibliothek

> *Als Musiker möchte ich eine persönliche Bibliothek „Meine Musik" haben, die wie eine Kapelle funktioniert, damit ich meine privaten Noten, Setlists und Stücke unabhängig von Kapellen verwalten kann.*

**Kriterien (INVEST):**
- **I**ndependent: Existiert unabhängig von jeder Kapellen-Mitgliedschaft
- **N**egotiable: Features gleich wie Kapelle, aber Einladungs-/Mitglieder-Flow entfällt
- **V**aluable: Nutzer hat sofort nach Registrierung einen nutzbaren Kontext
- **E**stimatable: ~0.5 Sprints (Logik leitet sich von Kapelle ab)
- **S**mall: Kein separates System — nutzt Kapellen-Infrastruktur mit Sonder-Flag
- **T**estable: ✅ Nach Registrierung existiert „Meine Musik" mit Nutzer als Admin

**Akzeptanzkriterien:**
1. „Meine Musik" wird bei der Registrierung **automatisch** erstellt — der Nutzer muss nichts tun
2. Der Nutzer ist automatisch **alleiniger Admin** seiner „Meine Musik"-Kapelle
3. „Meine Musik" bietet dieselben Features wie eine reguläre Kapelle: Noten, Setlists, Stücke, Annotationen
4. „Meine Musik" kann **nicht gelöscht** werden — weder vom Nutzer noch von Admins
5. Der Nutzer kann „Meine Musik" **nicht verlassen** — die Mitgliedschaft ist permanent
6. Andere Nutzer können **nicht** in „Meine Musik" eingeladen werden — kein Einladungsflow verfügbar
7. „Meine Musik" erscheint immer als **erster Eintrag** im Kapellen-Wechsel-Selector
8. „Meine Musik" hat einen visuell unterscheidbaren Eintrag (eigenes Icon, kein reguläres Kapellen-Logo)
9. Register-Verwaltung entfällt für „Meine Musik" (kein sinnvoller Anwendungsfall)
10. **Fehlerfall:** Versuch „Meine Musik" zu löschen → `403 Forbidden` mit Meldung „Die persönliche Bibliothek kann nicht gelöscht werden"
11. **Fehlerfall:** Versuch jemanden in „Meine Musik" einzuladen → `403 Forbidden` mit Meldung „In die persönliche Bibliothek können keine Mitglieder eingeladen werden"

---

### US-01: Kapelle erstellen

> *Als Vereinsvorstand möchte ich eine neue Kapelle in Sheetstorm anlegen, damit mein Verein die App nutzen kann.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert nur einen registrierten Account
- **N**egotiable: Logo/Branding sind optional für MS1
- **V**aluable: Ohne Kapelle ist kein organisiertes Arbeiten möglich
- **E**stimatable: ~1 Sprint
- **S**mall: Nur Erstanlage — Einladungen folgen in US-02
- **T**estable: ✅ Kapelle mit Name + Beschreibung existiert nach dem Flow in der DB

**Akzeptanzkriterien:**
1. Eingeloggter Nutzer kann auf "Neue Kapelle erstellen" tippen (Profil-Tab → Kapellen-Wechsel → "+ Neue Kapelle erstellen")
2. Pflichtfeld: **Name** (1–80 Zeichen, nicht leer, keine reinen Leerzeichen)
3. Optionale Felder: Beschreibung (max. 500 Zeichen), Ort (max. 100 Zeichen), Logo (JPG/PNG, max. 5 MB)
4. Nach Erstellen: Der erstellende Nutzer erhält automatisch die Rolle **Admin**
5. Die Kapelle erscheint sofort im Kapellen-Wechsel-Selector
6. Die neue Kapelle ist initial leer (0 Mitglieder außer dem Admin, 0 Stücke)
7. Name muss nicht global eindeutig sein (zwei Kapellen dürfen gleichen Namen haben)
8. **Fehlerfall:** Wenn Name leer ist → Validierungsfehler, Speichern blockiert
9. **Fehlerfall:** Wenn Logo-Format ungültig oder zu groß → Fehlermeldung mit erlaubten Formaten

---

### US-02: Mitglieder einladen

> *Als Admin möchte ich neue Mitglieder in meine Kapelle einladen, damit sie eine Beitrittsanfrage stellen und nach Genehmigung auf die Noten und Funktionen der Kapelle zugreifen können.*

**Kriterien (INVEST):**
- **I**ndependent: Läuft unabhängig von Noten-Import oder Setlist-Features
- **N**egotiable: SMS-Einladung ist Out of Scope; E-Mail + Linkteilen genügt für MS1
- **V**aluable: Ohne Einladungsflow kann keine Kapelle wachsen
- **E**stimatable: ~1.5 Sprints (inkl. E-Mail-Versand + Genehmigungs-Flow)
- **S**mall: Fokus auf Einladen + Beitrittsanfrage — Genehmigung ist US-06
- **T**estable: ✅ Eingeladene Person erhält E-Mail / besitzt gültigen Link → Beitrittsanfrage wird erstellt

**Wichtig:** Es gibt **keinen Auto-Join**. Jeder Beitritt erfordert eine Genehmigung durch berechtigte Personen (Admin, Dirigent oder Registerführer). Siehe US-06.

**Akzeptanzkriterien:**
1. Admin kann auf „+ Einladen" tippen (Mitglieder-Liste)
2. **Variante A — E-Mail-Einladung:** Admin gibt E-Mail-Adresse ein + wählt vorgeschlagene Rolle (Default: Musiker). Einladungs-E-Mail wird versendet. Der eingeladene Nutzer muss trotzdem genehmigt werden (**kein Auto-Join**).
3. **Variante B — Einladungslink:** Admin generiert einen Einladungslink. Jeder mit dem Link kann eine **Beitrittsanfrage** stellen (bis Ablauf oder Widerruf).
4. Einladungslinks sind standardmäßig **7 Tage** gültig; konfigurierbar durch Admin (1, 7, 14, 30 Tage oder „kein Ablauf")
5. Eingeladene Person mit bestehendem Account: Klickt auf Link/E-Mail → **Beitrittsanfrage** wird erstellt → Status „ausstehend"
6. Eingeladene Person ohne Account: Link führt zu Registrierungsseite → nach Registrierung wird automatisch eine **Beitrittsanfrage** für die Kapelle erstellt → Status „ausstehend"
7. **Mehrfach-Einladung:** Wenn eine E-Mail bereits Mitglied ist → Fehlermeldung „bereits Mitglied"
8. **Mehrfach-Einladung:** Wenn eine E-Mail bereits eine ausstehende Einladung hat → Fehlermeldung „Einladung bereits ausstehend" mit Option „Neue Einladung senden" (ersetzt die alte)
9. Admin kann ausstehende Einladungen in einer Liste sehen und einzeln widerrufen
10. Optionaler Einladungstext (max. 200 Zeichen) kann mitgesendet werden
11. **Mehrfach-Beitrittsanfrage:** Wenn der Nutzer bereits eine ausstehende Beitrittsanfrage hat → Fehlermeldung „Beitrittsanfrage bereits gestellt"
12. **Fehlerfall:** „Meine Musik"-Kapellen haben keinen Einladungsflow — Button „+ Einladen" ist nicht sichtbar

---

### US-03: Rollen zuweisen

> *Als Admin möchte ich Mitgliedern Rollen zuweisen, damit jede Person die für ihre Funktion passenden Berechtigungen hat.*

**Kriterien (INVEST):**
- **I**ndependent: Kann nach Einladungsannahme jederzeit geändert werden
- **N**egotiable: Custom-Rollen sind Out of Scope für MS1
- **V**aluable: Ohne Rollen gibt es keine Zugriffskontrolle
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Zuweisung — Berechtigungslogik ist in Auth implementiert
- **T**estable: ✅ Rollenwechsel wirkt sich sofort auf Berechtigungen aus

**Verfügbare Rollen:**

| Rolle | Beschreibung | Besonderheit |
|-------|-------------|-------------|
| **Admin** | Volle Kontrolle über die Kapelle | Mind. 1 Admin muss immer existieren |
| **Dirigent** | Musikalische Leitung | Kann Noten verwalten, Setlists erstellen, Termine anlegen |
| **Notenwart** | Pflegt Noten ein | Noten hochladen, Metadaten verwalten |
| **Registerführer** | Verantwortlich für ein Register | Kann Stimmen-Annotationen bearbeiten |
| **Musiker** | Standard-Mitglied | Noten ansehen, spielen, Termine zu-/absagen |

**Akzeptanzkriterien:**
1. Admin kann auf ✏️ neben einem Mitglied tippen → Rollen-Dialog öffnet sich
2. Ein Mitglied kann **mehrere Rollen gleichzeitig** haben (z.B. Dirigent + Admin)
3. Mindestens eine Rolle pro Mitglied ist Pflicht
4. Rollen sind **pro Kapelle** — derselbe Nutzer kann in Kapelle A Admin und in Kapelle B Musiker sein
5. Rollenzuweisung ist nur für Admins möglich
6. Admin kann eigene Admin-Rolle nur abgeben, wenn ein anderes Mitglied Admin ist (verhindert Admin-losen Zustand)
7. Änderungen treten sofort in Kraft — keine Session-Invalidierung erforderlich (nächste API-Anfrage nutzt neue Rolle)
8. **Fehlerfall:** Letzter Admin versucht, seine Admin-Rolle abzugeben → Fehlermeldung "Mindestens ein Admin muss in der Kapelle verbleiben. Ernenne zuerst einen anderen Admin."
9. Audit-Log-Eintrag bei jeder Rollenänderung (Wer hat wann welche Rolle geändert)

---

### US-04: Multi-Kapelle — Zwischen Kapellen wechseln

> *Als Musiker, der in mehreren Kapellen aktiv ist, möchte ich schnell zwischen meinen Kapellen wechseln, damit ich den richtigen Kontext für Noten, Setlists und Termine habe.*

**Kriterien (INVEST):**
- **I**ndependent: Kapellen sind isolierte Kontexte — kein Feature-Overlap
- **N**egotiable: "Alle Kapellen"-Gesamtansicht ist nicht in MS1
- **V**aluable: Kernversprechen von Sheetstorm als Multi-Kapellen-App
- **E**stimatable: ~0.5 Sprints (primär State-Management)
- **S**mall: Nur Kontextwechsel — kein Merge oder Cross-Kapellen-Feature
- **T**estable: ✅ Nach Wechsel zeigt die App nur Inhalte der neuen Kapelle

**Akzeptanzkriterien:**
1. Kapellen-Wechsel-Selector ist in der Hauptnavigation immer sichtbar (Top-Navigation auf Desktop/Tablet, Bottom-Navigation auf Phone)
2. Selector zeigt den Namen der aktuell aktiven Kapelle + Dropdown-Pfeil
3. Tap öffnet Liste aller Kapellen des Nutzers
4. Aktuell aktive Kapelle ist visuell markiert (✓ oder Highlight)
5. Liste enthält am Ende: "+ Kapelle beitreten", "+ Neue Kapelle erstellen"
6. Wechsel erfolgt sofort — alle angezeigten Inhalte (Bibliothek, Setlists, Termine) aktualisieren sich auf die neue Kapelle
7. **Einstiegsscreen nach Login:** Die Kapellen-/Band-Auswahl ist der Einstiegspunkt nach jedem Login — der Nutzer wählt „Meine Musik" oder eine Kapelle, dann sieht er alle Inhalte im Kontext dieser Auswahl. Letzter aktiver Kapellen-Kontext wird gespeichert (per Gerät).
8. „Meine Musik" erscheint immer als **erster Eintrag** im Kapellen-Wechsel-Selector — visuell unterscheidbar (eigenes Icon)
9. **Maximal-Kapellen:** Ein Nutzer kann Mitglied in bis zu 20 Kapellen sein (technische Grenze, konfigurierbar) — „Meine Musik" zählt nicht gegen dieses Limit
10. **Fehlerfall:** Wenn ein Nutzer aus einer Kapelle entfernt wurde und noch in deren Kontext ist → Redirect zur Kapellen-Auswahl mit Hinweis "Du bist nicht mehr Mitglied von [Kapellenname]"
11. **Ausnahme Kapellen-Auswahl:** Wenn der Nutzer nur Mitglied einer Kapelle + „Meine Musik" ist, kann direkt zur zuletzt aktiven Kapelle navigiert werden (kein Auswahl-Screen nötig)

---

### US-05: Instrument-Register verwalten

> *Als Admin oder Dirigent möchte ich die Instrument-Register meiner Kapelle definieren und pflegen, damit Musiker den richtigen Registern zugeordnet werden können.*

**Kriterien (INVEST):**
- **I**ndependent: Register-Struktur ist unabhängig von einzelnen Mitgliedern
- **N**egotiable: Vordefinierte Register-Vorlagen beschleunigen Setup — konfigurierbar
- **V**aluable: Register sind Grundlage für Stimmen-Zuordnung, Benachrichtigungen und Registerführer-Rolle
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Verwaltung der Register-Definition — Musiker-Zuweisung erfolgt im Mitgliederprofil
- **T**estable: ✅ Register kann erstellt, bearbeitet und gelöscht werden; Musiker können zugeordnet werden

**Standard-Register (Voreinstellung für Blaskapelle):**
- Flöte / Oboe
- Klarinetten (1., 2., 3.)
- Saxophone (Alt, Tenor, Bariton)
- Trompeten / Flügelhorn
- Hörner
- Tenorhorn / Euphonium
- Posaunen
- Tuba / Bässe
- Schlagwerk

**Akzeptanzkriterien:**
1. Admin/Dirigent kann unter Kapellen-Einstellungen → "Register" die Register-Liste verwalten
2. Register erstellen: Name (Pflicht, max. 50 Zeichen), Beschreibung (optional), Farbe (optional, für visuelle Unterscheidung)
3. Register bearbeiten: Name und Farbe können jederzeit geändert werden
4. Register löschen: Nur möglich wenn kein aktives Mitglied diesem Register zugeordnet ist; andernfalls Fehlermeldung mit Anzahl der betroffenen Mitglieder
5. Beim Erstellen einer Kapelle werden Standard-Blaskapellen-Register automatisch angelegt (überspringbar)
6. Reihenfolge der Register ist konfigurierbar (Drag & Drop in der Verwaltungsansicht)
7. Musiker können einem oder mehreren Registern zugeordnet werden (im Mitgliedsprofil)
8. Registerführer-Rolle bezieht sich immer auf ein spezifisches Register — bei Zuweisung muss das Register gewählt werden
9. **Fehlerfall:** Register löschen mit aktiven Mitgliedern → Fehlermeldung "Dieses Register hat noch X Mitglieder. Bitte weise sie zuerst anderen Registern zu."

---

### US-06: Beitrittsanfrage genehmigen / ablehnen

> *Als Admin, Dirigent oder Registerführer möchte ich Beitrittsanfragen von Musikern genehmigen oder ablehnen, damit ich kontrollieren kann, wer meiner Kapelle beitritt.*

**Kriterien (INVEST):**
- **I**ndependent: Setzt US-02 (Einladung) voraus, aber Genehmigungs-Flow ist eigenständig
- **N**egotiable: Auto-Approve für bestimmte Einladungen als spätere Erweiterung denkbar
- **V**aluable: Verhindert unkontrollierte Beitritte — Admin behält Kontrolle
- **E**stimatable: ~1 Sprint (inkl. Benachrichtigungen)
- **S**mall: Nur Genehmigung/Ablehnung — kein Einladungsflow (US-02)
- **T**estable: ✅ Beitrittsanfrage kann genehmigt/abgelehnt werden, Ergebnis ist sichtbar

**Akzeptanzkriterien:**
1. Berechtigte Personen (Admin, Dirigent, Registerführer) sehen eine Liste ausstehender Beitrittsanfragen
2. Jede Beitrittsanfrage zeigt: Name, E-Mail, Datum der Anfrage, vorgeschlagene Rolle (aus Einladung)
3. Berechtigte Person kann jede Anfrage **genehmigen** oder **ablehnen**
4. **Bei Genehmigung:** Neues Mitglied erscheint sofort in der Mitglieder-Liste mit der vorgeschlagenen Rolle (Default: Musiker)
5. **Bei Genehmigung:** Der Nutzer erhält eine Benachrichtigung „Du wurdest in [Kapellenname] aufgenommen"
6. **Bei Ablehnung:** Der Nutzer erhält eine Benachrichtigung „Deine Beitrittsanfrage für [Kapellenname] wurde abgelehnt"
7. **Bei Ablehnung:** Der Nutzer kann über einen **neuen** Einladungslink erneut eine Beitrittsanfrage stellen
8. Berechtigte Personen (Admin, Dirigent, Registerführer) erhalten eine **Benachrichtigung** wenn eine neue Beitrittsanfrage eingeht
9. Beitrittsanfragen haben drei Status: `ausstehend` → `genehmigt` | `abgelehnt`
10. **Fehlerfall:** Beitrittsanfrage genehmigen für Nutzer der bereits Mitglied ist → `409 Conflict` mit Meldung „Nutzer ist bereits Mitglied"
11. **Fehlerfall:** Beitrittsanfrage ablehnen die bereits bearbeitet wurde → `409 Conflict` mit Meldung „Diese Anfrage wurde bereits bearbeitet"
12. Audit-Log-Eintrag bei jeder Genehmigung/Ablehnung (Wer hat wann entschieden)

---

## 3. Akzeptanzkriterien (Feature-Level)

Diese Kriterien gelten übergreifend für das gesamte Kapellenverwaltungs-Feature:

| ID | Kriterium | Testbar durch |
|----|-----------|---------------|
| AC-01 | Kapelle erstellen dauert < 60 Sekunden (vom Tap bis Kapelle aktiv) | E2E-Test: Stopwatch |
| AC-02 | Einladungslink ist nach Ablauf-Datum ungültig | API-Test: Link nach Ablauf aufrufen → 410 Gone |
| AC-03 | Rollenwechsel wirkt sich spätestens beim nächsten API-Call aus (keine Cache-Stale) | Integration-Test |
| AC-04 | Kapellen-Wechsel < 500ms (State-Update, kein Netzwerk-Blocking) | Performance-Test |
| AC-05 | Jede Kapelle hat zu jedem Zeitpunkt mindestens einen Admin | DB-Constraint + Business-Logic-Test |
| AC-06 | Ein Nutzer kann nicht zweimal dieselbe Kapelle beitreten | DB-Unique-Constraint-Test |
| AC-07 | Multi-Kapellen-Kontext ist isoliert — Noten aus Kapelle A erscheinen nie in Kapelle B | Integration-Test: Cross-Kapellen-Leak |
| AC-08 | Alle sicherheitsrelevanten Aktionen werden im Audit-Log erfasst | DB-Test: Insert prüfen nach Admin-Aktionen |
| AC-09 | DSGVO: Nutzer kann beim Kapellenverlassen seine Mitgliedschaftsdaten exportieren | E2E-Test: Export vor Austritt |
| AC-10 | Wanda-UX-Flows aus `docs/ux-design.md` §3.5 und §4.3 sind vollständig implementiert | UX-Review durch Wanda (#14) |
| AC-11 | „Meine Musik" wird bei der Registrierung automatisch erstellt und ist sofort verfügbar | Integration-Test: Register → Check „Meine Musik" existiert |
| AC-12 | „Meine Musik" kann nicht gelöscht, verlassen oder geteilt werden | API-Test: DELETE/POST verlassen/einladen → 403 |
| AC-13 | Beitrittsanfrage erfordert Genehmigung — kein Auto-Join bei Einladungslink oder E-Mail-Einladung | E2E-Test: Link klicken → Anfrage ausstehend (nicht Mitglied) |
| AC-14 | Berechtigte Personen (Admin, Dirigent, Registerführer) werden über neue Beitrittsanfragen benachrichtigt | Integration-Test: Benachrichtigung nach Anfrage prüfen |
| AC-15 | Abgelehnte Nutzer können über neuen Einladungslink erneut anfragen | E2E-Test: Ablehnung → neuer Link → neue Anfrage |

---

## 4. API-Contract

**Base Path:** `/api/v1/kapellen`  
**Auth:** Bearer JWT (alle Endpunkte erfordern Authentifizierung)

### 4.1 Kapellen-CRUD

```
POST   /api/v1/kapellen                    → Kapelle erstellen
GET    /api/v1/kapellen                    → Alle Kapellen des aktuellen Nutzers
GET    /api/v1/kapellen/{id}               → Kapelle-Details
PUT    /api/v1/kapellen/{id}               → Kapelle aktualisieren (Admin)
DELETE /api/v1/kapellen/{id}               → Kapelle löschen (Admin, Soft-Delete)
POST   /api/v1/kapellen/{id}/logo          → Logo hochladen (multipart/form-data)
```

**POST /api/v1/kapellen — Request:**
```json
{
  "name": "Musikkapelle Beispiel",
  "beschreibung": "Gegründet 1923, 45 aktive Mitglieder.",
  "ort": "Musterstadt"
}
```

**POST /api/v1/kapellen — Response 201:**
```json
{
  "id": "uuid",
  "name": "Musikkapelle Beispiel",
  "beschreibung": "Gegründet 1923, 45 aktive Mitglieder.",
  "ort": "Musterstadt",
  "logo_url": null,
  "erstellt_am": "2026-03-28T12:00:00Z",
  "mitglieder_anzahl": 1,
  "meine_rollen": ["Admin"]
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (Name leer, zu lang, etc.)
- `403` — Nicht berechtigt (z.B. kein Admin bei PUT/DELETE)
- `404` — Kapelle nicht gefunden
- `409` — Konflikt (z.B. letzter Admin versucht Selbstlöschung)

---

### 4.2 Mitglieder-API

```
GET    /api/v1/kapellen/{id}/mitglieder              → Mitgliederliste
GET    /api/v1/kapellen/{id}/mitglieder/{musiker_id} → Mitglied-Details
PUT    /api/v1/kapellen/{id}/mitglieder/{musiker_id} → Mitglied aktualisieren (Admin)
DELETE /api/v1/kapellen/{id}/mitglieder/{musiker_id} → Mitglied entfernen (Admin)
POST   /api/v1/kapellen/{id}/verlassen               → Kapelle verlassen (eigener Account)
```

**GET /api/v1/kapellen/{id}/mitglieder — Response 200:**
```json
{
  "items": [
    {
      "musiker_id": "uuid",
      "name": "Anna Musterfrau",
      "email": "anna@example.com",
      "avatar_url": "https://...",
      "rollen": ["Musiker"],
      "register": ["Klarinetten"],
      "instrumente": ["Klarinette"],
      "standard_stimme": "2. Klarinette",
      "status": "aktiv",
      "beigetreten_am": "2026-01-15T10:00:00Z"
    }
  ],
  "gesamt": 45,
  "cursor": "eyJ..."
}
```

**PUT /api/v1/kapellen/{id}/mitglieder/{musiker_id} — Request (Admin):**
```json
{
  "rollen": ["Musiker", "Registerführer"],
  "register": ["Klarinetten"]
}
```

---

### 4.3 Rollen-API

```
GET    /api/v1/kapellen/{id}/rollen              → Verfügbare Rollen der Kapelle
PUT    /api/v1/kapellen/{id}/mitglieder/{musiker_id}/rollen → Rollen setzen (Admin)
```

**PUT Rollen — Request:**
```json
{
  "rollen": ["Dirigent", "Admin"]
}
```

**PUT Rollen — Response 200:**
```json
{
  "musiker_id": "uuid",
  "rollen": ["Dirigent", "Admin"],
  "geaendert_am": "2026-03-28T12:00:00Z",
  "geaendert_von": "uuid"
}
```

**Fehlercodes:**
- `409` — Letzter Admin-Versuch seine Admin-Rolle abzugeben

---

### 4.4 Einladungs- & Beitrittsanfrage-API

```
POST   /api/v1/kapellen/{id}/einladungen                        → Einladung erstellen (Admin)
GET    /api/v1/kapellen/{id}/einladungen                        → Ausstehende Einladungen (Admin)
DELETE /api/v1/kapellen/{id}/einladungen/{einladung_id}         → Einladung widerrufen (Admin)
GET    /api/v1/einladungen/{token}                              → Einladungsdetails (öffentlich, für Beitrittsseite)
POST   /api/v1/einladungen/{token}/beitrittsanfrage             → Beitrittsanfrage stellen (eingeloggter User)
GET    /api/v1/kapellen/{id}/beitrittsanfragen                  → Ausstehende Beitrittsanfragen (Admin/Dirigent/Registerführer)
PUT    /api/v1/kapellen/{id}/beitrittsanfragen/{anfrage_id}     → Genehmigen/Ablehnen (Admin/Dirigent/Registerführer)
```

**POST /api/v1/kapellen/{id}/einladungen — Request:**
```json
{
  "typ": "email",
  "email": "neu@example.com",
  "vorgeschlagene_rolle": "Musiker",
  "ablauf_tage": 7,
  "nachricht": "Herzlich willkommen bei unserer Kapelle!"
}
```

*Für Link-Einladung: `typ: "link"`, kein `email`-Feld erforderlich.*

**POST /api/v1/kapellen/{id}/einladungen — Response 201:**
```json
{
  "id": "uuid",
  "typ": "link",
  "token": "abc123xyz...",
  "link": "https://app.sheetstorm.com/einladung/abc123xyz",
  "vorgeschlagene_rolle": "Musiker",
  "ablauf_am": "2026-04-04T12:00:00Z",
  "erstellt_am": "2026-03-28T12:00:00Z",
  "status": "ausstehend"
}
```

**POST /api/v1/einladungen/{token}/beitrittsanfrage — Request:**
```json
{
  "nachricht": "Ich spiele 2. Klarinette und möchte gerne beitreten."
}
```

*Das `nachricht`-Feld ist optional (max. 500 Zeichen).*

**POST /api/v1/einladungen/{token}/beitrittsanfrage — Response 201:**
```json
{
  "id": "uuid",
  "kapelle_id": "uuid",
  "kapelle_name": "Musikkapelle Beispiel",
  "vorgeschlagene_rolle": "Musiker",
  "status": "ausstehend",
  "erstellt_am": "2026-03-28T14:00:00Z"
}
```

**GET /api/v1/kapellen/{id}/beitrittsanfragen — Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "musiker_id": "uuid",
      "name": "Max Mustermann",
      "email": "max@example.com",
      "vorgeschlagene_rolle": "Musiker",
      "nachricht": "Ich spiele 2. Klarinette und möchte gerne beitreten.",
      "einladung_id": "uuid",
      "status": "ausstehend",
      "erstellt_am": "2026-03-28T14:00:00Z"
    }
  ],
  "gesamt": 3
}
```

**PUT /api/v1/kapellen/{id}/beitrittsanfragen/{anfrage_id} — Request:**
```json
{
  "entscheidung": "genehmigt",
  "rolle": "Musiker",
  "begruendung": "Willkommen!"
}
```

*Mögliche Werte für `entscheidung`: `genehmigt`, `abgelehnt`. Das Feld `rolle` erlaubt es, die endgültige Rolle bei Genehmigung anzupassen (Default: vorgeschlagene Rolle aus Einladung). `begruendung` ist optional (max. 500 Zeichen).*

**PUT — Response 200 (Genehmigung):**
```json
{
  "id": "uuid",
  "status": "genehmigt",
  "entschieden_von": "uuid",
  "entschieden_am": "2026-03-28T15:00:00Z",
  "mitgliedschaft_id": "uuid"
}
```

**PUT — Response 200 (Ablehnung):**
```json
{
  "id": "uuid",
  "status": "abgelehnt",
  "entschieden_von": "uuid",
  "entschieden_am": "2026-03-28T15:00:00Z",
  "begruendung": "Leider kein Platz im Register."
}
```

**Fehlercodes:**
- `403` — Nicht berechtigt (kein Admin/Dirigent/Registerführer) oder „Meine Musik"-Kapelle
- `404` — Beitrittsanfrage nicht gefunden
- `409` — E-Mail bereits Mitglied, ausstehende Einladung, ausstehende Beitrittsanfrage, oder Anfrage bereits bearbeitet
- `410` — Einladungslink abgelaufen

---

### 4.5 Register-API

```
GET    /api/v1/kapellen/{id}/register              → Registerliste
POST   /api/v1/kapellen/{id}/register              → Register erstellen (Admin/Dirigent)
PUT    /api/v1/kapellen/{id}/register/{register_id} → Register aktualisieren
DELETE /api/v1/kapellen/{id}/register/{register_id} → Register löschen
PUT    /api/v1/kapellen/{id}/register/reihenfolge  → Reihenfolge ändern
```

**POST Register — Request:**
```json
{
  "name": "Klarinetten",
  "beschreibung": "1., 2. und 3. Klarinette sowie Es-Klarinette",
  "farbe": "#4A90D9",
  "sortierung": 3
}
```

---

## 5. Datenmodell

### 5.1 Kapelle

```sql
CREATE TABLE kapellen (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(80)  NOT NULL,
    beschreibung    VARCHAR(500),
    ort             VARCHAR(100),
    logo_url        TEXT,
    ist_persoenlich BOOLEAN      NOT NULL DEFAULT FALSE,  -- TRUE für "Meine Musik"
    erstellt_am     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    geloescht_am    TIMESTAMPTZ,          -- Soft-Delete (nicht möglich bei ist_persoenlich = TRUE)
    erstellt_von    UUID         NOT NULL REFERENCES musiker(id)
);

CREATE INDEX idx_kapellen_name ON kapellen(name) WHERE geloescht_am IS NULL;

-- Nur eine "Meine Musik"-Kapelle pro Nutzer
CREATE UNIQUE INDEX idx_kapellen_persoenlich ON kapellen(erstellt_von) WHERE ist_persoenlich = TRUE AND geloescht_am IS NULL;
```

### 5.2 Mitgliedschaft

```sql
CREATE TABLE mitgliedschaften (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    musiker_id      UUID         NOT NULL REFERENCES musiker(id)  ON DELETE CASCADE,
    status          VARCHAR(20)  NOT NULL DEFAULT 'aktiv',  -- aktiv | inaktiv | entfernt
    beigetreten_am  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    standard_stimme VARCHAR(100),
    UNIQUE (kapelle_id, musiker_id)
);

CREATE INDEX idx_mitgliedschaft_musiker   ON mitgliedschaften(musiker_id) WHERE status = 'aktiv';
CREATE INDEX idx_mitgliedschaft_kapelle   ON mitgliedschaften(kapelle_id) WHERE status = 'aktiv';
```

### 5.3 Rolle

```sql
CREATE TYPE kapellen_rolle AS ENUM (
    'Admin', 'Dirigent', 'Notenwart', 'Registerführer', 'Musiker'
);

CREATE TABLE mitgliedschaft_rollen (
    mitgliedschaft_id   UUID            NOT NULL REFERENCES mitgliedschaften(id) ON DELETE CASCADE,
    rolle               kapellen_rolle  NOT NULL,
    zugewiesen_am       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    zugewiesen_von      UUID            REFERENCES musiker(id),
    PRIMARY KEY (mitgliedschaft_id, rolle)
);
```

### 5.4 Einladung & Beitrittsanfrage

```sql
CREATE TYPE einladung_typ    AS ENUM ('email', 'link');
CREATE TYPE einladung_status AS ENUM ('ausstehend', 'verwendet', 'widerrufen', 'abgelaufen');

CREATE TABLE einladungen (
    id                   UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id           UUID                NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    typ                  einladung_typ       NOT NULL,
    token                VARCHAR(64)         NOT NULL UNIQUE,  -- kryptographisch sicher, 256-bit
    email                VARCHAR(255),                        -- nur bei typ = 'email'
    vorgeschlagene_rolle kapellen_rolle      NOT NULL DEFAULT 'Musiker',
    nachricht            VARCHAR(200),
    ablauf_am            TIMESTAMPTZ         NOT NULL,
    erstellt_am          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    erstellt_von         UUID                NOT NULL REFERENCES musiker(id),
    status               einladung_status    NOT NULL DEFAULT 'ausstehend'
);

CREATE INDEX idx_einladungen_token     ON einladungen(token) WHERE status = 'ausstehend';
CREATE INDEX idx_einladungen_kapelle   ON einladungen(kapelle_id) WHERE status = 'ausstehend';
CREATE INDEX idx_einladungen_email     ON einladungen(email, kapelle_id) WHERE status = 'ausstehend';
```

> **Hinweis:** Die Einladung enthält kein `angenommen_von`/`angenommen_am` mehr — das Annehmen einer Einladung erstellt jetzt eine **Beitrittsanfrage**, die separat genehmigt werden muss. Bei E-Mail-Einladungen wechselt der Status zu `verwendet` sobald der Nutzer eine Beitrittsanfrage stellt. Bei Link-Einladungen bleibt der Status `ausstehend` (mehrere Nutzer können über denselben Link anfragen).

```sql
CREATE TYPE beitrittsanfrage_status AS ENUM ('ausstehend', 'genehmigt', 'abgelehnt', 'zurueckgezogen');

CREATE TABLE beitrittsanfragen (
    id                   UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id           UUID                        NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    musiker_id           UUID                        NOT NULL REFERENCES musiker(id)  ON DELETE CASCADE,
    einladung_id         UUID                        REFERENCES einladungen(id),
    vorgeschlagene_rolle kapellen_rolle              NOT NULL DEFAULT 'Musiker',
    nachricht            VARCHAR(500),
    status               beitrittsanfrage_status     NOT NULL DEFAULT 'ausstehend',
    entschieden_von      UUID                        REFERENCES musiker(id),
    entschieden_am       TIMESTAMPTZ,
    begruendung          VARCHAR(500),
    erstellt_am          TIMESTAMPTZ                 NOT NULL DEFAULT NOW()
);

-- Nur eine ausstehende Anfrage pro Kapelle/Nutzer
CREATE UNIQUE INDEX idx_beitrittsanfragen_unique_ausstehend
    ON beitrittsanfragen(kapelle_id, musiker_id)
    WHERE status = 'ausstehend';

CREATE INDEX idx_beitrittsanfragen_kapelle ON beitrittsanfragen(kapelle_id) WHERE status = 'ausstehend';
CREATE INDEX idx_beitrittsanfragen_musiker ON beitrittsanfragen(musiker_id) WHERE status = 'ausstehend';
```

### 5.5 Register

```sql
CREATE TABLE register (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID        NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    name            VARCHAR(50) NOT NULL,
    beschreibung    VARCHAR(200),
    farbe           CHAR(7),    -- Hex-Farbe, z.B. #4A90D9
    sortierung      INTEGER     NOT NULL DEFAULT 0,
    erstellt_am     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (kapelle_id, name)
);

CREATE TABLE mitgliedschaft_register (
    mitgliedschaft_id   UUID NOT NULL REFERENCES mitgliedschaften(id)  ON DELETE CASCADE,
    register_id         UUID NOT NULL REFERENCES register(id)           ON DELETE RESTRICT,
    PRIMARY KEY (mitgliedschaft_id, register_id)
);
```

### 5.6 Audit-Log

```sql
CREATE TABLE audit_log (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id  UUID        REFERENCES kapellen(id),
    musiker_id  UUID        REFERENCES musiker(id),
    aktion      VARCHAR(100) NOT NULL,  -- z.B. 'rolle.zugewiesen', 'mitglied.entfernt'
    entitaet    VARCHAR(50)  NOT NULL,  -- z.B. 'Mitgliedschaft', 'Einladung'
    entitaet_id UUID,
    details     JSONB,
    zeitstempel TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_kapelle   ON audit_log(kapelle_id, zeitstempel DESC);
CREATE INDEX idx_audit_musiker   ON audit_log(musiker_id, zeitstempel DESC);
```

---

## 6. Berechtigungsmatrix

> **Prinzip:** RBAC pro Kapelle. Server-side Enforcement für alle Aktionen. Das Frontend blendet Elemente aus — aber der Server validiert jeden Request unabhängig.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|
| **Kapelle** | | | | | |
| Kapelle erstellen | ✅ (jeder) | ✅ (jeder) | ✅ (jeder) | ✅ (jeder) | ✅ (jeder) |
| Kapelle-Info bearbeiten (Name, Beschreibung) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Logo hochladen/ändern | ✅ | ❌ | ❌ | ❌ | ❌ |
| Kapelle löschen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Kapellen-Dashboard sehen | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Mitglieder** | | | | | |
| Mitglieder einladen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Einladungen widerrufen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Mitglied entfernen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Mitgliederliste sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Eigenes Profil bearbeiten | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kapelle verlassen | ✅¹ | ✅ | ✅ | ✅ | ✅ |
| **Beitrittsanfragen** | | | | | |
| Beitrittsanfragen sehen | ✅ | ✅ | ❌ | ✅ | ❌ |
| Beitrittsanfrage genehmigen | ✅ | ✅ | ❌ | ✅ | ❌ |
| Beitrittsanfrage ablehnen | ✅ | ✅ | ❌ | ✅ | ❌ |
| **Rollen** | | | | | |
| Rollen zuweisen/ändern | ✅ | ❌ | ❌ | ❌ | ❌ |
| Eigene Rollen sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Register** | | | | | |
| Register erstellen/bearbeiten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Register löschen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Registerliste sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Musiker Register zuordnen | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Audit-Log** | | | | | |
| Audit-Log lesen | ✅ | ❌ | ❌ | ❌ | ❌ |

> ¹ Admin kann Kapelle nur verlassen, wenn ein anderer Admin existiert.

---

## 7. Edge Cases

### 7.1 Letzter Admin verlässt die Kapelle

**Szenario:** Eine Kapelle hat genau einen Admin. Dieser Admin versucht, die Kapelle zu verlassen (oder seine Admin-Rolle abzugeben, oder seinen Account zu löschen).

**Verhalten:**
- `POST /api/v1/kapellen/{id}/verlassen` → `409 Conflict`
- Response: `{ "fehler": "LETZTER_ADMIN", "nachricht": "Du bist der einzige Admin. Ernenne zuerst ein anderes Mitglied zum Admin, bevor du die Kapelle verlässt." }`
- Frontend zeigt Dialog mit Erklärung und direktem Link zur Rollenverwaltung
- **Kein Auto-Promote:** Das System ernennt nicht automatisch das dienstälteste Mitglied zum Admin — das würde ohne Wissen des Nutzers geschehen

**Account-Löschung:** Wenn der letzte Admin seinen gesamten Account löscht → die Kapelle wird in den Status "verwaist" (`status: 'verwaist'`) gesetzt. Eine verwaiste Kapelle ist nach 90 Tagen zur Löschung vorgesehen. In dieser Zeit können verbliebene Mitglieder (Dirigent, Notenwart) einen neuen Admin per Support-Prozess beantragen.

---

### 7.2 Doppelte Einladung

**Szenario A: E-Mail bereits Mitglied**
- `POST /api/v1/kapellen/{id}/einladungen` mit E-Mail eines bestehenden Mitglieds
- Response: `409 Conflict` — `{ "fehler": "BEREITS_MITGLIED" }`

**Szenario B: E-Mail hat ausstehende Einladung**
- Response: `409 Conflict` — `{ "fehler": "EINLADUNG_AUSSTEHEND", "einladung_id": "uuid", "ablauf_am": "..." }`
- Admin kann die bestehende Einladung widerrufen und eine neue senden — das geschieht nie automatisch
- Frontend zeigt Dialog: "Eine Einladung ist bereits ausstehend (läuft ab am DD.MM.YYYY). Möchtest du sie durch eine neue ersetzen?"

**Szenario C: Nutzer versucht, über zwei Links derselben Kapelle eine Beitrittsanfrage zu stellen**
- Beim zweiten Versuch: `409 Conflict` — `{ "fehler": "ANFRAGE_AUSSTEHEND" }`
- Wenn bereits Mitglied: `409 Conflict` — `{ "fehler": "BEREITS_MITGLIED" }`
- Kein zweifacher Eintrag in `beitrittsanfragen` oder `mitgliedschaften`

---

### 7.3 Kapelle verlassen mit offenen Abhängigkeiten

**Szenario: Musiker verlässt Kapelle mit zugewiesenen Annotationen oder Aushilfe-Links**
- Verlassen ist erlaubt — persönliche (private) Annotationen werden gelöscht
- Stimmen-/Orchester-Annotationen des Nutzers bleiben bestehen (wurden für die Kapelle erstellt)
- Aktive Aushilfe-Links des Nutzers werden beim Verlassen automatisch widerrufen
- Setlist-Einträge, die der Nutzer erstellt hat, bleiben der Kapelle erhalten (Ownership geht an Admin über)

---

### 7.4 Abgelaufene Einladung

**Szenario:** Nutzer klickt auf Einladungslink nach Ablauf
- `GET /api/v1/einladungen/{token}` → `410 Gone`
- Frontend zeigt: "Diese Einladung ist abgelaufen. Bitte bitte einen Admin von [Kapellenname], dir eine neue Einladung zu senden."
- Abgelaufene Einladungen werden nicht automatisch erneuert

---

### 7.5 Mitglied wird entfernt, während es aktiv in der App ist

**Szenario:** Admin entfernt Mitglied B. Mitglied B ist gerade online und navigiert in der App.
- Beim nächsten API-Call von Mitglied B für diese Kapelle → `403 Forbidden` mit `{ "fehler": "NICHT_MITGLIED" }`
- Client-seitig: App erkennt den 403-Status und zeigt Hinweis "Du wurdest aus der Kapelle [Kapellenname] entfernt." und navigiert zur Kapellen-Auswahl
- Lokale Offline-Daten (heruntergeladene Noten) bleiben bis zum nächsten Sync bestehen — kein Hard-Delete vom Gerät

---

### 7.6 Register löschen mit aktiven Mitgliedern

**Szenario:** Admin versucht, Register "Klarinetten" zu löschen, dem 12 Mitglieder zugeordnet sind.
- `DELETE /api/v1/kapellen/{id}/register/{register_id}` → `409 Conflict`
- Response: `{ "fehler": "REGISTER_BELEGT", "mitglieder_anzahl": 12 }`
- Frontend: "Dieses Register hat noch 12 Mitglieder. Bitte weise sie zuerst anderen Registern zu."
- Der Admin muss die 12 Mitglieder manuell umbuchen — kein Auto-Reassign

---

### 7.7 Kapelle mit 0 Mitgliedern (nach Massenentfernung)

**Szenario:** Alle Mitglieder bis auf den letzten Admin verlassen die Kapelle.
- Kapelle bleibt bestehen — ein Admin ist ausreichend
- Kapelle mit 0 Mitgliedern (Admin hat sich selbst entfernt — nicht möglich, da AC-05)
- Dieser Fall ist durch den "Letzter-Admin"-Guard (Edge Case 7.1) ausgeschlossen

---

### 7.8 Token-Kollision bei Einladungslinks

**Szenario:** Zwei Einladungslinks haben denselben Token (extrem unwahrscheinlich bei 256-bit, aber abgedeckt).
- DB-Constraint: `UNIQUE (token)` auf `einladungen`
- Server generiert bei Kollision neu (max. 3 Versuche, danach 500 mit Alarm)
- Nicht frontend-sichtbar — reiner Server-Retry

---

### 7.9 „Meine Musik" — Schutz vor Manipulation

**Szenario A: Nutzer versucht „Meine Musik" zu löschen**
- `DELETE /api/v1/kapellen/{id}` → `403 Forbidden`
- Response: `{ "fehler": "PERSOENLICHE_BIBLIOTHEK", "nachricht": "Die persönliche Bibliothek kann nicht gelöscht werden." }`

**Szenario B: Nutzer versucht „Meine Musik" zu verlassen**
- `POST /api/v1/kapellen/{id}/verlassen` → `403 Forbidden`
- Response: `{ "fehler": "PERSOENLICHE_BIBLIOTHEK", "nachricht": "Die persönliche Bibliothek kann nicht verlassen werden." }`

**Szenario C: Nutzer versucht jemanden in „Meine Musik" einzuladen**
- `POST /api/v1/kapellen/{id}/einladungen` → `403 Forbidden`
- Response: `{ "fehler": "PERSOENLICHE_BIBLIOTHEK", "nachricht": "In die persönliche Bibliothek können keine Mitglieder eingeladen werden." }`

**Szenario D: Nutzer versucht seine Admin-Rolle in „Meine Musik" abzugeben**
- `PUT /api/v1/kapellen/{id}/mitglieder/{musiker_id}/rollen` → `403 Forbidden`
- Rollen in „Meine Musik" sind nicht änderbar

---

### 7.10 Beitrittsanfrage nach Ablehnung

**Szenario:** Nutzer wurde abgelehnt und möchte erneut anfragen.
- Der abgelehnte Nutzer kann über einen **neuen** Einladungslink eine neue Beitrittsanfrage stellen
- Der alte Einladungslink funktioniert nicht erneut für denselben Nutzer (Anfrage existiert bereits als „abgelehnt" für diesen Link)
- Bei neuem Link: Neue Beitrittsanfrage wird erstellt (neue ID, neuer Status „ausstehend")
- Admin/Dirigent/Registerführer sieht die Historie der Anfragen

---

### 7.11 Doppelte Beitrittsanfrage

**Szenario:** Nutzer stellt eine Beitrittsanfrage, obwohl bereits eine ausstehende Anfrage existiert.
- `POST /api/v1/einladungen/{token}/beitrittsanfrage` → `409 Conflict`
- Response: `{ "fehler": "ANFRAGE_AUSSTEHEND", "nachricht": "Du hast bereits eine ausstehende Beitrittsanfrage für diese Kapelle." }`
- Frontend zeigt Hinweis mit Status der bestehenden Anfrage

---

### 7.12 Gleichzeitige Genehmigung durch mehrere Berechtigte

**Szenario:** Admin und Dirigent versuchen gleichzeitig, dieselbe Beitrittsanfrage zu genehmigen.
- Optimistic Locking: Erster Request gewinnt, zweiter erhält `409 Conflict`
- Response: `{ "fehler": "ANFRAGE_BEREITS_BEARBEITET", "nachricht": "Diese Anfrage wurde bereits bearbeitet." }`
- Kein doppelter Eintrag in `mitgliedschaften`

---

### 7.13 Beitrittsanfrage bei Account-Löschung

**Szenario:** Nutzer löscht seinen Account, während eine Beitrittsanfrage aussteht.
- Ausstehende Beitrittsanfragen werden automatisch auf Status „zurueckgezogen" gesetzt (ON DELETE CASCADE auf `musiker_id` oder Application-Logic)
- Admins sehen die Anfrage nicht mehr in der aktiven Liste

---

## 8. Definition of Done

Eine Kapellenverwaltungs-Implementierung gilt als **Done**, wenn alle folgenden Kriterien erfüllt sind:

### Funktional
- [ ] Alle 7 User Stories (US-00 bis US-06) vollständig implementiert
- [ ] Alle Akzeptanzkriterien (AC-01 bis AC-15) durch Tests abgedeckt
- [ ] Alle Edge Cases (7.1–7.13) implementiert und getestet
- [ ] API-Contract vollständig implementiert (alle Endpunkte aus §4)
- [ ] Berechtigungsmatrix (§6) server-seitig durchgesetzt

### Qualität
- [ ] Unit-Test-Coverage ≥ 80% für Kapellenverwaltungs-Logik
- [ ] Integration-Tests für alle API-Endpunkte (Happypath + Fehlerfälle)
- [ ] E2E-Test für vollständigen Flow: Erstellen → Einladen → Beitrittsanfrage → Genehmigung → Rolle zuweisen → Wechseln
- [ ] E2E-Test: „Meine Musik" wird bei Registrierung erstellt und ist sofort nutzbar
- [ ] E2E-Test: Beitrittsanfrage ablehnen → Nutzer kann über neuen Link erneut anfragen
- [ ] Performance: Kapellen-Wechsel < 500ms (gemessen in Staging)
- [ ] Performance: Mitglieder-Liste mit 100 Mitgliedern in < 200ms (API 95. Pz.)
- [ ] Keine bekannten Security-Issues (OWASP Top 10 geprüft)

### UX / Design
- [ ] UX-Review durch Wanda bestätigt, dass Flows mit `docs/ux-design.md` §3.5 übereinstimmen
- [ ] Touch-Targets ≥ 44×44 px (Pflicht), ≥ 64×64 px im Kapellen-Wechsel-Selector
- [ ] Fehlermeldungen sind verständlich und handlungsleitend (kein technischer Jargon)
- [ ] WCAG 2.1 AA: Farbe ist nie alleiniger Indikator (Rollen z.B. immer Text + Farbe)
- [ ] Kapellen-Wechsel funktioniert auch wenn Nutzer nur Mitglied einer Kapelle ist
- [ ] Kapellen-Auswahl als Einstiegsscreen nach Login funktioniert korrekt (inkl. Ausnahme bei nur einer Kapelle + „Meine Musik")

### Technisch
- [ ] Audit-Log für alle Admin-Aktionen (Rollenzuweisung, Einladung, Entfernung)
- [ ] Soft-Delete für Kapellen (kein Hard-Delete)
- [ ] DB-Migrations erstellt und getestet
- [ ] API-Dokumentation (OpenAPI/Swagger) aktuell
- [ ] DSGVO-konform: Nutzer-Datenlöschung entfernt Mitgliedschaft-Records, aber nicht Kapellen-Audit-Log-Einträge (geschwärzt als "Gelöschter Nutzer")

### Deployment
- [ ] Feature-Flag vorhanden (Rollout steuerbar)
- [ ] Monitoring-Alerts für kritische Pfade (Einladungs-E-Mail-Fehler, Token-Kollision)
- [ ] Changelog-Eintrag erstellt

---

*Erstellt von Hill (Product Manager) · Sheetstorm MS1 · Issue #15*
