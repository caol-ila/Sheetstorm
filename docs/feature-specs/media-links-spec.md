# Feature-Spezifikation: Media Links

> **Issue:** TBD  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-28  
> **Status:** Bereit für Review  
> **Abhängigkeiten:** Stückverwaltung (Domain Model vorhanden)  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD (Wanda)

---

## 1. Feature-Überblick

Die **Media Links**-Funktion ermöglicht es, jedem Stück in der Notenbibliothek Referenzen zu YouTube- und Spotify-Aufnahmen hinzuzufügen. Musiker können sich das Stück während der Probenplanung oder beim Üben direkt anhören — ohne manuelles Suchen und ohne die App zu verlassen.

### 1.1 Ziel

Musiker sollen vor der Probe oder bei der Vorbereitung auf ein neues Stück schnell eine Referenzaufnahme hören können, um Tempo, Interpretation und Klangbild kennenzulernen. Registerführer und Notenwarte können gezielt die "richtige" Aufnahme verlinken — etwa eine spezifische Blasmusik-Version statt der Sinfonieorchester-Variante.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| YouTube- und Spotify-Links pro Stück | Apple Music / Deezer |
| "Anhören"-Button auf Stück-Detail | Inline-Player (Embedding) |
| Mehrere Links pro Stück | Links pro Stimme (z.B. Klarinette-Solo) |
| Automatische Metadaten via oEmbed | Playlists |
| Link-Vorschläge via Titel/Komponist (optional, AI) | Automatische Hintergrund-Synchronisation |
| Berechtigungen: Wer darf Links hinzufügen/löschen? | Zeitstempel-Marker ("Ab 1:23") |
| Deep-Linking in YouTube/Spotify-App | Partitur-Sync (Play-Along) |

### 1.3 Kontext & Technologie

**YouTube:**
- Embed-fähige URLs: `https://www.youtube.com/watch?v=VIDEO_ID` oder `https://youtu.be/VIDEO_ID`
- oEmbed API: `https://www.youtube.com/oembed?url=...&format=json` liefert Titel, Thumbnail, Dauer
- Deep-Linking: `youtube://VIDEO_ID` öffnet YouTube-App (wenn installiert)

**Spotify:**
- Web-URLs: `https://open.spotify.com/track/TRACK_ID`
- Spotify URIs: `spotify:track:TRACK_ID`
- oEmbed API: `https://open.spotify.com/oembed?url=...` liefert Titel, Künstler, Thumbnail
- Deep-Linking: `spotify:track:TRACK_ID` öffnet Spotify-App

**AI-gestützte Vorschläge (Optional):**
- API-Call: `POST /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links/vorschlaege`
- Payload: Stücktitel + Komponist → Backend nutzt YouTube Data API v3 + Spotify Search API
- Ergebnis: 3–5 vorgeschlagene Links mit Vorschau

---

## 2. User Stories

### US-01: Media Link manuell hinzufügen

> *Als Notenwart möchte ich einem Stück einen YouTube- oder Spotify-Link hinzufügen, damit Musiker eine Referenzaufnahme hören können.*

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert unabhängig von Noten-Upload oder Setlist-Features
- **N**egotiable: Inline-Player ist Out of Scope für MS2 — externer Link genügt
- **V**aluable: Musiker sparen Zeit beim Suchen und finden die "richtige" Version
- **E**stimatable: ~0.5 Sprints (Frontend + Backend + oEmbed-Integration)
- **S**mall: Nur Link-Verwaltung — keine Audio-Verarbeitung
- **T**estable: ✅ Link wird gespeichert, Metadaten abgerufen, Button ist klickbar

**Akzeptanzkriterien:**
1. Notenwart/Admin kann auf "+ Link hinzufügen" tippen (Stück-Detailseite)
2. Eingabefeld: URL (YouTube oder Spotify)
3. Nach Einfügen: Backend ruft oEmbed-Metadaten ab (Titel, Thumbnail, Dauer)
4. Metadaten werden automatisch gespeichert (kein manuelles Titel-Eingeben)
5. Der Link erscheint sofort in der Link-Liste unterhalb der Stückinfo
6. **Fehlerfall:** Ungültige URL → Validierungsfehler "Bitte gib eine gültige YouTube- oder Spotify-URL ein"
7. **Fehlerfall:** oEmbed-Abruf schlägt fehl → Link wird trotzdem gespeichert, Metadaten = null, manuell korrigierbar
8. **Fehlerfall:** Identischer Link existiert bereits → `409 Conflict` "Dieser Link ist bereits vorhanden"
9. Mehrere Links pro Stück erlaubt (z.B. 2 YouTube + 1 Spotify)
10. Link-Reihenfolge entspricht Erstellungszeitpunkt (ältester zuerst)

---

### US-02: "Anhören"-Button nutzen

> *Als Musiker möchte ich auf einen "Anhören"-Button tippen, um das Stück in YouTube oder Spotify zu öffnen, ohne manuell danach zu suchen.*

**Kriterien (INVEST):**
- **I**ndependent: Funktioniert unabhängig von anderen Features
- **N**egotiable: Inline-Player ist nicht Teil dieser Story
- **V**aluable: Direkter Zugriff ohne Kontext-Wechsel zur Suche
- **E**stimatable: ~0.3 Sprints (nur Deep-Linking)
- **S**mall: Nur Link öffnen — keine Playback-Logik
- **T**estable: ✅ Link öffnet korrekte Plattform (App oder Browser)

**Akzeptanzkriterien:**
1. "Anhören"-Button ist auf Stück-Detailseite sichtbar (wenn mindestens 1 Link existiert)
2. Button zeigt Plattform-Icon (YouTube/Spotify) + Titel des Links
3. Tap öffnet den Link:
   - **Mobile (iOS/Android):** Versucht Deep-Link (`youtube://`, `spotify:`) → Falls App nicht installiert: Öffnet Browser-URL
   - **Desktop/Web:** Öffnet Browser-URL in neuem Tab
4. Wenn mehrere Links existieren: Alle werden als Liste angezeigt (jeder mit eigenem "Anhören"-Button)
5. Setlist-Einträge: Zeigen kompakten "🎧"-Button neben dem Stücknamen (öffnet Auswahl-Dialog, falls mehrere Links)
6. **Fehlerfall:** Link nicht mehr verfügbar (z.B. YouTube-Video gelöscht) → Browser zeigt YouTube-Fehlerseite — kein Frontend-Error

---

### US-03: AI-gestützte Link-Vorschläge (Optional)

> *Als Notenwart möchte ich Vorschläge für YouTube-/Spotify-Links erhalten, damit ich nicht manuell nach Aufnahmen suchen muss.*

**Kriterien (INVEST):**
- **I**ndependent: Kann unabhängig von manueller Link-Eingabe existieren
- **N**egotiable: Vollautomatische Verknüpfung (ohne Bestätigung) ist Out of Scope
- **V**aluable: Spart Zeit bei der Ersteinrichtung neuer Stücke
- **E**stimatable: ~1 Sprint (Backend-Integration YouTube Data API + Spotify Search API)
- **S**mall: Nur Vorschläge — keine automatische Übernahme
- **T**estable: ✅ Vorschläge sind relevant (mind. 1 Treffer bei >80% der Test-Stücke)

**Akzeptanzkriterien:**
1. Notenwart/Admin kann auf "Vorschläge anfordern" tippen (Stück-Detailseite)
2. Backend nutzt Stücktitel + Komponist für API-Suche
3. YouTube: Top 3 Ergebnisse (nach Relevanz & View Count)
4. Spotify: Top 3 Tracks (nach Popularity)
5. Frontend zeigt Vorschau: Thumbnail, Titel, Künstler/Uploader, Dauer
6. Notenwart kann einen oder mehrere Vorschläge per Checkbox auswählen + "Hinzufügen"
7. Ausgewählte Links werden als reguläre Media Links gespeichert (mit `vorgeschlagen_von_ai: true`)
8. **Fehlerfall:** Keine Treffer → "Keine Vorschläge gefunden. Bitte füge manuell einen Link hinzu."
9. **Fehlerfall:** API-Rate-Limit erreicht → "Vorschläge temporär nicht verfügbar. Versuche es in 10 Minuten erneut."
10. Rate-Limiting: Max. 10 Vorschlag-Anfragen pro Kapelle/Stunde (serverseitig)

---

### US-04: Media Link löschen

> *Als Notenwart möchte ich einen veralteten oder falschen Link entfernen, damit Musiker nicht auf falsche Aufnahmen zugreifen.*

**Kriterien (INVEST):**
- **I**ndependent: Standard CRUD-Operation
- **N**egotiable: Soft-Delete ist Out of Scope — Hard-Delete genügt
- **V**aluable: Fehlerkorrektur und Datenqualität
- **E**stimatable: ~0.2 Sprints
- **S**mall: Nur DELETE-Endpunkt + UI
- **T**estable: ✅ Link verschwindet nach Löschung

**Akzeptanzkriterien:**
1. Notenwart/Admin kann auf "🗑️" neben einem Link tippen
2. Bestätigungs-Dialog: "Möchtest du diesen Link wirklich entfernen?"
3. Nach Bestätigung: Link wird sofort gelöscht (Hard-Delete)
4. Audit-Log-Eintrag: "Wer hat wann welchen Link gelöscht"
5. **Fehlerfall:** Nur Berechtigte können löschen (siehe §6 Berechtigungsmatrix) — Musiker sehen kein 🗑️-Icon

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Testmethode |
|----|-----------|-------------|
| AC-01 | YouTube- und Spotify-URLs werden korrekt geparst und validiert | Unit-Test: URL-Parser |
| AC-02 | oEmbed-Metadaten (Titel, Thumbnail, Dauer) werden automatisch abgerufen und gespeichert | Integration-Test: Mock oEmbed-APIs |
| AC-03 | Deep-Linking öffnet YouTube/Spotify-App (wenn installiert) oder Browser | E2E-Test: Mobile (iOS/Android) |
| AC-04 | Mehrere Links pro Stück sind möglich (keine Unique-Constraint auf `stueck_id`) | DB-Test: 3 Links für dasselbe Stück einfügen |
| AC-05 | Identische URLs werden erkannt und abgelehnt | API-Test: Doppelter POST → 409 Conflict |
| AC-06 | AI-Vorschläge liefern mind. 1 relevanten Treffer für 80% der Test-Stücke | Integration-Test: 100 reale Stücke |
| AC-07 | Rate-Limiting für AI-Vorschläge funktioniert (max. 10/Stunde/Kapelle) | API-Test: 11. Request → 429 Too Many Requests |
| AC-08 | Links ohne gültige Metadaten (oEmbed-Fehler) werden trotzdem gespeichert | Unit-Test: Null-Metadaten-Handling |
| AC-09 | "Anhören"-Button ist nur sichtbar, wenn mind. 1 Link existiert | UI-Test: Conditional Rendering |
| AC-10 | Berechtigungen werden serverseitig durchgesetzt (siehe §6) | API-Test: Musiker versucht POST → 403 |

---

## 4. API-Contract

**Base Path:** `/api/v1/kapellen/{kapelle_id}/stuecke/{stueck_id}/media-links`  
**Auth:** Bearer JWT (alle Endpunkte erfordern Authentifizierung)

### 4.1 Media Links CRUD

```
POST   /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links              → Link hinzufügen
GET    /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links              → Links eines Stücks
DELETE /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links/{link_id}   → Link löschen
POST   /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links/vorschlaege  → AI-Vorschläge (Optional)
```

---

### 4.2 POST — Link hinzufügen

**POST /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links**

**Request:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Response 201:**
```json
{
  "id": "uuid",
  "stueck_id": "uuid",
  "plattform": "youtube",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "titel": "Rick Astley - Never Gonna Give You Up",
  "thumbnail_url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
  "dauer_sekunden": 212,
  "vorgeschlagen_von_ai": false,
  "erstellt_am": "2026-03-28T12:00:00Z",
  "erstellt_von": "uuid"
}
```

**Fehlercodes:**
- `400` — Validierungsfehler: URL ungültig oder kein YouTube/Spotify
- `403` — Nicht berechtigt (nur Admin/Dirigent/Notenwart/Registerführer)
- `404` — Stück nicht gefunden
- `409` — Link existiert bereits für dieses Stück
- `502` — oEmbed-Abruf fehlgeschlagen (Link wird trotzdem gespeichert, Metadaten = null)

---

### 4.3 GET — Links eines Stücks abrufen

**GET /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links**

**Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "plattform": "youtube",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "titel": "Rick Astley - Never Gonna Give You Up",
      "thumbnail_url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      "dauer_sekunden": 212,
      "vorgeschlagen_von_ai": false,
      "erstellt_am": "2026-03-28T12:00:00Z"
    },
    {
      "id": "uuid",
      "plattform": "spotify",
      "url": "https://open.spotify.com/track/4PTG3Z6ehGkBFwjybzWkR8",
      "titel": "Never Gonna Give You Up - Rick Astley",
      "thumbnail_url": "https://i.scdn.co/image/ab67616d0000b273...",
      "dauer_sekunden": 213,
      "vorgeschlagen_von_ai": true,
      "erstellt_am": "2026-03-28T12:05:00Z"
    }
  ],
  "gesamt": 2
}
```

**Fehlercodes:**
- `403` — Nicht berechtigt (Nutzer ist kein Mitglied der Kapelle)
- `404` — Stück nicht gefunden

---

### 4.4 DELETE — Link löschen

**DELETE /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links/{link_id}**

**Response 204:** (No Content)

**Fehlercodes:**
- `403` — Nicht berechtigt (nur Admin/Dirigent/Notenwart/Registerführer)
- `404` — Link oder Stück nicht gefunden

---

### 4.5 POST — AI-Vorschläge anfordern (Optional)

**POST /api/v1/kapellen/{id}/stuecke/{stueck_id}/media-links/vorschlaege**

**Request:** (leer — nutzt Stückdaten aus DB)

**Response 200:**
```json
{
  "vorschlaege": [
    {
      "plattform": "youtube",
      "url": "https://www.youtube.com/watch?v=xyz123",
      "titel": "Star Wars Main Theme - John Williams",
      "thumbnail_url": "https://i.ytimg.com/vi/xyz123/hqdefault.jpg",
      "dauer_sekunden": 330,
      "uploader": "London Symphony Orchestra",
      "relevanz_score": 0.95
    },
    {
      "plattform": "spotify",
      "url": "https://open.spotify.com/track/abc456",
      "titel": "Star Wars: Main Title",
      "thumbnail_url": "https://i.scdn.co/image/...",
      "dauer_sekunden": 328,
      "kuenstler": "John Williams, London Symphony Orchestra",
      "relevanz_score": 0.92
    }
  ],
  "gesamt": 5,
  "query": "Star Wars Main Theme John Williams"
}
```

**Fehlercodes:**
- `403` — Nicht berechtigt
- `404` — Stück nicht gefunden
- `422` — Stücktitel oder Komponist fehlt → "Bitte füge zuerst Titel und Komponist hinzu, um Vorschläge zu erhalten"
- `429` — Rate-Limit erreicht (max. 10/Stunde/Kapelle)
- `502` — YouTube/Spotify API nicht erreichbar → "Vorschläge temporär nicht verfügbar"

---

## 5. Datenmodell

### 5.1 Media Links

```sql
CREATE TABLE media_links (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    stueck_id             UUID        NOT NULL REFERENCES stuecke(id) ON DELETE CASCADE,
    plattform             VARCHAR(20) NOT NULL CHECK (plattform IN ('youtube', 'spotify')),
    url                   TEXT        NOT NULL,
    titel                 TEXT,                      -- automatisch via oEmbed
    thumbnail_url         TEXT,                      -- automatisch via oEmbed
    dauer_sekunden        INTEGER,                   -- automatisch via oEmbed
    vorgeschlagen_von_ai  BOOLEAN     DEFAULT FALSE,
    erstellt_am           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    erstellt_von          UUID        NOT NULL REFERENCES musiker(id),
    
    CONSTRAINT unique_link_per_stueck UNIQUE (stueck_id, url)
);

CREATE INDEX idx_media_links_stueck ON media_links(stueck_id);
CREATE INDEX idx_media_links_plattform ON media_links(plattform);
```

**Design-Entscheidungen:**
- **`ON DELETE CASCADE`:** Wenn ein Stück gelöscht wird, werden alle zugehörigen Links automatisch entfernt
- **`UNIQUE (stueck_id, url)`:** Verhindert doppelte Links für dasselbe Stück
- **Nullable Metadaten:** Falls oEmbed-Abruf fehlschlägt, werden Links trotzdem gespeichert (titel, thumbnail_url, dauer_sekunden = NULL)
- **`vorgeschlagen_von_ai`:** Ermöglicht spätere Analysen zur Qualität der AI-Vorschläge

---

### 5.2 Rate-Limiting (Optional — für AI-Vorschläge)

```sql
CREATE TABLE media_link_vorschlaege_rate_limit (
    kapelle_id    UUID        NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    zeitfenster   TIMESTAMPTZ NOT NULL,  -- Stunden-Bucket (z.B. 2026-03-28 12:00:00)
    anzahl        INTEGER     DEFAULT 0,
    
    PRIMARY KEY (kapelle_id, zeitfenster)
);

CREATE INDEX idx_rate_limit_zeitfenster ON media_link_vorschlaege_rate_limit(zeitfenster);
```

**Cleanup-Job:** Einträge älter als 24h werden stündlich gelöscht.

---

## 6. Berechtigungsmatrix

> **Prinzip:** Nur Personen mit Verwaltungsrechten (Admin, Dirigent, Notenwart, Registerführer) können Links hinzufügen/löschen. Alle Mitglieder können Links sehen und nutzen.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|
| **Media Links** | | | | | |
| Link hinzufügen | ✅ | ✅ | ✅ | ✅ | ❌ |
| Link löschen | ✅ | ✅ | ✅ | ✅ | ❌ |
| Link ansehen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Link nutzen ("Anhören") | ✅ | ✅ | ✅ | ✅ | ✅ |
| AI-Vorschläge anfordern | ✅ | ✅ | ✅ | ✅ | ❌ |

**Rationale:**
- **Musiker können nicht hinzufügen/löschen:** Verhindert versehentliche oder mutwillige Änderungen an der offiziellen Referenz
- **Registerführer darf verwalten:** Hat Verantwortung für sein Register und sollte passende Aufnahmen kuratieren können

---

## 7. Edge Cases

### 7.1 oEmbed-Abruf schlägt fehl

**Szenario:** YouTube-Video ist privat gesetzt oder Spotify-API antwortet mit 404.

**Verhalten:**
- Link wird trotzdem in der DB gespeichert (`titel`, `thumbnail_url`, `dauer_sekunden` = NULL)
- Response: `201 Created` mit `"metadaten_status": "fehlgeschlagen"`
- Frontend zeigt Platzhalter: "📹 YouTube-Link (Metadaten nicht verfügbar)"
- Admin/Notenwart kann später Metadaten manuell nachpflegen (Future: Retry-Button)

---

### 7.2 URL-Format-Varianten

**Szenario:** Nutzer gibt YouTube-Short-URL oder Spotify-URI ein.

**Unterstützte Formate:**
- YouTube: `https://www.youtube.com/watch?v=VIDEO_ID`, `https://youtu.be/VIDEO_ID`, `https://m.youtube.com/watch?v=VIDEO_ID`
- Spotify: `https://open.spotify.com/track/TRACK_ID`, `spotify:track:TRACK_ID`

**Normalisierung:** Backend extrahiert VIDEO_ID / TRACK_ID und speichert kanonische URL.

**Nicht unterstützt (→ 400 Bad Request):**
- YouTube-Playlists: `https://www.youtube.com/playlist?list=...`
- Spotify-Alben: `https://open.spotify.com/album/...`
- Zeitstempel-URLs: `https://youtu.be/VIDEO_ID?t=123` → **MS2:** Zeitstempel wird ignoriert; **MS3:** Separate Spalte `start_sekunde`

---

### 7.3 Link zu gelöschtem Video/Track

**Szenario:** YouTube-Video wird vom Uploader gelöscht, Spotify-Track nicht mehr verfügbar.

**Verhalten:**
- Link bleibt in Sheetstorm bestehen (kein automatisches Löschen)
- Beim Klick auf "Anhören" → YouTube/Spotify zeigt eigene Fehlerseite ("Video nicht verfügbar")
- **MS3:** Optional: Wöchentlicher Background-Job prüft URLs und markiert tote Links

---

### 7.4 Mehrere Links — Sortierung

**Szenario:** Ein Stück hat 5 YouTube-Links und 2 Spotify-Links.

**Verhalten:**
- Standard-Sortierung: Erstellungszeitpunkt (ältester zuerst)
- Frontend gruppiert optional nach Plattform: "YouTube (5)" / "Spotify (2)"
- Kein Favoriten-System in MS2 — alle Links sind gleichwertig

---

### 7.5 Stück wird gelöscht

**Szenario:** Admin löscht ein Stück, das 3 Media Links hat.

**Verhalten:**
- Alle zugehörigen Links werden automatisch gelöscht (`ON DELETE CASCADE`)
- Kein Soft-Delete — Links sind nicht wiederherstellbar
- Audit-Log: "Stück [Titel] gelöscht → 3 Media Links entfernt"

---

### 7.6 Rate-Limit bei AI-Vorschlägen

**Szenario:** Notenwart fordert innerhalb 1 Stunde 11x Vorschläge an.

**Verhalten:**
- Request 1–10: `200 OK` mit Vorschlägen
- Request 11: `429 Too Many Requests`
- Response Body: `{ "fehler": "RATE_LIMIT", "retry_nach_sekunden": 3420 }`
- Frontend zeigt: "Limit erreicht. Verfügbar ab 13:30 Uhr."

---

### 7.7 Identische URL, unterschiedliche Stücke

**Szenario:** Notenwart fügt denselben YouTube-Link zwei verschiedenen Stücken hinzu (z.B. Medley mit 2 Einzelstücken).

**Verhalten:**
- Erlaubt — `UNIQUE (stueck_id, url)` verhindert nur Duplikate *innerhalb* eines Stücks
- Zwei DB-Einträge mit gleicher URL, aber unterschiedlichen `stueck_id`

---

### 7.8 Deep-Linking schlägt fehl

**Szenario:** iOS-Nutzer hat YouTube-App nicht installiert.

**Verhalten:**
- App versucht `youtube://VIDEO_ID`
- iOS erkennt: Schema nicht registriert → Fallback zu `https://www.youtube.com/watch?v=...`
- Browser öffnet sich automatisch (kein manueller Eingriff nötig)

---

## 8. Abhängigkeiten

| Abhängigkeit | Typ | Status | Details |
|--------------|-----|--------|---------|
| Stückverwaltung (Domain Model) | Backend | ✅ Vorhanden | `stuecke`-Tabelle mit `id`, `titel`, `komponist` |
| oEmbed-APIs (YouTube, Spotify) | Externe API | ⚠️ API-Keys nötig | YouTube Data API v3, Spotify oEmbed |
| Deep-Linking-Framework | Mobile | 📋 Zu klären | iOS: Universal Links, Android: App Links |
| Audit-Log-System | Backend | ✅ Vorhanden | Aus Kapellenverwaltung wiederverwendbar |
| Rate-Limiting-Middleware | Backend | 📋 Zu implementieren | Generisch für alle Features nutzbar |

**Blockers:**
- API-Keys für YouTube Data API v3 und Spotify Web API müssen vor Implementierung beantragt werden
- Deep-Linking-Setup erfordert App-Store-Konfiguration (Apple App Site Association, Android assetlinks.json)

---

## 9. Definition of Done

Eine Media-Links-Implementierung gilt als **Done**, wenn alle folgenden Kriterien erfüllt sind:

### Funktional
- [ ] Alle 4 User Stories (US-01 bis US-04) vollständig implementiert
- [ ] Alle Akzeptanzkriterien (AC-01 bis AC-10) durch Tests abgedeckt
- [ ] Alle Edge Cases (7.1–7.8) implementiert und getestet
- [ ] API-Contract vollständig implementiert (alle Endpunkte aus §4)
- [ ] Berechtigungsmatrix (§6) server-seitig durchgesetzt

### Qualität
- [ ] Code-Coverage: Mind. 80% für neue Backend-Logik
- [ ] E2E-Tests: Link hinzufügen → Anhören-Button → Deep-Linking (iOS + Android)
- [ ] Performance: oEmbed-Abruf < 2s (bei 95% der Requests)
- [ ] Performance: AI-Vorschläge < 5s (bei 90% der Requests)

### Dokumentation
- [ ] API-Docs aktualisiert (Swagger/OpenAPI)
- [ ] oEmbed-Integration dokumentiert (inkl. Error-Handling)
- [ ] Deep-Linking-Setup dokumentiert (iOS + Android)
- [ ] Nutzer-Hilfe: "Wie füge ich einen Link hinzu?" (FAQ)

### Deployment
- [ ] API-Keys für YouTube/Spotify sicher gespeichert (Environment Variables)
- [ ] Rate-Limiting-Middleware deployed und getestet
- [ ] Monitoring: Alert bei >10% oEmbed-Fehlerrate
- [ ] Monitoring: Alert bei API-Rate-Limit-Überschreitung

### UX/UI
- [ ] Wanda hat UX-Flows reviewed und freigegeben
- [ ] "Anhören"-Button ist barrierefrei (ARIA-Labels)
- [ ] Responsive Design: Desktop, Tablet, Mobile
- [ ] Dark-Mode-Support für Link-Vorschauen

### Sicherheit & Compliance
- [ ] OWASP: URL-Injection-Prevention (nur YouTube/Spotify erlaubt)
- [ ] DSGVO: Audit-Log enthält Link-Verwaltung
- [ ] Keine Speicherung von API-Keys im Client-Code

---

## 10. Open Questions

| # | Frage | Owner | Status |
|---|-------|-------|--------|
| Q1 | Sollen YouTube-Playlists unterstützt werden (MS3)? | Hill | 📋 Offen |
| Q2 | Inline-Player vs. nur externe Links? | Wanda | 📋 Zu diskutieren |
| Q3 | Zeitstempel-Marker ("Springe zu 1:23") für MS3? | Banner | 📋 Offen |
| Q4 | Apple Music / Deezer / Amazon Music? | Hill | ⏳ MS4+ |
| Q5 | Link-Vorschläge ohne AI (nur API-Suche)? | Banner | 📋 Zu diskutieren |
| Q6 | Favoriten-System (ein Link als "primär" markieren)? | Wanda | ⏳ MS3 |

---

**Ende der Feature-Spezifikation Media Links**
