import 'dart:math';

import 'package:flutter/painting.dart';

import 'package:cobalagi/core/character/robot_face.dart';
import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/view/star_ship.dart';

// Pictures shared by the Star fuel story's scenes, painted in code in Koba's
// colours with navy outlines.

/// The box a scene is laid out in, 1.6 times as wide as it is tall and as
/// big as fits in [stage], and its height (the scene's unit).
(Rect, double) storyBox(Rect stage) {
  final u = min(stage.width / 1.6, stage.height);
  return (Rect.fromCenter(center: stage.center, width: u * 1.6, height: u), u);
}

double storyLerp(double a, double b, double t) => a + (b - a) * t;

const storyInk = Color(0xFF222244);
const storyGold = Color(0xFFFFC83D);

/// A gold star like the ones Koba collects, of radius [r] around [c].
void paintStoryStar(
  Canvas canvas,
  Offset c,
  double r, {
  double opacity = 1,
  double turn = 0,
}) {
  final path = starPath(c, r, turn: turn * 0.3);
  canvas
    ..drawPath(path, Paint()..color = storyGold.withValues(alpha: opacity))
    ..drawPath(
      path,
      Paint()
        ..color = storyInk.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..strokeJoin = StrokeJoin.round,
    );
}

/// A far planet of radius [r] around [c].
void paintPlanet(Canvas canvas, Offset c, double r, Color color) {
  canvas
    ..drawCircle(c, r, Paint()..color = color)
    ..drawCircle(
      c + Offset(r * 0.25, r * 0.25),
      r * 0.75,
      Paint()..color = const Color(0x22000000),
    )
    ..drawCircle(
      c,
      r,
      Paint()
        ..color = storyInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, r * 0.08),
    );
}

/// Curved streaks blowing right to left, stronger with [gust].
void paintWind(Canvas canvas, Rect box, double u, double time, double gust) {
  final paint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * gust)
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(2, u * 0.012)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 7; i++) {
    final run = (time * 0.8 + i / 7) % 1;
    final x = box.right + u * 0.3 - run * (box.width + u * 0.6);
    final y = box.top + box.height * (0.1 + 0.12 * i);
    final length = u * (0.25 + 0.05 * (i % 3));
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + length / 2, y - u * 0.04, x + length, y)
        ..relativeArcToPoint(
          Offset(-u * 0.03, -u * 0.05),
          radius: Radius.circular(u * 0.03),
          clockwise: false,
        ),
      paint,
    );
  }
}

/// The planet's surface: a wide hill whose top is at [top], [color] on top
/// and [side] below.
void paintGround(
  Canvas canvas,
  Rect box,
  double top, {
  Color color = const Color(0xFFE6A15C),
  Color side = const Color(0xFFD08A4A),
}) {
  final radius = box.width * 2.5;
  final centre = Offset(box.center.dx, top + radius);
  canvas
    ..drawCircle(centre, radius, Paint()..color = color)
    ..drawCircle(
      centre + Offset(0, box.height * 0.08),
      radius,
      Paint()..color = side,
    )
    ..drawCircle(
      centre,
      radius,
      Paint()
        ..color = storyInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
}

/// A rock standing on the ground at [base].
void paintRock(Canvas canvas, Offset base, double u) {
  final w = u * 0.16;
  final h = u * 0.12;
  final path = Path()
    ..moveTo(base.dx - w / 2, base.dy)
    ..cubicTo(
      base.dx - w * 0.6,
      base.dy - h * 0.8,
      base.dx - w * 0.1,
      base.dy - h * 1.2,
      base.dx + w * 0.15,
      base.dy - h,
    )
    ..cubicTo(
      base.dx + w * 0.5,
      base.dy - h * 0.9,
      base.dx + w * 0.6,
      base.dy - h * 0.3,
      base.dx + w / 2,
      base.dy,
    )
    ..close();
  canvas
    ..drawPath(path, Paint()..color = const Color(0xFF8A90B4))
    ..drawCircle(
      Offset(base.dx - w * 0.1, base.dy - h * 0.7),
      w * 0.08,
      Paint()..color = const Color(0xFFB4B9D8),
    )
    ..drawPath(
      path,
      Paint()
        ..color = storyInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, u * 0.008)
        ..strokeJoin = StrokeJoin.round,
    );
}

/// A planet's [obstacle], as on its board, standing on the ground at [base]
/// and [size] wide; [seed] varies it.
void paintObstacle(
  Canvas canvas,
  Obstacle obstacle,
  Offset base,
  double size, {
  int seed = 0,
}) {
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..scale(size);
  drawObstacle(
    canvas,
    Rect.fromCenter(center: const Offset(0, -0.36), width: 1, height: 1),
    obstacle,
    seed,
  );
  canvas.restore();
}

/// Dust puffing out from under the landed ship, [p] (0 to 1) through.
void paintDust(Canvas canvas, Offset base, double u, double p) {
  final paint = Paint()
    ..color = const Color(0xFFF6E3C8).withValues(alpha: (1 - p) * 0.8);
  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        base + Offset(side * u * (0.08 + 0.12 * p + 0.05 * i), -u * 0.02 * i),
        u * (0.03 + 0.02 * p),
        paint,
      );
    }
  }
}

/// Koba from the side (facing right, or left when [mirror]ed) or, with
/// [front], facing the child, standing at [base] in a picture [size] wide.
void paintKoba(
  Canvas canvas,
  StoryArt art, {
  required Offset base,
  required double size,
  required RobotFace face,
  required double time,
  bool front = false,
  bool mirror = false,
  double angle = 0,
  Offset gaze = Offset.zero,
}) {
  // Where the wheels touch the ground in the 512-pixel pictures.
  final foot = front ? const Offset(256, 500) : const Offset(270, 500);
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle)
    ..scale(mirror ? -size / 512 : size / 512, size / 512)
    ..translate(-foot.dx, -foot.dy)
    ..drawImage(front ? art.robotFront : art.robot, Offset.zero, Paint());
  paintRobotFace(canvas, face, time: time, front: front, gaze: gaze);
  canvas.restore();
}
