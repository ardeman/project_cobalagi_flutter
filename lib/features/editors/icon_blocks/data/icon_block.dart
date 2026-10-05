import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/program.dart';

/// Tier 1 blocks: icons only, one step per block.
enum IconBlockType {
  forward(InstructionKind.move),
  turnLeft(InstructionKind.turnLeft),
  turnRight(InstructionKind.turnRight),
  repeat(InstructionKind.repeat);

  const IconBlockType(this.kind);

  final InstructionKind kind;
}

final class IconBlock {
  const IconBlock({
    required this.id,
    required this.type,
    this.count = 2,
    this.children = const [],
  });

  final String id;
  final IconBlockType type;

  /// Repeat count; ignored by other block types.
  final int count;
  final List<IconBlock> children;
}

/// Compiles the editor's blocks into the shared instruction set.
Program compileIconBlocks(List<IconBlock> blocks) =>
    Program([for (final block in blocks) _compile(block)]);

Instruction _compile(IconBlock block) => switch (block.type) {
  IconBlockType.forward => Move(blockId: block.id),
  IconBlockType.turnLeft => TurnLeft(blockId: block.id),
  IconBlockType.turnRight => TurnRight(blockId: block.id),
  IconBlockType.repeat => Repeat(block.count, [
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
};
