import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/adventure_map/view/island_screen.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('played levels can be replayed; others stay locked', (
    tester,
  ) async {
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
    await tester.runAsync(() async {
      await cubit.load();
      // Play and solve the first Directions lesson.
      final exercise = cubit.nextExercise();
      await cubit.record(
        ExerciseResult(
          conceptId: exercise.plan.conceptId,
          levelId: exercise.level.id,
          mode: exercise.plan.mode,
          difficulty: 1,
          succeeded: true,
          runs: 1,
          hintsUsed: 0,
          duration: const Duration(seconds: 5),
        ),
      );
    });

    final router = GoRouter(
      initialLocation: '/child/1/island/directions',
      routes: [
        GoRoute(
          path: '/child/1/island/directions',
          builder: (_, _) =>
              const IslandScreen(profileId: 1, conceptId: 'directions'),
        ),
        GoRoute(
          path: '/child/1/replay/:levelId',
          builder: (_, state) =>
              Text('replay ${state.pathParameters['levelId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // Every lesson after the first hasn't been played yet.
    final lessons = cubit.curriculum.lessons['directions']!.length;
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(lessons - 1));
    // Solved on the first run without a hint: all three stars.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Directions'), findsOneWidget, reason: 'locked: no-op');

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('replay directions-01'), findsOneWidget);
  });

  testWidgets('a passed island opens every lesson and offers the next one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final (curriculum, progress) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      return (await CurriculumRepository().load(), ProgressRepository(db));
    }))!;
    // Moved on to Loops (say, a new starting point) with one Directions
    // lesson solved.
    await tester.runAsync(
      () => progress.save(
        1,
        const LearnerState(
          currentConcept: 'loops',
          progress: {
            'directions': ConceptProgress(
              difficulty: 1,
              attemptedLessons: {'directions-01'},
              solvedLessons: {'directions-01'},
            ),
          },
        ),
      ),
    );
    final cubit = LearningCubit(
      profileId: 1,
      curriculum: curriculum,
      progress: progress,
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);

    final router = GoRouter(
      initialLocation: '/child/1/island/directions',
      routes: [
        GoRoute(
          path: '/child/1/island/directions',
          builder: (_, _) =>
              const IslandScreen(profileId: 1, conceptId: 'directions'),
        ),
        GoRoute(
          path: '/child/1/replay/:levelId',
          builder: (_, state) =>
              Text('replay ${state.pathParameters['levelId']}'),
        ),
        GoRoute(path: '/child/1/play', builder: (_, _) => const Text('play')),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Continue the adventure'), findsOneWidget);
    await tester.tap(find.text('Play level 2'));
    await tester.pumpAndSettle();
    expect(find.text('replay directions-02'), findsOneWidget);
  });

  testWidgets('the trail has a circle for every puzzle left', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (curriculum, progress) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      return (await CurriculumRepository().load(), ProgressRepository(db));
    }))!;
    final lessons = curriculum.lessonIds['loops']!;
    // Every lesson solved, back from a bonus adventure: the count restarted.
    await tester.runAsync(
      () => progress.save(
        1,
        LearnerState(
          currentConcept: 'loops',
          progress: {
            'loops': ConceptProgress(
              difficulty: 1,
              exercises: 1,
              attemptedLessons: {...lessons},
              solvedLessons: {...lessons},
            ),
          },
        ),
      ),
    );
    final cubit = LearningCubit(
      profileId: 1,
      curriculum: curriculum,
      progress: progress,
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.load);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const IslandScreen(profileId: 1, conceptId: 'loops'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final left = curriculum.engine.config.practiceLimit - 1;
    expect(find.textContaining('Up to $left more puzzles'), findsOneWidget);
    final circles = find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.constraints == BoxConstraints.tight(const Size(22, 22)) &&
          (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
    );
    expect(circles, findsNWidgets(left));
  });
}
