// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/application/performance_mode_notifier.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// Helper: builds a ProviderContainer with a PerformanceModeNotifier for [sheetId]
/// and waits for the initial async load to complete.
Future<(ProviderContainer, PerformanceModeNotifier)> _makeNotifier(
  String sheetId,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // Listen to keep the autoDispose provider alive
  final sub = container.listen(performanceModeProvider(sheetId), (_, __) {});
  addTearDown(sub.close);

  final notifier = container.read(performanceModeProvider(sheetId).notifier);
  // Wait for _loadSheetMusic (100 ms delay in implementation)
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return (container, notifier);
}

PerformanceModeState _state(ProviderContainer c, String id) =>
    c.read(performanceModeProvider(id));

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('PerformanceModeNotifier — initial load', () {
    test('starts in loading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(performanceModeProvider('test'), (_, __) {});
      addTearDown(sub.close);
      final state = container.read(performanceModeProvider('test'));
      expect(state.isLoading, isTrue);
    });

    test('loads 8 pages and selects default stimme', () async {
      final (container, _) = await _makeNotifier('stk-1');
      final state = _state(container, 'stk-1');

      expect(state.isLoading, isFalse);
      expect(state.totalPages, 8);
      expect(state.pages, hasLength(8));
      expect(state.currentVoiceId, 'kl2');
      expect(state.voices, hasLength(7));
    });

    test('first page is page 0 on load', () async {
      final (container, _) = await _makeNotifier('stk-2');
      expect(_state(container, 'stk-2').currentPage, 0);
    });
  });

  // ─── Page Navigation ─────────────────────────────────────────────────────

  group('PerformanceModeNotifier — singlePage navigation', () {
    test('nextPage increments currentPage', () async {
      final (container, notifier) = await _makeNotifier('nav-1');
      notifier.nextPage();
      expect(_state(container, 'nav-1').currentPage, 1);
    });

    test('previousPage decrements currentPage', () async {
      final (container, notifier) = await _makeNotifier('nav-2');
      notifier.nextPage();
      notifier.previousPage();
      expect(_state(container, 'nav-2').currentPage, 0);
    });

    test('previousPage on first page triggers haptic, does not go negative',
        () async {
      final (container, notifier) = await _makeNotifier('nav-3');
      notifier.previousPage();
      expect(_state(container, 'nav-3').currentPage, 0);
    });

    test('nextPage on last page in single piece triggers haptic (no crash)',
        () async {
      final (container, notifier) = await _makeNotifier('nav-4');
      // Navigate to last page (totalPages = 8, so index 7)
      for (int i = 0; i < 10; i++) {
        notifier.nextPage();
      }
      expect(_state(container, 'nav-4').currentPage, lessThanOrEqualTo(7));
    });

    test('goToPage sets page directly', () async {
      final (container, notifier) = await _makeNotifier('nav-5');
      notifier.goToPage(5);
      expect(_state(container, 'nav-5').currentPage, 5);
    });

    test('goToPage clamps to valid range', () async {
      final (container, notifier) = await _makeNotifier('nav-6');
      notifier.goToPage(100);
      expect(_state(container, 'nav-6').currentPage, 0); // invalid → no change
    });

    test('goToPage resets halfPageStep to 0', () async {
      final (container, notifier) = await _makeNotifier('nav-7');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.nextPage(); // goes to halfPageStep=1
      notifier.goToPage(3);
      expect(_state(container, 'nav-7').halfPageStep, 0);
    });
  });

  // ─── Half-Page-Turn ───────────────────────────────────────────────────────

  group('PerformanceModeNotifier — halfPageTurn mode (AC-13..AC-20)', () {
    test('first nextPage in halfPageTurn sets halfPageStep=1', () async {
      final (container, notifier) = await _makeNotifier('hpt-1');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.nextPage();
      final state = _state(container, 'hpt-1');
      expect(state.halfPageStep, 1);
      expect(state.currentPage, 0); // page not advanced yet
    });

    test('second nextPage in halfPageTurn advances page, resets step', () async {
      final (container, notifier) = await _makeNotifier('hpt-2');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.nextPage(); // step → 1
      notifier.nextPage(); // step → 0, page → 1
      final state = _state(container, 'hpt-2');
      expect(state.currentPage, 1);
      expect(state.halfPageStep, 0);
    });

    test('previousPage in halfPageTurn from step=1 resets step without page change',
        () async {
      final (container, notifier) = await _makeNotifier('hpt-3');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.nextPage(); // step=1
      notifier.previousPage(); // should go back to step=0
      final state = _state(container, 'hpt-3');
      expect(state.halfPageStep, 0);
      expect(state.currentPage, 0);
    });

    test('previousPage from step=0 moves back a page and sets step=1', () async {
      final (container, notifier) = await _makeNotifier('hpt-4');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.goToPage(3);
      notifier.previousPage(); // from page=3, step=0 → page=2, step=1
      final state = _state(container, 'hpt-4');
      expect(state.currentPage, 2);
      expect(state.halfPageStep, 1);
    });

    test('setViewMode resets halfPageStep to 0', () async {
      final (container, notifier) = await _makeNotifier('hpt-5');
      notifier.setViewMode(ViewMode.halfPageTurn);
      notifier.nextPage(); // step=1
      notifier.setViewMode(ViewMode.singlePage);
      expect(_state(container, 'hpt-5').halfPageStep, 0);
    });
  });

  // ─── Two-Page Navigation ────────────────────────────────────────────────

  group('PerformanceModeNotifier — twoPage mode', () {
    test('nextPage in twoPage advances by 2', () async {
      final (container, notifier) = await _makeNotifier('tp-1');
      notifier.setViewMode(ViewMode.twoPage);
      notifier.nextPage();
      expect(_state(container, 'tp-1').currentPage, 2);
    });

    test('previousPage in twoPage goes back by 2', () async {
      final (container, notifier) = await _makeNotifier('tp-2');
      notifier.setViewMode(ViewMode.twoPage);
      notifier.goToPage(4);
      notifier.previousPage();
      expect(_state(container, 'tp-2').currentPage, 2);
    });

    test('twoPage previousPage clamps to 0', () async {
      final (container, notifier) = await _makeNotifier('tp-3');
      notifier.setViewMode(ViewMode.twoPage);
      notifier.goToPage(1);
      notifier.previousPage();
      expect(_state(container, 'tp-3').currentPage, 0);
    });
  });

  // ─── Overlay (AC-52..AC-56) ──────────────────────────────────────────────

  group('PerformanceModeNotifier — overlay', () {
    test('toggleOverlay makes overlay visible', () async {
      final (container, notifier) = await _makeNotifier('ov-1');
      expect(_state(container, 'ov-1').overlayVisible, isFalse);
      notifier.toggleOverlay();
      expect(_state(container, 'ov-1').overlayVisible, isTrue);
    });

    test('toggleOverlay hides overlay when visible', () async {
      final (container, notifier) = await _makeNotifier('ov-2');
      notifier.toggleOverlay(); // show
      notifier.toggleOverlay(); // hide
      expect(_state(container, 'ov-2').overlayVisible, isFalse);
    });

    test('overlay auto-hides after 4 seconds (AC-53)', () async {
      final (container, notifier) = await _makeNotifier('ov-3');
      notifier.toggleOverlay();
      expect(_state(container, 'ov-3').overlayVisible, isTrue);
      // Wait slightly more than 4 seconds
      await Future<void>.delayed(const Duration(milliseconds: 4100));
      expect(_state(container, 'ov-3').overlayVisible, isFalse);
    });

    test('resetOverlayTimer extends auto-hide by resetting timer (AC-54)',
        () async {
      final (container, notifier) = await _makeNotifier('ov-4');
      notifier.toggleOverlay();
      // Reset timer at 3 seconds — overlay should still be visible at 4.5s
      await Future<void>.delayed(const Duration(milliseconds: 3000));
      notifier.resetOverlayTimer();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(_state(container, 'ov-4').overlayVisible, isTrue);
    });

    test('toggleOverlay does nothing when UI is locked', () async {
      final (container, notifier) = await _makeNotifier('ov-5');
      notifier.toggleUiLock();
      notifier.toggleOverlay();
      expect(_state(container, 'ov-5').overlayVisible, isFalse);
    });

    test('hideOverlay cancels timer and hides overlay', () async {
      final (container, notifier) = await _makeNotifier('ov-6');
      notifier.toggleOverlay();
      notifier.hideOverlay();
      expect(_state(container, 'ov-6').overlayVisible, isFalse);
    });
  });

  // ─── UI Lock (AC-05) ────────────────────────────────────────────────────

  group('PerformanceModeNotifier — UI lock', () {
    test('toggleUiLock locks the UI', () async {
      final (container, notifier) = await _makeNotifier('ul-1');
      notifier.toggleUiLock();
      expect(_state(container, 'ul-1').uiLocked, isTrue);
    });

    test('toggleUiLock hides overlay when locking', () async {
      final (container, notifier) = await _makeNotifier('ul-2');
      notifier.toggleOverlay(); // show overlay
      notifier.toggleUiLock(); // lock → overlay should hide
      final state = _state(container, 'ul-2');
      expect(state.uiLocked, isTrue);
      expect(state.overlayVisible, isFalse);
    });

    test('toggleUiLock again unlocks', () async {
      final (container, notifier) = await _makeNotifier('ul-3');
      notifier.toggleUiLock();
      notifier.toggleUiLock();
      expect(_state(container, 'ul-3').uiLocked, isFalse);
    });

    test('unlockUi always unlocks', () async {
      final (container, notifier) = await _makeNotifier('ul-4');
      notifier.toggleUiLock();
      notifier.unlockUi();
      expect(_state(container, 'ul-4').uiLocked, isFalse);
    });
  });

  // ─── View Mode / Orientation (AC-57..AC-60) ──────────────────────────────

  group('PerformanceModeNotifier — view mode for orientation', () {
    test('landscape ≥ 600px → twoPage', () async {
      final (container, notifier) = await _makeNotifier('vm-1');
      notifier.updateViewModeForOrientation(
        isLandscape: true,
        screenWidth: 800,
        halfPageTurnEnabled: true,
      );
      expect(_state(container, 'vm-1').viewMode, ViewMode.twoPage);
    });

    test('portrait + halfPageTurnEnabled → halfPageTurn', () async {
      final (container, notifier) = await _makeNotifier('vm-2');
      notifier.updateViewModeForOrientation(
        isLandscape: false,
        screenWidth: 400,
        halfPageTurnEnabled: true,
      );
      expect(_state(container, 'vm-2').viewMode, ViewMode.halfPageTurn);
    });

    test('portrait + halfPageTurnEnabled=false → singlePage', () async {
      final (container, notifier) = await _makeNotifier('vm-3');
      notifier.updateViewModeForOrientation(
        isLandscape: false,
        screenWidth: 400,
        halfPageTurnEnabled: false,
      );
      expect(_state(container, 'vm-3').viewMode, ViewMode.singlePage);
    });

    test('landscape < 600px → singlePage (small device)', () async {
      final (container, notifier) = await _makeNotifier('vm-4');
      notifier.updateViewModeForOrientation(
        isLandscape: true,
        screenWidth: 500,
        halfPageTurnEnabled: false,
      );
      expect(_state(container, 'vm-4').viewMode, ViewMode.singlePage);
    });
  });

  // ─── Stimme (AC-37..AC-42) ──────────────────────────────────────────────

  group('PerformanceModeNotifier — stimme change', () {
    test('changeVoice updates currentVoiceId and resets to page 0', () async {
      final (container, notifier) = await _makeNotifier('st-1');
      notifier.goToPage(3);
      notifier.changeVoice('tr1');
      final state = _state(container, 'st-1');
      expect(state.currentVoiceId, 'tr1');
      expect(state.currentPage, 0);
    });

    test('changeVoice hides overlay (AC-42 / AC-40)', () async {
      final (container, notifier) = await _makeNotifier('st-2');
      notifier.toggleOverlay();
      notifier.changeVoice('kl1');
      expect(_state(container, 'st-2').overlayVisible, isFalse);
    });
  });

  // ─── Setlist Navigation ──────────────────────────────────────────────────

  group('PerformanceModeNotifier — setlist navigation', () {
    final setlist = [
      const SetlistItem(pieceId: 's1', title: 'Stück 1', orderIndex: 0),
      const SetlistItem(pieceId: 's2', title: 'Stück 2', orderIndex: 1),
      const SetlistItem(pieceId: 's3', title: 'Stück 3', orderIndex: 2),
    ];

    test('loadSetlist sets setlist and index 0', () async {
      final (container, notifier) = await _makeNotifier('sl-1');
      notifier.loadSetlist(setlist);
      final state = _state(container, 'sl-1');
      expect(state.setlist, hasLength(3));
      expect(state.currentSetlistIndex, 0);
    });

    test('goToSetlistItem updates index and resets page', () async {
      final (container, notifier) = await _makeNotifier('sl-2');
      notifier.loadSetlist(setlist);
      notifier.goToPage(4);
      notifier.goToSetlistItem(2);
      final state = _state(container, 'sl-2');
      expect(state.currentSetlistIndex, 2);
      expect(state.currentPage, 0);
    });

    test('goToSetlistItem hides overlay', () async {
      final (container, notifier) = await _makeNotifier('sl-3');
      notifier.loadSetlist(setlist);
      notifier.toggleOverlay();
      notifier.goToSetlistItem(1);
      expect(_state(container, 'sl-3').overlayVisible, isFalse);
    });

    test('pageIndicator shows setlist info when setlist loaded', () async {
      final (container, notifier) = await _makeNotifier('sl-4');
      notifier.loadSetlist(setlist);
      notifier.goToSetlistItem(1);
      expect(_state(container, 'sl-4').pageIndicator, 'Stück 2 / 3');
    });

    test('currentTitle returns setlist item title', () async {
      final (container, notifier) = await _makeNotifier('sl-5');
      notifier.loadSetlist(setlist);
      expect(_state(container, 'sl-5').currentTitle, 'Stück 1');
    });

    test('nextPage on last page advances to next setlist item', () async {
      final (container, notifier) = await _makeNotifier('sl-6');
      notifier.loadSetlist(setlist);
      // Go to last page
      for (int i = 0; i < 10; i++) {
        notifier.nextPage();
      }
      // Should have advanced setlist
      expect(_state(container, 'sl-6').currentSetlistIndex, greaterThan(0));
    });

    test('goToSetlistItem out of range is ignored', () async {
      final (container, notifier) = await _makeNotifier('sl-7');
      notifier.loadSetlist(setlist);
      notifier.goToSetlistItem(99);
      expect(_state(container, 'sl-7').currentSetlistIndex, 0);
    });
  });

  // ─── Auto-Scroll ──────────────────────────────────────────────────────────

  group('PerformanceModeNotifier — auto-scroll speed calculation', () {
    test('setAutoScrollSpeed clamps to 10..200', () async {
      final (container, notifier) = await _makeNotifier('as-1');
      notifier.setAutoScrollSpeed(5.0);
      expect(_state(container, 'as-1').autoScrollSpeed, 10.0);

      notifier.setAutoScrollSpeed(300.0);
      expect(_state(container, 'as-1').autoScrollSpeed, 200.0);
    });

    test('setAutoScrollSpeed sets valid value', () async {
      final (container, notifier) = await _makeNotifier('as-2');
      notifier.setAutoScrollSpeed(60.0);
      expect(_state(container, 'as-2').autoScrollSpeed, 60.0);
    });

    test('toggleAutoScroll toggles active flag', () async {
      final (container, notifier) = await _makeNotifier('as-3');
      expect(_state(container, 'as-3').autoScrollActive, isFalse);
      notifier.toggleAutoScroll();
      expect(_state(container, 'as-3').autoScrollActive, isTrue);
      notifier.toggleAutoScroll();
      expect(_state(container, 'as-3').autoScrollActive, isFalse);
    });
  });

  // ─── Zoom Memory (AC-50, AC-51) ───────────────────────────────────────────

  group('PerformanceModeNotifier — zoom memory per page', () {
    test('setPageZoom stores zoom for page number', () async {
      final (container, notifier) = await _makeNotifier('zm-1');
      notifier.setPageZoom(2, 1.5);
      expect(_state(container, 'zm-1').pageZoomMemory[2], 1.5);
    });

    test('setPageZoom for multiple pages stored independently', () async {
      final (container, notifier) = await _makeNotifier('zm-2');
      notifier.setPageZoom(0, 1.2);
      notifier.setPageZoom(3, 2.0);
      final memory = _state(container, 'zm-2').pageZoomMemory;
      expect(memory[0], 1.2);
      expect(memory[3], 2.0);
    });

    test('resetPageZoom removes zoom for page (AC-51)', () async {
      final (container, notifier) = await _makeNotifier('zm-3');
      notifier.setPageZoom(1, 1.8);
      notifier.resetPageZoom(1);
      expect(_state(container, 'zm-3').pageZoomMemory.containsKey(1), isFalse);
    });

    test('pageZoomMemory is empty on init', () async {
      final (container, _) = await _makeNotifier('zm-4');
      expect(_state(container, 'zm-4').pageZoomMemory, isEmpty);
    });
  });

  // ─── State Helpers ───────────────────────────────────────────────────────

  group('PerformanceModeState — helpers', () {
    test('isFirstPage is true on page 0', () async {
      final (container, _) = await _makeNotifier('sh-1');
      expect(_state(container, 'sh-1').isFirstPage, isTrue);
    });

    test('isLastPage is true on last page', () async {
      final (container, notifier) = await _makeNotifier('sh-2');
      notifier.goToPage(7);
      expect(_state(container, 'sh-2').isLastPage, isTrue);
    });

    test('pageIndicator shows page/totalPages without setlist', () async {
      final (container, _) = await _makeNotifier('sh-3');
      expect(_state(container, 'sh-3').pageIndicator, 'Seite 1 / 8');
    });
  });
}
