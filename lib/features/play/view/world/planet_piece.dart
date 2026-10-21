import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'ink.dart';
import 'world_theme.dart';

// A piece cut out of a planet's surface, floating in space: the puzzle board
// is one, and the adventure map and the Star fuel story draw every planet the
// same way.

/// The outline of a piece of planet: [rect] with corners rounded by
/// [radius] and a gently uneven edge. [unit] is one board tile here, which
/// sets how uneven; the same [random] seed gives the same edge.
Path pieceOutline(
  Rect rect, {
  required double radius,
  required double unit,
  required Random random,
}) {
  final outline = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  final metric = outline.computeMetrics().single;
  final steps = (metric.length / unit * 5).round();
  final wobbly = Path();
  for (var i = 0; i < steps; i++) {
    final at = metric.getTangentForOffset(metric.length * i / steps)!;
    // Outward is to the left of the way round (the outline runs clockwise).
    final out = Offset(at.vector.dy, -at.vector.dx);
    final p = at.position + out * (random.nextDouble() * 0.07 * unit);
    i == 0 ? wobbly.moveTo(p.dx, p.dy) : wobbly.lineTo(p.dx, p.dy);
  }
  return wobbly..close();
}

/// A piece of planet floating in space, drawn like the puzzle board: its
/// surface, seen at a tilt, fills [top] in [ground] with [decor]'s odds and
/// ends on it, and its side shows [depth] thick below it in [side], all with
/// Koba's navy outline. [unit] is one board tile here (the size of the odds
/// and ends and the lines), and [squash] flattens the odds and ends for a
/// view from low down. [glow] lights the piece up around its edge.
void paintPlanetPiece(
  Canvas canvas,
  Rect top, {
  required Color ground,
  required Color side,
  required double unit,
  required double depth,
  Decor? decor,
  double squash = 1,
  int seed = 0,
  Color? glow,
}) {
  // Nothing to see (a planet growing in from nothing).
  if (top.isEmpty || unit <= 0) return;
  // The surface laid flat, in tiles; drawn squashed into [top].
  final flat = Rect.fromLTWH(
    0,
    0,
    top.width / unit,
    top.height / (unit * squash),
  );
  final toTop = Float64List.fromList([
    unit, 0, 0, 0, //
    0, unit * squash, 0, 0,
    0, 0, 1, 0,
    top.left, top.top, 0, 1,
  ]);
  final outline = pieceOutline(
    flat,
    radius: min(0.7, flat.shortestSide / 2),
    unit: 1,
    random: Random(seed),
  );
  final piece = outline.transform(toTop);
  final edge = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.5, unit * 0.03)
    ..strokeJoin = StrokeJoin.round;
  if (glow != null) {
    canvas.drawPath(
      piece.shift(Offset(0, depth / 2)),
      Paint()
        ..color = glow
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.3
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.2),
    );
  }
  // The side: the surface's outline, stacked down to the piece's depth.
  final sidePaint = Paint()..color = side;
  final layers = (depth / max(1, unit * 0.04)).ceil().clamp(8, 40);
  for (var i = 1; i <= layers; i++) {
    canvas.drawPath(piece.shift(Offset(0, depth * i / layers)), sidePaint);
  }
  // Its outline: the bottom's near half and the two outer edges (the far
  // half is behind the side).
  final bounds = piece.getBounds();
  final middle = bounds.center.dy;
  canvas
    ..save()
    ..clipRect(
      Rect.fromLTRB(
        bounds.left - unit,
        middle + depth,
        bounds.right + unit,
        bounds.bottom + depth + unit,
      ),
    )
    ..drawPath(piece.shift(Offset(0, depth)), edge)
    ..restore();
  for (final x in [bounds.left, bounds.right]) {
    canvas.drawLine(Offset(x, middle), Offset(x, middle + depth), edge);
  }
  canvas.drawPath(piece, Paint()..color = ground);
  if (decor != null) {
    canvas
      ..save()
      ..clipPath(piece)
      ..transform(toTop);
    final random = Random(seed * 7 + 1);
    final count = (flat.width * flat.height * 1.6).round();
    for (var i = 0; i < count; i++) {
      final at = Offset(
        random.nextDouble() * flat.width,
        random.nextDouble() * flat.height,
      );
      if (outline.contains(at)) drawDecor(canvas, at, decor, ground, random);
    }
    canvas.restore();
  }
  canvas.drawPath(piece, edge);
}
