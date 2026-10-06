// Runs the real app (real audio) through the warm-up game and checks that
// after a wrong answer "Jawabannya yang ini!" plays to the end before the
// next question's prompt starts.
//
//   flutter test integration_test/pretest_voice_test.dart -d macos
import 'package:cobalagi/app/app.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:cobalagi/features/learning/data/curriculum_repository.dart';
import 'package:cobalagi/features/learning/data/progress_repository.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Real audio, with a log of when each clip was requested and when the
/// player reported everything finished.
class RecordingAudio implements AudioService {
  RecordingAudio(this._inner);

  final AudioService _inner;
  final log = <({String event, String clip, DateTime at})>[];

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) {
    log.add((
      event: queue ? 'queue' : 'play',
      clip: clipId,
      at: DateTime.now(),
    ));
    return _inner.playVoice(clipId, languageCode: languageCode, queue: queue);
  }

  @override
  Future<void> whenIdle() => _inner.whenIdle().then(
    (_) => log.add((event: 'idle', clip: '', at: DateTime.now())),
  );

  @override
  void playEffect(SoundEffect effect) => _inner.playEffect(effect);

  @override
  bool get effectsOn => _inner.effectsOn;

  @override
  set effectsOn(bool on) => _inner.effectsOn = on;

  @override
  Future<void> dispose() => _inner.dispose();
}

Future<void> waitFor(
  WidgetTester tester,
  bool Function() done, {
  required String step,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) {
      final texts = [
        for (final e in find.byType(Text).evaluate())
          (e.widget as Text).data ?? '',
      ].where((t) => t.isNotEmpty).take(12);
      fail('timed out waiting for: $step. On screen: $texts');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the right-answer clip plays to the end before moving on', (
    tester,
  ) async {
    final db = await newDatabaseFactoryMemory().openDatabase('it.db');
    final settings = SettingsRepository(db);
    await settings.saveLanguageCode('id');
    final audio = RecordingAudio(AudioplayersAudioService());
    await tester.pumpWidget(
      CobaLagiApp(
        profiles: ProfileRepository(db),
        settings: settings,
        entitlement: const StaticEntitlementService(Plan.free),
        audio: audio,
        curriculum: CurriculumRepository(),
        progress: ProgressRepository(db),
      ),
    );
    await waitFor(
      tester,
      () => find.text('Pemain baru').evaluate().isNotEmpty,
      step: 'profiles screen',
    );

    // Add a player and open the warm-up game.
    await tester.tap(find.text('Pemain baru'));
    await waitFor(
      tester,
      () => find.byType(TextField).evaluate().isNotEmpty,
      step: 'new player dialog',
    );
    await tester.enterText(find.byType(TextField), 'Uji');
    await tester.tap(find.text('Simpan'));
    await waitFor(
      tester,
      () => find.text('Uji').evaluate().isNotEmpty,
      step: 'player tile',
    );
    // Let the dialog finish closing, or its barrier swallows the tap.
    await waitFor(
      tester,
      () => find.byType(TextField).evaluate().isEmpty,
      step: 'dialog closed',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uji'));
    await waitFor(
      tester,
      () => find.text('Mulai').evaluate().isNotEmpty,
      step: 'warm-up welcome',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai'));

    final answerWas = find.text('Jawabannya yang ini!');
    final check = find.byIcon(Icons.check_rounded);
    var wrongFound = false;
    for (var attempt = 0; attempt < 15 && !wrongFound; attempt++) {
      final cards = find.descendant(
        of: find.byType(QuestionView),
        matching: find.byType(InkWell),
      );
      await waitFor(
        tester,
        () => cards.evaluate().isNotEmpty,
        step: 'a question',
      );
      // Let the question finish sliding in, so the tap lands on the card.
      await tester.pumpAndSettle();
      await tester.tap(cards.at(attempt % cards.evaluate().length));
      await waitFor(
        tester,
        () => check.evaluate().isNotEmpty,
        step: 'answer feedback',
      );
      wrongFound = answerWas.evaluate().isNotEmpty;
      // Wait for this question's feedback to end before the next tap.
      await waitFor(
        tester,
        () => check.evaluate().isEmpty,
        step: 'next question',
      );
    }
    expect(wrongFound, isTrue, reason: 'no wrong answer within 15 taps');

    // The last "Jawabannya yang ini!" request, then what happened after it.
    final i = audio.log.lastIndexWhere(
      (e) => e.clip == VoiceClips.pretestAnswerWas,
    );
    final after = audio.log.sublist(i + 1);
    final idle = after.firstWhere((e) => e.event == 'idle');
    final nextPrompt = after.firstWhere((e) => e.event == 'play');
    final asked = audio.log[i].at;
    final spoken = idle.at.difference(asked);
    final untilNext = nextPrompt.at.difference(asked);
    // ignore: avoid_print
    print(
      'answer clip queued → audio finished: ${spoken.inMilliseconds} ms; '
      '→ next prompt "${nextPrompt.clip}": ${untilNext.inMilliseconds} ms',
    );
    // The clip is 1.84 s long and queued after the cheer, so finishing
    // sooner would mean it was cut off or skipped.
    expect(spoken, greaterThan(const Duration(milliseconds: 1700)));
    expect(
      nextPrompt.at.isBefore(idle.at),
      isFalse,
      reason: 'the next prompt must not start while the clip is playing',
    );

    // Unmounting the app disposes the players, whose position updater
    // otherwise keeps ticking after the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
