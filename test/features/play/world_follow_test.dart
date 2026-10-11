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
  test('following, the view turns so the robot faces up', () async {
    final game = await initializeGame(
      () => WorldGame(level: level, onEventShown: () {})..follow = true,
    );
    game.update(0.1);
    // Facing east: the view turns a quarter, so east is up on the screen.
    expect(game.camera.viewfinder.angle, closeTo(pi / 2, 1e-6));
    // The flag, the stars and the rocks stand upright on the screen.
    final world = game.world.children;
    expect(
      world.whereType<GoalComponent>().single.angle,
      closeTo(pi / 2, 1e-6),
    );
    expect(
      world.whereType<StarComponent>().single.angle,
      closeTo(pi / 2, 1e-6),
    );
    expect(
      world.whereType<BoardComponent>().single.upright,
      closeTo(pi / 2, 1e-6),
    );
    expect(
      world.whereType<ActorComponent>().single.viewAngle,
      closeTo(pi / 2, 1e-6),
    );

    // Turned off, it eases back to the board as drawn.
    game.follow = false;
    for (var i = 0; i < 30; i++) {
      game.update(0.05);
    }
    expect(game.camera.viewfinder.angle, closeTo(0, 1e-3));
    expect(world.whereType<GoalComponent>().single.angle, closeTo(0, 1e-3));
  });

  test('not following, the board shows as drawn', () async {
    final game = await initializeGame(
      () => WorldGame(level: level, onEventShown: () {}),
    );
    game.update(0.1);
    expect(game.camera.viewfinder.angle, 0);
  });
}
