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

    c.move(c.state.first.id, 3); // to the end
    expect(types(c).last, IconBlockType.turnRight);
    c.move(c.state.last.id, 0); // back to the front
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
}
