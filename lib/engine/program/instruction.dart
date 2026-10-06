/// The shared instruction set. Every editor (picture blocks, typed
/// code) compiles to these, and only these are executed by the interpreter.
enum InstructionKind {
  move,
  turnLeft,
  turnRight,
  repeat,
  call,
  ifPathClear,
  setSteps,
  moveSteps,
  untilGoal,
}

sealed class Instruction {
  const Instruction({this.blockId});

  /// The editor block this came from, so a running block can be highlighted.
  final String? blockId;

  InstructionKind get kind;

  /// Blocks this instruction occupies in the editor, including nested ones.
  int get blockCount => 1;
}

final class Move extends Instruction {
  const Move({this.steps = 1, super.blockId});

  final int steps;

  @override
  InstructionKind get kind => InstructionKind.move;
}

/// Saves a number in the child's Step Box for later moves in this run.
final class SetSteps extends Instruction {
  const SetSteps(this.value, {super.blockId});
  final int value;

  @override
  InstructionKind get kind => InstructionKind.setSteps;
}

/// Reads the current Step Box value and moves that many cells.
final class MoveSteps extends Instruction {
  const MoveSteps({super.blockId});

  @override
  InstructionKind get kind => InstructionKind.moveSteps;
}

final class TurnLeft extends Instruction {
  const TurnLeft({super.blockId});

  @override
  InstructionKind get kind => InstructionKind.turnLeft;
}

final class TurnRight extends Instruction {
  const TurnRight({super.blockId});

  @override
  InstructionKind get kind => InstructionKind.turnRight;
}

final class Repeat extends Instruction {
  const Repeat(this.times, this.body, {super.blockId});

  final int times;
  final List<Instruction> body;

  @override
  InstructionKind get kind => InstructionKind.repeat;

  @override
  int get blockCount =>
      1 + body.fold(0, (sum, instruction) => sum + instruction.blockCount);
}

/// Runs the program's [Program.procedure]: the child's own block (shown as a
/// star). The procedure itself may not contain a call.
final class Call extends Instruction {
  const Call({super.blockId});

  @override
  InstructionKind get kind => InstructionKind.call;
}

/// Checks the cell directly ahead once. Runs [body] only when it is open.
final class IfPathClear extends Instruction {
  const IfPathClear(this.body, {super.blockId});

  final List<Instruction> body;

  @override
  InstructionKind get kind => InstructionKind.ifPathClear;

  @override
  int get blockCount =>
      1 + body.fold(0, (sum, instruction) => sum + instruction.blockCount);
}

/// Repeats [body] until the friend reaches the flag, with no count: the run
/// ends there, or on a bump, or at the step limit if it never gets there.
/// Each round counts as one step, so a loop that only turns still stops.
final class RepeatUntilGoal extends Instruction {
  const RepeatUntilGoal(this.body, {super.blockId});

  final List<Instruction> body;

  @override
  InstructionKind get kind => InstructionKind.untilGoal;

  @override
  int get blockCount =>
      1 + body.fold(0, (sum, instruction) => sum + instruction.blockCount);
}
