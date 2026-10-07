import 'dart:convert';

import '../../../engine/world/level.dart';
import '../../editors/blocks/cubit/blocks_cubit.dart';
import '../../editors/blocks/data/block.dart';

/// One step of a "Watch me!" demo, done the way a child would do it.
sealed class TutorialAction {
  const TutorialAction();

  factory TutorialAction.fromJson(Object? json) => switch (json) {
    'go' => const PressGo(),
    {
      'add': final String type,
      'in': final List<Object?> path,
      'otherwise': true,
    } =>
      AddBlock(
        BlockType.values.byName(type),
        into: path.cast<int>(),
        otherwise: true,
      ),
    {'add': final String type, 'in': final List<Object?> path} => AddBlock(
      BlockType.values.byName(type),
      into: path.cast<int>(),
    ),
    {'add': final String type, 'star': true} => AddBlock(
      BlockType.values.byName(type),
      star: true,
    ),
    {'add': final String type} => AddBlock(BlockType.values.byName(type)),
    {'count': [final int index, final int count]} => SetCount(index, count),
    {'pick': final List<Object?> path} => PickBlock(path.cast<int>()),
    {'tap': final String type} => TapPalette(BlockType.values.byName(type)),
    _ => throw FormatException('unknown tutorial action: $json'),
  };

  /// The palette block the demo hand points at, if any.
  BlockType? get pointsAt => null;
}

/// Adds a block to the main row, the star row, or into the container at
/// [into] (indexes into the main row, then its children); into an
/// "otherwise" block's second row when [otherwise].
final class AddBlock extends TutorialAction {
  const AddBlock(
    this.type, {
    this.into = const [],
    this.star = false,
    this.otherwise = false,
  });

  final BlockType type;
  final List<int> into;
  final bool star;
  final bool otherwise;

  @override
  BlockType get pointsAt => type;
}

final class SetCount extends TutorialAction {
  const SetCount(this.index, this.count);

  /// Index into the main row.
  final int index;
  final int count;
}

/// Taps a placed block, as a child does before fixing it.
final class PickBlock extends TutorialAction {
  const PickBlock(this.path);

  final List<int> path;
}

/// Taps a palette block: added, or swapped for the picked block.
final class TapPalette extends TutorialAction {
  const TapPalette(this.type);

  final BlockType type;

  @override
  BlockType get pointsAt => type;
}

final class PressGo extends TutorialAction {
  const PressGo();
}

/// An island's demo: a small level and what the hand does in it.
final class Tutorial {
  const Tutorial({required this.level, required this.actions});

  factory Tutorial.fromJson(Map<String, Object?> json) => Tutorial(
    level: Level.fromJson((json['level']! as Map).cast<String, Object?>()),
    actions: [
      for (final action in json['actions']! as List)
        TutorialAction.fromJson(action),
    ],
  );

  final Level level;
  final List<TutorialAction> actions;

  String get concept => level.concept;
}

/// Parses `assets/config/tutorials.json`: `{"<concept>": {level, actions}}`.
Map<String, Tutorial> parseTutorials(String source) => {
  for (final MapEntry(:key, :value)
      in (jsonDecode(source) as Map<String, Object?>).entries)
    key: Tutorial.fromJson((value! as Map).cast<String, Object?>()),
};

String _idAt(List<Block> row, List<int> path) {
  var block = row[path.first];
  for (final i in path.skip(1)) {
    block = block.children[i];
  }
  return block.id;
}

/// Does [action] to the editor's blocks. [PressGo] is left to the caller,
/// which runs the program and waits for the world.
void applyTutorialAction(BlocksCubit blocks, TutorialAction action) {
  switch (action) {
    case AddBlock(:final type, :final into, :final star, :final otherwise):
      blocks.add(
        type,
        parentId: star
            ? BlocksCubit.starRow
            : into.isEmpty
            ? null
            : otherwise
            ? BlocksCubit.otherwiseOf(_idAt(blocks.state.main, into))
            : _idAt(blocks.state.main, into),
      );
    case SetCount(:final index, :final count):
      blocks.setCount(blocks.state.main[index].id, count);
    case PickBlock(:final path):
      blocks.pickBlock(_idAt(blocks.state.main, path));
    case TapPalette(:final type):
      blocks.tap(type);
    case PressGo():
      break;
  }
}
