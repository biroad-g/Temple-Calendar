'use strict';

// キャッシュ名（バージョンを上げると古いキャッシュを破棄）
const CACHE_VERSION = 'v3';
const CACHE_NAME = 'temple-calendar-' + CACHE_VERSION;

// このService Workerが配置されているベースURL
// 例: https://biroad-g.github.io/Temple-Calendar/
const SW_BASE = self.location.href.replace('flutter_service_worker.js', '');

// キャッシュするファイルの相対パスリスト（SW_BASEからの相対）
const CACHE_FILES = [
  '',                    // index.html (ベースURL自体)
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'version.json',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/AssetManifest.json',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/NOTICES',
  'assets/shaders/ink_sparkle.frag',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'canvaskit/skwasm.js',
  'canvaskit/skwasm.wasm',
  'canvaskit/skwasm_heavy.js',
  'canvaskit/skwasm_heavy.wasm',
];

// インストール時：全ファイルを事前キャッシュ
self.addEventListener('install', (event) => {
  console.log('[SW] Installing, base:', SW_BASE);
  self.skipWaiting();

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      // 全ファイルをフルURLに変換してキャッシュ
      const urls = CACHE_FILES.map(f => SW_BASE + f);
      console.log('[SW] Pre-caching', urls.length, 'files');

      // 重要ファイルは必須（失敗するとインストール失敗）
      const criticalFiles = [
        SW_BASE + '',
        SW_BASE + 'index.html',
        SW_BASE + 'flutter_bootstrap.js',
        SW_BASE + 'flutter.js',
        SW_BASE + 'main.dart.js',
        SW_BASE + 'canvaskit/canvaskit.js',
        SW_BASE + 'canvaskit/canvaskit.wasm',
      ];

      // 全ファイルを個別にキャッシュ（1つ失敗しても続行）
      return Promise.allSettled(
        urls.map(url =>
          cache.add(new Request(url, {cache: 'reload', mode: 'cors'}))
            .then(() => console.log('[SW] Cached:', url))
            .catch(err => console.warn('[SW] Cache failed:', url, err.message))
        )
      ).then((results) => {
        const failed = results.filter(r => r.status === 'rejected');
        console.log('[SW] Install complete. Failed:', failed.length, '/', urls.length);
      });
    })
  );
});

// activate時：古いキャッシュを削除
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating version:', CACHE_VERSION);
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter(name => name.startsWith('temple-calendar-') && name !== CACHE_NAME)
          .map(name => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      console.log('[SW] Activated, claiming clients');
      return self.clients.claim();
    })
  );
});

// fetch時：キャッシュ優先、なければネットワーク
self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // GETリクエスト以外は無視
  if (event.request.method !== 'GET') return;

  // このオリジン以外のリクエストは無視（外部CDN等）
  if (!url.startsWith(self.location.origin)) return;

  // SW_BASEで始まらないリクエストは無視
  if (!url.startsWith(SW_BASE) && url !== SW_BASE.replace(/\/$/, '')) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          // キャッシュヒット → そのまま返す
          return cachedResponse;
        }

        // キャッシュにない → ネットワークから取得してキャッシュに保存
        return fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.ok) {
            cache.put(event.request, networkResponse.clone());
          }
          return networkResponse;
        }).catch(() => {
          // オフラインでキャッシュにもない場合
          // index.htmlにフォールバック（Flutterのルーティングのため）
          const reqUrl = event.request.url;
          if (reqUrl === SW_BASE || reqUrl === SW_BASE + 'index.html' ||
              reqUrl.endsWith('/Temple-Calendar/') || reqUrl.endsWith('/Temple-Calendar')) {
            return cache.match(SW_BASE + 'index.html')
                || cache.match(SW_BASE);
          }
          console.warn('[SW] Offline, no cache for:', reqUrl);
          return new Response('Offline - file not cached', {
            status: 503,
            statusText: 'Service Unavailable'
          });
        });
      });
    })
  );
});

// メッセージハンドラ
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
  if (event.data === 'getCacheStatus') {
    caches.open(CACHE_NAME).then(cache => cache.keys()).then(keys => {
      event.source.postMessage({type: 'cacheStatus', count: keys.length, version: CACHE_VERSION});
    });
  }
});
