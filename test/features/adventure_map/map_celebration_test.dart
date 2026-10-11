import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/adventure_map/view/adventure_map_screen.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:cobalagi/learning/exercise_result.dart';
import 'package:cobalagi/learning/learning_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
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
      // Play well until a new island opens.
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
