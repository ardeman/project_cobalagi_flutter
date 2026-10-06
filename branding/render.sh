#!/usr/bin/env bash
# Renders the icon PNGs from the SVGs in branding/ with headless Chrome, then
# generates every platform's app icons and the splash screen's
# assets/images/logo.png. Run from the project root:
#   branding/render.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT

# render <svg> <extra css> <out.png>
render() {
  printf '<!doctype html><html><head><style>html,body{margin:0;background:transparent}svg{display:block;width:1024px;height:1024px}%s</style></head><body>%s</body></html>' \
    "$2" "$(cat "$1")" > "$TMP/render.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size=1024,1024 --screenshot="$3" "file://$TMP/render.html" 2>/dev/null
}

render branding/icon.svg "" branding/icon.png
render branding/icon.svg "#background{display:none}" branding/icon_foreground.png
render branding/icon.svg "#foreground{display:none}" branding/icon_background.png
render branding/icon_monochrome.svg "" branding/icon_monochrome.png
sips -Z 512 branding/icon.png --out branding/play_store_icon.png >/dev/null
# The character for the in-app splash screen.
mkdir -p assets/images
sips -Z 512 branding/icon_foreground.png --out assets/images/logo.png >/dev/null

dart run flutter_launcher_icons
# flutter_launcher_icons 0.14.4 also rewrites an unrelated Xcode build setting
# (ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS); undo that.
git checkout -- ios/Runner.xcodeproj/project.pbxproj
echo "Icons generated."
