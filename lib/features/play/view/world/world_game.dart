import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:math';

import 'package:flame/camera.dart' show MaxViewport;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../../core/audio/sound_effects.dart';
import '../../../../engine/interpreter/run_event.dart';
import '../../../../engine/world/grid_point.dart';
import '../../../../engine/world/level.dart';
import '../../cubit/play_cubit.dart';
import 'hint_mark.dart';
import 'world_components.dart';
import 'world_theme.dart';

/// Renders a level and replays run events as animations. Holds no game logic:
/// [apply] mirrors [PlayState], and [onEventShown] reports each finished event.
/// [onSound] plays the sound that goes with an animation as it starts.
class WorldGame extends FlameGame {
  WorldGame({
    required this.level,
    required this.onEventShown,
    this.onSound = _silent,
  }) : super(camera: CameraComponent(viewport: TiltedViewport()));

  final Level level;
  final VoidCallback onEventShown;
  final void Function(SoundEffect) onSound;

  static void _silent(SoundEffect _) {}

  late ActorComponent _actor;
  Sprite? _robot;
  Sprite? _robotBack;
  Sprite? _robotFront;
  Sprite? _robotHead;
  Sprite? _robotBody;
  Image? _robotTurn;
  final _stars = <GridPoint, StarComponent>{};
  PlayState? _pending;

  /// The board on show: [level] itself or one of its `moreBoards`.
  late Level _board = level;

  /// The state [apply] got last, shown once a slide to another board ends.
  PlayState? _latest;

  /// While one board slides away and the next slides in.
  var _sliding = false;

  /// Changed since the last rebuild, so editing needs a fresh board.
  var _dirty = false;

  /// The run and board the world was last built for.
  (int, int)? _builtForRun;
  (int, int, int)? _animating;
  int? _celebrated;

  /// Quarter turns (0 to 3) the child has turned the map, clockwise, so
  /// they can look at it from the robot's side.
  var quarterTurns = 0;

  /// Seconds per tile while Koba rolls on through several steps; starting
  /// and stopping take [rollTime] for their tile, and a single step
  /// [stepTime].
  static const cruiseTime = 0.3;
  static const rollTime = cruiseTime * 1.5;
  static const stepTime = 0.4;
  static const turnTime = 0.35;

  /// How long a step takes and how it eases: from a stop unless it [rollIn]
  /// from the step before, and to a stop unless it [rollOn] into the next.
  static (double, Curve) moveTiming({
    required bool rollIn,
    required bool rollOn,
  }) => switch ((rollIn, rollOn)) {
    (false, false) => (stepTime, Curves.easeInOut),
    (false, true) => (rollTime, _speedUp),
    (true, true) => (cruiseTime, Curves.linear),
    (true, false) => (rollTime, _speedUp.flipped),
  };

  /// Whether the last step rolled on at speed, so the next one starts
  /// rolling instead of from a stop.
  var _rollingOn = false;

  /// This island's look: its background, path, obstacles and finish.
  late final worldTheme = WorldTheme.forConcept(level.concept);

  @override
  Color backgroundColor() => worldTheme.background;

  @override
  Future<void> onLoad() async {
    // The robot's picture loads alongside, without holding up the world;
    // until then (or in a test without the app's bindings and assets) the
    // plain character shows.
    if (_canLoadAssets) {
      unawaited(
        Sprite.load('robot.png').then((robot) {
          _robot = robot;
          _actor.sprite = robot;
        }, onError: (Object _) {}),
      );
      unawaited(
        Sprite.load('robot_head.png').then((head) {
          _robotHead = head;
          _actor.headSprite = head;
        }, onError: (Object _) {}),
      );
      unawaited(
        Sprite.load('robot_body.png').then((body) {
          _robotBody = body;
          _actor.bodySprite = body;
        }, onError: (Object _) {}),
      );
      unawaited(
        Sprite.load('robot_back.png').then((back) {
          _robotBack = back;
          _actor.backSprite = back;
        }, onError: (Object _) {}),
      );
      unawaited(
        images.load('robot_turn.webp').then((frames) {
          _robotTurn = frames;
          _actor.turnFrames = frames;
        }, onError: (Object _) {}),
      );
      unawaited(
        Sprite.load('robot_front.png').then((front) {
          _robotFront = front;
          _actor.frontSprite = front;
        }, onError: (Object _) {}),
      );
    }
    camera.viewfinder
      ..visibleGameSize = _boardView
      ..position = Vector2(level.width / 2, level.height / 2)
      ..anchor = Anchor.center;
    _build();
    _turnView(1);
    if (_pending case final state?) apply(state);
  }

  void _build() {
    world.removeAll(world.children.toList());
    _stars.clear();
    final board = _board;
    world
      ..add(BoardComponent(board, worldTheme))
      ..add(GoalComponent(board.goal, worldTheme.finish));
    for (final star in board.stars) {
      world.add(_stars[star] = StarComponent(star));
    }
    world.add(
      _actor =
          ActorComponent(
              board.start,
              board.startFacing,
              sprite: _robot,
              backSprite: _robotBack,
              frontSprite: _robotFront,
            )
            ..turnFrames = _robotTurn
            ..headSprite = _robotHead
            ..bodySprite = _robotBody,
    );
    _dirty = false;
    _rollingOn = false;
  }

  /// The board with the planet's ground around it.
  Vector2 get _boardView => Vector2(level.width + 0.9, level.height + 0.9);

  /// Room on the screen, in tiles, beyond the tilted ground: its side at the
  /// bottom and the robot standing up at the top.
  static const _standingRoom = 0.6;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    _turnView(dt);
    _pointerLeft -= dt;
    final pointer = _pointer;
    _actor.watching = pointer == null || _pointerLeft <= 0
        ? null
        : _gazeAt(pointer);
  }

  /// Where the child last touched or moved the mouse, in the game's pixels,
  /// and for how many seconds more Koba watches it.
  Vector2? _pointer;
  var _pointerLeft = 0.0;

  /// Koba's eyes follow a touch or the mouse at [global] (anywhere on the
  /// screen, in global coordinates) for a moment, as `KobaHead.follow`
  /// does; then they look the way it faces again.
  void lookAt(Offset global) {
    _pointer = convertGlobalToLocalCoordinate(global.toVector2());
    _pointerLeft = 1.5;
  }

  /// A touch at [global] on the world: on Koba it shakes its head with a
  /// smile and a happy beep (true), anywhere else nothing happens (false).
  bool touch(Offset global) {
    if (!isLoaded) return false;
    final at = convertGlobalToLocalCoordinate(global.toVector2());
    final middle = kobaOnScreen(up: 0.1);
    // At least 32 pixels round, so a small board still gives a 64dp target.
    final reach = max(32.0, 0.6 * camera.viewfinder.zoom);
    if (at.distanceTo(middle) > reach || !_actor.poke()) return false;
    onSound(SoundEffect.poke);
    return true;
  }

  /// Where Koba stands on the screen, in the game's pixels: its tile's
  /// middle on the tilted board, raised [up] tiles (its screen, where its
  /// eyes are, is 0.4 up).
  Vector2 kobaOnScreen({double up = 0}) {
    final at = camera.localToGlobal(_actor.position);
    // The viewport tilts everything around the middle of the screen.
    final middle = camera.viewport.size.y / 2;
    return Vector2(
      at.x,
      middle + (at.y - middle) * tilt - up * camera.viewfinder.zoom,
    );
  }

  /// Where Koba's pupils go to look at [pointer], in its picture's pixels:
  /// further off, the eyes turn further, up to the edge of the eye.
  Offset _gazeAt(Vector2 pointer) {
    final toward = pointer - kobaOnScreen(up: 0.4);
    final distance = toward.length;
    if (distance < 1) return Offset.zero;
    final reach = min(1.0, distance / (camera.viewfinder.zoom * 3));
    return Offset(
      toward.x / distance * 16 * reach,
      toward.y / distance * 24 * reach,
    );
  }

  /// Eases the view round to [quarterTurns], keeps the whole board in view
  /// at every angle, and keeps the flag, stars and hint marks upright.
  void _turnView(double dt) {
    final viewfinder = camera.viewfinder;
    final goal = quarterTurns % 4 * pi / 2;
    // The shortest way round, so 270° to 0° is one more quarter turn.
    final turn = atan2(
      sin(goal - viewfinder.angle),
      cos(goal - viewfinder.angle),
    );
    viewfinder.angle += turn * min(1.0, dt * 10);
    // The board's outline as turned on the screen, so it always fits.
    final c = cos(viewfinder.angle).abs(), s = sin(viewfinder.angle).abs();
    final board = _boardView;
    viewfinder.visibleGameSize = Vector2(
      board.x * c + board.y * s,
      (board.x * s + board.y * c) * tilt + _standingRoom,
    );
    final upright = viewfinder.angle;
    _actor.viewAngle = upright;
    for (final child in world.children) {
      if (child is BoardComponent) child.upright = upright;
      if (child is GoalComponent ||
          child is StarComponent ||
          child is HintMarkComponent) {
        (child as PositionComponent).angle = upright;
      }
    }
  }

  void apply(PlayState state) {
    if (!isLoaded) {
      _pending = state;
      return;
    }
    _latest = state;
    if (_sliding) return;
    switch (state.phase) {
      case PlayPhase.editing:
        _animating = null;
        if (_board != state.shownBoard) {
          _slideTo(state.shownBoard);
        } else if (_dirty) {
          _build();
        }
      case PlayPhase.running:
        final built = (state.runs, state.board);
        if (_builtForRun != built) {
          final goesOn = _builtForRun?.$1 == state.runs;
          _builtForRun = built;
          if (goesOn) {
            // The run solved a board and goes on to the next one.
            _slideTo(state.shownBoard, solved: true);
            return;
          }
          _board = state.shownBoard;
          _build();
        }
        final event = state.currentEvent;
        final key = (state.runs, state.board, state.cursor);
        if (event != null && _animating != key) {
          _animating = key;
          _dirty = true;
          _animate(event, rollOn: _movesNext(state), () {
            if (_animating == key) onEventShown();
          });
        }
      case PlayPhase.succeeded:
        if (_celebrated != state.runs) {
          _celebrated = state.runs;
          onSound(SoundEffect.goal);
          world.add(CelebrationComponent(_board.goal));
          _actor.face = RobotFace.cheer;
          _actor.add(
            SequenceEffect([
              ScaleEffect.to(
                Vector2.all(1.35),
                EffectController(duration: 0.2),
              ),
              ScaleEffect.to(
                Vector2.all(1),
                EffectController(duration: 0.25, curve: Curves.bounceOut),
              ),
            ], repeatCount: 2),
          );
        }
      case PlayPhase.failed:
        break;
    }
  }

  /// Slides the board on show away and [board] in from the other side.
  /// After a [solved] board Koba cheers at its flag first. Then the latest
  /// state is applied, so a run goes on on the new board.
  void _slideTo(Level board, {bool solved = false}) {
    _sliding = true;
    final viewfinder = camera.viewfinder;
    final middle = Vector2(level.width / 2, level.height / 2);
    // Along the screen's width, whichever way the map is turned.
    final angle = quarterTurns % 4 * pi / 2;
    final away =
        Vector2(cos(angle), sin(angle)) * (level.width + level.height + 2);
    if (solved) {
      onSound(SoundEffect.goal);
      world.add(CelebrationComponent(_board.goal));
      _actor.face = RobotFace.cheer;
    }
    viewfinder.add(
      MoveEffect.to(
        middle + away,
        EffectController(
          duration: 0.35,
          startDelay: solved ? 0.7 : 0,
          curve: Curves.easeIn,
        ),
        onComplete: () {
          _board = board;
          _build();
          viewfinder
            ..position = middle - away
            ..add(
              MoveEffect.to(
                middle,
                EffectController(duration: 0.35, curve: Curves.easeOut),
                onComplete: () {
                  _sliding = false;
                  if (_latest case final state?) apply(state);
                },
              ),
            );
        },
      ),
    );
  }

  /// Shows a solution as small blocks on the map, one by one in the order
  /// they run, then shrinks them away.
  ///
  /// The [trail] (tile centres along the route) is drawn out underneath as
  /// the blocks appear, showing which way they go. The blocks' arrows turn
  /// to follow the road unless [followRoad] is off (a parent setting).
  void showHint(
    List<HintMark> marks, {
    List<Vector2> trail = const [],
    bool followRoad = true,
  }) {
    if (!isLoaded) return;
    world.children.whereType<HintMarkComponent>().forEach(
      (old) => old.removeFromParent(),
    );
    world.children.whereType<HintTrailComponent>().forEach(
      (old) => old.removeFromParent(),
    );
    const step = 0.35;
    final fadeAt = marks.length * step + _hintVisible;
    if (trail.length > 1) {
      world.add(
        HintTrailComponent(trail, drawIn: marks.length * step)
          ..add(RemoveEffect(delay: fadeAt + 0.3)),
      );
    }
    for (var i = 0; i < marks.length; i++) {
      world.add(
        HintMarkComponent(marks[i], followRoad: followRoad)
          ..scale = Vector2.zero()
          ..addAll([
            ScaleEffect.to(
              Vector2.all(marks[i].big ? 1.6 : 1),
              EffectController(
                duration: 0.25,
                startDelay: i * step,
                curve: Curves.easeOutBack,
              ),
            ),
            ScaleEffect.to(
              Vector2.zero(),
              EffectController(
                duration: 0.3,
                startDelay: fadeAt + i * 0.05,
                curve: Curves.easeIn,
              ),
            ),
            RemoveEffect(delay: fadeAt + i * 0.05 + 0.35),
          ]),
      );
    }
  }

  /// How long a hint stays after its last block appears, in seconds.
  static const _hintVisible = 5.0;

  /// Whether Koba's next move after the event being shown is another step,
  /// past any stars it picks up on the way, and plays on without a pause
  /// (not in step mode): then it rolls on into it without stopping.
  static bool _movesNext(PlayState state) {
    final events = state.result?.events;
    if (state.stepping || events == null) return false;
    for (final event in events.skip(state.cursor + 1)) {
      if (event is! Collected) return event is Moved;
    }
    return false;
  }

  void _animate(RunEvent event, void Function() done, {bool rollOn = false}) {
    final rollIn = _rollingOn;
    if (event is! Collected) _rollingOn = event is Moved && rollOn;
    switch (event) {
      case StepsStored():
        // The number is displayed by PlayView from the same event stream.
        _actor.add(
          ScaleEffect.to(
            Vector2.all(1.12),
            EffectController(duration: 0.15),
            onComplete: () {
              _actor.add(
                ScaleEffect.to(
                  Vector2.all(1),
                  EffectController(duration: 0.15),
                  onComplete: done,
                ),
              );
            },
          ),
        );
      case Moved(:final to):
        onSound(SoundEffect.step);
        _actor.rolling = true;
        // Like a robot on wheels: it speeds up from a stop, rolls on at a
        // steady speed through steps in a row and brakes at the last one,
        // the speeds matching where steps meet.
        final (duration, curve) = moveTiming(rollIn: rollIn, rollOn: rollOn);
        _actor.add(
          MoveToEffect(
            tileCenter(to),
            EffectController(duration: duration, curve: curve),
            onComplete: () {
              if (!rollOn) _actor.rolling = false;
              done();
            },
          ),
        );
      case Turned(:final from, :final to):
        onSound(SoundEffect.turn);
        _actor.add(
          RotateEffect.by(
            to == from.left ? -pi / 2 : pi / 2,
            EffectController(duration: turnTime, curve: Curves.easeInOut),
            onComplete: done,
          ),
        );
      case Bumped(:final facing):
        // It bumps into the planet's obstacles, or the edge beside them.
        onSound(worldTheme.obstacle.bumpSound);
        _actor.face = RobotFace.dizzy;
        _actor.add(
          TimerComponent(
            period: 0.9,
            removeOnFinish: true,
            onTick: () => _actor.face = RobotFace.normal,
          ),
        );
        final nudge = Vector2(facing.dx * 0.28, facing.dy * 0.28);
        _actor.add(
          SequenceEffect([
            MoveByEffect(nudge, EffectController(duration: 0.12)),
            MoveByEffect(
              -nudge,
              EffectController(duration: 0.25, curve: Curves.elasticOut),
            ),
          ], onComplete: done),
        );
      case Collected(:final star):
        onSound(SoundEffect.star);
        // The star shrinks away on its own while Koba rolls on.
        final component = _stars.remove(star);
        component?.add(
          ScaleEffect.to(
            Vector2.zero(),
            EffectController(duration: 0.2),
            onComplete: () => component.removeFromParent(),
          ),
        );
        done();
      case PathChecked(:final ahead, :final clear):
        // Green or orange ring shows the check without moving the actor.
        // The result comes from the interpreter, never from this world.
        final ring = CircleComponent(
          radius: 0.32,
          position: tileCenter(ahead),
          anchor: Anchor.center,
          paint: Paint()
            ..color = clear ? const Color(0xFF43A047) : const Color(0xFFFB8C00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.06,
        );
        world.add(ring);
        ring.add(
          OpacityEffect.fadeOut(
            EffectController(duration: 0.3),
            onComplete: () {
              ring.removeFromParent();
              done();
            },
          ),
        );
    }
  }
}

/// Speeding up from a stop to rolling speed: still at the start, and at
/// the end 1.5 times as fast as on average, so a step [WorldGame.rollTime]
/// long ends at the speed of a step [WorldGame.cruiseTime] long.
const _speedUp = _SpeedUp();

class _SpeedUp extends Curve {
  const _SpeedUp();

  @override
  double transformInternal(double t) => 1.5 * t * t - 0.5 * t * t * t;
}

/// Whether assets can load: false in plain tests without Flutter's bindings.
bool get _canLoadAssets {
  try {
    ServicesBinding.instance;
    return true;
  } on Object catch (_) {
    return false;
  }
}

/// The game's viewport, tilting the board away from the child: everything is
/// drawn [tilt] as tall around the middle of the screen, after the map's
/// turn, so the board always tilts away whichever way it is turned. Upright
/// things stand back up where they are (`standUp`).
class TiltedViewport extends MaxViewport {
  @override
  void transformCanvas(Canvas canvas) {
    super.transformCanvas(canvas);
    canvas
      ..translate(0, size.y / 2)
      ..scale(1, tilt)
      ..translate(0, -size.y / 2);
  }
}
