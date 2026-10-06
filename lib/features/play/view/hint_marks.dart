import 'dart:math';

import 'package:flame/components.dart';

import '../../../engine/interpreter/interpreter.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../engine/program/instruction.dart';
import '../../../engine/program/program.dart';
import '../../../engine/world/direction.dart';
import '../../../engine/world/grid_point.dart';
import '../../../engine/world/level.dart';
import '../../editors/blocks/data/block.dart';
import '../../editors/blocks/view/block_tile.dart';
import 'world/hint_mark.dart';

/// Turns [solution] into hint marks that look like the level's own blocks:
/// a step arrow between tiles in the moving block's colour, pointing the way
/// the character walks, and a turn badge on the tile where it turns.
///
/// Levels without a single-step block move with the Step Box: each straight
/// stretch becomes one "use steps" mark carrying its length.
List<HintMark> hintMarks(Level level, Program solution, {String? labelFont}) {
  final stepBox =
      !level.palette.contains(InstructionKind.move) &&
      level.palette.contains(InstructionKind.moveSteps);
  final walk = stepBox ? BlockType.moveSteps : BlockType.forward;
  final marks = <HintMark>[];
  var at = level.start;
  // Turns already shown on each tile, so a second one sits beside the first.
  final turnsAt = <GridPoint, int>{};
  // The open Step Box stretch: where it starts, its direction and length.
  (GridPoint, Direction, int)? stretch;

  void closeStretch() {
    if (stretch case (final from, final facing, final length)) {
      marks.add(
        HintMark(
          // In the middle of the stretch, clear of the character.
          at: _between(from, _walk(from, facing, length)),
          icon: walk.icon,
          color: walk.color,
          angle: _arrowAngle(facing, walk),
          label: '$length',
          labelFont: labelFont,
        ),
      );
    }
    stretch = null;
  }

  for (final event in runProgram(solution, level).events) {
    switch (event) {
      case Moved(:final from, :final to):
        final facing = _direction(from, to);
        if (stepBox) {
          if (stretch case (final start, final f, final n) when f == facing) {
            stretch = (start, f, n + 1);
          } else {
            closeStretch();
            stretch = (from, facing, 1);
          }
        } else {
          marks.add(
            HintMark(
              at: _between(from, to),
              icon: walk.icon,
              color: walk.color,
              angle: _arrowAngle(facing, walk),
            ),
          );
        }
        at = to;
      case Turned(:final from, :final to):
        closeStretch();
        final turn = to == from.left ? BlockType.turnLeft : BlockType.turnRight;
        final k = turnsAt[at] = (turnsAt[at] ?? 0) + 1;
        marks.add(
          HintMark(
            at: Vector2(at.x + 0.5 + (k - 1) * 0.3, at.y + 0.5),
            icon: turn.icon,
            color: turn.color,
          ),
        );
      default:
        break;
    }
  }
  closeStretch();
  return marks;
}

Vector2 _between(GridPoint a, GridPoint b) =>
    Vector2((a.x + b.x) / 2 + 0.5, (a.y + b.y) / 2 + 0.5);

GridPoint _walk(GridPoint from, Direction facing, int steps) {
  var at = from;
  for (var i = 0; i < steps; i++) {
    at = at.step(facing);
  }
  return at;
}

Direction _direction(GridPoint from, GridPoint to) =>
    Direction.values.firstWhere((d) => from.step(d) == to);

/// The forward block's arrow points up, the Step Box's to the right; both
/// turn to point the way the character walks.
double _arrowAngle(Direction facing, BlockType walk) =>
    facing.index * pi / 2 - (walk == BlockType.moveSteps ? pi / 2 : 0);
