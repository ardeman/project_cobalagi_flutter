import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_repository.dart';

/// Holds the locale override; null means follow the device.
class SettingsCubit extends Cubit<Locale?> {
  SettingsCubit(this._repository) : super(null);

  final SettingsRepository _repository;

  Future<void> load() async {
    final code = await _repository.loadLanguageCode();
    emit(code == null ? null : Locale(code));
  }

  Future<void> setLanguageCode(String? code) async {
    await _repository.saveLanguageCode(code);
    emit(code == null ? null : Locale(code));
  }
}
