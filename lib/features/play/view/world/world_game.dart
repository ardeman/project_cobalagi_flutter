import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' show Image;

import 'package:flame/camera.dart' show MaxViewport;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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
  Image? _robotTurn;
  final _stars = <GridPoint, StarComponent>{};
  PlayState? _pending;

  /// Changed since the last rebuild, so editing needs a fresh board.
  var _dirty = false;
  int? _builtForRun;
  (int, int)? _animating;
  int? _celebrated;

  /// Quarter turns (0 to 3) the child has turned the map, clockwise, so
  /// they can look at it from the robot's side.
  var quarterTurns = 0;

  /// Seconds per tile while Koba rolls on through several steps; starting
  /// and stopping take [_rollTime] for their tile, and a single step
  /// [_stepTime].
  static const _cruiseTime = 0.3;
  static const _rollTime = _cruiseTime * 1.5;
  static const _stepTime = 0.4;
  static const _turnTime = 0.35;

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
    world
      ..add(BoardComponent(level, worldTheme))
      ..add(GoalComponent(level.goal, worldTheme.finish));
    for (final star in level.stars) {
      world.add(_stars[star] = StarComponent(star));
    }
    world.add(
      _actor = ActorComponent(
        level.start,
        level.startFacing,
        sprite: _robot,
        backSprite: _robotBack,
        frontSprite: _robotFront,
      )..turnFrames = _robotTurn,
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
    if (isLoaded) _turnView(dt);
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
    switch (state.phase) {
      case PlayPhase.editing:
        _animating = null;
        if (_dirty) _build();
      case PlayPhase.running:
        if (_builtForRun != state.runs) {
          _builtForRun = state.runs;
          _build();
        }
        final event = state.currentEvent;
        final key = (state.runs, state.cursor);
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
          world.add(CelebrationComponent(level.goal));
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
        final (duration, curve) = switch ((rollIn, rollOn)) {
          (false, false) => (_stepTime, Curves.easeInOut),
          (false, true) => (_rollTime, _speedUp),
          (true, true) => (_cruiseTime, Curves.linear),
          (true, false) => (_rollTime, _speedUp.flipped),
        };
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
            EffectController(duration: _turnTime, curve: Curves.easeInOut),
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
/// the end 1.5 times as fast as on average, so a step [WorldGame._rollTime]
/// long ends at the speed of a step [WorldGame._cruiseTime] long.
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
