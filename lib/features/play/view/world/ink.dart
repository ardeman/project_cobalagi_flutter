import 'dart:math';
import 'dart:ui';

/// Koba's navy outline colour (`branding/robot.svg`).
const ink = Color(0xFF222244);

/// The arena's pieces in Koba's look: [draw]'s shapes, in world units
/// within [bounds], with a bold navy outline [width] units wide around
/// everything solid. See-through parts (soft shadows, glass) get no outline,
/// so shadows stay soft. Drawn once into an image of [pixelsPerUnit], as a
/// board's pieces never change; draw it back over [bounds].
Image inkedPiece(
  void Function(Canvas canvas) draw, {
  required Rect bounds,
  double width = 0.035,
  double pixelsPerUnit = 160,
}) {
  final pieceRecorder = PictureRecorder();
  draw(Canvas(pieceRecorder));
  final piece = pieceRecorder.endRecording();

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(pixelsPerUnit)
    ..translate(-bounds.left, -bounds.top);
  // The outline: the piece in navy, nudged all round. Each copy keeps only
  // what is mostly opaque (alpha over a half becomes solid, under it
  // disappears) before the copies overlap, or soft shadows would add up.
  final solidInk = Paint()
    ..colorFilter = const ColorFilter.matrix([
      0, 0, 0, 0, 0x22, //
      0, 0, 0, 0, 0x22, //
      0, 0, 0, 0, 0x44, //
      0, 0, 0, 8, -1020, //
    ]);
  const steps = 16;
  for (var i = 0; i < steps; i++) {
    final a = i * 2 * pi / steps;
    canvas
      ..saveLayer(bounds, solidInk)
      ..translate(cos(a) * width, sin(a) * width)
      ..drawPicture(piece)
      ..restore();
  }
  canvas.drawPicture(piece);
  final image = recorder.endRecording().toImageSync(
    (bounds.width * pixelsPerUnit).ceil(),
    (bounds.height * pixelsPerUnit).ceil(),
  );
  piece.dispose();
  return image;
}

final _smooth = Paint()..filterQuality = FilterQuality.medium;

/// Draws an image from [inkedPiece] back over its [bounds].
void drawInked(Canvas canvas, Image image, Rect bounds) => canvas.drawImageRect(
  image,
  Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
  bounds,
  _smooth,
);
