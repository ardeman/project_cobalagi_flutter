import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import '../../../../engine/world/direction.dart';
import '../../../../engine/world/grid_point.dart';
import '../../../../engine/world/level.dart';

// Placeholder art until the Rive characters arrive. One world unit is one tile.

Vector2 tileCenter(GridPoint p) => Vector2(p.x + 0.5, p.y + 0.5);

/// Clockwise from north, matching Flame's rotation direction.
double angleOf(Direction direction) => direction.index * pi / 2;

class BoardComponent extends PositionComponent {
  BoardComponent(this.level)
    : super(size: Vector2(level.width.toDouble(), level.height.toDouble()));

  final Level level;

  static final _floor = Paint()..color = const Color(0xFFFFF1C9);
  static final _floorEdge = Paint()..color = const Color(0xFFF2D99A);
  static final _bush = Paint()..color = const Color(0xFF6CC071);
  static final _bushShade = Paint()..color = const Color(0xFF4FA457);

  /// The board never changes, so it is drawn once and replayed each frame.
  late final Picture _picture = () {
    final recorder = PictureRecorder();
    _draw(Canvas(recorder));
    return recorder.endRecording();
  }();

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);

  @override
  void onRemove() {
    _picture.dispose();
    super.onRemove();
  }

  void _draw(Canvas canvas) {
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final cell = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
        if (level.tiles[y][x] == Tile.floor) {
          canvas
            ..drawRRect(
              RRect.fromRectAndRadius(
                cell.deflate(0.03),
                const Radius.circular(0.18),
              ),
              _floorEdge,
            )
            ..drawRRect(
              RRect.fromRectAndRadius(
                cell.deflate(0.08),
                const Radius.circular(0.14),
              ),
              _floor,
            );
        } else {
          final c = cell.center;
          canvas
            ..drawCircle(c + const Offset(0.04, 0.06), 0.36, _bushShade)
            ..drawCircle(c, 0.34, _bush)
            ..drawCircle(c + const Offset(-0.12, -0.1), 0.12, _bushShade);
        }
      }
    }
  }
}

class GoalComponent extends PositionComponent {
  GoalComponent(GridPoint at)
    : super(
        position: tileCenter(at),
        size: Vector2.all(1),
        anchor: Anchor.center,
      );

  static final _pole = Paint()
    ..color = const Color(0xFF8D6E63)
    ..strokeWidth = 0.07
    ..strokeCap = StrokeCap.round;
  static final _flag = Paint()..color = const Color(0xFFE53935);
  static final _base = Paint()..color = const Color(0x5581C784);

  @override
  Future<void> onLoad() async => add(
    ScaleEffect.to(
      Vector2.all(1.08),
      EffectController(duration: 0.8, alternate: true, infinite: true),
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas
      ..drawOval(const Rect.fromLTWH(0.2, 0.72, 0.6, 0.16), _base)
      ..drawLine(const Offset(0.38, 0.8), const Offset(0.38, 0.14), _pole)
      ..drawPath(
        Path()
          ..moveTo(0.41, 0.14)
          ..lineTo(0.8, 0.27)
          ..lineTo(0.41, 0.42)
          ..close(),
        _flag,
      );
  }
}

class StarComponent extends PositionComponent {
  StarComponent(GridPoint at)
    : super(
        position: tileCenter(at),
        size: Vector2.all(1),
        anchor: Anchor.center,
      );

  static final _fill = Paint()..color = const Color(0xFFFFC83D);
  static final _outline = Paint()
    ..color = const Color(0xFFF59E0B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..strokeJoin = StrokeJoin.round;

  static final Path _shape = () {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.32 : 0.14;
      final a = -pi / 2 + i * pi / 5;
      final point = Offset(0.5 + r * cos(a), 0.5 + r * sin(a));
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }();

  @override
  Future<void> onLoad() async => add(
    RotateEffect.by(
      0.25,
      EffectController(duration: 1.2, alternate: true, infinite: true),
    ),
  );

  @override
  void render(Canvas canvas) => canvas
    ..drawPath(_shape, _fill)
    ..drawPath(_shape, _outline);
}

/// The character. Its face points in its facing direction.
class ActorComponent extends PositionComponent {
  ActorComponent(GridPoint at, Direction facing)
    : super(
        position: tileCenter(at),
        size: Vector2.all(1),
        anchor: Anchor.center,
        angle: angleOf(facing),
      );

  static final _body = Paint()..color = const Color(0xFFFF7A59);
  static final _belly = Paint()..color = const Color(0xFFFFB199);
  static final _eye = Paint()..color = const Color(0xFFFFFFFF);
  static final _pupil = Paint()..color = const Color(0xFF263238);
  static final _shadow = Paint()..color = const Color(0x33000000);

  @override
  void render(Canvas canvas) {
    canvas
      ..drawCircle(const Offset(0.53, 0.56), 0.35, _shadow)
      ..drawCircle(const Offset(0.5, 0.5), 0.35, _body)
      ..drawCircle(const Offset(0.5, 0.6), 0.18, _belly)
      ..drawPath(
        Path()
          ..moveTo(0.5, 0.06)
          ..lineTo(0.62, 0.2)
          ..lineTo(0.38, 0.2)
          ..close(),
        _body,
      );
    for (final dx in [-0.13, 0.13]) {
      canvas
        ..drawCircle(Offset(0.5 + dx, 0.36), 0.085, _eye)
        ..drawCircle(Offset(0.5 + dx, 0.33), 0.042, _pupil);
    }
  }
}

/// Confetti and little stars bursting from [at] when a puzzle is solved.
/// Purely decorative; removes itself when the burst is over.
class CelebrationComponent extends ParticleSystemComponent {
  CelebrationComponent(GridPoint at, {Random? random})
    : super(position: tileCenter(at), particle: _burst(random ?? Random()));

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF7043),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFF06292),
  ];

  static Particle _burst(Random random) => Particle.generate(
    count: 48,
    lifespan: 1.6,
    generator: (i) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 1.5 + random.nextDouble() * 3;
      final paint = Paint()..color = _colors[i % _colors.length];
      final size = 0.06 + random.nextDouble() * 0.07;
      return AcceleratedParticle(
        speed: Vector2(cos(angle) * speed, sin(angle) * speed - 2.5),
        acceleration: Vector2(0, 6),
        child: i.isEven
            ? CircleParticle(radius: size, paint: paint)
            : ComputedParticle(
                renderer: (canvas, particle) {
                  // A spinning square of confetti.
                  canvas
                    ..save()
                    ..rotate(particle.progress * 4 * pi)
                    ..drawRect(
                      Rect.fromCenter(
                        center: Offset.zero,
                        width: size * 2,
                        height: size * 1.2,
                      ),
                      paint,
                    )
                    ..restore();
                },
              ),
      );
    },
  );
}
