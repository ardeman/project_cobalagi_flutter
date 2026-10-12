import 'package:cobalagi/engine/generator/off_track.dart';
import 'package:cobalagi/engine/generator/solver.dart';
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

List<String> offTrack(Level l, List<Instruction> body) =>
    offTrackBlocks(l, Program(body));

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
      isEmpty,
    );
  });

  test('finds the turn the wrong way', () {
    expect(
      offTrack(corner, const [
        Move(blockId: 'a'),
        TurnLeft(blockId: 'b'),
        Move(blockId: 'c'),
      ]),
      ['b'],
    );
  });

  test('finds the move into a rock', () {
    expect(offTrack(corner, const [Move(blockId: 'a'), Move(blockId: 'b')]), [
      'b',
    ]);
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
      // Both turns are wrong: the finish is straight ahead.
      ['a', 'b'],
    );
  });

  test('a loop block is found when one of its rounds goes wrong', () {
    // The first round's move is right; the second walks into the rock.
    expect(
      offTrack(corner, const [
        Repeat(3, [Move(blockId: 'move')], blockId: 'loop'),
      ]),
      ['move'],
    );
  });

  test('passing the finish by a star is off track, not just short', () {
    // The star is behind the robot: going straight to the finish misses it.
    final starry = level(['*S.G']);
    expect(offTrack(starry, const [Move(blockId: 'a')]), ['a']);
  });

  test('finds every wrong block, judging each from the right spot', () {
    // S . #
    // # . #
    // # . G : a wrong turn first, then right moves, then a wrong move.
    expect(
      offTrack(corner, const [
        TurnLeft(blockId: 'wrong-turn'),
        Move(blockId: 'a'),
        TurnRight(blockId: 'b'),
        Move(blockId: 'c'),
        Move(blockId: 'd'),
        Move(blockId: 'wrong-move'),
      ]),
      ['wrong-turn', 'wrong-move'],
    );
  });

  test('every step of any shortest answer is on track', () {
    final l = level(['S..', '...', '..G']);
    // Down first or right first: both are shortest.
    for (final body in const [
      [Move(), Move(), TurnRight(), Move(), Move()],
      [TurnRight(), Move(), Move(), TurnLeft(), Move(), Move()],
    ]) {
      expect(offTrack(l, body), isEmpty);
    }
    expect(stepsToFinish(l, l.start, Direction.east, const {}), 5);
  });

  group('loop shapes', () {
    // functions-01: S at the bottom left facing east, the flag at the top
    // right; the answer is three magic blocks of forward, left, forward,
    // right.
    final stairs = level(['######', '####G#', '###..#', '##..##', '#S.###']);
    const right = [
      Move(blockId: 'm1'),
      TurnLeft(blockId: 'l'),
      Move(blockId: 'm2'),
      TurnRight(blockId: 'r'),
    ];

    test('a magic block with one step too many: that step', () {
      // The screenshot: the magic block walks the route the first time and
      // only goes astray the second, so step by step blames the first step.
      const program = Program(
        [Call(blockId: 's1'), Call(blockId: 's2')],
        procedure: [
          ...right,
          Move(blockId: 'extra'),
        ],
      );
      expect(offTrackBlocks(stairs, program), ['m1']);
      expect(loopShapeMistakes(stairs, program), ['extra']);
    });

    test('a right magic block with too few stars has nothing to ring', () {
      const program = Program([
        Call(blockId: 's1'),
        Call(blockId: 's2'),
      ], procedure: right);
      expect(loopShapeMistakes(stairs, program), isEmpty);
    });

    test('another right way to repeat counts as right', () {
      // Forward first, then the loop starting with the turn.
      const program = Program(
        [
          Move(blockId: 'a'),
          Call(blockId: 's1'),
          Call(blockId: 's2'),
          TurnLeft(blockId: 'b'),
          Move(blockId: 'c'),
        ],
        procedure: [
          TurnLeft(blockId: 'l'),
          Move(blockId: 'm1'),
          TurnRight(blockId: 'r'),
          Move(blockId: 'm2'),
        ],
      );
      expect(loopShapeMistakes(stairs, program), isEmpty);
    });

    test('a turn the wrong way inside a loop, and a wrong count', () {
      const program = Program([
        Repeat(2, [
          Move(blockId: 'm1'),
          TurnRight(blockId: 'wrong-turn'),
          Move(blockId: 'm2'),
          TurnRight(blockId: 'r'),
        ], blockId: 'loop'),
      ]);
      expect(loopShapeMistakes(stairs, program), ['loop', 'wrong-turn']);
    });

    test('programs without a loop are judged step by step', () {
      expect(
        loopShapeMistakes(stairs, const Program([Move(blockId: 'a')])),
        isNull,
      );
    });
  });
}
