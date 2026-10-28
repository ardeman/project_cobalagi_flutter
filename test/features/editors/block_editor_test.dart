import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/program_json.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
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
  BlocksCubit? blocks,
  String? activeBlockId,
  String? activeCallId,
}) async {
  final cubit = blocks ?? BlocksCubit(maxBlocks: maxBlocks);
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
              activeBlockId: activeBlockId,
              activeCallId: activeCallId,
            ),
          ),
        ),
      ),
    ),
  );
  return cubit;
}

Finder paletteBlock(IconData icon) => find.byIcon(icon).first;

/// Where to hold a dragged block so its centre, which picks the drop spot,
/// is at [spot]: the block floats just above the finger.
Offset holdFor(Offset spot) => spot + const Offset(0, 64 * 1.1 * 0.35);

void main() {
  testWidgets('the running Magic Block call lights up with its blocks', (
    tester,
  ) async {
    final cubit = BlocksCubit()
      ..add(BlockType.forward, parentId: BlocksCubit.starRow)
      ..add(BlockType.star)
      ..add(BlockType.star);
    final body = cubit.state.star.single.id;
    final [first, second] = cubit.state.main.map((b) => b.id).toList();
    await pumpEditor(
      tester,
      star: true,
      blocks: cubit,
      activeBlockId: body,
      activeCallId: first,
    );
    bool lit(String id) => tester
        .widget<BlockTile>(
          find
              .descendant(
                of: find.byKey(ValueKey(id)),
                matching: find.byType(BlockTile),
                matchRoot: true,
              )
              .first,
        )
        .highlighted;
    expect(lit(body), isTrue);
    expect(lit(first), isTrue);
    expect(lit(second), isFalse);
  });

  testWidgets('a full star row leaves the main program room on a tablet', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester, star: true);
    // A long Magic Block: far more than fits beside the program.
    for (var i = 0; i < 16; i++) {
      cubit.add(BlockType.forward, parentId: BlocksCubit.starRow);
    }
    // Two rows of the main program.
    for (var i = 0; i < 10; i++) {
      cubit.add(i.isEven ? BlockType.star : BlockType.forward);
    }
    await tester.pumpAndSettle();
    final last = find.byKey(ValueKey(cubit.state.main.last.id)).first;
    final view = tester.getRect(
      find.ancestor(of: last, matching: find.byType(Scrollable)).first,
    );
    // Both rows show without scrolling the program.
    expect(view.contains(tester.getRect(last).bottomRight), isTrue);
    expect(view.height, greaterThanOrEqualTo(64 * 2));
    expect(tester.takeException(), isNull);
  });

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
    // "Use steps": the Step Box with an arrow.
    await tester.tap(
      find
          .byWidgetPredicate(
            (w) => w is BlockTile && w.type == BlockType.moveSteps,
          )
          .first,
    );
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

  testWidgets('in a scrolling page, space scrolls; a block drags at once', (
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
    // A swipe beside the blocks scrolls the page.
    final beside = Offset(397, tester.getCenter(repeat).dy);
    await tester.dragFrom(beside, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(scroll.offset, lessThan(start));
    expect(cubit.state.main, program.main);

    // So does a swipe on the repeat itself, away from its tile: a repeat
    // can fill the program area. Only its tile drags it.
    await tester.ensureVisible(repeat);
    await tester.pumpAndSettle();
    final onRepeat = scroll.offset;
    await tester.dragFrom(
      tester.getRect(repeat).bottomRight - const Offset(6, 6),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();
    expect(scroll.offset, lessThan(onRepeat));
    expect(cubit.state.main, program.main);

    // A block drags at once, and held near the top it scrolls the page up
    // to the palette, where it is removed.
    final last = find.byKey(ValueKey(cubit.state.main.last.id));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    final before = scroll.offset;
    final gesture = await tester.startGesture(tester.getCenter(last));
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveTo(const Offset(200, 40));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(scroll.offset, lessThan(before), reason: 'scrolls at the edge');
    await tester.ensureVisible(find.byIcon(Icons.arrow_upward_rounded).first);
    await gesture.moveTo(
      holdFor(tester.getCenter(find.byIcon(Icons.arrow_upward_rounded).first)),
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

  testWidgets(
    'a full program is fixed by tapping a block, then the right one',
    (tester) async {
      final cubit = BlocksCubit(
        maxBlocks: 3,
        start: programFromJson(['move', 'turnLeft', 'move']),
      );
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
                  palette: const {
                    InstructionKind.move,
                    InstructionKind.turnLeft,
                    InstructionKind.turnRight,
                  },
                  blockSize: 64,
                ),
              ),
            ),
          ),
        ),
      );
      // At the limit, the palette rests.
      await tester.tap(paletteBlock(Icons.turn_right_rounded));
      await tester.pump();
      expect(cubit.state.main.map((b) => b.type), [
        BlockType.forward,
        BlockType.turnLeft,
        BlockType.forward,
      ]);
      // Tap the wrong turn in the program, then the right one.
      await tester.tap(find.byIcon(Icons.turn_left_rounded).last);
      await tester.pump();
      expect(find.byTooltip('Remove this block'), findsOneWidget);
      await tester.tap(paletteBlock(Icons.turn_right_rounded));
      await tester.pump();
      expect(cubit.state.main.map((b) => b.type), [
        BlockType.forward,
        BlockType.turnRight,
        BlockType.forward,
      ]);
      expect(find.byTooltip('Remove all blocks'), findsOneWidget);
      // Pick a block and remove only it.
      await tester.tap(find.byIcon(Icons.turn_right_rounded).last);
      await tester.pump();
      await tester.tap(find.byTooltip('Remove this block'));
      await tester.pump();
      expect(cubit.state.main.map((b) => b.type), [
        BlockType.forward,
        BlockType.forward,
      ]);
    },
  );

  testWidgets('each use-steps block shows the number it will use', (
    tester,
  ) async {
    final cubit = BlocksCubit(
      start: programFromJson([
        'moveSteps',
        {'setSteps': 3},
        'moveSteps',
        'turnRight',
        'moveSteps',
        {'setSteps': 2},
        'moveSteps',
      ]),
    );
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
                InstructionKind.turnRight,
              },
              blockSize: 64,
            ),
          ),
        ),
      ),
    );
    final uses = [
      for (final b in cubit.state.main)
        if (b.type == BlockType.moveSteps) b.id,
    ];
    String? bubble(String id) =>
        tester.widget<BlockTile>(find.byKey(ValueKey(id))).stepValue;
    expect([for (final id in uses) bubble(id)], ['?', '3', '3', '2']);
    // Screen readers hear the number too.
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^Use steps: 3')), findsNWidgets(2));
    semantics.dispose();
    // The palette block has no number.
    expect(
      tester
          .widgetList<BlockTile>(find.byType(BlockTile))
          .where((t) => t.type == BlockType.moveSteps && t.stepValue == null),
      hasLength(1),
    );
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
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveTo(
        tester.getCenter(paletteBlock(Icons.arrow_upward_rounded)),
      );
      await gesture.up();
      await tester.pump();
      expect(cubit.state.main.single.type, BlockType.forward);
    });
  }

  testWidgets('on a tablet, a swipe beside the blocks scrolls the program', (
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
    // Swipe up in the space at the end of a line of blocks.
    final area = tester.getRect(find.byType(SingleChildScrollView).last);
    await tester.dragFrom(
      area.centerRight - const Offset(10, 0),
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

  testWidgets('a see-through copy shows where a dragged block will land', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(BlockType.forward)
      ..add(BlockType.turnRight);
    await tester.pump();
    final forward = find.byIcon(Icons.arrow_upward_rounded).last;
    final start = tester.getCenter(paletteBlock(Icons.turn_left_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 30));
    expect(find.byKey(const ValueKey('dropGhost')), findsNothing);
    // The right half of a block: the new one goes after it.
    await gesture.moveTo(
      holdFor(tester.getCenter(forward) + const Offset(20, 0)),
    );
    await tester.pump();
    final ghost = find.byKey(const ValueKey('dropGhost'));
    expect(ghost, findsOneWidget);
    expect(
      tester.getCenter(ghost).dx,
      greaterThan(tester.getCenter(forward).dx),
    );
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.turnLeft,
      BlockType.turnRight,
    ]);
    expect(find.byKey(const ValueKey('dropGhost')), findsNothing);
  });

  for (final above in [true, false]) {
    testWidgets('a block drops ${above ? 'before' : 'after'} a wide repeat', (
      tester,
    ) async {
      final cubit = await pumpEditor(tester)
        ..add(BlockType.repeat);
      final loop = cubit.state.main.single.id;
      cubit.add(BlockType.forward, parentId: loop);
      await tester.pump();
      final box = tester.getRect(find.byKey(ValueKey(loop)));
      final start = tester.getCenter(paletteBlock(Icons.turn_left_rounded));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 30));
      // The repeat's edge, outside the row that holds its own blocks.
      await gesture.moveTo(
        holdFor(
          above
              ? box.topLeft + const Offset(40, 4)
              : box.bottomLeft + const Offset(40, -4),
        ),
      );
      await tester.pump();
      final ghost = tester.getRect(find.byKey(const ValueKey('dropGhost')));
      final moved = tester.getRect(find.byKey(ValueKey(loop)));
      // The copy comes before or after the repeat, in reading order.
      if (above) {
        expect(ghost.right <= moved.left || ghost.bottom <= moved.top, isTrue);
      } else {
        expect(ghost.left >= moved.right || ghost.top >= moved.bottom, isTrue);
      }
      expect(moved.width, box.width, reason: 'not squeezed by the ghost');
      await gesture.up();
      await tester.pump();
      expect(cubit.state.main.map((b) => b.type), [
        if (above) BlockType.turnLeft,
        BlockType.repeat,
        if (!above) BlockType.turnLeft,
      ]);
      expect(cubit.state.main[above ? 1 : 0].children, hasLength(1));
    });
  }

  testWidgets('a gap between blocks drops there, and the copy holds still', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(BlockType.forward)
      ..add(BlockType.turnRight)
      ..add(BlockType.forward);
    await tester.pump();
    final first = tester.getRect(find.byIcon(Icons.arrow_upward_rounded).at(1));
    final gesture = await tester.startGesture(
      tester.getCenter(paletteBlock(Icons.turn_left_rounded)),
    );
    await gesture.moveBy(const Offset(0, 30));
    // Just right of the first block, in the gap: not the end of the program.
    await gesture.moveTo(holdFor(first.centerRight + const Offset(4, 0)));
    await tester.pump();
    final ghost = find.byKey(const ValueKey('dropGhost'));
    final spot = tester.getRect(ghost);
    // Resting on the copy keeps it where it is.
    await gesture.moveTo(holdFor(spot.center));
    await tester.pump();
    expect(tester.getRect(ghost), spot);
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.turnLeft,
      BlockType.turnRight,
      BlockType.forward,
    ]);
  });

  testWidgets('lifting a placed block shows no drop spot until it moves', (
    tester,
  ) async {
    final cubit = await pumpEditor(tester)
      ..add(BlockType.forward)
      ..add(BlockType.turnLeft);
    await tester.pump();
    final placed = find.byIcon(Icons.arrow_upward_rounded).last;
    final gesture = await tester.startGesture(
      tester.getCenter(placed),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(5, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('dropGhost')), findsNothing);
    await gesture.up();
    await tester.pump();
    expect(cubit.state.main.map((b) => b.type), [
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
