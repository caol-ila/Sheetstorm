# Frontend Code Review — Vision (Principal Frontend Engineer)
**Datum:** 2026-03-29T00:11:00Z
**Reviewer:** Vision
**Model:** claude-opus-4.6
**Scope:** Frontend (Flutter Features, Core, Shared)

## Zusammenfassung

Die MS2-Flutter-Codebasis zeigt eine **gut strukturierte, feature-modulare Architektur** mit konsistenter Layering (application/data/presentation). Die Design-Token-Infrastruktur ist vorbildlich, das Theme-System professionell, und die Annotation-Engine mit CustomPainter/RepaintBoundary/Stylus-Engine ist auf Principal-Level. Es gibt jedoch **mehrere kritische Issues** — insbesondere duplizierte Author-Klassen, hardcoded Strings in der Broadcast-UI, fehlende Route-Definitionen und `(context as Element).markNeedsBuild()`-Antipatterns — die vor dem Merge behoben werden müssen.

---

## Kritische Issues (MUST FIX vor Merge)

### K1: Duplizierte `Author`-Klasse in Communication-Models
- **Datei:** `lib/features/communication/data/models/poll_models.dart` (Zeile 22–49)
- **Zweite Instanz:** `lib/features/communication/data/models/post_models.dart` (Zeile 66–92)
- **Problem:** Zwei identische `Author`-Klassen in separaten Dateien im selben Feature-Modul. Das führt zu Import-Konflikten, wenn beide Models im selben Scope verwendet werden (z.B. in `board_screen.dart`, das sowohl Posts als auch Polls anzeigt).
- **Fix:** `Author` in eine gemeinsame Datei extrahieren (z.B. `lib/features/communication/data/models/author_model.dart`) und in beiden Model-Dateien importieren.
- **Begründung:** Compile-Fehler oder Namespace-Konflikte bei gleichzeitigem Import. Verstößt gegen DRY-Prinzip.

### K2: Hardcoded leere `musikerId: ''` in BroadcastReceiverScreen
- **Datei:** `lib/features/song_broadcast/presentation/screens/broadcast_receiver_screen.dart`
- **Zeilen:** 98, 241, 412
- **Problem:** `joinSession(musikerId: '')` und `leaveSession(musikerId: '')` werden mit leerem String aufgerufen. Der Backend-Service erwartet eine echte Musiker-ID. Ohne korrekte ID werden Session-Joins nicht funktionieren, und der Dirigent sieht keine Musiker.
- **Fix:** Die aktuelle Musiker-ID aus dem Auth-State oder User-Provider injizieren. Beispiel: `ref.read(authProvider).user.musicianId` oder ein dedizierter `currentMusicianIdProvider`.
- **Begründung:** Feature-Blockierung — Broadcast-Beitritt für Musiker funktioniert nicht.

### K3: `(context as Element).markNeedsBuild()` Antipattern
- **Datei:** `lib/features/shifts/presentation/screens/shift_plan_screen.dart` (Zeilen 178, 196)
- **Datei:** `lib/features/substitute/presentation/screens/substitute_management_screen.dart` (Zeile 192)
- **Problem:** Direktes Casting von `BuildContext` zu `Element` und Aufruf von `markNeedsBuild()` innerhalb eines Dialogs. Das ist ein Dart-Antipattern: es bricht die Widget-Abstraktion, funktioniert nicht zuverlässig in allen Szenarien (z.B. nach Widget-Disposal) und kann zu Framework-Exceptions führen.
- **Fix:** Die Dialog-Form mit einem `StatefulBuilder` wrappen, sodass `setState` innerhalb des Dialogs lokal funktioniert:
  ```dart
  StatefulBuilder(builder: (context, setDialogState) {
    // ...
    onTap: () async {
      final time = await showTimePicker(...);
      if (time != null) setDialogState(() => startTime = ...);
    },
  })
  ```
- **Begründung:** Kann zu Runtime-Crashes führen. Flutter-Team empfiehlt explizit gegen dieses Pattern.

### K4: Fehlende Route `/substitute/qr` im Router
- **Datei:** `lib/features/substitute/presentation/screens/substitute_management_screen.dart` (Zeile 359)
- **Problem:** `Navigator.pushNamed(context, '/substitute/qr', ...)` wird aufgerufen, aber die Route ist in `substitute/routes.dart` nicht definiert. Dort existieren nur `substitutes` und `substitute/link`. Die QR-Code-Ansicht wird einen RouteNotFound-Fehler auslösen.
- **Fix:** Route in `substitute/routes.dart` hinzufügen:
  ```dart
  GoRoute(
    path: 'substitute/qr',
    builder: (context, state) => QRCodeScreen(access: state.extra as SubstituteAccess),
  ),
  ```
  Oder die Navigation auf GoRouter-Syntax umstellen: `context.push(...)`.
- **Begründung:** Runtime-Error bei QR-Code-Anzeige.

### K5: Inkonsistente Navigation — `Navigator.pushNamed` vs. GoRouter
- **Dateien:**
  - `lib/features/shifts/presentation/screens/shift_plan_screen.dart` (Zeile 265): `Navigator.pushNamed(context, '/shift/detail', ...)`
  - `lib/features/substitute/presentation/screens/substitute_management_screen.dart` (Zeile 237): `Navigator.pushNamed(context, '/substitute/link', ...)`
  - `lib/features/substitute/presentation/screens/substitute_management_screen.dart` (Zeile 359): `Navigator.pushNamed(context, '/substitute/qr', ...)`
- **Problem:** Die gesamte App verwendet GoRouter (`context.push()`, `context.go()`), aber diese drei Stellen verwenden `Navigator.pushNamed()`. Das umgeht die GoRouter-Middleware (Auth-Redirect, Deep-Link-Handling) und die Routes werden nicht aufgelöst, da GoRouter eigene Route-Definitionen verwendet.
- **Fix:** Alle `Navigator.pushNamed`-Aufrufe durch GoRouter-Äquivalente ersetzen. Für `state.extra`-Passing: `context.push('/path', extra: data)`.
- **Begründung:** Navigation-Bruch — diese Routen werden im laufenden Betrieb fehlschlagen.

### K6: `broadcastRoutes` Integration im Router ist fragil
- **Datei:** `lib/core/routing/app_router.dart` (Zeilen 271–275)
- **Datei:** `lib/features/song_broadcast/routes.dart` (Zeilen 10–23)
- **Problem:** `broadcastRoutes` wird als `GoRoute` mit absolutem Pfad `/app/band/:bandId/broadcast` definiert, aber im Router wird er relativ eingebettet:
  ```dart
  GoRoute(
    path: 'broadcast',
    builder: (context, state) => broadcastRoutes.builder!(context, state),
    routes: broadcastRoutes.routes,
  ),
  ```
  Der äußere GoRoute hat `path: 'broadcast'` (relativ), aber `broadcastRoutes` definiert den absoluten Pfad. Das `builder!`-Force-Unwrap auf `.builder` ist gefährlich — GoRouter erlaubt `null` builder, und der absolute Pfad in `broadcastRoutes` kollidiert mit der relativen Einbettung.
- **Fix:** `broadcastRoutes` sollte relative Pfade verwenden oder direkt als Sub-Routes definiert werden, ohne den äußeren Wrapper:
  ```dart
  // In routes.dart:
  final broadcastRoutes = [
    GoRoute(path: 'broadcast', builder: ..., routes: [
      GoRoute(path: 'join', builder: ...),
    ]),
  ];
  // In app_router.dart:
  ...broadcastRoutes,
  ```
- **Begründung:** Potentieller Runtime-Crash durch `builder!` und Path-Mismatch.

### K7: `AttendanceNotifier.build()` startet async Arbeit ohne `await`
- **Datei:** `lib/features/attendance/application/attendance_notifier.dart` (Zeile 63)
- **Problem:** `_loadData()` wird im `build()` aufgerufen, aber nicht awaited. Da `build()` synchron `AttendanceDashboardState` zurückgibt, läuft `_loadData()` als fire-and-forget. Wenn `_loadData()` fehlschlägt, bevor `state` aktualisiert wird, gibt es kein Error-Handling. Außerdem: `DateTime(now.year, now.month - 3, now.day)` (Zeile 56) — bei Januar liefert `month - 3` den Wert `-2`, was von Dart zwar korrekt gehandhabt wird (September des Vorjahres), aber schwer lesbar ist.
- **Fix:** Entweder den Notifier als `AsyncNotifier` implementieren (empfohlen), oder `_loadData()` explizit mit `.catchError` absichern. Für das Datum: `DateTime(now.year, now.month - 3, now.day)` durch `now.subtract(Duration(days: 90))` ersetzen (klarer).
- **Begründung:** Silent failures beim initialen Laden der Attendance-Daten.

---

## Empfehlungen (SHOULD — nice-to-have)

### E1: Fehlende Semantics/Accessibility in Annotation-Toolbar
- **Datei:** `lib/features/annotations/presentation/widgets/annotation_toolbar.dart`
- **Problem:** `_ToolbarButton` hat `Tooltip` aber keine `Semantics`-Widgets. Screen Reader können die Buttons nicht korrekt identifizieren. Besonders kritisch für blinde Musiker (Accessibility-Anforderung im UX-Spec).
- **Fix:** `Semantics(label: label, button: true, ...)` um die Buttons wrappen.

### E2: Keine Pagination in Post/Poll-Listen
- **Datei:** `lib/features/communication/application/post_notifier.dart` (Zeile 14)
- **Datei:** `lib/features/communication/data/services/post_service.dart` (Zeile 27–28)
- **Problem:** `PostService.getPosts()` akzeptiert `cursor` und `limit` Parameter, aber `PostListNotifier.build()` übergibt diese nie. Bei vielen Posts wird die gesamte Liste geladen.
- **Fix:** Cursor-basierte Pagination implementieren (z.B. mit Riverpod `keepAlive + loadMore` Pattern oder einem `InfiniteScrollNotifier`).

### E3: `PostDetailScreen` setzt `timeago`-Locale bei jedem Build
- **Datei:** `lib/features/communication/presentation/screens/post_detail_screen.dart` (Zeile 137)
- **Problem:** `timeago.setLocaleMessages('de', timeago.DeMessages())` wird bei jedem `build()` aufgerufen. Das ist unnötig — die Locale-Registrierung sollte einmalig in `main()` erfolgen.
- **Fix:** In `main.dart` einmalig konfigurieren: `timeago.setLocaleMessages('de', timeago.DeMessages());`

### E4: `CalendarScreen._ListView` sortiert Entries in-place
- **Datei:** `lib/features/events/presentation/screens/calendar_screen.dart` (Zeile 301)
- **Problem:** `entries.sort(...)` mutiert die Liste direkt. Da `entries` aus dem Provider kommt, wird der State direkt verändert. Das kann zu subtilen Bugs führen.
- **Fix:** `final sorted = [...entries]..sort(...)` verwenden.

### E5: Hardcoded Dark-Mode-Farben in Annotation-Toolbar
- **Datei:** `lib/features/annotations/presentation/widgets/annotation_toolbar.dart` (Zeilen 188, 274)
- **Problem:** `Colors.black.withOpacity(0.85)`, `Colors.white70`, `Colors.white24` sind hardcoded. Im Dark Mode der App würde ein schwarzer Toolbar-Hintergrund mit dem Scaffold verschmelzen. Die Toolbar hat kein Theme-Awareness.
- **Fix:** Theme-abhängige Farben verwenden oder die Annotation-Toolbar explizit für beide Modi stylen.

### E6: Fehlende Loading-Skeleton/Shimmer-Effekte
- **Dateien:** Alle Screens verwenden `CircularProgressIndicator()` für Loading-States.
- **Problem:** Die UX-Specs empfehlen Skeleton/Shimmer für Content-Loading. Aktuell gibt es überall nur Spinner.
- **Fix:** Ein `SkeletonCard`/`ShimmerListTile` Widget in `shared/widgets/` erstellen und in allen Listen-Screens verwenden.

### E7: `BroadcastSignalRService` Stream-Controller werden nicht in `disconnect()` geschlossen
- **Datei:** `lib/features/song_broadcast/data/services/broadcast_service.dart`
- **Problem:** `disconnect()` (Zeile 180) schließt die StreamController nicht. `dispose()` (Zeile 236) tut das, wird aber nie aufgerufen, da der Service als `keepAlive: true` Provider existiert. Die StreamController bleiben immer offen.
- **Fix:** Entweder `dispose()` in `ref.onDispose()` des Providers registrieren, oder die Controller in `disconnect()` schließen und in `connect()` neu erstellen.

### E8: `_ConnectionSummary` zeigt falschen Status
- **Datei:** `lib/features/song_broadcast/presentation/screens/broadcast_control_screen.dart` (Zeile 347)
- **Problem:** `'✓ Alle bereit (${broadcastState.connectedCount}/${broadcastState.connectedCount})'` — Zähler/Nenner sind identisch, was immer "alle bereit" suggeriert. Es gibt keine Unterscheidung zwischen "verbunden" und "bereit" (ready vs. loading/error).
- **Fix:** Den tatsächlichen "ready count" aus `connectedMusicians` berechnen und getrennt darstellen.

### E9: `AppDatabase` hat keine Web-Kompatibilität
- **Datei:** `lib/shared/database/app_database.dart`
- **Problem:** `NativeDatabase` und `dart:io` werden verwendet, was auf Web nicht funktioniert. Das Projekt hat Web-Assets (`web/` Verzeichnis), also muss Web-Kompatibilität berücksichtigt werden.
- **Fix:** Conditional Imports für Web verwenden (z.B. `package:drift/wasm.dart` für Web-Target).

### E10: Fehlende `const` Constructors bei einigen Widgets
- **Dateien:** Diverse
- **Problem:** `analysis_options.yaml` hat `prefer_const_constructors: true` aktiviert, aber einige Widgets nutzen `const` nicht optimal:
  - `BoardScreen` Zeile 94: `backgroundColor: Colors.transparent` in FilterChip ist nicht const-fähig
  - `PostDetailScreen` Zeile 229: `BoxDecoration` mit `AppColors.background` (ist const, wird aber in Container verwendet der nicht const ist)
- **Fix:** Wo möglich `const` hinzufügen. Lint-Runner sollte hier helfen.

### E11: Fehlende `dispose()` für `_commentController` bei Error-State
- **Datei:** `lib/features/communication/presentation/screens/post_detail_screen.dart` (Zeile 31)
- **Problem:** `_commentController` wird korrekt in `dispose()` entsorgt. Jedoch: wenn der `postAsync` Provider einen Error-State hat, wird der `_commentController` nie benutzt, aber trotzdem erstellt. Das ist kein Leak, aber verschwendete Ressource.
- **Fix:** `TextEditingController` lazy initialisieren oder nur erstellen wenn `postAsync.hasValue`.

### E12: `communication/routes.dart` hat potenziellen Route-Konflikt
- **Datei:** `lib/features/communication/routes.dart` (Zeilen 31–43)
- **Problem:** Route `':bandId/polls/:pollId'` und `':bandId/polls/create'` sind gleichrangig. GoRouter resolved `create` als `:pollId` bevor die statische Route matched wird. D.h. der Poll-Detail-Screen wird mit `pollId = 'create'` aufgerufen.
- **Fix:** Die statische Route `create` vor die dynamische Route `:pollId` platzieren:
  ```dart
  GoRoute(path: ':bandId/polls/create', ...),
  GoRoute(path: ':bandId/polls/:pollId', ...),
  ```

---

## Positives

- **Exzellente Design-Token-Architektur:** `AppColors`, `AppSpacing`, `AppTypography`, `AppShadows`, `AppDurations`, `AppCurves` — alles sauber als `abstract final class` mit UX-Spec-Referenzen in den Kommentaren. Touch-Targets ≥ 44px werden systematisch eingehalten (`AppSpacing.touchTargetMin`).

- **Professionelles Theme-System:** Light/Dark Mode korrekt implementiert mit Material 3 (`useMaterial3: true`), konsistenten ColorSchemes und platform-spezifischen Page-Transitions.

- **Annotation-Engine auf hohem Niveau:** `AnnotationPainter` + `DrawingPainter` Separation ist 60fps-optimiert. RepaintBoundary für persistierte Annotations, ValueListenableBuilder für aktive Zeichnung. Pressure-Sensitivity, Palm Rejection, Stylus-Detection — das ist production-ready für Tablet-use.

- **Saubere Feature-Modularisierung:** Konsistente `application/data/presentation` Layering in jedem Feature. Clean Separation of Concerns. Models haben `fromJson`/`toJson`/`copyWith`.

- **Auth-Interceptor mit Mutex-Pattern:** `_AuthInterceptor` in `api_client.dart` implementiert Token-Refresh mit `Completer`-basiertem Mutex korrekt — concurrent 401s triggern nur einen Refresh.

- **Broadcast-SignalR-Service:** Manuelle SignalR-JSON-Protokoll-Implementation ist clever gelöst. Reconnect mit exponential backoff, Heartbeat-Timer, sauberes Stream-basiertes Event-System.

- **Undo/Redo in Annotations:** Command-Pattern korrekt implementiert mit `UndoAction` Stack und bidirektionalem Redo.

- **GoRouter-Auth-Redirect:** Saubere State-Machine für Auth-Routing (Loading → Authenticated/Unauthenticated → Email-Pending). Public Routes korrekt definiert.

- **Responsive Layout-Ansätze:** Broadcast-Screen hat `LayoutBuilder` mit 720px Breakpoint für Sidebar-Layout. Annotation-Toolbar wechselt zwischen horizontal (Phone) und vertikal (Tablet-Landscape). Calendar hat Month/Week/List Views.

- **Konsistente Error-States:** Die meisten Features implementieren den Loading → Data → Error Lifecycle korrekt mit `AsyncValue.when()`.

---

## Bewertung

- **State Management:** ⭐⭐⭐⭐ / Riverpod wird konsistent verwendet (mix aus codegen `@riverpod` und manuellen `NotifierProvider`). `AsyncNotifier` Pattern ist gut. Abzug: AttendanceNotifier ist synchroner Notifier mit async fire-and-forget; Annotation-Notifier ist manuell statt codegen. Kein unnötiges Rebuilding erkennbar — `ref.watch` vs `ref.read` korrekt eingesetzt.

- **Error Handling:** ⭐⭐⭐½ / Error-States existieren in allen Features mit `AsyncValue.when()`. Benutzerfreundliche deutsche Fehlermeldungen. Abzug: Keine Retry-Buttons in Poll-Error-State (Board), AttendanceNotifier swallowed errors, BroadcastSignalRService Reconnect hat kein User-Feedback, Export-Fehler geben nur `null` zurück ohne Fehlermeldung.

- **UI/UX-Konsistenz:** ⭐⭐⭐⭐ / Design-Tokens werden überall verwendet. GoRouter-Navigation ist größtenteils konsistent (Ausnahme: K5). Dark-Mode-Support im Theme komplett, aber Annotation-Toolbar hat hardcoded Farben. Touch-Targets eingehalten. Empty-States sind vorhanden.

- **Accessibility:** ⭐⭐½ / `Tooltip`-Widgets vorhanden, aber keine `Semantics`-Widgets in kritischen Bereichen (Annotation-Toolbar, RSVP-Buttons, Broadcast-Status). Keine `ExcludeSemantics`/`MergeSemantics` für komplexe Widgets. Keyboard-Navigation nicht explizit getestet/implementiert. Focus-Management fehlt.

- **Performance:** ⭐⭐⭐⭐½ / Annotation-Engine: RepaintBoundary + separate DrawingPainter = 60fps. `shouldRepaint` korrekt implementiert. `ListView.builder` in Listen-Screens (Shifts, Substitute). `const` Constructors werden größtenteils genutzt. `List.unmodifiable` für Annotation-Points. Abzug: Keine Pagination in Communication-Listen, `entries.sort()` mutiert Provider-State in-place.

- **Code-Qualität:** ⭐⭐⭐⭐ / Saubere Naming Conventions (camelCase, PascalCase), konsistente Datei-/Ordner-Struktur, gut extrahierte Widget-Klassen. Models sind immutable mit `copyWith`. Null Safety durchgängig. Abzug: Duplicate Author-Klasse, `markNeedsBuild`-Antipattern, gemischte Navigation-APIs.
