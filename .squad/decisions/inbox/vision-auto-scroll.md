# Decision: Auto-Scroll Architecture

**By:** Vision (Principal Frontend Engineer)  
**Date:** 2026-04-16  
**Feature:** Auto-Scroll / Reflow (MS3)

## Decisions

### 1. Separate Runtime State from Persistent Settings
- `AutoScrollNotifier` manages runtime state (idle/playing/paused, current speed, current mode)
- `AutoScrollSettingsNotifier` manages persistent defaults (SharedPreferences)
- **Reason:** Runtime state resets on each session. Settings persist across app restarts. Mixing them would cause stale state or unnecessary persistence writes.

### 2. Speed Calculation lives in State, not Notifier
- `AutoScrollState.calculateManualSpeed()` and `calculateBpmSpeed()` are pure methods on the state object
- **Reason:** Pure functions are trivially testable. No need for notifier access or async.

### 3. Widget Tests use `UncontrolledProviderScope` for Riverpod 3.x codegen
- `overrideWithValue` on codegen `@riverpod` notifier providers throws in Riverpod 3.x
- All widget tests use `UncontrolledProviderScope(container: ...)` with a real `ProviderContainer`
- **Reason:** Codegen notifiers extend `$Notifier` which requires proper lifecycle. Direct value overrides bypass this.

### 4. Control Bar is always-visible when active (UX §2.2)
- Bar appears at bottom of Stack, 48px height
- Page dots hidden while bar is visible to avoid overlap
- **Reason:** Per UX spec, controls stay visible (subtle) during scroll — no hide-after-timeout.

### 5. Pause-on-Touch wired through gesture layer
- `PageGestureDetector.onNextPage` / `onPreviousPage` call `autoScrollNotifier.onUserInteraction()` before page navigation
- **Reason:** Respects user's manual override intent (UX §5.4 Option A).

## Open Items for Team
- BPM-Metronom-Kopplung: needs integration once Metronom feature is ready (MS3)
- Page-Flip (seitenweise) mode: not yet implemented, needs separate scroll controller logic
- Vorlauf-Takte: calculation exists in state model, UI integration pending
