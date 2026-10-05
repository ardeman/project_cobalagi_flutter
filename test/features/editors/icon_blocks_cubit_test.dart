import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/icon_blocks/cubit/icon_blocks_cubit.dart';
import 'package:cobalagi/features/editors/icon_blocks/data/icon_block.dart';
import 'package:flutter_test/flutter_test.dart';

List<IconBlockType> types(IconBlocksCubit c) => [
  for (final b in c.state) b.type,
];

void main() {
  test('add, insert, move and remove keep order', () {
    final c = IconBlocksCubit()
      ..add(IconBlockType.forward)
      ..add(IconBlockType.turnLeft)
      ..add(IconBlockType.turnRight, index: 0);
    expect(types(c), [
      IconBlockType.turnRight,
      IconBlockType.forward,
      IconBlockType.turnLeft,
    ]);

    c.move(c.state.first.id, index: 3); // to the end
    expect(types(c).last, IconBlockType.turnRight);
    c.move(c.state.last.id, index: 0); // back to the front
    expect(types(c).first, IconBlockType.turnRight);

    c
      ..remove(c.state.first.id)
      ..removeLast();
    expect(types(c), [IconBlockType.forward]);
    c.clear();
    expect(c.state, isEmpty);
  });

  test('respects the block limit', () {
    final c = IconBlocksCubit(maxBlocks: 2);
    expect(c.add(IconBlockType.forward), isTrue);
    expect(c.add(IconBlockType.forward), isTrue);
    expect(c.isFull, isTrue);
    expect(c.add(IconBlockType.forward), isFalse);
    expect(c.state, hasLength(2));
  });

  test('compiles to the shared instruction set with block ids', () {
    final c = IconBlocksCubit()
      ..add(IconBlockType.forward)
      ..add(IconBlockType.turnRight);
    final body = c.program.body;
    expect(body[0], isA<Move>());
    expect(body[1], isA<TurnRight>());
    expect(body.map((i) => i.blockId), [for (final b in c.state) b.id]);

    final nested = compileIconBlocks([
      const IconBlock(
        id: 'r',
        type: IconBlockType.repeat,
        count: 3,
        children: [IconBlock(id: 'f', type: IconBlockType.forward)],
      ),
    ]);
    final repeat = nested.body.single as Repeat;
    expect(repeat.times, 3);
    expect(repeat.body.single.blockId, 'f');
  });

  test('blocks nest inside a repeat, but a repeat cannot nest', () {
    final c = IconBlocksCubit()..add(IconBlockType.repeat);
    final loop = c.state.single.id;
    expect(c.add(IconBlockType.forward, parentId: loop), isTrue);
    expect(c.add(IconBlockType.turnLeft, parentId: loop), isTrue);
    expect(c.add(IconBlockType.repeat, parentId: loop), isFalse);
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
    final c = IconBlocksCubit()
      ..add(IconBlockType.forward)
      ..add(IconBlockType.repeat);
    final forward = c.state[0].id;
    final loop = c.state[1].id;

    c.move(forward, parentId: loop, index: 0);
    expect(c.state.single.children.single.id, forward);

    c.move(forward, index: 0);
    expect(c.state.map((b) => b.id), [forward, loop]);
    expect(c.state[1].children, isEmpty);

    c.add(IconBlockType.turnRight, parentId: loop);
    c.remove(c.state[1].children.single.id);
    expect(c.state[1].children, isEmpty);
  });

  test('repeat counts stay within 1 to 9', () {
    final c = IconBlocksCubit()..add(IconBlockType.repeat);
    final loop = c.state.single.id;
    c.setCount(loop, 12);
    expect(c.state.single.count, 2);
    c.setCount(loop, 9);
    expect(c.state.single.count, 9);
  });
}
