import 'dart:math';

import 'package:cobalagi/engine/generator/puzzle_generator.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/program_json.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

Set<InstructionKind> kinds(List<Instruction> body) => {
  for (final i in body) ...[
    i.kind,
    if (i case Repeat(:final body) || IfPathClear(:final body)) ...kinds(body),
  ],
};

void main() {
  test('starter programs read from and write to lesson JSON', () {
    const json = {
      'body': [
        'move',
        {
          'repeat': 3,
          'body': [
            'turnLeft',
            {
              'ifPathClear': ['move'],
            },
          ],
        },
        {'setSteps': 2},
        'moveSteps',
        'call',
      ],
      'procedure': ['turnRight', 'move'],
    };
    final program = programFromJson(json);
    expect(program.body, hasLength(5));
    expect((program.body[1] as Repeat).times, 3);
    expect(programToJson(program), json);
    expect(programToJson(programFromJson(['move', 'turnLeft'])), [
      'move',
      'turnLeft',
    ]);
    expect(
      () => programFromJson(['jump']),
      throwsA(isA<LevelFormatException>()),
    );
  });

  for (
    var difficulty = minDifficulty;
    difficulty <= maxDifficulty;
    difficulty++
  ) {
    test(
      'debugging puzzles start with a bug that the solution fixes (d$difficulty)',
      () {
        for (var seed = 0; seed < 40; seed++) {
          final puzzle = generatePuzzle(
            PuzzleKind.debugging,
            difficulty: difficulty,
            seed: seed,
          );
          final level = puzzle.level;
          final starter = level.starter!;
          expect(level.concept, 'debugging');
          expect(
            runProgram(starter, level).succeeded,
            isFalse,
            reason: 'seed $seed',
          );
          expect(runProgram(puzzle.solution, level).succeeded, isTrue);
          // The bug is fixable within the palette and the block limit.
          expect(
            validateProgram(starter, level),
            isEmpty,
            reason: 'seed $seed',
          );
          expect(validateProgram(puzzle.solution, level), isEmpty);
          expect(kinds(starter.body).difference(level.palette), isEmpty);
          // The starter survives a trip through lesson JSON.
          expect(
            Level.fromJson(level.toJson()).starter!.blockCount,
            starter.blockCount,
          );
        }
      },
    );
  }

  test('later debugging puzzles hide the bug in a repeat route', () {
    final puzzle = generatePuzzle(PuzzleKind.debugging, difficulty: 4, seed: 3);
    expect(puzzle.level.palette, contains(InstructionKind.repeat));
    expect(kinds(puzzle.level.starter!.body), contains(InstructionKind.repeat));
  });

  test('the same seed gives the same bug', () {
    Object json(int seed) => generatePuzzle(
      PuzzleKind.debugging,
      difficulty: 3,
      seed: seed,
    ).level.toJson();
    expect(json(7), json(7));
  });

  test('plantBug changes exactly one thing', () {
    const program = Program([
      Move(),
      Move(),
      TurnLeft(),
      Repeat(3, [Move(), TurnRight()]),
    ]);
    for (var seed = 0; seed < 50; seed++) {
      final bugged = plantBug(program, Random(seed))!;
      expect(programToJson(bugged), isNot(programToJson(program)));
      // At most one block more or fewer.
      expect(
        (bugged.blockCount - program.blockCount).abs(),
        lessThanOrEqualTo(1),
      );
    }
  });
}
