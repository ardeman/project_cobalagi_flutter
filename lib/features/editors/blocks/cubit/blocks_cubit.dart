import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/program/instruction.dart';
import '../../../../engine/program/program.dart';
import '../../../../engine/program/validation.dart';
import '../data/block.dart';

/// The child's program in the block editor: a main row of blocks, where a
/// repeat block holds its own row, plus a star row that star blocks run.
/// No repeat goes inside a repeat and no star inside the star row.
class BlocksCubit extends Cubit<BlockProgram> {
  BlocksCubit({this.maxBlocks, Program? start}) : super(const BlockProgram()) {
    // Blocks already placed, such as a debugging puzzle's buggy program.
    // Not an edit: undo never goes back past them.
    if (start != null) {
      super.emit(
        BlockProgram(
          main: _blocksOf(start.body),
          star: _blocksOf(start.procedure),
        ),
      );
    }
  }

  List<Block> _blocksOf(List<Instruction> instructions) => [
    for (final instruction in instructions)
      switch (instruction) {
        Move() => Block(id: 'b${_nextId++}', type: BlockType.forward),
        TurnLeft() => Block(id: 'b${_nextId++}', type: BlockType.turnLeft),
        TurnRight() => Block(id: 'b${_nextId++}', type: BlockType.turnRight),
        Call() => Block(id: 'b${_nextId++}', type: BlockType.star),
        MoveSteps() => Block(id: 'b${_nextId++}', type: BlockType.moveSteps),
        SetSteps(:final value) => Block(
          id: 'b${_nextId++}',
          type: BlockType.setSteps,
          count: value,
        ),
        Repeat(:final times, :final body) => Block(
          id: 'b${_nextId++}',
          type: BlockType.repeat,
          count: times,
          children: _blocksOf(body),
        ),
        IfPathClear(:final body) => Block(
          id: 'b${_nextId++}',
          type: BlockType.ifPathClear,
          children: _blocksOf(body),
        ),
        IfElsePathClear(:final body, :final otherwise) => Block(
          id: 'b${_nextId++}',
          type: BlockType.ifElse,
          children: _blocksOf(body),
          otherwise: _blocksOf(otherwise),
        ),
        RepeatUntilGoal(:final body) => Block(
          id: 'b${_nextId++}',
          type: BlockType.untilGoal,
          children: _blocksOf(body),
        ),
      },
  ];

  /// Parent id for the star row, in [add], [move] and [drop].
  static const starRow = '*';

  /// Added to an "otherwise" block's id, the parent id of its second row.
  static const otherwiseRow = ':else';

  /// The parent id of [blockId]'s "otherwise" row.
  static String otherwiseOf(String blockId) => '$blockId$otherwiseRow';

  /// The block a parent id belongs to, and whether it names the otherwise row.
  static (String, bool) _rowOf(String parentId) =>
      parentId.endsWith(otherwiseRow)
      ? (parentId.substring(0, parentId.length - otherwiseRow.length), true)
      : (parentId, false);

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
    // A picked block is swapped for the tapped one, in its place.
    if (state.pickedBlock case final picked?) {
      if (replace(picked, type)) return true;
    }
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
    if (state.tapToStar != star ||
        state.selectedContainer != null ||
        state.pickedBlock != null) {
      emit(
        state.copyWith(
          tapToStar: star,
          selectedContainer: () => null,
          pickedBlock: () => null,
        ),
      );
    }
  }

  /// Picks a container's row (an "otherwise" block has two) to receive
  /// tapped palette blocks.
  void pickContainer(String id) {
    final (blockId, otherwise) = _rowOf(id);
    final block = _find(blockId);
    if (otherwise && block?.type != BlockType.ifElse) return;
    if (block?.type.isContainer ?? false) {
      emit(
        state.copyWith(selectedContainer: () => id, pickedBlock: () => null),
      );
    }
  }

  /// Picks (or, if already picked, unpicks) a single block to fix.
  void pickBlock(String id) {
    final block = _find(id);
    if (block == null || block.type.isContainer) return;
    emit(
      state.copyWith(
        pickedBlock: () => state.pickedBlock == id ? null : id,
        selectedContainer: () => null,
      ),
    );
  }

  /// Puts a new [type] block where block [id] is. Containers can't replace
  /// or be replaced, so their contents never vanish by accident. Returns
  /// false if it isn't allowed there.
  bool replace(String id, BlockType type) {
    final old = _find(id);
    if (old == null || type.isContainer || old.type.isContainer) return false;
    final (parent, index) = _locate(id)!;
    if (!_fits(type, parent)) return false;
    final block = Block(id: 'b${_nextId++}', type: type);
    emit(
      _insert(
        _removed(id),
        parent,
        index,
        block,
      ).copyWith(pickedBlock: () => null),
    );
    return true;
  }

  /// Moves block [id] into [parentId] before the block now at [index].
  void move(String id, {String? parentId, required int index}) {
    final block = _find(id);
    if (block == null || !_fits(block.type, parentId)) return;
    // A container cannot be moved into itself or one of its descendants.
    final target = parentId == null ? null : _rowOf(parentId).$1;
    if (block.selfAndDescendants.any((b) => b.id == target)) return;
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
    final gone = {...?_find(id)?.selfAndDescendants.map((b) => b.id)};
    emit(
      _removed(id).copyWith(
        selectedContainer:
            gone.contains(
              state.selectedContainer == null
                  ? null
                  : _rowOf(state.selectedContainer!).$1,
            )
            ? () => null
            : null,
        pickedBlock: gone.contains(state.pickedBlock) ? () => null : null,
      ),
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

  /// The delete button: removes the picked block, or else every block.
  void deletePickedOrClear() {
    if (state.pickedBlock case final picked?) {
      remove(picked);
    } else {
      clear();
    }
  }

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
        pickedBlock: () => null,
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
    // Repeat-until runs to the end of the program, so it stays in the main
    // row, never inside another block or the star row.
    if (type == BlockType.untilGoal) return false;
    if (parentId == starRow) return type != BlockType.star;
    final (blockId, otherwise) = _rowOf(parentId);
    final parent = _find(blockId);
    if (!(parent?.type.isContainer ?? false)) return false;
    if (otherwise && parent?.type != BlockType.ifElse) return false;
    // Keep container nesting to one loop holding one condition. Children
    // of a condition are actions, so the editor stays usable on phones.
    if (type == BlockType.repeat ||
        (type.isCondition && (parent?.type.isCondition ?? false))) {
      return false;
    }
    // A repeat inside the star row may not hold a star either.
    return type != BlockType.star || !_inStar(blockId);
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
      final inner =
          _locateIn(blocks[i].children, id, blocks[i].id) ??
          _locateIn(blocks[i].otherwise, id, otherwiseOf(blocks[i].id));
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
    final (blockId, otherwise) = _rowOf(parentId);
    return _update(
      blocks,
      blockId,
      (parent) => otherwise
          ? parent.copyWith(
              otherwise: _insertIn(parent.otherwise, null, index, block),
            )
          : parent.copyWith(
              children: _insertIn(parent.children, null, index, block),
            ),
    );
  }

  static List<Block> _remove(List<Block> blocks, String id) => [
    for (final b in blocks)
      if (b.id != id)
        b.copyWith(
          children: _remove(b.children, id),
          otherwise: _remove(b.otherwise, id),
        ),
  ];

  static List<Block> _update(
    List<Block> blocks,
    String id,
    Block Function(Block) change,
  ) => [
    for (final b in blocks)
      b.id == id
          ? change(b)
          : b.copyWith(
              children: _update(b.children, id, change),
              otherwise: _update(b.otherwise, id, change),
            ),
  ];
}
