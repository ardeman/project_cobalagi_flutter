#!/usr/bin/env bash
# Renders each Lottie file in build/character/ as a strip of 8 frames
# (build/character/<name>.png) with lottie-web in headless Chrome, to review
# generated animations before any goes into the app. Developer tool only;
# it loads lottie-web from cdnjs.
#   tool/character_preview.sh [file.json ...]
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT
files=("$@")
[ ${#files[@]} -eq 0 ] && files=(build/character/*.json)
for json in "${files[@]}"; do
  name="$(basename "$json" .json)"
  frames=""
  for i in 0 1 2 3 4 5 6 7; do
    frames+="<div class=\"f\" id=\"f$i\"></div>"
  done
  cat > "$TMP/page.html" <<HTML
<!doctype html><html><head><meta charset="utf-8">
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>
<style>body{margin:0;background:#9fe2f0;display:flex;gap:8px;padding:8px}
.f{width:200px;height:200px;background:#fff1c9;border-radius:16px}</style></head>
<body>$frames<script>
const data = $(cat "$json");
for (let i = 0; i < 8; i++) {
  const a = lottie.loadAnimation({container: document.getElementById('f' + i),
    renderer: 'svg', loop: false, autoplay: false, animationData: data});
  a.goToAndStop(Math.floor((a.totalFrames - 1) * i / 7), true);
}
</script></body></html>
HTML
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --virtual-time-budget=3000 --window-size=1680,216 \
    --screenshot="build/character/$name.png" "file://$TMP/page.html" 2>/dev/null
  echo "build/character/$name.png"
done
