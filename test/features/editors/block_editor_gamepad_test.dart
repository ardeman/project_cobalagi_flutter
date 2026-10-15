import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'block_editor_test.dart' show pumpEditor;

/// Every control the highlight can reach from the first one with up, down,
/// left and right, as a controller's d-pad moves it.
Future<Set<FocusNode>> reachable(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  final start = FocusManager.instance.primaryFocus!;
  final seen = {start};
  final queue = [start];
  while (queue.isNotEmpty) {
    final node = queue.removeLast();
    for (final direction in TraversalDirection.values) {
      node.requestFocus();
      await tester.pump();
      FocusManager.instance.primaryFocus!.focusInDirection(direction);
      await tester.pumpAndSettle();
      final next = FocusManager.instance.primaryFocus!;
      if (seen.add(next)) queue.add(next);
    }
  }
  return seen;
}

/// The focus node of the tap target around a placed block.
FocusNode focusOf(WidgetTester tester, String blockId) => Focus.of(
  tester.element(
    find
        .descendant(
          of: find.byKey(ValueKey(blockId)).first,
          matching: find.byType(Icon),
        )
        .first,
  ),
);

void main() {
  testWidgets('the d-pad reaches every block, inside a repeat too', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    cubit
      ..add(BlockType.forward)
      ..add(BlockType.repeat);
    final repeat = cubit.state.main.last.id;
    cubit
      ..add(BlockType.turnLeft, parentId: repeat)
      ..add(BlockType.forward, parentId: repeat)
      ..add(BlockType.turnRight);
    await tester.pumpAndSettle();

    final seen = await reachable(tester);
    final placed = [
      for (final b in cubit.state.main) ...b.selfAndDescendants,
    ].where((b) => !b.type.isContainer);
    for (final block in placed) {
      expect(seen, contains(focusOf(tester, block.id)), reason: '$block');
    }
  });

  testWidgets('the d-pad reaches the Magic Block row and its blocks', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester, star: true);
    cubit
      ..add(BlockType.forward, parentId: BlocksCubit.starRow)
      ..add(BlockType.turnLeft, parentId: BlocksCubit.starRow)
      ..add(BlockType.star)
      ..add(BlockType.forward);
    await tester.pumpAndSettle();

    final seen = await reachable(tester);
    for (final block in [...cubit.state.star, ...cubit.state.main]) {
      expect(seen, contains(focusOf(tester, block.id)), reason: '$block');
    }
  });

  testWidgets('A on a palette block adds it; on a placed block picks it', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(cubit.state.main, hasLength(1));

    final placed = cubit.state.main.single.id;
    focusOf(tester, placed).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(cubit.state.pickedBlock, placed);
  });
}
