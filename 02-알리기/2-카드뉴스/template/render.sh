#!/bin/bash
# 카드뉴스 HTML → PNG (1080x1350)
# 사용: bash render.sh            → 이 폴더의 card-*.html 전부
#       bash render.sh 01 03      → 지정한 번호만
# 결과: ../output/card-NN.png  (output 폴더는 깃에 올라가지 않습니다)
# 필요: Chrome, Chromium, Edge 중 하나. 다른 위치에 있으면 CHROME=브라우저경로 bash render.sh
set -uo pipefail
cd "$(dirname "$0")"; DIR="$PWD"; OUT="$(dirname "$DIR")/output"
mkdir -p "$OUT"

find_chrome() {
  if [ -n "${CHROME:-}" ] && [ -x "$CHROME" ]; then echo "$CHROME"; return; fi
  for c in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
    "/c/Program Files/Google/Chrome/Application/chrome.exe" \
    "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  for n in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge; do
    command -v "$n" >/dev/null 2>&1 && { command -v "$n"; return; }
  done
}

CHROME_BIN="$(find_chrome)"
if [ -z "$CHROME_BIN" ]; then
  echo "Chrome/Chromium/Edge를 찾지 못했습니다. CHROME=브라우저경로 bash render.sh 로 지정하세요." >&2
  exit 1
fi

PROFILE="$(mktemp -d "${TMPDIR:-/tmp}/cardnews-profile.XXXXXX")"
trap 'rm -rf "$PROFILE"' EXIT
# 일부 Chrome은 결과 파일을 쓴 뒤에도 종료하지 않는다.
# 결과가 준비되면(또는 제한 시간이 지나면) 해당 브라우저만 종료한다.
# 사용: run_until 제한초 "준비판정명령" 브라우저명령...
run_until() {
  local limit="$1" ready="$2"; shift 2
  "$@" & local pid=$!
  local t=0
  while kill -0 "$pid" 2>/dev/null && [ "$t" -lt "$((limit*2))" ]; do
    if eval "$ready"; then sleep 1; break; fi
    sleep 0.5; t=$((t+1))
  done
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  return 0
}

FLAGS=(--headless --disable-gpu --hide-scrollbars --allow-file-access-from-files --user-data-dir="$PROFILE" --force-device-scale-factor=1 --window-size=1080,1350 --virtual-time-budget=8000)

if [ $# -gt 0 ]; then NUMS=("$@"); else
  NUMS=(); for f in card-*.html; do n="${f#card-}"; NUMS+=("${n%.html}"); done
fi

for n in "${NUMS[@]}"; do
  src="$DIR/card-$n.html"
  [ -f "$src" ] || { echo "card-$n: 파일 없음"; continue; }
  rm -f "$OUT/card-$n.png" "$PROFILE/dom.html"
  run_until 40 '[ -s "$OUT/card-$n.png" ]' "$CHROME_BIN" "${FLAGS[@]}" --screenshot="$OUT/card-$n.png" "file://$src" >/dev/null 2>&1
  run_until 40 'grep -q "</html>" "$PROFILE/dom.html" 2>/dev/null' "$CHROME_BIN" "${FLAGS[@]}" --dump-dom "file://$src" >"$PROFILE/dom.html" 2>/dev/null
  check="$(grep -o 'data-check="[^"]*"' "$PROFILE/dom.html" 2>/dev/null | sed 's/&quot;/"/g')"
  [ -n "$check" ] || check="(넘침 검사 결과를 받지 못했습니다. PNG를 열어 눈으로 확인하세요)"
  if [ -f "$OUT/card-$n.png" ]; then echo "card-$n: 저장됨 → output/card-$n.png  $check"; else echo "card-$n: 렌더 실패"; fi
done
echo "검사 결과 보는 법: problems 가 [] 이면 글자가 카드 밖으로 넘치지 않은 것입니다. faces 에 loaded 가 보이면 글꼴이 적용된 것입니다."
