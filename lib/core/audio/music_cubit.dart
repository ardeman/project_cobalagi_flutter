import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings/settings_repository.dart';
import 'audio_service.dart';

/// Whether background music is on: a parent setting, applied to
/// [AudioService].
class MusicCubit extends Cubit<bool> {
  MusicCubit(this._settings, this._audio) : super(true);

  final SettingsRepository _settings;
  final AudioService _audio;

  Future<void> load() async => _apply(await _settings.loadMusic());

  Future<void> set({required bool on}) async {
    await _settings.saveMusic(on);
    _apply(on);
  }

  void _apply(bool on) {
    _audio.musicOn = on;
    emit(on);
  }
}
