import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/data/services/page_cache_service.dart';

void main() {
  PageCacheService makeCache({int maxPages = 5}) =>
      PageCacheService(maxCachedPages: maxPages);

  CachedPage makePage(int n, {int sizeBytes = 1024}) => CachedPage(
        pageNumber: n,
        filePath: '/pages/$n.png',
        sizeBytes: sizeBytes,
      );

  group('PageCacheService — cache/get', () {
    test('isPageCached returns false for uncached page', () {
      final cache = makeCache();
      expect(cache.isPageCached(0), isFalse);
    });

    test('isPageCached returns true after caching', () {
      final cache = makeCache();
      cache.cachePage(0, makePage(0));
      expect(cache.isPageCached(0), isTrue);
    });

    test('getPage returns cached page', () {
      final cache = makeCache();
      cache.cachePage(2, makePage(2));
      final result = cache.getPage(2);
      expect(result, isNotNull);
      expect(result!.pageNumber, 2);
    });

    test('getPage returns null for uncached page', () {
      final cache = makeCache();
      expect(cache.getPage(99), isNull);
    });

    test('getPage moves page to end (LRU update)', () {
      final cache = makeCache(maxPages: 3);
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      cache.cachePage(2, makePage(2));
      // Access page 0 → makes it MRU
      cache.getPage(0);
      // Add page 3 → should evict page 1 (oldest now)
      cache.cachePage(3, makePage(3));
      expect(cache.isPageCached(0), isTrue); // still here (recently used)
      expect(cache.isPageCached(1), isFalse); // evicted
      expect(cache.isPageCached(2), isTrue);
      expect(cache.isPageCached(3), isTrue);
    });

    test('size reflects number of cached pages', () {
      final cache = makeCache();
      expect(cache.size, 0);
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      expect(cache.size, 2);
    });

    test('clear empties cache', () {
      final cache = makeCache();
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      cache.clear();
      expect(cache.size, 0);
      expect(cache.isPageCached(0), isFalse);
    });
  });

  group('PageCacheService — LRU eviction (Spec §3.1)', () {
    test('evicts oldest page when maxCachedPages exceeded', () {
      final cache = makeCache(maxPages: 3);
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      cache.cachePage(2, makePage(2));
      // Adding a 4th page should evict page 0 (inserted first)
      cache.cachePage(3, makePage(3));

      expect(cache.size, 3);
      expect(cache.isPageCached(0), isFalse);
      expect(cache.isPageCached(1), isTrue);
      expect(cache.isPageCached(2), isTrue);
      expect(cache.isPageCached(3), isTrue);
    });

    test('re-caching an existing page updates it without duplicating', () {
      final cache = makeCache(maxPages: 3);
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      cache.cachePage(2, makePage(2));
      // Re-cache page 0 with new data → should not evict anything (still 3)
      cache.cachePage(0, makePage(0, sizeBytes: 2048));
      expect(cache.size, 3);
      expect(cache.getPage(0)!.sizeBytes, 2048);
    });

    test('evicts multiple pages when necessary', () {
      final cache = makeCache(maxPages: 2);
      for (int i = 0; i < 5; i++) {
        cache.cachePage(i, makePage(i));
      }
      expect(cache.size, 2);
    });

    test('maxCachedPages=1 always keeps only the last cached', () {
      final cache = makeCache(maxPages: 1);
      cache.cachePage(0, makePage(0));
      cache.cachePage(1, makePage(1));
      expect(cache.size, 1);
      expect(cache.isPageCached(1), isTrue);
      expect(cache.isPageCached(0), isFalse);
    });
  });

  group('PageCacheService — getPagesToPrecache (Spec §3.1)', () {
    test('returns current page ±2 pages', () {
      final cache = makeCache();
      final pages = cache.getPagesToPrecache(5, 10);
      expect(pages, containsAll([3, 4, 5, 6, 7]));
      expect(pages.length, 5);
    });

    test('clamps to valid range at start of document', () {
      final cache = makeCache();
      final pages = cache.getPagesToPrecache(0, 10);
      expect(pages, containsAll([0, 1, 2]));
      expect(pages.contains(-1), isFalse);
      expect(pages.contains(-2), isFalse);
    });

    test('clamps to valid range at end of document', () {
      final cache = makeCache();
      final pages = cache.getPagesToPrecache(9, 10);
      expect(pages, containsAll([7, 8, 9]));
      expect(pages.contains(10), isFalse);
    });

    test('single page document returns only page 0', () {
      final cache = makeCache();
      final pages = cache.getPagesToPrecache(0, 1);
      expect(pages, {0});
    });
  });

  group('PageCacheService — evictDistant (Spec §3.1)', () {
    test('removes pages outside ±2 range from current page', () {
      final cache = makeCache(maxPages: 10);
      for (int i = 0; i < 10; i++) {
        cache.cachePage(i, makePage(i));
      }
      // Currently on page 5 → keep 3,4,5,6,7
      cache.evictDistant(5, 10);
      expect(cache.isPageCached(3), isTrue);
      expect(cache.isPageCached(4), isTrue);
      expect(cache.isPageCached(5), isTrue);
      expect(cache.isPageCached(6), isTrue);
      expect(cache.isPageCached(7), isTrue);
      expect(cache.isPageCached(0), isFalse);
      expect(cache.isPageCached(9), isFalse);
    });

    test('evictDistant on empty cache does not throw', () {
      final cache = makeCache();
      expect(() => cache.evictDistant(3, 10), returnsNormally);
    });
  });

  group('PageCacheService — CachedPage properties', () {
    test('stores filePath correctly', () {
      const page = CachedPage(pageNumber: 0, filePath: '/test/page0.png');
      expect(page.filePath, '/test/page0.png');
    });

    test('stores autoRotationAngle', () {
      const page = CachedPage(
        pageNumber: 1,
        filePath: '/p.png',
        autoRotationAngle: 3.5,
      );
      expect(page.autoRotationAngle, 3.5);
    });

    test('default autoRotationAngle is 0.0', () {
      const page = CachedPage(pageNumber: 0, filePath: '/p.png');
      expect(page.autoRotationAngle, 0.0);
    });
  });
}
