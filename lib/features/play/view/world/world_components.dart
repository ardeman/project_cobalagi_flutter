import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import '../../../../engine/world/direction.dart';
import '../../../../engine/world/grid_point.dart';
import '../../../../engine/world/level.dart';
import '../../../../core/character/robot_face.dart';
import 'ink.dart';
import 'world_theme.dart';

export '../../../../core/character/robot_face.dart' show RobotFace;

// Placeholder art until the Rive characters arrive. One world unit is one tile.

Vector2 tileCenter(GridPoint p) => Vector2(p.x + 0.5, p.y + 0.5);

/// Clockwise from north, matching Flame's rotation direction.
double angleOf(Direction direction) => direction.index * pi / 2;

/// How much the board tilts away from the child: the ground is drawn this
/// much shorter than wide, and upright things (obstacles, the finish, stars,
/// hint marks, the robot) are stretched back by its inverse where they
/// stand, so they stand up instead of lying flat. See `TiltedViewport`.
const tilt = 0.8;

/// Stands what is drawn after it upright on the tilted board, around the
/// point [base] (in the same, upright, frame) where it touches the ground.
void standUp(Canvas canvas, Offset base) => canvas
  ..translate(base.dx, base.dy)
  ..scale(1, 1 / tilt)
  ..translate(-base.dx, -base.dy);

/// The board: a piece of the planet's surface floating in the starry sky,
/// cut a little wider than the board, with the path's tiles raised on it and
/// the planet's obstacles and odds and ends ([Decor]) on the ground off it.
class BoardComponent extends PositionComponent {
  BoardComponent(this.level, this.theme)
    : super(size: Vector2(level.width.toDouble(), level.height.toDouble()));

  final Level level;
  final WorldTheme theme;

  late final _floor = Paint()..color = theme.floor;
  late final _floorEdge = Paint()..color = theme.floorEdge;
  late final _tileSide = Paint()
    ..color = Color.lerp(theme.floorEdge, const Color(0xFF000000), 0.2)!;
  late final _ground = Paint()..color = theme.ground;
  late final _groundSide = Paint()..color = theme.groundSide;

  /// Each path tile's outline, in Koba's navy, so the path reads as drawn
  /// like Koba.
  static final _tileOutline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.022;
  static final _edge = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.03
    ..strokeJoin = StrokeJoin.round;

  /// How far the planet's piece reaches past the board, and how thick it is.
  static const _margin = 0.32, _depth = 0.38, _tileDepth = 0.07;

  /// How far the view is turned (see `WorldGame.follow`): each obstacle
  /// stands upright on the screen, so rocks never lie on their sides, and
  /// the sides of the ground and tiles show at the bottom of the screen.
  var upright = 0.0;

  /// The piece's outline: the board's rectangle with rounded corners and a
  /// gently uneven edge, the same every time for a level.
  late final Path _piece = () {
    final random = Random(level.width * 31 + level.height);
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -_margin,
            -_margin,
            level.width + 2 * _margin,
            level.height + 2 * _margin,
          ),
          const Radius.circular(0.7),
        ),
      );
    final metric = outline.computeMetrics().single;
    final steps = (metric.length * 5).round();
    final wobbly = Path();
    for (var i = 0; i < steps; i++) {
      final at = metric.getTangentForOffset(metric.length * i / steps)!;
      // Outward is to the left of the way round (the outline runs clockwise).
      final out = Offset(at.vector.dy, -at.vector.dx);
      final p = at.position + out * (random.nextDouble() * 0.07);
      i == 0 ? wobbly.moveTo(p.dx, p.dy) : wobbly.lineTo(p.dx, p.dy);
    }
    return wobbly..close();
  }();

  bool _isPath(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < level.width &&
      y < level.height &&
      level.tiles[y][x] == Tile.floor;

  late final List<RRect> _tiles = [
    for (var y = 0; y < level.height; y++)
      for (var x = 0; x < level.width; x++)
        if (_isPath(x, y))
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1).deflate(0.05),
            const Radius.circular(0.16),
          ),
  ];

  /// The sky behind, never changing.
  late final Picture _sky = _record(
    (canvas) => drawSky(
      canvas,
      Rect.fromLTWH(
        -level.width.toDouble(),
        -level.height.toDouble(),
        level.width * 3.0,
        level.height * 3.0,
      ),
    ),
  );

  /// The planet's surface, its odds and ends, and the path's tiles: all flat
  /// on the ground, so drawn once.
  late final Picture _surface = _record(_drawSurface);

  static Picture _record(void Function(Canvas) draw) {
    final recorder = PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  void _drawSurface(Canvas canvas) {
    canvas
      ..drawPath(_piece, _ground)
      ..drawPath(_piece, _edge);
    // Odds and ends on the ground, scattered so no two cells look alike,
    // never on the path.
    final random = Random(level.width * 7 + level.height * 13 + 1);
    final bounds = _piece.getBounds();
    final count = (bounds.width * bounds.height * 1.6).round();
    for (var i = 0; i < count; i++) {
      final at = Offset(
        bounds.left + random.nextDouble() * bounds.width,
        bounds.top + random.nextDouble() * bounds.height,
      );
      final near = Rect.fromCenter(center: at, width: 0.42, height: 0.42);
      final onPath = _tiles.any((tile) => tile.outerRect.overlaps(near));
      if (onPath || !_piece.contains(at)) continue;
      drawDecor(canvas, at, theme.decor, theme.ground, random);
    }
    for (final tile in _tiles) {
      canvas
        ..drawRRect(tile, _floorEdge)
        ..drawRRect(tile, _tileOutline)
        ..drawRRect(tile.deflate(0.05), _floor)
        ..drawRRect(tile.deflate(0.05), _tileOutline);
    }
  }

  /// Where an obstacle's picture reaches, around its tile's centre.
  static const _obstacleBounds = Rect.fromLTWH(-0.6, -0.6, 1.2, 1.2);

  /// Each obstacle, drawn once in Koba's look, and placed a little
  /// differently in its tile (shifted, sized, mirrored) so the planet's
  /// ground never looks stamped out.
  late final List<({Offset at, Image image, double size, bool mirror})>
  _obstacles = [
    for (var y = 0; y < level.height; y++)
      for (var x = 0; x < level.width; x++)
        if (level.tiles[y][x] != Tile.floor)
          () {
            final random = Random(y * 997 + x + 5);
            // A maze's hedges are its walls: they stay lined up.
            final varied = theme.obstacle != Obstacle.hedge;
            return (
              at: Offset(
                x + 0.5 + (varied ? (random.nextDouble() - 0.5) * 0.14 : 0),
                y + 0.5 + (varied ? (random.nextDouble() - 0.5) * 0.1 : 0),
              ),
              image: inkedPiece(
                (canvas) => drawObstacle(
                  canvas,
                  const Rect.fromLTWH(-0.5, -0.5, 1, 1),
                  theme.obstacle,
                  y * 997 + x,
                ),
                bounds: _obstacleBounds,
              ),
              size: varied ? 0.68 + random.nextDouble() * 0.3 : 1.0,
              mirror: varied && random.nextBool(),
            );
          }(),
  ];

  @override
  void render(Canvas canvas) {
    // Down the screen, in the board's own (turned) frame: where the sides
    // of the ground and the tiles show.
    final down = Offset(-sin(upright), cos(upright));
    canvas.drawPicture(_sky);
    for (var i = 1; i <= 8; i++) {
      canvas.drawPath(_piece.shift(down * (_depth * i / 8)), _groundSide);
    }
    canvas.drawPath(_piece.shift(down * _depth), _edge);
    for (final tile in _tiles) {
      canvas.drawRRect(tile.shift(down * _tileDepth), _tileSide);
    }
    canvas.drawPicture(_surface);
    // Nearer the bottom of the screen draws later, in front.
    double depth(Offset at) => sin(upright) * -at.dx + cos(upright) * at.dy;
    final order = [..._obstacles]
      ..sort((a, b) => depth(a.at).compareTo(depth(b.at)));
    for (final obstacle in order) {
      canvas
        ..save()
        ..translate(obstacle.at.dx, obstacle.at.dy)
        ..rotate(upright);
      standUp(canvas, const Offset(0, 0.28));
      canvas.scale(
        obstacle.mirror ? -obstacle.size : obstacle.size,
        obstacle.size,
      );
      drawInked(canvas, obstacle.image, _obstacleBounds);
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    _sky.dispose();
    _surface.dispose();
    for (final obstacle in _obstacles) {
      obstacle.image.dispose();
    }
    super.onRemove();
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

  /// Where the finish's picture reaches, around its unit square.
  static const _bounds = Rect.fromLTWH(-0.1, -0.1, 1.2, 1.2);

  /// The finish in Koba's look, drawn once.
  late final Image _image = inkedPiece(
    (canvas) => drawFinish(canvas, finish),
    bounds: _bounds,
  );

  @override
  Future<void> onLoad() async => add(
    ScaleEffect.to(
      Vector2.all(1.08),
      EffectController(duration: 0.8, alternate: true, infinite: true),
    ),
  );

  @override
  void render(Canvas canvas) {
    // Standing on its tile, near the bottom of its square.
    standUp(canvas, const Offset(0.5, 0.82));
    drawInked(canvas, _image, _bounds);
  }

  @override
  void onRemove() {
    _image.dispose();
    super.onRemove();
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
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
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
  void render(Canvas canvas) {
    standUp(canvas, const Offset(0.5, 0.5));
    canvas
      ..drawPath(_shape, _fill)
      ..drawPath(_shape, _outline);
  }
}

/// The character. The component turns to its facing direction (and the
/// world's turn effects rotate it). With [sprite] (the robot) the picture
/// stays upright and shows its facing itself: a headlight beam on the tile
/// ahead, its side when facing left or right, its back facing up and its
/// front facing down, and its eyes look the way it faces. It bobs gently
/// while idle; as it moves it stays on the ground and its wheels roll, as
/// far as it travels: spokes turn on the hubs seen from the side, and the
/// treads run past seen from the front or back.
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

  /// Set while it moves between tiles: it stays on the ground then, instead
  /// of bobbing.
  var rolling = false;

  /// How far the view is turned (see `WorldGame.follow`): the robot stands
  /// upright on the screen, not on the board.
  var viewAngle = 0.0;

  /// The face on the robot's screen.
  var face = RobotFace.normal;

  var _time = 0.0;

  /// How far it has travelled, in tiles, which turns its wheels.
  var _travelled = 0.0;
  Vector2? _last;

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
    final last = _last;
    if (last != null) _travelled += position.distanceTo(last);
    _last = position.clone();
  }

  @override
  void render(Canvas canvas) {
    if (sprite == null) return _renderPlain(canvas);
    // Its facing as seen on the screen, which may be turned with it.
    final angle = this.angle - viewAngle;
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
    final bounce = rolling ? 0.0 : sin(_time * 2.4) * 0.02;
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
      ..rotate(-angle);
    // Standing up on the tilted board, its wheels on the ground.
    standUp(canvas, const Offset(0, 0.28));
    canvas
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
    // The wheels and the face, drawn over the picture in its own pixels
    // (512); the back picture has no face.
    canvas
      ..translate(-0.55, -0.82)
      ..scale(1.1 / 512);
    // The picture is 1.1 tiles for 512 pixels: how far the wheels' rims
    // have run, in its pixels.
    final run = _travelled * 512 / 1.1;
    if (identical(robot, frontSprite)) {
      // Coming towards the child, the treads run down.
      _paintTreads(canvas, run);
    } else if (identical(robot, backSprite)) {
      _paintTreads(canvas, -run);
    } else {
      _paintSpokes(canvas, run);
    }
    if (!away) {
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

  static final _navy = Paint()
    ..color = const Color(0xFF222244)
    ..strokeCap = StrokeCap.round;
  static final _teal = Paint()..color = const Color(0xFF92DCCF);

  /// Spokes on both hubs of the three-quarter picture (`branding/robot.sh`,
  /// as on the splash), turned by [run] pixels of rim: a wheel's radius is
  /// about 28 pixels.
  static void _paintSpokes(Canvas canvas, double run) {
    _navy.strokeWidth = 3.2;
    const hubs = [
      (center: Offset(229, 472), radii: Offset(8.5, 11.5)),
      (center: Offset(295.5, 472), radii: Offset(8, 11.5)),
    ];
    final turn = run / 28;
    for (final hub in hubs) {
      for (var i = 0; i < 3; i++) {
        final a = turn + i * 2 * pi / 3;
        canvas.drawLine(
          hub.center,
          hub.center + Offset(cos(a) * hub.radii.dx, sin(a) * hub.radii.dy),
          _navy,
        );
      }
    }
  }

  /// The treads of both wheels of the front and back pictures (drawn by
  /// `tool/robot/front.html`: 38 by 54 pixels, lines 11 apart), moved
  /// down by [run] pixels.
  static void _paintTreads(Canvas canvas, double run) {
    _navy.strokeWidth = 2;
    final shift = run % 11;
    for (final x in [204.0, 308.0]) {
      final inside = RRect.fromLTRBR(
        x - 17,
        440,
        x + 17,
        490,
        const Radius.circular(12),
      );
      canvas
        ..save()
        ..clipRRect(inside)
        ..drawRRect(inside, _teal);
      for (var y = 450 - 22 + shift; y < 492; y += 11) {
        canvas.drawLine(Offset(x - 16, y), Offset(x + 16, y), _navy);
      }
      canvas.restore();
    }
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
