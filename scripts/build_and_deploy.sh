#!/usr/bin/env bash
# =============================================================================
# build_and_deploy.sh
# 寺院カレンダー ビルド＆デプロイ自動化スクリプト
#
# 使い方:
#   ./scripts/build_and_deploy.sh [オプション]
#
# オプション:
#   --local        ローカルプレビュー用ビルド（base href=/）
#   --deploy       GitHub Pages用ビルド＋gh-pagesデプロイ
#   --all          ローカルビルド後、GitHub Pagesにもデプロイ（デフォルト）
#   --no-push      デプロイせずビルドと修正適用のみ
#
# 例:
#   ./scripts/build_and_deploy.sh            # ビルド → 修正適用 → 両方プッシュ
#   ./scripts/build_and_deploy.sh --local    # ローカルプレビュー用のみ
#   ./scripts/build_and_deploy.sh --deploy   # GitHub Pagesデプロイのみ
# =============================================================================

set -e  # エラーで即停止

# ---- 設定 -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
SW_TEMPLATE="$SCRIPT_DIR/flutter_service_worker_template.js"
GH_PAGES_BASE_HREF="/Temple-Calendar/"
LOCAL_BASE_HREF="/"
GH_PAGES_WORKTREE="/tmp/gh-pages-build-deploy"

# ---- カラー出力 -------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }
step()    { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ---- オプション解析 ---------------------------------------------------------
MODE="all"
DO_PUSH=true
for arg in "$@"; do
  case $arg in
    --local)   MODE="local"  ;;
    --deploy)  MODE="deploy" ;;
    --all)     MODE="all"    ;;
    --no-push) DO_PUSH=false ;;
    -h|--help)
      sed -n '3,20p' "$0"
      exit 0
      ;;
  esac
done

# =============================================================================
# 関数: flutter_bootstrap.js にパッチを当てる
# 引数: $1 = ファイルパス
# =============================================================================
patch_flutter_bootstrap() {
  local file="$1"
  info "flutter_bootstrap.js にパッチ適用中: $file"

  python3 - "$file" << 'PYEOF'
import re, sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

changed = False

# 1) useLocalCanvasKit:true を buildConfig に追加
if '"useLocalCanvasKit":true' not in content:
    content = re.sub(
        r'"engineRevision":"([^"]+)"',
        r'"engineRevision":"\1","useLocalCanvasKit":true',
        content,
        count=1
    )
    print("  + useLocalCanvasKit:true を追加")
    changed = True
else:
    print("  = useLocalCanvasKit:true は既に存在")

# 2) serviceWorkerSettings ブロックを削除して _flutter.loader.load({}) に変更
new_load = '// Flutter起動（SWはindex.htmlで独自登録済み）\n_flutter.loader.load({});'
if re.search(r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings', content):
    content = re.sub(
        r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings\s*:\s*\{[^}]*\}\s*\}\s*\);',
        new_load,
        content
    )
    print("  + serviceWorkerSettings を削除 → _flutter.loader.load({}) に変更")
    changed = True
elif '_flutter.loader.load({});' in content:
    print("  = _flutter.loader.load({}) は既に適用済み")
else:
    print("  ! 警告: serviceWorkerSettings パターンが見つかりません。手動確認が必要です。")

with open(path, 'w') as f:
    f.write(content)

if changed:
    print("  → flutter_bootstrap.js パッチ完了")
PYEOF

  success "flutter_bootstrap.js パッチ完了"
}

# =============================================================================
# 関数: index.html にSW独自登録スクリプトを挿入する
# 引数: $1 = ファイルパス
# =============================================================================
patch_index_html() {
  local file="$1"
  info "index.html にSW登録スクリプトを挿入中: $file"

  python3 - "$file" << 'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

SW_SCRIPT = """
    // Service Worker を独自登録（flutter_bootstrap.jsのSW待機処理をバイパス）
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('flutter_service_worker.js', {scope: './'})
        .then(function(reg) {
          console.log('[App] SW registered scope:', reg.scope);
          // 既存のSWが待機中なら即座にアクティブ化
          if (reg.waiting) { reg.waiting.postMessage('skipWaiting'); }
          reg.addEventListener('updatefound', function() {
            var sw = reg.installing;
            if (sw) {
              sw.addEventListener('statechange', function() {
                if (sw.state === 'installed') { sw.postMessage('skipWaiting'); }
              });
            }
          });
        })
        .catch(function(e) { console.warn('[App] SW registration failed:', e); });
    }"""

MARKER = "  <script src=\"flutter_bootstrap.js\" async></script>"

if 'serviceWorker' in content:
    print("  = SW登録スクリプトは既に存在")
elif MARKER in content:
    content = content.replace(
        MARKER,
        SW_SCRIPT + "\n  </script>\n\n" + MARKER
    )
    print("  + SW登録スクリプトを挿入")
else:
    print("  ! 警告: flutter_bootstrap.js の script タグが見つかりません")

with open(path, 'w') as f:
    f.write(content)
print("  → index.html パッチ完了")
PYEOF

  success "index.html パッチ完了"
}

# =============================================================================
# 関数: カスタムSWテンプレートをコピー
# 引数: $1 = コピー先ディレクトリ
# =============================================================================
restore_custom_sw() {
  local dest_dir="$1"
  if [ ! -f "$SW_TEMPLATE" ]; then
    error "SW テンプレートが見つかりません: $SW_TEMPLATE"
  fi
  cp "$SW_TEMPLATE" "$dest_dir/flutter_service_worker.js"
  success "カスタム SW v4 を復元: $dest_dir/flutter_service_worker.js"
}

# =============================================================================
# 関数: ローカルプレビュー用ビルド
# =============================================================================
build_local() {
  step "ローカルプレビュー用ビルド (base href=/)"
  cd "$PROJECT_DIR"

  flutter build web --release \
    --base-href "$LOCAL_BASE_HREF" \
    --dart-define=flutter.inspector.structuredErrors=false \
    --pwa-strategy=offline-first
  success "flutter build web 完了"

  step "ビルド後パッチ適用"
  patch_flutter_bootstrap "$BUILD_DIR/flutter_bootstrap.js"
  patch_index_html        "$BUILD_DIR/index.html"
  restore_custom_sw       "$BUILD_DIR"
}

# =============================================================================
# 関数: GitHub Pages へデプロイ
# =============================================================================
deploy_gh_pages() {
  step "gh-pages ブランチへデプロイ"

  # 既存のworktreeをクリーンアップ
  if [ -d "$GH_PAGES_WORKTREE" ]; then
    cd "$PROJECT_DIR"
    git worktree remove "$GH_PAGES_WORKTREE" --force 2>/dev/null || true
  fi

  cd "$PROJECT_DIR"
  git fetch origin gh-pages
  git worktree add "$GH_PAGES_WORKTREE" gh-pages
  info "gh-pages worktree 作成: $GH_PAGES_WORKTREE"

  # GitHub Pages用ファイルをコピー（base href だけ書き換え）
  info "ファイルをコピー中..."
  # flutter_bootstrap.js / flutter_service_worker.js はそのままコピー
  cp "$BUILD_DIR/flutter_bootstrap.js"      "$GH_PAGES_WORKTREE/"
  cp "$BUILD_DIR/flutter_service_worker.js" "$GH_PAGES_WORKTREE/"
  # index.html は base href を /Temple-Calendar/ に変換
  sed "s|<base href=\"${LOCAL_BASE_HREF}\">|<base href=\"${GH_PAGES_BASE_HREF}\">|" \
    "$BUILD_DIR/index.html" > "$GH_PAGES_WORKTREE/index.html"

  # base href の確認
  local actual_href
  actual_href=$(grep -o 'base href="[^"]*"' "$GH_PAGES_WORKTREE/index.html" | head -1)
  info "gh-pages index.html: $actual_href"

  cd "$GH_PAGES_WORKTREE"
  git add flutter_bootstrap.js flutter_service_worker.js index.html

  # 変更がある場合のみコミット
  if git diff --cached --quiet; then
    info "gh-pages: 変更なし。コミットをスキップ"
  else
    local commit_msg
    commit_msg="Deploy: $(date '+%Y-%m-%d %H:%M') - base href=${GH_PAGES_BASE_HREF}"
    git commit -m "$commit_msg"
    success "gh-pages コミット完了"

    if [ "$DO_PUSH" = true ]; then
      git push origin gh-pages
      success "gh-pages プッシュ完了 → https://biroad-g.github.io/Temple-Calendar/"
    else
      warn "--no-push のためプッシュをスキップ"
    fi
  fi

  # worktreeクリーンアップ
  cd "$PROJECT_DIR"
  git worktree remove "$GH_PAGES_WORKTREE" --force
  info "gh-pages worktree を削除"
}

# =============================================================================
# 関数: main ブランチをプッシュ
# =============================================================================
push_main() {
  step "main ブランチへコミット＆プッシュ"
  cd "$PROJECT_DIR"

  git add -f \
    build/web/flutter_bootstrap.js \
    build/web/index.html \
    build/web/flutter_service_worker.js \
    build/web/.last_build_id 2>/dev/null || true

  if git diff --cached --quiet; then
    info "main: 変更なし。コミットをスキップ"
  else
    local commit_msg
    commit_msg="Build: $(date '+%Y-%m-%d %H:%M') - PWA patch applied"
    git commit -m "$commit_msg"
    success "main コミット完了"

    if [ "$DO_PUSH" = true ]; then
      git push origin main
      success "main プッシュ完了"
    else
      warn "--no-push のためプッシュをスキップ"
    fi
  fi
}

# =============================================================================
# 関数: ローカルプレビューサーバー起動
# =============================================================================
start_preview_server() {
  step "ローカルプレビューサーバー起動 (port 5060)"

  # 既存プロセスを停止
  lsof -ti:5060 | xargs -r kill -9 2>/dev/null || true
  sleep 1

  cd "$BUILD_DIR"
  nohup python3 -c "
import http.server, socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('X-Frame-Options','ALLOWALL')
        self.send_header('Content-Security-Policy','frame-ancestors *')
        self.send_header('Service-Worker-Allowed','/')
        if self.path.endswith('.wasm'):
            self.send_header('Cross-Origin-Resource-Policy','cross-origin')
        super().end_headers()
    def guess_type(self,p):
        if str(p).endswith('.wasm'): return 'application/wasm'
        return super().guess_type(p)
    def log_message(self,*a): pass
with socketserver.TCPServer(('0.0.0.0',5060),H) as s: s.serve_forever()
" > /tmp/temple_calendar_server.log 2>&1 &

  sleep 2
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5060/ 2>/dev/null)
  if [ "$status" = "200" ]; then
    success "プレビューサーバー起動済み (HTTP $status)"
    info "ローカルURL: http://localhost:5060/"
  else
    warn "サーバー応答: HTTP $status (ログ: /tmp/temple_calendar_server.log)"
  fi
}

# =============================================================================
# メイン処理
# =============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  寺院カレンダー ビルド＆デプロイスクリプト  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo "  モード: $MODE | プッシュ: $DO_PUSH"
echo ""

cd "$PROJECT_DIR"

case "$MODE" in
  local)
    build_local
    start_preview_server
    ;;
  deploy)
    # すでにビルド済みの build/web を使ってデプロイのみ
    step "既存ビルドにパッチ適用"
    patch_flutter_bootstrap "$BUILD_DIR/flutter_bootstrap.js"
    patch_index_html        "$BUILD_DIR/index.html"
    restore_custom_sw       "$BUILD_DIR"
    deploy_gh_pages
    push_main
    ;;
  all|*)
    build_local
    start_preview_server
    deploy_gh_pages
    push_main
    ;;
esac

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              完了！                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
if [ "$MODE" != "deploy" ]; then
  echo "  ローカルプレビュー : http://localhost:5060/"
fi
if [ "$MODE" != "local" ] && [ "$DO_PUSH" = true ]; then
  echo "  GitHub Pages       : https://biroad-g.github.io/Temple-Calendar/"
fi
echo ""
