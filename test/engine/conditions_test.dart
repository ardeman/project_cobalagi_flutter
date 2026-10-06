import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level corridor({Direction facing = Direction.east}) => Level.fromRows(
  id: 'conditions-test',
  concept: 'conditions',
  rows: ['S.G'],
  startFacing: facing,
  palette: InstructionKind.values.toSet(),
);

void main() {
  test('clear checks execute their body and preserve check and action ids', () {
    final result = runProgram(
      const Program([
        IfPathClear([Move(blockId: 'move')], blockId: 'eye'),
        Move(),
      ]),
      corridor(),
    );
    expect(result.succeeded, isTrue);
    final check = result.events.whereType<PathChecked>().single;
    expect(check.clear, isTrue);
    expect(check.blockId, 'eye');
    expect(result.events.whereType<Moved>().first.blockId, 'move');
  });

  test('an edge skips the body then continues without a bump', () {
    final result = runProgram(
      const Program([
        IfPathClear([Move()]),
        TurnRight(),
        Move(),
        Move(),
      ]),
      corridor(facing: Direction.north),
    );
    expect(result.succeeded, isTrue);
    expect(result.events.whereType<PathChecked>().single.clear, isFalse);
    expect(result.events.whereType<Bumped>(), isEmpty);
  });

  test('each iteration checks again and stops safely at a wall', () {
    final level = Level.fromRows(
      id: 'corner',
      concept: 'conditions',
      rows: ['#####', '#S..#', '###G#', '#####'],
      startFacing: Direction.east,
      palette: InstructionKind.values.toSet(),
    );
    final result = runProgram(
      const Program([
        Repeat(5, [
          IfPathClear([Move()]),
        ]),
        TurnRight(),
        IfPathClear([Move()]),
      ]),
      level,
    );
    expect(result.succeeded, isTrue);
    expect(result.events.whereType<PathChecked>().map((c) => c.clear), [
      true,
      true,
      false,
      false,
      false,
      true,
    ]);
  });

  test('a check applies once, not to every action in its body', () {
    final result = runProgram(
      const Program([
        IfPathClear([Move(steps: 4)]),
      ]),
      Level.fromRows(
        id: 'wall',
        concept: 'conditions',
        rows: ['S.#G'],
        startFacing: Direction.east,
        palette: InstructionKind.values.toSet(),
      ),
    );
    expect(result.outcome, RunOutcome.bumped);
  });

  test('blocked checks consume the execution budget', () {
    final result = runProgram(
      const Program([
        Repeat(9, [
          IfPathClear([Move()]),
        ]),
      ]),
      corridor(facing: Direction.north),
      stepLimit: 3,
    );
    expect(result.outcome, RunOutcome.tooManySteps);
    expect(result.events.whereType<PathChecked>(), hasLength(3));
  });

  test('validation visits condition bodies and counts every nested block', () {
    final empty = validateProgram(
      const Program([IfPathClear([], blockId: 'empty')]),
      corridor(),
    );
    expect(empty.single, isA<EmptyCondition>());
    expect(empty.single.blockId, 'empty');
    final program = const Program([
      IfPathClear([Call(blockId: 'call'), Move(steps: 0, blockId: 'move')]),
    ]);
    expect(program.blockCount, 3);
    final issues = validateProgram(program, corridor());
    expect(issues.whereType<EmptyProcedure>().single.blockId, 'call');
    expect(issues.whereType<CountOutOfRange>().single.blockId, 'move');
  });
}
