import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/icon_blocks/cubit/icon_blocks_cubit.dart';
import 'package:cobalagi/features/editors/icon_blocks/data/icon_block.dart';
import 'package:cobalagi/features/editors/icon_blocks/view/icon_block_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<IconBlocksCubit> pumpEditor(
  WidgetTester tester, {
  int? maxBlocks,
  bool star = false,
}) async {
  final cubit = IconBlocksCubit(maxBlocks: maxBlocks);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: SizedBox(
            width: 600,
            height: 500,
            child: IconBlockEditor(
              palette: {
                InstructionKind.move,
                InstructionKind.turnLeft,
                InstructionKind.turnRight,
                if (star) InstructionKind.call else InstructionKind.repeat,
              },
              blockSize: 64,
            ),
          ),
        ),
      ),
    ),
  );
  return cubit;
}

Finder paletteBlock(IconData icon) => find.byIcon(icon).first;

void main() {
  testWidgets('tapping palette blocks appends them', (tester) async {
    final cubit = await pumpEditor(tester);
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.tap(paletteBlock(Icons.turn_left_rounded));
    await tester.pump();
    expect(cubit.state.main.map((b) => b.type), [
      IconBlockType.forward,
      IconBlockType.turnLeft,
    ]);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(2));
  });

  testWidgets('dragging a palette block into the program adds it', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    final start = tester.getCenter(paletteBlock(Icons.turn_right_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 50));
    await gesture.moveTo(start + const Offset(0, 250));
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.single.type, IconBlockType.turnRight);
  });

  testWidgets('dragging a placed block onto the palette removes it', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(IconBlockType.forward)
      ..add(IconBlockType.turnLeft);
    await tester.pump();
    final placed = find.byIcon(Icons.turn_left_rounded).last;
    final gesture = await tester.startGesture(tester.getCenter(placed));
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveTo(
      tester.getCenter(paletteBlock(Icons.arrow_upward_rounded)),
    );
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.single.type, IconBlockType.forward);
  });

  testWidgets('the palette is disabled at the block limit', (tester) async {
    final cubit = await pumpEditor(tester, maxBlocks: 1);
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(cubit.state.main, hasLength(1));
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('dragging a block into a repeat nests it; + raises the count', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    await tester.tap(paletteBlock(Icons.repeat_rounded));
    await tester.pump();
    expect(cubit.state.main.single.type, IconBlockType.repeat);

    final start = tester.getCenter(paletteBlock(Icons.arrow_upward_rounded));
    final inner = tester.getCenter(find.byIcon(Icons.add_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveTo(inner);
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.single.children.single.type, IconBlockType.forward);

    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pump();
    expect(cubit.state.main.single.count, 3);
  });

  testWidgets('a full repeat block wraps its blocks instead of overflowing', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(IconBlockType.repeat);
    final loop = cubit.state.main.single.id;
    for (var i = 0; i < 8; i++) {
      cubit.add(IconBlockType.forward, parentId: loop);
    }
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'no overflow');
    final tops = {
      for (final e
          in find.byIcon(Icons.arrow_upward_rounded).evaluate().skip(1))
        tester.getTopLeft(find.byWidget(e.widget).first).dy,
    };
    expect(tops.length, greaterThan(1), reason: 'blocks wrap onto rows');
  });

  testWidgets('blocks can be dropped at the end of a repeat that has blocks', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(IconBlockType.repeat);
    final loop = cubit.state.main.single.id;
    cubit.add(IconBlockType.forward, parentId: loop);
    await tester.pump();

    // The drop spot after the last block inside the repeat.
    final end = find.bySemanticsLabel('Put blocks here');
    expect(end, findsOneWidget);
    final start = tester.getCenter(paletteBlock(Icons.turn_left_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveTo(tester.getCenter(end));
    await gesture.up();
    await tester.pump();

    expect(
      cubit.state.main,
      hasLength(1),
      reason: 'nothing added outside the loop',
    );
    expect(cubit.state.main.single.children.map((b) => b.type), [
      IconBlockType.forward,
      IconBlockType.turnLeft,
    ]);
  });

  testWidgets('the star row shows only when the palette has a star', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    await pumpEditor(tester, star: true);
    // The palette block and the star row's label.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
  });

  testWidgets('tapping the star row sends tapped blocks there', (tester) async {
    final cubit = await pumpEditor(tester, star: true);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    expect(cubit.state.tapToStar, isTrue);
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.tap(paletteBlock(Icons.turn_right_rounded));
    // A star tapped now still goes to the main row.
    await tester.tap(paletteBlock(Icons.star_rounded));
    await tester.pump();
    expect(cubit.state.star.map((b) => b.type), [
      IconBlockType.forward,
      IconBlockType.turnRight,
    ]);
    expect(cubit.state.main.single.type, IconBlockType.star);
    expect(cubit.program.procedure, hasLength(2));
  });
}
