import 'package:cobalagi/engine/generator/off_track.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/interpreter/interpreter.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
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

String? offTrack(Level l, List<Instruction> body) =>
    firstOffTrackBlock(l, runProgram(Program(body), l));

void main() {
  // S . #
  // # . #
  // # . G
  final corner = level(['S.#', '#.#', '#.G']);

  test('a program that only needs more blocks has none off track', () {
    expect(
      offTrack(corner, const [
        Move(blockId: 'a'),
        TurnRight(blockId: 'b'),
        Move(blockId: 'c'),
      ]),
      isNull,
    );
  });

  test('finds the turn the wrong way', () {
    expect(
      offTrack(corner, const [
        Move(blockId: 'a'),
        TurnLeft(blockId: 'b'),
        Move(blockId: 'c'),
      ]),
      'b',
    );
  });

  test('finds the move into a rock', () {
    expect(
      offTrack(corner, const [Move(blockId: 'a'), Move(blockId: 'b')]),
      'b',
    );
  });

  test('finds a move away from the finish', () {
    // S . . G, facing east: turning round and moving is away.
    final line = level(['.S..G']);
    expect(
      offTrack(line, const [
        TurnLeft(blockId: 'a'),
        TurnLeft(blockId: 'b'),
        Move(blockId: 'c'),
      ]),
      'a',
    );
  });

  test('a loop block is found when one of its rounds goes wrong', () {
    // The first round's move is right; the second walks into the rock.
    expect(
      offTrack(corner, const [
        Repeat(3, [Move(blockId: 'move')], blockId: 'loop'),
      ]),
      'move',
    );
  });

  test('passing the finish by a star is off track, not just short', () {
    // The star is behind the robot: going straight to the finish misses it.
    final starry = level(['*S.G']);
    expect(offTrack(starry, const [Move(blockId: 'a')]), 'a');
  });

  test('every step of any shortest answer is on track', () {
    final l = level(['S..', '...', '..G']);
    // Down first or right first: both are shortest.
    for (final body in const [
      [Move(), Move(), TurnRight(), Move(), Move()],
      [TurnRight(), Move(), Move(), TurnLeft(), Move(), Move()],
    ]) {
      expect(offTrack(l, body), isNull);
    }
    expect(stepsToFinish(l, l.start, Direction.east, const {}), 5);
  });
}
