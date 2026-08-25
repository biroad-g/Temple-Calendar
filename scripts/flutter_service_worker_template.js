'use strict';

const CACHE_VERSION = 'v4';
const CACHE_NAME = 'temple-calendar-' + CACHE_VERSION;

// このSWのベースURL（例: https://biroad-g.github.io/Temple-Calendar/）
const SW_BASE = self.location.href.replace('flutter_service_worker.js', '');

// アプリ起動に必須のファイル（インストール時に必ずキャッシュ）
const CRITICAL_FILES = [
  '',              // index.html
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'assets/AssetManifest.bin.json',
  'assets/AssetManifest.json',
  'assets/FontManifest.json',
];

// 起動後にバックグラウンドでキャッシュする大きなファイル
const BACKGROUND_FILES = [
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/shaders/ink_sparkle.frag',
  'assets/NOTICES',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'canvaskit/skwasm.js',
  'canvaskit/skwasm.wasm',
  'canvaskit/skwasm_heavy.js',
  'canvaskit/skwasm_heavy.wasm',
  'manifest.json',
  'favicon.png',
  'version.json',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

// インストール時：必須ファイルだけキャッシュ（すぐ完了させる）
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      const urls = CRITICAL_FILES.map(f => SW_BASE + f);
      return cache.addAll(urls.map(url => new Request(url, {cache: 'reload'})))
        .then(() => {
          // バックグラウンドで残りをキャッシュ（インストールをブロックしない）
          const bgUrls = BACKGROUND_FILES.map(f => SW_BASE + f);
          Promise.allSettled(
            bgUrls.map(url =>
              cache.add(new Request(url, {cache: 'reload'}))
                .catch(() => {})
            )
          );
        });
    })
  );
});

// activate時：古いキャッシュを削除してクライアントを引き継ぐ
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then(names => Promise.all(
        names
          .filter(n => n.startsWith('temple-calendar-') && n !== CACHE_NAME)
          .map(n => caches.delete(n))
      ))
      .then(() => self.clients.claim())
  );
});

// fetch：キャッシュ優先、なければネットワーク
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = event.request.url;

  // このオリジン・このアプリのパス以外は無視
  if (!url.startsWith(self.location.origin)) return;
  if (!url.startsWith(SW_BASE) && url !== SW_BASE.replace(/\/$/, '')) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) =>
      cache.match(event.request).then((cached) => {
        if (cached) return cached;

        return fetch(event.request)
          .then((res) => {
            if (res && res.ok) cache.put(event.request, res.clone());
            return res;
          })
          .catch(() => {
            // オフラインでキャッシュにもない → index.htmlにフォールバック
            const isPage = url === SW_BASE || url === SW_BASE + 'index.html'
              || url.endsWith('/Temple-Calendar') || url.endsWith('/Temple-Calendar/');
            if (isPage) {
              return cache.match(SW_BASE + 'index.html')
                  || cache.match(SW_BASE);
            }
            return new Response('offline', {status: 503});
          });
      })
    )
  );
});

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
