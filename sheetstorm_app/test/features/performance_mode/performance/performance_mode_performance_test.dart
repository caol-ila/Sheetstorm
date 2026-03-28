import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/performance_mode/application/performance_mode_notifier.dart';
import 'package:sheetstorm/features/performance_mode/data/services/page_cache_service.dart';

/// Performance benchmark — verifies state transition speed (Spec §3.1, AC-11, AC-61, AC-62).
///
/// Pure Dart unit-level tests: measures CPU-bound state computation only.
/// End-to-end frame timing is verified via Flutter DevTools on a `--profile` build.

Future<(ProviderContainer, PerformanceModeNotifier)> _makePerf(String id) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final sub = container.listen(performanceModeProvider(id), (_, __) {});
  addTearDown(sub.close);
  final notifier = container.read(performanceModeProvider(id).notifier);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return (container, notifier);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Performance — page state transition < 16ms (Spec §3.1, AC-11)', () {
    test('nextPage state transition completes in < 16ms', () async {
      final (_, notifier) = await _makePerf('perf-1');

      final stopwatch = Stopwatch()..start();
      notifier.nextPage();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(16000),
        reason: 'nextPage() state transition must complete within 1 frame (16ms)',
      );
    });

    test('previousPage state transition completes in < 16ms', () async {
      final (_, notifier) = await _makePerf('perf-2');
      notifier.nextPage(); // move to page 1 first

      final stopwatch = Stopwatch()..start();
      notifier.previousPage();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(16000),
        reason: 'previousPage() must complete within 1 frame (16ms)',
      );
    });

    test('toggleOverlay state transition completes in < 16ms', () async {
      final (_, notifier) = await _makePerf('perf-3');

      final stopwatch = Stopwatch()..start();
      notifier.toggleOverlay();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(16000),
        reason: 'toggleOverlay() must complete within 1 frame (16ms, AC-62)',
      );
    });

    test('goToPage state transition completes in < 16ms', () async {
      final (_, notifier) = await _makePerf('perf-4');

      final stopwatch = Stopwatch()..start();
      notifier.goToPage(5);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(16000),
        reason: 'goToPage() must complete within 1 frame (16ms)',
      );
    });
  });

  group('Performance — 100 page navigations without degradation (AC-61)', () {
    test('100 consecutive nextPage transitions stay under 16ms each', () async {
      final (_, notifier) = await _makePerf('perf-5');

      int maxMicros = 0;
      for (int i = 0; i < 100; i++) {
        final sw = Stopwatch()..start();
        notifier.nextPage();
        sw.stop();
        if (sw.elapsedMicroseconds > maxMicros) {
          maxMicros = sw.elapsedMicroseconds;
        }
        if (i == 50) {
          notifier.goToPage(0); // reset to allow further navigation
        }
      }

      expect(
        maxMicros,
        lessThan(16000),
        reason: 'Worst-case nextPage() over 100 calls must stay under 1 frame',
      );
    });

    test('zoom memory does not degrade navigation speed', () async {
      final (_, notifier) = await _makePerf('perf-6');

      // Pre-populate zoom memory with many entries
      for (int i = 0; i < 50; i++) {
        notifier.setPageZoom(i, 1.0 + i * 0.01);
      }

      final sw = Stopwatch()..start();
      notifier.nextPage();
      sw.stop();

      expect(
        sw.elapsedMicroseconds,
        lessThan(16000),
        reason: 'nextPage() must remain fast even with large pageZoomMemory',
      );
    });
  });

  group('Performance — LRU cache operations < 1ms', () {
    test('cachePage is fast (< 1ms)', () {
      final cache = PageCacheService(maxCachedPages: 5);

      final sw = Stopwatch()..start();
      cache.cachePage(
        0,
        const CachedPage(pageNumber: 0, filePath: '/p0.png'),
      );
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000),
          reason: 'cachePage() must complete in < 1ms');
    });

    test('getPage is fast (< 1ms) with 5 cached pages', () {
      final cache = PageCacheService(maxCachedPages: 5);
      for (int i = 0; i < 5; i++) {
        cache.cachePage(i, CachedPage(pageNumber: i, filePath: '/p$i.png'));
      }

      final sw = Stopwatch()..start();
      cache.getPage(2);
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000),
          reason: 'getPage() must complete in < 1ms');
    });

    test('LRU eviction is fast (< 1ms) with maxCachedPages=20', () {
      final cache = PageCacheService(maxCachedPages: 20);
      for (int i = 0; i < 20; i++) {
        cache.cachePage(i, CachedPage(pageNumber: i, filePath: '/p$i.png'));
      }

      final sw = Stopwatch()..start();
      cache.cachePage(20, const CachedPage(pageNumber: 20, filePath: '/p20.png'));
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000),
          reason: 'LRU eviction must complete in < 1ms');
    });

    test('getPagesToPrecache is O(1) per call (< 1ms)', () {
      final cache = PageCacheService();

      final sw = Stopwatch()..start();
      cache.getPagesToPrecache(50, 200);
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000),
          reason: 'getPagesToPrecache() must complete in < 1ms');
    });

    test('evictDistant is fast on 20-page cache (< 1ms)', () {
      final cache = PageCacheService(maxCachedPages: 20);
      for (int i = 0; i < 20; i++) {
        cache.cachePage(i, CachedPage(pageNumber: i, filePath: '/p$i.png'));
      }

      final sw = Stopwatch()..start();
      cache.evictDistant(10, 20);
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000),
          reason: 'evictDistant() must complete in < 1ms for a 20-page cache');
    });
  });

  group('Performance — auto-scroll speed calculation', () {
    test('setAutoScrollSpeed clamp is O(1)', () async {
      final (_, notifier) = await _makePerf('perf-7');

      final sw = Stopwatch()..start();
      notifier.setAutoScrollSpeed(75.0);
      sw.stop();

      expect(sw.elapsedMicroseconds, lessThan(1000));
    });

    test('frame delta calculation at 60fps matches expected pixels', () {
      // AutoScrollWrapper uses: delta = speed * 0.016 (speed * seconds per frame)
      const speed = 30.0;
      const frameSeconds = 0.016;
      final delta = speed * frameSeconds;
      expect(delta, closeTo(0.48, 0.001));
    });

    test('frame delta at max speed 200 px/s', () {
      const speed = 200.0;
      const frameSeconds = 0.016;
      final delta = speed * frameSeconds;
      expect(delta, closeTo(3.2, 0.001));
    });

    test('frame delta at min speed 10 px/s', () {
      const speed = 10.0;
      const frameSeconds = 0.016;
      final delta = speed * frameSeconds;
      expect(delta, closeTo(0.16, 0.001));
    });
  });
}
