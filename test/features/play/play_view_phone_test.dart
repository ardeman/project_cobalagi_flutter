import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/features/editors/typed/view/typed_code_editor.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/play/view/play_view.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:flame/game.dart';
import 'package:cobalagi/core/widgets/paint_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _level = Level.fromRows(
  id: 'phone',
  concept: 'sequencing',
  rows: ['S.......G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move, InstructionKind.turnLeft},
  maxBlocks: 20,
);

Future<void> _pumpPhone(
  WidgetTester tester, {
  Size size = const Size(400, 760),
  Level? level,
  bool allowCode = true,
  int hintAfterRuns = 1,
  Decision? decision,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: PlayView(
          // A fresh puzzle for each decision a test tries.
          key: ValueKey(decision),
          exercise: Exercise(
            plan: const ExercisePlan(
              conceptId: 'sequencing',
              mode: ExerciseMode.replay,
              difficulty: 1,
            ),
            level: level ?? _level,
            key: 'phone',
          ),
          hintAfterRuns: hintAfterRuns,
          hintPulseAfterTries: 2,
          starsFor: (_) => 3,
          homePath: '/',
          onFinished: (_) async => decision,
          onNext: () {},
          allowCode: allowCode,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// The world keeps animating, so pump through a scroll instead of settling.
Future<void> _pumpScroll(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a phone keeps Go at the bottom and scrolls to the world on Go', (
    tester,
  ) async {
    await _pumpPhone(tester);
    final go = find.widgetWithText(FilledButton, 'Go!');
    // Go sits at the bottom of the screen, below the world and the editor.
    expect(tester.getRect(go).bottom, greaterThan(760 - 16 - 80));
    expect(
      tester
          .getRect(find.byWidgetPredicate((widget) => widget is GameWidget))
          .height,
      greaterThan(300),
    );

    final cubit = tester.element(find.byType(BlockEditor)).read<BlocksCubit>();
    for (var i = 0; i < 8; i++) {
      cubit.add(BlockType.forward);
    }
    for (var i = 0; i < 12; i++) {
      cubit.add(BlockType.turnLeft);
    }
    await _pumpScroll(tester);
    final page = find.byType(SingleChildScrollView).first;
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: page, matching: find.byType(Scrollable)).first,
        )
        .position;
    // Adding blocks scrolled down to show them, clear of the glass Go bar.
    expect(position.pixels, greaterThan(0));
    final newest = find.byKey(ValueKey(cubit.state.main.last.id)).first;
    expect(
      tester.getRect(newest).bottom,
      lessThanOrEqualTo(tester.getRect(go).top),
    );

    await tester.tap(go);
    await _pumpScroll(tester);
    expect(position.pixels, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone held sideways fits the world, Go and the editor', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      size: const Size(840, 380),
      level: Level.fromRows(
        id: 'sideways',
        concept: 'functions',
        rows: ['S..G'],
        startFacing: Direction.east,
        palette: {
          InstructionKind.move,
          InstructionKind.turnLeft,
          InstructionKind.turnRight,
          InstructionKind.call,
          InstructionKind.repeat,
          InstructionKind.ifPathClear,
        },
        maxBlocks: 12,
      ),
    );
    expect(tester.takeException(), isNull);
    final go = find.widgetWithText(FilledButton, 'Go!');
    expect(tester.getRect(go).bottom, lessThanOrEqualTo(380));
    // The world sits beside the editor and keeps a usable size.
    final world = tester.getRect(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    final editor = tester.getRect(find.byType(BlockEditor));
    expect(world.right, lessThan(editor.left));
    expect(world.height, greaterThan(150));
    // The editor scrolls on its own, with small blocks.
    expect(
      find.ancestor(
        of: find.byType(BlockEditor),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a tablet held upright stacks a large world over the editor', (
    tester,
  ) async {
    await _pumpPhone(tester, size: const Size(800, 1280));
    expect(tester.takeException(), isNull);
    final world = tester.getRect(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    final editor = tester.getRect(find.byType(BlockEditor));
    expect(world.bottom, lessThanOrEqualTo(editor.top));
    expect(world.width, greaterThan(700));
    expect(
      tester.getRect(find.widgetWithText(FilledButton, 'Go!')).bottom,
      greaterThan(1280 - 120),
    );
  });

  testWidgets('on a phone, code starts at the top of its panel', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await tester.tap(find.byTooltip('Code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final panel = tester.getRect(find.byType(TypedCodeEditor));
    final source = tester.getRect(find.byKey(const Key('typedCodeSource')));
    // No gap the size of the glass top bar above the code.
    expect(source.top - panel.top, lessThan(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'on a phone, the code field keeps focus when the keyboard opens',
    (tester) async {
      await _pumpPhone(tester);
      await tester.tap(find.byTooltip('Code'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('typedCodeSource')));
      await tester.pump();
      bool focused() => tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus;
      expect(focused(), isTrue);
      // The keyboard slides up and the layout gives the code the screen.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(focused(), isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      // The code gets the room: the world and Go step aside while typing.
      expect(find.text('Go!'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(400, 760), const Size(1280, 800)]) {
    testWidgets('the Code tab shows only when allowed ($size)', (tester) async {
      await _pumpPhone(tester, size: size, allowCode: false);
      expect(find.byTooltip('Code'), findsNothing);
      expect(find.text('Code'), findsNothing);
      expect(find.byType(BlockEditor), findsOneWidget);

      await _pumpPhone(tester, size: size);
      expect(
        find.byTooltip('Code').evaluate().isNotEmpty ||
            find.text('Code').evaluate().isNotEmpty,
        isTrue,
      );
    });
  }

  testWidgets('a Fix it! puzzle opens with its bugged blocks in place', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      size: const Size(1280, 800),
      level: Level.fromJson({
        'id': 'fix',
        'concept': 'debugging',
        'facing': 'east',
        'palette': ['move', 'turnLeft', 'turnRight'],
        'maxBlocks': 4,
        'starter': ['move', 'move', 'move'],
        'rows': ['#######', '#S...G#', '#######'],
      }),
    );
    final cubit = tester.element(find.byType(BlockEditor)).read<BlocksCubit>();
    expect(cubit.state.main.map((b) => b.type), [
      BlockType.forward,
      BlockType.forward,
      BlockType.forward,
    ]);
    // Go is ready at once: the child runs the bug before fixing it.
    final go = find.widgetWithText(FilledButton, 'Go!');
    expect(tester.widget<FilledButton>(go).onPressed, isNotNull);
    expect(
      find.byTooltip(
        "Listen again: Oops, these blocks aren't quite right yet! "
        'Press Go, watch what happens, then fix them.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'beside the editor, the world keeps its size when feedback shows',
    (tester) async {
      for (final size in const [Size(1280, 800), Size(800, 400)]) {
        await _pumpPhone(tester, size: size);
        final world = find.byWidgetPredicate((widget) => widget is GameWidget);
        final before = tester.getRect(world);
        // Three steps on an eight-step road: the run stops short.
        final cubit = tester
            .element(find.byType(BlockEditor))
            .read<BlocksCubit>();
        for (var i = 0; i < 3; i++) {
          cubit.add(BlockType.forward);
        }
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Go!'));
        for (
          var i = 0;
          i < 60 && find.text('Try again!').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Try again!'), findsOneWidget, reason: '$size');
        expect(tester.getRect(world), before, reason: '$size');
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('the hint bulb turns on, then pulses, after a few tries', (
    tester,
  ) async {
    await _pumpPhone(tester, size: const Size(1280, 800), hintAfterRuns: 3);
    IconButton bulb() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.lightbulb_rounded),
    );
    expect(bulb().onPressed, isNull, reason: 'a child tries first');
    tester
        .element(find.byType(BlockEditor))
        .read<BlocksCubit>()
        .add(BlockType.forward);
    await tester.pump();
    bool pulsing() => tester
        .widget<PaintTransition>(
          find
              .ancestor(
                of: find.widgetWithIcon(IconButton, Icons.lightbulb_rounded),
                matching: find.byType(PaintTransition),
              )
              .first,
        )
        .animation
        .isAnimating;
    for (var run = 1; run <= 5; run++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Go!'));
      for (
        var i = 0;
        i < 60 && find.text('Try again!').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The card replaces the controls; trying again brings them back.
      await tester.tap(find.text('Try again!'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(bulb().onPressed, run < 3 ? isNull : isNotNull, reason: '$run');
      // On after three tries; pulsing two tries later, while unused.
      expect(pulsing(), run >= 5, reason: '$run');
    }
  });

  testWidgets('a solved puzzle leads back to its island, or the map when '
      'the island is complete', (tester) async {
    for (final (decision, label) in [
      (const Practice('sequencing'), 'Back to the planet'),
      (const Advance('sequencing', 'loops'), 'To the map'),
    ]) {
      await _pumpPhone(tester, size: const Size(1280, 800), decision: decision);
      final cubit = tester
          .element(find.byType(BlockEditor))
          .read<BlocksCubit>();
      for (var i = 0; i < 8; i++) {
        cubit.add(BlockType.forward);
      }
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Go!'));
      for (var i = 0; i < 80 && find.text(label).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(label), findsOneWidget, reason: '$decision');
    }
  });
}
