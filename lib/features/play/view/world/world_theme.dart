import 'dart:math';
import 'dart:ui';

/// What blocks the way on an island.
enum Obstacle {
  bush,
  flowerBush,
  rock,
  crystal,
  pine,
  cactus,
  crate,
  asteroid,
  hedge,
}

/// The island's finish. Every one carries the red flag the voice talks
/// about ("reach the flag"), so the goal reads the same on every island.
enum Finish {
  flag,
  house,
  chest,
  castle,
  igloo,
  tent,
  toolbox,
  rocket,
  treehouse,
}

/// How an island's world looks: background, path, obstacles and finish.
/// Purely visual; the level decides where things are.
final class WorldTheme {
  const WorldTheme({
    required this.background,
    required this.floor,
    required this.floorEdge,
    required this.obstacle,
    required this.finish,
  });

  final Color background;
  final Color floor;
  final Color floorEdge;
  final Obstacle obstacle;
  final Finish finish;

  /// Directions, and anything without an island of its own.
  static const meadow = WorldTheme(
    background: Color(0xFFBFE6FF),
    floor: Color(0xFFFFF1C9),
    floorEdge: Color(0xFFF2D99A),
    obstacle: Obstacle.bush,
    finish: Finish.flag,
  );

  static const garden = WorldTheme(
    background: Color(0xFFD5F2C4),
    floor: Color(0xFFEFE8DD),
    floorEdge: Color(0xFFCDBFA9),
    obstacle: Obstacle.flowerBush,
    finish: Finish.house,
  );

  static const beach = WorldTheme(
    background: Color(0xFF9FE2F0),
    floor: Color(0xFFFFE8B5),
    floorEdge: Color(0xFFF0CC82),
    obstacle: Obstacle.rock,
    finish: Finish.chest,
  );

  static const crystals = WorldTheme(
    background: Color(0xFFE2D6FF),
    floor: Color(0xFFFFF3FA),
    floorEdge: Color(0xFFE6C3DD),
    obstacle: Obstacle.crystal,
    finish: Finish.castle,
  );

  static const snow = WorldTheme(
    background: Color(0xFFDDEFFC),
    floor: Color(0xFFF7FBFF),
    floorEdge: Color(0xFFB9D6EC),
    obstacle: Obstacle.pine,
    finish: Finish.igloo,
  );

  static const desert = WorldTheme(
    background: Color(0xFFFFE6C2),
    floor: Color(0xFFFFF7E6),
    floorEdge: Color(0xFFEBC384),
    obstacle: Obstacle.cactus,
    finish: Finish.tent,
  );

  static const workshop = WorldTheme(
    background: Color(0xFFDDE2F7),
    floor: Color(0xFFF7F8FC),
    floorEdge: Color(0xFFC3C9E6),
    obstacle: Obstacle.crate,
    finish: Finish.toolbox,
  );

  static const space = WorldTheme(
    background: Color(0xFF233056),
    floor: Color(0xFFFFF4D6),
    floorEdge: Color(0xFFB9C2E8),
    obstacle: Obstacle.asteroid,
    finish: Finish.rocket,
  );

  /// A hedge maze, for following the walls on the Otherwise island.
  static const maze = WorldTheme(
    background: Color(0xFFE3F1D4),
    floor: Color(0xFFF6ECD8),
    floorEdge: Color(0xFFD9C29A),
    obstacle: Obstacle.hedge,
    finish: Finish.treehouse,
  );

  /// One world per island, keyed by concept id.
  static WorldTheme forConcept(String concept) => switch (concept) {
    'sequencing' => garden,
    'loops' => beach,
    'functions' => crystals,
    'conditions' => snow,
    'variables' => desert,
    'debugging' => workshop,
    'until' => space,
    'otherwise' => maze,
    _ => meadow,
  };
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
      // A square-cut hedge, so the walls read as a maze.
      final hedge = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 0.84, height: 0.84),
        const Radius.circular(0.14),
      );
      canvas
        ..drawRRect(hedge.shift(const Offset(0.03, 0.05)), shadow)
        ..drawRRect(hedge, _fill(0xFF3F8F4A))
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c.dx - 0.42, c.dy - 0.42, 0.84, 0.3),
            const Radius.circular(0.14),
          ),
          _fill(0xFF5BAE5F),
        );
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          c +
              Offset(
                (random.nextDouble() - 0.5) * 0.56,
                (random.nextDouble() - 0.3) * 0.5,
              ),
          0.05,
          _fill(0xFF7CC97A),
        );
      }
    case Obstacle.bush:
      canvas
        ..drawCircle(c + const Offset(0.04, 0.06), 0.36 * s, _fill(0xFF4FA457))
        ..drawCircle(c, 0.34 * s, _fill(0xFF6CC071))
        ..drawCircle(c + const Offset(-0.12, -0.1), 0.12, _fill(0xFF4FA457));
    case Obstacle.flowerBush:
      canvas
        ..drawCircle(c + const Offset(0.04, 0.06), 0.36 * s, _fill(0xFF4E9F4A))
        ..drawCircle(c, 0.34 * s, _fill(0xFF74C66A));
      const petals = [0xFFF48FB1, 0xFFFFD54F, 0xFFFFFFFF];
      final petal = _fill(petals[random.nextInt(petals.length)]);
      for (final (dx, dy) in [(-0.13, -0.08), (0.12, 0.06), (-0.02, 0.15)]) {
        final f = c + Offset(dx * s, dy * s);
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5;
          canvas.drawCircle(f + Offset(cos(a), sin(a)) * 0.05, 0.04, petal);
        }
        canvas.drawCircle(f, 0.03, _fill(0xFFFFA000));
      }
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
      final tint = tints[random.nextInt(tints.length)];
      for (final (dx, h, w) in [(-0.14, 0.5, 0.16), (0.1, 0.62, 0.18)]) {
        final base = c + Offset(dx, 0.28);
        final crystal = Path()
          ..moveTo(base.dx - w, base.dy)
          ..lineTo(base.dx - w, base.dy - h * s * 0.6)
          ..lineTo(base.dx, base.dy - h * s)
          ..lineTo(base.dx + w, base.dy - h * s * 0.6)
          ..lineTo(base.dx + w, base.dy)
          ..close();
        canvas
          ..drawPath(crystal, _fill(tint))
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
    case Obstacle.pine:
      canvas.drawOval(
        Rect.fromCenter(
          center: c + const Offset(0, 0.34),
          width: 0.5,
          height: 0.12,
        ),
        shadow,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: c + const Offset(0, 0.3),
          width: 0.1,
          height: 0.14,
        ),
        _fill(0xFF795548),
      );
      for (final (y, w) in [(0.22, 0.36), (0.02, 0.28), (-0.17, 0.2)]) {
        final tier = Path()
          ..moveTo(c.dx - w * s, c.dy + y)
          ..lineTo(c.dx, c.dy + y - 0.3 * s)
          ..lineTo(c.dx + w * s, c.dy + y)
          ..close();
        canvas.drawPath(tier, _fill(0xFF2E7D5B));
        // Snow on each tier.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - w * s * 0.45, c.dy + y - 0.165 * s)
            ..lineTo(c.dx, c.dy + y - 0.3 * s)
            ..lineTo(c.dx + w * s * 0.45, c.dy + y - 0.165 * s)
            ..close(),
          _fill(0xFFFFFFFF),
        );
      }
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
  final base = _fill(0x5581C784);
  switch (finish) {
    case Finish.flag:
      canvas.drawOval(const Rect.fromLTWH(0.2, 0.72, 0.6, 0.16), base);
      _flag(canvas, const Offset(0.38, 0.8), 0.66);
    case Finish.house:
      canvas
        ..drawOval(const Rect.fromLTWH(0.14, 0.76, 0.72, 0.14), base)
        ..drawRect(
          const Rect.fromLTWH(0.24, 0.48, 0.52, 0.34),
          _fill(0xFFFFF3E0),
        )
        ..drawPath(
          Path()
            ..moveTo(0.16, 0.5)
            ..lineTo(0.5, 0.22)
            ..lineTo(0.84, 0.5)
            ..close(),
          _fill(0xFFE57373),
        )
        ..drawRect(
          const Rect.fromLTWH(0.43, 0.62, 0.14, 0.2),
          _fill(0xFF8D6E63),
        );
      _flag(canvas, const Offset(0.5, 0.24), 0.2, scale: 0.65);
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
    case Finish.treehouse:
      canvas
        ..drawOval(const Rect.fromLTWH(0.14, 0.78, 0.72, 0.12), base)
        ..drawRect(
          const Rect.fromLTWH(0.44, 0.46, 0.12, 0.38),
          _fill(0xFF8D6E63),
        )
        ..drawCircle(const Offset(0.5, 0.32), 0.26, _fill(0xFF4CAF50))
        ..drawCircle(const Offset(0.36, 0.26), 0.14, _fill(0xFF66BB6A))
        ..drawRect(
          const Rect.fromLTWH(0.34, 0.4, 0.32, 0.18),
          _fill(0xFFFFCC80),
        )
        ..drawPath(
          Path()
            ..moveTo(0.3, 0.41)
            ..lineTo(0.5, 0.28)
            ..lineTo(0.7, 0.41)
            ..close(),
          _fill(0xFFE57373),
        )
        ..drawRect(
          const Rect.fromLTWH(0.46, 0.47, 0.08, 0.11),
          _fill(0xFF6D4C41),
        );
      _flag(canvas, const Offset(0.5, 0.3), 0.2, scale: 0.6);
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
