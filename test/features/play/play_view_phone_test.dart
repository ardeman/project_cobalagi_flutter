import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/cubit/blocks_cubit.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
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

Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 760);
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
            level: _level,
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
}
