const V = 'vx-v7';
const SHELL = ['./', 'index.html', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'icon-maskable-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(V).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k)))).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.hostname.endsWith('supabase.co')) return; // API-ul rămâne mereu live

  // pagina: network-first, ca actualizările să ajungă imediat; offline -> cache
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req).then(r => { caches.open(V).then(c => c.put('index.html', r.clone())); return r; })
        .catch(() => caches.match('index.html'))
    );
    return;
  }

  // restul (iconițe, manifest, supabase-js de pe CDN): cache-first + salvare la prima cerere
  if (url.origin === location.origin || url.hostname === 'cdn.jsdelivr.net') {
    e.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(r => {
        if (r.ok) caches.open(V).then(c => c.put(req, r.clone()));
        return r;
      }))
    );
  }
});
