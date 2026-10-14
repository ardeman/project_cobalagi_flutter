import 'package:cobalagi/engine/generator/route_pattern.dart';
import 'package:cobalagi/engine/generator/solver.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';
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
    // The arrows follow the road: steps the way Koba moves, a turn from the
    // way Koba faced before it.
    expect(
      [for (final m in marks) m.heading],
      [Direction.east, Direction.east, Direction.east, Direction.north],
    );
    // The trail shows the way: the start tile, then each tile walked into.
    expect(hintTrail(level, solve(level)!), [
      Vector2(0.5, 1.5),
      Vector2(1.5, 1.5),
      Vector2(2.5, 1.5),
      Vector2(2.5, 0.5),
    ]);
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
    // The Step Box badge sits on each "use steps" mark, as on its block.
    expect(marks.first.badge?.color, BlockType.setSteps.color);
    expect(marks[1].badge, isNull);
    // In the middle of the two-step stretch, off the character's tile.
    expect(marks.first.at, Vector2(1.5, 1.5));
  });

  group('findPattern', () {
    // The shape's length, then where each round starts.
    List<Object>? pattern(RoutePattern? p) =>
        p == null ? null : [p.unit, p.rounds];

    const m = InstructionKind.move;
    const l = InstructionKind.turnLeft;
    const r = InstructionKind.turnRight;

    test('a corridor repeats one step', () {
      expect(pattern(findPattern([m, m, m, m, m])), [
        1,
        [0, 1, 2, 3, 4],
      ]);
    });

    test('stairs repeat their shape, a last part-round counts', () {
      expect(pattern(findPattern([m, l, m, r, m, l, m, r, m, l, m])), [
        4,
        [0, 4, 8],
      ]);
    });

    test('a lead-in comes before the repeating part', () {
      expect(pattern(findPattern([m, m, r, m, l, m, l, m, l, m, l])), [
        2,
        [3, 5, 7, 9],
      ]);
    });

    // functions-05: the third round has one more forward first.
    final extraStep = [m, m, m, r, m, l, m, m, m, r, m, l, m, m, m, m, r, m];

    test('a part round only counts on the flag', () {
      expect(pattern(findPattern(extraStep)), [
        6,
        [0, 6],
      ]);
    });

    test('the Magic Block can have a block between its rounds', () {
      expect(pattern(findPattern(extraStep, gaps: true)), [
        6,
        [0, 6, 13],
      ]);
    });

    test('until the flag must reach the flag', () {
      expect(findPattern([m, l, m, l, r], toEnd: true), isNull);
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

  test('blocks inside the loop are ringed; blocks around it are not', () {
    final level = Level.fromRows(
      id: 'r',
      concept: 'loops',
      rows: ['#######', '#....G#', '#S....#', '#######'],
      startFacing: Direction.north,
      palette: const {
        InstructionKind.move,
        InstructionKind.turnLeft,
        InstructionKind.turnRight,
        InstructionKind.repeat,
      },
    );
    // Turn, four steps (the loop), then turn and one more step.
    final marks = patternHintMarks(
      level,
      const Program([
        TurnRight(),
        Move(),
        Move(),
        Move(),
        Move(),
        TurnLeft(),
        Move(),
      ]),
    )!.where((m) => !m.big).toList();
    expect(marks, hasLength(7));
    final purple = BlockType.repeat.color;
    expect(
      [for (final m in marks) m.loop],
      [
        null, purple, purple, purple, purple, null, null, //
      ],
    );
    // Only the loop's later rounds fade; the blocks after it are the
    // child's to place, so they stay bright.
    expect(
      [for (final m in marks) m.faded],
      [
        false, false, true, true, true, false, false, //
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
