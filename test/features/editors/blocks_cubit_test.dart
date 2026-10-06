import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:flutter_test/flutter_test.dart';

List<BlockType> types(BlocksCubit c) => [for (final b in c.state.main) b.type];

void main() {
  test('conditions compile with child ids and can be filled by tapping', () {
    final c = BlocksCubit()..add(BlockType.ifPathClear);
    addTearDown(c.close);
    final eye = c.state.main.single.id;
    c.pickContainer(eye);
    c.tap(BlockType.forward);
    final condition = c.program.body.single as IfPathClear;
    expect(condition.blockId, eye);
    expect(condition.body.single, isA<Move>());
    expect(
      condition.body.single.blockId,
      c.state.main.single.children.single.id,
    );
    expect(c.blockCount, 2);
    c.pickRow(star: false);
    c.tap(BlockType.turnRight);
    expect(c.state.main.last.type, BlockType.turnRight);
  });

  test(
    'a repeat can hold a condition; containers cannot move into themselves',
    () {
      final c = BlocksCubit()..add(BlockType.repeat);
      addTearDown(c.close);
      final loop = c.state.main.single.id;
      c.add(BlockType.ifPathClear, parentId: loop);
      final eye = c.state.main.single.children.single.id;
      c.add(BlockType.forward, parentId: eye);
      expect(c.add(BlockType.repeat, parentId: eye), isFalse);
      expect(c.add(BlockType.ifPathClear, parentId: eye), isFalse);
      final before = c.state;
      c.move(eye, parentId: eye, index: 0);
      expect(c.state, same(before));
      c.move(loop, parentId: eye, index: 0);
      expect(c.state, same(before));
      c.pickContainer(eye);
      c.remove(c.state.main.last.id);
      expect(c.state.selectedContainer, isNull);
      c.tap(BlockType.forward);
      expect(c.state.main.single.type, BlockType.forward);
    },
  );

  test('add, insert, move and remove keep order', () {
    final c = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.turnLeft)
      ..add(BlockType.turnRight, index: 0);
    expect(types(c), [
      BlockType.turnRight,
      BlockType.forward,
      BlockType.turnLeft,
    ]);

    c.move(c.state.main.first.id, index: 3); // to the end
    expect(types(c).last, BlockType.turnRight);
    c.move(c.state.main.last.id, index: 0); // back to the front
    expect(types(c).first, BlockType.turnRight);

    c.remove(c.state.main.first.id);
    c.remove(c.state.main.last.id);
    expect(types(c), [BlockType.forward]);
    c.clear();
    expect(c.state.main, isEmpty);
  });

  test('respects the block limit', () {
    final c = BlocksCubit(maxBlocks: 2);
    expect(c.add(BlockType.forward), isTrue);
    expect(c.add(BlockType.forward), isTrue);
    expect(c.isFull, isTrue);
    expect(c.add(BlockType.forward), isFalse);
    expect(c.state.main, hasLength(2));
  });

  test('compiles to the shared instruction set with block ids', () {
    final c = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.turnRight);
    final body = c.program.body;
    expect(body[0], isA<Move>());
    expect(body[1], isA<TurnRight>());
    expect(body.map((i) => i.blockId), [for (final b in c.state.main) b.id]);

    final nested = compileBlocks([
      const Block(
        id: 'r',
        type: BlockType.repeat,
        count: 3,
        children: [Block(id: 'f', type: BlockType.forward)],
      ),
    ]);
    final repeat = nested.body.single as Repeat;
    expect(repeat.times, 3);
    expect(repeat.body.single.blockId, 'f');
  });

  test('blocks nest inside a repeat, but a repeat cannot nest', () {
    final c = BlocksCubit()..add(BlockType.repeat);
    final loop = c.state.main.single.id;
    expect(c.add(BlockType.forward, parentId: loop), isTrue);
    expect(c.add(BlockType.turnLeft, parentId: loop), isTrue);
    expect(c.add(BlockType.repeat, parentId: loop), isFalse);
    c.setCount(loop, 4);

    final repeat = c.program.body.single as Repeat;
    expect(repeat.times, 4);
    expect(repeat.body.map((i) => i.kind), [
      InstructionKind.move,
      InstructionKind.turnLeft,
    ]);
    expect(c.blockCount, 3);
  });

  test('blocks move into and out of a repeat', () {
    final c = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.repeat);
    final forward = c.state.main[0].id;
    final loop = c.state.main[1].id;

    c.move(forward, parentId: loop, index: 0);
    expect(c.state.main.single.children.single.id, forward);

    c.move(forward, index: 0);
    expect(c.state.main.map((b) => b.id), [forward, loop]);
    expect(c.state.main[1].children, isEmpty);

    c.add(BlockType.turnRight, parentId: loop);
    c.remove(c.state.main[1].children.single.id);
    expect(c.state.main[1].children, isEmpty);
  });

  test('repeat counts stay within 1 to 9', () {
    final c = BlocksCubit()..add(BlockType.repeat);
    final loop = c.state.main.single.id;
    c.setCount(loop, 12);
    expect(c.state.main.single.count, 2);
    c.setCount(loop, 9);
    expect(c.state.main.single.count, 9);
  });

  group('star row', () {
    test('compiles to calls and a procedure, counted in the limit', () {
      final c = BlocksCubit(maxBlocks: 4)
        ..add(BlockType.forward, parentId: BlocksCubit.starRow)
        ..add(BlockType.turnLeft, parentId: BlocksCubit.starRow)
        ..add(BlockType.star)
        ..add(BlockType.star);
      expect(c.isFull, isTrue);
      final program = c.program;
      expect(program.body, everyElement(isA<Call>()));
      expect(program.procedure.map((i) => i.blockId), [
        for (final b in c.state.star) b.id,
      ]);
    });

    test('a star never goes inside the star row', () {
      final c = BlocksCubit();
      expect(c.add(BlockType.star, parentId: BlocksCubit.starRow), isFalse);
      c.add(BlockType.repeat, parentId: BlocksCubit.starRow);
      final loop = c.state.star.single.id;
      expect(c.add(BlockType.star, parentId: loop), isFalse);
      // A star may go in a repeat in the main row.
      c.add(BlockType.repeat);
      expect(c.add(BlockType.star, parentId: c.state.main.single.id), isTrue);
    });

    test('blocks move between the rows; a star stays out', () {
      final c = BlocksCubit()
        ..add(BlockType.forward)
        ..add(BlockType.star);
      final forward = c.state.main.first.id;
      final star = c.state.main.last.id;
      c.move(forward, parentId: BlocksCubit.starRow, index: 0);
      expect(c.state.star.single.id, forward);
      c.move(star, parentId: BlocksCubit.starRow, index: 0);
      expect(c.state.main.single.id, star);
      c.move(forward, index: 0);
      expect(c.state.star, isEmpty);
      expect(c.state.main.map((b) => b.id), [forward, star]);
    });

    test('clear empties both rows', () {
      final c = BlocksCubit()
        ..add(BlockType.forward, parentId: BlocksCubit.starRow)
        ..add(BlockType.star)
        ..clear();
      expect(c.state.main, isEmpty);
      expect(c.state.star, isEmpty);
    });
  });

  test('undo and redo step through edits, including clear', () {
    final c = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.repeat);
    final loop = c.state.main.last.id;
    c
      ..add(BlockType.turnLeft, parentId: loop)
      ..setCount(loop, 4);
    final built = c.state;
    expect(c.canRedo, isFalse);

    c.clear();
    expect(c.state.main, isEmpty);
    c.undo();
    expect(c.state.main, built.main);
    expect(c.canRedo, isTrue);
    c.redo();
    expect(c.state.main, isEmpty);
    c.undo();

    // Back through the count, the nested block and both adds.
    c.undo();
    expect(c.state.main.last.count, 2);
    c
      ..undo()
      ..undo()
      ..undo();
    expect(c.state.main, isEmpty);
    expect(c.canUndo, isFalse);
    c.undo(); // nothing left: no change
    expect(c.state.main, isEmpty);

    // A new edit after undo drops what could be redone.
    c.redo();
    expect(types(c), [BlockType.forward]);
    c.add(BlockType.turnRight);
    expect(c.canRedo, isFalse);
  });

  test('picking a row or container is not an edit', () {
    final c = BlocksCubit()..add(BlockType.repeat);
    final loop = c.state.main.single.id;
    c
      ..pickContainer(loop)
      ..pickRow(star: true)
      ..pickRow(star: false);
    c.undo();
    expect(c.state.main, isEmpty);
    expect(c.canUndo, isFalse);
  });

  test('a block dragged away comes back with undo', () {
    final c = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.turnLeft);
    c.remove(c.state.main.first.id);
    c.undo();
    expect(types(c), [BlockType.forward, BlockType.turnLeft]);
  });

  test('history keeps the last ${BlocksCubit.historyLimit} edits', () {
    final c = BlocksCubit();
    for (var i = 0; i < BlocksCubit.historyLimit + 10; i++) {
      c.add(BlockType.forward);
    }
    for (var i = 0; i < BlocksCubit.historyLimit + 10; i++) {
      c.undo();
    }
    expect(c.state.main, hasLength(10));
  });
}
