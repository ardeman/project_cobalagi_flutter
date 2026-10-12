import 'dart:math';

import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/view/world/world_components.dart';
import 'package:cobalagi/features/play/view/world/world_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 't',
  concept: 'sequencing',
  rows: ['S*G', '###'],
  startFacing: Direction.east,
  palette: {InstructionKind.move, InstructionKind.turnLeft},
);

void main() {
  test(
    'the map turns by quarter turns, pieces upright, board in view',
    () async {
      final game = await initializeGame(
        () => WorldGame(level: level, onEventShown: () {}),
      );
      void settle() {
        for (var i = 0; i < 60; i++) {
          game.update(0.05);
        }
      }

      settle();
      expect(game.camera.viewfinder.angle, closeTo(0, 1e-6));
      final world = game.world.children;
      for (final turns in [1, 2, 3]) {
        game.quarterTurns = turns;
        settle();
        final angle = turns * pi / 2;
        expect(
          cos(game.camera.viewfinder.angle - angle),
          closeTo(1, 1e-3),
          reason: '$turns quarter turns',
        );
        // The flag, the stars and the rocks stand upright on the screen.
        expect(
          cos(world.whereType<GoalComponent>().single.angle - angle),
          closeTo(1, 1e-3),
        );
        expect(
          cos(world.whereType<StarComponent>().single.angle - angle),
          closeTo(1, 1e-3),
        );
        expect(
          cos(world.whereType<BoardComponent>().single.upright - angle),
          closeTo(1, 1e-3),
        );
        // A 3 x 2 board shows 2 wide and 3 tall when turned sideways.
        final size = game.camera.viewfinder.visibleGameSize!;
        final sideways = turns.isOdd;
        expect(size.x, closeTo((sideways ? 2 : 3) + 0.4, 1e-2));
        expect(size.y, closeTo((sideways ? 3 : 2) + 0.4, 1e-2));
      }
      // A fourth turn brings it back, the short way round.
      game.quarterTurns = 0;
      settle();
      expect(cos(game.camera.viewfinder.angle), closeTo(1, 1e-3));
    },
  );
}
