import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/program.dart';

/// Block types of the block editor, one step per block, shown as pictures.
enum BlockType {
  forward(InstructionKind.move),
  turnLeft(InstructionKind.turnLeft),
  turnRight(InstructionKind.turnRight),
  repeat(InstructionKind.repeat),
  setSteps(InstructionKind.setSteps),
  moveSteps(InstructionKind.moveSteps),
  ifPathClear(InstructionKind.ifPathClear),

  /// The eye block with an "otherwise" row: one row runs when the path
  /// ahead is clear, the other when it isn't.
  ifElse(InstructionKind.ifElse),

  /// Repeats its blocks, with no count, until the friend reaches the flag.
  untilGoal(InstructionKind.untilGoal),

  /// The child's own block: runs the star row.
  star(InstructionKind.call);

  const BlockType(this.kind);

  final InstructionKind kind;

  /// Holds a row of blocks of its own.
  bool get isContainer =>
      this == repeat ||
      this == ifPathClear ||
      this == ifElse ||
      this == untilGoal;

  /// Checks the path ahead.
  bool get isCondition => this == ifPathClear || this == ifElse;
}

final class Block {
  const Block({
    required this.id,
    required this.type,
    this.count = 2,
    this.children = const [],
    this.otherwise = const [],
  });

  final String id;
  final BlockType type;

  /// Repeat count or saved Step Box value; ignored by other block types.
  final int count;
  final List<Block> children;

  /// An [BlockType.ifElse] block's second row, run when the path is blocked.
  final List<Block> otherwise;

  Block copyWith({int? count, List<Block>? children, List<Block>? otherwise}) =>
      Block(
        id: id,
        type: type,
        count: count ?? this.count,
        children: children ?? this.children,
        otherwise: otherwise ?? this.otherwise,
      );

  /// This block and every block nested inside it.
  Iterable<Block> get selfAndDescendants sync* {
    yield this;
    for (final child in [...children, ...otherwise]) {
      yield* child.selfAndDescendants;
    }
  }
}

/// Everything the child has built: the main row, and the star row that a
/// star block runs.
final class BlockProgram {
  const BlockProgram({
    this.main = const [],
    this.star = const [],
    this.tapToStar = false,
    this.selectedContainer,
    this.pickedBlock,
  });

  final List<Block> main;
  final List<Block> star;

  /// Where tapped palette blocks go: the star row, or else the main row.
  final bool tapToStar;

  /// A tapped repeat or condition receives palette actions without dragging.
  final String? selectedContainer;

  /// A tapped single block: the next palette tap replaces it, and the delete
  /// button removes just this block. How a child fixes one block in place.
  final String? pickedBlock;

  /// Nothing to run: the main row is empty.
  bool get isEmpty => main.isEmpty;

  BlockProgram copyWith({
    List<Block>? main,
    List<Block>? star,
    bool? tapToStar,
    String? Function()? selectedContainer,
    String? Function()? pickedBlock,
  }) => BlockProgram(
    main: main ?? this.main,
    star: star ?? this.star,
    tapToStar: tapToStar ?? this.tapToStar,
    selectedContainer: selectedContainer != null
        ? selectedContainer()
        : this.selectedContainer,
    pickedBlock: pickedBlock != null ? pickedBlock() : this.pickedBlock,
  );
}

/// Compiles the editor's blocks into the shared instruction set.
Program compileBlocks(List<Block> blocks, {List<Block> star = const []}) =>
    Program(
      [for (final block in blocks) _compile(block)],
      procedure: [for (final block in star) _compile(block)],
    );

Instruction _compile(Block block) => switch (block.type) {
  BlockType.forward => Move(blockId: block.id),
  BlockType.setSteps => SetSteps(block.count, blockId: block.id),
  BlockType.moveSteps => MoveSteps(blockId: block.id),
  BlockType.turnLeft => TurnLeft(blockId: block.id),
  BlockType.turnRight => TurnRight(blockId: block.id),
  BlockType.repeat => Repeat(block.count, [
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
  BlockType.star => Call(blockId: block.id),
  BlockType.untilGoal => RepeatUntilGoal([
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
  BlockType.ifPathClear => IfPathClear([
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
  BlockType.ifElse => IfElsePathClear(
    [for (final child in block.children) _compile(child)],
    [for (final child in block.otherwise) _compile(child)],
    blockId: block.id,
  ),
};
