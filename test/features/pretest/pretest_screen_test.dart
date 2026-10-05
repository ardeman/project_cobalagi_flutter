import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/pretest/view/pretest_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('playing the warm-up game to the end places the child', (
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
    await tester.runAsync(cubit.load);

    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PretestScreen(profileId: 1),
          ),
        ),
      ),
    );
    await tester.pump();

    var answered = 0;
    while (find.text("Let's go!").evaluate().isEmpty) {
      expect(answered, lessThan(15), reason: 'at most 15 questions');
      await tester.tap(find.byType(Card).first);
      // Feedback stays up to 2.6 s after a wrong answer.
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 400));
      answered++;
    }
    expect(answered, greaterThanOrEqualTo(5));
    expect(cubit.state.learner!.placement, isNotNull);
  });
}
