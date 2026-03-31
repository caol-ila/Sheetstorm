# Decision: GoRouter-Navigation ohne state.extra — PendingProvider-Pattern

**Datum:** 2026-03-31
**Agent:** Romanoff
**Issue:** #102 / CR#1

## Kontext

Beim Navigieren zu `SubstituteLinkScreen` nach der Erstellung eines Zuganglinks musste ein `SubstituteLink`-Objekt übergeben werden. Das bisherige `state.extra` bricht Deep Links und App-State-Wiederherstellung.

## Entscheidung

Für transiente Navigationsdaten, die nicht als URL-Parameter serialisiert werden können, wird ein dedizierter Riverpod-Notifier als temporärer "Puffer" verwendet:

```dart
// pending_substitute_link_provider.dart (eigene Datei!)
@riverpod
class PendingSubstituteLink extends _$PendingSubstituteLink {
  @override
  SubstituteLink? build() => null;
  void set(SubstituteLink? link) => state = link;
}

// Navigation im Screen:
ref.read(pendingSubstituteLinkProvider.notifier).set(link);
context.push('/app/band/$bandId/substitute/link');

// Route liest aus Provider:
final link = ref.watch(pendingSubstituteLinkProvider);
if (link == null) { /* pop zurück */ }
```

## Begründung

- **Serialisierbare Objekte → path/query params** (z.B. `shiftId`, `accessId`)
- **Nicht-serialisierbare Objekte (frisch erstellt, transient) → PendingProvider**
- Alternativen:
  - `state.extra` beibehalten → bricht Deep Links
  - Im Screen nachfetchen → unnötiger API-Call für Daten, die schon im RAM sind

## Konsequenz

- PendingProvider immer in eigener `.dart`-Datei (nicht in Codegen-Dateien mit `part`)
- Route-Builder muss null-Guard haben und bei null `context.pop()` aufrufen
- `keepAlive: false` für PendingProvider (kein Grund zum Persistieren)
