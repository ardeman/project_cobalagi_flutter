import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/program.dart';

/// Block types of the block editor, one step per block. Tier 1 shows them
/// as pictures, Tier 2 as words.
enum BlockType {
  forward(InstructionKind.move),
  turnLeft(InstructionKind.turnLeft),
  turnRight(InstructionKind.turnRight),
  repeat(InstructionKind.repeat),

  /// The child's own block: runs the star row.
  star(InstructionKind.call);

  const BlockType(this.kind);

  final InstructionKind kind;
}

final class Block {
  const Block({
    required this.id,
    required this.type,
    this.count = 2,
    this.children = const [],
  });

  final String id;
  final BlockType type;

  /// Repeat count; ignored by other block types.
  final int count;
  final List<Block> children;

  Block copyWith({int? count, List<Block>? children}) => Block(
    id: id,
    type: type,
    count: count ?? this.count,
    children: children ?? this.children,
  );

  /// This block and every block nested inside it.
  Iterable<Block> get selfAndDescendants sync* {
    yield this;
    for (final child in children) {
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
  });

  final List<Block> main;
  final List<Block> star;

  /// Where tapped palette blocks go: the star row, or else the main row.
  final bool tapToStar;

  /// Nothing to run: the main row is empty.
  bool get isEmpty => main.isEmpty;

  BlockProgram copyWith({
    List<Block>? main,
    List<Block>? star,
    bool? tapToStar,
  }) => BlockProgram(
    main: main ?? this.main,
    star: star ?? this.star,
    tapToStar: tapToStar ?? this.tapToStar,
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
  BlockType.turnLeft => TurnLeft(blockId: block.id),
  BlockType.turnRight => TurnRight(blockId: block.id),
  BlockType.repeat => Repeat(block.count, [
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
  BlockType.star => Call(blockId: block.id),
};
