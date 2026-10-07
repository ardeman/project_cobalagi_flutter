import 'package:cobalagi/engine/generator/puzzle_generator.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/program_json.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/typed/data/typed_program.dart';
import 'package:flutter_test/flutter_test.dart';

const followRight = Program([
  RepeatUntilGoal([
    IfElsePathClear([Move()], [TurnRight()]),
  ]),
]);

Level maze(List<String> rows) => Level.fromRows(
  id: 'o',
  concept: 'otherwise',
  rows: rows,
  startFacing: Direction.east,
  palette: const {
    InstructionKind.move,
    InstructionKind.turnLeft,
    InstructionKind.turnRight,
    InstructionKind.untilGoal,
    InstructionKind.ifElse,
  },
);

final lShape = maze(['#####', '#S..#', '###.#', '###G#', '#####']);

void main() {
  test('steps while the path is clear, otherwise turns', () {
    final run = runProgram(followRight, lShape);
    expect(run.succeeded, isTrue);
    final checks = run.events.whereType<PathChecked>().toList();
    expect(checks.where((c) => c.clear), isNotEmpty);
    expect(checks.where((c) => !c.clear), hasLength(1));
  });

  test('only one row runs each time', () {
    // Turning left at the wall faces the wall of the other side: no flag.
    final wrongWay = Program([
      RepeatUntilGoal([
        IfElsePathClear([const Move()], [const TurnLeft()]),
      ]),
    ]);
    expect(runProgram(wrongWay, lShape).succeeded, isFalse);
  });

  test('both rows need a block', () {
    for (final program in [
      const Program([
        RepeatUntilGoal([
          IfElsePathClear([], [TurnRight()]),
        ]),
      ]),
      const Program([
        RepeatUntilGoal([
          IfElsePathClear([Move()], []),
        ]),
      ]),
    ]) {
      expect(validateProgram(program, lShape), contains(isA<EmptyCondition>()));
    }
    expect(validateProgram(followRight, lShape), isEmpty);
  });

  test('counts both rows toward the block limit', () {
    expect(followRight.blockCount, 4);
  });

  test('round-trips through lesson JSON and typed code', () {
    final json = programToJson(followRight);
    expect(json, [
      {
        'untilGoal': [
          {
            'ifPathClear': ['move'],
            'otherwise': ['turnRight'],
          },
        ],
      },
    ]);
    expect(programToJson(programFromJson(json)), json);
    final code = formatCode(followRight);
    expect(code, contains('} otherwise {'));
    expect(programToJson(compileCode(code)), json);
    // Without "otherwise" it stays the plain eye block.
    expect(
      compileCode('if_path_clear { move(); }').body.single,
      isA<IfPathClear>(),
    );
  });

  test('generated puzzles need the otherwise block to fit', () {
    for (var difficulty = 1; difficulty <= 5; difficulty++) {
      final puzzle = generatePuzzle(
        PuzzleKind.otherwise,
        difficulty: difficulty,
        seed: difficulty * 7,
      );
      final level = puzzle.level;
      expect(level.palette, contains(InstructionKind.ifElse));
      expect(runProgram(puzzle.solution, level).succeeded, isTrue);
      expect(solve(level)!.blockCount, greaterThan(level.maxBlocks!));
    }
  });
}
