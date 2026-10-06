import '../world/direction.dart';
import '../world/grid_point.dart';

/// One visible step of a run, replayed by the game world as an animation.
sealed class RunEvent {
  const RunEvent(this.blockId);

  /// The editor block that caused this event.
  final String? blockId;
}

final class Moved extends RunEvent {
  const Moved(this.from, this.to, super.blockId);

  final GridPoint from;
  final GridPoint to;
}

final class Turned extends RunEvent {
  const Turned(this.from, this.to, super.blockId);

  final Direction from;
  final Direction to;
}

/// The actor tried to walk into a wall or off the grid. The run stops here.
final class Bumped extends RunEvent {
  const Bumped(this.at, this.facing, super.blockId);

  final GridPoint at;
  final Direction facing;
}

final class Collected extends RunEvent {
  const Collected(this.star, super.blockId);

  final GridPoint star;
}

/// The interpreter checked the path; the world only shows this result.
final class PathChecked extends RunEvent {
  const PathChecked(this.ahead, this.clear, super.blockId);

  final GridPoint ahead;
  final bool clear;
}

/// The interpreter saved a new value; editors and the world only display it.
final class StepsStored extends RunEvent {
  const StepsStored(this.value, super.blockId);
  final int value;
}

enum RunOutcome {
  /// Reached the goal with every star collected.
  success,

  /// Walked into a wall or off the grid.
  bumped,

  /// The program ended away from the goal.
  stoppedShort,

  /// The program ended on the goal but stars are left.
  missedStars,

  /// Exceeded the step limit.
  tooManySteps,
}

final class RunResult {
  const RunResult({
    required this.outcome,
    required this.events,
    required this.position,
    required this.facing,
    required this.starsCollected,
    required this.steps,
  });

  final RunOutcome outcome;
  final List<RunEvent> events;
  final GridPoint position;
  final Direction facing;
  final int starsCollected;
  final int steps;

  bool get succeeded => outcome == RunOutcome.success;
}
