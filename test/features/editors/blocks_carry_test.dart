import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:flutter_test/flutter_test.dart';

/// The program as types, a repeat's blocks in brackets.
String shape(List<Block> blocks) => blocks
    .map(
      (b) => b.type.isContainer
          ? '${b.type.name}[${shape(b.children)}]'
          : b.type.name,
    )
    .join(' ');

void main() {
  late BlocksCubit cubit;
  setUp(() {
    cubit = BlocksCubit()
      ..add(BlockType.forward)
      ..add(BlockType.repeat);
    final repeat = cubit.state.main[1].id;
    cubit
      ..add(BlockType.turnLeft, parentId: repeat)
      ..add(BlockType.turnRight);
  });
  tearDown(() => cubit.close());

  test('a carried block walks through every spot, into a repeat too', () {
    cubit.carry(cubit.state.main[0].id);
    expect(cubit.state.carrying, isTrue);
    final seen = <String>[shape(cubit.state.main)];
    for (var i = 0; i < 6; i++) {
      cubit.carryBy(1);
      seen.add(shape(cubit.state.main));
    }
    expect(seen, [
      'forward repeat[turnLeft] turnRight',
      'repeat[forward turnLeft] turnRight',
      'repeat[turnLeft forward] turnRight',
      'repeat[turnLeft] forward turnRight',
      'repeat[turnLeft] turnRight forward',
      // It stops at the end.
      'repeat[turnLeft] turnRight forward',
      'repeat[turnLeft] turnRight forward',
    ]);
    cubit.carryBy(-2);
    expect(shape(cubit.state.main), 'repeat[turnLeft forward] turnRight');
  });

  test('dropping is one edit for undo; B puts the block back', () {
    final first = cubit.state.main[0].id;
    cubit
      ..carry(first)
      ..carryBy(1)
      ..carryBy(1)
      ..carryBy(1)
      ..dropCarried();
    expect(cubit.state.carrying, isFalse);
    expect(cubit.state.pickedBlock, first, reason: 'picked once put down');
    expect(shape(cubit.state.main), 'repeat[turnLeft] forward turnRight');
    cubit.undo();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft] turnRight');

    cubit
      ..carry(first)
      ..carryBy(3)
      ..cancelCarry();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft] turnRight');
    expect(cubit.state.carrying, isFalse);
    // An edit would have cleared redo.
    expect(cubit.canRedo, isTrue, reason: 'a cancelled carry is no edit');
  });

  test('a picked repeat carries with its blocks, never into itself', () {
    final repeat = cubit.state.main[1].id;
    cubit
      ..carry(repeat)
      ..carryBy(-1);
    expect(shape(cubit.state.main), 'repeat[turnLeft] forward turnRight');
    cubit
      ..carryBy(5)
      ..dropCarried();
    expect(shape(cubit.state.main), 'forward turnRight repeat[turnLeft]');
    // Picked as a row again, so delete can't take its blocks by accident.
    expect(cubit.state.pickedBlock, isNull);
    expect(cubit.state.selectedContainer, repeat);
  });

  test('R2 on the palette drags out a new block; B takes it away', () {
    cubit
      ..grabNew(BlockType.forward)
      ..carryBy(-1);
    expect(cubit.state.carrying, isTrue);
    expect(
      shape(cubit.state.main),
      'forward repeat[turnLeft] forward turnRight',
    );
    cubit.dropCarried();
    cubit.undo();
    expect(
      shape(cubit.state.main),
      'forward repeat[turnLeft] turnRight',
      reason: 'adding and moving it is one edit',
    );

    cubit
      ..grabNew(BlockType.turnLeft)
      ..carryBy(-2)
      ..cancelCarry();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft] turnRight');
  });

  test('carried back past the first spot, a block goes over the palette; '
      'putting it down there deletes it, as one edit', () {
    final last = cubit.state.main.last.id;
    cubit
      ..carry(last)
      ..carryBy(-20);
    expect(cubit.state.overPalette, isTrue);
    expect(shape(cubit.state.main), 'forward repeat[turnLeft]');
    // Steering forward again brings it back in, at the first spot.
    cubit.carryBy(1);
    expect(cubit.state.overPalette, isFalse);
    expect(shape(cubit.state.main), 'turnRight forward repeat[turnLeft]');
    cubit
      ..carryBy(-1)
      ..dropCarried();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft]');
    expect(cubit.state.carrying, isFalse);
    expect(cubit.state.pickedBlock, isNull);
    cubit.undo();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft] turnRight');
  });

  test('a new block taken straight back to the palette leaves no edit', () {
    final undoable = cubit.canUndo;
    cubit
      ..grabNew(BlockType.forward)
      ..carryBy(-20)
      ..dropCarried();
    expect(shape(cubit.state.main), 'forward repeat[turnLeft] turnRight');
    expect(cubit.canRedo, isFalse);
    cubit.undo();
    expect(
      shape(cubit.state.main),
      'forward repeat[turnLeft]',
      reason: 'undo takes back the last real edit (setUp), not a no-op',
    );
    expect(undoable, isTrue);
  });
}
