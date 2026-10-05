/// The shared instruction set. Every editor (icon blocks, word blocks, typed
/// code) compiles to these, and only these are executed by the interpreter.
enum InstructionKind { move, turnLeft, turnRight, repeat }

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
