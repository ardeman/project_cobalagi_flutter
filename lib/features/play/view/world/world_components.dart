import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import '../../../../engine/world/direction.dart';
import '../../../../engine/world/grid_point.dart';
import '../../../../engine/world/level.dart';
import '../../../../core/character/robot_face.dart';
import '../../../../core/character/robot_turn.dart';
import 'board_painter.dart';
import 'ink.dart';
import 'world_theme.dart';

export '../../../../core/character/robot_face.dart' show RobotFace;
export 'board_painter.dart' show standUp, tilt;

// The world's pieces, drawn in code in Koba's look. One world unit is one tile.

Vector2 tileCenter(GridPoint p) => Vector2(p.x + 0.5, p.y + 0.5);

/// Clockwise from north, matching Flame's rotation direction.
double angleOf(Direction direction) => direction.index * pi / 2;

/// The board, painted by [BoardPainter].
class BoardComponent extends PositionComponent {
  BoardComponent(this.level, this.theme)
    : super(size: Vector2(level.width.toDouble(), level.height.toDouble()));

  final Level level;
  final WorldTheme theme;

  late final _painter = BoardPainter(level, theme);

  /// How far the view is turned (see `WorldGame.follow`): each obstacle
  /// stands upright on the screen, so rocks never lie on their sides, and
  /// the sides of the ground and tiles show at the bottom of the screen.
  var upright = 0.0;

  @override
  void render(Canvas canvas) => _painter.paint(canvas, upright: upright);

  @override
  void onRemove() {
    _painter.dispose();
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
/// front facing down, and its eyes look the way it faces, or at what it
/// [watching], its head turning that way too. Touched, it shakes its head
/// ([poke]), with a smile unless its back is turned. It bobs gently
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

  /// [sprite]'s head and body apart (`assets/images/robot_head.png` and
  /// `robot_body.png`, as on the splash), so its head can turn; [sprite]
  /// stands in, with a still head, until both load. The front and back
  /// pictures are cut at the neck instead.
  Sprite? headSprite;
  Sprite? bodySprite;

  /// The 3D robot turning on the spot (`assets/images/robot_turn.webp`, see
  /// [robotTurnFrameCount]), shown part way round a turn so it turns round
  /// instead of switching pictures.
  Image? turnFrames;

  /// Set while it moves between tiles: it stays on the ground then, instead
  /// of bobbing.
  var rolling = false;

  /// How far the view is turned (see `WorldGame.follow`): the robot stands
  /// upright on the screen, not on the board.
  var viewAngle = 0.0;

  /// The face on the robot's screen.
  var face = RobotFace.normal;

  /// Where its eyes look while it watches the child's finger or the mouse
  /// (`WorldGame.lookAt`): the pupils' place on the screen, in its
  /// picture's pixels; null to look the way it faces.
  Offset? watching;

  /// Where the pupils are, on the screen: they glide to what it looks at.
  var _gaze = Offset.zero;

  /// Where the pupils are now (see [watching]).
  Offset get gaze => _gaze;

  /// Seconds left of its delight after a [poke].
  var _delight = 0.0;
  static const _delightTime = 0.9;

  /// How far its head tilts (radians, clockwise on the screen) and dips (in
  /// its picture's pixels) to follow what it watches.
  var _headTilt = 0.0;
  var _headDip = 0.0;

  /// How far its head is tilted now: following what it watches, or shaking
  /// after a [poke].
  double get headTurn {
    if (_delight <= 0) return _headTilt;
    final shaking = _delightTime - _delight;
    return _headTilt +
        sin(shaking * 2 * pi * 3.5) * 0.16 * _delight / _delightTime;
  }

  var _time = 0.0;

  /// How far it has travelled, in tiles, which turns its wheels.
  var _travelled = 0.0;
  Vector2? _last;
  final _velocity = Vector2.zero();

  /// How far it leans forward (radians), on its suspension: back as it
  /// speeds up, forward as it brakes, settling with a little bounce.
  var _pitch = 0.0;
  var _pitchSpeed = 0.0;

  /// How far it leans forward now, in radians (back when below 0).
  double get lean => _pitch;

  static final _body = Paint()..color = const Color(0xFFFF7A59);
  static final _belly = Paint()..color = const Color(0xFFFFB199);
  static final _eye = Paint()..color = const Color(0xFFFFFFFF);
  static final _pupil = Paint()..color = const Color(0xFF263238);
  static final _shadow = Paint()..color = const Color(0x33000000);
  static final _picture = Vector2.all(512);

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
    _delight = max(0, _delight - dt);
    // The eyes dart quickly, then settle.
    final aim = watching ?? _facingGaze(angle - viewAngle);
    _gaze = Offset.lerp(_gaze, aim, min(1.0, dt * 12))!;
    // The head turns more slowly than the eyes. It only ever dips: lifting
    // it would open a gap at the neck.
    final follow = min(1.0, dt * 6);
    _headTilt +=
        ((watching == null ? 0 : (watching!.dx / 16).clamp(-1, 1) * 0.1) -
            _headTilt) *
        follow;
    _headDip +=
        ((watching == null ? 0 : (watching!.dy / 24).clamp(0, 1) * 6) -
            _headDip) *
        follow;
    final last = _last;
    if (last != null) _travelled += position.distanceTo(last);
    _last = position.clone();
    if (dt <= 0) return;
    // Its speed along the way it faces, and how fast that changes.
    final velocity = last == null ? Vector2.zero() : (position - last)
      ..scale(1 / dt);
    final speedUp =
        (velocity - _velocity).dot(Vector2(sin(angle), -cos(angle))) / dt;
    _velocity.setFrom(velocity);
    // A damped spring pulls the lean towards what the speeding up asks for.
    final lean = (-speedUp * 0.008).clamp(-0.14, 0.14);
    for (var left = min(dt, 0.1); left > 0; left -= 1 / 60) {
      final step = min(left, 1 / 60);
      _pitchSpeed += (-220 * (_pitch - lean) - 9 * _pitchSpeed) * step;
      _pitch += _pitchSpeed * step;
    }
  }

  /// Where the eyes look for a facing [angle] on the screen, on the screen:
  /// the way it faces and, facing the child, at the child.
  Offset _facingGaze(double angle) => frontSprite != null && -cos(angle) > 0.7
      ? const Offset(0, 6)
      : Offset(sin(angle) * 14, -cos(angle) * 22);

  /// Whether its back shows: facing up the board, it walks away. Its faces
  /// (dizzy, cheering) always turn to the child, but a [poke] doesn't turn
  /// it round: with its back turned it only shakes its head.
  bool get showsBack =>
      face == RobotFace.normal && cos(angle - viewAngle) > 0.7;

  /// Touched: it shakes its head, with a smile when its face shows. False
  /// while it shows another face or still shakes, so a quick run of taps
  /// doesn't make it jitter.
  bool poke() {
    if (face != RobotFace.normal || _delight > 0) return false;
    _delight = _delightTime;
    return true;
  }

  /// The turning frame to show for a facing [angle] on the screen, or null
  /// when it faces along the board (see [robotTurnFrame]).
  int? _turnFrame(double angle) =>
      turnFrames == null ? null : robotTurnFrame(angle);

  @override
  void render(Canvas canvas) {
    if (sprite == null) return _renderPlain(canvas);
    // Its facing as seen on the screen, which may be turned with it.
    final angle = this.angle - viewAngle;
    final turnFrame = _turnFrame(angle);
    final face = this.face == RobotFace.normal && _delight > 0
        ? RobotFace.cheer
        : this.face;
    final away = showsBack;
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
    final mirrored = turnFrame == null && sideways < -0.3;
    canvas
      ..translate(0, bounce)
      // Rocking on its wheels: seen from the side it tips about them, seen
      // from the front or back it dips.
      ..translate(0, 0.28)
      ..rotate(_pitch * sideways)
      ..scale(1, 1 - _pitch.abs() * cos(angle).abs() * 0.5)
      ..translate(0, -0.28)
      // Mirrored to face left. Its shadow and the marks under its wheels
      // stay flat, and its width true in every facing.
      ..scale(mirrored ? -1 : 1, 1);
    if (turnFrame != null) {
      _renderTurning(canvas, turnFrame, face);
      return canvas.restore();
    }
    // Drawn in the picture's own pixels (512), a little taller than its
    // tile, as board-game pieces are.
    canvas
      ..translate(-0.55, -0.82)
      ..scale(1.1 / 512);
    final side =
        !identical(robot, frontSprite) && !identical(robot, backSprite);
    final head = side ? headSprite : robot;
    final body = side ? bodySprite : robot;
    final apart = head != null && body != null;
    // Where the head sits on the neck, and where the front and back
    // pictures are cut: across their neck piece.
    final neck = side ? const Offset(268, 330) : const Offset(256, 328);
    if (!apart) {
      robot.render(canvas, size: _picture);
    } else if (side) {
      body.render(canvas, size: _picture);
    } else {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(0, neck.dy, 512, 512));
      body.render(canvas, size: _picture);
      canvas.restore();
    }
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
    if (apart) {
      // Its head turns on its neck; the canvas is mirrored facing left, the
      // turn is on the screen.
      canvas
        ..translate(neck.dx, neck.dy + _headDip)
        ..rotate(mirrored ? -headTurn : headTurn)
        ..translate(-neck.dx, -neck.dy);
      if (side) {
        head.render(canvas, size: _picture);
      } else {
        canvas
          ..save()
          ..clipRect(Rect.fromLTRB(0, 0, 512, neck.dy));
        head.render(canvas, size: _picture);
        canvas.restore();
      }
    }
    if (!away) {
      paintRobotFace(
        canvas,
        face,
        time: _time,
        // Its canvas is mirrored facing left; the gaze is on the screen.
        gaze: mirrored ? Offset(-_gaze.dx, _gaze.dy) : _gaze,
        front: front,
      );
    }
    canvas.restore();
  }

  /// Turning frame [frame], in the drawn pictures' place, with its [face]
  /// on its screen while that shows.
  void _renderTurning(Canvas canvas, int frame, RobotFace face) {
    canvas
      ..translate(-0.55, -0.82)
      ..scale(1.1 / 512);
    paintRobotTurning(canvas, turnFrames!, frame, face, time: _time);
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
