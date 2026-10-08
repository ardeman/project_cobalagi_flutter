#!/usr/bin/env bash
# Shared helpers for the promo videos (invite_video.sh, promo_video.sh).
# Cards are HTML rendered by headless Chrome; gameplay comes from the frames
# that tool/screenshots records of the "Watch me!" demos:
#   VIDEO_FRAMES=1 flutter test tool/screenshots --update-goldens \
#     --plain-name 'video frames'
# Source this from the project root after setting W, H (video size).
set -euo pipefail

ROOT="$PWD"
OUT="build/marketing"
FRAMES="tool/screenshots/out/video"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT
mkdir -p "$OUT"
CHARACTER="$(sed -n '/<g id="foreground">/,/^  <\/g>$/p' branding/icon.svg)"
FADE=0.4
FPS=30

if [ ! -f "$FRAMES/loops-000.png" ]; then
  echo "No gameplay frames in $FRAMES. Record them first (see lib.sh)." >&2
  exit 1
fi

BASE_STYLE='
  html,body{margin:0;overflow:hidden}
  body{font-family:ui-rounded,"SF Pro Rounded",-apple-system,system-ui,sans-serif;color:#fff;
       background:radial-gradient(circle at 85% 12%,#ffb38a 0,transparent 45%),
                  radial-gradient(circle at 10% 92%,#ffc83d66 0,transparent 42%),
                  linear-gradient(180deg,#ff9a6b,#e0532f)}
  h1{margin:0;font-weight:900;letter-spacing:-1px;line-height:1.05}
  .device{position:absolute;background:#1d2b2b;box-shadow:0 40px 80px -30px #003030}
  .device img{display:block;width:100%;height:100%}
  .chip{display:inline-block;background:#ffffff26;border:3px solid #ffffff80;border-radius:999px;font-weight:800}
  .cta{display:inline-block;background:#ffc83d;color:#3a2a00;border-radius:999px;font-weight:900}
'

# card <html body> <extra css> <out.png>: one W x H picture.
card() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>%s html,body{width:%spx;height:%spx} %s</style></head><body>%s</body></html>' \
    "$BASE_STYLE" "$W" "$H" "$2" "$1" > "$TMP/page.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="$W,$H" --screenshot="$3" "file://$TMP/page.html" 2>/dev/null
}

# bezel <x> <y> <w> <h> <pad> <radius> <out.png>: a transparent picture
# with only the device's rounded bezel around the screen at x,y,w,h, laid
# over moving gameplay so its corners stay rounded.
bezel() {
  printf '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;width:%spx;height:%spx;background:transparent;overflow:hidden} div{position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border:%spx solid #1d2b2b;border-radius:%spx}</style></head><body><div></div></body></html>' \
    "$W" "$H" "$(($1 - $5))" "$(($2 - $5))" "$3" "$4" "$5" "$6" > "$TMP/bezel.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size="$W,$H" --screenshot="$7" "file://$TMP/bezel.html" 2>/dev/null
}

SEGMENTS=()
DURATIONS=()
# Narration: "<file>|<segment index>" entries, mixed over the music.
VOICES=()

# still <png> <seconds>: a card that slowly zooms in.
still() {
  local n=${#SEGMENTS[@]} out="$TMP/seg-${#SEGMENTS[@]}.mp4"
  ffmpeg -v error -y -framerate $FPS -loop 1 -t "$2" -i "$1" \
    -vf "scale=$((W * 2)):$((H * 2)),zoompan=z='min(1+0.0005*on,1.04)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${W}x${H}:fps=$FPS,setsar=1,format=yuv420p" \
    -t "$2" -c:v libx264 -preset fast -crf 16 "$out"
  SEGMENTS+=("$out")
  DURATIONS+=("$2")
}

# gameplay <background png> <bezel png> <frame prefix> <x> <y> <w> <h>
# <speed> [voice]: the recorded demo, played inside the device.
gameplay() {
  local out="$TMP/seg-${#SEGMENTS[@]}.mp4"
  local count
  count=$(ls "$FRAMES/$3"-[0-9][0-9][0-9].png | wc -l | tr -d ' ')
  local dur
  dur=$(echo "scale=3; $count / 10 / $8" | bc)
  ffmpeg -v error -y -framerate $FPS -loop 1 -t "$dur" -i "$1" \
    -framerate 10 -i "$FRAMES/$3-%03d.png" -loop 1 -i "$2" \
    -filter_complex "[1:v]setpts=PTS/$8,fps=$FPS,scale=$6:$7:flags=lanczos[g];[0:v][g]overlay=$4:$5:shortest=1[b];[b][2:v]overlay=0:0:shortest=1,setsar=1,format=yuv420p" \
    -t "$dur" -c:v libx264 -preset fast -crf 16 "$out"
  if [ -n "${9:-}" ]; then VOICES+=("$9|${#SEGMENTS[@]}"); fi
  SEGMENTS+=("$out")
  DURATIONS+=("$dur")
}

# finish <out.mp4>: cross-fades the segments, adds music and narration.
finish() {
  local inputs=() filters="" last="0:v" offset=0 starts=(0)
  for s in "${SEGMENTS[@]}"; do inputs+=(-i "$s"); done
  local n=${#SEGMENTS[@]}
  for ((i = 1; i < n; i++)); do
    offset=$(echo "$offset + ${DURATIONS[$((i - 1))]} - $FADE" | bc)
    starts+=("$offset")
    filters+="[$last][$i:v]xfade=transition=fade:duration=$FADE:offset=$offset[x$i];"
    last="x$i"
  done
  local total
  total=$(echo "$offset + ${DURATIONS[$((n - 1))]}" | bc)
  # Music under everything, a little softer when someone speaks.
  inputs+=(-stream_loop -1 -i assets/audio/music/theme.mp3)
  local music=$n mix="[music]" k=0
  filters+="[$music:a]atrim=0:$total,volume=0.45,afade=t=in:d=1,afade=t=out:st=$(echo "$total - 1.5" | bc):d=1.5[music];"
  for v in "${VOICES[@]}"; do
    local file="${v%%|*}" seg="${v##*|}"
    inputs+=(-i "$file")
    local delay
    delay=$(echo "(${starts[$seg]} + 0.6) * 1000 / 1" | bc)
    filters+="[$((music + 1 + k)):a]adelay=${delay}|${delay},volume=1.6[v$k];"
    mix+="[v$k]"
    k=$((k + 1))
  done
  filters+="${mix}amix=inputs=$((k + 1)):duration=first:normalize=0[a]"
  ffmpeg -v error -y "${inputs[@]}" -filter_complex "$filters" \
    -map "[$last]" -map "[a]" -c:v libx264 -preset slow -crf 19 -pix_fmt yuv420p \
    -r $FPS -c:a aac -b:a 192k -movflags +faststart -t "$total" "$1"
  echo "$1 (${total}s)"
  SEGMENTS=()
  DURATIONS=()
  VOICES=()
}
