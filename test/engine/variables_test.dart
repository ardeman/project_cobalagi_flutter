import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/play/cubit/play_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 'variables-test',
  concept: 'variables',
  rows: ['S.....G'],
  startFacing: Direction.east,
  palette: InstructionKind.values.toSet(),
);

void main() {
  test(
    'stores, reuses and changes the value with source IDs and cell events',
    () {
      const program = Program([
        SetSteps(2, blockId: 'save'),
        MoveSteps(blockId: 'use'),
        SetSteps(4, blockId: 'change'),
        MoveSteps(blockId: 'use-again'),
      ]);
      final result = runProgram(program, level);
      expect(result.succeeded, isTrue);
      expect(result.steps, 8);
      expect(result.events.whereType<StepsStored>().map((e) => e.value), [
        2,
        4,
      ]);
      expect(result.events.whereType<Moved>().map((e) => e.blockId), [
        'use',
        'use',
        'use-again',
        'use-again',
        'use-again',
        'use-again',
      ]);
      expect(validateProgram(program, level), isEmpty);
      expect(program.blockCount, 4);
    },
  );
  test('stored value is shared by procedures and loops', () {
    const program = Program(
      [
        SetSteps(2),
        Repeat(3, [Call()]),
      ],
      procedure: [MoveSteps()],
    );
    expect(validateProgram(program, level), isEmpty);
    expect(runProgram(program, level).succeeded, isTrue);
    const settingProcedure = Program(
      [Call(), MoveSteps()],
      procedure: [SetSteps(6)],
    );
    expect(validateProgram(settingProcedure, level), isEmpty);
    expect(runProgram(settingProcedure, level).succeeded, isTrue);
  });
  test('each run starts with an empty box and refuses an unset use', () {
    expect(
      runProgram(const Program([SetSteps(6), MoveSteps()]), level).succeeded,
      isTrue,
    );
    const unset = Program([MoveSteps(blockId: 'needs-save')]);
    expect(
      validateProgram(unset, level).single,
      isA<UnsetSteps>().having((e) => e.blockId, 'source', 'needs-save'),
    );
    final result = runProgram(unset, level);
    expect(result.outcome, RunOutcome.stoppedShort);
    expect(result.events, isEmpty);
  });
  test(
    'conditional assignment cannot initialize a value for the outer program',
    () {
      const program = Program([
        IfPathClear([SetSteps(3)]),
        MoveSteps(),
      ]);
      expect(validateProgram(program, level).single, isA<UnsetSteps>());
      expect(
        validateProgram(
          const Program([
            IfPathClear([SetSteps(3), MoveSteps()]),
          ]),
          level,
        ),
        isEmpty,
      );
      expect(
        validateProgram(
          const Program([
            Repeat(2, [SetSteps(3)]),
            MoveSteps(),
          ]),
          level,
        ),
        isEmpty,
      );
    },
  );
  test('range, palette and block limit use the shared validator', () {
    expect(
      validateProgram(const Program([SetSteps(0), MoveSteps()]), level),
      contains(isA<CountOutOfRange>()),
    );
    expect(
      validateProgram(const Program([SetSteps(10)]), level),
      contains(isA<CountOutOfRange>()),
    );
    final restricted = Level.fromJson({
      ...level.toJson(),
      'palette': ['move'],
      'maxBlocks': 1,
    });
    final issues = validateProgram(
      const Program([SetSteps(2), MoveSteps()]),
      restricted,
    );
    expect(issues.whereType<DisallowedInstruction>(), hasLength(2));
    expect(issues, contains(isA<TooManyBlocks>()));
  });
  test('assignment and movements respect the execution limit and walls', () {
    expect(
      runProgram(
        const Program([
          Repeat(9, [SetSteps(2)]),
        ]),
        level,
        stepLimit: 3,
      ).outcome,
      RunOutcome.tooManySteps,
    );
    expect(
      runProgram(
        const Program([SetSteps(9), MoveSteps()]),
        level,
        stepLimit: 3,
      ).outcome,
      RunOutcome.tooManySteps,
    );
    final wall = Level.fromRows(
      id: 'wall',
      concept: 'variables',
      rows: ['S.#G'],
      startFacing: Direction.east,
      palette: InstructionKind.values.toSet(),
    );
    final result = runProgram(const Program([SetSteps(3), MoveSteps()]), wall);
    expect(result.outcome, RunOutcome.bumped);
    expect(result.events.last, isA<Bumped>());
  });
  test(
    'playback shows only values already reached and reset clears them',
    () async {
      final play = PlayCubit(level);
      addTearDown(play.close);
      play.step(
        const Program([SetSteps(2), MoveSteps(), SetSteps(4), MoveSteps()]),
      );
      expect(play.state.storedSteps, 2);
      play.eventShown(); // First movement, paused.
      expect(play.state.storedSteps, 2);
      play.step(const Program([]));
      play.eventShown(); // Second movement, paused.
      expect(play.state.storedSteps, 2);
      play.step(const Program([]));
      play.eventShown(); // The second assignment is reached.
      expect(play.state.storedSteps, 4);
      play.reset();
      expect(play.state.storedSteps, isNull);
    },
  );
}
