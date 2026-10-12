import '../interpreter/run_event.dart';
import '../world/grid_point.dart';
import '../world/level.dart';
import 'solver.dart';

/// The first block in [result]'s run that took the robot no closer to the
/// finish (with every star): a turn the wrong way, a move away, a walk into
/// a rock. Every step of some shortest answer brings the finish one step
/// nearer, so any right answer passes, not just one. Null when every step
/// was right, so the program only needs more blocks.
///
/// Used by the hint to show the child which of their blocks to change.
String? firstOffTrackBlock(Level level, RunResult result) {
  var position = level.start;
  var facing = level.startFacing;
  final collected = <GridPoint>{if (level.stars.contains(position)) position};
  var steps = stepsToFinish(level, position, facing, collected);
  if (steps == null) return null;
  for (final event in result.events) {
    switch (event) {
      case Bumped():
        return event.blockId;
      case Moved(:final to):
        position = to;
        if (level.stars.contains(to)) collected.add(to);
      case Turned(:final to):
        facing = to;
      case Collected() || PathChecked() || StepsStored():
        continue;
    }
    final left = stepsToFinish(level, position, facing, collected);
    if (left == null || left >= steps!) return event.blockId;
    steps = left;
  }
  return null;
}
