import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/settings/settings_repository.dart';

/// Whether the play world turns with the robot, so the way it faces is
/// always up and its left and right are the child's. Saved on the device.
class FollowRobotCubit extends Cubit<bool> {
  FollowRobotCubit(this._settings) : super(false);

  final SettingsRepository _settings;

  Future<void> load() async => emit(await _settings.loadFollowRobot());

  Future<void> set(bool on) async {
    emit(on);
    await _settings.saveFollowRobot(on);
  }
}
