// Service worker: offline app shell + cached CDN libraries.
// Bump CACHE version whenever index.html or the cached asset list changes.
const CACHE = 'itinerary-v8';
const SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
  'https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js',
  'https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  // Cache the shell, but don't fail the whole install if one CDN asset is unreachable.
  e.waitUntil(caches.open(CACHE).then((c) => Promise.allSettled(SHELL.map((u) => c.add(u)))));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Never cache API traffic (Supabase, Google, weather, FX) — always go to network.
  const isApi = /supabase\.co|googleapis\.com|aviationstack\.com|open-meteo\.com|er-api\.com/.test(url.host);
  if (isApi) return; // let the browser handle it normally

  // App shell + CDN libs: cache-first, fall back to network and cache the result.
  e.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match('./index.html')))
  );
});
