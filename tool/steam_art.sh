#!/usr/bin/env bash
# Renders Coba Lagi's Steam library artwork with headless Chrome, into
# linux/steam/artwork/ (linux/steam/CobaLagi-Steam-Installer.sh installs it):
#   capsule.png  600 x 900    library grid
#   wide.png     920 x 430    recent games on the home screen
#   hero.png     1920 x 620   banner on the game's page (no text: Steam
#                             draws the logo over it)
#   logo.png     1280 x 400   the name, transparent
#   icon.png     256 x 256    the app icon
# Run from the project root (macOS): tool/steam_art.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="linux/steam/artwork"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT
mkdir -p "$OUT"

ROBOT="file://$ROOT/assets/images/robot.png"

# Coral like the icon, with a few stars: the adventure is in space.
STYLE='
  html,body{margin:0;overflow:hidden}
  body{font-family:ui-rounded,"SF Pro Rounded",-apple-system,system-ui,sans-serif;color:#fff}
  .sky{background:radial-gradient(circle at 85% 15%,#ffb38a 0,transparent 45%),
                  radial-gradient(circle at 10% 95%,#ffc83d55 0,transparent 40%),
                  radial-gradient(2px 2px at 12% 20%,#fff 50%,transparent 51%),
                  radial-gradient(3px 3px at 30% 70%,#fffc 50%,transparent 51%),
                  radial-gradient(2px 2px at 55% 12%,#fff 50%,transparent 51%),
                  radial-gradient(3px 3px at 72% 82%,#fffc 50%,transparent 51%),
                  radial-gradient(2px 2px at 90% 45%,#fff 50%,transparent 51%),
                  radial-gradient(2px 2px at 44% 40%,#fffa 50%,transparent 51%),
                  linear-gradient(180deg,#ff9a6b,#e85a37)}
  .robot{filter:drop-shadow(0 24px 30px #7a1f0055)}
  h1{margin:0;font-weight:800;letter-spacing:0;text-shadow:0 6px 0 #1e2a4a,0 10px 24px #7a1f0066}
'

# shot <width> <height> <html body> <out.png>
shot() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>%s</style></head><body style="width:%spx;height:%spx">%s</body></html>' \
    "$STYLE" "$1" "$2" "$3" > "$TMP/page.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --default-background-color=00000000 \
    --window-size="$1,$2" --screenshot="$4" "file://$TMP/page.html" 2>/dev/null
}

shot 600 900 "<div class=\"sky\" style=\"height:900px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px\">
    <h1 style=\"font-size:96px\">Coba Lagi</h1>
    <img class=\"robot\" src=\"$ROBOT\" width=\"520\" height=\"520\">
  </div>" "$OUT/capsule.png"

shot 920 430 "<div class=\"sky\" style=\"height:430px;display:flex;align-items:center;justify-content:center;gap:12px\">
    <img class=\"robot\" src=\"$ROBOT\" width=\"380\" height=\"380\">
    <h1 style=\"font-size:100px\">Coba Lagi</h1>
  </div>" "$OUT/wide.png"

shot 1920 620 "<div class=\"sky\" style=\"height:620px;position:relative\">
    <img class=\"robot\" src=\"$ROBOT\" width=\"600\" height=\"600\" style=\"position:absolute;right:160px;top:20px\">
  </div>" "$OUT/hero.png"

shot 1280 400 "<div style=\"height:400px;display:flex;align-items:center;justify-content:center\">
    <h1 style=\"font-size:200px\">Coba Lagi</h1>
  </div>" "$OUT/logo.png"

sips -z 256 256 branding/icon.png --out "$OUT/icon.png" >/dev/null
echo "Rendered $OUT"
