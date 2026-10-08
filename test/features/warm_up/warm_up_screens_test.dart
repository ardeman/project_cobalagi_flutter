import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/warm_up/view/warm_up_game_screen.dart';
import 'package:cobalagi/features/warm_up/view/warm_up_island_screen.dart';
import 'package:cobalagi/learning/warm_up/warm_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

Future<LearningCubit> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final (curriculum, progress) = (await tester.runAsync(() async {
    final db = await newDatabaseFactoryMemory().openDatabase('t.db');
    return (await CurriculumRepository().load(), ProgressRepository(db));
  }))!;
  final cubit = LearningCubit(
    profileId: 1,
    curriculum: curriculum,
    progress: progress,
  );
  addTearDown(cubit.close);
  await tester.runAsync(cubit.load);
  await tester.pumpWidget(
    RepositoryProvider<AudioService>.value(
      value: const SilentAudioService(),
      child: BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  testWidgets('the island shows every game with its stars', (tester) async {
    final cubit = await pumpScreen(
      tester,
      const WarmUpIslandScreen(profileId: 1),
    );
    expect(cubit.curriculum.warmUp.games, hasLength(6));
    for (final name in ['Counting', 'Colours', 'Shapes', 'Patterns']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('a round ends with play again, which starts a new one', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const WarmUpGameScreen(profileId: 1, game: WarmUpGame.colors),
    );
    for (var i = 0; i < 5; i++) {
      expect(find.text('Play again'), findsNothing);
      await tester.tap(find.byType(Card).first);
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Play again'), findsOneWidget);

    await tester.tap(find.text('Play again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Play again'), findsNothing);
    expect(find.textContaining('Tap the'), findsOneWidget);
  });

  testWidgets('a finished round saves the best level, never the path', (
    tester,
  ) async {
    final cubit = await pumpScreen(tester, const SizedBox());
    final before = cubit.state.learner!;
    final round = cubit.startWarmUp(WarmUpGame.shapes);
    while (!round.isFinished) {
      round.answer(round.current!.correct);
    }
    await tester.runAsync(() => cubit.recordWarmUp(round));
    final after = cubit.state.learner!;
    expect(after.warmUp, {'shapes': 3});
    expect(after.currentConcept, before.currentConcept);
    expect(after.progress, before.progress);

    // A weaker round later keeps the stars.
    final easy = cubit.startWarmUp(WarmUpGame.shapes);
    expect(easy.current!.level, 3, reason: 'starts at the best level');
    while (!easy.isFinished) {
      easy.answer((easy.current!.correct + 1) % easy.current!.optionCount);
    }
    await tester.runAsync(() => cubit.recordWarmUp(easy));
    expect(cubit.state.learner!.warmUp, {'shapes': 3});
  });

  testWidgets('a game opened before progress loads waits for it', (
    tester,
  ) async {
    final (curriculum, progress) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      return (await CurriculumRepository().load(), ProgressRepository(db));
    }))!;
    final cubit = LearningCubit(
      profileId: 1,
      curriculum: curriculum,
      progress: progress,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const WarmUpGameScreen(profileId: 1, game: WarmUpGame.colors),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.runAsync(cubit.load);
    await tester.pump();
    expect(find.textContaining('Tap the'), findsOneWidget);
  });

  for (final size in const [Size(2560, 1600), Size(1080, 2400)]) {
    testWidgets('the pictures stay put when the child answers ($size)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const WarmUpGameScreen(profileId: 1, game: WarmUpGame.counting),
      );
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = size.width > 2000 ? 2 : 2.625;
      await tester.pumpAndSettle();
      final cards = find.byType(Card);
      final before = [
        for (final c in cards.evaluate())
          tester.getRect(find.byWidget(c.widget)),
      ];
      // A wrong answer shows the most: the label under the right card.
      await tester.tap(cards.first);
      // Past the cross-fade (250 ms), well within the feedback time.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final after = [
        for (final c in cards.evaluate())
          tester.getRect(find.byWidget(c.widget)),
      ];
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(
          after[i].center.dy,
          moreOrLessEquals(before[i].center.dy, epsilon: 1),
        );
        expect(
          after[i].center.dx,
          moreOrLessEquals(before[i].center.dx, epsilon: 1),
        );
      }
      // Let the feedback finish.
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
