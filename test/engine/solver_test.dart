import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level level(List<String> rows, {Direction facing = Direction.east}) =>
    Level.fromRows(
      id: 't',
      concept: 'test',
      rows: rows,
      startFacing: facing,
      palette: InstructionKind.values.toSet(),
    );

void main() {
  test('finds a shortest solution that the interpreter accepts', () {
    final l = level(['S.#', '#.#', '#.G']);
    final solution = solve(l)!;
    // move, right, move, move, left, move
    expect(solution.body, hasLength(6));
    expect(runProgram(solution, l).succeeded, isTrue);
  });

  test('collects every star', () {
    final l = level(['*.S.G']);
    final solution = solve(l)!;
    final run = runProgram(solution, l);
    expect(run.succeeded, isTrue);
    expect(run.starsCollected, 1);
  });

  test('returns null when the goal is unreachable', () {
    expect(solve(level(['S#G'])), isNull);
  });
}
