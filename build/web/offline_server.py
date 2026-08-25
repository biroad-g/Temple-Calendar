#!/usr/bin/env python3
"""
寺院カレンダー PWA オフライン対応サーバー
Service Workerが正しく動作するために必要なヘッダーを付与します。
"""
import http.server
import socketserver
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5060

class OfflinePWAHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        path = self.path.split('?')[0]

        # CORS許可（プレビュー環境用）
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', "frame-ancestors *; default-src * 'unsafe-inline' 'unsafe-eval' blob: data:")

        # Service Worker スコープを許可
        self.send_header('Service-Worker-Allowed', '/')

        # WASM ファイルに正しい MIME タイプを設定
        if path.endswith('.wasm'):
            self.send_header('Cross-Origin-Resource-Policy', 'cross-origin')

        # キャッシュ制御：HTMLとSWは毎回確認、他はキャッシュ可
        if path.endswith('.html') or 'flutter_service_worker' in path or 'flutter_bootstrap' in path:
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
        else:
            self.send_header('Cache-Control', 'public, max-age=31536000, immutable')

        super().end_headers()

    def guess_type(self, path):
        # WASMのMIMEタイプを正しく設定
        if str(path).endswith('.wasm'):
            return 'application/wasm'
        if str(path).endswith('.js'):
            return 'application/javascript'
        return super().guess_type(path)

    def log_message(self, format, *args):
        # 静的ファイルのログは抑制
        pass

os.chdir(os.path.dirname(os.path.abspath(__file__)))

with socketserver.TCPServer(('0.0.0.0', PORT), OfflinePWAHandler) as httpd:
    httpd.serve_forever()
