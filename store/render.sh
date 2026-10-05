#!/usr/bin/env bash
# Renders the Google Play graphics for each listing language with headless
# Chrome, from website/screenshots/ and branding/icon.svg:
#   store/<locale>/feature_graphic.png   1024 x 500
#   store/<locale>/screenshots/*.png     1920 x 1080 (16:9, for phone and tablet)
# Run from the project root: store/render.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT

# The character from the app icon, without its background.
CHARACTER="$(sed -n '/<g id="foreground">/,/<\/g>/p' branding/icon.svg)"

STYLE='
  html,body{margin:0}
  body{font-family:ui-rounded,"SF Pro Rounded",-apple-system,system-ui,sans-serif;color:#fff;
       background:radial-gradient(circle at 85% 15%,#2fd0d0 0,transparent 45%),
                  radial-gradient(circle at 10% 95%,#ffc83d55 0,transparent 40%),
                  linear-gradient(180deg,#14b8b8,#008c8c);overflow:hidden}
  .tablet{background:#1d2b2b;padding:18px;border-radius:44px;box-shadow:0 30px 60px -20px #00303088}
  .tablet img{display:block;border-radius:28px}
  h1{margin:0;font-weight:800;letter-spacing:0}
'

# shot <width> <height> <html body> <out.png>
shot() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>%s</style></head><body style="width:%spx;height:%spx">%s</body></html>' \
    "$STYLE" "$1" "$2" "$3" > "$TMP/page.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --window-size="$1,$2" --screenshot="$4" "file://$TMP/page.html" 2>/dev/null
}

# slide <image> <caption> <out>: caption above a framed 1280 x 740 screenshot.
slide() {
  shot 1920 1080 "<div style=\"display:flex;flex-direction:column;align-items:center;gap:44px;padding-top:70px\">
      <h1 style=\"font-size:76px\">$2</h1>
      <div class=\"tablet\"><img src=\"file://$ROOT/website/screenshots/$1\" width=\"1280\" height=\"740\"></div>
    </div>" "$3"
}

# dialog_slide <image> <caption> <out>: caption beside a framed dialog card.
dialog_slide() {
  shot 1920 1080 "<div style=\"display:flex;align-items:center;justify-content:center;gap:110px;height:1080px\">
      <h1 style=\"font-size:84px;max-width:720px;line-height:1.1\">$2</h1>
      <div class=\"tablet\" style=\"border-radius:56px\"><img src=\"file://$ROOT/website/screenshots/$1\" style=\"height:820px;border-radius:40px\"></div>
    </div>" "$3"
}

# feature <tagline> <screenshot> <out>
feature() {
  shot 1024 500 "<div style=\"display:flex;align-items:center;height:500px;padding-left:56px;gap:8px\">
      <div style=\"width:400px;flex:none\">
        <svg viewBox=\"200 200 640 560\" width=\"150\" height=\"131\">$CHARACTER</svg>
        <h1 style=\"font-size:68px;margin-top:6px\">Coba Lagi</h1>
        <p style=\"font-size:30px;font-weight:700;margin:6px 0 0;opacity:.95\">$1</p>
      </div>
      <div class=\"tablet\" style=\"padding:10px;border-radius:26px;transform:rotate(-4deg);margin-left:20px\">
        <img src=\"file://$ROOT/website/screenshots/$2\" style=\"width:560px;border-radius:17px\">
      </div>
    </div>" "$3"
}

render_locale() { # locale suffix tagline captions...
  local locale="$1" s="$2" tagline="$3"; shift 3
  mkdir -p "store/$locale/screenshots"
  feature "$tagline" "play-loops$s.png" "store/$locale/feature_graphic.png"
  slide "adventure-map$s.png"   "$1" "store/$locale/screenshots/1-adventure-map.png"
  slide "play-loops$s.png"      "$2" "store/$locale/screenshots/2-play-loops.png"
  slide "solved$s.png"          "$3" "store/$locale/screenshots/3-solved.png"
  slide "warm-up-pattern$s.png" "$4" "store/$locale/screenshots/4-warm-up.png"
  dialog_slide "parent-placement$s.png" "$5" "store/$locale/screenshots/5-parents.png"
}

render_locale id "-id" "Belajar coding sambil bermain" \
  "Jelajahi pulau-pulau coding" \
  "Blok bergambar, tanpa perlu membaca" \
  "Setiap percobaan disambut dengan semangat" \
  "Permainan pemanasan menemukan titik awal" \
  "Orang tua tetap memegang kendali"

render_locale en-US "" "Learn to code through play" \
  "Explore the coding islands" \
  "Picture blocks, no reading needed" \
  "Every try is met with encouragement" \
  "A warm-up game finds the right start" \
  "Parents stay in charge"

echo "Store graphics rendered."
