import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/features/learning/cubit/learning_cubit.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/pretest/view/pretest_screen.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Audio that stays "playing" until the test calls [finish].
class HeldAudio implements AudioService {
  final played = <String>[];
  Completer<void> _idle = Completer<void>();

  void finish() {
    if (!_idle.isCompleted) _idle.complete();
  }

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async {
    played.add(clipId);
    if (_idle.isCompleted) _idle = Completer<void>();
  }

  @override
  Future<void> whenIdle() => _idle.future;

  @override
  void playEffect(SoundEffect effect) {}

  @override
  bool effectsOn = true;

  @override
  bool musicOn = false;

  @override
  set foreground(bool visible) {}

  @override
  Future<void> dispose() async {}
}

Future<LearningCubit> pumpPretest(
  WidgetTester tester,
  AudioService audio, {
  Size physicalSize = const Size(2560, 1600),
  double pixelRatio = 2,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = pixelRatio;
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
      value: audio,
      child: BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const PretestScreen(profileId: 1),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  testWidgets('waits for the voice to finish before the next question', (
    tester,
  ) async {
    final audio = HeldAudio();
    await pumpPretest(tester, audio);
    final firstPrompt = find.text('Which picture matches the words?');
    expect(firstPrompt, findsOneWidget);

    await tester.tap(find.byType(Card).first);
    await tester.pump();
    // Well past the minimum display time, but the voice is still speaking.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(firstPrompt, findsNothing, reason: 'still showing feedback');

    final spokenBefore = audio.played.length;
    audio.finish();
    await tester.pump();
    // The cross-fade to the next question starts on the next frame.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(audio.played.length, spokenBefore + 1, reason: 'next prompt spoken');
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('a stuck clip cannot freeze the game', (tester) async {
    final audio = HeldAudio();
    await pumpPretest(tester, audio);
    await tester.tap(find.byType(Card).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

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
      // 3 levels per skill plus one second chance each.
      expect(answered, lessThan(20), reason: 'at most 20 questions');
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

  testWidgets('a phone held sideways shows every answer without scrolling', (
    tester,
  ) async {
    final audio = HeldAudio();
    await pumpPretest(
      tester,
      audio,
      physicalSize: const Size(840, 380),
      pixelRatio: 1,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final answers = find.descendant(
      of: find.byType(QuestionView),
      matching: find.byType(InkWell),
    );
    expect(answers, findsWidgets);
    for (final answer in answers.evaluate()) {
      final rect = tester.getRect(find.byElementPredicate((e) => e == answer));
      expect(rect.bottom, lessThanOrEqualTo(380));
      expect(rect.shortestSide, greaterThanOrEqualTo(64));
    }
    expect(tester.takeException(), isNull);
    audio.finish();
  });
}
