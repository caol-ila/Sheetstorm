# Feature-Spezifikation: Kommunikation

> **Issue:** TBD  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** #15 (Kapellenverwaltung), Auth & Registerverwaltung (MS1)  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD (`docs/ux-specs/kommunikation.md` — Wanda)

---

## 1. Feature-Überblick

Das Kommunikationsmodul ist die **zentrale Austauschplattform** innerhalb einer Kapelle. Es ermöglicht schnelle Information, Abstimmungen und gezielte Benachrichtigungen — und bildet damit die Grundlage für effiziente Probenorganisation, Terminfindung und Vereinskommunikation.

### 1.1 Ziel

Kapellen-Admins und Dirigenten sollen wichtige Informationen mit ihren Mitgliedern teilen, Meinungsbilder einholen und gezielt Untergruppen erreichen können — ohne externe Messenger oder E-Mail-Verteiler. Musiker sollen Posts kommentieren, sich austauschen und über relevante Ereignisse informiert werden.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Nachrichten-Board mit Posts | Private Direktnachrichten |
| Kommentare (1 Ebene) | Verschachtelte Threads |
| Emoji-Reaktionen | Custom-Emoji oder GIF-Support |
| Post-Anhänge (Bilder, PDFs) | Video-Uploads oder Streaming |
| Pin-Funktion für Posts | Archiv-Ansicht / Kategorien |
| Umfragen mit Einzel-/Mehrfachauswahl | Matrix-Fragen, Conditional-Logic |
| Push-Benachrichtigungen (FCM/APNs) | SMS- oder E-Mail-Fallback |
| Register-basierte Benachrichtigungen | Terminbezogene Auto-Benachrichtigungen |
| Anonyme/öffentliche Abstimmungen | Geheime Wahl mit Audit-Log |
| Live-Ergebnisanzeige | Export von Umfrageergebnissen |

### 1.3 Kontext & Marktdifferenzierung

**Alleinstellungsmerkmal:** Sheetstorm kombiniert als einzige App musikalische Noten mit Register-basierter Kommunikation. Dirigenten können gezielt einzelne Register erreichen (z.B. "Alle Trompeten zu Satzprobe um 18 Uhr") — kein Wettbewerber bietet diese Granularität.

**Zielgruppen-Fokus:** Anders als allgemeine Gruppen-Chat-Apps (WhatsApp, Telegram) ist Sheetstorm Kapellen-kontextbezogen — Posts, Umfragen und Benachrichtigungen sind immer einer Kapelle zugeordnet und respektieren deren Rollensystem.

---

## 2. User Stories

### US-01: Post im Nachrichten-Board erstellen

> *Als Dirigent möchte ich eine Nachricht im Board posten, damit alle Mitglieder wichtige Informationen (z.B. Probenausfall, neue Besetzung) sehen.*

**Kriterien (INVEST):**
- **I**ndependent: Läuft unabhängig von Umfragen oder Benachrichtigungen
- **N**egotiable: Rich-Text-Formatierung ist Optional für MS2
- **V**aluable: Ohne Posts kein Informationsaustausch möglich
- **E**stimatable: ~1 Sprint (inkl. Anhang-Upload)
- **S**mall: Nur Erstellung — Kommentare folgen in US-02
- **T**estable: ✅ Post erscheint im Feed, ist für alle Mitglieder sichtbar

**Akzeptanzkriterien:**
1. Admin, Dirigent und Registerführer können auf "+ Neuer Post" tippen (Board-Tab)
2. Pflichtfeld: **Titel** (1–120 Zeichen, nicht leer)
3. Pflichtfeld: **Inhalt** (1–5.000 Zeichen, nicht leer)
4. Optional: Bis zu 5 Anhänge (Bilder: JPG/PNG/HEIF, max. 10 MB pro Datei; PDFs: max. 5 MB)
5. Optional: "An Register" — Dropdown zur Auswahl eines oder mehrerer Register (Default: "Alle")
6. Nach Erstellen: Post erscheint sofort oben im chronologischen Feed
7. Post zeigt: Titel, Inhalt, Autor (Profilbild + Name), Timestamp (z.B. "vor 5 Minuten"), Anhänge als Thumbnails
8. Registerführer können nur Posts für ihr eigenes Register erstellen
9. **Fehlerfall:** Titel oder Inhalt leer → Validierungsfehler, Speichern blockiert
10. **Fehlerfall:** Anhang zu groß oder ungültiges Format → Fehlermeldung mit erlaubten Formaten
11. Neu erstellte Posts triggern optional eine Push-Benachrichtigung (User-Einstellung)

---

### US-02: Kommentare zu Posts hinzufügen

> *Als Musiker möchte ich auf einen Post antworten können, damit ich Fragen stellen oder Feedback geben kann.*

**Kriterien (INVEST):**
- **I**ndependent: Kommentare sind unabhängig von Umfragen
- **N**egotiable: Nested-Threads (Antworten auf Kommentare) sind Out of Scope für MS2
- **V**aluable: Ohne Kommentare wäre der Feed nur Einweg-Kommunikation
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur 1-Ebene-Kommentare — keine verschachtelten Antworten
- **T**estable: ✅ Kommentar erscheint unterhalb des Posts

**Akzeptanzkriterien:**
1. Alle Kapellen-Mitglieder (inkl. Musiker) können auf "Kommentieren" tippen
2. Pflichtfeld: **Text** (1–1.000 Zeichen, nicht leer)
3. Optional: Bis zu 1 Bild-Anhang (JPG/PNG, max. 5 MB)
4. Kommentare werden **chronologisch** (älteste zuerst) unter dem Post angezeigt
5. Jeder Kommentar zeigt: Text, Autor, Timestamp, optionales Bild
6. Nur der Autor oder Admins können eigene Kommentare löschen (Soft-Delete: "Kommentar gelöscht")
7. Post-Autor erhält Push-Benachrichtigung bei neuem Kommentar (falls aktiviert)
8. Kommentar-Anzahl wird am Post angezeigt (z.B. "💬 12")
9. **Fehlerfall:** Text leer → Validierungsfehler, Speichern blockiert
10. Keine Verschachtelung: Es gibt keine "Antwort auf Kommentar"-Funktion (erst MS3)

---

### US-03: Reaktionen auf Posts hinzufügen

> *Als Musiker möchte ich schnell auf einen Post reagieren (z.B. Daumen hoch, Herz), ohne einen Kommentar schreiben zu müssen.*

**Kriterien (INVEST):**
- **I**ndependent: Reaktionen funktionieren unabhängig von Kommentaren
- **N**egotiable: Custom-Emoji oder GIF-Reaktionen sind Out of Scope
- **V**aluable: Schnelles Feedback ohne Kommentar-Overhead
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Basis-Emoji-Set — kein Custom-Upload
- **T**estable: ✅ Reaktionen werden sofort angezeigt und gezählt

**Akzeptanzkriterien:**
1. Unter jedem Post erscheint eine Reaktionsleiste mit vordefinierten Emoji (👍 👏 ❤️ 😊 🎺)
2. Tap auf Emoji fügt Reaktion hinzu; erneuter Tap entfernt sie (Toggle)
3. Jeder Nutzer kann **nur eine Reaktion pro Post** abgeben (kein Multi-Emoji)
4. Reaktionen werden aggregiert angezeigt (z.B. "👍 12 ❤️ 5")
5. Tap auf Reaktionszahl öffnet Liste der Nutzer, die reagiert haben (z.B. "Max, Anna, +10 weitere")
6. Post-Autor erhält keine Push-Benachrichtigung für Reaktionen (zu viel Rauschen)
7. Reaktionen können jederzeit geändert werden (Emoji A → Emoji B)
8. **Edge Case:** Reaktion wird vom Server optimistisch im Client angezeigt, bei Fehler zurückgerollt

---

### US-04: Posts anpinnen

> *Als Admin möchte ich wichtige Posts oben fixieren (z.B. Willkommenspost, Vereinsordnung), damit sie nicht im Feed verschwinden.*

**Kriterien (INVEST):**
- **I**ndependent: Pin-Funktion ist unabhängig von anderen Features
- **N**egotiable: Mehrere Pin-Kategorien (z.B. "Wichtig", "Info") sind Out of Scope
- **V**aluable: Verhindert, dass wichtige Infos im Feed untergehen
- **E**stimatable: ~0.25 Sprints
- **S**mall: Nur Pin/Unpin — keine Sortierung innerhalb der gepinnten Posts
- **T**estable: ✅ Gepinnte Posts erscheinen immer oben

**Akzeptanzkriterien:**
1. Admin und Dirigent können auf "📌 Pinnen" im Post-Menü tippen
2. Gepinnte Posts erscheinen **oberhalb** des chronologischen Feeds in einem separaten Abschnitt
3. Maximal **3 Posts** können gleichzeitig gepinnt sein
4. Beim Versuch, einen 4. Post zu pinnen → Dialog: "Du kannst maximal 3 Posts pinnen. Möchtest du [ältesten gepinnten Post] entpinnen?"
5. Gepinnte Posts zeigen ein 📌-Badge in der Ecke
6. Gepinnte Posts werden chronologisch sortiert (neueste zuerst)
7. "Pinnen rückgängig" entfernt Post aus dem Pin-Bereich — er kehrt an seine chronologische Position zurück
8. Registerführer können nur Posts aus ihrem eigenen Register pinnen
9. **Fehlerfall:** Versuch, einen bereits gepinnten Post erneut zu pinnen → No-Op (idempotent)

---

### US-05: Umfrage erstellen

> *Als Dirigent möchte ich eine Umfrage erstellen (z.B. Terminfindung, Besetzungswünsche), damit ich schnell ein Meinungsbild der Kapelle einholen kann.*

**Kriterien (INVEST):**
- **I**ndependent: Umfragen sind separate Entities vom Board
- **N**egotiable: Matrix-Fragen oder Conditional-Logic sind Out of Scope
- **V**aluable: Ohne Umfragen müssten Abstimmungen extern (Doodle, WhatsApp) stattfinden
- **E**stimatable: ~1.5 Sprints (inkl. Auswertung)
- **S**mall: Fokus auf Einzel-/Mehrfachauswahl — keine Freitext-Antworten
- **T**estable: ✅ Umfrage kann erstellt, beantwortet und ausgewertet werden

**Akzeptanzkriterien:**
1. Admin und Dirigent können auf "+ Neue Umfrage" tippen (Board-Tab → Umfragen)
2. Pflichtfeld: **Frage** (1–200 Zeichen)
3. Pflichtfeld: Mind. **2 Optionen**, max. **10 Optionen** (je 1–100 Zeichen)
4. Pflichtfeld: **Auswahltyp** — "Einzelauswahl" oder "Mehrfachauswahl" (Radio/Checkbox)
5. Optional: **Ablaufdatum** (Default: 7 Tage, konfigurierbar: 1, 3, 7, 14, 30 Tage oder "kein Ablauf")
6. Optional: **Anonymität** — "Anonym" (Standard) oder "Öffentlich" (zeigt Wählernamen)
7. Optional: **Ergebnisse** — "Sofort sichtbar" oder "Nach Ablauf" (für strategische Abstimmungen)
8. Optional: "An Register" — Dropdown zur Auswahl eines oder mehrerer Register (Default: "Alle")
9. Nach Erstellen: Umfrage erscheint im Feed als eigener Card-Typ mit eindeutigem Design
10. Umfrage zeigt: Frage, Optionen (als Buttons/Checkboxen), Anzahl Teilnehmer, verbleibende Zeit
11. **Fehlerfall:** Weniger als 2 Optionen → Validierungsfehler
12. **Fehlerfall:** Ablaufdatum in der Vergangenheit → Validierungsfehler

---

### US-06: An Umfrage teilnehmen

> *Als Musiker möchte ich an einer Umfrage abstimmen, damit meine Meinung in die Entscheidung einfließt.*

**Kriterien (INVEST):**
- **I**ndependent: Teilnahme ist unabhängig von Erstellen
- **N**egotiable: Stimme ändern ist Optional (wird in MS2 implementiert)
- **V**aluable: Ohne Teilnahme wären Umfragen nutzlos
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur abstimmen — Auswertung ist separate Concern
- **T**estable: ✅ Stimme wird gespeichert und in Ergebnis reflektiert

**Akzeptanzkriterien:**
1. Alle Kapellen-Mitglieder können an einer Umfrage teilnehmen (sofern sie die Zielgruppe sind, z.B. "Nur Trompeten")
2. Bei Einzelauswahl: Tap auf eine Option wählt diese aus; vorherige Auswahl wird deaktiviert
3. Bei Mehrfachauswahl: Tap togglet Checkbox; mehrere Optionen gleichzeitig möglich
4. "Abstimmen"-Button wird nach Auswahl einer Option aktiv
5. Nach Abstimmung: Button ändert sich zu "Stimme ändern" (nur wenn Umfrage noch nicht abgelaufen)
6. Nutzer, die bereits abgestimmt haben, sehen einen ✓-Badge auf der Umfrage
7. **Anonyme Umfragen:** Nutzer sehen aggregierte Ergebnisse, aber keine Wählernamen
8. **Öffentliche Umfragen:** Tap auf Balken zeigt Liste "Wer hat dafür gestimmt?"
9. **Ergebnisse "Nach Ablauf":** Nutzer sehen nur "Du hast abgestimmt", aber keine Ergebnisse, bis Umfrage endet
10. Nach Ablauf: Umfrage-Card wird als "Abgelaufen" markiert, keine neuen Stimmen möglich
11. **Fehlerfall:** Versuch, nach Ablauf abzustimmen → Fehlermeldung "Diese Umfrage ist abgelaufen"
12. **Fehlerfall:** Versuch, ohne ausgewählte Option abzustimmen → Validierungsfehler

---

### US-07: Push-Benachrichtigungen empfangen

> *Als Musiker möchte ich eine Push-Benachrichtigung erhalten, wenn ein neuer Post im Board erscheint oder eine Umfrage erstellt wird, damit ich nichts verpasse.*

**Kriterien (INVEST):**
- **I**ndependent: Push-System ist von Board/Umfragen entkoppelt
- **N**egotiable: SMS-Fallback oder E-Mail-Digest sind Out of Scope
- **V**aluable: Ohne Push würden Nutzer nur bei App-Start neue Inhalte sehen
- **E**stimatable: ~1 Sprint (FCM/APNs-Integration)
- **S**small: Nur Push — In-App-Benachrichtigungen sind separate Concern
- **T**estable: ✅ Push wird auf registrierten Geräten empfangen

**Akzeptanzkriterien:**
1. Bei App-Installation: Nutzer wird einmalig nach Push-Berechtigung gefragt (iOS/Android-Standard-Dialog)
2. Nutzer kann in den Einstellungen Push-Benachrichtigungen **pro Kapelle** aktivieren/deaktivieren
3. Nutzer kann Push-Kategorien granular steuern: "Neue Posts", "Neue Umfragen", "Neue Kommentare auf meine Posts"
4. Push-Benachrichtigung enthält: Titel (Post-/Umfrage-Titel), Body (erste 100 Zeichen), Kapellenname, Autor
5. Tap auf Push öffnet die App und navigiert direkt zum betreffenden Post/Umfrage
6. **Register-basiert:** Wenn Post nur "An Register: Trompeten" gerichtet ist, erhalten nur Trompeten-Mitglieder Push
7. Push wird an **alle registrierten Geräte** des Nutzers gesendet (Multi-Device-Support)
8. Nutzer ohne Push-Berechtigung sehen In-App-Banner: "Aktiviere Benachrichtigungen, um nichts zu verpassen"
9. **Fehlerfall:** Gerät hat Push-Token widerrufen → Silent-Fail, Server markiert Token als ungültig
10. **Fehlerfall:** FCM/APNs liefert Fehler → Retry-Logic (max. 3 Versuche), danach Logging + Monitoring-Alert
11. **Rate-Limiting:** Max. 1 Push pro Nutzer pro Minute (verhindert Spam bei schnellen Post-Salven)

---

### US-08: Benachrichtigungen gezielt an Register senden

> *Als Dirigent möchte ich eine Benachrichtigung nur an bestimmte Register senden (z.B. "Alle Holzbläser zu Satzprobe"), damit nicht alle Mitglieder irrelevante Nachrichten erhalten.*

**Kriterien (INVEST):**
- **I**ndependent: Register-Filter funktioniert unabhängig von anderen Features
- **N**egotiable: Individuelle Nutzer-Auswahl (außerhalb Register) ist Optional
- **V**aluable: Verhindert Benachrichtigungs-Fatigue
- **E**stimatable: ~0.5 Sprints
- **S**mall: Nur Filterung — keine Multi-Kapellen-Benachrichtigungen
- **T**estable: ✅ Nur Zielgruppen-Mitglieder erhalten Push

**Akzeptanzkriterien:**
1. Beim Erstellen eines Posts/Umfrage: Dropdown "An Register" mit Multi-Select
2. Optionen: "Alle" (Default), einzelne Register (Klarinetten, Trompeten, ...), oder "Mehrere Register"
3. Ausgewählte Register werden unter dem Post angezeigt (z.B. Badge: "🎺 Trompeten, Posaunen")
4. Push-Benachrichtigung wird **nur an Mitglieder der ausgewählten Register** gesendet
5. Nutzer, die **keinem Register zugeordnet** sind (z.B. Dirigent ohne Instrument), erhalten bei "Alle" trotzdem Push
6. Admin/Dirigent können nachträglich Zielgruppe **nicht ändern** (um Verwirrung zu vermeiden)
7. Im Feed sehen Nutzer alle Posts (auch nicht-Register-spezifische), aber Push ist selektiv
8. **Fehlerfall:** Post an Register "Trompeten", aber Kapelle hat keine Trompeten → Post wird trotzdem erstellt, aber 0 Push gesendet

---

## 3. Akzeptanzkriterien (Feature-Level Tabelle)

| ID | Akzeptanzkriterium | Priorität | Testbar durch |
|----|-------------------|-----------|---------------|
| **AC-01** | Nur Admin, Dirigent und Registerführer (für eigenes Register) können Posts erstellen | MUSS | Integration-Test (403 für Musiker) |
| **AC-02** | Posts unterstützen Titel (1–120 Zeichen), Inhalt (1–5.000 Zeichen), bis zu 5 Anhänge (10 MB/Bild, 5 MB/PDF) | MUSS | Unit-Test (Validierung) |
| **AC-03** | Kommentare sind 1-Ebene (keine verschachtelten Threads) | MUSS | E2E-Test (UI zeigt keine Reply-Option) |
| **AC-04** | Reaktionen: 5 vordefinierte Emoji (👍 👏 ❤️ 😊 🎺), nur 1 Reaktion pro Nutzer pro Post | MUSS | Integration-Test (Toggle-Logic) |
| **AC-05** | Maximal 3 Posts gleichzeitig pinnen; beim 4. wird Dialog zur Auswahl gezeigt | MUSS | E2E-Test (Pin-Limit) |
| **AC-06** | Umfragen: Mind. 2, max. 10 Optionen; Einzel- oder Mehrfachauswahl | MUSS | Unit-Test (Validierung) |
| **AC-07** | Umfragen können anonym oder öffentlich sein; Ergebnisse sofort oder nach Ablauf sichtbar | MUSS | Integration-Test (Sichtbarkeits-Logic) |
| **AC-08** | Push-Benachrichtigungen nur an Zielgruppe (Register-basiert oder "Alle") | MUSS | Integration-Test (FCM-Mock) |
| **AC-09** | Rate-Limiting: Max. 1 Push pro Nutzer pro Minute | MUSS | Load-Test (Spam-Prevention) |
| **AC-10** | Nutzer können Push pro Kapelle und Kategorie (Posts/Umfragen/Kommentare) deaktivieren | MUSS | E2E-Test (Einstellungen) |
| **AC-11** | Gepinnte Posts erscheinen oberhalb des chronologischen Feeds mit 📌-Badge | MUSS | E2E-Test (UI) |
| **AC-12** | Umfragen zeigen Live-Ergebnisse (außer bei "Nach Ablauf"-Einstellung) | MUSS | Integration-Test (Websocket/Polling) |
| **AC-13** | Nur Autor oder Admins können eigene Kommentare löschen (Soft-Delete) | MUSS | Integration-Test (403 für andere Nutzer) |
| **AC-14** | Post-Autor erhält Push bei neuem Kommentar (falls aktiviert), aber nicht bei Reaktionen | MUSS | Integration-Test (Selective Push) |
| **AC-15** | Nach Umfrage-Ablauf: Keine neuen Stimmen möglich, Ergebnisse final | MUSS | Integration-Test (Time-based Logic) |

---

## 4. API-Contract

**Basis-URL:** `/api/v1/kapellen/{kapelle_id}`  
**Auth:** Bearer JWT (aus MS1 Auth)  
**Pagination:** Cursor-basiert (`?cursor=...&limit=20`)  
**Fehler-Format:** JSON mit `{ "fehler": "ERROR_CODE", "nachricht": "..." }`

---

### 4.1 Posts-API

```
GET    /api/v1/kapellen/{id}/posts              → Post-Feed (Pagination)
POST   /api/v1/kapellen/{id}/posts              → Post erstellen (Admin/Dirigent/Registerführer)
GET    /api/v1/kapellen/{id}/posts/{post_id}    → Post-Details
PUT    /api/v1/kapellen/{id}/posts/{post_id}    → Post bearbeiten (nur Autor)
DELETE /api/v1/kapellen/{id}/posts/{post_id}    → Post löschen (Soft-Delete, nur Autor/Admin)
PUT    /api/v1/kapellen/{id}/posts/{post_id}/pin → Post pinnen/unpinnen (Admin/Dirigent)
```

**POST /api/v1/kapellen/{id}/posts — Request:**
```json
{
  "titel": "Wichtig: Probenausfall am 15.04.",
  "inhalt": "Aufgrund der Hallensanierung fällt die Probe am 15.04. aus. Nächster Termin ist der 22.04. wie gewohnt.",
  "anhaenge": [
    {
      "typ": "bild",
      "url": "https://cdn.sheetstorm.com/uploads/abc123.jpg",
      "groesse_bytes": 204800,
      "dateiname": "hallenplan.jpg"
    }
  ],
  "register_ids": ["uuid-klarinetten", "uuid-trompeten"],  // Optional, leer = "Alle"
  "gepinnt": false
}
```

**POST Response 201:**
```json
{
  "id": "uuid",
  "kapelle_id": "uuid",
  "autor": {
    "id": "uuid",
    "name": "Max Mustermann",
    "profilbild_url": "https://cdn.sheetstorm.com/avatars/max.jpg",
    "rolle": "Dirigent"
  },
  "titel": "Wichtig: Probenausfall am 15.04.",
  "inhalt": "Aufgrund der Hallensanierung...",
  "anhaenge": [...],
  "register_ids": ["uuid-klarinetten", "uuid-trompeten"],
  "gepinnt": false,
  "reaktionen": {},
  "kommentar_anzahl": 0,
  "erstellt_am": "2026-03-28T10:00:00Z",
  "aktualisiert_am": "2026-03-28T10:00:00Z"
}
```

**GET /api/v1/kapellen/{id}/posts — Query-Parameter:**
- `cursor` — Pagination-Cursor (optional)
- `limit` — Anzahl Posts (default: 20, max: 50)
- `gepinnt` — Filter: `true` (nur gepinnte), `false` (nur ungepinnte), leer (alle)

**GET Response 200:**
```json
{
  "posts": [
    {
      "id": "uuid",
      "autor": {...},
      "titel": "...",
      "inhalt": "...",
      "anhaenge": [...],
      "register_ids": [],
      "gepinnt": true,
      "reaktionen": {
        "👍": 12,
        "❤️": 5
      },
      "kommentar_anzahl": 8,
      "erstellt_am": "2026-03-28T10:00:00Z",
      "aktualisiert_am": "2026-03-28T10:00:00Z"
    },
    ...
  ],
  "pagination": {
    "next_cursor": "abc123xyz",
    "has_more": true
  }
}
```

**Fehlercodes:**
- `400` — Validierungsfehler (Titel leer, Inhalt zu lang, etc.)
- `403` — Musiker versucht, Post zu erstellen
- `404` — Kapelle existiert nicht
- `413` — Anhang zu groß

---

### 4.2 Kommentare-API

```
GET    /api/v1/kapellen/{id}/posts/{post_id}/kommentare     → Kommentare auflisten (Pagination)
POST   /api/v1/kapellen/{id}/posts/{post_id}/kommentare     → Kommentar erstellen
DELETE /api/v1/kapellen/{id}/posts/{post_id}/kommentare/{kommentar_id} → Kommentar löschen (Autor/Admin)
```

**POST Kommentar — Request:**
```json
{
  "text": "Schade, aber verständlich. Danke für die Info!",
  "anhang": {
    "typ": "bild",
    "url": "https://cdn.sheetstorm.com/uploads/def456.jpg",
    "groesse_bytes": 102400,
    "dateiname": "reaktion.jpg"
  }
}
```

**POST Kommentar — Response 201:**
```json
{
  "id": "uuid",
  "post_id": "uuid",
  "autor": {
    "id": "uuid",
    "name": "Anna Schmidt",
    "profilbild_url": "...",
    "rolle": "Musiker"
  },
  "text": "Schade, aber verständlich...",
  "anhang": {...},
  "erstellt_am": "2026-03-28T10:05:00Z",
  "geloescht": false
}
```

**GET Kommentare — Response 200:**
```json
{
  "kommentare": [
    {
      "id": "uuid",
      "autor": {...},
      "text": "...",
      "anhang": {...},
      "erstellt_am": "2026-03-28T10:05:00Z",
      "geloescht": false
    },
    ...
  ],
  "pagination": {
    "next_cursor": "xyz789",
    "has_more": false
  }
}
```

**Fehlercodes:**
- `400` — Text leer oder zu lang (> 1.000 Zeichen)
- `403` — Nutzer versucht, fremden Kommentar zu löschen
- `404` — Post existiert nicht

---

### 4.3 Reaktionen-API

```
PUT    /api/v1/kapellen/{id}/posts/{post_id}/reaktionen     → Reaktion setzen/ändern
DELETE /api/v1/kapellen/{id}/posts/{post_id}/reaktionen     → Reaktion entfernen
GET    /api/v1/kapellen/{id}/posts/{post_id}/reaktionen     → Nutzer auflisten, die reagiert haben
```

**PUT Reaktion — Request:**
```json
{
  "emoji": "👍"
}
```

**PUT Reaktion — Response 200:**
```json
{
  "post_id": "uuid",
  "emoji": "👍",
  "nutzer_id": "uuid",
  "erstellt_am": "2026-03-28T10:10:00Z"
}
```

**GET Reaktionen — Response 200:**
```json
{
  "reaktionen": [
    {
      "emoji": "👍",
      "nutzer": [
        { "id": "uuid", "name": "Max", "profilbild_url": "..." },
        { "id": "uuid", "name": "Anna", "profilbild_url": "..." }
      ]
    },
    {
      "emoji": "❤️",
      "nutzer": [...]
    }
  ]
}
```

**Fehlercodes:**
- `400` — Ungültiges Emoji (nicht in Whitelist: 👍 👏 ❤️ 😊 🎺)
- `404` — Post existiert nicht

---

### 4.4 Umfragen-API

```
GET    /api/v1/kapellen/{id}/umfragen                → Umfragen auflisten (Pagination)
POST   /api/v1/kapellen/{id}/umfragen                → Umfrage erstellen (Admin/Dirigent)
GET    /api/v1/kapellen/{id}/umfragen/{umfrage_id}   → Umfrage-Details
DELETE /api/v1/kapellen/{id}/umfragen/{umfrage_id}   → Umfrage löschen (nur Ersteller/Admin)
POST   /api/v1/kapellen/{id}/umfragen/{umfrage_id}/stimmen → Abstimmen
PUT    /api/v1/kapellen/{id}/umfragen/{umfrage_id}/stimmen → Stimme ändern
```

**POST Umfrage — Request:**
```json
{
  "frage": "Welcher Termin passt für die Satzprobe?",
  "optionen": [
    { "text": "Montag, 15.04. um 18:00" },
    { "text": "Mittwoch, 17.04. um 19:00" },
    { "text": "Freitag, 19.04. um 18:30" }
  ],
  "auswahltyp": "einzelauswahl",  // "einzelauswahl" | "mehrfachauswahl"
  "anonym": true,
  "ergebnisse_sichtbar": "sofort",  // "sofort" | "nach_ablauf"
  "ablauf_am": "2026-04-10T23:59:59Z",  // Optional, null = kein Ablauf
  "register_ids": ["uuid-trompeten"]  // Optional, leer = "Alle"
}
```

**POST Umfrage — Response 201:**
```json
{
  "id": "uuid",
  "kapelle_id": "uuid",
  "ersteller": {
    "id": "uuid",
    "name": "Max Mustermann",
    "rolle": "Dirigent"
  },
  "frage": "Welcher Termin passt für die Satzprobe?",
  "optionen": [
    {
      "id": "uuid",
      "text": "Montag, 15.04. um 18:00",
      "stimmen_anzahl": 0,
      "prozent": 0.0
    },
    ...
  ],
  "auswahltyp": "einzelauswahl",
  "anonym": true,
  "ergebnisse_sichtbar": "sofort",
  "ablauf_am": "2026-04-10T23:59:59Z",
  "register_ids": ["uuid-trompeten"],
  "teilnehmer_anzahl": 0,
  "hat_abgestimmt": false,
  "abgelaufen": false,
  "erstellt_am": "2026-03-28T10:00:00Z"
}
```

**POST /api/v1/kapellen/{id}/umfragen/{umfrage_id}/stimmen — Request:**
```json
{
  "option_ids": ["uuid"]  // Bei Einzelauswahl: Array mit 1 Element; bei Mehrfachauswahl: >= 1
}
```

**POST Stimme — Response 201:**
```json
{
  "umfrage_id": "uuid",
  "option_ids": ["uuid"],
  "abgestimmt_am": "2026-03-28T10:15:00Z"
}
```

**Fehlercodes:**
- `400` — Weniger als 2 Optionen, oder mehr als 10
- `400` — Ablaufdatum in der Vergangenheit
- `400` — Einzelauswahl, aber mehrere `option_ids` gesendet
- `403` — Musiker versucht, Umfrage zu erstellen
- `409` — Versuch, nach Ablauf abzustimmen
- `404` — Umfrage existiert nicht

---

### 4.5 Push-Benachrichtigungen-API

```
POST   /api/v1/push/devices                    → Push-Device registrieren (FCM/APNs Token)
DELETE /api/v1/push/devices/{device_id}        → Device deregistrieren
GET    /api/v1/push/einstellungen              → Push-Einstellungen abrufen
PUT    /api/v1/push/einstellungen              → Push-Einstellungen aktualisieren
```

**POST /api/v1/push/devices — Request:**
```json
{
  "plattform": "ios",  // "ios" | "android"
  "token": "fcm-token-abc123xyz...",
  "geraetename": "iPhone 14 Pro",
  "app_version": "1.2.0"
}
```

**POST Device — Response 201:**
```json
{
  "id": "uuid",
  "plattform": "ios",
  "token": "fcm-token-abc123xyz...",
  "registriert_am": "2026-03-28T10:00:00Z"
}
```

**PUT /api/v1/push/einstellungen — Request:**
```json
{
  "kapelle_einstellungen": [
    {
      "kapelle_id": "uuid",
      "aktiviert": true,
      "kategorien": {
        "neue_posts": true,
        "neue_umfragen": true,
        "kommentare_auf_meine_posts": true,
        "umfrage_ergebnisse": false
      }
    }
  ]
}
```

**PUT Einstellungen — Response 200:**
```json
{
  "kapelle_einstellungen": [...],
  "aktualisiert_am": "2026-03-28T10:20:00Z"
}
```

**Fehlercodes:**
- `400` — Token leer oder ungültiges Format
- `409` — Token bereits für anderen Nutzer registriert (Edge Case)

---

### 4.6 Benachrichtigungen-Versand (Internes Backend-API)

```
POST /internal/api/v1/benachrichtigungen/senden  → Benachrichtigung versenden (nur Server-zu-Server)
```

**Request:**
```json
{
  "kapelle_id": "uuid",
  "titel": "Neuer Post: Probenausfall am 15.04.",
  "body": "Aufgrund der Hallensanierung fällt die Probe am 15.04. aus...",
  "typ": "post",  // "post" | "umfrage" | "kommentar"
  "ziel_id": "uuid",  // Post-ID, Umfrage-ID, etc.
  "register_ids": ["uuid-klarinetten", "uuid-trompeten"],  // Optional, leer = "Alle"
  "sender_id": "uuid"  // Autor des Posts/Umfrage
}
```

**Response 202 (Async Processing):**
```json
{
  "benachrichtigung_id": "uuid",
  "status": "wartend",
  "empfaenger_anzahl": 42,
  "erstellt_am": "2026-03-28T10:00:00Z"
}
```

---

## 5. Datenmodell

### 5.1 Post

```sql
CREATE TABLE posts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id       UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    autor_id         UUID         NOT NULL REFERENCES musiker(id)  ON DELETE CASCADE,
    titel            VARCHAR(120) NOT NULL,
    inhalt           TEXT         NOT NULL CHECK (char_length(inhalt) <= 5000),
    gepinnt          BOOLEAN      NOT NULL DEFAULT false,
    anhaenge         JSONB,  -- Array von { typ, url, groesse_bytes, dateiname }
    register_ids     UUID[],  -- Array von Register-UUIDs, leer = "Alle"
    erstellt_am      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    geloescht_am     TIMESTAMPTZ,  -- Soft-Delete
    CONSTRAINT check_titel_nicht_leer CHECK (trim(titel) != ''),
    CONSTRAINT check_inhalt_nicht_leer CHECK (trim(inhalt) != '')
);

CREATE INDEX idx_posts_kapelle           ON posts(kapelle_id, erstellt_am DESC) WHERE geloescht_am IS NULL;
CREATE INDEX idx_posts_gepinnt           ON posts(kapelle_id, gepinnt, erstellt_am DESC) WHERE geloescht_am IS NULL;
CREATE INDEX idx_posts_register          ON posts USING GIN(register_ids) WHERE geloescht_am IS NULL;
```

---

### 5.2 Post-Kommentar

```sql
CREATE TABLE post_kommentare (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID         NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    autor_id        UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    text            VARCHAR(1000) NOT NULL,
    anhang          JSONB,  -- Optional: { typ, url, groesse_bytes, dateiname }
    erstellt_am     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    geloescht_am    TIMESTAMPTZ,  -- Soft-Delete
    CONSTRAINT check_text_nicht_leer CHECK (trim(text) != '')
);

CREATE INDEX idx_kommentare_post ON post_kommentare(post_id, erstellt_am ASC) WHERE geloescht_am IS NULL;
```

---

### 5.3 Post-Reaktion

```sql
CREATE TABLE post_reaktionen (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID         NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    nutzer_id       UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    emoji           VARCHAR(10)  NOT NULL CHECK (emoji IN ('👍', '👏', '❤️', '😊', '🎺')),
    erstellt_am     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (post_id, nutzer_id)  -- Ein Nutzer kann nur 1 Reaktion pro Post haben
);

CREATE INDEX idx_reaktionen_post ON post_reaktionen(post_id, emoji);
```

---

### 5.4 Umfrage

```sql
CREATE TABLE umfragen (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id              UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    ersteller_id            UUID         NOT NULL REFERENCES musiker(id)  ON DELETE CASCADE,
    frage                   VARCHAR(200) NOT NULL,
    auswahltyp              VARCHAR(20)  NOT NULL CHECK (auswahltyp IN ('einzelauswahl', 'mehrfachauswahl')),
    anonym                  BOOLEAN      NOT NULL DEFAULT true,
    ergebnisse_sichtbar     VARCHAR(20)  NOT NULL CHECK (ergebnisse_sichtbar IN ('sofort', 'nach_ablauf')),
    ablauf_am               TIMESTAMPTZ,  -- Optional, NULL = kein Ablauf
    register_ids            UUID[],  -- Optional, leer = "Alle"
    erstellt_am             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    aktualisiert_am         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    geloescht_am            TIMESTAMPTZ,  -- Soft-Delete
    CONSTRAINT check_frage_nicht_leer CHECK (trim(frage) != '')
);

CREATE INDEX idx_umfragen_kapelle ON umfragen(kapelle_id, erstellt_am DESC) WHERE geloescht_am IS NULL;
CREATE INDEX idx_umfragen_ablauf  ON umfragen(ablauf_am) WHERE geloescht_am IS NULL AND ablauf_am IS NOT NULL;
```

---

### 5.5 Umfrage-Option

```sql
CREATE TABLE umfrage_optionen (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    umfrage_id      UUID         NOT NULL REFERENCES umfragen(id) ON DELETE CASCADE,
    text            VARCHAR(100) NOT NULL,
    sortierung      INT          NOT NULL DEFAULT 0,
    CONSTRAINT check_option_text_nicht_leer CHECK (trim(text) != '')
);

CREATE INDEX idx_optionen_umfrage ON umfrage_optionen(umfrage_id, sortierung);
```

---

### 5.6 Umfrage-Stimme

```sql
CREATE TABLE umfrage_stimmen (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    umfrage_id      UUID         NOT NULL REFERENCES umfragen(id) ON DELETE CASCADE,
    option_id       UUID         NOT NULL REFERENCES umfrage_optionen(id) ON DELETE CASCADE,
    nutzer_id       UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    abgestimmt_am   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (umfrage_id, nutzer_id, option_id)  -- Verhindert Doppel-Abstimmung für dieselbe Option
);

CREATE INDEX idx_stimmen_umfrage ON umfrage_stimmen(umfrage_id);
CREATE INDEX idx_stimmen_nutzer  ON umfrage_stimmen(nutzer_id);
CREATE INDEX idx_stimmen_option  ON umfrage_stimmen(option_id);
```

---

### 5.7 Push-Device

```sql
CREATE TABLE push_devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nutzer_id       UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    plattform       VARCHAR(20)  NOT NULL CHECK (plattform IN ('ios', 'android')),
    token           TEXT         NOT NULL,  -- FCM/APNs Token
    geraetename     VARCHAR(100),
    app_version     VARCHAR(20),
    registriert_am  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    letzter_ping    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),  -- Für Cleanup inaktiver Devices
    aktiv           BOOLEAN      NOT NULL DEFAULT true,
    UNIQUE (token)
);

CREATE INDEX idx_push_devices_nutzer ON push_devices(nutzer_id) WHERE aktiv = true;
CREATE INDEX idx_push_devices_ping   ON push_devices(letzter_ping) WHERE aktiv = true;
```

---

### 5.8 Push-Einstellungen

```sql
CREATE TABLE push_einstellungen (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nutzer_id               UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    kapelle_id              UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    aktiviert               BOOLEAN      NOT NULL DEFAULT true,
    neue_posts              BOOLEAN      NOT NULL DEFAULT true,
    neue_umfragen           BOOLEAN      NOT NULL DEFAULT true,
    kommentare_auf_meine    BOOLEAN      NOT NULL DEFAULT true,
    umfrage_ergebnisse      BOOLEAN      NOT NULL DEFAULT false,
    aktualisiert_am         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (nutzer_id, kapelle_id)
);

CREATE INDEX idx_push_einstellungen_nutzer ON push_einstellungen(nutzer_id);
```

---

### 5.9 Benachrichtigung (für Audit-Log und In-App-History)

```sql
CREATE TABLE benachrichtigungen (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id          UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    typ                 VARCHAR(20)  NOT NULL CHECK (typ IN ('post', 'umfrage', 'kommentar')),
    ziel_id             UUID         NOT NULL,  -- Post-ID, Umfrage-ID, etc.
    titel               VARCHAR(200) NOT NULL,
    body                TEXT,
    sender_id           UUID         REFERENCES musiker(id) ON DELETE SET NULL,
    register_ids        UUID[],  -- Optional, leer = "Alle"
    erstellt_am         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_benachrichtigungen_kapelle ON benachrichtigungen(kapelle_id, erstellt_am DESC);
```

---

### 5.10 Benachrichtigung-Empfänger (für Tracking & Analytics)

```sql
CREATE TABLE benachrichtigung_empfaenger (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    benachrichtigung_id     UUID         NOT NULL REFERENCES benachrichtigungen(id) ON DELETE CASCADE,
    nutzer_id               UUID         NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
    device_id               UUID         REFERENCES push_devices(id) ON DELETE SET NULL,
    status                  VARCHAR(20)  NOT NULL DEFAULT 'wartend',  -- wartend | gesendet | zugestellt | fehlgeschlagen
    gesendet_am             TIMESTAMPTZ,
    zugestellt_am           TIMESTAMPTZ,
    geoeffnet_am            TIMESTAMPTZ,
    fehler                  TEXT,
    UNIQUE (benachrichtigung_id, nutzer_id, device_id)
);

CREATE INDEX idx_empfaenger_benachrichtigung ON benachrichtigung_empfaenger(benachrichtigung_id);
CREATE INDEX idx_empfaenger_nutzer           ON benachrichtigung_empfaenger(nutzer_id, status);
```

---

## 6. Berechtigungsmatrix

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|-------|----------|-----------|----------------|---------|
| **Posts** |  |  |  |  |  |
| Post erstellen (Alle) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Post erstellen (eigenes Register) | ✅ | ✅ | ❌ | ✅ | ❌ |
| Eigenen Post bearbeiten | ✅ | ✅ | ❌ | ✅ | ❌ |
| Fremden Post bearbeiten | ✅ | ❌ | ❌ | ❌ | ❌ |
| Eigenen Post löschen | ✅ | ✅ | ❌ | ✅ | ❌ |
| Fremden Post löschen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Post pinnen/unpinnen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Post lesen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Kommentare** |  |  |  |  |  |
| Kommentar erstellen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Eigenen Kommentar löschen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fremden Kommentar löschen | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Reaktionen** |  |  |  |  |  |
| Reaktion hinzufügen/ändern/entfernen | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Umfragen** |  |  |  |  |  |
| Umfrage erstellen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Eigene Umfrage löschen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Fremde Umfrage löschen | ✅ | ❌ | ❌ | ❌ | ❌ |
| An Umfrage teilnehmen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Umfrage-Ergebnisse sehen (bei "sofort") | ✅ | ✅ | ✅ | ✅ | ✅ |
| Umfrage-Ergebnisse sehen (bei "nach_ablauf", vor Ablauf) | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Push-Benachrichtigungen** |  |  |  |  |  |
| Push-Device registrieren | ✅ | ✅ | ✅ | ✅ | ✅ |
| Push-Einstellungen ändern | ✅ | ✅ | ✅ | ✅ | ✅ |

**Spezielle Regeln:**
- **Registerführer:** Können nur Posts für ihr zugewiesenes Register erstellen (Validierung auf Backend: `register_ids` muss ihr Register enthalten)
- **Notenwart:** Hat keine speziellen Kommunikations-Berechtigungen (entspricht Musiker)
- **Admin & Dirigent:** Sehen Umfrage-Ergebnisse immer, auch bei "nach_ablauf" vor Ablauf (für Moderationszwecke)
- **Register-spezifische Posts:** Mitglieder sehen alle Posts im Feed, erhalten aber nur Push für ihre Register

---

## 7. Edge Cases

### 7.1 Gleichzeitiges Pinnen des 4. Posts

**Szenario:** Admin A und Admin B versuchen gleichzeitig, einen 4. Post zu pinnen (während bereits 3 gepinnt sind).
- Erste Request gewinnt → 200 OK
- Zweite Request → `409 Conflict` mit `{ "fehler": "PIN_LIMIT_ERREICHT", "gepinnte_posts": ["uuid1", "uuid2", "uuid3", "uuid-neue"] }`
- Frontend zeigt Dialog: "Maximal 3 Posts können gepinnt sein. Bitte unpinne zuerst einen Post."

---

### 7.2 Post-Autor verlässt Kapelle, bevor Kommentare gelöscht sind

**Szenario:** Nutzer A erstellt Post, erhält 10 Kommentare, wird dann aus der Kapelle entfernt.
- Post bleibt bestehen, Autor-Feld zeigt "Ehemaliges Mitglied" (UI)
- Backend: `autor_id` bleibt in DB (für Audit-Zwecke), aber `ON DELETE CASCADE` ist nicht gesetzt → stattdessen Flag `geloescht_am` auf `mitgliedschaften`
- Kommentare bleiben erhalten (Historie ist wichtig)
- Nutzer A kann nach Entfernung den Post **nicht mehr bearbeiten** (403 bei PUT, da keine aktive Mitgliedschaft)

---

### 7.3 Umfrage läuft ab, während Nutzer abstimmt

**Szenario:** Nutzer öffnet Umfrage um 23:59:50, Umfrage läuft um 00:00:00 ab, Nutzer klickt "Abstimmen" um 00:00:05.
- `POST /api/v1/kapellen/{id}/umfragen/{umfrage_id}/stimmen` → `409 Conflict` mit `{ "fehler": "UMFRAGE_ABGELAUFEN" }`
- Frontend zeigt Toast: "Diese Umfrage ist abgelaufen. Deine Stimme wurde nicht gezählt."
- Client-seitig: Umfrage-Card wird automatisch auf "Abgelaufen" aktualisiert

---

### 7.4 Push-Token wird von Nutzer widerrufen (iOS/Android-Systemeinstellung)

**Szenario:** Nutzer deaktiviert Push-Berechtigung in iOS-Einstellungen.
- Bei nächstem Push-Versand: FCM/APNs liefert Fehler `InvalidRegistration` oder `NotRegistered`
- Backend: Setzt `aktiv = false` auf `push_devices` für diesen Token
- Kein User-sichtbarer Fehler — Device wird silent deaktiviert
- Monitoring-Alert bei > 5% ungültiger Tokens pro Stunde (Indikator für FCM/APNs-Probleme)

---

### 7.5 Register wird gelöscht, während Post mit diesem Register-Filter existiert

**Szenario:** Admin löscht Register "Klarinetten", aber es gibt 5 Posts mit `register_ids = ["uuid-klarinetten"]`.
- Posts bleiben bestehen, `register_ids` enthält nun "tote" UUID
- Backend: Bei Abfrage von `/api/v1/kapellen/{id}/posts` wird Filter gegen aktive Register validiert
- Frontend zeigt Badge: "🎺 Unbekanntes Register" (Graceful Degradation)
- Push-Benachrichtigungen für gelöschte Register werden **nicht mehr gesendet** (Filter auf `register WHERE geloescht_am IS NULL`)

---

### 7.6 Nutzer stimmt bei Mehrfachauswahl für dieselbe Option mehrfach ab (Race Condition)

**Szenario:** Nutzer klickt schnell 3x auf "Option A" (schlechte Netzwerkbedingungen → 3 parallele Requests).
- DB-Constraint: `UNIQUE (umfrage_id, nutzer_id, option_id)`
- Erste Request: `201 Created`
- Zweite & dritte Request: `409 Conflict` (Duplicate-Key)
- Frontend: Ignoriert 409, behandelt als erfolgreiche Abstimmung (idempotent)

---

### 7.7 Umfrage mit "Ergebnisse nach Ablauf" läuft ab, aber Admin sieht Ergebnisse vorher

**Szenario:** Umfrage läuft um 00:00:00 ab, Admin hat um 23:59:00 bereits Zwischenstand gesehen.
- Admin-Berechtigung: Darf Ergebnisse immer sehen (Berechtigungsmatrix §6)
- Beim Ablauf: Umfrage-Ergebnisse werden für **alle Nutzer** sichtbar
- Kein Mechanismus für "Admin-Zwischenstand verstecken" → Admin kann vorab reagieren (Feature, nicht Bug — Admin ist vertrauenswürdig)

---

### 7.8 Push-Rate-Limiting bei schnellen Post-Salven

**Szenario:** Dirigent erstellt 10 Posts innerhalb von 1 Minute.
- Erste 1 Minute: Nutzer X erhält nur **1 Push** (Rate-Limit: 1 Push/Nutzer/Minute)
- Backend: Aggregiert nachfolgende Posts in einen "Sammel-Push" (z.B. "5 neue Posts in [Kapellenname]")
- Nach Ablauf der Minute: Nächster Push wird normal gesendet
- Verhindert Notification-Spam und iOS/Android-Rate-Limiting

---

### 7.9 Nutzer öffnet Push, aber Post ist bereits gelöscht

**Szenario:** Nutzer erhält Push für Post, Admin löscht Post sofort, Nutzer tippt auf Push.
- App navigiert zu `/posts/{post_id}` → `404 Not Found`
- Frontend zeigt Toast: "Dieser Post wurde entfernt." und kehrt zum Feed zurück
- `geoeffnet_am` in `benachrichtigung_empfaenger` wird trotzdem gesetzt (für Analytics)

---

### 7.10 Nutzer ist in mehreren Kapellen — Push zeigt falsche Kapelle

**Szenario:** Nutzer ist in Kapelle A und B, erhält Push von Kapelle A, aber App ist gerade auf Kapelle B.
- Push-Payload enthält `kapelle_id`
- Tap auf Push: App wechselt automatisch zu Kapelle A, navigiert dann zum Post
- State-Management: Kapellen-Kontext wird vor Navigation aktualisiert

---

## 8. Abhängigkeiten

### 8.1 Funktionale Abhängigkeiten

| Feature | Abhängigkeit | Grund |
|---------|--------------|-------|
| Posts erstellen | Kapellenverwaltung (MS1) | Benötigt `kapelle_id`, Rollen-System |
| Register-Filter | Registerverwaltung (MS1) | Benötigt aktive Register-Liste |
| Push-Benachrichtigungen | Auth (MS1) | JWT für Device-Registrierung |
| Kommentare | Posts | Kommentare sind Child-Entities von Posts |
| Umfragen | Kapellenverwaltung | Benötigt Rollen-Check (nur Admin/Dirigent) |

### 8.2 Technische Abhängigkeiten

- **Cloud Storage:** Für Anhänge (Bilder, PDFs) — CDN-Integration erforderlich (z.B. AWS S3 + CloudFront)
- **Push-Provider:** FCM (Android) + APNs (iOS) — API-Keys & Zertifikate erforderlich
- **Job-Queue:** Für asynchrone Push-Benachrichtigungen (z.B. RabbitMQ, AWS SQS)
- **WebSocket (Optional):** Für Live-Updates im Feed (Alternative: Polling mit 30s-Intervall)

### 8.3 UX-Abhängigkeiten

- **UX-Design:** `docs/ux-specs/kommunikation.md` (Wanda) — muss Board-Layout, Umfrage-Design, Push-Benachrichtigungsformat definieren
- **Design-System:** Emoji-Picker, Pin-Badge, Umfrage-Card-Design benötigen Design-Tokens

---

## 9. Definition of Done

Eine Kommunikations-Implementierung gilt als **Done**, wenn alle folgenden Kriterien erfüllt sind:

### Funktional
- [ ] Alle 8 User Stories (US-01 bis US-08) vollständig implementiert
- [ ] Alle Akzeptanzkriterien (AC-01 bis AC-15) durch Tests abgedeckt
- [ ] Alle Edge Cases (7.1–7.10) implementiert und getestet
- [ ] API-Contract vollständig implementiert (alle Endpunkte aus §4)
- [ ] Berechtigungsmatrix (§6) server-seitig durchgesetzt
- [ ] Pin-Limit (3 Posts) wird konsistent durchgesetzt

### Qualität
- [ ] Unit-Test-Coverage ≥ 80% für Posts, Kommentare, Reaktionen, Umfragen
- [ ] Integration-Tests für alle API-Endpunkte (Happypath + Fehlerfälle)
- [ ] E2E-Test für vollständigen Flow: Post erstellen → Kommentieren → Reagieren → Pinnen
- [ ] E2E-Test für Umfragen: Erstellen → Abstimmen → Ergebnisse sehen → Ablauf
- [ ] E2E-Test für Push: Device registrieren → Post erstellen → Push empfangen → Tap öffnet Post
- [ ] Performance: Feed mit 100 Posts in < 500ms (API 95. Pz.)
- [ ] Performance: Umfrage-Ergebnis-Update in < 200ms nach Abstimmung
- [ ] Keine bekannten Security-Issues (OWASP Top 10 geprüft, inkl. XSS in Post-Inhalt)

### UX / Design
- [ ] UX-Review durch Wanda bestätigt, dass Flows mit `docs/ux-specs/kommunikation.md` übereinstimmen
- [ ] Feed scrollt flüssig mit 60 FPS (auch bei Bildern)
- [ ] Optimistic UI: Kommentare/Reaktionen erscheinen sofort, Fehler werden gerollt
- [ ] Fehlermeldungen sind verständlich und handlungsleitend
- [ ] WCAG 2.1 AA: Emoji sind nie alleiniger Indikator (Alternative: Text-Label)
- [ ] Touch-Targets ≥ 44×44 px (Emoji-Buttons, Pin-Button)

### Push-Benachrichtigungen
- [ ] FCM (Android) erfolgreich getestet auf 3+ Geräten
- [ ] APNs (iOS) erfolgreich getestet auf 3+ Geräten
- [ ] Push-Benachrichtigungen enthalten korrekten Deep-Link (öffnet richtigen Post/Umfrage)
- [ ] Rate-Limiting (1 Push/Nutzer/Minute) funktioniert
- [ ] Monitoring für FCM/APNs-Fehlerquote (Alert bei > 5% Fehlerrate)
- [ ] Nutzer kann Push pro Kapelle deaktivieren (Einstellungen funktionieren)

### Technisch
- [ ] Anhang-Upload unterstützt JPG, PNG, HEIF, PDF mit Größenlimits (10 MB/5 MB)
- [ ] Soft-Delete für Posts & Kommentare (kein Hard-Delete)
- [ ] DB-Migrations erstellt und getestet (inkl. Rollback-Script)
- [ ] API-Dokumentation (OpenAPI/Swagger) aktuell
- [ ] DSGVO-konform: Nutzer-Datenlöschung entfernt Push-Devices, aber Posts bleiben als "Ehemaliges Mitglied"
- [ ] Job-Queue für Push-Benachrichtigungen funktioniert (Async-Versand in < 5 Sekunden)
- [ ] Audit-Log für Admin-Aktionen (Post-Löschung, Umfrage-Löschung)

### Deployment
- [ ] Feature-Flag vorhanden (Rollout steuerbar für einzelne Kapellen)
- [ ] Monitoring-Alerts für kritische Pfade (FCM-Fehler, Umfrage-Ablauf-Job, Push-Rate-Limit)
- [ ] Changelog-Eintrag erstellt
- [ ] CDN-Integration für Anhänge getestet (Upload + Download)
- [ ] Load-Test: 1.000 gleichzeitige Nutzer im Feed (95. Pz. < 1s)

---

*Erstellt von Hill (Product Manager) · Sheetstorm MS2 · Kommunikation*
