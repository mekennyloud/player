// Кэширует сам плеер, чтобы он открывался без интернета.
// При обновлении плеера увеличь номер версии.
const CACHE = 'player-v13';
const FILES = ['./', 'index.html', 'manifest.webmanifest',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png',
  'fonts/InterTight-latin.woff2', 'fonts/InterTight-cyrillic.woff2', 'fonts/JetBrainsMono-latin.woff2', 'fonts/JetBrainsMono-cyrillic.woff2'];

// cache: 'reload' — берём файлы прямо с сервера, мимо HTTP-кэша браузера,
// иначе новая версия может закэшировать старую страницу
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE)
    .then(c => c.addAll(FILES.map(f => new Request(f, { cache: 'reload' }))))
    .then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// сначала из кэша (мгновенно и офлайн), в фоне — свежая версия из сети
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  e.respondWith(caches.open(CACHE).then(async cache => {
    const cached = await cache.match(req, { ignoreSearch: true });
    const fresh = fetch(req.url, { cache: 'no-cache' }).then(res => {
      if (res.ok) cache.put(req, res.clone());
      return res;
    }).catch(() => cached);
    return cached || fresh;
  }));
});
