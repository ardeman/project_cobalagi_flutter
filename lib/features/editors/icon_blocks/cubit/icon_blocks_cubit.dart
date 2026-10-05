import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/program/program.dart';
import '../../../../engine/program/validation.dart';
import '../data/icon_block.dart';

/// The child's program in the Tier 1 editor: a row of blocks, where a repeat
/// block holds its own row. Tier 1 allows no repeat inside a repeat.
class IconBlocksCubit extends Cubit<List<IconBlock>> {
  IconBlocksCubit({this.maxBlocks}) : super(const []);

  /// The level's block limit, or null for none.
  final int? maxBlocks;
  var _nextId = 0;

  Program get program => compileIconBlocks(state);

  int get blockCount => program.blockCount;

  bool get isFull => maxBlocks != null && blockCount >= maxBlocks!;

  /// Inserts a new block into [parentId] (null: the main row) at [index]
  /// (default: the end). Returns false if it isn't allowed there.
  bool add(IconBlockType type, {String? parentId, int? index}) {
    if (isFull || !_fits(type, parentId)) return false;
    final block = IconBlock(id: 'b${_nextId++}', type: type);
    emit(_insert(state, parentId, index, block));
    return true;
  }

  /// Moves block [id] into [parentId] before the block now at [index].
  void move(String id, {String? parentId, required int index}) {
    final block = _find(state, id);
    if (block == null || !_fits(block.type, parentId)) return;
    final (oldParent, oldIndex) = _locate(state, id)!;
    final adjusted = oldParent == parentId && oldIndex < index
        ? index - 1
        : index;
    emit(_insert(_remove(state, id), parentId, adjusted, block));
  }

  /// Adds a palette block or moves a placed one, depending on [data].
  void drop(Object data, {String? parentId, required int index}) {
    switch (data) {
      case IconBlockType type:
        add(type, parentId: parentId, index: index);
      case IconBlock block:
        move(block.id, parentId: parentId, index: index);
    }
  }

  void remove(String id) => emit(_remove(state, id));

  void setCount(String id, int count) {
    if (count < minCount || count > maxCount) return;
    emit(_update(state, id, (b) => b.copyWith(count: count)));
  }

  void removeLast() {
    if (state.isNotEmpty) emit(state.sublist(0, state.length - 1));
  }

  void clear() => emit(const []);

  bool _fits(IconBlockType type, String? parentId) {
    if (parentId == null) return true;
    final parent = _find(state, parentId);
    return parent?.type == IconBlockType.repeat && type != IconBlockType.repeat;
  }

  static IconBlock? _find(List<IconBlock> blocks, String id) {
    for (final block in blocks) {
      for (final b in block.selfAndDescendants) {
        if (b.id == id) return b;
      }
    }
    return null;
  }

  /// The parent id (null for the main row) and index of block [id].
  static (String?, int)? _locate(
    List<IconBlock> blocks,
    String id, [
    String? parentId,
  ]) {
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].id == id) return (parentId, i);
      final inner = _locate(blocks[i].children, id, blocks[i].id);
      if (inner != null) return inner;
    }
    return null;
  }

  static List<IconBlock> _insert(
    List<IconBlock> blocks,
    String? parentId,
    int? index,
    IconBlock block,
  ) {
    if (parentId == null) {
      final at = (index ?? blocks.length).clamp(0, blocks.length);
      return [...blocks]..insert(at, block);
    }
    return _update(
      blocks,
      parentId,
      (parent) => parent.copyWith(
        children: _insert(parent.children, null, index, block),
      ),
    );
  }

  static List<IconBlock> _remove(List<IconBlock> blocks, String id) => [
    for (final b in blocks)
      if (b.id != id) b.copyWith(children: _remove(b.children, id)),
  ];

  static List<IconBlock> _update(
    List<IconBlock> blocks,
    String id,
    IconBlock Function(IconBlock) change,
  ) => [
    for (final b in blocks)
      b.id == id
          ? change(b)
          : b.copyWith(children: _update(b.children, id, change)),
  ];
}
