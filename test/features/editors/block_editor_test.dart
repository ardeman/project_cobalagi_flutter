import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BlocksCubit> pumpEditor(
  WidgetTester tester, {
  int? maxBlocks,
  bool star = false,
  bool showHowTo = false,
  bool conditions = false,
}) async {
  final cubit = BlocksCubit(maxBlocks: maxBlocks);
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
            child: BlockEditor(
              palette: {
                InstructionKind.move,
                InstructionKind.turnLeft,
                InstructionKind.turnRight,
                if (star) InstructionKind.call else InstructionKind.repeat,
                if (conditions) InstructionKind.ifPathClear,
              },
              blockSize: 64,
              showHowTo: showHowTo,
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
  testWidgets('Step Box buttons save 1–9 with 64dp targets', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = BlocksCubit(maxBlocks: 2);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: BlockEditor(
              palette: const {
                InstructionKind.setSteps,
                InstructionKind.moveSteps,
              },
              blockSize: 64,
            ),
          ),
        ),
      ),
    );
    await tester.tap(paletteBlock(Icons.inventory_2_rounded));
    await tester.pump();
    expect(cubit.state.main.single.count, 2);
    final fewer = find.byTooltip('Save a smaller number');
    final more = find.byTooltip('Save a bigger number');
    expect(tester.getSize(fewer).width, greaterThanOrEqualTo(64));
    expect(tester.getSize(more).height, greaterThanOrEqualTo(64));
    await tester.tap(fewer);
    await tester.pump();
    expect(cubit.state.main.single.count, 1);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.remove_circle_rounded),
          )
          .onPressed,
      isNull,
    );
    for (var i = 0; i < 8; i++) {
      await tester.tap(more);
      await tester.pump();
    }
    expect(cubit.state.main.single.count, 9);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_circle_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(paletteBlock(Icons.forward_rounded));
    await tester.pump();
    final Program program = cubit.program;
    expect((program.body.first as SetSteps).value, 9);
    expect(program.body.last, isA<MoveSteps>());
    expect(program.body.first.blockId, cubit.state.main.first.id);
    expect(program.body.last.blockId, cubit.state.main.last.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in a scrolling page the editor shows each new block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = BlocksCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            // Phones scroll the world and the editor as one page.
            child: SingleChildScrollView(
              child: BlockEditor(
                palette: const {
                  InstructionKind.move,
                  InstructionKind.turnLeft,
                  InstructionKind.turnRight,
                  InstructionKind.call,
                },
                blockSize: 56,
                fitContent: true,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      // Like a tap on the palette, which may have scrolled away by now.
      cubit.tap(BlockType.turnLeft);
      await tester.pumpAndSettle();
    }
    expect(cubit.state.main, hasLength(12));
    // The palette scrolled away and the newest block is on screen.
    final last = find.byKey(ValueKey(cubit.state.main.last.id));
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('in a scrolling page, a swipe on a block scrolls; a hold drags', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = BlocksCubit();
    addTearDown(cubit.close);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  // The world above the editor, as on a phone.
                  const SizedBox(height: 300),
                  BlockEditor(
                    palette: const {
                      InstructionKind.move,
                      InstructionKind.repeat,
                    },
                    blockSize: 56,
                    fitContent: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // A repeat as wide as the screen, then more blocks below it.
    cubit.add(BlockType.repeat);
    final loop = cubit.state.main.single.id;
    for (var i = 0; i < 4; i++) {
      cubit.add(BlockType.forward, parentId: loop);
    }
    for (var i = 0; i < 6; i++) {
      cubit.add(BlockType.forward);
    }
    await tester.pumpAndSettle();
    final program = cubit.state;

    // Scroll the repeat into view near the bottom, then swipe down on it.
    final repeat = find.byKey(ValueKey(loop));
    await tester.ensureVisible(repeat);
    await tester.pumpAndSettle();
    final start = scroll.offset;
    expect(start, greaterThan(0));
    await tester.dragFrom(tester.getCenter(repeat), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(scroll.offset, lessThan(start));
    expect(cubit.state.main, program.main);

    // Hold, then drag the last block onto the palette to remove it.
    final last = find.byKey(ValueKey(cubit.state.main.last.id));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(last));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byIcon(Icons.arrow_upward_rounded).first);
    await gesture.moveTo(
      tester.getCenter(find.byIcon(Icons.arrow_upward_rounded).first),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(cubit.state.main, hasLength(program.main.length - 1));
  });

  for (final showTips in [true, false]) {
    testWidgets('the written Step Box tip follows showTips ($showTips)', (
      tester,
    ) async {
      final cubit = BlocksCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: BlockEditor(
                palette: const {
                  InstructionKind.setSteps,
                  InstructionKind.moveSteps,
                },
                blockSize: 56,
                showTips: showTips,
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(BlockEditor));
      expect(
        find.text(AppLocalizations.of(context).variableHint),
        showTips ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('undo brings cleared blocks back; redo clears them again', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    final undo = find.byTooltip('Undo');
    final redo = find.byTooltip('Redo');
    IconButton button(Finder f) => tester.widget<IconButton>(
      find.ancestor(of: f, matching: find.byType(IconButton)).first,
    );
    expect(button(undo).onPressed, isNull);
    expect(button(redo).onPressed, isNull);

    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.tap(paletteBlock(Icons.turn_left_rounded));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove all blocks'));
    await tester.pump();
    expect(cubit.state.main, isEmpty);

    await tester.tap(undo);
    await tester.pump();
    expect(cubit.state.main, hasLength(2));
    expect(button(redo).onPressed, isNotNull);

    await tester.tap(redo);
    await tester.pump();
    expect(cubit.state.main, isEmpty);
  });

  testWidgets('tap a condition then a palette action to fill it', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester, conditions: true);
    await tester.tap(paletteBlock(Icons.visibility_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.visibility_rounded).last);
    await tester.pump();
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.pump();
    final condition = cubit.program.body.single as IfPathClear;
    expect(condition.body.single, isA<Move>());
    expect(find.bySemanticsLabel('Put blocks here'), findsOneWidget);
  });

  testWidgets('drag actions into a condition', (tester) async {
    final cubit = await pumpEditor(tester, conditions: true);
    await tester.tap(paletteBlock(Icons.visibility_rounded));
    await tester.pump();
    final start = tester.getCenter(paletteBlock(Icons.arrow_upward_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveTo(
      tester.getCenter(find.bySemanticsLabel('Put blocks here')),
    );
    await gesture.up();
    await tester.pump();
    expect((cubit.program.body.single as IfPathClear).body.single, isA<Move>());
  });

  testWidgets('a condition inside a repeat fits a phone', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    final cubit = await pumpEditor(tester, conditions: true);
    cubit.add(BlockType.repeat);
    final loop = cubit.state.main.single.id;
    cubit.add(BlockType.ifPathClear, parentId: loop);
    final eye = cubit.state.main.single.children.single.id;
    cubit.add(BlockType.forward, parentId: eye);
    await tester.pump();
    // Layout errors are reported by the widget test framework.
  });

  testWidgets('tapping palette blocks appends them', (tester) async {
    final cubit = await pumpEditor(tester);
    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.tap(paletteBlock(Icons.turn_left_rounded));
    await tester.pump();
    expect(cubit.state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.turnLeft,
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
    expect(cubit.state.main.single.type, BlockType.turnRight);
  });

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('dragging a placed block onto the palette removes it ($kind)', (
      tester,
    ) async {
      final cubit = await pumpEditor(tester)
        ..add(BlockType.forward)
        ..add(BlockType.turnLeft);
      await tester.pump();
      final placed = find.byIcon(Icons.turn_left_rounded).last;
      final gesture = await tester.startGesture(
        tester.getCenter(placed),
        kind: kind,
      );
      // A finger holds first, since the program row can scroll.
      if (kind == PointerDeviceKind.touch) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveTo(
        tester.getCenter(paletteBlock(Icons.arrow_upward_rounded)),
      );
      await gesture.up();
      await tester.pump();
      expect(cubit.state.main.single.type, BlockType.forward);
    });
  }

  testWidgets('on a tablet, a swipe on a placed block scrolls the program', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester);
    cubit.add(BlockType.repeat);
    final loop = cubit.state.main.single.id;
    for (var i = 0; i < 3; i++) {
      cubit.add(BlockType.forward, parentId: loop);
    }
    for (var i = 0; i < 12; i++) {
      cubit.add(BlockType.turnLeft);
    }
    await tester.pumpAndSettle();
    final program = cubit.state;
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    // Swipe up from the wide repeat, as a finger would.
    await tester.dragFrom(
      tester.getCenter(find.byKey(ValueKey(loop))),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(cubit.state.main, program.main);
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
    expect(cubit.state.main.single.type, BlockType.repeat);

    final start = tester.getCenter(paletteBlock(Icons.arrow_upward_rounded));
    final inner = tester.getCenter(find.byIcon(Icons.add_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveTo(inner);
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.single.children.single.type, BlockType.forward);

    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pump();
    expect(cubit.state.main.single.count, 3);
  });

  testWidgets('a full repeat block wraps its blocks instead of overflowing', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(BlockType.repeat);
    final loop = cubit.state.main.single.id;
    for (var i = 0; i < 8; i++) {
      cubit.add(BlockType.forward, parentId: loop);
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
      ..add(BlockType.repeat);
    final loop = cubit.state.main.single.id;
    cubit.add(BlockType.forward, parentId: loop);
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
      BlockType.forward,
      BlockType.turnLeft,
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
      BlockType.forward,
      BlockType.turnRight,
    ]);
    expect(cubit.state.main.single.type, BlockType.star);
    expect(cubit.program.procedure, hasLength(2));
  });

  testWidgets('a hand shows how to add a block until there is one', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester, showHowTo: true);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);

    await tester.tap(paletteBlock(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(cubit.state.main, hasLength(1));
    expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
  });

  testWidgets('no hand without showHowTo', (tester) async {
    await pumpEditor(tester);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
  });
}
