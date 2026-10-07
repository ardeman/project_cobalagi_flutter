#!/usr/bin/env bash
# Landscape (1920 x 1080) promo video for YouTube and the Google Play
# listing's video: real gameplay from the app's "Watch me!" demos between
# cards, with the app's music and narration. One per language:
#   build/marketing/promo-id.mp4, build/marketing/promo-en.mp4
# Run from the project root: tool/marketing/promo_video.sh
cd "$(dirname "$0")/../.."
W=1920
H=1080
source tool/marketing/lib.sh

# The tablet screen on gameplay and screenshot cards.
X=320 Y=262 SW=1280 SH=740 PAD=18 R=44
bezel $X $Y $SW $SH $PAD $R "$TMP/bezel.png"

# tablet_card <caption> <out> [screenshot]: caption above the tablet.
tablet_card() {
  local img=""
  if [ -n "${3:-}" ]; then
    img="<img src=\"file://$ROOT/website/screenshots/$3\" style=\"position:absolute;left:${PAD}px;top:${PAD}px;width:${SW}px;height:${SH}px;border-radius:$((R - PAD))px\">"
  fi
  card "<div class=\"device\" style=\"left:$((X - PAD))px;top:$((Y - PAD))px;width:$((SW + 2 * PAD))px;height:$((SH + 2 * PAD))px;border-radius:${R}px\">$img</div>
    <div style=\"position:absolute;left:0;right:0;top:56px;height:150px;display:flex;align-items:center;justify-content:center;text-align:center\"><h1 style=\"font-size:74px\">$1</h1></div>" "" "$2"
}

render() { # lang suffix tagline map blocks fix until code parents chips
  local lang="$1" s="$2"
  local title="<div style=\"display:flex;align-items:center;justify-content:center;gap:70px;height:${H}px\">
      <svg viewBox=\"200 200 640 560\" width=\"420\" height=\"368\">$CHARACTER</svg>
      <div><h1 style=\"font-size:140px\">Coba Lagi</h1><h1 style=\"font-size:64px;font-weight:800;opacity:.95;margin-top:18px\">$3</h1>
      <div style=\"display:flex;gap:16px;margin-top:40px;flex-wrap:wrap\">${10}</div></div></div>"
  card "$title" ".chip{font-size:36px;padding:10px 28px}" "$TMP/title.png"
  still "$TMP/title.png" 3.5

  tablet_card "$4" "$TMP/map.png" "adventure-map$s.png"
  still "$TMP/map.png" 3.5
  tablet_card "$5" "$TMP/c1.png"
  gameplay "$TMP/c1.png" "$TMP/bezel.png" "loops$s" $X $Y $SW $SH 1.25 "assets/audio/$lang/tutorial_loops.mp3"
  tablet_card "$6" "$TMP/c2.png"
  gameplay "$TMP/c2.png" "$TMP/bezel.png" "debugging$s" $X $Y $SW $SH 1.25 "assets/audio/$lang/tutorial_debugging.mp3"
  tablet_card "$7" "$TMP/c3.png"
  gameplay "$TMP/c3.png" "$TMP/bezel.png" "until$s" $X $Y $SW $SH 1.4 "assets/audio/$lang/tutorial_until.mp3"
  tablet_card "$8" "$TMP/code.png" "play-code$s.png"
  still "$TMP/code.png" 3.5
  tablet_card "$9" "$TMP/parents.png" "parent-progress$s.png"
  still "$TMP/parents.png" 3.5
  card "$title" ".chip{font-size:36px;padding:10px 28px}" "$TMP/end.png"
  still "$TMP/end.png" 4.5
  finish "$OUT/promo-$lang.mp4"
}

render id "-id" "Belajar coding sambil bermain" \
  "Jelajahi delapan pulau coding" \
  "Blok bergambar, tanpa perlu membaca" \
  "Belum pas? Temukan lalu betulkan" \
  "Ulangi sampai bendera, tanpa menghitung" \
  "Sudah bisa membaca? Ketik kode sungguhan" \
  "Orang tua bisa melihat perkembangan anak" \
  "<span class=\"chip\">Gratis</span><span class=\"chip\">Tanpa iklan</span><span class=\"chip\">Bahasa Indonesia &amp; English</span>"

render en "" "Learn to code through play" \
  "Explore eight coding islands" \
  "Picture blocks, no reading needed" \
  "Not quite right? Find it and fix it" \
  "Repeat until the flag, no counting needed" \
  "Reading already? Type real code" \
  "Parents can follow their child's progress" \
  "<span class=\"chip\">Free</span><span class=\"chip\">No ads</span><span class=\"chip\">Bahasa Indonesia &amp; English</span>"
