import 'package:flame/components.dart';

import '../../../engine/generator/route_pattern.dart';
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

/// Turns [solution] into hint marks that look like the level's own blocks,
/// turned to follow the road: a step block between tiles, its arrow the way
/// Koba moves, and a turn block on the tile where it turns, its arrow
/// starting the way Koba faced. [hintTrail] draws the route under them.
///
/// Levels without a single-step block move with the Step Box: each straight
/// stretch becomes one "use steps" mark carrying its length.
///
/// With [lookFirst] (a level with several boards, where counting steps
/// can't work) every step wears the eye block's badge: look, then step.
List<HintMark> hintMarks(
  Level level,
  Program solution, {
  String? labelFont,
  bool lookFirst = false,
}) {
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
          // The Step Box badge, as on the "use steps" block.
          badge: (
            icon: BlockType.setSteps.icon,
            color: BlockType.setSteps.color,
          ),
          label: '$length',
          labelFont: labelFont,
          heading: facing,
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
              badge: lookFirst
                  ? (
                      icon: BlockType.ifPathClear.icon,
                      color: BlockType.ifPathClear.color,
                    )
                  : null,
              heading: facing,
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
            heading: from,
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

/// The route [solution] walks, as tile centres from the start to where it
/// ends: the dotted trail that shows which way the hint's blocks go.
List<Vector2> hintTrail(Level level, Program solution) => [
  Vector2(level.start.x + 0.5, level.start.y + 0.5),
  for (final event in runProgram(solution, level).events)
    if (event case Moved(:final to)) Vector2(to.x + 0.5, to.y + 0.5),
];

/// The second hint on islands with a loop block: the route's repeating
/// shape. Blocks inside the loop are ringed in the loop block's colour;
/// its first round is bright, later rounds fade, blocks before and after
/// it look as usual, and the island's
/// loop block (repeat, Magic Block star or until the flag) sits above the
/// first round with how many times it runs. Null when the level has no loop
/// block or the route has no repeating shape.
List<HintMark>? patternHintMarks(
  Level level,
  Program solution, {
  String? labelFont,
}) {
  final loop = level.palette.contains(InstructionKind.untilGoal)
      ? BlockType.untilGoal
      : level.palette.contains(InstructionKind.call)
      ? BlockType.star
      : level.palette.contains(InstructionKind.repeat)
      ? BlockType.repeat
      : null;
  if (loop == null) return null;
  // One mark per straight-line step, in order.
  final steps = [for (final i in solution.body) i.kind];
  final route = hintMarks(level, solution, labelFont: labelFont);
  if (route.length != steps.length) return null;
  final pattern = findPattern(
    steps,
    gaps: loop == BlockType.star,
    toEnd: loop == BlockType.untilGoal,
  );
  if (pattern == null) return null;
  final (:unit, :rounds) = pattern;
  final end = rounds.first + unit;
  // Which round each step is in; steps outside every round are the child's
  // to place, before, between (Magic Block) or after them.
  int? roundOf(int i) {
    for (var r = 0; r < rounds.length; r++) {
      if (i >= rounds[r] && i < rounds[r] + unit) return r;
    }
    return null;
  }

  final first = route[rounds.first].at;
  final marks = [
    for (var i = 0; i < route.length; i++)
      HintMark(
        at: route[i].at,
        icon: route[i].icon,
        color: route[i].color,
        badge: route[i].badge,
        label: route[i].label,
        labelFont: labelFont,
        heading: route[i].heading,
        // Blocks inside the loop are ringed in its colour; its later rounds
        // fade, because the loop does them. Blocks outside it stay as they
        // are: the child places those.
        loop: roundOf(i) != null ? loop.color : null,
        faded: (roundOf(i) ?? 0) > 0,
      ),
  ];
  // Pops in right after the first round: these blocks, again and again.
  marks.insert(
    end,
    HintMark(
      at: _besidePath(level, first),
      icon: loop.icon,
      color: loop.color,
      // Until the flag needs no count.
      label: loop == BlockType.untilGoal ? null : '${rounds.length}',
      labelFont: labelFont,
      big: true,
    ),
  );
  return marks;
}

/// A spot next to [near] on a wall tile, where no hint mark sits, for the
/// loop block; above it if nothing nearby is a wall.
Vector2 _besidePath(Level level, Vector2 near) {
  for (final (dx, dy) in [
    (0.0, -1.0), (-1.0, 0.0), (1.0, 0.0), (0.0, 1.0), //
    (-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0),
  ]) {
    final spot = Vector2(near.x + dx, near.y + dy);
    final tile = GridPoint(spot.x.floor(), spot.y.floor());
    // The tile's centre, so the badge sits squarely on the wall.
    if (level.contains(tile) && !level.isOpen(tile)) {
      return Vector2(tile.x + 0.5, tile.y + 0.5);
    }
  }
  return Vector2(near.x, near.y - 0.75);
}
