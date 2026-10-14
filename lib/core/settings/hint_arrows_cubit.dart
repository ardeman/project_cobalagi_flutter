import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_repository.dart';

/// Whether the hint's arrows turn to follow the road (the default) or point
/// up, as on the blocks: a parent setting.
class HintArrowsCubit extends Cubit<bool> {
  HintArrowsCubit(this._settings) : super(true);

  final SettingsRepository _settings;

  Future<void> load() async => emit(await _settings.loadHintArrowsFollowRoad());

  Future<void> set({required bool followRoad}) async {
    await _settings.saveHintArrowsFollowRoad(followRoad);
    emit(followRoad);
  }
}
