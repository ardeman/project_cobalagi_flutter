import 'dart:math';

import 'package:flutter/painting.dart';

import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/story/data/story_art.dart';

final _fuel = Paint()..color = const Color(0xFFFFC83D);
final _fuelShine = Paint()..color = const Color(0xFFFFF3C4);

/// Paints the ship as [view] with its [base] (the engine's middle) at a
/// point on [canvas], its picture [size] wide, turned by [angle] and
/// [mirror]ed to face left. Its tank is [fill] full (0 to 1) and Koba's
/// [face] looks out of the cockpit, unless Koba is out of the ship
/// ([koba] false); [time] (seconds) makes it blink.
void paintShip(
  Canvas canvas,
  StoryArt art,
  ShipView view, {
  required Offset base,
  required double size,
  double fill = 0,
  double angle = 0,
  bool mirror = false,
  RobotFace face = RobotFace.normal,
  bool koba = true,
  double time = 0,
  double opacity = 1,
}) {
  if (opacity <= 0) return;
  final g = ShipGeometry.of(view);
  final scale = size / ShipGeometry.picture;
  const box = Rect.fromLTWH(0, 0, ShipGeometry.picture, ShipGeometry.picture);
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle)
    ..scale(mirror ? -scale : scale, scale)
    ..translate(-g.base.dx, -g.base.dy);
  if (opacity < 1) {
    canvas.saveLayer(
      box,
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0, 1)),
    );
  }
  canvas.drawImage(art.ships[view]!, Offset.zero, Paint());

  // The fuel: a bar along the tank's axis, clipped by its window's mask.
  if (fill > 0) {
    final axis = g.tankTop - g.tankBottom;
    final along = axis / axis.distance;
    final across = Offset(-along.dy, along.dx) * g.tankWidth;
    // Empty sits just below the window and full just above it.
    final level = g.tankBottom + axis * (fill.clamp(0, 1) * 1.2 - 0.1);
    final start = g.tankBottom - along * g.tankWidth;
    canvas.saveLayer(box, Paint());
    canvas.drawPath(
      Path()..addPolygon([
        start - across,
        start + across,
        level + across,
        level - across,
      ], true),
      _fuel,
    );
    // Twinkles rising in the fuel.
    for (var i = 0; i < 3; i++) {
      final rise = (time * 0.4 + i / 3) % 1;
      final at =
          g.tankBottom +
          axis * (rise * fill) +
          across * (0.15 * sin(time * 2 + i * 2));
      canvas.drawCircle(at, 2.5 + i.toDouble(), _fuelShine);
    }
    canvas
      ..drawImage(
        art.tanks[view]!,
        Offset.zero,
        Paint()..blendMode = BlendMode.dstIn,
      )
      ..restore();
  }

  // Koba looks out of the round window.
  if (koba) {
    canvas
      ..save()
      ..translate(g.cockpit.dx, g.cockpit.dy)
      ..scale((mirror ? -1 : 1) * g.cockpitRadius / 100, g.cockpitRadius / 100);
    paintRobotFace(canvas, face, time: time, at: Offset.zero);
    canvas.restore();
  }

  if (opacity < 1) canvas.restore();
  canvas.restore();
}

/// A five-pointed star of radius [r] around [c], for the stars Koba collects.
Path starPath(Offset c, double r, {double turn = 0}) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final a = -pi / 2 + turn + i * pi / 5;
    final p = c + Offset(cos(a), sin(a)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Where the tank's middle is when the ship is painted as by [paintShip].
Offset tankPoint(
  ShipView view, {
  required Offset base,
  required double size,
  double angle = 0,
  bool mirror = false,
}) {
  final g = ShipGeometry.of(view);
  final scale = size / ShipGeometry.picture;
  var p = ((g.tankBottom + g.tankTop) / 2 - g.base) * scale;
  if (mirror) p = Offset(-p.dx, p.dy);
  return base +
      Offset(
        p.dx * cos(angle) - p.dy * sin(angle),
        p.dx * sin(angle) + p.dy * cos(angle),
      );
}
