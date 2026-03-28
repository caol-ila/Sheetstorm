import 'dart:collection';

/// LRU page cache for pre-rendered sheet pages (Spec §3.1).
///
/// Strategy: current page ± 2 pre-cached, max 20MB configurable.
/// On page turn: N+3 async load, N-3 evicted.
class PageCacheService {
  PageCacheService({this.maxCachedPages = 5});

  final int maxCachedPages;
  final LinkedHashMap<int, CachedPage> _cache = LinkedHashMap<int, CachedPage>();

  /// Pre-caches pages around [currentPage].
  /// Returns set of page numbers that need loading.
  Set<int> getPagesToPrecache(int currentPage, int totalPages) {
    final pages = <int>{};
    for (int i = currentPage - 2; i <= currentPage + 2; i++) {
      if (i >= 0 && i < totalPages) {
        pages.add(i);
      }
    }
    return pages;
  }

  /// Returns true if [pageNumber] is in cache.
  bool isPageCached(int pageNumber) => _cache.containsKey(pageNumber);

  /// Adds a page to the cache; evicts oldest if over limit.
  void cachePage(int pageNumber, CachedPage page) {
    _cache.remove(pageNumber);
    _cache[pageNumber] = page;
    _evictIfNeeded();
  }

  /// Retrieves a cached page.
  CachedPage? getPage(int pageNumber) {
    final page = _cache.remove(pageNumber);
    if (page != null) {
      // Move to end (most recently used)
      _cache[pageNumber] = page;
    }
    return page;
  }

  /// Evicts pages furthest from [currentPage].
  void evictDistant(int currentPage, int totalPages) {
    final keep = getPagesToPrecache(currentPage, totalPages);
    _cache.removeWhere((key, _) => !keep.contains(key));
  }

  void clear() => _cache.clear();

  int get size => _cache.length;

  void _evictIfNeeded() {
    while (_cache.length > maxCachedPages) {
      _cache.remove(_cache.keys.first);
    }
  }
}

class CachedPage {
  const CachedPage({
    required this.pageNumber,
    required this.filePath,
    this.sizeBytes = 0,
    this.autoRotationAngle = 0.0,
  });

  final int pageNumber;
  final String filePath;
  final int sizeBytes;
  final double autoRotationAngle;
}
