import '../world/level.dart';
import 'instruction.dart';
import 'program.dart';

/// Something an editor should point out before running a program.
sealed class ProgramIssue {
  const ProgramIssue(this.blockId);

  final String? blockId;
}

final class DisallowedInstruction extends ProgramIssue {
  const DisallowedInstruction(this.kind, super.blockId);

  final InstructionKind kind;
}

final class TooManyBlocks extends ProgramIssue {
  const TooManyBlocks(this.count, this.max) : super(null);

  final int count;
  final int max;
}

final class EmptyRepeat extends ProgramIssue {
  const EmptyRepeat(super.blockId);
}

final class EmptyCondition extends ProgramIssue {
  const EmptyCondition(super.blockId);
}

/// A call to the child's own block while that block is still empty.
final class EmptyProcedure extends ProgramIssue {
  const EmptyProcedure(super.blockId);
}

/// The child's own block calls itself.
final class CallInProcedure extends ProgramIssue {
  const CallInProcedure(super.blockId);
}

final class CountOutOfRange extends ProgramIssue {
  const CountOutOfRange(this.value, super.blockId);

  final int value;
}

/// Smallest and largest number a block may carry (move steps, repeat times).
const minCount = 1;
const maxCount = 9;

List<ProgramIssue> validateProgram(Program program, Level level) {
  final issues = <ProgramIssue>[];
  final max = level.maxBlocks;
  if (max != null && program.blockCount > max) {
    issues.add(TooManyBlocks(program.blockCount, max));
  }

  void visit(List<Instruction> body, {bool inProcedure = false}) {
    for (final instruction in body) {
      if (!level.palette.contains(instruction.kind)) {
        issues.add(
          DisallowedInstruction(instruction.kind, instruction.blockId),
        );
      }
      switch (instruction) {
        case Move(:final steps) when steps < minCount || steps > maxCount:
          issues.add(CountOutOfRange(steps, instruction.blockId));
        case Repeat(:final times, :final body):
          if (times < minCount || times > maxCount) {
            issues.add(CountOutOfRange(times, instruction.blockId));
          }
          if (body.isEmpty) issues.add(EmptyRepeat(instruction.blockId));
          visit(body, inProcedure: inProcedure);
        case IfPathClear(:final body):
          if (body.isEmpty) issues.add(EmptyCondition(instruction.blockId));
          visit(body, inProcedure: inProcedure);
        case Call() when inProcedure:
          issues.add(CallInProcedure(instruction.blockId));
        case Call() when program.procedure.isEmpty:
          issues.add(EmptyProcedure(instruction.blockId));
        case Call() || Move() || TurnLeft() || TurnRight():
          break;
      }
    }
  }

  visit(program.body);
  visit(program.procedure, inProcedure: true);
  return issues;
}
