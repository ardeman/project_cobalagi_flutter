import 'package:flutter/painting.dart';

/// Curves from planet to planet, leaving and landing just off each planet's
/// edge: sideways on tablets (labels sit below the planets), and from the
/// bottom of one planet to the top of the next on phones (labels sit beside
/// them). No route crosses a planet label.
List<Path> mapConnections({
  required List<Offset> centres,
  required double islandSize,
  required bool wide,
}) => [
  for (var i = 0; i + 1 < centres.length; i++)
    _connection(
      planetCentre(centres[i], islandSize),
      planetCentre(centres[i + 1], islandSize),
      islandSize,
      wide,
    ),
];

/// Where the planet drawn for the map point [at] has its centre: the
/// planet stands above the point, which also places its label.
Offset planetCentre(Offset at, double size) => at - Offset(0, size * 0.42);

/// Room between a planet's middle and where its path starts sideways: half
/// the piece's width (0.46 sizes) and a small gap.
const _reach = 0.5;

/// On phones, paths leave a little below the piece's underside (0.31 sizes
/// below its middle) and land a little above its top (0.2 above), off to
/// the side of the emblem standing in its middle.
const _below = 0.38;
const _above = 0.3;
const _aside = 0.32;

Path _connection(Offset from, Offset to, double size, bool wide) {
  final side = (to.dx - from.dx).sign;
  final a = wide
      ? from + Offset(size * _reach, 0)
      : from + Offset(side * size * _aside, size * _below);
  final b = wide
      ? to - Offset(size * _reach, 0)
      : to - Offset(side * size * _aside, size * _above);
  final tangent = wide
      ? Offset((b.dx - a.dx) * 0.55, 0)
      : Offset(0, (b.dy - a.dy) * 0.55);
  final controlA = a + tangent;
  final controlB = b - tangent;
  return Path()
    ..moveTo(a.dx, a.dy)
    ..cubicTo(controlA.dx, controlA.dy, controlB.dx, controlB.dy, b.dx, b.dy);
}
