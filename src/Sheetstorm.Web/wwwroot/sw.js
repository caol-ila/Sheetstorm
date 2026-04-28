/* Sheetstorm Service Worker
 *
 * Strategie:
 * - "App-Shell" wird beim Install vor-gecacht (Login, Bands, Pieces, Profile-Pages)
 * - PDF-Dateien (/files/parts/{partId}/{fileId}) werden Cache-First geladen
 *   - Bei Erfolg im Cache: sofort liefern, im Hintergrund refreshen
 *   - Bei Cache-Miss: Netzwerk laden + cachen
 * - Andere GET-Requests: Network-First mit Cache-Fallback
 * - POST/PUT/DELETE: nie cachen
 *
 * Sync:
 * - Beim Aktivieren ruft der SW /api/offline/urls und cacht alle markierten PDFs
 * - Periodisch (alle 5min wenn online) wird neu synchronisiert
 */
const SHELL_CACHE = 'sheetstorm-shell-v1';
const FILES_CACHE = 'sheetstorm-files-v1';

const SHELL_URLS = [
  '/',
  '/Account/Login',
  '/Bands',
  '/Account/Profile',
  '/manifest.webmanifest',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((cache) => cache.addAll(SHELL_URLS).catch(() => { /* nicht blockierend */ })),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== SHELL_CACHE && k !== FILES_CACHE).map((k) => caches.delete(k))),
    ).then(() => self.clients.claim()).then(() => syncOfflineFiles()),
  );
});

async function syncOfflineFiles() {
  try {
    const res = await fetch('/api/offline/urls', { credentials: 'include' });
    if (!res.ok) return;
    const json = await res.json();
    const cache = await caches.open(FILES_CACHE);
    await Promise.allSettled(
      (json.urls || []).map(async (url) => {
        try {
          const r = await fetch(url, { credentials: 'include' });
          if (r.ok) await cache.put(url, r);
        } catch { /* ignore */ }
      }),
    );
  } catch { /* keine Verbindung — egal */ }
}

self.addEventListener('message', (event) => {
  if (event.data === 'sync-offline') {
    event.waitUntil(syncOfflineFiles());
  }
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  // Blazor-internals und JS/CSS: Network-First (für schnelle Updates)
  if (url.pathname.startsWith('/_blazor') || url.pathname.startsWith('/_framework')) return;

  // PDF-Files: Cache-First (Offline-fähig)
  if (url.pathname.startsWith('/files/parts/')) {
    event.respondWith(cacheFirst(req, FILES_CACHE));
    return;
  }

  // App-Shell + Pages: Network-First, Cache-Fallback
  event.respondWith(networkFirst(req, SHELL_CACHE));
});

async function cacheFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(req);
  if (cached) {
    // Stale-while-revalidate
    fetch(req, { credentials: 'include' }).then((r) => { if (r.ok) cache.put(req, r.clone()); }).catch(() => {});
    return cached;
  }
  try {
    const r = await fetch(req, { credentials: 'include' });
    if (r.ok) cache.put(req, r.clone());
    return r;
  } catch (e) {
    return new Response('Offline und nicht im Cache', { status: 503, statusText: 'Offline' });
  }
}

async function networkFirst(req, cacheName) {
  try {
    const r = await fetch(req);
    if (r.ok) {
      const cache = await caches.open(cacheName);
      cache.put(req, r.clone());
    }
    return r;
  } catch (e) {
    const cache = await caches.open(cacheName);
    const cached = await cache.match(req);
    if (cached) return cached;
    throw e;
  }
}
