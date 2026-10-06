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
import 'world_components.dart';

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

  @override
  Color backgroundColor() => const Color(0xFFBFE6FF);

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
      ..add(BoardComponent(level))
      ..add(GoalComponent(level.goal));
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

  /// Shows the route as footprints that appear one by one, then fade away.
  void showHint(List<GridPoint> route) {
    if (!isLoaded) return;
    for (var i = 0; i < route.length; i++) {
      world.add(
        CircleComponent(
          radius: 0.12,
          position: tileCenter(route[i]),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xCCFF7A59),
          scale: Vector2.zero(),
        )..addAll([
          ScaleEffect.to(
            Vector2.all(1),
            EffectController(duration: 0.15, startDelay: i * 0.12),
          ),
          OpacityEffect.fadeOut(
            EffectController(duration: 0.6, startDelay: 2.5 + i * 0.05),
          ),
          RemoveEffect(delay: 3.4 + i * 0.05),
        ]),
      );
    }
  }

  void _animate(RunEvent event, void Function() done) {
    switch (event) {
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
    }
  }
}
