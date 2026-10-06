import 'package:cobalagi/engine/generator/puzzle_generator.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

bool usesRepeat(List<Instruction> body) => body.any((i) => i is Repeat);

void main() {
  for (final kind in PuzzleKind.values) {
    for (
      var difficulty = minDifficulty;
      difficulty <= maxDifficulty;
      difficulty++
    ) {
      test('${kind.name} difficulty $difficulty: 40 seeds are valid', () {
        final fingerprints = <String>{};
        for (var seed = 0; seed < 40; seed++) {
          final puzzle = generatePuzzle(
            kind,
            difficulty: difficulty,
            seed: seed,
          );
          final level = puzzle.level;
          fingerprints.add(level.fingerprint);

          expect(level.concept, kind.name);
          expect(validateProgram(puzzle.solution, level), isEmpty);
          expect(runProgram(puzzle.solution, level).succeeded, isTrue);
          // JSON round trip keeps the puzzle identical.
          expect(Level.fromJson(level.toJson()).fingerprint, level.fingerprint);

          if (kind == PuzzleKind.loops) {
            expect(usesRepeat(puzzle.solution.body), isTrue);
            expect(solve(level)!.blockCount, greaterThan(level.maxBlocks!));
          } else if (kind == PuzzleKind.functions) {
            expect(puzzle.solution.body, contains(isA<Call>()));
            expect(puzzle.solution.procedure, isNotEmpty);
            expect(level.palette, contains(InstructionKind.call));
            expect(level.palette, isNot(contains(InstructionKind.repeat)));
            expect(solve(level)!.blockCount, greaterThan(level.maxBlocks!));
          } else if (kind == PuzzleKind.variables) {
            expect(puzzle.solution.body, contains(isA<SetSteps>()));
            expect(puzzle.solution.body, contains(isA<MoveSteps>()));
            expect(level.palette, isNot(contains(InstructionKind.move)));
            expect(
              puzzle.solution.blockCount,
              lessThanOrEqualTo(level.maxBlocks!),
            );
            final stores = runProgram(
              puzzle.solution,
              level,
            ).events.whereType<StepsStored>();
            expect(stores.length, difficulty < 3 ? 1 : greaterThan(1));
          } else if (kind == PuzzleKind.conditions) {
            final checks = runProgram(
              puzzle.solution,
              level,
            ).events.whereType<PathChecked>();
            expect(checks.any((check) => check.clear), isTrue);
            expect(checks.any((check) => !check.clear), isTrue);
            expect(level.palette, contains(InstructionKind.ifPathClear));
          } else if (kind == PuzzleKind.debugging) {
            // Steps and turns first, then routes with a repeat; the rest is
            // covered in debugging_test.dart.
            expect(
              level.palette.contains(InstructionKind.repeat),
              difficulty >= 3,
            );
            expect(runProgram(level.starter!, level).succeeded, isFalse);
          } else {
            expect(level.palette, isNot(contains(InstructionKind.repeat)));
          }
        }
        // Variations: most seeds give a different layout.
        expect(fingerprints.length, greaterThan(10));
      });
    }
  }

  test('the same seed gives the same puzzle', () {
    final a = generatePuzzle(PuzzleKind.sequencing, difficulty: 3, seed: 7);
    final b = generatePuzzle(PuzzleKind.sequencing, difficulty: 3, seed: 7);
    expect(a.level.fingerprint, b.level.fingerprint);
  });

  test('rejects out-of-range difficulty', () {
    expect(
      () => generatePuzzle(PuzzleKind.loops, difficulty: 0, seed: 1),
      throwsRangeError,
    );
  });
}
