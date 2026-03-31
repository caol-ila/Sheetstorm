# MS2 Nacharbeit — Priorisierter Arbeitsplan

**Erstellt:** Stark (Lead / Architect)
**Datum:** 2025-07-17
**Quelle:** 22 Post-Merge Issues (#100–#121) + 10 Code-Review-Empfehlungen (`docs/reviews/ms2-code-review.md`)

---

## Deduplizierung: Issues ↔ Code-Review-Empfehlungen

| Code-Review-Empfehlung | Überlappt mit Issue | Aktion |
|------------------------|---------------------|--------|
| CR#6 MembershipGuard als shared Service | #108 DRY Auth-Helper | **Zusammengelegt** → #108 |
| CR#8 BroadcastSignalRService StreamController schließen | #107 dispose() nie aufgerufen | **Zusammengelegt** → #107 |
| CR#1 Navigator.pushNamed → GoRouter | #102 state.extra Deep Links | **Zusammengelegt** → #102 (GoRouter-Migration umfasst beide) |

**Eigenständige CR-Items (kein Issue-Pendant):**
- CR#2: Duplicate Author-Klasse + markNeedsBuild → StatefulBuilder
- CR#3: Hardcoded musikerId '' aus Auth-State injizieren
- CR#4: Production-CORS-Policy konfigurierbar
- CR#5: Rate-Limiting für Substitute-Token-Validation
- CR#7: Pagination für Listen-Endpoints
- CR#9: Error-Code-Konsistenz (BAND_NOT_FOUND → FORBIDDEN)
- CR#10: Frontend-Integration-Tests für kritische User-Journeys

---

## Batch 1 — P0: Sofort (Kaputtes Feature)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| CR#3 | Hardcoded `musikerId: ''` aus Auth-State injizieren | **Romanoff** | — | 0.5 Tage | 3× hardcoded leerer String mit TODO. Broadcast-Join funktioniert nicht ohne echte Musiker-ID. Aus Auth-Provider (`ref.read(authProvider).musikerId`) injizieren. Dateien: `broadcast_screen.dart`, `broadcast_controls.dart`. |

> **Begründung P0:** Broadcast-Join ist ein Kern-Feature von MS2 (Setlist-Broadcast). Ohne echte musikerId ist die Funktion komplett kaputt.

---

## Batch 2 — P1: Hoch (Crash-Potential, Datenintegrität, fehlende Validierungen)

### Frontend (Romanoff)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #102 + CR#1 | state.extra Deep Links + GoRouter-Migration | **Romanoff** | — | 1 Tag | `state.extra` in Substitute/Shift-Routes durch Path/Query-Parameter ersetzen. Alle `Navigator.pushNamed` (3 Stellen) auf `context.go()`/`context.push()` migrieren. Subsumiert auch #106 (Event-Subrouten) und CR#1. Stellt Auth-Redirect und Deep-Link-Handling sicher. |
| #104 | Event.fromJson crasht bei fehlendem `erstellt_von` | **Romanoff** | — | 0.25 Tage | Null-Check für optionale Backend-Felder: `json['erstellt_von'] as String? ?? ''`. Defensives Parsing in allen Event-Models prüfen. |
| #103 | bandId als leerer String bei fehlenden Query-Parametern | **Romanoff** | — | 0.25 Tage | `state.uri.queryParameters['bandId'] ?? ''` → Validierung: wenn leer, redirect zur Band-Auswahl oder Error-State. Nicht still leeren String weitergeben. |
| #107 (= CR#8) | BroadcastSignalRService.dispose() + StreamController | **Romanoff** | — | 0.5 Tage | 5 StreamControllers werden bei keepAlive:true nie geschlossen. `disconnect()` muss alle Streams schließen. Prüfen ob keepAlive wirklich nötig oder ob Provider-Lifecycle reicht. |
| CR#2 | Duplicate Author-Klasse + markNeedsBuild → StatefulBuilder | **Romanoff** | — | 0.5 Tage | (a) `Author`-Klasse aus `poll_models.dart` und `post_models.dart` in `shared/author_model.dart` extrahieren. (b) 3× `(context as Element).markNeedsBuild()` in Shift/Substitute-Screens durch `StatefulBuilder` ersetzen (Flutter-Antipattern, Crash-Risiko). |

### Backend (Banner)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #111 | ShiftService: StartTime < EndTime Validierung | **Banner** | — | 0.25 Tage | `if (request.StartTime >= request.EndTime) throw BadRequest("StartTime must be before EndTime")` in `CreateShiftAsync` und `UpdateShiftAsync`. Analog zu EventService-Pattern. TDD: Test zuerst. |
| #112 | PostService: ParentCommentId Existenz-Check | **Banner** | — | 0.5 Tage | Vor dem Erstellen eines Comments: (1) ParentCommentId existiert, (2) ParentComment gehört zum gleichen Post. Sonst 404/400. TDD: Test zuerst. |
| #109 | Fehlende MaxLength Attribute in Request-Modellen | **Banner** | — | 0.5 Tage | `[MaxLength(200)]` auf Title, `[MaxLength(5000)]` auf Content, etc. in allen MS2-Request-DTOs. Damit Model-Validation 400 statt DB-Exception 500 liefert. Systematisch alle Request-Records durchgehen. |
| #110 | PostService: Soft-Delete inkonsistent | **Banner** | — | 0.5 Tage | **Design-Entscheidung nötig (Stark):** Comments sind soft-deleted (`IsDeleted`), Posts sind hard-deleted. Empfehlung: Alles Soft-Delete mit `DeletedAt` Timestamp. Posts mit Kindern: Content nullen, Hülle behalten. Posts ohne Kinder: hard-delete OK. Konsistent dokumentieren. |

### Tests (Parker)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #115 | Fehlende Tests: Post-Reply auf fremden Parent | **Parker** | #112 muss zuerst | 0.25 Tage | Test: `CreateCommentAsync_WithParentFromDifferentPost_ThrowsNotFound`. Cross-Post-Reply Szenario verifizieren. |
| #114 | Fehlende Tests: GEMA-Export ungültiges Format | **Parker** | — | 0.25 Tage | Tests für den bereits gefixten null/ungültigen format-Parameter: `ExportReport_NullFormat_Returns400`, `ExportReport_InvalidFormat_Returns400`. |

---

## Batch 3 — P2: Code Quality (DRY, Architektur, Konsistenz)

### Backend (Strange / Banner)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #108 (= CR#6) | DRY Auth-Helper → IAuthorizationService | **Strange** | — | 1 Tag | `RequireMembershipAsync` und `RequireConductorOrAdminAsync` aus 10+ Services in einen `IBandAuthorizationService` extrahieren. Single Responsibility. DI-registrieren als Scoped. Alle Services refactoren. Tests anpassen. |
| CR#7 | Pagination für Listen-Endpoints | **Strange** | #108 zuerst (weniger Merge-Konflikte) | 2 Tage | Cursor-basierte Pagination (nicht Offset) für alle Listen-Endpoints: Events, Posts, Comments, Setlists, Shifts, etc. Spec sieht `/api/v1/` mit Cursor-Pagination vor. `PagedResult<T>` mit `cursor`, `hasMore`, `pageSize`. |
| CR#4 | Production-CORS-Policy konfigurierbar | **Banner** | — | 0.5 Tage | CORS-Origins aus `appsettings.json` / Umgebungsvariable lesen statt `AllowAnyOrigin()`. Für Dev: `*`, für Prod: konfigurierte Origins. |
| CR#5 | Rate-Limiting für Substitute-Token-Validation | **Banner** | — | 1 Tag | Rate-Limiting auf Token-Validation-Endpoint (`/api/v1/substitute/validate`). Analog zu Auth-Endpoints. Brute-Force-Schutz für Aushilfen-Tokens. |
| CR#9 | Error-Code-Konsistenz | **Banner** | — | 0.5 Tage | Vereinheitlichung: `BAND_NOT_FOUND` bei fehlender Membership → `FORBIDDEN` (OWASP: keine Existenz-Leaks). Alle Error-Responses systematisch durchgehen. |

### Frontend (Romanoff)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #101 | Systematisches copyWith-Problem bei nullable Feldern | **Romanoff** | — | 1 Tag | Akute Fälle (Broadcast, Attendance) sind gefixt. Restliche Models identifizieren und konsistentes Sentinel-Pattern (`_undefined`) oder Freezed-Migration anwenden. Architektur-Entscheidung: Sentinel vs. Freezed. |
| #100 | broadcastRoutes fragiler Integrations-Muster | **Romanoff** | #102 zuerst | 0.5 Tage | Absolute Pfade + `.builder!` Force-Unwrap refactoren. Relative Pfade, null-safe builder-Zugriff. Kann mit GoRouter-Migration (#102) zusammen gemacht werden. |
| #105 | AttendanceNotifier: AsyncValue statt eigenem State | **Romanoff** | — | 0.5 Tage | Refactoring auf `AsyncNotifier` oder konsistentes `AsyncValue`-Pattern. Fehler-Handling mit `.catchError` oder `.when()` statt silent failure. |
| #106 | Event-Subrouten unter /app/events verschachteln | **Romanoff** | #102 zuerst | 0.25 Tage | Strukturelle Route-Verschachtelung. Wird teilweise durch GoRouter-Migration (#102) abgedeckt. Restliche Event-Subrouten (attendance, shifts, substitute) unter `/app/events/:eventId/` verschachteln. |

### Tests (Parker)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #113 | Flutter-Tests: Provider-Overrides einführen | **Parker** | — | 1 Tag | Alle netzwerkgekoppelten Widget-Tests auf Provider-Overrides umstellen. Mock-Services via `ProviderScope(overrides: [...])`. Fundament für alle weiteren Frontend-Tests. |
| #118 + #117 | Setlist-Tests: Assertions + Empty-State | **Parker** | — | 0.5 Tage | (a) `expect(true, isTrue)` durch aussagekräftige Assertions ersetzen (Feld-Vergleiche, State-Checks). (b) Tests für leere Setlist: `isLast` bei 0 Items, Navigation bei leerer Liste. |
| #116 | Fehlende Tests: Attendance Filter-Reset | **Parker** | #101 zuerst (copyWith-Fix) | 0.25 Tage | Tests für Filter-Reset nach copyWith-Fix: `resetFilter_ClearsAllFields`, `filterByStatus_ThenReset_ShowsAll`. |

---

## Batch 4 — P3: Nice-to-have (Accessibility, Kosmetik, Erweiterungen)

| Issue | Titel | Agent | Abhängigkeiten | Aufwand | Beschreibung |
|-------|-------|-------|----------------|---------|--------------|
| #119 | Hardcoded Colors.white → Theme-Farben | **Romanoff** | — | 0.25 Tage | Alle `Colors.white` und `Colors.black` durch `Theme.of(context).colorScheme.onPrimary` / `.onSurface` ersetzen. Dark-Mode-kompatibel. |
| #120 | Accessibility: Semantics-Labels nachrüsten | **Romanoff** | — | 0.5 Tage | `Semantics(label: ...)` für RSVP-Buttons, Broadcast-Controls, Attendance-Charts. Systematisch in eigenem PR. |
| #121 | ISO-Wochennummer korrekt berechnen | **Romanoff** | — | 0.25 Tage | Näherung `(dayOfYear / 7).ceil()` durch korrekte ISO-8601-Berechnung ersetzen. `package:intl` oder getestete Utility-Funktion. |
| CR#10 | Frontend-Integration-Tests | **Parker** | #113 zuerst | 2 Tage | Integration-Tests für kritische User-Journeys: Event erstellen → RSVP → Attendance, Setlist erstellen → Broadcast starten, Post erstellen → Kommentieren. |

---

## Abhängigkeitsgraph

```
CR#3 (musikerId)          ──→ kann sofort starten

#102+CR#1 (GoRouter)      ──→ kann sofort starten
  └─→ #100 (broadcastRoutes)   wartet auf #102
  └─→ #106 (Event-Subrouten)   wartet auf #102

#112 (ParentCommentId)    ──→ kann sofort starten
  └─→ #115 (Tests dazu)        wartet auf #112

#101 (copyWith Sentinel)  ──→ kann sofort starten
  └─→ #116 (Tests dazu)        wartet auf #101

#108 (DRY Auth-Helper)    ──→ kann sofort starten
  └─→ CR#7 (Pagination)        wartet auf #108

#113 (Provider-Overrides) ──→ kann sofort starten
  └─→ CR#10 (Integration-Tests) wartet auf #113

Alle anderen Issues/CRs   ──→ können parallel starten
```

---

## Zusammenfassung nach Agent

| Agent | Batch 1 | Batch 2 | Batch 3 | Batch 4 | Gesamt |
|-------|---------|---------|---------|---------|--------|
| **Romanoff** (Frontend) | CR#3 | #102+CR#1, #104, #103, #107, CR#2 | #101, #100, #105, #106 | #119, #120, #121 | ~6 Tage |
| **Banner** (Backend) | — | #111, #112, #109, #110 | CR#4, CR#5, CR#9 | — | ~4 Tage |
| **Strange** (Principal Backend) | — | — | #108, CR#7 | — | ~3 Tage |
| **Parker** (Tests) | — | #115, #114 | #113, #118+#117, #116 | CR#10 | ~4.5 Tage |

**Gesamtaufwand:** ~17.5 Tage (parallelisiert auf ~6 Tage bei 4 Agents gleichzeitig)

---

## Reihenfolge-Empfehlung

1. **Sofort starten (parallel):** CR#3 (Romanoff), #111+#112+#109 (Banner), #113 (Parker)
2. **Danach:** #102+CR#1 (Romanoff), #110 (Banner), #108 (Strange), #114+#115 (Parker)
3. **Dann:** Restliche P2-Items, abhängige Tests
4. **Zuletzt:** P3-Items wenn Zeit bleibt

> **Stark's Empfehlung:** Batch 1 + Batch 2 vor MS3-Start abschließen. Batch 3 kann parallel zu MS3-Beginn laufen. Batch 4 ist optional und kann bei Bedarf in MS3 integriert werden.
