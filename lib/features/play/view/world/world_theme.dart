import 'dart:math';
import 'dart:ui';

/// What blocks the way on a planet.
enum Obstacle {
  moonRock,
  alienPlant,
  rock,
  crystal,
  iceSpike,
  cactus,
  crate,
  asteroid,
  hedge,
}

/// The planet's finish. Every one carries the red flag the voice talks
/// about ("reach the flag"), so the goal reads the same on every planet.
enum Finish { flag, dome, chest, castle, igloo, tent, toolbox, rocket, ufo }

/// How a planet's world looks: its sky, ground, obstacles and finish. Every
/// planet floats in space, so the sky is dark and starry; the ground tiles
/// stay light so the path reads clearly. Purely visual; the level decides
/// where things are.
final class WorldTheme {
  const WorldTheme({
    required this.background,
    required this.floor,
    required this.floorEdge,
    required this.obstacle,
    required this.finish,
  });

  /// The sky around the board, sprinkled with stars.
  final Color background;
  final Color floor;
  final Color floorEdge;
  final Obstacle obstacle;
  final Finish finish;

  /// Directions, and anything without a planet of its own: the Moon, with
  /// a flag to plant.
  static const moon = WorldTheme(
    background: Color(0xFF1B2150),
    floor: Color(0xFFE8EAF2),
    floorEdge: Color(0xFFB9BED3),
    obstacle: Obstacle.moonRock,
    finish: Finish.flag,
  );

  static const jungle = WorldTheme(
    background: Color(0xFF14303F),
    floor: Color(0xFFE3F4D2),
    floorEdge: Color(0xFFA9D48D),
    obstacle: Obstacle.alienPlant,
    finish: Finish.dome,
  );

  static const water = WorldTheme(
    background: Color(0xFF102E52),
    floor: Color(0xFFD8F1FA),
    floorEdge: Color(0xFF8ACFE6),
    obstacle: Obstacle.rock,
    finish: Finish.chest,
  );

  static const crystals = WorldTheme(
    background: Color(0xFF2A1E55),
    floor: Color(0xFFF8EAFB),
    floorEdge: Color(0xFFD5B3E6),
    obstacle: Obstacle.crystal,
    finish: Finish.castle,
  );

  static const ice = WorldTheme(
    background: Color(0xFF17304F),
    floor: Color(0xFFF1F8FF),
    floorEdge: Color(0xFFAFD0EA),
    obstacle: Obstacle.iceSpike,
    finish: Finish.igloo,
  );

  static const mars = WorldTheme(
    background: Color(0xFF35183A),
    floor: Color(0xFFFFE1CC),
    floorEdge: Color(0xFFE6A47F),
    obstacle: Obstacle.cactus,
    finish: Finish.tent,
  );

  static const station = WorldTheme(
    background: Color(0xFF1E2438),
    floor: Color(0xFFEEF1F8),
    floorEdge: Color(0xFFAAB3CC),
    obstacle: Obstacle.crate,
    finish: Finish.toolbox,
  );

  static const asteroids = WorldTheme(
    background: Color(0xFF233056),
    floor: Color(0xFFFFF4D6),
    floorEdge: Color(0xFFB9C2E8),
    obstacle: Obstacle.asteroid,
    finish: Finish.rocket,
  );

  /// An alien hedge maze, for following the walls on the Otherwise planet.
  static const maze = WorldTheme(
    background: Color(0xFF221C45),
    floor: Color(0xFFF2ECDB),
    floorEdge: Color(0xFFCDBB92),
    obstacle: Obstacle.hedge,
    finish: Finish.ufo,
  );

  /// One world per planet, keyed by concept id.
  static WorldTheme forConcept(String concept) => switch (concept) {
    'sequencing' => jungle,
    'loops' => water,
    'functions' => crystals,
    'conditions' => ice,
    'variables' => mars,
    'debugging' => station,
    'until' => asteroids,
    'otherwise' => maze,
    _ => moon,
  };
}

/// Stars scattered over [area] of the sky, the same every time.
void drawSky(Canvas canvas, Rect area) {
  final random = Random(11);
  final count = (area.width * area.height * 1.6).round().clamp(20, 600);
  for (var i = 0; i < count; i++) {
    final at = Offset(
      area.left + random.nextDouble() * area.width,
      area.top + random.nextDouble() * area.height,
    );
    final bright = random.nextDouble();
    canvas.drawCircle(
      at,
      0.015 + bright * 0.025,
      _fill(0xFFFFFFFF)
        ..color = Color.fromRGBO(255, 255, 255, 0.3 + bright * 0.6),
    );
  }
}

Paint _fill(int color) => Paint()..color = Color(color);

/// Draws [obstacle] in the unit cell at [cell], varied a little by [seed] so
/// neighbouring tiles don't look stamped out.
void drawObstacle(Canvas canvas, Rect cell, Obstacle obstacle, int seed) {
  final random = Random(seed);
  final c = cell.center;
  final s = 0.9 + random.nextDouble() * 0.2;
  final shadow = _fill(0x26000000);
  switch (obstacle) {
    case Obstacle.hedge:
      // A square-cut alien hedge, so the walls read as a maze.
      final hedge = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 0.84, height: 0.84),
        const Radius.circular(0.14),
      );
      canvas
        ..drawRRect(hedge.shift(const Offset(0.03, 0.05)), shadow)
        ..drawRRect(hedge, _fill(0xFF5B4BA8))
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c.dx - 0.42, c.dy - 0.42, 0.84, 0.3),
            const Radius.circular(0.14),
          ),
          _fill(0xFF7E6CD0),
        );
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          c +
              Offset(
                (random.nextDouble() - 0.5) * 0.56,
                (random.nextDouble() - 0.3) * 0.5,
              ),
          0.05,
          _fill(0xFFB9ACFF),
        );
      }
    case Obstacle.moonRock:
      // A round grey boulder with craters.
      canvas
        ..drawCircle(c + const Offset(0.03, 0.05), 0.32 * s, shadow)
        ..drawCircle(c, 0.32 * s, _fill(0xFF9196AE))
        ..drawCircle(c + Offset(-0.04, -0.05) * s, 0.26 * s, _fill(0xFFB8BCCF))
        ..drawCircle(c + Offset(-0.1, -0.08) * s, 0.07 * s, _fill(0xFF9196AE))
        ..drawCircle(c + Offset(0.1, 0.06) * s, 0.05 * s, _fill(0xFF9196AE));
      if (random.nextBool()) {
        canvas.drawCircle(
          c + Offset(-0.02, 0.14) * s,
          0.035 * s,
          _fill(0xFF9196AE),
        );
      }
    case Obstacle.alienPlant:
      // A mound with three stalks, each ending in a glowing bulb.
      final stalk = Paint()
        ..color = const Color(0xFF39B39A)
        ..strokeWidth = 0.05
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      const bulbs = [0xFFFF7AB6, 0xFFFFD54F, 0xFFB388FF];
      final bulb = _fill(bulbs[random.nextInt(bulbs.length)]);
      final ground = c + const Offset(0, 0.26);
      for (final dx in [-0.18, 0.0, 0.18]) {
        final tip = c + Offset(dx * s, (-0.2 + dx.abs() * 0.5) * s);
        canvas
          ..drawPath(
            Path()
              ..moveTo(ground.dx + dx * 0.4, ground.dy)
              ..quadraticBezierTo(
                ground.dx + dx * 1.4,
                (ground.dy + tip.dy) / 2,
                tip.dx,
                tip.dy,
              ),
            stalk,
          )
          ..drawCircle(tip, 0.08, bulb)
          ..drawCircle(
            tip + const Offset(-0.025, -0.025),
            0.025,
            _fill(0xCCFFFFFF),
          );
      }
      canvas.drawOval(
        Rect.fromCenter(center: ground, width: 0.62 * s, height: 0.2),
        _fill(0xFF2E8C7A),
      );
    case Obstacle.rock:
      final rock = Path()
        ..moveTo(c.dx - 0.34 * s, c.dy + 0.2)
        ..lineTo(c.dx - 0.26 * s, c.dy - 0.16)
        ..lineTo(c.dx - 0.02, c.dy - 0.3 * s)
        ..lineTo(c.dx + 0.28 * s, c.dy - 0.14)
        ..lineTo(c.dx + 0.34 * s, c.dy + 0.2)
        ..close();
      canvas
        ..drawPath(rock.shift(const Offset(0.03, 0.05)), shadow)
        ..drawPath(rock, _fill(0xFF9AA6B2))
        ..drawPath(
          Path()
            ..moveTo(c.dx - 0.26 * s, c.dy - 0.16)
            ..lineTo(c.dx - 0.02, c.dy - 0.3 * s)
            ..lineTo(c.dx + 0.04, c.dy)
            ..close(),
          _fill(0xFFC3CCD5),
        );
      if (random.nextInt(3) == 0) {
        // A little shell beside the rock.
        canvas.drawCircle(c + const Offset(0.28, 0.3), 0.07, _fill(0xFFFFCCBC));
      }
    case Obstacle.crystal:
      const tints = [0xFFB388FF, 0xFF80DEEA, 0xFFF48FB1];
      _crystals(canvas, c, s, tints[random.nextInt(tints.length)], const [
        (-0.14, 0.5, 0.16),
        (0.1, 0.62, 0.18),
      ]);
    case Obstacle.iceSpike:
      // Icicles poking up, pale blue.
      _crystals(canvas, c, s, 0xFFB3E5FC, const [
        (-0.2, 0.42, 0.09),
        (0.0, 0.66, 0.11),
        (0.2, 0.5, 0.09),
      ]);
    case Obstacle.cactus:
      final green = Paint()
        ..color = const Color(0xFF5DA65A)
        ..strokeWidth = 0.16 * s
        ..strokeCap = StrokeCap.round;
      final arms = Paint()
        ..color = const Color(0xFF5DA65A)
        ..strokeWidth = 0.1 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: c + const Offset(0, 0.34),
            width: 0.44,
            height: 0.1,
          ),
          shadow,
        )
        ..drawLine(c + const Offset(0, 0.3), c + Offset(0, -0.3 * s), green)
        ..drawPath(
          Path()
            ..moveTo(c.dx, c.dy + 0.06)
            ..lineTo(c.dx - 0.18, c.dy + 0.06)
            ..lineTo(c.dx - 0.18, c.dy - 0.12),
          arms,
        )
        ..drawPath(
          Path()
            ..moveTo(c.dx, c.dy - 0.02)
            ..lineTo(c.dx + 0.17, c.dy - 0.02)
            ..lineTo(c.dx + 0.17, c.dy - 0.2),
          arms,
        );
      if (random.nextBool()) {
        canvas.drawCircle(c + Offset(0, -0.32 * s), 0.05, _fill(0xFFF06292));
      }
    case Obstacle.crate:
      final side = 0.62 * s;
      final box = Rect.fromCenter(center: c, width: side, height: side);
      final wood = random.nextBool() ? 0xFFC58B52 : 0xFFB57B45;
      final plank = Paint()
        ..color = const Color(0xFF8D5A2B)
        ..strokeWidth = 0.04
        ..style = PaintingStyle.stroke;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            box.shift(const Offset(0.03, 0.05)),
            const Radius.circular(0.05),
          ),
          shadow,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(0.05)),
          _fill(wood),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            box.deflate(0.02),
            const Radius.circular(0.04),
          ),
          plank,
        )
        ..drawLine(
          box.topLeft + const Offset(0.05, 0.05),
          box.bottomRight - const Offset(0.05, 0.05),
          plank,
        )
        ..drawLine(
          box.topRight + const Offset(-0.05, 0.05),
          box.bottomLeft + const Offset(0.05, -0.05),
          plank,
        );
    case Obstacle.asteroid:
      final r = 0.3 * s;
      final bumpy = Path();
      for (var i = 0; i <= 10; i++) {
        final a = i * 2 * pi / 10;
        final d = r * (0.88 + 0.12 * ((i * 7 + seed) % 3) / 2);
        final p = c + Offset(cos(a), sin(a)) * d;
        if (i == 0) {
          bumpy.moveTo(p.dx, p.dy);
        } else {
          bumpy.lineTo(p.dx, p.dy);
        }
      }
      bumpy.close();
      canvas
        ..drawPath(bumpy.shift(const Offset(0.03, 0.05)), _fill(0x55000000))
        ..drawPath(bumpy, _fill(0xFF8E8AA6))
        ..drawCircle(c + Offset(-0.1, -0.06) * s, 0.07 * s, _fill(0xFF6E6A88))
        ..drawCircle(c + Offset(0.1, 0.08) * s, 0.05 * s, _fill(0xFF6E6A88));
      if (random.nextInt(3) == 0) {
        // A tiny star twinkling nearby.
        canvas.drawCircle(
          c + const Offset(0.36, -0.34),
          0.035,
          _fill(0xFFFFF59D),
        );
      }
  }
}

/// Crystal spikes standing on the bottom of the cell around [c]: each is
/// (offset, height, half width), lit on its left face.
void _crystals(
  Canvas canvas,
  Offset c,
  double s,
  int tint,
  List<(double, double, double)> spikes,
) {
  for (final (dx, h, w) in spikes) {
    final base = c + Offset(dx, 0.28);
    canvas
      ..drawPath(
        Path()
          ..moveTo(base.dx - w, base.dy)
          ..lineTo(base.dx - w, base.dy - h * s * 0.6)
          ..lineTo(base.dx, base.dy - h * s)
          ..lineTo(base.dx + w, base.dy - h * s * 0.6)
          ..lineTo(base.dx + w, base.dy)
          ..close(),
        _fill(tint),
      )
      ..drawPath(
        Path()
          ..moveTo(base.dx - w, base.dy)
          ..lineTo(base.dx - w, base.dy - h * s * 0.6)
          ..lineTo(base.dx, base.dy - h * s)
          ..lineTo(base.dx, base.dy)
          ..close(),
        _fill(0x66FFFFFF),
      );
  }
}

final _pole = Paint()
  ..color = const Color(0xFF8D6E63)
  ..strokeWidth = 0.06
  ..strokeCap = StrokeCap.round;
final _red = _fill(0xFFE53935);

/// The red flag, its pole running from [base] up by [height].
void _flag(Canvas canvas, Offset base, double height, {double scale = 1}) {
  final top = base - Offset(0, height);
  canvas
    ..drawLine(base, top, _pole)
    ..drawPath(
      Path()
        ..moveTo(top.dx + 0.03, top.dy)
        ..lineTo(top.dx + 0.03 + 0.36 * scale, top.dy + 0.12 * scale)
        ..lineTo(top.dx + 0.03, top.dy + 0.26 * scale)
        ..close(),
      _red,
    );
}

/// Draws [finish] in the unit square at the origin.
void drawFinish(Canvas canvas, Finish finish) {
  final base = _fill(0x33223355);
  switch (finish) {
    case Finish.flag:
      canvas.drawOval(const Rect.fromLTWH(0.2, 0.72, 0.6, 0.16), base);
      _flag(canvas, const Offset(0.38, 0.8), 0.66);
    case Finish.dome:
      // A glass dome with a little garden inside.
      final glass = Path()
        ..moveTo(0.16, 0.78)
        ..arcToPoint(
          const Offset(0.84, 0.78),
          radius: const Radius.circular(0.34),
        )
        ..close();
      canvas
        ..drawOval(const Rect.fromLTWH(0.12, 0.74, 0.76, 0.14), base)
        ..drawCircle(const Offset(0.38, 0.7), 0.08, _fill(0xFF66BB6A))
        ..drawCircle(const Offset(0.58, 0.68), 0.1, _fill(0xFF4CAF50))
        ..drawPath(glass, _fill(0x6681D4FA))
        ..drawPath(
          glass,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = 0.03
            ..style = PaintingStyle.stroke,
        )
        ..drawRect(
          const Rect.fromLTWH(0.14, 0.76, 0.72, 0.07),
          _fill(0xFF90A4AE),
        );
      _flag(canvas, const Offset(0.5, 0.45), 0.26, scale: 0.65);
    case Finish.chest:
      canvas
        ..drawOval(const Rect.fromLTWH(0.16, 0.74, 0.68, 0.14), base)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.2, 0.46, 0.6, 0.34),
            const Radius.circular(0.06),
          ),
          _fill(0xFFA1673F),
        )
        ..drawRect(const Rect.fromLTWH(0.2, 0.56, 0.6, 0.05), _fill(0xFFFFC83D))
        ..drawRect(
          const Rect.fromLTWH(0.46, 0.53, 0.08, 0.12),
          _fill(0xFFFFC83D),
        );
      _flag(canvas, const Offset(0.68, 0.48), 0.36, scale: 0.75);
    case Finish.castle:
      final wall = _fill(0xFFF8BBD0);
      canvas
        ..drawOval(const Rect.fromLTWH(0.12, 0.76, 0.76, 0.14), base)
        ..drawRect(const Rect.fromLTWH(0.2, 0.44, 0.6, 0.38), wall)
        ..drawRect(const Rect.fromLTWH(0.14, 0.3, 0.18, 0.52), wall)
        ..drawRect(const Rect.fromLTWH(0.68, 0.3, 0.18, 0.52), wall)
        ..drawPath(
          Path()
            ..moveTo(0.42, 0.82)
            ..lineTo(0.42, 0.64)
            ..arcToPoint(
              const Offset(0.58, 0.64),
              radius: const Radius.circular(0.08),
            )
            ..lineTo(0.58, 0.82)
            ..close(),
          _fill(0xFF9575CD),
        );
      for (final x in [0.14, 0.68]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 0.02, 0.31)
            ..lineTo(x + 0.09, 0.16)
            ..lineTo(x + 0.2, 0.31)
            ..close(),
          _fill(0xFF9575CD),
        );
      }
      _flag(canvas, const Offset(0.5, 0.44), 0.34, scale: 0.7);
    case Finish.igloo:
      final dome = Path()
        ..moveTo(0.14, 0.8)
        ..arcToPoint(
          const Offset(0.86, 0.8),
          radius: const Radius.circular(0.36),
        )
        ..close();
      final outline = Paint()
        ..color = const Color(0xFF7FA6C4)
        ..strokeWidth = 0.035
        ..style = PaintingStyle.stroke;
      canvas
        ..drawOval(const Rect.fromLTWH(0.1, 0.74, 0.8, 0.14), _fill(0x5590A4AE))
        ..drawPath(dome, _fill(0xFFDCEBF6))
        ..drawPath(dome, outline);
      final line = Paint()
        ..color = const Color(0xFF9FBFD6)
        ..strokeWidth = 0.025
        ..style = PaintingStyle.stroke;
      canvas
        ..drawLine(const Offset(0.19, 0.67), const Offset(0.81, 0.67), line)
        ..drawLine(const Offset(0.29, 0.55), const Offset(0.71, 0.55), line)
        ..drawPath(
          Path()
            ..moveTo(0.38, 0.8)
            ..arcToPoint(
              const Offset(0.62, 0.8),
              radius: const Radius.circular(0.12),
            )
            ..close(),
          _fill(0xFF4F6F86),
        );
      _flag(canvas, const Offset(0.5, 0.45), 0.3, scale: 0.7);
    case Finish.toolbox:
      final handle = Paint()
        ..color = const Color(0xFF546E7A)
        ..strokeWidth = 0.05
        ..style = PaintingStyle.stroke;
      canvas
        ..drawOval(const Rect.fromLTWH(0.14, 0.74, 0.72, 0.14), base)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.18, 0.5, 0.64, 0.3),
            const Radius.circular(0.05),
          ),
          _fill(0xFFE53935),
        )
        ..drawRect(
          const Rect.fromLTWH(0.18, 0.58, 0.64, 0.05),
          _fill(0xFFB71C1C),
        )
        ..drawRect(
          const Rect.fromLTWH(0.45, 0.56, 0.1, 0.09),
          _fill(0xFFFFC83D),
        )
        ..drawPath(
          Path()
            ..moveTo(0.36, 0.5)
            ..lineTo(0.36, 0.42)
            ..lineTo(0.56, 0.42)
            ..lineTo(0.56, 0.5),
          handle,
        );
      _flag(canvas, const Offset(0.72, 0.5), 0.36, scale: 0.7);
    case Finish.rocket:
      final body = Path()
        ..moveTo(0.5, 0.16)
        ..quadraticBezierTo(0.68, 0.36, 0.64, 0.72)
        ..lineTo(0.36, 0.72)
        ..quadraticBezierTo(0.32, 0.36, 0.5, 0.16)
        ..close();
      canvas
        ..drawOval(
          const Rect.fromLTWH(0.18, 0.78, 0.64, 0.12),
          _fill(0x55000000),
        )
        ..drawPath(
          Path()
            ..moveTo(0.36, 0.56)
            ..lineTo(0.24, 0.78)
            ..lineTo(0.38, 0.72)
            ..close(),
          _fill(0xFFE53935),
        )
        ..drawPath(
          Path()
            ..moveTo(0.64, 0.56)
            ..lineTo(0.76, 0.78)
            ..lineTo(0.62, 0.72)
            ..close(),
          _fill(0xFFE53935),
        )
        ..drawPath(body, _fill(0xFFF5F5F5))
        ..drawCircle(const Offset(0.5, 0.44), 0.07, _fill(0xFF4FC3F7))
        ..drawPath(
          Path()
            ..moveTo(0.42, 0.72)
            ..lineTo(0.5, 0.86)
            ..lineTo(0.58, 0.72)
            ..close(),
          _fill(0xFFFFB300),
        );
      _flag(canvas, const Offset(0.5, 0.2), 0.12, scale: 0.55);
    case Finish.ufo:
      // A flying saucer, landed, its lights on.
      canvas
        ..drawOval(const Rect.fromLTWH(0.16, 0.76, 0.68, 0.12), base)
        ..drawCircle(const Offset(0.5, 0.56), 0.16, _fill(0xFF80DEEA))
        ..drawCircle(const Offset(0.45, 0.51), 0.05, _fill(0xAAFFFFFF))
        ..drawOval(
          const Rect.fromLTWH(0.12, 0.56, 0.76, 0.2),
          _fill(0xFFB0BEC5),
        )
        ..drawOval(
          const Rect.fromLTWH(0.12, 0.56, 0.76, 0.1),
          _fill(0xFFCFD8DC),
        );
      for (final x in [0.26, 0.5, 0.74]) {
        canvas.drawCircle(Offset(x, 0.68), 0.035, _fill(0xFFFFD54F));
      }
      _flag(canvas, const Offset(0.5, 0.41), 0.22, scale: 0.6);
    case Finish.tent:
      canvas
        ..drawOval(const Rect.fromLTWH(0.12, 0.76, 0.76, 0.14), base)
        ..drawPath(
          Path()
            ..moveTo(0.14, 0.82)
            ..lineTo(0.5, 0.3)
            ..lineTo(0.86, 0.82)
            ..close(),
          _fill(0xFFFFB74D),
        )
        ..drawPath(
          Path()
            ..moveTo(0.5, 0.3)
            ..lineTo(0.62, 0.82)
            ..lineTo(0.38, 0.82)
            ..close(),
          _fill(0xFFE65100),
        );
      _flag(canvas, const Offset(0.5, 0.32), 0.24, scale: 0.7);
  }
}
