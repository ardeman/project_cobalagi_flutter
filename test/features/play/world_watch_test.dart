import 'dart:math';

import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/view/world/world_components.dart';
import 'package:cobalagi/features/play/view/world/world_game.dart';
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 'watch',
  concept: 'sequencing',
  rows: ['..S..', '.....', '....G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move},
);

void main() {
  Future<(WorldGame, List<SoundEffect>)> start() async {
    final sounds = <SoundEffect>[];
    final game = await initializeGame(
      () => WorldGame(level: level, onEventShown: () {}, onSound: sounds.add),
    );
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    return (game, sounds);
  }

  ActorComponent koba(WorldGame game) =>
      game.world.children.whereType<ActorComponent>().single;

  void settle(WorldGame game, {double seconds = 0.5}) {
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      game.update(1 / 60);
    }
  }

  test(
    "Koba's eyes follow a touch or the mouse, then look ahead again",
    () async {
      final (game, _) = await start();
      final eyes = koba(game).kobaEyes;
      final facing = koba(game).gaze;
      game.lookAt((eyes + Vector2(0, 400)).toOffset());
      settle(game);
      expect(koba(game).gaze.dy, greaterThan(20), reason: 'looks down');
      expect(koba(game).gaze.dx.abs(), lessThan(1));
      game.lookAt((eyes - Vector2(400, 0)).toOffset());
      settle(game);
      expect(koba(game).gaze.dx, lessThan(-14), reason: 'looks left');
      expect(koba(game).headTurn, lessThan(-0.05), reason: 'turns its head');
      settle(game, seconds: 2);
      expect(
        (koba(game).gaze - facing).distance,
        lessThan(0.5),
        reason: 'it looks the way it faces once the pointer rests',
      );
    },
  );

  test(
    'touching Koba makes it shake its head with a smile and a beep',
    () async {
      final (game, sounds) = await start();
      expect(
        game.touch((koba(game).kobaEyes + Vector2(0, 200)).toOffset()),
        isFalse,
      );
      expect(game.touch(game.kobaOnScreen().toOffset()), isTrue);
      expect(sounds, [SoundEffect.poke]);
      final turns = <double>[];
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
        turns.add(koba(game).headTurn);
      }
      expect(turns.reduce(max), greaterThan(0.08), reason: 'shakes its head');
      expect(turns.reduce(min), lessThan(-0.08));
      // Tapping again while it shakes does nothing more.
      expect(game.touch(game.kobaOnScreen().toOffset()), isFalse);
      settle(game, seconds: 1);
      expect(game.touch(game.kobaOnScreen().toOffset()), isTrue);
      expect(sounds, [SoundEffect.poke, SoundEffect.poke]);
    },
  );

  test('touched with its back turned, Koba shakes its head without '
      'turning round', () {
    final actor = ActorComponent(const GridPoint(0, 0), Direction.north);
    expect(actor.showsBack, isTrue);
    expect(actor.poke(), isTrue);
    final turns = <double>[];
    for (var i = 0; i < 30; i++) {
      actor.update(1 / 60);
      turns.add(actor.headTurn);
      expect(actor.showsBack, isTrue, reason: 'its back stays turned');
    }
    expect(turns.reduce(max), greaterThan(0.08), reason: 'shakes its head');
  });
}

extension on ActorComponent {
  Vector2 get kobaEyes => (findGame()! as WorldGame).kobaOnScreen(up: 0.4);
}
