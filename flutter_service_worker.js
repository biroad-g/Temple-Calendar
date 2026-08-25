'use strict';

// ============================================================
// 寺院カレンダー Service Worker v5
// 修正点:
//   - cache.match() を URL 文字列で比較（Requestオブジェクト不一致を回避）
//   - キャッシュ保存時も URL 文字列をキーにする
//   - 全アセットをインストール時に同期キャッシュ（分割なし）
//   - デバッグログを強化
// ============================================================

const CACHE_VERSION = 'v5';
const CACHE_NAME = 'temple-calendar-' + CACHE_VERSION;

// SW 自身の URL からベースパスを計算
// 例: https://biroad-g.github.io/Temple-Calendar/flutter_service_worker.js
//  → https://biroad-g.github.io/Temple-Calendar/
const SW_BASE = self.location.href.replace('flutter_service_worker.js', '');

// キャッシュする全ファイルリスト（URL文字列で管理）
const ALL_FILES = [
  SW_BASE,
  SW_BASE + 'index.html',
  SW_BASE + 'flutter.js',
  SW_BASE + 'flutter_bootstrap.js',
  SW_BASE + 'main.dart.js',
  SW_BASE + 'favicon.png',
  SW_BASE + 'manifest.json',
  SW_BASE + 'version.json',
  // アセット
  SW_BASE + 'assets/AssetManifest.bin',
  SW_BASE + 'assets/AssetManifest.bin.json',
  SW_BASE + 'assets/AssetManifest.json',
  SW_BASE + 'assets/FontManifest.json',
  SW_BASE + 'assets/NOTICES',
  SW_BASE + 'assets/fonts/MaterialIcons-Regular.otf',
  SW_BASE + 'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  SW_BASE + 'assets/shaders/ink_sparkle.frag',
  // アイコン
  SW_BASE + 'icons/Icon-192.png',
  SW_BASE + 'icons/Icon-512.png',
  SW_BASE + 'icons/Icon-maskable-192.png',
  SW_BASE + 'icons/Icon-maskable-512.png',
  // CanvasKit
  SW_BASE + 'canvaskit/canvaskit.js',
  SW_BASE + 'canvaskit/canvaskit.wasm',
  SW_BASE + 'canvaskit/chromium/canvaskit.js',
  SW_BASE + 'canvaskit/chromium/canvaskit.wasm',
  SW_BASE + 'canvaskit/skwasm.js',
  SW_BASE + 'canvaskit/skwasm.wasm',
  SW_BASE + 'canvaskit/skwasm_heavy.js',
  SW_BASE + 'canvaskit/skwasm_heavy.wasm',
];

// ============================================================
// install: 全ファイルをキャッシュ
// ============================================================
self.addEventListener('install', (event) => {
  console.log('[SW v5] install start. SW_BASE =', SW_BASE);
  self.skipWaiting();

  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      let ok = 0, fail = 0;
      for (const url of ALL_FILES) {
        try {
          // no-store で取得してキャッシュに URL 文字列キーで保存
          const res = await fetch(url, { cache: 'no-store' });
          if (res.ok) {
            // URL文字列をキーにして保存（Requestオブジェクトではなく）
            await cache.put(url, res);
            ok++;
          } else {
            console.warn('[SW v5] fetch not ok:', url, res.status);
            fail++;
          }
        } catch (e) {
          console.warn('[SW v5] fetch failed:', url, e.message);
          fail++;
        }
      }
      console.log(`[SW v5] install done. ok=${ok} fail=${fail}`);
    })
  );
});

// ============================================================
// activate: 古いキャッシュを削除
// ============================================================
self.addEventListener('activate', (event) => {
  console.log('[SW v5] activate');
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((n) => n.startsWith('temple-calendar-') && n !== CACHE_NAME)
          .map((n) => {
            console.log('[SW v5] delete old cache:', n);
            return caches.delete(n);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ============================================================
// fetch: キャッシュ優先 → ネットワーク → index.html フォールバック
// ============================================================
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const reqUrl = event.request.url;

  // このアプリのスコープ外は無視
  if (!reqUrl.startsWith(SW_BASE) && reqUrl !== SW_BASE.replace(/\/$/, '')) return;

  event.respondWith(
    caches.open(CACHE_NAME).then(async (cache) => {
      // ★ URL文字列でキャッシュを検索（Requestオブジェクト不一致を回避）
      const cached = await cache.match(reqUrl);
      if (cached) {
        console.log('[SW v5] cache hit:', reqUrl);
        return cached;
      }

      // キャッシュにない → ネットワーク取得
      try {
        const res = await fetch(event.request);
        if (res && res.ok) {
          // ネットワーク取得成功 → URL文字列キーでキャッシュに追加
          await cache.put(reqUrl, res.clone());
          console.log('[SW v5] fetched & cached:', reqUrl);
        }
        return res;
      } catch (e) {
        console.warn('[SW v5] offline & no cache:', reqUrl);

        // オフライン + キャッシュなし → index.html にフォールバック
        const indexUrl = SW_BASE + 'index.html';
        const fallback = await cache.match(indexUrl) || await cache.match(SW_BASE);
        if (fallback) {
          console.log('[SW v5] fallback to index.html');
          return fallback;
        }
        return new Response('offline - cache not ready', {
          status: 503,
          headers: { 'Content-Type': 'text/plain' },
        });
      }
    })
  );
});

// ============================================================
// message: skipWaiting
// ============================================================
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    console.log('[SW v5] skipWaiting received');
    self.skipWaiting();
  }
});
