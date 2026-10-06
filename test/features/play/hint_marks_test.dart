import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/play/view/hint_marks.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Two steps east, a left turn, one step north.
  const rows = ['##G#', 'S..#'];

  test('steps and turns look like their blocks, in running order', () {
    final level = Level.fromRows(
      id: 'h',
      concept: 'sequencing',
      rows: rows,
      startFacing: Direction.east,
      palette: const {
        InstructionKind.move,
        InstructionKind.turnLeft,
        InstructionKind.turnRight,
      },
    );
    final marks = hintMarks(level, solve(level)!);
    expect(
      [for (final m in marks) m.color],
      [
        BlockType.forward.color,
        BlockType.forward.color,
        BlockType.turnLeft.color,
        BlockType.forward.color,
      ],
    );
    expect(marks.first.icon, BlockType.forward.icon);
    expect(marks[2].icon, BlockType.turnLeft.icon);
    // Steps sit between tiles; the turn sits on the tile where it happens.
    expect(marks.first.at, Vector2(1, 1.5));
    expect(marks[2].at, Vector2(2.5, 1.5));
    expect(marks.every((m) => m.label == null), isTrue);
  });

  test('Step Box levels show each straight stretch once, with its length', () {
    final level = Level.fromRows(
      id: 'h',
      concept: 'variables',
      rows: rows,
      startFacing: Direction.east,
      palette: const {
        InstructionKind.setSteps,
        InstructionKind.moveSteps,
        InstructionKind.turnLeft,
      },
    );
    final marks = hintMarks(level, solve(level)!, labelFont: 'Roboto');
    expect(
      [for (final m in marks) m.color],
      [
        BlockType.moveSteps.color,
        BlockType.turnLeft.color,
        BlockType.moveSteps.color,
      ],
    );
    expect([for (final m in marks) m.label], ['2', null, '1']);
    expect(marks.first.labelFont, 'Roboto');
    // In the middle of the two-step stretch, off the character's tile.
    expect(marks.first.at, Vector2(1.5, 1.5));
  });
}
