#!/usr/bin/env bash
# Vertical (1080 x 1920) promo short for YouTube Shorts, Instagram Reels and
# Stories, TikTok and WhatsApp status: a hook, real gameplay from the app's
# "Watch me!" demos with their narration, the space map, and an end card.
# About 30 seconds. One per language:
#   build/marketing/short-id.mp4, build/marketing/short-en.mp4, each with its
#   subtitles (.srt)
# Run from the project root: tool/marketing/short_video.sh
# Once the app is public on Google Play: STORE=live tool/marketing/short_video.sh
#
# Those apps lay their own buttons and captions over the video, so every
# word and the phone stay inside the middle: clear of the top 250 px, the
# bottom 380 px and the right 140 px.
cd "$(dirname "$0")/../.."
W=1080
H=1920
STORE="${STORE:-soon}"
source tool/marketing/lib.sh

# The phone screen on gameplay cards (the recorded phone frames' shape).
X=290 Y=560 SW=500 SH=950 PAD=14 R=54
bezel $X $Y $SW $SH $PAD $R "$TMP/bezel.png"

# phone_card <caption> <out> [screenshot]: caption above the phone.
phone_card() {
  local img=""
  if [ -n "${3:-}" ]; then
    img="<img src=\"file://$ROOT/website/screenshots/$3\" style=\"position:absolute;left:${PAD}px;top:${PAD}px;width:${SW}px;height:${SH}px;border-radius:$((R - PAD))px;object-fit:cover\">"
  fi
  card "<div class=\"device\" style=\"left:$((X - PAD))px;top:$((Y - PAD))px;width:$((SW + 2 * PAD))px;height:$((SH + 2 * PAD))px;border-radius:${R}px\">$img</div>
    <div style=\"position:absolute;left:90px;right:140px;top:250px;height:270px;display:flex;align-items:center;justify-content:center;text-align:center\"><h1 style=\"font-size:84px\">$1</h1></div>" "" "$2"
}

# centred <html>: a column in the safe middle of the frame.
centred() {
  echo "<div style=\"position:absolute;left:90px;right:140px;top:250px;bottom:380px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:48px;text-align:center\">$1</div>"
}

robot="<img src=\"file://$ROOT/assets/images/robot.png\" width=\"440\" height=\"440\" style=\"margin:-40px 0\">"

render() { # lang suffix hook hookSub blocks fix until map tagline chips store web
  local lang="$1" s="$2"
  card "$(centred "$robot<h1 style=\"font-size:92px\">$3</h1><h1 style=\"font-size:56px;font-weight:800;opacity:.95\">$4</h1>")" "" "$TMP/hook.png"
  still "$TMP/hook.png" 2.6

  phone_card "$5" "$TMP/c1.png"
  gameplay "$TMP/c1.png" "$TMP/bezel.png" "phone-loops$s" $X $Y $SW $SH 1.8 "assets/audio/$lang/tutorial_loops.mp3"
  phone_card "$6" "$TMP/c2.png"
  gameplay "$TMP/c2.png" "$TMP/bezel.png" "phone-debugging$s" $X $Y $SW $SH 1.6 "assets/audio/$lang/tutorial_debugging.mp3"
  phone_card "$7" "$TMP/c3.png"
  gameplay "$TMP/c3.png" "$TMP/bezel.png" "phone-until$s" $X $Y $SW $SH 2.2 "assets/audio/$lang/tutorial_until.mp3"
  phone_card "$8" "$TMP/map.png" "phone-adventure-map$s.png"
  still "$TMP/map.png" 2.8

  card "$(centred "<svg viewBox=\"180 190 660 670\" width=\"300\" height=\"305\">$CHARACTER</svg>
      <div><h1 style=\"font-size:120px\">Coba Lagi</h1><h1 style=\"font-size:56px;font-weight:800;opacity:.95;margin-top:14px\">$9</h1></div>
      <div style=\"display:flex;gap:16px;flex-wrap:wrap;justify-content:center\">${10}</div>
      <div class=\"cta\" style=\"font-size:48px;padding:26px 46px;white-space:nowrap\">${11}</div>
      <div style=\"font-size:44px;font-weight:800;opacity:.95\">${12}</div>")" \
    ".chip{font-size:40px;padding:12px 30px}" "$TMP/end.png"
  still "$TMP/end.png" 4.5
  finish "$OUT/short-$lang.mp4"
}

if [ "$STORE" = live ]; then
  store_id="Ada di Google Play" store_en="Get it on Google Play"
else
  store_id="Segera di Google Play" store_en="Coming soon to Google Play"
fi

render id "-id" \
  "Anak bisa belajar coding, bahkan sebelum bisa membaca" \
  "Dengan Coba Lagi" \
  "Susun blok, tuntun robot ke bendera" \
  "Belum pas?<br>Temukan lalu betulkan" \
  "Ulangi sampai bendera, tanpa menghitung" \
  "Jelajahi 9 planet coding" \
  "Belajar coding sambil bermain" \
  "<span class=\"chip\">Gratis</span><span class=\"chip\">Tanpa iklan</span><span class=\"chip\">Bisa offline</span><span class=\"chip\">Bahasa Indonesia &amp; English</span>" \
  "$store_id" \
  "cobalagi.ardeman.com"

render en "" \
  "Kids can learn to code, even before they can read" \
  "With Coba Lagi" \
  "Snap blocks, guide the robot to the flag" \
  "Not quite right?<br>Find it, fix it" \
  "Repeat until the flag, no counting needed" \
  "Explore 9 coding planets" \
  "Learn to code through play" \
  "<span class=\"chip\">Free</span><span class=\"chip\">No ads</span><span class=\"chip\">Works offline</span><span class=\"chip\">Bahasa Indonesia &amp; English</span>" \
  "$store_en" \
  "cobalagi.ardeman.com"
