#!/usr/bin/env bash
# Renders the icon PNGs from the SVGs in branding/ with headless Chrome, then
# generates every platform's app icons. (The splash screen shows the whole
# robot from branding/robot.sh instead.) Run from the project root:
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
sips -Z 256 branding/icon.png --out linux/packaging/cobalagi.png >/dev/null

dart run flutter_launcher_icons
# flutter_launcher_icons 0.14.4 also rewrites an unrelated Xcode build setting
# (ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS); undo that.
git checkout -- ios/Runner.xcodeproj/project.pbxproj

# Liquid Glass icon (iOS and macOS 26+), as an Icon Composer document: the
# head as one glass layer over the sky's gradient. The system derives its
# dark, clear and tinted looks; older systems use the AppIcon.appiconset
# above (with dark and tinted versions from flutter_launcher_icons.yaml).
for dir in ios/Runner macos/Runner; do
  rm -rf "$dir/AppIcon.icon"
  mkdir -p "$dir/AppIcon.icon/Assets"
  cp branding/icon_foreground.png "$dir/AppIcon.icon/Assets/koba.png"
  cat > "$dir/AppIcon.icon/icon.json" <<'JSON'
{
  "fill" : {
    "linear-gradient" : [
      "srgb:1.00000,0.60392,0.41961,1.00000",
      "srgb:0.94118,0.38431,0.24706,1.00000"
    ],
    "orientation" : { "start" : { "x" : 0.5, "y" : 0 }, "stop" : { "x" : 0.5, "y" : 1 } }
  },
  "groups" : [
    {
      "layers" : [ { "image-name" : "koba.png", "name" : "koba" } ],
      "shadow" : { "kind" : "neutral", "opacity" : 0.5 },
      "translucency" : { "enabled" : true, "value" : 0.5 }
    }
  ],
  "supported-platforms" : { "squares" : "shared" }
}
JSON
done
echo "Icons generated."
