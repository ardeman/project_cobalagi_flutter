#!/usr/bin/env bash
# Copies the renders from tool/screenshots/out/ (2x) into website/screenshots/
# at 1x, the size the README, website and store/render.sh use.
# Run after: flutter test tool/screenshots --update-goldens
set -euo pipefail
cd "$(dirname "$0")/../.."
for src in tool/screenshots/out/*.png; do
  name="$(basename "$src")"
  width="$(sips -g pixelWidth "$src" | awk '/pixelWidth/ {print $2}')"
  sips --resampleWidth "$((width / 2))" "$src" --out "website/screenshots/$name" >/dev/null
  echo "website/screenshots/$name"
done
