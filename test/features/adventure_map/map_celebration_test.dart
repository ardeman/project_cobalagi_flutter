import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/adventure_map/view/adventure_map_screen.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/story/data/story_art.dart';
import 'package:cobalagi/features/story/view/ship_flight.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Plays well until a new island opens.
Future<void> _playUntilAdvance(LearningCubit learning) async {
  Decision? decision;
  while (decision is! Advance) {
    final e = learning.nextExercise();
    decision = await learning.record(
      ExerciseResult(
        conceptId: e.plan.conceptId,
        levelId: e.level.id,
        mode: e.plan.mode,
        difficulty: e.plan.difficulty,
        succeeded: true,
        runs: 1,
        hintsUsed: 0,
        duration: const Duration(seconds: 10),
      ),
    );
  }
}

void main() {
  testWidgets('a planet opened under another screen flies once, on top', (
    tester,
  ) async {
    // The ship's pictures, loaded for real before the map's parked ship asks
    // for them, so the flight takes off and lands.
    await tester.runAsync(StoryArt.load);
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (profiles, learning) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      final profiles = ProfilesCubit(ProfileRepository(db));
      await profiles.load();
      final profile = await profiles.add(
        nickname: 'Ayu',
        avatar: 0,
        maxProfiles: 1,
      );
      final learning = LearningCubit(
        profileId: profile!.id,
        curriculum: await CurriculumRepository().load(),
        progress: ProgressRepository(db),
      );
      await learning.load();
      // Past the first warm-up, so the map shows its planets.
      await learning.completePretest(const {});
      return (profiles, learning);
    }))!;
    addTearDown(profiles.close);
    addTearDown(learning.close);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: profiles),
            BlocProvider.value(value: learning),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdventureMapScreen(profileId: learning.profileId),
          ),
        ),
      ),
    );
    await tester.pump();

    // The puzzle that opens a planet is solved on a screen over the map.
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => _playUntilAdvance(learning));
    await tester.pump();
    expect(find.byType(ShipFlight, skipOffstage: false), findsNothing);

    navigator.currentState!.pop();
    await tester.pump();
    // The loaded pictures reach the flight on the real event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final flight = tester.state(find.byType(ShipFlight));
    // Past landing, the same flight is still there: none starts again.
    for (var t = 0; t < 70; t++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ShipFlight).evaluate().isEmpty) break;
      expect(tester.state(find.byType(ShipFlight)), same(flight));
    }
    await tester.pump(const Duration(seconds: 3));
    expect(learning.state.islandToCelebrate, isNull);
    expect(find.byType(ShipFlight), findsNothing);
  });

  testWidgets('leaving the map early still counts the new island as seen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (profiles, learning) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      final profiles = ProfilesCubit(ProfileRepository(db));
      await profiles.load();
      final profile = await profiles.add(
        nickname: 'Ayu',
        avatar: 0,
        maxProfiles: 1,
      );
      final learning = LearningCubit(
        profileId: profile!.id,
        curriculum: await CurriculumRepository().load(),
        progress: ProgressRepository(db),
      );
      await learning.load();
      await _playUntilAdvance(learning);
      return (profiles, learning);
    }))!;
    addTearDown(profiles.close);
    addTearDown(learning.close);
    expect(learning.state.islandToCelebrate, isNotNull);

    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: profiles),
            BlocProvider.value(value: learning),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdventureMapScreen(profileId: learning.profileId),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(learning.state.islandToCelebrate, isNotNull);
    // The child leaves before the celebration ends.
    await tester.pumpWidget(const SizedBox());
    expect(learning.state.islandToCelebrate, isNull);
  });
}
