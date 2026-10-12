import 'dart:collection';

import '../program/instruction.dart';
import '../program/program.dart';
import '../world/direction.dart';
import '../world/grid_point.dart';
import '../world/level.dart';

/// Finds a shortest straight-line solution (single moves and turns, no loops)
/// with breadth-first search, or returns null when [level] can't be solved.
///
/// Used to check generated puzzles and to give hints.
Program? solve(Level level) =>
    switch (_search(level, level.start, level.startFacing, const {})) {
      final path? => Program(path),
      null => null,
    };

/// The fewest single moves and turns from [position], facing [facing], with
/// the stars in [collected] already picked up, to the finish with every
/// star; null when it can't be reached from there.
int? stepsToFinish(
  Level level,
  GridPoint position,
  Direction facing,
  Set<GridPoint> collected,
) => _search(level, position, facing, collected)?.length;

List<Instruction>? _search(
  Level level,
  GridPoint position,
  Direction facing,
  Set<GridPoint> collected,
) {
  final stars = level.stars.toList();
  final allStars = (1 << stars.length) - 1;

  int starsAt(GridPoint p, int mask) {
    final i = stars.indexOf(p);
    return i < 0 ? mask : mask | (1 << i);
  }

  var startMask = 0;
  for (final star in collected) {
    startMask = starsAt(star, startMask);
  }
  final startState = (position, facing, starsAt(position, startMask));
  final parents = <_State, (_State, Instruction)?>{startState: null};
  final queue = Queue.of([startState]);

  while (queue.isNotEmpty) {
    final state = queue.removeFirst();
    final (position, facing, mask) = state;
    if (position == level.goal && mask == allStars) {
      return _path(state, parents);
    }
    final next = position.step(facing);
    for (final (successor, instruction) in [
      if (level.isOpen(next))
        ((next, facing, starsAt(next, mask)), const Move()),
      ((position, facing.left, mask), const TurnLeft()),
      ((position, facing.right, mask), const TurnRight()),
    ]) {
      if (parents.containsKey(successor)) continue;
      parents[successor] = (state, instruction);
      queue.add(successor);
    }
  }
  return null;
}

typedef _State = (GridPoint, Direction, int);

List<Instruction> _path(
  _State end,
  Map<_State, (_State, Instruction)?> parents,
) {
  final instructions = <Instruction>[];
  for (var link = parents[end]; link != null; link = parents[link.$1]) {
    instructions.add(link.$2);
  }
  return instructions.reversed.toList();
}
