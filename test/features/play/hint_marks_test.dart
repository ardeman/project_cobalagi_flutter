import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/grid_point.dart';
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

  group('findPattern', () {
    const m = InstructionKind.move;
    const l = InstructionKind.turnLeft;
    const r = InstructionKind.turnRight;

    test('a corridor repeats one step', () {
      expect(findPattern([m, m, m, m, m]), (start: 0, unit: 1, times: 5));
    });

    test('stairs repeat their shape, a last part-round counts', () {
      expect(findPattern([m, l, m, r, m, l, m, r, m, l, m]), (
        start: 0,
        unit: 4,
        times: 3,
      ));
    });

    test('a lead-in comes before the repeating part', () {
      expect(findPattern([m, m, r, m, l, m, l, m, l, m, l]), (
        start: 3,
        unit: 2,
        times: 4,
      ));
    });

    test('nothing repeats', () {
      expect(findPattern([m, l, r]), isNull);
      expect(findPattern([]), isNull);
    });
  });

  test('the pattern hint shows one bright round and the repeat block', () {
    final level = Level.fromRows(
      id: 'p',
      concept: 'loops',
      rows: ['########', '#S....G#', '########'],
      startFacing: Direction.east,
      palette: const {InstructionKind.move, InstructionKind.repeat},
    );
    final marks = patternHintMarks(level, solve(level)!)!;
    // Five steps plus the repeat block, which comes after the first round.
    expect(marks, hasLength(6));
    expect(marks[1].icon, BlockType.repeat.icon);
    expect(marks[1].big, isTrue);
    expect(marks[1].label, '5');
    // On a wall tile beside the path, not over another mark.
    final at = marks[1].at;
    expect(level.isOpen(GridPoint(at.x.floor(), at.y.floor())), isFalse);
    expect(
      [for (final m in marks) m.faded],
      [
        false, false, true, true, true, true, //
      ],
    );
  });

  test('until the flag shows its block without a count', () {
    final level = Level.fromRows(
      id: 'u',
      concept: 'until',
      rows: ['######', '#S..G#', '######'],
      startFacing: Direction.east,
      palette: const {InstructionKind.move, InstructionKind.untilGoal},
    );
    final loop = patternHintMarks(
      level,
      solve(level)!,
    )!.firstWhere((m) => m.big);
    expect(loop.icon, BlockType.untilGoal.icon);
    expect(loop.label, isNull);
  });

  test('no pattern hint without a loop block or a repeating shape', () {
    final plain = Level.fromRows(
      id: 'n',
      concept: 'sequencing',
      rows: ['#####', '#S.G#', '#####'],
      startFacing: Direction.east,
      palette: const {InstructionKind.move},
    );
    expect(patternHintMarks(plain, solve(plain)!), isNull);
    final noShape = Level.fromRows(
      id: 'n2',
      concept: 'loops',
      rows: ['####', '#SG#', '####'],
      startFacing: Direction.east,
      palette: const {InstructionKind.move, InstructionKind.repeat},
    );
    expect(patternHintMarks(noShape, solve(noShape)!), isNull);
  });
}
