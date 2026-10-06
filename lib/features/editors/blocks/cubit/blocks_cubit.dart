import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/program/program.dart';
import '../../../../engine/program/validation.dart';
import '../data/block.dart';

/// The child's program in the block editor: a main row of blocks, where a
/// repeat block holds its own row, plus a star row that star blocks run.
/// No repeat goes inside a repeat and no star inside the star row.
class BlocksCubit extends Cubit<BlockProgram> {
  BlocksCubit({this.maxBlocks}) : super(const BlockProgram());

  /// Parent id for the star row, in [add], [move] and [drop].
  static const starRow = '*';

  /// The level's block limit, or null for none.
  final int? maxBlocks;
  var _nextId = 0;

  Program get program => compileBlocks(state.main, star: state.star);

  int get blockCount => program.blockCount;

  bool get isFull => maxBlocks != null && blockCount >= maxBlocks!;

  /// Inserts a new block into [parentId] (null: the main row; [starRow]: the
  /// star row) at [index] (default: the end). Returns false if it isn't
  /// allowed there.
  bool add(BlockType type, {String? parentId, int? index}) {
    if (isFull || !_fits(type, parentId)) return false;
    final block = Block(id: 'b${_nextId++}', type: type);
    emit(_insert(state, parentId, index, block));
    return true;
  }

  /// Adds a tapped palette block to the row the child picked last, the main
  /// row unless they tapped the star row. A star tapped while the star row is
  /// picked goes to the main row.
  bool tap(BlockType type) {
    final selected = state.selectedContainer;
    // A new repeat starts in the main row; actions go inside the selected
    // container. A condition can go inside a repeat.
    final parent = selected != null && _fits(type, selected)
        ? selected
        : state.tapToStar && type != BlockType.star
        ? starRow
        : null;
    return add(type, parentId: parent);
  }

  /// Picks the row that tapped palette blocks go to.
  void pickRow({required bool star}) {
    if (state.tapToStar != star || state.selectedContainer != null) {
      emit(state.copyWith(tapToStar: star, selectedContainer: () => null));
    }
  }

  void pickContainer(String id) {
    final block = _find(id);
    if (block?.type == BlockType.repeat ||
        block?.type == BlockType.ifPathClear) {
      emit(state.copyWith(selectedContainer: () => id));
    }
  }

  /// Moves block [id] into [parentId] before the block now at [index].
  void move(String id, {String? parentId, required int index}) {
    final block = _find(id);
    if (block == null || !_fits(block.type, parentId)) return;
    // A container cannot be moved into itself or one of its descendants.
    if (block.selfAndDescendants.any((b) => b.id == parentId)) return;
    final (oldParent, oldIndex) = _locate(id)!;
    final adjusted = oldParent == parentId && oldIndex < index
        ? index - 1
        : index;
    emit(_insert(_removed(id), parentId, adjusted, block));
  }

  /// Adds a palette block or moves a placed one, depending on [data].
  void drop(Object data, {String? parentId, required int index}) {
    switch (data) {
      case BlockType type:
        add(type, parentId: parentId, index: index);
      case Block block:
        move(block.id, parentId: parentId, index: index);
    }
  }

  void remove(String id) {
    final selected = state.selectedContainer;
    final removesSelection =
        _find(id)?.selfAndDescendants.any((b) => b.id == selected) ?? false;
    final removed = _removed(id);
    emit(
      removesSelection
          ? removed.copyWith(selectedContainer: () => null)
          : removed,
    );
  }

  void setCount(String id, int count) {
    if (count < minCount || count > maxCount) return;
    emit(
      state.copyWith(
        main: _update(state.main, id, (b) => b.copyWith(count: count)),
        star: _update(state.star, id, (b) => b.copyWith(count: count)),
      ),
    );
  }

  void clear() => emit(BlockProgram(tapToStar: state.tapToStar));

  /// Edits that can be undone, oldest first.
  final _past = <BlockProgram>[];

  /// Undone edits that can be redone, most recently undone last.
  final _future = <BlockProgram>[];

  /// How many edits [undo] can step back.
  static const historyLimit = 50;

  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  /// Puts the blocks back as they were before the last edit, including a
  /// clear or a block dragged away by accident.
  void undo() => _restore(from: _past, to: _future);

  /// Applies the edit [undo] last took back.
  void redo() => _restore(from: _future, to: _past);

  void _restore({
    required List<BlockProgram> from,
    required List<BlockProgram> to,
  }) {
    if (from.isEmpty) return;
    to.add(state);
    final program = from.removeLast();
    // Keep the row the child picked; a picked container may be gone.
    super.emit(
      program.copyWith(
        tapToStar: state.tapToStar,
        selectedContainer: () => null,
      ),
    );
  }

  /// Records every change to the blocks, but not picking a row or container.
  @override
  void emit(BlockProgram state) {
    final before = this.state;
    if (!identical(state.main, before.main) ||
        !identical(state.star, before.star)) {
      _past.add(before);
      if (_past.length > historyLimit) _past.removeAt(0);
      _future.clear();
    }
    super.emit(state);
  }

  bool _fits(BlockType type, String? parentId) {
    if (parentId == null) return true;
    if (parentId == starRow) return type != BlockType.star;
    final parent = _find(parentId);
    if (parent?.type != BlockType.repeat &&
        parent?.type != BlockType.ifPathClear) {
      return false;
    }
    // Keep container nesting to one repeat holding one condition. Children
    // of a condition are actions, so the editor stays usable on phones.
    if (type == BlockType.repeat ||
        (type == BlockType.ifPathClear && parent?.type != BlockType.repeat)) {
      return false;
    }
    // A repeat inside the star row may not hold a star either.
    return type != BlockType.star || !_inStar(parentId);
  }

  bool _inStar(String id) =>
      state.star.any((b) => b.selfAndDescendants.any((d) => d.id == id));

  Block? _find(String id) {
    for (final block in [...state.main, ...state.star]) {
      for (final b in block.selfAndDescendants) {
        if (b.id == id) return b;
      }
    }
    return null;
  }

  /// The parent id ([starRow] for the star row) and index of block [id].
  (String?, int)? _locate(String id) {
    final inMain = _locateIn(state.main, id);
    if (inMain != null) return inMain;
    final inStar = _locateIn(state.star, id);
    if (inStar == null) return null;
    return (inStar.$1 ?? starRow, inStar.$2);
  }

  static (String?, int)? _locateIn(
    List<Block> blocks,
    String id, [
    String? parentId,
  ]) {
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].id == id) return (parentId, i);
      final inner = _locateIn(blocks[i].children, id, blocks[i].id);
      if (inner != null) return inner;
    }
    return null;
  }

  BlockProgram _removed(String id) => state.copyWith(
    main: _remove(state.main, id),
    star: _remove(state.star, id),
  );

  static BlockProgram _insert(
    BlockProgram program,
    String? parentId,
    int? index,
    Block block,
  ) => switch (parentId) {
    null => program.copyWith(main: _insertIn(program.main, null, index, block)),
    starRow => program.copyWith(
      star: _insertIn(program.star, null, index, block),
    ),
    _ => program.copyWith(
      main: _insertIn(program.main, parentId, index, block),
      star: _insertIn(program.star, parentId, index, block),
    ),
  };

  static List<Block> _insertIn(
    List<Block> blocks,
    String? parentId,
    int? index,
    Block block,
  ) {
    if (parentId == null) {
      final at = (index ?? blocks.length).clamp(0, blocks.length);
      return [...blocks]..insert(at, block);
    }
    return _update(
      blocks,
      parentId,
      (parent) => parent.copyWith(
        children: _insertIn(parent.children, null, index, block),
      ),
    );
  }

  static List<Block> _remove(List<Block> blocks, String id) => [
    for (final b in blocks)
      if (b.id != id) b.copyWith(children: _remove(b.children, id)),
  ];

  static List<Block> _update(
    List<Block> blocks,
    String id,
    Block Function(Block) change,
  ) => [
    for (final b in blocks)
      b.id == id
          ? change(b)
          : b.copyWith(children: _update(b.children, id, change)),
  ];
}
