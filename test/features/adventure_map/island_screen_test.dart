import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/adventure_map/view/island_screen.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
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
    // Lessons 2-5 haven't been played yet.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Directions'), findsOneWidget, reason: 'locked: no-op');

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('replay directions-01'), findsOneWidget);
  });
}
