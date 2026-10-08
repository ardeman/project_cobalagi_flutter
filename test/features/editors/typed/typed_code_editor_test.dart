import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/world/direction.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/blocks/view/block_editor.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:cobalagi/features/editors/typed/cubit/typed_code_cubit.dart';
import 'package:cobalagi/features/editors/typed/view/typed_code_editor.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/play/view/play_view.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final level = Level.fromRows(
  id: 'test',
  concept: 'sequencing',
  rows: ['S.G'],
  startFacing: Direction.east,
  palette: {InstructionKind.move},
  maxBlocks: 2,
);
Widget app(Widget child, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  for (final code in [false, true]) {
    testWidgets(
      'Variables on a phone show the box and reset it after editing ($code)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final variables = Level.fromRows(
          id: 'v',
          concept: 'variables',
          rows: ['S..G'],
          startFacing: Direction.east,
          palette: const {InstructionKind.setSteps, InstructionKind.moveSteps},
          maxBlocks: 2,
        );
        await tester.pumpWidget(
          app(
            RepositoryProvider<AudioService>.value(
              value: const SilentAudioService(),
              child: PlayView(
                exercise: Exercise(
                  plan: const ExercisePlan(
                    conceptId: 'variables',
                    mode: ExerciseMode.replay,
                    difficulty: 1,
                  ),
                  level: variables,
                  key: 'variables',
                ),
                hintAfterRuns: 1,
                hintPulseAfterTries: 2,
                starsFor: (_) => 3,
                homePath: '/',
                onFinished: (_) async => null,
                onNext: () {},
                allowCode: true,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        // Phones show the island's emblem and a small box beside the world.
        expect(find.byTooltip('Step Box'), findsOneWidget);
        expect(find.bySemanticsLabel('Step Box: —'), findsOneWidget);
        if (code) {
          await tester.tap(find.byTooltip('Code'));
          await tester.pump();
          await tester.enterText(
            find.byKey(const Key('typedCodeSource')),
            'move(steps);',
          );
          await tester.pump();
          expect(
            find.textContaining('Save a number with steps'),
            findsOneWidget,
          );
          await tester.enterText(
            find.byKey(const Key('typedCodeSource')),
            'steps = 2;\nmove(steps);',
          );
          await tester.pump();
        } else {
          // Palette blocks; the box beside the world shares the picture.
          Finder palette(IconData icon) => find
              .descendant(
                of: find.byType(BlockEditor),
                matching: find.byIcon(icon),
              )
              .first;
          await tester.tap(palette(Icons.inventory_2_rounded));
          await tester.pump();
          await tester.tap(
            find
                .descendant(
                  of: find.byType(BlockEditor),
                  matching: find.byWidgetPredicate(
                    (w) => w is BlockTile && w.type == BlockType.moveSteps,
                  ),
                )
                .first,
          );
          await tester.pump();
        }
        await tester.tap(find.byTooltip('One step'));
        await tester.pump();
        expect(find.bySemanticsLabel('Step Box: 2'), findsOneWidget);
        await tester.tap(find.byTooltip('Start over'));
        await tester.pump();
        expect(find.bySemanticsLabel('Step Box: —'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in ['en', 'id']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'code editing fits a narrow phone in $locale at scale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final all = Level.fromRows(
            id: 'all',
            concept: 'conditions',
            rows: ['SG'],
            startFacing: Direction.east,
            palette: InstructionKind.values.toSet(),
          );
          final cubit = TypedCodeCubit(all);
          addTearDown(cubit.close);
          await tester.pumpWidget(
            app(
              BlocProvider.value(
                value: cubit,
                child: const Scaffold(body: TypedCodeEditor(enabled: true)),
              ),
              locale: locale,
              scale: scale,
            ),
          );
          await tester.enterText(
            find.byKey(const Key('typedCodeSource')),
            'repeat(2) {',
          );
          await tester.pump();
          expect(cubit.state.canRun, isFalse);
          expect(
            find.textContaining(locale == 'en' ? 'Line 1:' : 'Baris 1:'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.enterText(
            find.byKey(const Key('typedCodeSource')),
            'move();',
          );
          await tester.pump();
          expect(cubit.state.canRun, isTrue);
          final reference = find.textContaining('move();');
          await tester.ensureVisible(reference.last);
          await tester.tap(reference.last);
          await tester.pump();
          expect(cubit.state.program!.body.length, 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'phone keyboard leaves code usable and invalid source cannot run',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          RepositoryProvider<AudioService>.value(
            value: const SilentAudioService(),
            child: PlayView(
              exercise: Exercise(
                plan: const ExercisePlan(
                  conceptId: 'sequencing',
                  mode: ExerciseMode.replay,
                  difficulty: 1,
                ),
                level: level,
                key: 'phone',
              ),
              hintAfterRuns: 1,
              hintPulseAfterTries: 2,
              starsFor: (_) => 3,
              homePath: '/',
              onFinished: (_) async => null,
              onNext: () {},
              allowCode: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Code'));
      await tester.pump();
      final source = find.byKey(const Key('typedCodeSource'));
      await tester.enterText(source, 'turn_left();');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go!'))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Use the commands shown'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pump();
      expect(source, findsOneWidget);
      expect(find.text('Go!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.enterText(source, 'move();');
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Go!'))
            .onPressed,
        isNotNull,
      );
      expect(
        tester.getSize(find.byTooltip('Code')).height,
        greaterThanOrEqualTo(64),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'block draft seeds code; edits survive switching; code solves and records the same puzzle',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ExerciseResult? recorded;
      await tester.pumpWidget(
        app(
          RepositoryProvider<AudioService>.value(
            value: const SilentAudioService(),
            child: PlayView(
              exercise: Exercise(
                plan: const ExercisePlan(
                  conceptId: 'sequencing',
                  mode: ExerciseMode.replay,
                  difficulty: 1,
                ),
                level: level,
                key: 'test',
              ),
              hintAfterRuns: 1,
              hintPulseAfterTries: 2,
              starsFor: (_) => 3,
              homePath: '/',
              onFinished: (result) async {
                recorded = result;
                return null;
              },
              onNext: () {},
              allowCode: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded).first);
      await tester.pump();
      await tester.tap(find.text('Code'));
      await tester.pump();
      final source = find.byKey(const Key('typedCodeSource'));
      expect(tester.widget<TextField>(source).controller!.text, 'move();\n');
      await tester.enterText(source, 'move();\nmove();');
      await tester.pump();
      await tester.tap(find.text('Blocks'));
      await tester.pump();
      // The palette block and the one the code put back.
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(2));
      await tester.tap(find.text('Code'));
      await tester.pump();
      expect(
        tester.widget<TextField>(source).controller!.text,
        'move();\nmove();',
      );
      await tester.tap(find.byTooltip('One step'));
      await tester.pump();
      expect(find.text('Running line 1'), findsOneWidget);
      expect(tester.widget<TextField>(source).readOnly, isTrue);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Go!'));
      for (var i = 0; i < 30 && recorded == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(recorded?.succeeded, isTrue);
      expect(recorded?.mode, ExerciseMode.replay);
      expect(recorded?.runs, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
