import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/core/audio/sound_effects.dart';
import 'package:cobalagi/core/audio/sound_effects_cubit.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

class FakeAudio extends SilentAudioService {
  @override
  bool effectsOn = true;

  @override
  void playEffect(SoundEffect effect) {}
}

void main() {
  test(
    'effects are on by default, and turning them off is remembered',
    () async {
      final settings = SettingsRepository(
        await newDatabaseFactoryMemory().openDatabase('s.db'),
      );
      final audio = FakeAudio();
      final cubit = SoundEffectsCubit(settings, audio);
      await cubit.load();
      expect(cubit.state, isTrue);
      expect(audio.effectsOn, isTrue);

      await cubit.set(on: false);
      expect(audio.effectsOn, isFalse);

      final reopened = SoundEffectsCubit(settings, FakeAudio());
      await reopened.load();
      expect(reopened.state, isFalse);
    },
  );

  test('every sound effect has a prompt for the generator', () {
    final config =
        jsonDecode(File('tool/sound_effects.json').readAsStringSync())
            as Map<String, Object?>;
    final effects = config['effects']! as Map<String, Object?>;
    expect(effects.keys.toSet(), {for (final e in SoundEffect.values) e.name});
  });
}
