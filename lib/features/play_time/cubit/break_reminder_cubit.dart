import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/settings/settings_repository.dart';

/// Minutes of play before a break reminder, or 0 when it is off: a parent
/// setting.
class BreakReminderCubit extends Cubit<int> {
  BreakReminderCubit(this._settings) : super(0);

  final SettingsRepository _settings;

  /// The choices offered to parents.
  static const choices = [0, 15, 30, 45];

  Future<void> load() async => emit(await _settings.loadBreakMinutes());

  Future<void> set(int minutes) async {
    await _settings.saveBreakMinutes(minutes);
    emit(minutes);
  }
}
