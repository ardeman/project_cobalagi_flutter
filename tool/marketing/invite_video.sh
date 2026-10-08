#!/usr/bin/env bash
# Vertical (1080 x 1920) video inviting friends to the Google Play closed
# test, for Instagram Stories, Reels, TikTok, WhatsApp status and Shorts:
# real gameplay from the app's "Watch me!" demos, ending with a request to
# send the email they use on Google Play. One per language:
#   build/marketing/invite-id.mp4, build/marketing/invite-en.mp4
# Run from the project root: tool/marketing/invite_video.sh
cd "$(dirname "$0")/../.."
W=1080
H=1920
source tool/marketing/lib.sh

# The phone screen on gameplay cards.
X=230 Y=560 SW=620 SH=1178 PAD=16 R=64
bezel $X $Y $SW $SH $PAD $R "$TMP/bezel.png"

# phone_card <caption> <out>: caption above an empty phone.
phone_card() {
  card "<div class=\"device\" style=\"left:$((X - PAD))px;top:$((Y - PAD))px;width:$((SW + 2 * PAD))px;height:$((SH + 2 * PAD))px;border-radius:${R}px\"></div>
    <div style=\"position:absolute;left:70px;right:70px;top:150px;height:370px;display:flex;align-items:center;justify-content:center;text-align:center\"><h1 style=\"font-size:88px\">$1</h1></div>" "" "$2"
}

render() { # lang suffix hook hookSub blocks fix until ctaTitle chips cta small
  local lang="$1" s="$2"
  card "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:56px;height:${H}px;padding:0 80px;text-align:center\">
      <svg viewBox=\"180 190 660 670\" width=\"374\" height=\"380\">$CHARACTER</svg>
      <h1 style=\"font-size:100px\">$3</h1><h1 style=\"font-size:58px;font-weight:800;opacity:.95\">$4</h1></div>" "" "$TMP/hook.png"
  still "$TMP/hook.png" 2.8

  phone_card "$5" "$TMP/c1.png"
  gameplay "$TMP/c1.png" "$TMP/bezel.png" "phone-loops$s" $X $Y $SW $SH 1.6 "assets/audio/$lang/tutorial_loops.mp3"
  phone_card "$6" "$TMP/c2.png"
  gameplay "$TMP/c2.png" "$TMP/bezel.png" "phone-debugging$s" $X $Y $SW $SH 1.6 "assets/audio/$lang/tutorial_debugging.mp3"
  phone_card "$7" "$TMP/c3.png"
  gameplay "$TMP/c3.png" "$TMP/bezel.png" "phone-until$s" $X $Y $SW $SH 2.0

  card "<div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;gap:56px;height:${H}px;padding:0 80px;text-align:center\">
      <svg viewBox=\"180 190 660 670\" width=\"256\" height=\"260\">$CHARACTER</svg>
      <h1 style=\"font-size:96px\">$8</h1>
      <div style=\"display:flex;gap:18px;flex-wrap:wrap;justify-content:center\">$9</div>
      <div class=\"cta\" style=\"font-size:62px;padding:32px 60px;line-height:1.15\">${10}</div>
      <div style=\"font-size:42px;font-weight:700;opacity:.92\">${11}</div></div>" \
    ".chip{font-size:46px;padding:14px 34px}" "$TMP/cta.png"
  still "$TMP/cta.png" 5
  finish "$OUT/invite-$lang.mp4"
}

render id "-id" \
  "Aku bikin game belajar coding buat bocil" \
  "Namanya Coba Lagi. Sekarang lagi uji coba tertutup di Google Play." \
  "Susun blok bergambar, robotnya jalan sampai bendera" \
  "Belum pas? Coba lagi, temukan lalu betulkan" \
  "9 planet coding, tanpa perlu bisa baca" \
  "Mau ikut uji coba?" \
  "<span class=\"chip\">Gratis</span><span class=\"chip\">Tanpa iklan</span><span class=\"chip\">Android</span>" \
  "DM aku email<br>Google Play kamu" \
  "Nanti aku kirim link buat gabung"

render en "" \
  "I made a coding game for kids" \
  "It's called Coba Lagi, and it's in closed testing on Google Play." \
  "Snap picture blocks together, guide the robot to the flag" \
  "Not quite right? Find it, fix it!" \
  "9 coding planets, no reading needed" \
  "Want to test it?" \
  "<span class=\"chip\">Free</span><span class=\"chip\">No ads</span><span class=\"chip\">Android</span>" \
  "DM me your<br>Google Play email" \
  "I'll send you the link to join"
