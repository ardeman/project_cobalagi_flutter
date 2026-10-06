import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings/settings_repository.dart';
import 'audio_service.dart';

/// Whether sound effects are on: a parent setting, applied to [AudioService].
class SoundEffectsCubit extends Cubit<bool> {
  SoundEffectsCubit(this._settings, this._audio) : super(true);

  final SettingsRepository _settings;
  final AudioService _audio;

  Future<void> load() async => _apply(await _settings.loadSoundEffects());

  Future<void> set({required bool on}) async {
    await _settings.saveSoundEffects(on);
    _apply(on);
  }

  void _apply(bool on) {
    _audio.effectsOn = on;
    emit(on);
  }
}
