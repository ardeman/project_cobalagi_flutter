import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/interpreter/run_event.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
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
  final corridor = level(['S...G']);

  test('moving to the goal succeeds and stops there', () {
    final result = runProgram(
      const Program([Move(steps: 4, blockId: 'a'), TurnLeft(blockId: 'b')]),
      corridor,
    );
    expect(result.outcome, RunOutcome.success);
    expect(result.position, const GridPoint(4, 0));
    expect(result.steps, 4);
    expect(result.events, hasLength(4));
    expect(result.events.every((e) => e is Moved && e.blockId == 'a'), isTrue);
  });

  test('repeat expands its body', () {
    final result = runProgram(
      const Program([
        Repeat(2, [Move(), Move()], blockId: 'r'),
      ]),
      corridor,
    );
    expect(result.succeeded, isTrue);
    expect(result.steps, 4);
  });

  test('turns change facing and are reported', () {
    final l = level(['S#', '.G'], facing: Direction.south);
    final result = runProgram(const Program([Move(), TurnLeft(), Move()]), l);
    expect(result.succeeded, isTrue);
    final turn = result.events.whereType<Turned>().single;
    expect((turn.from, turn.to), (Direction.south, Direction.east));
  });

  test('bumping into a wall or the edge stops the run', () {
    final wall = runProgram(const Program([Move(steps: 2)]), level(['S#G']));
    expect(wall.outcome, RunOutcome.bumped);
    expect(wall.events.single, isA<Bumped>());
    expect(wall.position, const GridPoint(0, 0));

    final edge = runProgram(const Program([TurnLeft(), Move()]), corridor);
    expect(edge.outcome, RunOutcome.bumped);
  });

  test('ending away from the goal is stoppedShort', () {
    final result = runProgram(const Program([Move()]), corridor);
    expect(result.outcome, RunOutcome.stoppedShort);
  });

  test('stars must be collected before the goal counts', () {
    final l = level(['*S.G'], facing: Direction.west);
    final skipped = runProgram(
      const Program([TurnLeft(), TurnLeft(), Move(steps: 2)]),
      l,
    );
    expect(skipped.outcome, RunOutcome.missedStars);

    final collected = runProgram(
      const Program([Move(), TurnRight(), TurnRight(), Move(steps: 3)]),
      l,
    );
    expect(collected.outcome, RunOutcome.success);
    expect(collected.starsCollected, 1);
    expect(collected.events.whereType<Collected>(), hasLength(1));
  });

  test('step limit stops runaway programs', () {
    final spin = runProgram(
      const Program([
        Repeat(9, [
          Repeat(9, [
            Repeat(9, [TurnLeft()]),
          ]),
        ]),
      ]),
      corridor,
      stepLimit: 100,
    );
    expect(spin.outcome, RunOutcome.tooManySteps);
    expect(spin.events, hasLength(100));
  });

  test('is deterministic', () {
    const program = Program([
      Repeat(3, [Move()]),
      Move(),
    ]);
    final a = runProgram(program, corridor);
    final b = runProgram(program, corridor);
    expect(a.outcome, b.outcome);
    expect(a.steps, b.steps);
    expect(a.events.length, b.events.length);
  });
}
