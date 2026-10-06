import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/program/program.dart';
import '../../../../engine/program/validation.dart';
import '../data/icon_block.dart';

/// The child's program in the Tier 1 editor: a main row of blocks, where a
/// repeat block holds its own row, plus a star row that star blocks run.
/// Tier 1 allows no repeat inside a repeat and no star inside the star row.
class IconBlocksCubit extends Cubit<IconProgram> {
  IconBlocksCubit({this.maxBlocks}) : super(const IconProgram());

  /// Parent id for the star row, in [add], [move] and [drop].
  static const starRow = '*';

  /// The level's block limit, or null for none.
  final int? maxBlocks;
  var _nextId = 0;

  Program get program => compileIconBlocks(state.main, star: state.star);

  int get blockCount => program.blockCount;

  bool get isFull => maxBlocks != null && blockCount >= maxBlocks!;

  /// Inserts a new block into [parentId] (null: the main row; [starRow]: the
  /// star row) at [index] (default: the end). Returns false if it isn't
  /// allowed there.
  bool add(IconBlockType type, {String? parentId, int? index}) {
    if (isFull || !_fits(type, parentId)) return false;
    final block = IconBlock(id: 'b${_nextId++}', type: type);
    emit(_insert(state, parentId, index, block));
    return true;
  }

  /// Adds a tapped palette block to the row the child picked last, the main
  /// row unless they tapped the star row. A star tapped while the star row is
  /// picked goes to the main row.
  bool tap(IconBlockType type) => add(
    type,
    parentId: state.tapToStar && type != IconBlockType.star ? starRow : null,
  );

  /// Picks the row that tapped palette blocks go to.
  void pickRow({required bool star}) {
    if (state.tapToStar != star) emit(state.copyWith(tapToStar: star));
  }

  /// Moves block [id] into [parentId] before the block now at [index].
  void move(String id, {String? parentId, required int index}) {
    final block = _find(id);
    if (block == null || !_fits(block.type, parentId)) return;
    final (oldParent, oldIndex) = _locate(id)!;
    final adjusted = oldParent == parentId && oldIndex < index
        ? index - 1
        : index;
    emit(_insert(_removed(id), parentId, adjusted, block));
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

  void remove(String id) => emit(_removed(id));

  void setCount(String id, int count) {
    if (count < minCount || count > maxCount) return;
    emit(
      state.copyWith(
        main: _update(state.main, id, (b) => b.copyWith(count: count)),
        star: _update(state.star, id, (b) => b.copyWith(count: count)),
      ),
    );
  }

  /// Removes the last block of the main row (the undo button).
  void removeLast() {
    if (state.main.isNotEmpty) {
      emit(state.copyWith(main: state.main.sublist(0, state.main.length - 1)));
    }
  }

  void clear() => emit(IconProgram(tapToStar: state.tapToStar));

  bool _fits(IconBlockType type, String? parentId) {
    if (parentId == null) return true;
    if (parentId == starRow) return type != IconBlockType.star;
    final parent = _find(parentId);
    if (parent?.type != IconBlockType.repeat) return false;
    if (type == IconBlockType.repeat) return false;
    // A repeat inside the star row may not hold a star either.
    return type != IconBlockType.star || !_inStar(parentId);
  }

  bool _inStar(String id) =>
      state.star.any((b) => b.selfAndDescendants.any((d) => d.id == id));

  IconBlock? _find(String id) {
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
    List<IconBlock> blocks,
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

  IconProgram _removed(String id) => state.copyWith(
    main: _remove(state.main, id),
    star: _remove(state.star, id),
  );

  static IconProgram _insert(
    IconProgram program,
    String? parentId,
    int? index,
    IconBlock block,
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

  static List<IconBlock> _insertIn(
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
        children: _insertIn(parent.children, null, index, block),
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
