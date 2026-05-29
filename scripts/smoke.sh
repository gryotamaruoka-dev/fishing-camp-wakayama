#!/usr/bin/env bash
# Fast smoke test (15-30秒で完結) - smoke-evaluator agent が1回呼ぶだけ
#
# 4つの check を順に実行し、最初の失敗で exit code を返す:
#   exit 0 = PASS         - 全て合格
#   exit 1 = BUILD_FAIL   - npm run build が失敗
#   exit 2 = MISSING_TEXT - docs/spec.json の must_contain_text にあるテキストが DOM に無い
#   exit 3 = CONSOLE_ERROR - ブラウザのコンソールにエラーが出ている
#   exit 4 = SCREENSHOT_FAIL - スクショ撮影に失敗
#   exit 5 = URL_UNREACHABLE - dev server に接続できない
#
# 引数: $1 = URL (省略時 http://localhost:5173)
# 前提: PROJECT_ROOT は cwd または引数から推定。dev server は別途起動済みであること

set -u
URL="${1:-http://localhost:5173}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

HEADLESS=/opt/playwright-browsers/chromium_headless_shell-1223/chrome-linux/headless_shell
if [ ! -x "$HEADLESS" ]; then
  # フォールバック: シンボリックリンク或いは新バージョンを探す
  HEADLESS=$(find /opt/playwright-browsers -name "headless_shell" -type f 2>/dev/null | head -1)
  if [ -z "$HEADLESS" ]; then
    echo "FATAL: headless_shell binary not found under /opt/playwright-browsers"
    exit 10
  fi
fi

# --- check 1: build success (vite/static共通) ---
if [ -f package.json ] && grep -q '"build"' package.json; then
  echo "[smoke] running npm run build..."
  if ! npm run build > /tmp/smoke-build.log 2>&1; then
    echo "BUILD_FAIL"
    tail -50 /tmp/smoke-build.log
    exit 1
  fi
fi

# --- check 2: URL reachability (dev server が立っているか) ---
if ! curl -sf --max-time 5 -o /dev/null "$URL"; then
  echo "URL_UNREACHABLE: $URL"
  echo "  → dev server を別シェルで先に起動してください (例: npm run dev, python3 -m http.server 8080)"
  exit 5
fi

# --- check 3: must_contain_text の DOM 検証 ---
DOM=$("$HEADLESS" --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
      --virtual-time-budget=3000 --dump-dom "$URL" 2>/dev/null)
if [ -z "$DOM" ]; then
  echo "URL_UNREACHABLE: dumped DOM is empty"
  exit 5
fi

if [ -f docs/spec.json ]; then
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    if ! printf '%s' "$DOM" | grep -qF "$t"; then
      echo "MISSING_TEXT: $t"
      echo "  → docs/spec.json の must_contain_text にあるテキストが DOM に見つかりませんでした"
      exit 2
    fi
  done < <(jq -r '.must_contain_text[]?' docs/spec.json 2>/dev/null)
fi

# --- check 4: console.error 0 件 (playwright cr で起動・ログ収集) ---
echo "[smoke] checking console errors..."
CONSOLE_LOG=$(mktemp)
( timeout 6 npx -y playwright cr --headless "$URL" 2>"$CONSOLE_LOG" >/dev/null & ) 2>/dev/null
sleep 4
pkill -f "playwright" 2>/dev/null || true
sleep 1
if grep -E "(Uncaught|TypeError|ReferenceError|SyntaxError|console\.error)" "$CONSOLE_LOG" >/dev/null 2>&1; then
  echo "CONSOLE_ERROR"
  grep -E "(Uncaught|TypeError|ReferenceError|SyntaxError|console\.error)" "$CONSOLE_LOG" | head -20
  rm -f "$CONSOLE_LOG"
  exit 3
fi
rm -f "$CONSOLE_LOG"

# --- check 5: 3 viewport スクショ (375 / 768 / 1280) ---
mkdir -p screenshots
for w in 375 768 1280; do
  if ! npx -y playwright screenshot --browser chromium --viewport-size "$w,800" \
        "$URL" "screenshots/${w}.png" 2>/dev/null; then
    echo "SCREENSHOT_FAIL: $w"
    exit 4
  fi
done

echo "PASS"
exit 0
