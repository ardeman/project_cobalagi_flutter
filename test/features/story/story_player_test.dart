import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:cobalagi/features/story/view/intro_scene.dart';
import 'package:cobalagi/features/story/view/story_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the clips asked for; each one ends at once.
class _Voices extends SilentAudioService {
  _Voices();

  final said = <String>[];
  final heard = <SoundEffect>[];

  @override
  void playEffect(SoundEffect effect) => heard.add(effect);

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async => said.add(clipId);
}

Future<void> _pump(
  WidgetTester tester,
  AudioService audio,
  VoidCallback onDone, {
  bool still = false,
}) async {
  tester.view.physicalSize = const Size(2400, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepositoryProvider<AudioService>.value(
      value: audio,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(1200, 800),
            disableAnimations: still,
          ),
          child: StoryPlayer(scene: const IntroScene(), onDone: onDone),
        ),
      ),
    ),
  );
}

void main() {
  const scene = IntroScene();

  test('every line of the intro has a voice clip with a speaker', () {
    for (final beat in scene.beats) {
      expect(VoiceClips.all, contains(beat.clip));
      expect(() => VoiceClips.speakerOf(beat.clip), returnsNormally);
    }
  });

  testWidgets('the ship and the wind are heard as the intro shows them', (
    tester,
  ) async {
    final audio = _Voices();
    await _pump(tester, audio, () {});
    await tester.pump();
    for (final beat in scene.beats) {
      await tester.pump(beat.length);
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
      audio.heard.where(
        (e) => const [
          SoundEffect.shipFly,
          SoundEffect.wind,
          SoundEffect.shipLand,
        ].contains(e),
      ),
      [SoundEffect.shipFly, SoundEffect.wind, SoundEffect.shipLand],
    );
  });

  for (final still in [false, true]) {
    testWidgets('plays every line in order, then offers to go on '
        '(${still ? 'reduced motion' : 'moving'})', (tester) async {
      final audio = _Voices();
      var done = 0;
      await _pump(tester, audio, () => done++, still: still);
      await tester.pump();
      for (final beat in scene.beats) {
        expect(audio.said.last, beat.clip);
        await tester.pump(beat.length);
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(audio.said, [for (final b in scene.beats) b.clip]);
      await tester.pumpAndSettle();
      expect(find.text("Let's play!"), findsOneWidget);
      await tester.tap(find.text("Let's play!"));
      expect(done, 1);
    });
  }

  testWidgets('shows each line under the scene', (tester) async {
    await _pump(tester, _Voices(), () {});
    await tester.pump();
    expect(
      find.text("This is Koba's star ship. It flies on stars!"),
      findsOneWidget,
    );
  });

  testWidgets('Skip leaves at once', (tester) async {
    var done = 0;
    await _pump(tester, _Voices(), () => done++);
    await tester.pump();
    await tester.tap(find.text('Skip'));
    expect(done, 1);
  });

  testWidgets('Watch again starts from the first line', (tester) async {
    final audio = _Voices();
    await _pump(tester, audio, () {});
    await tester.pump();
    for (final beat in scene.beats) {
      await tester.pump(beat.length);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    audio.said.clear();
    await tester.tap(find.text('Watch again'));
    await tester.pump();
    expect(audio.said, [scene.beats.first.clip]);
  });
}
