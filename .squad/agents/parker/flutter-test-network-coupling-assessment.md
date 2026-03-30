# Flutter-Tests: Netzwerkkopplung Assessment

**Datum:** 2026-05-30  
**Erstellt von:** Parker (QA)  
**Issue:** #113 — Flutter-Tests ohne Provider-Overrides

---

## Betroffene Test-Dateien (nach Priorität)

### 🔴 KRITISCH — Tests schlagen ohne Mocks fehl

#### 1. `post_notifier_test.dart` ✅ BEHOBEN
- **Provider:** `postServiceProvider` → `MockPostService`
- **Problem:** 20+ Tests riefen `createPost`, `deletePost`, `togglePin`, `addReaction`, `removeReaction`, `addComment`, `deleteComment` auf und erwarteten non-null Ergebnisse (z.B. `expect(post, isNotNull)`). Ohne Mock schlug der Dio-HTTP-Call fehl → Service-Error → Notifier fing Exception → return null. Tests scheiterten.
- **Fix:** `MockPostService extends Mock implements PostService`, `ProviderContainer(overrides: [postServiceProvider.overrideWithValue(service)])`, `when()` für jede Service-Methode.

#### 2. `substitute_notifier_test.dart` ✅ BEHOBEN
- **Provider:** `substituteServiceProvider` → `MockSubstituteService`
- **Problem:** `createAccess`, `revokeAccess`, `extendExpiry` erwarteten non-null/true Ergebnisse. Ohne Mock: Dio-Fehler → null/false → Assertions scheitern.
- **Fix:** Gleiche Pattern wie post. `invocation.namedArguments[#param]` zum Zurückgeben der echten Eingabewerte (für expiresAt, eventId, note Tests).

---

### 🟡 MITTEL — Tests könnten flaky sein

#### 3. `attendance_notifier_test.dart` — OFFEN
- **Provider:** `attendanceServiceProvider`
- **Problem:** Tests wie `setDateRange`, `setEventType` prüfen lokalen State NACH Service-Aufruf. Funktionieren aktuell weil nur `isLoading: true` geprüft wird (synchroner Check vor async Response). Könnte flaky werden wenn Riverpod Verhalten sich ändert.
- **Empfehlung:** Mittelfristig ebenfalls mit `MockAttendanceService` absichern.

#### 4. `setlist_notifier_test.dart` — OFFEN
- **Provider:** `setlistServiceProvider`
- **Problem:** Expliziter Kommentar im Code: "Without a real service, this will fail". Tests prüfen `anyOf(isNull, isA<Setlist>())` als Workaround.
- **Empfehlung:** Bald fixen — zeigt bewusstes Umgehen des Problems.

---

### 🟢 NIEDRIG — Tests laufen ohne Mocks (korrekt)

#### 5. `media_link_notifier_test.dart` — KEIN HANDLUNGSBEDARF
- Nur domain model Tests (Attachment-Dauer, Plattform-Erkennung) und initial state (AsyncLoading).
- Kein CRUD wird aufgerufen, keine Ergebnisse erwartet.

#### 6. `gema_notifier_test.dart` — KEIN HANDLUNGSBEDARF
- Nur initial state (AsyncLoading) und domain model Tests.
- Notifier-Methoden werden nicht aufgerufen.

---

## Providers die Overrides brauchen

| Service Provider | Mock-Klasse | Notifier |
|---|---|---|
| `postServiceProvider` | `MockPostService` | PostListNotifier, PostDetailNotifier, PostCommentsNotifier |
| `substituteServiceProvider` | `MockSubstituteService` | SubstituteListNotifier |
| `attendanceServiceProvider` | `MockAttendanceService` | AttendanceNotifier |
| `setlistServiceProvider` | `MockSetlistService` | SetlistListNotifier, SetlistDetailNotifier |

---

## Pattern (aus event_notifier_test.dart und jetzt post/substitute)

```dart
class MockPostService extends Mock implements PostService {}

final container = ProviderContainer(
  overrides: [postServiceProvider.overrideWithValue(service)],
);
addTearDown(container.dispose);

when(() => service.getPosts(any(), pinnedOnly: any(named: 'pinnedOnly')))
    .thenAnswer((_) async => []);
```

**Wichtig bei invocation-Capture (Named Args):**
```dart
when(() => service.createAccessLink(
  any(),
  name: any(named: 'name'),
  expiresAt: any(named: 'expiresAt'),
)).thenAnswer((invocation) async {
  final expiresAt = invocation.namedArguments[#expiresAt] as DateTime?;
  return _link(access: _access(expiresAt: expiresAt));
});
```

---

## Bekannte Bugs (außerhalb Scope, aber notiert)

- `PostCommentsNotifier.refresh()` hat kein `ref.mounted`-Check nach `await` → kann "Ref disposed" Fehler werfen. Gleicher Bug wie im Spielmodus (#27) behoben.
- `PostListNotifier.createPost` kann Riverpod "disposed" Fehler werfen wenn Container vor async-Completion disposed wird.
