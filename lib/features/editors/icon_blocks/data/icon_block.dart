import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/program.dart';

/// Tier 1 blocks: icons only, one step per block.
enum IconBlockType {
  forward(InstructionKind.move),
  turnLeft(InstructionKind.turnLeft),
  turnRight(InstructionKind.turnRight),
  repeat(InstructionKind.repeat),

  /// The child's own block: runs the star row.
  star(InstructionKind.call);

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

  IconBlock copyWith({int? count, List<IconBlock>? children}) => IconBlock(
    id: id,
    type: type,
    count: count ?? this.count,
    children: children ?? this.children,
  );

  /// This block and every block nested inside it.
  Iterable<IconBlock> get selfAndDescendants sync* {
    yield this;
    for (final child in children) {
      yield* child.selfAndDescendants;
    }
  }
}

/// Everything the child has built: the main row, and the star row that a
/// star block runs.
final class IconProgram {
  const IconProgram({
    this.main = const [],
    this.star = const [],
    this.tapToStar = false,
  });

  final List<IconBlock> main;
  final List<IconBlock> star;

  /// Where tapped palette blocks go: the star row, or else the main row.
  final bool tapToStar;

  /// Nothing to run: the main row is empty.
  bool get isEmpty => main.isEmpty;

  IconProgram copyWith({
    List<IconBlock>? main,
    List<IconBlock>? star,
    bool? tapToStar,
  }) => IconProgram(
    main: main ?? this.main,
    star: star ?? this.star,
    tapToStar: tapToStar ?? this.tapToStar,
  );
}

/// Compiles the editor's blocks into the shared instruction set.
Program compileIconBlocks(
  List<IconBlock> blocks, {
  List<IconBlock> star = const [],
}) => Program(
  [for (final block in blocks) _compile(block)],
  procedure: [for (final block in star) _compile(block)],
);

Instruction _compile(IconBlock block) => switch (block.type) {
  IconBlockType.forward => Move(blockId: block.id),
  IconBlockType.turnLeft => TurnLeft(blockId: block.id),
  IconBlockType.turnRight => TurnRight(blockId: block.id),
  IconBlockType.repeat => Repeat(block.count, [
    for (final child in block.children) _compile(child),
  ], blockId: block.id),
  IconBlockType.star => Call(blockId: block.id),
};
