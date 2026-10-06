import 'package:flutter/painting.dart';

/// Shore-to-shore curves, with horizontal tangents on tablets and vertical
/// tangents below island labels on phones. No route crosses an island label.
List<Path> mapConnections({
  required List<Offset> centres,
  required double islandSize,
  required bool wide,
}) => [
  for (var i = 0; i + 1 < centres.length; i++)
    _connection(centres[i], centres[i + 1], islandSize, wide),
];

Path _connection(Offset from, Offset to, double size, bool wide) {
  final vertical = (to.dy - from.dy).sign;
  final a =
      from +
      (wide
          ? Offset(size * 0.68, size * (-0.1 + 0.16 * vertical))
          : Offset(0, size * 1.05));
  final b =
      to +
      (wide
          ? Offset(-size * 0.68, size * (-0.1 - 0.16 * vertical))
          : Offset(0, -size * 0.62));
  final tangent = wide
      ? Offset((b.dx - a.dx) * 0.55, 0)
      : Offset(0, (b.dy - a.dy) * 0.55);
  final controlA = a + tangent;
  final controlB = b - tangent;
  return Path()
    ..moveTo(a.dx, a.dy)
    ..cubicTo(controlA.dx, controlA.dy, controlB.dx, controlB.dy, b.dx, b.dy);
}
