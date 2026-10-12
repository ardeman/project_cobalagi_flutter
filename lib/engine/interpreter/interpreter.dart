import '../program/instruction.dart';
import '../program/program.dart';
import '../world/direction.dart';
import '../world/grid_point.dart';
import '../world/level.dart';
import 'run_event.dart';

/// Each single-cell move, turn, path check, value save and round of a
/// repeat-until counts as one step.
const defaultStepLimit = 1000;

/// How deep calls may nest before the run stops, so a procedure that calls
/// itself ends instead of hanging. Validation already reports such programs.
const maxCallDepth = 8;

/// Asked before each move and turn when given to [runProgram], about the
/// step from [at] facing [facing] (with the stars in [collected]) to [next]
/// facing [nextFacing]: returns the facing to end up with, or null to skip
/// the step (nothing moves, no event, and the run goes on). For a move, any
/// facing lets it happen; a move into a rock is always skipped, never a
/// bump. For a turn, it may give another facing to turn to instead.
typedef StepCheck =
    Direction? Function(
      GridPoint at,
      Direction facing,
      Set<GridPoint> collected,
      GridPoint next,
      Direction nextFacing,
      String? blockId,
    );

/// Runs [program] on [level] and returns every event plus the outcome.
///
/// Deterministic: the same program and level always give the same result. The
/// run stops as soon as the goal is reached with all stars, on a bump, or at
/// [stepLimit]. With [check], steps it refuses are skipped (see [StepCheck]).
RunResult runProgram(
  Program program,
  Level level, {
  int stepLimit = defaultStepLimit,
  StepCheck? check,
}) {
  final run = _Run(level, stepLimit, program.procedure, check);
  RunOutcome outcome;
  try {
    run.execute(program.body);
    outcome = run.position != level.goal
        ? RunOutcome.stoppedShort
        : RunOutcome.missedStars;
  } on _Halt catch (halt) {
    outcome = halt.outcome;
  }
  // A program that starts on a solved level (no moves needed) still succeeds.
  if (outcome != RunOutcome.bumped &&
      outcome != RunOutcome.tooManySteps &&
      run.isSolved) {
    outcome = RunOutcome.success;
  }
  return RunResult(
    outcome: outcome,
    events: List.unmodifiable(run.events),
    position: run.position,
    facing: run.facing,
    starsCollected: run.collected.length,
    steps: run.steps,
  );
}

final class _Halt implements Exception {
  const _Halt(this.outcome);

  final RunOutcome outcome;
}

final class _Run {
  _Run(this.level, this.stepLimit, this.procedure, this.check)
    : position = level.start,
      facing = level.startFacing;

  final Level level;
  final int stepLimit;
  final List<Instruction> procedure;
  final StepCheck? check;
  var _depth = 0;
  final events = <RunEvent>[];
  final collected = <GridPoint>{};
  GridPoint position;
  Direction facing;
  var steps = 0;
  int? _storedSteps;

  bool get isSolved =>
      position == level.goal && collected.length == level.stars.length;

  void execute(List<Instruction> body) {
    for (final instruction in body) {
      switch (instruction) {
        case SetSteps(:final value):
          _tick();
          _storedSteps = value;
          events.add(StepsStored(value, instruction.blockId));
        case MoveSteps():
          final value = _storedSteps;
          // Validation reports this before running; direct engine callers
          // also stop safely if a value has not been saved.
          if (value == null) throw const _Halt(RunOutcome.stoppedShort);
          for (var i = 0; i < value; i++) {
            _step(instruction);
          }
        case Move(:final steps):
          for (var i = 0; i < steps; i++) {
            _step(instruction);
          }
        case TurnLeft():
          _turn(facing.left, instruction);
        case TurnRight():
          _turn(facing.right, instruction);
        case Repeat(:final times, :final body):
          for (var i = 0; i < times; i++) {
            execute(body);
          }
        case Call():
          if (++_depth > maxCallDepth) {
            throw const _Halt(RunOutcome.tooManySteps);
          }
          execute(procedure);
          _depth--;
        case RepeatUntilGoal(:final body):
          // Stops by ending the run: on the flag, on a bump, or at the limit.
          while (true) {
            _tick();
            execute(body);
          }
        case IfPathClear(:final body):
          _tick();
          final ahead = position.step(facing);
          final clear = level.isOpen(ahead);
          events.add(PathChecked(ahead, clear, instruction.blockId));
          if (clear) execute(body);
        case IfElsePathClear(:final body, :final otherwise):
          _tick();
          final ahead = position.step(facing);
          final clear = level.isOpen(ahead);
          events.add(PathChecked(ahead, clear, instruction.blockId));
          execute(clear ? body : otherwise);
      }
    }
  }

  void _tick() {
    if (++steps > stepLimit) throw const _Halt(RunOutcome.tooManySteps);
  }

  void _step(Instruction source) {
    _tick();
    final next = position.step(facing);
    if (check case final check?) {
      final open = level.isOpen(next);
      final allowed = check(
        position,
        facing,
        collected,
        open ? next : position,
        facing,
        source.blockId,
      );
      if (!open || allowed == null) return;
    }
    if (!level.isOpen(next)) {
      events.add(Bumped(position, facing, source.blockId));
      throw const _Halt(RunOutcome.bumped);
    }
    events.add(Moved(position, next, source.blockId));
    position = next;
    if (level.stars.contains(next) && collected.add(next)) {
      events.add(Collected(next, source.blockId));
    }
    if (isSolved) throw const _Halt(RunOutcome.success);
  }

  void _turn(Direction to, Instruction source) {
    _tick();
    if (check case final check?) {
      final turned = check(
        position,
        facing,
        collected,
        position,
        to,
        source.blockId,
      );
      if (turned == null) return;
      to = turned;
    }
    events.add(Turned(facing, to, source.blockId));
    facing = to;
  }
}
