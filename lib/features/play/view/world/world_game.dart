import 'dart:math';

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
  });

  final Level level;
  final VoidCallback onEventShown;
  final void Function(SoundEffect) onSound;

  static void _silent(SoundEffect _) {}

  late ActorComponent _actor;
  final _stars = <GridPoint, StarComponent>{};
  PlayState? _pending;

  /// Changed since the last rebuild, so editing needs a fresh board.
  var _dirty = false;
  int? _builtForRun;
  (int, int)? _animating;
  int? _celebrated;

  static const _moveTime = 0.35;
  static const _turnTime = 0.25;

  /// This island's look: its background, path, obstacles and finish.
  late final worldTheme = WorldTheme.forConcept(level.concept);

  @override
  Color backgroundColor() => worldTheme.background;

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..visibleGameSize = Vector2(level.width + 0.4, level.height + 0.4)
      ..position = Vector2(level.width / 2, level.height / 2)
      ..anchor = Anchor.center;
    _build();
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
    world.add(_actor = ActorComponent(level.start, level.startFacing));
    _dirty = false;
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
          _animate(event, () {
            if (_animating == key) onEventShown();
          });
        }
      case PlayPhase.succeeded:
        if (_celebrated != state.runs) {
          _celebrated = state.runs;
          onSound(SoundEffect.goal);
          world.add(CelebrationComponent(level.goal));
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
  /// the blocks appear, showing which way they go.
  void showHint(List<HintMark> marks, {List<Vector2> trail = const []}) {
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
        HintMarkComponent(marks[i])
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

  void _animate(RunEvent event, void Function() done) {
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
        _actor.add(
          MoveToEffect(
            tileCenter(to),
            EffectController(duration: _moveTime, curve: Curves.easeInOut),
            onComplete: done,
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
        onSound(SoundEffect.bump);
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
        final component = _stars.remove(star);
        if (component == null) return done();
        component.add(
          ScaleEffect.to(
            Vector2.zero(),
            EffectController(duration: 0.2),
            onComplete: () {
              component.removeFromParent();
              done();
            },
          ),
        );
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
