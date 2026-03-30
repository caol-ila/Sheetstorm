# Banner Decision: Cloud-Sync Backend

**Datum:** 2026-03-30
**Von:** Banner (Backend Developer)
**Status:** Umgesetzt

---

## Entscheidung: API-Route-Struktur

**Spezifikation (feature-spec):** `/api/v1/sync/meine-musik/delta`
**Protokoll-Spec (Stark):** `/api/sync/state`, `/api/sync/push`, `/api/sync/pull`
**Implementiert:** `/api/sync/{state|pull|push|resolve}`

**Begründung:** Starks Protokoll-Spec ist die technisch verbindliche Quelle für das Backend-API. Die Feature-Spec enthält Entwürfe (v1, meine-musik), die Protokoll-Spec ist die finale Version. Außerdem gilt die Projekt-Konvention "kein Version-Segment in Routes" (`/api/` direkt, kein `/api/v1/`).

**Team-Impakt:** Flutter-Client (Romanoff) muss Endpoints auf `/api/sync/...` (ohne v1 und ohne `meine-musik`) konfigurieren.

---

## Entscheidung: SyncChangelog statt SyncChangelogs (Tabellenname)

Die EF-Entity heißt `SyncChangelog` (Singular), der DbSet `SyncChangelogs` (Plural). Standard ASP.NET Core EF-Konvention.

---

## Entscheidung: LWW-Granularität auf Feld-Ebene

Last-Write-Wins wird pro `(EntityId, FieldName)` geprüft — nicht pro Entity. Das bedeutet: gleichzeitige Änderungen an `title` und `composer` desselben Stücks verursachen **keinen** Konflikt. Nur wenn dasselbe Feld zweimal geändert wurde und der Server die neuere Änderung hat, gibt es einen ServerWins-Konflikt.

Dies entspricht exakt der Protokoll-Spec (§ LWW per field).

---

## Offene Fragen für das Team

1. **Entity-Mutations im Push:** Die aktuelle Implementierung speichert Änderungen nur im Changelog, wendet sie aber **nicht** automatisch auf die `Piece`/`Voice`/`PiecePage`-Entities an. Für einen voll funktionsfähigen Sync muss die Flutter-App beim Pull die Änderungen selbst anwenden (Drift). Soll das Backend die Entities auch live mutieren? → Abklärung mit Romanoff.

2. **Band.IsPersonal — Seeder:** `Band.IsPersonal = true` ist in der Entity vorhanden, aber der `DemoDataSeeder` erstellt noch keine persönliche Band beim User-Setup. → Parker/Romanoff informieren.

3. **`resolve`-Endpoint:** Derzeit nimmt `POST /api/sync/resolve` explizite Resolutions entgegen und speichert sie als neue Changelog-Einträge. Die Flutter-Seite muss diesen Endpoint nicht zwingend nutzen (LWW passiert automatisch beim Push). Relevant nur wenn UI-seitig explizite Konfliktanzeige gewünscht wird.
