import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import '../../../../engine/world/direction.dart';
import '../../../../engine/world/grid_point.dart';
import '../../../../engine/world/level.dart';
import '../../../../core/character/robot_face.dart';
import 'world_theme.dart';

export '../../../../core/character/robot_face.dart' show RobotFace;

// Placeholder art until the Rive characters arrive. One world unit is one tile.

Vector2 tileCenter(GridPoint p) => Vector2(p.x + 0.5, p.y + 0.5);

/// Clockwise from north, matching Flame's rotation direction.
double angleOf(Direction direction) => direction.index * pi / 2;

class BoardComponent extends PositionComponent {
  BoardComponent(this.level, this.theme)
    : super(size: Vector2(level.width.toDouble(), level.height.toDouble()));

  final Level level;
  final WorldTheme theme;

  late final _floor = Paint()..color = theme.floor;
  late final _floorEdge = Paint()..color = theme.floorEdge;

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
    // Stars behind the board, reaching past it into any space around.
    drawSky(
      canvas,
      Rect.fromLTWH(
        -level.width.toDouble(),
        -level.height.toDouble(),
        level.width * 3.0,
        level.height * 3.0,
      ),
    );
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
          drawObstacle(canvas, cell, theme.obstacle, y * 997 + x);
        }
      }
    }
  }
}

/// The island's finish, with the red flag, gently pulsing.
class GoalComponent extends PositionComponent {
  GoalComponent(GridPoint at, this.finish)
    : super(
        position: tileCenter(at),
        size: Vector2.all(1),
        anchor: Anchor.center,
      );

  final Finish finish;

  @override
  Future<void> onLoad() async => add(
    ScaleEffect.to(
      Vector2.all(1.08),
      EffectController(duration: 0.8, alternate: true, infinite: true),
    ),
  );

  @override
  void render(Canvas canvas) => drawFinish(canvas, finish);
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

/// The character. The component turns to its facing direction (and the
/// world's turn effects rotate it). With [sprite] (the robot) the picture
/// stays upright and shows its facing itself: a headlight beam on the tile
/// ahead, its side when facing left or right, its back facing up and its
/// front facing down, and its eyes look the way it faces. It bobs gently
/// while idle and bounces as it rolls.
/// Without a sprite it draws the round character, whose face turns.
class ActorComponent extends PositionComponent {
  ActorComponent(
    GridPoint at,
    Direction facing, {
    this.sprite,
    this.backSprite,
    this.frontSprite,
  }) : super(
         position: tileCenter(at),
         size: Vector2.all(1),
         anchor: Anchor.center,
         angle: angleOf(facing),
       );

  /// The robot's picture, once loaded.
  Sprite? sprite;

  /// The robot seen from behind (no chest buttons), for facing up the
  /// board; [sprite] stands in until it loads.
  Sprite? backSprite;

  /// The robot facing the child, for facing down the board.
  Sprite? frontSprite;

  /// Set while it moves between tiles, for a livelier bounce.
  var rolling = false;

  /// The face on the robot's screen.
  var face = RobotFace.normal;

  var _time = 0.0;

  static final _body = Paint()..color = const Color(0xFFFF7A59);
  static final _belly = Paint()..color = const Color(0xFFFFB199);
  static final _eye = Paint()..color = const Color(0xFFFFFFFF);
  static final _pupil = Paint()..color = const Color(0xFF263238);
  static final _shadow = Paint()..color = const Color(0x33000000);

  /// A soft cone of light from the robot over the next tile, facing up
  /// (the component's turn points it).
  /// It grows from a point in the robot's middle and fades in, so it has
  /// no hard start in any direction and, facing up, stays hidden behind
  /// the robot until it clears the head.
  static final _beamShape = Path()
    ..moveTo(-0.04, -0.1)
    ..lineTo(0.04, -0.1)
    ..lineTo(0.36, -1.1)
    ..quadraticBezierTo(0, -1.2, -0.36, -1.1)
    ..close();
  static final _beam = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.1),
      const Offset(0, -1.15),
      [
        const Color(0x00FFB300),
        const Color(0xBFFFB300),
        const Color(0x00FFB300),
      ],
      const [0, 0.35, 1],
    );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (sprite == null) return _renderPlain(canvas);
    // Facing up the board, it walks away: its back shows. Its faces
    // (dizzy, cheering) always turn to the child.
    final away = face == RobotFace.normal && cos(angle) > 0.7;
    // Facing down the board, it faces the child.
    final front = frontSprite != null && -cos(angle) > 0.7;
    final robot = away
        ? backSprite ?? sprite!
        : front
        ? frontSprite!
        : sprite!;
    final bounce = rolling
        ? -(sin(_time * 18).abs()) * 0.07
        : sin(_time * 2.4) * 0.02;
    // Upright: undo the component's turn, so up is up again. The robot
    // shows its facing instead (see the class comment), its eyes sweeping
    // round with the world's turn effects.
    final sideways = sin(angle);
    canvas
      ..save()
      ..translate(0.5, 0.5)
      // Its shadow, upright, then its headlight over it: the beam is drawn
      // before the canvas turns upright, so it points the way the robot
      // faces and sweeps round as it turns.
      ..rotate(-angle)
      ..drawOval(const Rect.fromLTWH(-0.32, 0.2, 0.64, 0.17), _shadow)
      ..rotate(angle)
      ..drawPath(_beamShape, _beam)
      ..rotate(-angle)
      ..translate(0, bounce)
      // Mirrored to face left. It doesn't lean: the marks under its wheels
      // stay flat and its width true in every facing.
      ..scale(sideways < -0.3 ? -1 : 1, 1);
    robot.render(
      canvas,
      // A little taller than its tile, as board-game pieces are.
      position: Vector2(-0.55, -0.82),
      size: Vector2.all(1.1),
    );
    // The face, drawn over the picture's screen in its own pixels (512);
    // the back picture has none.
    if (!away) {
      canvas
        ..translate(-0.55, -0.82)
        ..scale(1.1 / 512);
      paintRobotFace(
        canvas,
        face,
        time: _time,
        // The eyes look the way it faces; facing the child, at the child.
        gaze: front
            ? const Offset(0, 6)
            : Offset(sideways.abs() * 14, -cos(angle) * 22),
        front: front,
      );
    }
    canvas.restore();
  }

  void _renderPlain(Canvas canvas) {
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
      final speed = 2 + random.nextDouble() * 3;
      final paint = Paint()..color = _colors[i % _colors.length];
      final size = 0.06 + random.nextDouble() * 0.07;
      final out = Vector2(cos(angle), sin(angle));
      return AcceleratedParticle(
        // From a ring around the character, never piled on top of it.
        position: out * 0.55,
        speed: out * speed - Vector2(0, 2.5),
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
