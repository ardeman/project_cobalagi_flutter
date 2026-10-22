#!/usr/bin/env bash
# Puts the device frames that store/render.sh draws around the store
# screenshots into store/bezels/ (git-ignored), named like the devices in
# tool/screenshots/screenshots_test.dart:
#   - Apple's product bezels (Apple Design Resources), for the App Store slides
#     only. Their license doesn't allow sharing them, so they never go in the
#     repo. Downloading them accepts that license; the user accepted it on
#     2026-10-23.
#   - The status bar glyphs (status-*.png, white on black: signal, Wi-Fi,
#     battery) are captured by hand from the iOS Simulator and the Android
#     emulator (README → Store listing); this script doesn't make them.
#   - Google's Pixel 9 and Pixel Tablet device art from the Android SDK's
#     emulator skins (install them with Android Studio's Device Manager), for
#     the Google Play slides.
# It also writes store/bezels/screens.txt: each frame's screen opening, as
# "<name> <x> <y> <width> <height>" and its corners' radii (top left, top
# right, bottom right, bottom left), in the frame's pixels.
# Run from the project root: tool/fetch_bezels.sh
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$PWD/store/bezels"
SKINS="${ANDROID_HOME:-$HOME/Library/Android/sdk}/skins"
TMP="$(mktemp -d)"
cleanup() {
  for m in "$TMP"/mnt/*; do [ -d "$m" ] && hdiutil detach -quiet "$m" || true; done
  rm -rf -- "${TMP:?}"
}
trap cleanup EXIT
mkdir -p "$OUT" "$TMP/mnt"

# apple <dmg name> <png in its PNG folder> <name>...: copies bezels out of one
# of Apple's disk images.
apple() {
  local dmg="$1"; shift
  curl -sSfL -o "$TMP/$dmg.dmg" "https://devimages-cdn.apple.com/design/resources/download/Bezel-$dmg.dmg"
  mkdir -p "$TMP/mnt/$dmg"
  # The image asks to accept its license before it mounts.
  hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$TMP/mnt/$dmg" "$TMP/$dmg.dmg" < <(yes) >/dev/null 2>&1
  while [ $# -gt 0 ]; do
    cp "$TMP/mnt/$dmg/PNG/$1" "$OUT/$2.png"
    shift 2
  done
  hdiutil detach -quiet "$TMP/mnt/$dmg"
  rm "$TMP/$dmg.dmg"
}

apple iPhone-17 \
  "iPhone 17/iPhone 17 - Black - Portrait.png" iphone \
  "iPhone 17/iPhone 17 - Black - Landscape.png" iphone-landscape
apple "iPad-Pro-(M5)" \
  'iPad Pro (M5) 13" - Space Black - Landscape.png' ipad \
  'iPad Pro (M5) 13" - Space Black - Portrait.png' ipad-portrait
apple MacBook-Air-M5 "MacBook Air M5 13-inch Midnight.png" mac
apple iPhone-Duo \
  "iPhone Duo - Night Sky - Inner Open Portrait.png" duo \
  "iPhone Duo - Night Sky - Inner Open Landscape.png" duo-landscape \
  "iPhone Duo - Night Sky - Outer Closed Portrait.png" duo-outer \
  "iPhone Duo - Night Sky - Outer Closed Landscape.png" duo-outer-landscape

# The Mac's desktop picture, a built-in macOS wallpaper, behind the app's
# window.
sips -s format jpeg -s formatOptions 92 -Z 2560 \
  "/System/Library/Desktop Pictures/Mac Blue.heic" --out "$OUT/mac-desktop.jpg" >/dev/null

# The skins draw the frame (back), then the screen, then a mask with the
# screen's corners and camera hole. Sideways, a Pixel's camera is on the left
# and a Pixel Tablet's on the right.
for part in back mask; do
  sips -s format png "$SKINS/pixel_9/$part.webp" --out "$OUT/pixel-$part.png" >/dev/null
  sips -r 270 "$OUT/pixel-$part.png" --out "$OUT/pixel-landscape-$part.png" >/dev/null
  sips -s format png "$SKINS/pixel_tablet/$part.webp" --out "$OUT/pixel-tablet-$part.png" >/dev/null
  sips -r 90 "$OUT/pixel-tablet-$part.png" --out "$OUT/pixel-tablet-portrait-$part.png" >/dev/null
done

# Each frame's screen: the see-through box around the middle, measured on a
# lines a third of the way across and down, clear of a notch, island or
# camera hole.
cat > "$TMP/screen.swift" <<'SWIFT'
import CoreGraphics
import Foundation
import ImageIO

for path in CommandLine.arguments.dropFirst() {
  let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
  let w = image.width, h = image.height
  var pixels = [UInt8](repeating: 0, count: w * h * 4)
  let context = CGContext(
    data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
  func clear(_ x: Int, _ y: Int) -> Bool { pixels[(y * w + x) * 4 + 3] < 128 }
  let cx = w / 3, cy = h / 3
  var left = w / 2, right = w / 2, top = h / 2, bottom = h / 2
  while left > 0 && clear(left - 1, cy) { left -= 1 }
  while right < w - 1 && clear(right + 1, cy) { right += 1 }
  while top > 0 && clear(cx, top - 1) { top -= 1 }
  while bottom < h - 1 && clear(cx, bottom + 1) { bottom += 1 }
  // Each corner's radius (top left, top right, bottom right, bottom left),
  // from how far its curve sits in along the diagonal: past the clear corner
  // outside the device (when it is rounder than the screen), then the frame.
  func radius(_ x0: Int, _ y0: Int, _ dx: Int, _ dy: Int) -> Int {
    var d = 0
    while d < (right - left) / 2 && clear(x0 + d * dx, y0 + d * dy) { d += 1 }
    while d < (right - left) / 2 && !clear(x0 + d * dx, y0 + d * dy) { d += 1 }
    return Int((Double(d) / (2.0.squareRoot() - 1)).rounded())
  }
  let radii = [
    radius(left, top, 1, 1), radius(right, top, -1, 1),
    radius(right, bottom, -1, -1), radius(left, bottom, 1, -1),
  ].map(String.init).joined(separator: " ")
  let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    .replacingOccurrences(of: "-back", with: "")
  print(name, left, top, right - left + 1, bottom - top + 1, radii)
}
SWIFT
swift "$TMP/screen.swift" "$OUT"/*.png 2>/dev/null | grep -v -- '-mask ' > "$OUT/screens.txt"
cat "$OUT/screens.txt"
