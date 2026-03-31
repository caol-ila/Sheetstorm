# Riverpod 3.x: ref.read() nicht in onDispose-Callbacks

**By:** Romanoff  
**Date:** 2026-03-30  
**Context:** BroadcastNotifier CR#3 — musikerId-Injektion aus Auth-State

## Entscheidung

Services, die in `ref.onDispose()` / `_cleanup()`-Methoden benötigt werden, müssen als `late final`-Felder in `build()` gecacht werden — NICHT als Getter mit `ref.read()`.

## Begründung

Riverpod 3.x wirft einen AssertionError wenn `ref.read()` innerhalb eines Lifecycle-Callbacks aufgerufen wird:

```
'package:riverpod/src/core/ref.dart': Failed assertion: 
'_debugCallbackStack == 0': 
Cannot use Ref or modify other providers inside life-cycles/selectors.
```

**Falsches Muster (wirft Fehler):**
```dart
BroadcastSignalRService get _signalR => ref.read(broadcastSignalRServiceProvider);

void _cleanup() {
  _signalR.disconnect(); // Fehler: ref.read() in onDispose
}
```

**Korrektes Muster:**
```dart
late BroadcastSignalRService _signalR;

BroadcastState build() {
  _signalR = ref.read(broadcastSignalRServiceProvider); // gecacht in build()
  ref.onDispose(_cleanup);
  return const BroadcastState();
}

void _cleanup() {
  _signalR.disconnect(); // kein ref.read() mehr, gecachter Wert
}
```

## Scope

Gilt für alle `keepAlive: true` Notifier die Services in Cleanup-Methoden nutzen:
- `BroadcastNotifier` ✓ (behoben)
- Zukünftige Notifier mit ähnlichem Pattern
