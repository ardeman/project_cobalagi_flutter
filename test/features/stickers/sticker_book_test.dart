import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/stickers/view/sticker_book_screen.dart';
import 'package:cobalagi/features/stickers/view/sticker_view.dart';
import 'package:cobalagi/learning/learner_state.dart';
import 'package:cobalagi/learning/stickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('the book shows every sticker and marks new ones seen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (curriculum, progress) = (await tester.runAsync(() async {
      final db = await newDatabaseFactoryMemory().openDatabase('t.db');
      return (await CurriculumRepository().load(), ProgressRepository(db));
    }))!;
    final directions = curriculum.lessonIds['directions']!;
    await tester.runAsync(
      () => progress.save(
        1,
        LearnerState(
          currentConcept: 'sequencing',
          progress: {
            'directions': ConceptProgress(
              difficulty: 1,
              attemptedLessons: {...directions},
              solvedLessons: {...directions},
            ),
          },
          warmUp: const {'shapes': 3},
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
    expect(newStickers(cubit.state.learner!, cubit.stickers), {
      'directions',
      'warmup-shapes',
    });

    await tester.pumpWidget(
      RepositoryProvider<AudioService>.value(
        value: const SilentAudioService(),
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const StickerBookScreen(profileId: 1),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(
      find.byType(StickerView),
      findsNWidgets(cubit.stickers.length),
      reason: 'earned or not, every sticker has a place',
    );
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Shapes'), findsOneWidget);
    expect(cubit.state.learner!.stickersSeen, {'directions', 'warmup-shapes'});
    expect(newStickers(cubit.state.learner!, cubit.stickers), isEmpty);
  });
}
