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
          exercise: Exercise(
            plan: const ExercisePlan(
              conceptId: 'sequencing',
              mode: ExerciseMode.replay,
              difficulty: 1,
            ),
            level: level ?? _level,
            key: 'phone',
          ),
          skipAfterRuns: 3,
          homePath: '/',
          onFinished: (_) async => null,
          onNext: () {},
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
}
