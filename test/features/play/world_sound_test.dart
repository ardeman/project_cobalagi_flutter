import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/cubit/play_cubit.dart';
import 'package:cobalagi/features/play/view/world/world_components.dart';
import 'package:cobalagi/features/play/view/world/world_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 't',
  concept: 'sequencing',
  rows: ['S*G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move, InstructionKind.turnLeft},
);

void main() {
  test('the world finishes clear and blocked check animations', () async {
    final checkedLevel = Level.fromRows(
      id: 'checks',
      concept: 'conditions',
      rows: ['#####', '#S.G#', '#####'],
      startFacing: Direction.north,
      palette: InstructionKind.values.toSet(),
    );
    final sounds = <SoundEffect>[];
    final play = PlayCubit(checkedLevel);
    addTearDown(play.close);
    final game = await initializeGame(
      () => WorldGame(
        level: checkedLevel,
        onEventShown: play.eventShown,
        onSound: sounds.add,
      ),
    );
    final subscription = play.stream.listen(game.apply);
    addTearDown(subscription.cancel);
    play.run(
      const Program([
        IfPathClear([Move()], blockId: 'blocked'),
        TurnRight(),
        Repeat(3, [
          IfPathClear([Move()], blockId: 'clear'),
        ]),
      ]),
    );
    for (var i = 0; i < 100 && play.state.phase == PlayPhase.running; i++) {
      await Future<void>.delayed(Duration.zero);
      game.update(0.1);
    }
    await Future<void>.delayed(Duration.zero);
    expect(play.state.phase, PlayPhase.succeeded);
    expect(sounds, [
      SoundEffect.turn,
      SoundEffect.step,
      SoundEffect.step,
      SoundEffect.goal,
    ]);
  });

  test(
    'the world plays a sound with each event and celebrates success',
    () async {
      final sounds = <SoundEffect>[];
      final play = PlayCubit(level);
      final game = await initializeGame(
        () => WorldGame(
          level: level,
          onEventShown: play.eventShown,
          onSound: sounds.add,
        ),
      );
      play.stream.listen(game.apply);
      play.run(
        const Program([
          TurnLeft(),
          TurnLeft(),
          TurnLeft(),
          TurnLeft(),
          Move(),
          Move(),
        ]),
      );
      for (var i = 0; i < 100 && play.state.phase == PlayPhase.running; i++) {
        await Future<void>.delayed(Duration.zero);
        game.update(0.1);
      }
      await Future<void>.delayed(Duration.zero);
      expect(play.state.phase, PlayPhase.succeeded);
      // Confetti bursts over the flag, then cleans itself up.
      game.update(0);
      expect(
        game.world.children.whereType<CelebrationComponent>(),
        hasLength(1),
      );
      for (var i = 0; i < 25; i++) {
        game.update(0.1);
      }
      expect(game.world.children.whereType<CelebrationComponent>(), isEmpty);
      expect(sounds, [
        for (var i = 0; i < 4; i++) SoundEffect.turn,
        SoundEffect.step,
        SoundEffect.star,
        SoundEffect.step,
        SoundEffect.goal,
      ]);
    },
  );
}
