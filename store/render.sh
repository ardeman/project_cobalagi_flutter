#!/usr/bin/env bash
# Renders the store graphics for each listing language with headless Chrome,
# from the device renders in tool/screenshots/out/devices/ (run
# flutter test tool/screenshots --update-goldens first), the device frames in
# store/bezels/ (tool/fetch_bezels.sh) and branding/icon.svg. Every
# screenshot shows its real device around it, with its status bar
# (store/device.mjs), in each way it is held:
#   store/google_play/<locale>/feature_graphic.png     1024 x 500
#   store/google_play/<locale>/screenshots/*.png       1920 x 1080 (16:9, tablets):
#     Pixel Tablet, sideways and upright
#   store/google_play/<locale>/phone_screenshots/*.png 1080 x 1920 (9:16, phones):
#     Pixel 9, upright and sideways
#   store/app_store/<locale>/screenshots/iphone/*.jpg  1206 x 2622 (iPhone 6.3",
#     the size App Store Connect requires): iPhone 17, upright and sideways
#   store/app_store/<locale>/screenshots/ipad/*.jpg    2752 x 2064 (iPad 13"):
#     iPad Pro, sideways and upright
#   store/app_store/<locale>/screenshots/mac/*.jpg     2880 x 1800: MacBook Air
#   store/app_store/<locale>/screenshots/duo/*.jpg     2007 x 2853 (iPhone Duo):
#     open upright and sideways, closed both ways, half folded on a table and
#     like a book
#   store/app_store/<locale>/header.png, search_result.png (creative assets)
# Run from the project root: store/render.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/tool/screenshots/out/devices"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT

if [ ! -f "$OUT/pixel/adventure-map.png" ]; then
  echo "Missing $OUT: run flutter test tool/screenshots --update-goldens first." >&2
  exit 1
fi
if [ ! -f store/bezels/screens.txt ]; then
  echo "Missing store/bezels: run tool/fetch_bezels.sh first." >&2
  exit 1
fi
# Android's status bar clock is Roboto, which ships with Flutter.
FONTS="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")/bin/cache/artifacts/material_fonts"

# The character from the app icon, without its background.
CHARACTER="$(sed -n '/<g id="foreground">/,/^  <\/g>$/p' branding/icon.svg)"

STYLE="
  @font-face{font-family:Roboto;src:url('file://$FONTS/Roboto-Regular.ttf')}
"'
  html,body{margin:0}
  body{font-family:ui-rounded,"SF Pro Rounded",-apple-system,system-ui,sans-serif;color:#fff;
       background:radial-gradient(circle at 85% 15%,#ffb38a 0,transparent 45%),
                  radial-gradient(circle at 10% 95%,#ffc83d55 0,transparent 40%),
                  linear-gradient(180deg,#ff9a6b,#e85a37);overflow:hidden}
  h1{margin:0;font-weight:800;letter-spacing:0}
'

# shot <width> <height> <html body> <out.png>
shot() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>%s</style></head><body style="width:%spx;height:%spx">%s</body></html>' \
    "$STYLE" "$1" "$2" "$3" > "$TMP/page.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --window-size="$1,$2" --screenshot="$4" "file://$TMP/page.html" 2>/dev/null
}

# device <kind> <image> <box width> <box height> [style]: the screenshot
# $OUT/<image> in its device (store/device.mjs), as big as fits the box. The
# kind is the device's folder in $OUT; the map's dark sky gets a light status
# bar.
device() {
  local tone=dark lang=en
  case "$2" in *adventure-map*) tone=light ;; esac
  case "$2" in *-id.png) lang=id ;; esac
  node store/device.mjs "$1" "$OUT/$2" "$3" "$4" "$tone" "$lang" "${5:-}"
}

# slide <width> <height> <font size> <caption> <devices html> <out>: the
# caption above the devices.
slide() {
  shot "$1" "$2" "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:$(($3 * 2 / 3))px;height:$2px\">
      <h1 style=\"font-size:$3px;max-width:$(($1 * 9 / 10))px;text-align:center;line-height:1.1\">$4</h1>
      <div style=\"display:flex;align-items:center;justify-content:center\">$5</div>
    </div>" "$6"
}

# box_w <w>, box_h <h> <font>: room for the devices below the caption.
box_w() { echo $(($1 * 90 / 100)); }
box_h() { echo $(($1 - $2 * 4)); }

# one <w> <h> <font> <device> <screen> <suffix> <caption> <out>
one() {
  slide "$1" "$2" "$3" "$7" "$(device "$4" "$4/$5$6.png" "$(box_w "$1")" "$(box_h "$2" "$3")")" "$8"
}

# pair <w> <h> <font> <device> <screen> <screen> <suffix> <caption> <out>:
# two screens of one device, overlapping, for related screens.
pair() {
  local bw bh
  if [ "$1" -gt "$2" ]; then bw=$(($1 * 55 / 100)); bh=$(($2 * 62 / 100))
  else bw=$(($1 * 62 / 100)); bh=$(($2 * 55 / 100)); fi
  slide "$1" "$2" "$3" "$8" "<div style=\"display:flex;align-items:flex-start\">
      $(device "$4" "$4/$5$7.png" "$bw" "$bh" "transform:rotate(-2deg)")
      $(device "$4" "$4/$6$7.png" "$bw" "$bh" "transform:rotate(2deg);margin-left:-$((bw * 22 / 100))px;margin-top:$((bh * 22 / 100))px")
    </div>" "$9"
}

# turned <w> <h> <font> <device> <turned device> <screen> <suffix> <caption>
# <out>: one screen on a device held both ways, upright and sideways; the
# slide's own way gets the most room.
turned() {
  local up side
  if [ "$1" -gt "$2" ]; then
    side="$(device "$4" "$4/$6$7.png" $(($1 * 54 / 100)) $(($(box_h "$2" "$3") * 85 / 100)))"
    up="$(device "$5" "$5/$6$7.png" $(($1 * 34 / 100)) "$(box_h "$2" "$3")" "margin-left:$(($1 * 4 / 100))px")"
    slide "$1" "$2" "$3" "$8" "$side$up" "$9"
  else
    up="$(device "$4" "$4/$6$7.png" $(($1 * 80 / 100)) $(($(box_h "$2" "$3") * 56 / 100)))"
    side="$(device "$5" "$5/$6$7.png" "$(box_w "$1")" $(($(box_h "$2" "$3") * 36 / 100)) "margin-top:$(($2 * 3 / 100))px")"
    slide "$1" "$2" "$3" "$8" "<div style=\"display:flex;flex-direction:column;align-items:center\">$up$side</div>" "$9"
  fi
}

# set_of <w> <h> <font> <device> <slide 3: the device turned, or "" for
# none> <suffix> <out dir> captions...: the eight slides of one device.
set_of() {
  local w="$1" h="$2" f="$3" d="$4" t="$5" s="$6" dir="$7"
  shift 7
  mkdir -p "$dir"
  rm -f "${dir:?}/"*.png "${dir:?}/"*.jpg
  one "$w" "$h" "$f" "$d" adventure-map  "$s" "$1" "$dir/1-adventure-map.png"
  one "$w" "$h" "$f" "$d" play-loops     "$s" "$2" "$dir/2-play-loops.png"
  if [ -n "$t" ]; then
    turned "$w" "$h" "$f" "$d" "$t" play-code "$s" "$3" "$dir/3-code.png"
  else
    one "$w" "$h" "$f" "$d" play-code    "$s" "$3" "$dir/3-code.png"
  fi
  one "$w" "$h" "$f" "$d" play-functions "$s" "$4" "$dir/4-play-functions.png"
  one "$w" "$h" "$f" "$d" play-debugging "$s" "$5" "$dir/5-fix-it.png"
  one "$w" "$h" "$f" "$d" solved         "$s" "$6" "$dir/6-solved.png"
  one "$w" "$h" "$f" "$d" play-until     "$s" "$7" "$dir/7-until.png"
  pair "$w" "$h" "$f" "$d" parent-placement parent-progress "$s" "$8" "$dir/8-parents.png"
}

# duo_set <suffix> <out dir> captions...: the iPhone Duo in every way it is
# held: open upright, half folded on a table and like a book, open sideways,
# closed upright, open again, closed sideways, and open for the parents.
duo_set() {
  local s="$1" dir="$2" w=2007 h=2853 f=120
  shift 2
  mkdir -p "$dir"
  rm -f "${dir:?}/"*.png "${dir:?}/"*.jpg
  one "$w" "$h" "$f" duo                 adventure-map  "$s" "$1" "$dir/1-adventure-map.png"
  one "$w" "$h" "$f" duo-table           play-loops     "$s" "$2" "$dir/2-play-loops.png"
  one "$w" "$h" "$f" duo-book            play-code      "$s" "$3" "$dir/3-code.png"
  one "$w" "$h" "$f" duo-landscape       play-functions "$s" "$4" "$dir/4-play-functions.png"
  one "$w" "$h" "$f" duo-outer           play-debugging "$s" "$5" "$dir/5-fix-it.png"
  one "$w" "$h" "$f" duo                 solved         "$s" "$6" "$dir/6-solved.png"
  one "$w" "$h" "$f" duo-outer-landscape play-until     "$s" "$7" "$dir/7-until.png"
  pair "$w" "$h" "$f" duo parent-placement parent-progress "$s" "$8" "$dir/8-parents.png"
}

# JPEG halves the size, and the App Store takes it.
to_jpeg() {
  local png
  for png in "$1/"*.png; do
    sips -s format jpeg -s formatOptions 90 "$png" --out "${png%.png}.jpg" >/dev/null
    rm "$png"
  done
}

# feature <tagline> <suffix> <out>: Koba and the tagline beside a Pixel
# Tablet with a Pixel 9 in front of its corner.
feature() {
  shot 1024 500 "<div style=\"display:flex;align-items:center;height:500px;padding-left:56px;gap:8px\">
      <div style=\"width:380px;flex:none\">
        <svg viewBox=\"180 190 660 670\" width=\"138\" height=\"140\">$CHARACTER</svg>
        <h1 style=\"font-size:68px;margin-top:6px\">Coba Lagi</h1>
        <p style=\"font-size:30px;font-weight:700;margin:6px 0 0;opacity:.95\">$1</p>
      </div>
      <div style=\"position:relative;flex:none\">
        $(device pixel-tablet "pixel-tablet/play-loops$2.png" 500 340 "transform:rotate(-4deg);margin-top:-30px")
        <div style=\"position:absolute;left:410px;top:10px\">$(device pixel "pixel/play-code$2.png" 200 320 "transform:rotate(5deg)")</div>
      </div>
    </div>" "$3"
}

CAPTIONS_ID=(
  "Jelajahi planet-planet coding"
  "Blok bergambar, tanpa perlu membaca"
  "Sudah bisa membaca? Ketik kode sungguhan"
  "Buat blok sendiri, pakai berkali-kali"
  "Temukan blok yang belum pas, lalu betulkan"
  "Setiap percobaan disambut dengan semangat"
  "Ulangi terus sampai bendera, tanpa menghitung"
  "Orang tua memilih titik awal; sponsor melihat laporan"
)
CAPTIONS_EN=(
  "Explore the coding planets"
  "Picture blocks, no reading needed"
  "Reading already? Type real code"
  "Build your own block, use it again and again"
  "Find the block that isn't quite right, and fix it"
  "Every try is met with encouragement"
  "Repeat until the flag, no counting needed"
  "Parents set the start; sponsors see progress"
)

render_locale() { # locale suffix tagline captions...
  local locale="$1" s="$2" tagline="$3"; shift 3
  local play="store/google_play/$locale" apple="store/app_store/$locale/screenshots"
  feature "$tagline" "$s" "$play/feature_graphic.png"
  set_of 1920 1080 64 pixel-tablet pixel-tablet-portrait "$s" "$play/screenshots" "$@"
  set_of 1080 1920 68 pixel pixel-landscape "$s" "$play/phone_screenshots" "$@"
  set_of 1206 2622 84 iphone iphone-landscape "$s" "$apple/iphone" "$@"
  set_of 2752 2064 104 ipad ipad-portrait "$s" "$apple/ipad" "$@"
  set_of 2880 1800 100 mac "" "$s" "$apple/mac" "$@"
  duo_set "$s" "$apple/duo" "$@"
  local set
  for set in iphone ipad mac duo; do to_jpeg "$apple/$set"; done
}

render_locale id "-id" "Belajar coding sambil bermain" "${CAPTIONS_ID[@]}"
render_locale en-US "" "Learn to code through play" "${CAPTIONS_EN[@]}"

# App Store creative assets (Header and Search Results), PNG without alpha:
#   store/app_store/<locale>/header.png          3840 x 1646 (21:9, product page)
#   store/app_store/<locale>/search_result.png   3840 x 2560 (3:2, search results)
# The header is cropped on narrow screens, so Koba and the tagline sit in the
# middle, with an iPad and iPhones at the sides that may be cut off.
creative() { # locale suffix tagline
  local dir="store/app_store/$1" s="$2" tagline="$3"
  shot 3840 1646 "<div style=\"position:relative;height:1646px\">
      <div style=\"position:absolute;left:-180px;top:300px\">$(device ipad "ipad/adventure-map$s.png" 1500 1200 "transform:rotate(-6deg)")</div>
      <div style=\"position:absolute;left:3300px;top:280px\">$(device iphone "iphone/play-code$s.png" 560 1200 "transform:rotate(10deg)")</div>
      <div style=\"position:absolute;left:2760px;top:200px\">$(device iphone "iphone/play-loops$s.png" 560 1200 "transform:rotate(4deg)")</div>
      <div style=\"position:absolute;left:1220px;width:1400px;top:0;height:1646px;display:flex;flex-direction:column;align-items:center;justify-content:center\">
        <svg viewBox=\"180 190 660 670\" width=\"720\" height=\"730\">$CHARACTER</svg>
        <h1 style=\"font-size:150px;text-align:center;line-height:1.1;margin-top:40px\">$tagline</h1>
      </div>
    </div>" "$TMP/header.png"
  shot 3840 2560 "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;height:2560px;gap:110px\">
      <div style=\"display:flex;align-items:center;gap:60px\">
        <svg viewBox=\"180 190 660 670\" width=\"420\" height=\"426\">$CHARACTER</svg>
        <h1 style=\"font-size:170px\">$tagline</h1>
      </div>
      <div style=\"display:flex;align-items:flex-end\">
        $(device ipad "ipad/play-loops$s.png" 2500 1800)
        $(device iphone "iphone/play-code$s.png" 800 1600 "margin-left:-260px;margin-bottom:-60px;transform:rotate(4deg)")
      </div>
    </div>" "$TMP/search.png"
  # PNG: App Store Connect turns down .jpg here ("invalid extension"). Chrome's
  # screenshots have an alpha channel, which Apple refuses; a pass through JPEG
  # at full quality drops it.
  rm -f "$dir/header.jpg" "$dir/search_result.jpg"
  local name
  for name in header search; do
    sips -s format jpeg -s formatOptions 100 "$TMP/$name.png" --out "$TMP/$name.jpg" >/dev/null
    sips -s format png "$TMP/$name.jpg" --out "$TMP/$name-opaque.png" >/dev/null
  done
  mv "$TMP/header-opaque.png" "$dir/header.png"
  mv "$TMP/search-opaque.png" "$dir/search_result.png"
}

creative id -id "Belajar coding sambil bermain"
creative en-US "" "Learn to code through play"

echo "Store graphics rendered."
