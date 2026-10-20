#!/bin/sh
# Copies Koba's star ship from branding/ship/ (made by build_ship.py) into the
# app as 512-pixel WebP pictures: assets/images/ship_<view>.webp and the
# tank window's mask, ship_<view>_tank.webp. Half the size of the renders,
# so lib/features/story/view/ship_geometry.dart halves ship.json's pixels.
#
#   tool/ship/export.sh
set -eu
cd "$(dirname "$0")/../.."
for view in landed launch landing flying; do
  cwebp -quiet -resize 512 512 -q 88 -alpha_q 100 \
    "branding/ship/$view.png" -o "assets/images/ship_$view.webp"
  cwebp -quiet -resize 512 512 -lossless \
    "branding/ship/${view}_tank.png" -o "assets/images/ship_${view}_tank.webp"
done
