# Feature-Spezifikation: Konzertplanung + Kalender

> **Issue:** #TBD (MS2)  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2025-01-22  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** Kapellenverwaltung (#15), Setlist-Feature (MS2), Push-Notification-Infrastruktur (MS2)  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD — `docs/ux-specs/konzertplanung.md` (Wanda)

---

## 1. Feature-Überblick

Die **Konzertplanung + Kalender** ist das organisatorische Rückgrat für Proben, Auftritte und Veranstaltungen. Sie ermöglicht Dirigenten und Admins, Termine zu erstellen, verknüpft diese mit Setlists, und bietet Musikern ein einfaches Zu-/Absage-System mit intelligentem Ersatzmusiker-Vorschlag. Der integrierte Kalender synchronisiert bidirektional mit Google Calendar, Apple Calendar und Outlook.

### 1.1 Ziel

Ein Dirigent soll Termine für Proben und Konzerte erstellen können — mit Datum, Uhrzeit, Ort und verknüpfter Setlist. Musiker sagen zu oder ab, optional mit Begründung. Bei Absagen schlägt das System automatisch Ersatzmusiker vor. Der Kalender zeigt alle Termine übersichtlich an und synchronisiert sich automatisch mit externen Kalendern der Musiker.

**Kernversprechen:** Keine Spreadsheets, keine WhatsApp-Gruppen, keine verlorenen Zusagen — alles in einer App.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Termine erstellen (Datum, Uhrzeit, Ort, Typ, Setlist) | Anwesenheitsstatistiken / Auswertungen |
| Zu-/Absage-System mit optionaler Begründung | Automatische Terminvorschläge (AI) |
| Übersicht: Zugesagt / Offen / Abgesagt | Konflikte mit anderen Kapellen |
| Ersatzmusiker-Vorschlag bei Absage | Raumbuchung / Ressourcenverwaltung |
| Push-Benachrichtigungen / Erinnerungen | Wetter-Integration für Outdoor-Events |
| Kalender: Monats-/Wochen-/Listenansicht | Ticket-Verkauf / Event-Management |
| Filter nach Kapelle | Social-Sharing (Facebook, Instagram) |
| Termin-Details mit Setlist | Catering / Verpflegungsplanung |
| Bidirektionale Kalender-Sync (Google, Apple, Outlook) | Automatische Routenplanung |
| Erinnerungen (1 Tag, 1 Stunde vor Termin) | Setlist-Änderungsbenachrichtigung |

### 1.3 Kontext & Marktdifferenzierung

**Alleinstellungsmerkmal:** Keine App auf dem Markt bietet **intelligente Ersatzmusiker-Vorschläge** basierend auf Instrumentenprofil + Verfügbarkeit. Wettbewerber (BAND, Doodle, Google Calendar) zeigen nur statische Verfügbarkeiten — ohne musikalischen Kontext.

**Kalender-Sync:** Sheetstorm synchronisiert **bidirektional** — Änderungen in Google/Apple/Outlook werden zurück übertragen. Wettbewerber bieten nur einseitigen Export.

**Setlist-Verknüpfung:** Konzerte sind direkt mit Setlists verknüpft — Musiker sehen beim Zusagen sofort, welche Stücke gespielt werden.

---

## 2. User Stories

### US-01: Termin erstellen

> *Als Dirigent möchte ich einen Termin für eine Probe oder ein Konzert erstellen, damit alle Mitglieder informiert sind und zusagen können.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert nur Kapellen-Kontext, keine externen Abhängigkeiten
- **N**egotiable: Setlist-Verknüpfung ist optional für Proben
- **V**aluable: Ohne Termine keine Planung möglich
- **E**stimatable: ~1.5 Sprints (inkl. Push-Benachrichtigungen)
- **S**mall: Fokus auf Erstellung — Zusage-Flow ist separate Concern
- **T**estable: ✅ Termin existiert in DB, Musiker erhalten Benachrichtigung

**Akzeptanzkriterien:**
1. Dirigent/Admin kann auf "+ Termin erstellen" tippen (Kalender-Tab)
2. **Pflichtfelder:** Titel (1–100 Zeichen), Datum, Uhrzeit (Start), Typ (Probe | Konzert | Sonstiges)
3. **Optionale Felder:** Enduhrzeit, Ort (max. 200 Zeichen), Setlist (Dropdown mit allen Setlists der Kapelle), Beschreibung (max. 1000 Zeichen), Treffpunkt (abweichend vom Ort), Kleiderordnung
4. **Termin-Typ:** Probe, Konzert, Auftritt, Ausflug, Sonstiges (freies Textfeld)
5. Nach Erstellen: Alle aktiven Mitglieder der Kapelle erhalten eine **Push-Benachrichtigung** + In-App-Notification
6. Termin erscheint sofort im Kalender aller Mitglieder
7. Standard-Teilnahmestatus für alle Mitglieder: **"Offen"** (nicht zugesagt, nicht abgesagt)
8. **Wiederkehrende Termine:** Admin kann "Wöchentlich wiederholen" aktivieren (für Proben) — erstellt automatisch Termine für die nächsten 12 Wochen
9. **Fehlerfall:** Wenn Startzeit nach Endzeit liegt → Validierungsfehler
10. **Fehlerfall:** Wenn Datum in der Vergangenheit liegt → Warnung, aber erlaubt (für Nacherfassung)
11. **Fehlerfall:** Wenn Setlist verknüpft ist, aber keine Stücke enthält → Warnung "Setlist ist leer"

**Business Rules:**
- Nur Dirigent oder Admin kann Termine erstellen
- Termine sind kapellen-spezifisch — kein Cross-Kapellen-Termin
- Setlist-Verknüpfung ist optional, aber empfohlen für Konzerte
- Termine ohne Setlist zeigen Warnung: "Keine Setlist verknüpft — Musiker wissen nicht, welche Noten sie vorbereiten sollen"

---

### US-02: Zu-/Absage-System

> *Als Musiker möchte ich schnell zu- oder absagen, damit der Dirigent weiß, wer beim Termin dabei ist.*

**Kriterien (INVEST):**
- **I**ndependent: Läuft unabhängig von Ersatzmusiker-Logik
- **N**egotiable: Begründung ist optional
- **V**aluable: Ohne Zusagen keine Planungssicherheit
- **E**stimatable: ~1 Sprint
- **S**small: Nur Zusage-Flow — Ersatzmusiker-Vorschlag ist separate Concern
- **T**estable: ✅ Status-Änderung wird persistiert, Dirigent erhält Update

**Akzeptanzkriterien:**
1. Musiker tippt auf Termin → Detail-Ansicht öffnet sich
2. Drei Buttons: **"Zusagen"**, **"Absagen"**, **"Vielleicht"**
3. Bei **Zusage:** Status wechselt auf "Zugesagt" (grüner Haken), keine weitere Eingabe erforderlich
4. Bei **Absage:** Optional Begründung eingeben (max. 200 Zeichen, z.B. "Urlaub", "Krank", "Beruflich verhindert")
5. Bei **"Vielleicht":** Status "Unsicher" — zählt **nicht** als Zusage für die Besetzungsplanung
6. Status-Änderung ist jederzeit möglich (Musiker kann Zusage in Absage ändern)
7. **Benachrichtigung:** Dirigent + Admin erhalten Push-Notification bei jeder Status-Änderung (zusammengefasst alle 30 Minuten, nicht bei jeder einzelnen Änderung)
8. **Frist:** Dirigent kann optionale **Zusage-Frist** setzen (z.B. "Bitte bis 1 Woche vor Termin zusagen") — nach Ablauf der Frist erhalten alle Offene/Unsichere Mitglieder eine Erinnerung
9. **Fehlerfall:** Wenn Termin in < 2 Stunden beginnt und Musiker sagt ab → Warnung "Kurzfristige Absage — bitte kontaktiere den Dirigenten direkt"
10. Musiker sehen in der Termin-Detailansicht die **Gesamtübersicht:** "12 zugesagt, 2 abgesagt, 3 offen"

**Status-Übersicht:**
| Status | Bedeutung | Icon | Farbe |
|--------|-----------|------|-------|
| Offen | Noch keine Antwort | ○ | Grau |
| Zugesagt | Nimmt teil | ✓ | Grün |
| Abgesagt | Nimmt nicht teil | ✗ | Rot |
| Unsicher | Vielleicht | ? | Orange |

---

### US-03: Ersatzmusiker-Vorschlag bei Absage

> *Als Dirigent möchte ich bei Absagen automatisch Ersatzmusiker vorgeschlagen bekommen, damit ich schnell reagieren kann.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt bestehende Musiker-/Register-Daten
- **N**egotiable: Ranking-Algorithmus kann in MS3 verfeinert werden
- **V**aluable: Kernversprechen — keine andere App bietet diese Intelligenz
- **E**stimatable: ~1.5 Sprints
- **S**mall: Nur Vorschlag — Kontaktaufnahme ist separate Concern
- **T**estable: ✅ Bei Absage werden Ersatzmusiker angezeigt, sortiert nach Match-Score

**Akzeptanzkriterien:**
1. Wenn ein Musiker **absagt**, analysiert das System:
   - **Instrument/Stimme** des abgesagten Musikers (z.B. "1. Trompete")
   - **Alle anderen Musiker der Kapelle** mit gleichem oder kompatiblem Instrument
   - **Verfügbarkeit:** Haben die Kandidaten bereits zugesagt (→ nicht verfügbar) oder sind sie noch offen?
2. System zeigt Dirigent/Admin eine Liste von **max. 5 Ersatzmusikern**, sortiert nach:
   - **Primär-Match:** Gleiches Instrument + gleiche Stimme (z.B. "1. Trompete")
   - **Sekundär-Match:** Gleiches Instrument, andere Stimme (z.B. "2. Trompete")
   - **Fallback-Match:** Kompatibles Instrument aus gleichem Register (z.B. Flügelhorn statt Trompete)
   - **Verfügbarkeit:** Offen > Unsicher > bereits Zugesagt für anderen Termin
3. Für jeden Ersatzmusiker zeigt das System:
   - Name, Avatar
   - Instrument + Stimme
   - Letzter Auftritt mit der Kapelle (z.B. "vor 2 Wochen")
   - Status für diesen Termin (Offen / Unsicher / Zugesagt für anderen Termin)
   - **"Anfragen"-Button:** Sendet personalisierte Push-Notification an den Ersatzmusiker
4. **Anfrage-Nachricht:** "Max hat für [Konzert XY] abgesagt. Kannst du als Ersatz einspringen? (1. Trompete)"
5. Ersatzmusiker erhält Benachrichtigung und kann direkt zusagen/absagen
6. **Fehlerfall:** Wenn kein Ersatzmusiker gefunden wird → "Keine Ersatzmusiker verfügbar. Bitte kontaktiere Musiker aus anderen Kapellen oder suche extern."
7. **Fehlerfall:** Wenn Musiker bereits für einen anderen Termin zur gleichen Zeit zugesagt hat → Kennzeichnung "Konflikt mit [Termin-Name]"

**Matching-Algorithmus (vereinfacht):**
```
Score = 0
IF Instrument == exakt gleich: Score += 100
IF Stimme == exakt gleich: Score += 50
IF Register == gleich: Score += 25
IF Status == "Offen": Score += 30
IF Status == "Unsicher": Score += 15
IF letzter_auftritt < 30 Tage: Score += 10
IF hat_konflikt: Score -= 100
SORT BY Score DESC
LIMIT 5
```

---

### US-04: Push-Benachrichtigungen + Erinnerungen

> *Als Musiker möchte ich rechtzeitig an Termine erinnert werden, damit ich keinen Auftritt verpasse.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt FCM/APNs-Infrastruktur
- **N**egotiable: Erinnerungszeitpunkte können konfigurierbar gemacht werden (MS3)
- **V**aluable: Ohne Erinnerungen vergessen Musiker Termine
- **E**stimatable: ~1 Sprint (FCM/APNs-Integration)
- **S**mall: Nur Benachrichtigungen — Kalender-Sync ist separate Concern
- **T**estable: ✅ Benachrichtigung wird zur richtigen Zeit versendet

**Akzeptanzkriterien:**
1. **Termin-Erinnerungen (automatisch):**
   - **7 Tage vorher:** "Erinnerung: Konzert am [Datum] — bitte zusagen!"
   - **1 Tag vorher:** "Morgen um [Uhrzeit]: [Termin-Name] — bist du dabei?" (nur wenn Status = Offen/Unsicher)
   - **1 Stunde vorher:** "In 1 Stunde: [Termin-Name] in [Ort]" (nur wenn Status = Zugesagt)
2. **Zusage-Erinnerung (bei Frist):**
   - Wenn Dirigent eine Zusage-Frist gesetzt hat und Musiker noch offen ist → Benachrichtigung am Fristdatum
3. **Status-Änderung (Dirigent/Admin):**
   - Bei jeder Zu-/Absage eines Musikers → Dirigent erhält Update (max. alle 30 Minuten zusammengefasst)
4. **Ersatzmusiker-Anfrage:**
   - Wenn Dirigent Ersatzmusiker anfragt → sofortige Push-Notification
5. **Termin-Änderung:**
   - Wenn Dirigent Termin-Zeit, Ort oder Setlist ändert → alle Mitglieder erhalten Update
   - **Critical:** Wenn Termin < 24h vor Beginn geändert wird → sofortige Push (nicht zusammengefasst)
6. **Benachrichtigungs-Einstellungen (Pro Musiker):**
   - Musiker kann Push-Benachrichtigungen global deaktivieren
   - Musiker kann Erinnerungen pro Kapelle deaktivieren
   - Standard: Alle Benachrichtigungen aktiviert
7. **Fehlerfall:** Wenn Push-Token ungültig (User hat App deinstalliert) → System protokolliert, versucht erneut nach 24h, markiert Token nach 7 Tagen als ungültig

**Technologie:**
- **iOS:** Apple Push Notification Service (APNs)
- **Android:** Firebase Cloud Messaging (FCM)
- **Backend:** Queue-basierte Verarbeitung (z.B. Hangfire, Azure Queue) für verzögerte Benachrichtigungen

---

### US-05: Kalender — Übersicht & Filter

> *Als Musiker möchte ich alle Termine in einem Kalender sehen, damit ich meine Woche planen kann.*

**Kriterien (INVEST):**
- **I**ndependent: Nutzt bestehende Termin-Daten
- **N**egotiable: Ansichten können erweitert werden (MS3: Jahresansicht)
- **V**aluable: Ohne Kalender keine visuelle Übersicht
- **E**stimatable: ~1 Sprint
- **S**mall: Nur Darstellung — Sync ist separate Concern
- **T**estable: ✅ Termine erscheinen in allen Ansichten korrekt

**Akzeptanzkriterien:**
1. **Kalender-Tab** in der Hauptnavigation
2. **Drei Ansichten:**
   - **Monatsansicht:** Grid mit Tagen, Termine als Dots/Badges (Farbe = Termin-Typ)
   - **Wochenansicht:** 7 Spalten (Mo–So), Termine als Blöcke mit Uhrzeit
   - **Listenansicht:** Chronologische Liste, gruppiert nach Monat
3. **Filter:**
   - Nach Kapelle (Dropdown) — zeigt nur Termine der gewählten Kapelle
   - Nach Termin-Typ (Alle | Probe | Konzert | Sonstiges)
   - Nach Zusage-Status (Alle | Zugesagt | Abgesagt | Offen)
4. **Termin-Badge:**
   - Farbe nach Typ: Probe = Blau, Konzert = Rot, Sonstiges = Grau
   - Icon nach Status: ✓ = Zugesagt, ✗ = Abgesagt, ○ = Offen
5. Tap auf Termin → Detail-Ansicht öffnet sich
6. **Navigation:** Pfeile für Monatswechsel, "Heute"-Button springt zum aktuellen Datum
7. **Performance:** Kalender lädt nur den sichtbaren Zeitraum (z.B. ±3 Monate), nicht alle Termine
8. **Fehlerfall:** Wenn keine Termine vorhanden → "Noch keine Termine geplant — erstelle deinen ersten Termin!"

---

### US-06: Termin-Details mit Setlist

> *Als Musiker möchte ich bei einem Termin sehen, welche Stücke gespielt werden, damit ich mich vorbereiten kann.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert Setlist-Feature
- **N**egotiable: Noten-Preview ist optional (MS3)
- **V**aluable: Musiker müssen wissen, was sie spielen sollen
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Anzeige — Setlist-Bearbeitung ist separate Concern
- **T**estable: ✅ Setlist wird korrekt angezeigt

**Akzeptanzkriterien:**
1. Termin-Detailansicht zeigt:
   - Titel, Datum, Uhrzeit, Ort, Typ
   - Beschreibung
   - **Setlist** (falls verknüpft): Liste aller Stücke mit Reihenfolge
   - Zusage-Status des aktuellen Musikers
   - Übersicht: Anzahl Zugesagt/Abgesagt/Offen
   - Liste aller Mitglieder mit Status (nur für Dirigent/Admin sichtbar)
2. **Setlist-Bereich:**
   - Zeigt Setlist-Name als Überschrift
   - Liste aller Stücke (Nummer, Titel, Komponist)
   - Tap auf Stück → öffnet Noten (falls vorhanden)
   - Button "Setlist bearbeiten" (nur Dirigent/Admin)
3. **Wenn keine Setlist verknüpft:** "Keine Setlist verknüpft" + Hinweis für Dirigent
4. **Fehlerfall:** Wenn Setlist gelöscht wurde, Termin aber noch verknüpft ist → "Setlist wurde entfernt"

---

### US-07: Bidirektionale Kalender-Sync

> *Als Musiker möchte ich Sheetstorm-Termine automatisch in meinem Google/Apple/Outlook-Kalender sehen, damit ich alle Termine an einem Ort habe.*

**Kriterien (INVEST):**
- **I**ndependent: Erfordert OAuth2-Integration
- **N**egotiable: Sync-Frequenz kann konfigurierbar gemacht werden (MS3)
- **V**aluable: Alleinstellungsmerkmal — Wettbewerber bieten nur einseitigen Export
- **E**stimatable: ~2 Sprints (OAuth2 + CalDAV für alle 3 Plattformen)
- **S**mall: Fokus auf Sync — Konfliktauflösung ist MS3
- **T**estable: ✅ Termine erscheinen in externem Kalender, Änderungen werden zurück synchronisiert

**Akzeptanzkriterien:**
1. **Einrichtung (Pro Musiker):**
   - Musiker geht in Einstellungen → "Kalender-Synchronisierung"
   - Wählt Kalender-Anbieter: Google Calendar, Apple Calendar (iCloud), Outlook (Microsoft 365)
   - Durchläuft OAuth2-Flow (Weiterleitung zu Google/Apple/Microsoft)
   - Nach erfolgreicher Authentifizierung: System erstellt dediziertes Kalender-Abonnement "Sheetstorm — [Kapellenname]"
2. **Synchronisation (bidirektional):**
   - **Sheetstorm → Externer Kalender:** Neue/geänderte/gelöschte Termine werden innerhalb von 15 Minuten synchronisiert
   - **Externer Kalender → Sheetstorm:** Änderungen am Termin-Titel/Zeit/Ort im externen Kalender werden zurück zu Sheetstorm übertragen (nur Dirigent/Admin dürfen editieren — andere Benutzer sehen Warnung)
   - **Zusage-Status:** Wird als Termin-Antwort im externen Kalender gespeichert ("Zugesagt" = Accepted, "Abgesagt" = Declined, "Offen" = Needs Action)
3. **Kalender-Einträge enthalten:**
   - Titel: "[Kapellenname] — [Termin-Titel]"
   - Beschreibung: Termin-Beschreibung + Setlist (falls verknüpft)
   - Ort: Adresse (falls angegeben)
   - Erinnerung: 1 Stunde vorher
   - Link: Deep-Link zu Sheetstorm-App ("sheetstorm://termine/{id}")
4. **Pro Kapelle ein eigenes Kalender-Abo:**
   - Musiker mit 3 Kapellen → 3 separate Kalender-Abos (deaktivierbar einzeln)
   - Farbcodierung nach Kapelle (Google/Apple unterstützen Kalenderfarben)
5. **Sync-Status:**
   - Musiker sieht in Einstellungen: "Letzte Synchronisation: vor 5 Minuten"
   - Bei Fehler: "Synchronisation fehlgeschlagen — bitte Berechtigung erneut erteilen"
6. **Fehlerfall:** Wenn OAuth-Token abläuft → System versucht automatisch Refresh (OAuth2 Refresh Token); bei Fehler → Benachrichtigung an Musiker "Kalender-Sync unterbrochen"
7. **Fehlerfall:** Wenn externer Kalender gelöscht wird → System erkennt dies und deaktiviert Sync für diese Kapelle

**Technologie:**
- **Google Calendar:** Google Calendar API v3 (OAuth2)
- **Apple Calendar (iCloud):** CalDAV (iCloud-spezifische Endpoints)
- **Outlook:** Microsoft Graph API (OAuth2)
- **Protokoll:** CalDAV für Apple, REST APIs für Google/Microsoft
- **Sync-Mechanismus:** Webhook-basiert (wenn verfügbar) + Polling alle 15 Minuten als Fallback

**Berechtigungen:**
- Google: `https://www.googleapis.com/auth/calendar.events`
- Microsoft: `Calendars.ReadWrite`
- Apple: CalDAV-Zugriff via App-spezifisches Passwort

---

## 3. Akzeptanzkriterien (Feature-Level)

> **Hinweis:** Diese Kriterien gelten über alle User Stories hinweg und definieren, wann das Feature als "vollständig" gilt.

| ID | Kriterium | Testbar durch |
|----|-----------|---------------|
| AC-01 | Termine können von Dirigent/Admin erstellt, bearbeitet und gelöscht werden | E2E-Test: Termin-CRUD-Flow |
| AC-02 | Musiker können für jeden Termin zusagen, absagen oder "vielleicht" wählen | E2E-Test: Zusage-Flow |
| AC-03 | Ersatzmusiker-Vorschlag erscheint innerhalb von 5 Sekunden nach Absage | Performance-Test |
| AC-04 | Push-Benachrichtigungen werden zur richtigen Zeit versendet (±5 Minuten) | Integration-Test mit Mock-FCM/APNs |
| AC-05 | Kalender zeigt alle Termine korrekt in Monats-/Wochen-/Listenansicht | E2E-Test: Kalender-Rendering |
| AC-06 | Kalender-Sync funktioniert bidirektional für Google/Apple/Outlook | Integration-Test mit Test-Accounts |
| AC-07 | Änderungen in externem Kalender werden innerhalb von 30 Minuten zu Sheetstorm übertragen | Integration-Test: Webhook-Verarbeitung |
| AC-08 | Setlist-Verknüpfung zeigt alle Stücke korrekt in Termin-Details | E2E-Test: Setlist-Rendering |
| AC-09 | Wiederholende Termine erstellen automatisch Termine für 12 Wochen | Unit-Test: Wiederkehrungs-Logik |
| AC-10 | Musiker ohne Push-Berechtigung erhalten In-App-Notifications als Fallback | E2E-Test: Notification-Fallback |
| AC-11 | Alle sicherheitsrelevanten Aktionen (Termin-Änderung, Ersatzmusiker-Anfrage) werden im Audit-Log erfasst | DB-Test: Insert prüfen |
| AC-12 | DSGVO: Musiker kann Kalender-Sync jederzeit widerrufen und alle Daten löschen | E2E-Test: Daten-Löschung |

---

## 4. API-Contract

**Base Path:** `/api/v1/termine`  
**Auth:** Bearer JWT (alle Endpunkte erfordern Authentifizierung)

### 4.1 Termine-CRUD

```
POST   /api/v1/termine                    → Termin erstellen (Dirigent/Admin)
GET    /api/v1/termine                    → Alle Termine der aktuellen Kapelle (mit Pagination + Filter)
GET    /api/v1/termine/{id}               → Termin-Details
PUT    /api/v1/termine/{id}               → Termin aktualisieren (Dirigent/Admin)
DELETE /api/v1/termine/{id}               → Termin löschen (Dirigent/Admin)
```

**POST /api/v1/termine — Request:**
```json
{
  "kapelle_id": "uuid",
  "titel": "Sommerkonzert 2026",
  "typ": "Konzert",
  "datum": "2026-07-15",
  "start_uhrzeit": "19:00",
  "end_uhrzeit": "21:30",
  "ort": "Stadtpark Musterstadt, Hauptstraße 10",
  "treffpunkt": "Hintereingang beim Lagerraum",
  "beschreibung": "Gemeinsames Sommerkonzert mit Gastkapelle",
  "setlist_id": "uuid",
  "kleiderordnung": "Tracht",
  "zusage_frist": "2026-07-08",
  "wiederkehrend": false,
  "wiederkehrung_wochen": null
}
```

**POST /api/v1/termine — Response 201:**
```json
{
  "id": "uuid",
  "kapelle_id": "uuid",
  "titel": "Sommerkonzert 2026",
  "typ": "Konzert",
  "datum": "2026-07-15",
  "start_uhrzeit": "19:00",
  "end_uhrzeit": "21:30",
  "ort": "Stadtpark Musterstadt, Hauptstraße 10",
  "treffpunkt": "Hintereingang beim Lagerraum",
  "beschreibung": "Gemeinsames Sommerkonzert mit Gastkapelle",
  "setlist_id": "uuid",
  "setlist_name": "Sommer 2026",
  "kleiderordnung": "Tracht",
  "zusage_frist": "2026-07-08",
  "erstellt_am": "2026-03-28T12:00:00Z",
  "erstellt_von": {
    "id": "uuid",
    "name": "Max Dirigent"
  },
  "statistik": {
    "zugesagt": 0,
    "abgesagt": 0,
    "unsicher": 0,
    "offen": 45
  }
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (Datum in Vergangenheit, Start nach Ende, etc.)
- `403` — Nicht berechtigt (kein Dirigent/Admin)
- `404` — Kapelle oder Setlist nicht gefunden
- `409` — Konflikt (z.B. überschneidender Termin zur gleichen Zeit am gleichen Ort)

---

### 4.2 Teilnahme-API (Zusage/Absage)

```
POST   /api/v1/termine/{id}/teilnahme           → Eigene Zusage/Absage setzen
GET    /api/v1/termine/{id}/teilnahmen          → Alle Teilnahmen für einen Termin (Dirigent/Admin)
PUT    /api/v1/termine/{id}/teilnahmen/{musiker_id} → Teilnahme aktualisieren (Dirigent/Admin)
```

**POST /api/v1/termine/{id}/teilnahme — Request:**
```json
{
  "status": "Zugesagt",
  "begruendung": null
}
```

**Status:** `Offen` | `Zugesagt` | `Abgesagt` | `Unsicher`

**POST /api/v1/termine/{id}/teilnahme — Response 200:**
```json
{
  "termin_id": "uuid",
  "musiker_id": "uuid",
  "status": "Zugesagt",
  "begruendung": null,
  "geaendert_am": "2026-03-28T12:00:00Z"
}
```

**GET /api/v1/termine/{id}/teilnahmen — Response 200:**
```json
{
  "items": [
    {
      "musiker_id": "uuid",
      "name": "Anna Musterfrau",
      "avatar_url": "https://...",
      "instrument": "1. Klarinette",
      "register": "Klarinetten",
      "status": "Zugesagt",
      "begruendung": null,
      "geaendert_am": "2026-03-28T12:00:00Z"
    },
    {
      "musiker_id": "uuid",
      "name": "Max Mustermann",
      "avatar_url": "https://...",
      "instrument": "1. Trompete",
      "register": "Trompeten",
      "status": "Abgesagt",
      "begruendung": "Urlaub",
      "geaendert_am": "2026-03-28T13:00:00Z"
    }
  ],
  "gesamt": 45,
  "cursor": null
}
```

---

### 4.3 Ersatzmusiker-API

```
GET    /api/v1/termine/{id}/ersatzmusiker/{musiker_id}  → Ersatzmusiker-Vorschläge für abgesagten Musiker (Dirigent/Admin)
POST   /api/v1/termine/{id}/ersatzmusiker/anfragen      → Ersatzmusiker anfragen (Dirigent/Admin)
```

**GET /api/v1/termine/{id}/ersatzmusiker/{musiker_id} — Response 200:**
```json
{
  "abgesagter_musiker": {
    "id": "uuid",
    "name": "Max Mustermann",
    "instrument": "1. Trompete",
    "register": "Trompeten"
  },
  "vorschlaege": [
    {
      "musiker_id": "uuid",
      "name": "Lisa Ersatz",
      "avatar_url": "https://...",
      "instrument": "1. Trompete",
      "register": "Trompeten",
      "status": "Offen",
      "letzter_auftritt": "2026-03-15",
      "match_score": 185,
      "match_grund": "Gleiches Instrument und Stimme, verfügbar"
    },
    {
      "musiker_id": "uuid",
      "name": "Tom Backup",
      "avatar_url": "https://...",
      "instrument": "2. Trompete",
      "register": "Trompeten",
      "status": "Unsicher",
      "letzter_auftritt": "2026-02-20",
      "match_score": 160,
      "match_grund": "Gleiches Instrument, andere Stimme"
    }
  ]
}
```

**POST /api/v1/termine/{id}/ersatzmusiker/anfragen — Request:**
```json
{
  "musiker_ids": ["uuid1", "uuid2"],
  "nachricht": "Max hat abgesagt. Könnt ihr einspringen?"
}
```

**Response 200:**
```json
{
  "angefragt": 2,
  "benachrichtigungen_gesendet": 2
}
```

---

### 4.4 Kalender-API

```
GET    /api/v1/kalender                   → Alle Termine für Kalender-Ansicht (mit Filter)
GET    /api/v1/kalender/sync-status       → Status der Kalender-Synchronisation
POST   /api/v1/kalender/sync/google       → Google Calendar Sync aktivieren (OAuth2-Flow)
POST   /api/v1/kalender/sync/apple        → Apple Calendar Sync aktivieren (CalDAV)
POST   /api/v1/kalender/sync/outlook      → Outlook Sync aktivieren (OAuth2-Flow)
DELETE /api/v1/kalender/sync/{provider}   → Sync deaktivieren und Daten löschen
```

**GET /api/v1/kalender — Query-Parameter:**
- `kapelle_id` — Filter nach Kapelle (optional, default: aktuelle Kapelle)
- `von` — Start-Datum (ISO 8601, default: heute - 1 Monat)
- `bis` — End-Datum (ISO 8601, default: heute + 3 Monate)
- `typ` — Filter nach Termin-Typ (optional: `Probe`, `Konzert`, `Sonstiges`)
- `status` — Filter nach Zusage-Status (optional: `Zugesagt`, `Abgesagt`, `Offen`, `Unsicher`)

**GET /api/v1/kalender — Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "titel": "Probe",
      "typ": "Probe",
      "datum": "2026-03-29",
      "start_uhrzeit": "19:00",
      "end_uhrzeit": "21:00",
      "ort": "Proberaum",
      "meine_teilnahme": "Zugesagt",
      "kapelle_id": "uuid",
      "kapelle_name": "Musikkapelle Beispiel",
      "setlist_id": null
    }
  ],
  "gesamt": 24,
  "cursor": null
}
```

**GET /api/v1/kalender/sync-status — Response 200:**
```json
{
  "google": {
    "aktiv": true,
    "letzte_sync": "2026-03-28T12:00:00Z",
    "kalender_id": "sheetstorm_musikkapelle_beispiel@group.calendar.google.com",
    "fehler": null
  },
  "apple": {
    "aktiv": false
  },
  "outlook": {
    "aktiv": true,
    "letzte_sync": "2026-03-28T11:55:00Z",
    "kalender_id": "AAMkAG...",
    "fehler": null
  }
}
```

---

### 4.5 Push-Benachrichtigungen

```
POST   /api/v1/push/register              → FCM/APNs-Token registrieren
DELETE /api/v1/push/unregister            → Token entfernen
PUT    /api/v1/push/einstellungen         → Benachrichtigungs-Einstellungen ändern
```

**POST /api/v1/push/register — Request:**
```json
{
  "plattform": "iOS",
  "token": "apns-token-xyz",
  "geraet_name": "iPhone 14 Pro"
}
```

**PUT /api/v1/push/einstellungen — Request:**
```json
{
  "termine_erinnerung": true,
  "termine_aenderung": true,
  "ersatzmusiker_anfrage": true,
  "kapelle_benachrichtigungen": {
    "uuid-kapelle-1": true,
    "uuid-kapelle-2": false
  }
}
```

---

## 5. Datenmodell

### 5.1 Termin

```sql
CREATE TYPE termin_typ AS ENUM (
    'Probe', 'Konzert', 'Auftritt', 'Ausflug', 'Sonstiges'
);

CREATE TABLE termine (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id          UUID        NOT NULL REFERENCES bands(id) ON DELETE CASCADE,
    titel               VARCHAR(100) NOT NULL,
    typ                 termin_typ  NOT NULL,
    datum               DATE        NOT NULL,
    start_uhrzeit       TIME        NOT NULL,
    end_uhrzeit         TIME,
    ort                 VARCHAR(200),
    treffpunkt          VARCHAR(200),
    beschreibung        TEXT,
    setlist_id          UUID        REFERENCES setlists(id) ON DELETE SET NULL,
    kleiderordnung      VARCHAR(100),
    zusage_frist        DATE,
    wiederkehrend       BOOLEAN     NOT NULL DEFAULT FALSE,
    wiederkehrung_parent UUID       REFERENCES termine(id) ON DELETE CASCADE,
    erstellt_am         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aktualisiert_am     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    geloescht_am        TIMESTAMPTZ,
    erstellt_von        UUID        NOT NULL REFERENCES musicians(id)
);

CREATE INDEX idx_termine_kapelle      ON termine(kapelle_id, datum) WHERE geloescht_am IS NULL;
CREATE INDEX idx_termine_datum        ON termine(datum) WHERE geloescht_am IS NULL;
CREATE INDEX idx_termine_setlist      ON termine(setlist_id) WHERE setlist_id IS NOT NULL;
CREATE INDEX idx_termine_wiederkehrung ON termine(wiederkehrung_parent) WHERE wiederkehrung_parent IS NOT NULL;
```

### 5.2 Termin-Teilnahme

```sql
CREATE TYPE teilnahme_status AS ENUM (
    'Offen', 'Zugesagt', 'Abgesagt', 'Unsicher'
);

CREATE TABLE termin_teilnahmen (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    termin_id       UUID            NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
    musiker_id      UUID            NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    status          teilnahme_status NOT NULL DEFAULT 'Offen',
    begruendung     VARCHAR(200),
    geaendert_am    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    erstellt_am     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (termin_id, musiker_id)
);

CREATE INDEX idx_teilnahmen_termin   ON termin_teilnahmen(termin_id, status);
CREATE INDEX idx_teilnahmen_musiker  ON termin_teilnahmen(musiker_id, status);
```

**Business Rule:** Bei Termin-Erstellung werden automatisch Einträge für alle aktiven Mitglieder der Kapelle erstellt (Status = `Offen`).

### 5.3 Termin-Erinnerung

```sql
CREATE TYPE erinnerung_typ AS ENUM (
    'Zusage_7_Tage', 'Zusage_1_Tag', 'Termin_1_Stunde', 'Frist_Erreicht'
);

CREATE TABLE termin_erinnerungen (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    termin_id           UUID            NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
    musiker_id          UUID            NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    typ                 erinnerung_typ  NOT NULL,
    geplant_am          TIMESTAMPTZ     NOT NULL,
    gesendet_am         TIMESTAMPTZ,
    fehler              TEXT,
    erstellt_am         TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_erinnerungen_geplant ON termin_erinnerungen(geplant_am) WHERE gesendet_am IS NULL;
CREATE INDEX idx_erinnerungen_termin  ON termin_erinnerungen(termin_id);
```

**Business Rule:** Erinnerungen werden beim Termin-Erstellen automatisch generiert (Queue-Job).

### 5.4 Ersatzmusiker-Anfrage

```sql
CREATE TABLE ersatzmusiker_anfragen (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    termin_id               UUID        NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
    abgesagter_musiker_id   UUID        NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    angefragter_musiker_id  UUID        NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    nachricht               VARCHAR(500),
    angefragt_am            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    angefragt_von           UUID        NOT NULL REFERENCES musicians(id),
    antwort_status          teilnahme_status,
    antwort_am              TIMESTAMPTZ
);

CREATE INDEX idx_ersatzmusiker_termin    ON ersatzmusiker_anfragen(termin_id);
CREATE INDEX idx_ersatzmusiker_angefragt ON ersatzmusiker_anfragen(angefragter_musiker_id, antwort_status);
```

### 5.5 Kalender-Sync

```sql
CREATE TYPE kalender_provider AS ENUM (
    'Google', 'Apple', 'Outlook'
);

CREATE TABLE kalender_sync (
    id                  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    musiker_id          UUID                NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    kapelle_id          UUID                NOT NULL REFERENCES bands(id) ON DELETE CASCADE,
    provider            kalender_provider   NOT NULL,
    aktiv               BOOLEAN             NOT NULL DEFAULT TRUE,
    oauth_token         TEXT,               -- verschlüsselt
    oauth_refresh_token TEXT,               -- verschlüsselt
    oauth_expires_at    TIMESTAMPTZ,
    kalender_id         VARCHAR(255),       -- Externe Kalender-ID (Google/Outlook)
    letzte_sync         TIMESTAMPTZ,
    fehler              TEXT,
    erstellt_am         TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    aktualisiert_am     TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    UNIQUE (musiker_id, kapelle_id, provider)
);

CREATE INDEX idx_kalender_sync_musiker   ON kalender_sync(musiker_id) WHERE aktiv = TRUE;
CREATE INDEX idx_kalender_sync_kapelle   ON kalender_sync(kapelle_id) WHERE aktiv = TRUE;
CREATE INDEX idx_kalender_sync_expires   ON kalender_sync(oauth_expires_at) WHERE aktiv = TRUE;
```

**Sicherheit:** OAuth-Tokens werden mit AES-256 verschlüsselt in der Datenbank gespeichert.

### 5.6 Push-Benachrichtigungen

```sql
CREATE TYPE push_plattform AS ENUM (
    'iOS', 'Android', 'Web'
);

CREATE TABLE push_tokens (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    musiker_id      UUID            NOT NULL REFERENCES musicians(id) ON DELETE CASCADE,
    plattform       push_plattform  NOT NULL,
    token           VARCHAR(255)    NOT NULL UNIQUE,
    geraet_name     VARCHAR(100),
    aktiv           BOOLEAN         NOT NULL DEFAULT TRUE,
    letzte_verwendung TIMESTAMPTZ,
    erstellt_am     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_push_tokens_musiker ON push_tokens(musiker_id) WHERE aktiv = TRUE;
CREATE INDEX idx_push_tokens_token   ON push_tokens(token) WHERE aktiv = TRUE;
```

```sql
CREATE TABLE push_einstellungen (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    musiker_id                  UUID        NOT NULL REFERENCES musicians(id) ON DELETE CASCADE UNIQUE,
    termine_erinnerung          BOOLEAN     NOT NULL DEFAULT TRUE,
    termine_aenderung           BOOLEAN     NOT NULL DEFAULT TRUE,
    ersatzmusiker_anfrage       BOOLEAN     NOT NULL DEFAULT TRUE,
    status_aenderung_zusammenfassung BOOLEAN NOT NULL DEFAULT TRUE,
    kapelle_benachrichtigungen  JSONB       DEFAULT '{}',  -- { "kapelle_id": true/false }
    aktualisiert_am             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 6. Berechtigungsmatrix

> **Prinzip:** RBAC pro Kapelle. Server-side Enforcement für alle Aktionen. Das Frontend blendet Elemente aus — aber der Server validiert jeden Request unabhängig.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|
| **Termine** | | | | | |
| Termin erstellen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Termin bearbeiten (Titel, Datum, Ort) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Termin löschen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Setlist verknüpfen/ändern | ✅ | ✅ | ❌ | ❌ | ❌ |
| Termin-Details sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Teilnahme** | | | | | |
| Eigene Zusage/Absage setzen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zusage/Absage anderer sehen | ✅ | ✅ | ❌ | ❌ | ❌¹ |
| Teilnahme für andere setzen | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Ersatzmusiker** | | | | | |
| Ersatzmusiker-Vorschläge sehen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Ersatzmusiker anfragen | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Kalender** | | | | | |
| Kalender-Ansicht sehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kalender-Sync aktivieren (eigene Konten) | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Benachrichtigungen** | | | | | |
| Push-Einstellungen ändern (eigene) | ✅ | ✅ | ✅ | ✅ | ✅ |

> ¹ Musiker sehen nur Gesamtzahl (z.B. "12 zugesagt"), aber keine Namen der anderen Musiker.

---

## 7. Edge Cases

> **Definition:** Edge Cases sind Grenzfälle, die in User Stories oft nicht explizit beschrieben sind, aber dennoch auftreten können. Sie erfordern definiertes Verhalten.

| Szenario | Erwartetes Verhalten |
|----------|---------------------|
| **Musiker sagt zu, dann ab, dann wieder zu** | Jede Statusänderung wird protokolliert (Audit-Log). Letzter Status gilt. Dirigent erhält nur eine Benachrichtigung pro 30-Minuten-Fenster (zusammengefasst). |
| **Dirigent löscht Termin nach 10 Zusagen** | Alle Teilnahmen werden weich gelöscht (Soft-Delete). Push-Benachrichtigung an alle zugesagten Musiker: "Termin [Titel] wurde abgesagt." Externe Kalender: Termin wird als "Cancelled" markiert. |
| **Termin startet in 10 Minuten, Musiker sagt ab** | Warnung: "Kurzfristige Absage — bitte kontaktiere den Dirigenten unter [Telefonnummer]." Dirigent erhält sofortige Push-Notification (nicht zusammengefasst). |
| **Ersatzmusiker hat zur gleichen Zeit einen anderen Termin zugesagt** | Kennzeichnung im Vorschlag: "Konflikt mit [Termin-Name] um [Uhrzeit]". Ersatzmusiker kann trotzdem angefragt werden (evtl. andere Kapelle). |
| **Setlist wird gelöscht, aber Termin ist noch verknüpft** | Termin behält Setlist-Referenz (FK ON DELETE SET NULL). Anzeige: "Setlist wurde entfernt." Dirigent erhält Warnung. |
| **Musiker verlässt Kapelle nach Zusage für zukünftigen Termin** | Alle zukünftigen Teilnahmen werden auf "Abgesagt" gesetzt. Dirigent erhält Benachrichtigung. Externe Kalender: Termine bleiben bis zum nächsten Sync, dann werden sie gelöscht. |
| **OAuth-Token für Google Calendar läuft ab** | System versucht automatisch Refresh (Refresh Token). Bei Fehler: Sync wird deaktiviert, Musiker erhält Benachrichtigung "Kalender-Sync unterbrochen — bitte erneut autorisieren." |
| **Musiker ändert Termin-Zeit in Google Calendar (bidirektional)** | Änderung wird zu Sheetstorm übertragen. **Nur Dirigent/Admin dürfen editieren:** Wenn Musiker (nicht Dirigent) ändert → Änderung wird verworfen + Warnung per E-Mail: "Du hast einen Termin in Google Calendar geändert, aber nur Dirigenten dürfen Termine bearbeiten." |
| **Zwei Termine zur gleichen Zeit am gleichen Ort** | System warnt beim Erstellen: "Es existiert bereits ein Termin um [Uhrzeit] in [Ort]. Trotzdem erstellen?" (nicht blockierend). |
| **Musiker hat Push-Benachrichtigungen deaktiviert** | In-App-Notification als Fallback. Badge auf Kalender-Tab. Bei kritischen Benachrichtigungen (< 24h vor Termin): Zusätzlich E-Mail. |
| **Kapelle hat 0 Mitglieder (alle ausgetreten)** | Termine bleiben erhalten (für Audit-Zwecke). Keine Benachrichtigungen werden versendet. |
| **Wiederkehrender Termin: Musiker sagt für einen der 12 Termine ab** | Absage gilt nur für diesen einen Termin. System schlägt vor: "Möchtest du für alle zukünftigen Termine absagen?" (Optional). |
| **Ersatzmusiker-Algorithmus findet 0 Kandidaten** | Anzeige: "Keine Ersatzmusiker verfügbar." Vorschlag: "Kontaktiere Musiker aus anderen Registern oder suche extern." |
| **Musiker ist in 5 Kapellen — Kalender-Sync für alle aktiv** | 5 separate Kalender-Abos werden erstellt (z.B. "Sheetstorm — Kapelle A", "Sheetstorm — Kapelle B", ...). Musiker kann Sync pro Kapelle deaktivieren. |
| **External Kalender (Google) wird gelöscht** | Beim nächsten Sync-Versuch: API-Fehler 404. System deaktiviert Sync für diese Kapelle, Musiker erhält Benachrichtigung. |
| **Musiker hat App deinstalliert (Push-Token ungültig)** | FCM/APNs liefert "Token invalid". System markiert Token als inaktiv nach 7 Tagen. Fallback: In-App-Notification beim nächsten App-Start. |

---

## 8. Abhängigkeiten

### 8.1 Technische Abhängigkeiten

| Abhängigkeit | Beschreibung | Status |
|--------------|-------------|--------|
| **Kapellenverwaltung** (#15) | Musiker, Rollen, Register | ✅ MS1 abgeschlossen |
| **Setlist-Feature** | Setlist-Entität für Termin-Verknüpfung | 🚧 MS2 parallel |
| **Push-Notification-Infrastruktur** | FCM/APNs-Setup, Queue-basierte Verarbeitung | ⏳ MS2 — muss vor Termine implementiert werden |
| **OAuth2-Integration** | Google/Microsoft OAuth2-Flow | ⏳ MS2 — neue Abhängigkeit |
| **CalDAV-Client** | Apple iCloud-Kalender-Zugriff | ⏳ MS2 — neue Abhängigkeit |

### 8.2 Externe Abhängigkeiten

| Service | Zweck | Kritikalität |
|---------|-------|--------------|
| **Firebase Cloud Messaging (FCM)** | Android Push-Benachrichtigungen | Kritisch |
| **Apple Push Notification Service (APNs)** | iOS Push-Benachrichtigungen | Kritisch |
| **Google Calendar API** | Kalender-Sync | Hoch |
| **Microsoft Graph API** | Outlook-Sync | Hoch |
| **iCloud CalDAV** | Apple Calendar-Sync | Mittel |

### 8.3 Feature-Abhängigkeiten (MS3+)

| Feature | Abhängigkeit zu Termine |
|---------|------------------------|
| **Anwesenheitsstatistiken** | Benötigt historische Teilnahme-Daten |
| **Automatische Terminvorschläge (AI)** | Analysiert vergangene Termine + Verfügbarkeit |
| **Setlist-Änderungsbenachrichtigung** | Überwacht Änderungen an verknüpften Setlists |

---

## 9. Definition of Done

> **Prinzip:** Ein Feature ist erst dann "Done", wenn es produktionsreif ist — nicht nur "Code Complete". Die Definition of Done gilt für das gesamte Feature "Konzertplanung + Kalender".

### 9.1 Code

- [ ] Alle User Stories (US-01 bis US-07) sind implementiert und deployed
- [ ] API-Endpunkte entsprechen dem Contract (inkl. Fehlerbehandlung)
- [ ] Datenmodell ist implementiert (inkl. Indizes, Constraints)
- [ ] Berechtigungsmatrix wird server-side für jeden Endpunkt validiert
- [ ] Code-Review durch mindestens 2 Entwickler (Banner + Romanoff)
- [ ] Keine bekannten P0/P1-Bugs (P2/P3 sind akzeptabel, wenn dokumentiert)

### 9.2 Tests

- [ ] Unit-Tests: Mind. 80% Code-Coverage für Business-Logik (Ersatzmusiker-Algorithmus, Erinnerungs-Generierung)
- [ ] Integration-Tests: API-Endpunkte (Happy Path + Error Cases)
- [ ] E2E-Tests: Termin-CRUD, Zusage-Flow, Kalender-Rendering, Kalender-Sync (mit Test-Accounts)
- [ ] Performance-Tests: Ersatzmusiker-Vorschlag < 5 Sekunden, Kalender-Rendering < 500ms
- [ ] Security-Tests: JWT-Validierung, RBAC-Enforcement, OAuth-Token-Verschlüsselung

### 9.3 Dokumentation

- [ ] API-Dokumentation in Swagger/OpenAPI aktualisiert
- [ ] README.md: Setup-Anleitung für FCM/APNs-Konfiguration
- [ ] README.md: OAuth2-Setup für Google/Microsoft (Client-IDs, Redirect-URLs)
- [ ] Datenbank-Migrations-Skripte (mit Rollback-Plan)
- [ ] Deployment-Runbook: Schritte für Production-Rollout
- [ ] User-Facing-Dokumentation: "Wie richte ich Kalender-Sync ein?" (Help Center)

### 9.4 UX/UI

- [ ] UX-Design von Wanda abgenommen (`docs/ux-specs/konzertplanung.md`)
- [ ] Responsive Design für Phone/Tablet/Desktop
- [ ] Accessibility: WCAG 2.1 Level AA (Screen Reader, Keyboard-Navigation)
- [ ] Offline-Support: Kalender-Ansicht funktioniert offline (cached), Zusage/Absage wird nach Reconnect synchronisiert
- [ ] Feedback bei langsamen Aktionen (Loading-Spinner für Ersatzmusiker-Suche, Kalender-Sync)

### 9.5 DevOps

- [ ] CI/CD-Pipeline: Automatische Tests + Deployment zu Staging
- [ ] Monitoring: Application Insights / Sentry für Error-Tracking
- [ ] Metrics: Push-Benachrichtigungen (Delivery-Rate), Kalender-Sync (Success-Rate), API-Latency
- [ ] Alerts: Fehlerrate > 5%, OAuth-Token-Refresh-Fehler > 10%
- [ ] Backup: Termin-Daten werden täglich gesichert

### 9.6 Compliance

- [ ] DSGVO: Musiker kann Kalender-Sync-Daten exportieren + löschen
- [ ] DSGVO: OAuth-Tokens werden verschlüsselt gespeichert (AES-256)
- [ ] DSGVO: Audit-Log für alle sicherheitsrelevanten Aktionen (Termin-Änderung, Ersatzmusiker-Anfrage)
- [ ] DSGVO: Datenverarbeitungsverträge (DPA) mit Google/Microsoft für API-Nutzung

### 9.7 Launch-Readiness

- [ ] Staging-Deployment erfolgreich (1 Woche Beta-Test mit 3 Testkapellen)
- [ ] Rollout-Plan: Phased Rollout (10% → 50% → 100% über 1 Woche)
- [ ] Rollback-Plan: Bei kritischen Fehlern → Feature-Flag deaktivieren, DB-Rollback-Skript bereit
- [ ] Support-Team geschult (FAQ, Troubleshooting für Kalender-Sync)
- [ ] Product-Owner (Hill) hat Release-Notes abgenommen

---

## 10. Offene Fragen

> **Hinweis:** Diese Fragen müssen vor Implementierungsstart geklärt werden.

| ID | Frage | Verantwortlich | Deadline |
|----|-------|---------------|----------|
| Q-01 | Sollen Musiker andere Musiker zur gleichen Kapelle für einen Termin sehen können (Transparenz vs. Datenschutz)? | Hill + Thomas | MS2 Kickoff |
| Q-02 | Wie soll Konfliktauflösung bei bidirektionaler Sync funktionieren (Sheetstorm vs. Google Calendar = zwei Wahrheiten)? | Banner (Backend) | Woche 1 |
| Q-03 | Sollen wiederkehrende Termine als Serie oder als einzelne Termine gespeichert werden? | Banner (Backend) | Woche 1 |
| Q-04 | Welche FCM/APNs-Infrastruktur nutzen wir (eigene Server oder Service wie OneSignal/Pusher)? | Banner (Backend) | Vor Implementierung |
| Q-05 | Soll Ersatzmusiker-Vorschlag auch Musiker aus anderen Kapellen vorschlagen (wenn User in mehreren Kapellen ist)? | Hill | MS2 Kickoff |
| Q-06 | Wie gehen wir mit Zeitzonen um (Termin-Zeitstempel UTC oder lokale Zeit)? | Banner (Backend) | Woche 1 |
| Q-07 | Sollen Dirigenten die Möglichkeit haben, Erinnerungszeitpunkte anzupassen (z.B. 2 Tage statt 7 Tage)? | Hill + Wanda | MS3 Backlog |

---

## 11. Nicht-funktionale Anforderungen

### 11.1 Performance

| Metrik | Zielwert | Messmethode |
|--------|----------|-------------|
| Kalender-Rendering | < 500ms | Lighthouse Performance Score |
| Ersatzmusiker-Vorschlag | < 5 Sekunden | API-Response-Time |
| Push-Benachrichtigung (Delivery) | < 10 Sekunden | FCM/APNs-Metrics |
| Kalender-Sync (bidirektional) | < 30 Minuten | Webhook-Verarbeitung |
| API-Latency (P95) | < 300ms | Application Insights |

### 11.2 Skalierbarkeit

| Szenario | Anforderung |
|----------|-------------|
| Anzahl Termine pro Kapelle | 1000+ Termine |
| Anzahl gleichzeitiger Push-Notifications | 10.000+ Musiker |
| Anzahl Kalender-Syncs pro Stunde | 1000+ Sync-Vorgänge |
| Anzahl Ersatzmusiker-Berechnungen pro Minute | 100+ |

### 11.3 Security

| Anforderung | Umsetzung |
|-------------|-----------|
| OAuth-Token-Verschlüsselung | AES-256, Key-Rotation alle 90 Tage |
| HTTPS für alle API-Calls | TLS 1.3 |
| JWT-Token-Validierung | Server-side, Expiry nach 1 Stunde |
| RBAC-Enforcement | Server-side für jeden Endpunkt |
| Audit-Log | Alle sicherheitsrelevanten Aktionen |

### 11.4 Verfügbarkeit

| Metrik | Zielwert |
|--------|----------|
| Uptime | 99.5% (monatlich) |
| Recovery Time Objective (RTO) | < 1 Stunde |
| Recovery Point Objective (RPO) | < 24 Stunden (täglich Backup) |

---

**Ende der Spezifikation**

---

> **Review-Checkliste für Reviewer:**
> - [ ] Alle User Stories sind INVEST-konform
> - [ ] API-Contract ist vollständig (Request/Response/Fehlercodes)
> - [ ] Datenmodell hat alle Beziehungen + Indizes
> - [ ] Berechtigungsmatrix ist konsistent mit Kapellenverwaltung
> - [ ] Edge Cases decken reale Szenarien ab
> - [ ] Definition of Done ist erreichbar innerhalb MS2-Timeline
> - [ ] Offene Fragen sind vor Implementierungsstart klärbar
