// Prints the HTML for one store screenshot in its device, for store/render.sh:
//
//   node store/device.mjs <kind> <screenshot.png> <box width> <box height> \
//     <light|dark status bar> <id|en> [style]
//
// The device frame comes from store/bezels/ (tool/fetch_bezels.sh): Apple's
// product bezels for the App Store, Google's emulator skins for Google Play.
// Kinds are the device names in tool/screenshots/screenshots_test.dart, whose
// renders fill the frame's screen exactly; the Mac's is the app's window on
// its desktop, under the menu bar. The status bar shows 9:41, full
// signal, Wi-Fi and battery, from glyphs captured in the Simulator and the
// Android emulator, the clock drawn in the system's font: dark on light
// screens, light on dark ones. Half folded, the iPhone Duo bends in 3D, with
// the thickness of its halves.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const [kind, shot, boxW, boxH, tone, lang, style = ''] = process.argv.slice(2);
const bezels = join(dirname(fileURLToPath(import.meta.url)), 'bezels');
const file = (name) => `file://${join(bezels, name)}`;

// A PNG's size, from its header.
function size(path) {
  const b = readFileSync(path);
  return [b.readUInt32BE(16), b.readUInt32BE(20)];
}

const screens = Object.fromEntries(
  readFileSync(join(bezels, 'screens.txt'), 'utf8')
    .trim()
    .split('\n')
    .map((line) => {
      const [name, ...n] = line.split(' ');
      return [name, n.map(Number)];
    }),
);

// The frame each kind is drawn in; the half-folded Duo bends the open one.
const frameOf = { 'duo-table': 'duo', 'duo-book': 'duo-landscape' };
const frame = frameOf[kind] ?? kind;
const pixel = frame.startsWith('pixel');
const frameFile = pixel ? `${frame}-back.png` : `${frame}.png`;
const [fw, fh] = size(join(bezels, frameFile));
const [sx, sy, sw, sh, ...corners] = screens[frame];
// A corner with no curve (the Mac's screen meets its hinge) measures as
// huge: it is square.
const radii = corners.map((r) => (r > Math.min(sw, sh) / 2 ? 0 : r));
const [iw, ih] = size(shot);

const ink = tone === 'light' ? '#fff' : '#000';
const androidInk = tone === 'light' ? '#fff' : '#1f1f1f';

// A captured glyph image, tinted: its white shapes on black are the mask.
const glyph = (name, x, y, w, h, color = ink) =>
  `<i style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;` +
  `background:${color};-webkit-mask:url('${file(name)}') 0 0/100% 100%;` +
  `mask:url('${file(name)}') 0 0/100% 100% luminance"></i>`;

// Text with its digits' middle at (x, y): x is the left edge, or the middle
// when centred.
const text = (s, x, y, px, weight, family, spacing, color, centred = false) =>
  `<b style="position:absolute;left:${x}px;top:${y - px * 0.5}px;height:${px}px;` +
  `line-height:${px}px;font:${weight} ${px}px ${family};letter-spacing:${spacing}px;` +
  `color:${color};white-space:nowrap;${centred ? 'transform:translateX(-50%);' : ''}"><span style="position:relative;top:${-px * 0.02}px">${s}</span></b>`;

const sf = "-apple-system,'SF Pro Text',sans-serif";
const roboto = 'Roboto,sans-serif';
const date = lang === 'id' ? 'Sel 9 Jan' : 'Tue Jan 9';

// The Duo's status bar: the clock over a battery ring with Wi-Fi inside and
// the signal's four dots along its foot, down a side edge (in pixels at 3x).
function duoStack(cx, top) {
  const ring = 99, stroke = 9, r = (ring - stroke) / 2;
  const cy = top + 69;
  const arc = (from, to) => {
    const p = (a) => [ring / 2 + r * Math.sin((a * Math.PI) / 180), ring / 2 - r * Math.cos((a * Math.PI) / 180)];
    const [x1, y1] = p(from), [x2, y2] = p(to);
    return `M${x1} ${y1}A${r} ${r} 0 1 1 ${x2} ${y2}`;
  };
  const dots = [-33, -11, 11, 33]
    .map((a) => {
      const t = ((180 + a) * Math.PI) / 180;
      return `<circle cx="${ring / 2 + r * Math.sin(t)}" cy="${ring / 2 - r * Math.cos(t)}" r="5" fill="${ink}"/>`;
    })
    .join('');
  return (
    text('9:41', cx, top, 44, 600, sf, 1.5, ink, true) +
    `<svg style="position:absolute;left:${cx - ring / 2}px;top:${cy - ring / 2}px" width="${ring}" height="${ring}">` +
    `<path d="${arc(-128, 128)}" fill="none" stroke="${ink}" stroke-width="${stroke}" stroke-linecap="round"/>${dots}</svg>` +
    glyph('status-wifi.png', cx - 23, cy - 21, 46, 36)
  );
}

// The status bar in the screen's pixels.
function statusBar() {
  switch (kind) {
    case 'iphone':
      return text('9:41', 220, 96, 55, 600, sf, 2.5, ink, true) + glyph('status-iphone.png', 840, 60, 280, 75);
    case 'ipad':
    case 'ipad-portrait':
      return (
        text(`9:41<span style="margin-left:27px">${date}</span>`, 52, 32, 29, 500, sf, 1, ink) +
        glyph('status-ipad.png', sw - 39 - 165, 10, 165, 45)
      );
    case 'pixel':
      return text('9:41', 63, 85, 37, 400, roboto, 0.3, androidInk) + glyph('status-android.png', sw - 63 - 144, 85 - 31.5, 144, 63, androidInk);
    case 'pixel-landscape':
      return text('9:41', 157, 32, 37, 400, roboto, 0.3, androidInk) + glyph('status-android.png', sw - 63 - 144, 32 - 31.5, 144, 63, androidInk);
    case 'pixel-tablet':
    case 'pixel-tablet-portrait':
      return text('9:41', 18, 23, 28, 400, roboto, 0.2, androidInk) + glyph('status-android.png', sw - 45 - 110, 0, 110, 48, androidInk);
    case 'duo':
    case 'duo-landscape':
    case 'duo-table':
    case 'duo-book':
      return duoStack(sw - 90, 81);
    case 'duo-outer':
      return duoStack(1243.5, 261);
    case 'duo-outer-landscape':
      return duoStack(154, 261);
    default: // An iPhone held sideways shows none; the Mac has its menu bar
      return '';
  }
}

// The Mac's desktop (at 2x): its picture, the menu bar up to the screen's
// rounded top corners (the notch sits in the middle of it), and the app's
// window below, with its title bar.
function macDesktop() {
  const bar = 74;
  const item = (t, bold = false) =>
    `<span style="font-weight:${bold ? 700 : 500}">${t}</span>`;
  const menus = ['\uf8ff', 'Coba Lagi', 'Edit', 'View', 'Window', 'Help']
    .map((t, i) => item(t, i === 1))
    .join('');
  const clock = lang === 'id' ? 'Sel 9 Jan&nbsp;&nbsp;9:41' : 'Tue Jan 9&nbsp;&nbsp;9:41 AM';
  const title = 64, x = (sw - iw) / 2, y = bar + 26;
  const light = ['#ff5f57', '#febc2e', '#28c840']
    .map((c, i) => `<i style="position:absolute;left:${26 + i * 40}px;top:${title / 2 - 12}px;width:24px;height:24px;border-radius:50%;background:${c};box-shadow:inset 0 0 0 1px #0000001f"></i>`)
    .join('');
  return (
    `<img src="${file('mac-desktop.jpg')}" style="position:absolute;inset:0;width:${sw}px;height:${sh}px;object-fit:cover">` +
    `<div style="position:absolute;left:0;top:0;width:${sw}px;height:${bar}px;display:flex;align-items:center;justify-content:space-between;` +
    `padding:0 40px 0 44px;box-sizing:border-box;font:500 26px ${sf};color:#000;background:#ffffff38">` +
    `<div style="display:flex;gap:46px;align-items:center">${menus}</div>` +
    `<div style="display:flex;gap:34px;align-items:center">` +
    `<i style="display:block;width:31px;height:24px;background:#000;-webkit-mask:url('${file('status-wifi.png')}') 0 0/100% 100%;mask:url('${file('status-wifi.png')}') 0 0/100% 100% luminance"></i>` +
    `<i style="display:block;width:49px;height:26px;background:#000;-webkit-mask:url('${file('status-battery.png')}') 0 0/100% 100%;mask:url('${file('status-battery.png')}') 0 0/100% 100% luminance"></i>` +
    `<span>${clock}</span></div></div>` +
    `<div style="position:absolute;left:${x}px;top:${y}px;width:${iw}px;height:${ih + title}px;border-radius:32px;overflow:hidden;` +
    `box-shadow:0 0 0 1px #00000026,0 40px 90px -10px #00000066,0 12px 30px #0000002e;background:#f6f6f6">` +
    `<div style="position:relative;height:${title}px;background:#f2f2f2;border-bottom:1px solid #0000000f">${light}` +
    `<div style="text-align:center;line-height:${title}px;font:600 26px ${sf};color:#262626">Coba Lagi</div></div>` +
    `<img src="file://${shot}" style="display:block;width:${iw}px;height:${ih}px"></div>`
  );
}

// The flat device at the frame's own pixels.
const flat =
  `<div style="position:absolute;left:${sx}px;top:${sy}px;width:${sw}px;height:${sh}px;background:#000;overflow:hidden;border-radius:${radii.map((r) => `${r}px`).join(' ')}">` +
  (kind === 'mac' ? macDesktop() : `<img src="file://${shot}" style="position:absolute;left:0;top:0;width:${iw}px;height:${ih}px">${statusBar()}`) +
  `</div>` +
  `<img src="${file(frameFile)}" style="position:absolute;left:0;top:0;width:${fw}px;height:${fh}px">` +
  // The skin's mask covers the screen: its rounded corners and camera hole.
  (pixel ? `<img src="${file(`${frame}-mask.png`)}" style="position:absolute;left:${sx}px;top:${sy}px;width:${sw}px;height:${sh}px">` : '');

const scale = Math.min(boxW / fw, boxH / fh);
const shadow = `filter:drop-shadow(0 ${fh * scale * 0.025}px ${fh * scale * 0.03}px #0000005c)`;

if (kind !== 'duo-table' && kind !== 'duo-book') {
  process.stdout.write(
    `<div style="position:relative;flex:none;width:${fw * scale}px;height:${fh * scale}px;${shadow};${style}">` +
      `<div style="position:absolute;left:0;top:0;width:${fw}px;height:${fh}px;transform:scale(${scale});transform-origin:0 0">${flat}</div></div>`,
  );
  process.exit(0);
}

// Half folded. Each half is a slab: its face (the flat device, clipped to
// that half) over layers of the device's outline in its metal, stepped
// towards the edge we see, so the slab shows its thickness there. Only the
// slab turns in 3D, and the halves paint in order, so nothing sorts wrongly.
const book = kind === 'duo-book';
const depth = Math.min(fw, fh) * 0.032;
const layers = 14;
// clip <left> <top> <width> <height> <html> <dx> <dy>: the part of a
// full-size layer in one half, moved by (dx, dy).
const clip = (x, y, w, h, html, dx = 0, dy = 0) =>
  `<div style="position:absolute;left:${dx}px;top:${dy}px;width:${w}px;height:${h}px;overflow:hidden">` +
  `<div style="position:absolute;left:${-x}px;top:${-y}px;width:${fw}px;height:${fh}px">${html}</div></div>`;
const outline = (shade) =>
  `<div style="position:absolute;inset:0;background:${shade};` +
  `-webkit-mask:url('${file(frameFile)}') 0 0/100% 100%;mask:url('${file(frameFile)}') 0 0/100% 100% alpha"></div>` +
  `<div style="position:absolute;left:${sx}px;top:${sy}px;width:${sw}px;height:${sh}px;background:${shade};border-radius:${radii.map((r) => `${r}px`).join(' ')}"></div>`;
// slab <x> <y> <w> <h> <rim dx> <rim dy> <transform> <origin>
const slab = (x, y, w, h, rx, ry, transform, origin) => {
  let html = '';
  for (let i = layers; i >= 1; i--) {
    // Lit at the front edge, darker towards the back.
    const k = i / layers;
    const c = (a, b) => Math.round(a + (b - a) * k);
    html += clip(x, y, w, h, outline(`rgb(${c(74, 16)},${c(84, 20)},${c(104, 30)})`), rx * depth * k, ry * depth * k);
  }
  html += clip(x, y, w, h, flat);
  return (
    `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;` +
    `transform-origin:${origin};transform:${transform}">${html}</div>`
  );
};

let scene;
if (!book) {
  // On a table: the top half stands, leaning back a little; the bottom half
  // lies towards us, seen from a little above.
  const fy = Math.round(sy + sh / 2);
  scene =
    slab(0, 0, fw, fy, 0, -0.7, 'rotateX(12deg)', '50% 100%') +
    slab(0, fy, fw, fh - fy, 0, 2.2, 'rotateX(58deg)', '50% 0');
} else {
  // Like a book: both halves turn towards us from the fold.
  const fx = Math.round(sx + sw / 2);
  scene =
    slab(0, 0, fx, fh, -1.3, -0.3, 'rotateY(24deg)', '100% 50%') +
    slab(fx, 0, fw - fx, fh, 1.3, -0.3, 'rotateY(-24deg)', '0 50%');
}
// Bent, the device takes less room than flat, except where a half turns
// towards us; leave it a margin.
const s3 = Math.min(boxW / fw, boxH / fh) * (book ? 0.86 : 0.92);
process.stdout.write(
  `<div style="position:relative;flex:none;width:${fw * s3}px;height:${fh * s3 * (book ? 1 : 0.86)}px;${shadow};${style}">` +
    `<div style="position:absolute;left:0;top:0;width:${fw}px;height:${fh}px;transform:scale(${s3});transform-origin:0 0;` +
    `perspective:${Math.max(fw, fh) * 2.6}px;perspective-origin:50% ${book ? '40%' : '15%'}">` +
    `${scene}</div></div>`,
);
