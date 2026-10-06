#!/usr/bin/env bash
# Renders the Google Play graphics for each listing language with headless
# Chrome, from website/screenshots/ and branding/icon.svg:
#   store/<locale>/feature_graphic.png   1024 x 500
#   store/<locale>/screenshots/*.png     1920 x 1080 (16:9, tablets)
#   store/<locale>/phone_screenshots/*.png 1080 x 1920 (9:16, phones), from the
#     phone-*.png renders of tool/screenshots
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

# phone_slide <image> <caption> <out>: caption above a framed 400 x 760
# phone screenshot, in portrait.
phone_slide() {
  shot 1080 1920 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:56px;height:1920px\">
      <h1 style=\"font-size:72px;max-width:900px;text-align:center;line-height:1.1\">$2</h1>
      <div class=\"tablet\" style=\"padding:16px;border-radius:64px\"><img src=\"file://$ROOT/website/screenshots/$1\" style=\"height:1400px;border-radius:50px\"></div>
    </div>" "$3"
}

# phone_pair_slide <image> <image> <caption> <out>: two framed phone
# screenshots side by side, for related screens.
phone_pair_slide() {
  shot 1080 1920 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:56px;height:1920px\">
      <h1 style=\"font-size:72px;max-width:900px;text-align:center;line-height:1.1\">$3</h1>
      <div style=\"display:flex;align-items:flex-start\">
        <div class=\"tablet\" style=\"padding:12px;border-radius:48px;transform:rotate(-2deg)\"><img src=\"file://$ROOT/website/screenshots/$1\" style=\"height:1040px;display:block;border-radius:38px\"></div>
        <div class=\"tablet\" style=\"padding:12px;border-radius:48px;transform:rotate(2deg);margin-left:-150px;margin-top:240px\"><img src=\"file://$ROOT/website/screenshots/$2\" style=\"height:1040px;display:block;border-radius:38px\"></div>
      </div>
    </div>" "$4"
}

render_phone() { # locale suffix captions...
  local locale="$1" s="$2"; shift 2
  local dir="store/$locale/phone_screenshots"
  mkdir -p "$dir"
  rm -f "$dir/"*.png
  phone_slide "phone-adventure-map$s.png"   "$1" "$dir/1-adventure-map.png"
  phone_slide "phone-play-loops$s.png"      "$2" "$dir/2-play-loops.png"
  phone_slide "phone-play-code$s.png"       "$3" "$dir/3-code.png"
  phone_slide "phone-play-functions$s.png"  "$4" "$dir/4-play-functions.png"
  phone_slide "phone-play-conditions$s.png" "$5" "$dir/5-play-conditions.png"
  phone_slide "phone-solved$s.png"          "$6" "$dir/6-solved.png"
  phone_slide "phone-warm-up$s.png"         "$7" "$dir/7-warm-up.png"
  phone_pair_slide "phone-parent-placement$s.png" "phone-parent-progress$s.png" "$8" "$dir/8-parents.png"
}

# pair_slide <image> <image> <caption> <out>: two framed tablet screenshots
# side by side, slightly overlapping, for related screens.
pair_slide() {
  shot 1920 1080 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:36px;height:1080px\">
      <h1 style=\"font-size:72px\">$3</h1>
      <div style=\"display:flex;align-items:flex-start\">
        <div class=\"tablet\" style=\"padding:12px;border-radius:32px;transform:rotate(-2deg)\"><img src=\"file://$ROOT/website/screenshots/$1\" style=\"width:1040px;display:block;border-radius:20px\"></div>
        <div class=\"tablet\" style=\"padding:12px;border-radius:32px;transform:rotate(2deg);margin-left:-300px;margin-top:220px\"><img src=\"file://$ROOT/website/screenshots/$2\" style=\"width:1040px;display:block;border-radius:20px\"></div>
      </div>
    </div>" "$4"
}

# slide <image> <caption> <out>: caption above a framed 1280 x 740 screenshot.
slide() {
  shot 1920 1080 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:44px;height:1080px\">
      <h1 style=\"font-size:76px\">$2</h1>
      <div class=\"tablet\"><img src=\"file://$ROOT/website/screenshots/$1\" width=\"1280\" height=\"740\"></div>
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
  rm -f "store/$locale/screenshots/"*.png
  slide "adventure-map$s.png"   "$1" "store/$locale/screenshots/1-adventure-map.png"
  slide "play-loops$s.png"      "$2" "store/$locale/screenshots/2-play-loops.png"
  slide "play-code$s.png"       "$3" "store/$locale/screenshots/3-code.png"
  slide "play-functions$s.png"  "$4" "store/$locale/screenshots/4-play-functions.png"
  slide "play-conditions$s.png" "$5" "store/$locale/screenshots/5-play-conditions.png"
  slide "solved$s.png"          "$6" "store/$locale/screenshots/6-solved.png"
  slide "warm-up-pattern$s.png" "$7" "store/$locale/screenshots/7-warm-up.png"
  pair_slide "parent-placement$s.png" "parent-progress$s.png" "$8" "store/$locale/screenshots/8-parents.png"
}

render_locale id "-id" "Belajar coding sambil bermain" \
  "Jelajahi pulau-pulau coding" \
  "Blok bergambar, tanpa perlu membaca" \
  "Sudah bisa membaca? Ketik kode sungguhan" \
  "Buat blok sendiri, pakai berkali-kali" \
  "Periksa jalan sebelum melangkah" \
  "Setiap percobaan disambut dengan semangat" \
  "Permainan pemanasan menemukan titik awal" \
  "Orang tua memilih titik awal; sponsor melihat laporan"

render_locale en-US "" "Learn to code through play" \
  "Explore the coding islands" \
  "Picture blocks, no reading needed" \
  "Reading already? Type real code" \
  "Build your own block, use it again and again" \
  "Check the path before taking a step" \
  "Every try is met with encouragement" \
  "A warm-up game finds the right start" \
  "Parents set the start; sponsors see progress"

render_phone id "-id" \
  "Jelajahi pulau-pulau coding" \
  "Blok bergambar, tanpa perlu membaca" \
  "Sudah bisa membaca? Ketik kode sungguhan" \
  "Buat blok sendiri, pakai berkali-kali" \
  "Periksa jalan sebelum melangkah" \
  "Setiap percobaan disambut dengan semangat" \
  "Permainan pemanasan menemukan titik awal" \
  "Orang tua memilih titik awal; sponsor melihat laporan"

render_phone en-US "" \
  "Explore the coding islands" \
  "Picture blocks, no reading needed" \
  "Reading already? Type real code" \
  "Build your own block, use it again and again" \
  "Check the path before taking a step" \
  "Every try is met with encouragement" \
  "A warm-up game finds the right start" \
  "Parents set the start; sponsors see progress"

echo "Store graphics rendered."
