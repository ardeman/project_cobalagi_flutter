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

Level corridor(List<String> rows) => Level.fromRows(
  id: 'u',
  concept: 'until',
  rows: rows,
  startFacing: Direction.east,
  palette: const {
    InstructionKind.move,
    InstructionKind.turnLeft,
    InstructionKind.turnRight,
    InstructionKind.untilGoal,
  },
);

void main() {
  group('repeat until the flag', () {
    test('keeps going until the flag, however far it is', () {
      for (final length in [2, 5, 9]) {
        final level = corridor([
          '#' * (length + 3),
          '#S${'.' * (length - 1)}G#',
          '#' * (length + 3),
        ]);
        final run = runProgram(
          const Program([
            RepeatUntilGoal([Move()]),
          ]),
          level,
        );
        expect(run.succeeded, isTrue);
        expect(run.events.whereType<Moved>(), hasLength(length));
      }
    });

    test('stops at a wall, and at the step limit when it never moves', () {
      final level = corridor(['#####', '#S#G#', '#...#', '#####']);
      expect(
        runProgram(
          const Program([
            RepeatUntilGoal([Move()]),
          ]),
          level,
        ).outcome,
        RunOutcome.bumped,
      );
      final spinning = runProgram(
        const Program([
          RepeatUntilGoal([TurnLeft()]),
        ]),
        level,
      );
      expect(spinning.outcome, RunOutcome.tooManySteps);
    });

    test('walks past the flag until every star is collected', () {
      final level = corridor(['######', '#SG.*#', '######']);
      final run = runProgram(
        const Program([
          RepeatUntilGoal([Move()]),
        ]),
        level,
      );
      // Over the flag, to the star, then into the wall.
      expect(run.outcome, RunOutcome.bumped);
      expect(run.starsCollected, 1);
    });

    test('an empty one is pointed out before running', () {
      final level = corridor(['#####', '#S.G#', '#####']);
      expect(
        validateProgram(
          const Program([RepeatUntilGoal([], blockId: 'u')]),
          level,
        ).single,
        isA<EmptyUntil>(),
      );
    });

    test('reads and writes lesson JSON and typed code', () {
      const program = Program([
        Move(),
        RepeatUntilGoal([
          Move(),
          TurnLeft(),
          IfPathClear([Move()]),
        ]),
      ]);
      expect(programToJson(programFromJson(programToJson(program))), [
        'move',
        {
          'untilGoal': [
            'move',
            'turnLeft',
            {
              'ifPathClear': ['move'],
            },
          ],
        },
      ]);
      final code = formatCode(program);
      expect(code, contains('until_flag {'));
      expect(programToJson(compileCode(code)), programToJson(program));
    });
  });

  for (
    var difficulty = minDifficulty;
    difficulty <= maxDifficulty;
    difficulty++
  ) {
    test('until puzzles need the loop and fit it (d$difficulty)', () {
      for (var seed = 0; seed < 40; seed++) {
        final puzzle = generatePuzzle(
          PuzzleKind.until,
          difficulty: difficulty,
          seed: seed,
        );
        final level = puzzle.level;
        expect(level.concept, 'until');
        expect(level.palette, contains(InstructionKind.untilGoal));
        expect(level.palette, isNot(contains(InstructionKind.repeat)));
        expect(puzzle.solution.body.last, isA<RepeatUntilGoal>());
        expect(validateProgram(puzzle.solution, level), isEmpty);
        expect(runProgram(puzzle.solution, level).succeeded, isTrue);
        expect(solve(level)!.blockCount, greaterThan(level.maxBlocks!));
      }
    });
  }
}
