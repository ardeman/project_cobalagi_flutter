import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/program/program.dart';
import '../data/icon_block.dart';

/// The child's program in the Tier 1 editor: a flat row of blocks.
class IconBlocksCubit extends Cubit<List<IconBlock>> {
  IconBlocksCubit({this.maxBlocks}) : super(const []);

  /// The level's block limit, or null for none.
  final int? maxBlocks;
  var _nextId = 0;

  Program get program => compileIconBlocks(state);

  int get blockCount => program.blockCount;

  bool get isFull => maxBlocks != null && blockCount >= maxBlocks!;

  /// Inserts a new block at [index] (default: the end). Returns false when the
  /// block limit is reached.
  bool add(IconBlockType type, {int? index}) {
    if (isFull) return false;
    final block = IconBlock(id: 'b${_nextId++}', type: type);
    final blocks = [...state];
    blocks.insert((index ?? blocks.length).clamp(0, blocks.length), block);
    emit(blocks);
    return true;
  }

  /// Moves the block [id] so it sits before the block now at [index].
  void move(String id, int index) {
    final from = state.indexWhere((b) => b.id == id);
    if (from < 0) return;
    final blocks = [...state];
    final block = blocks.removeAt(from);
    final to = (from < index ? index - 1 : index).clamp(0, blocks.length);
    blocks.insert(to, block);
    emit(blocks);
  }

  void remove(String id) => emit([
    for (final b in state)
      if (b.id != id) b,
  ]);

  void removeLast() {
    if (state.isNotEmpty) emit(state.sublist(0, state.length - 1));
  }

  void clear() => emit(const []);
}
