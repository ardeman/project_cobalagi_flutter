import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final level = Level.fromRows(
    id: 't',
    concept: 'loops',
    rows: ['S...G'],
    startFacing: Direction.east,
    palette: {InstructionKind.move, InstructionKind.repeat},
    maxBlocks: 3,
  );

  test('a valid program has no issues', () {
    expect(
      validateProgram(
        const Program([
          Repeat(4, [Move()]),
        ]),
        level,
      ),
      isEmpty,
    );
  });

  test('reports block limit, palette, empty repeat and bad counts', () {
    final issues = validateProgram(
      const Program([
        TurnLeft(blockId: 'turn'),
        Repeat(0, [], blockId: 'loop'),
        Move(steps: 12, blockId: 'move'),
        Move(),
      ]),
      level,
    );
    expect(issues.whereType<TooManyBlocks>().single.count, 4);
    expect(issues.whereType<DisallowedInstruction>().single.blockId, 'turn');
    expect(issues.whereType<EmptyRepeat>().single.blockId, 'loop');
    expect(issues.whereType<CountOutOfRange>().map((i) => i.blockId), [
      'loop',
      'move',
    ]);
  });

  test('block count includes nested blocks', () {
    expect(
      const Program([
        Move(),
        Repeat(2, [
          Move(),
          Repeat(2, [TurnLeft()]),
        ]),
      ]).blockCount,
      5,
    );
  });
}
