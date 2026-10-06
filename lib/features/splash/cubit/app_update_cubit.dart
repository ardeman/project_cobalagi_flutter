import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum UpdateStatus { checking, ready, opening, openFailed }

class AppUpdateState {
  const AppUpdateState({required this.status, this.update});

  final UpdateStatus status;
  final AvailableUpdate? update;
}

/// A bounded, optional launch check: unavailable stores and offline devices
/// must never stop children from playing.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit(
    this._service, {
    this.checkTimeout = const Duration(seconds: 2),
  }) : super(const AppUpdateState(status: UpdateStatus.checking));

  final AppUpdateService _service;
  final Duration checkTimeout;

  Future<void> check() async {
    AvailableUpdate? update;
    try {
      update = await _service.check().timeout(checkTimeout);
    } on Exception {
      // Missing stores, offline devices and timeouts all continue to play.
    }
    if (!isClosed) {
      emit(AppUpdateState(status: UpdateStatus.ready, update: update));
    }
  }

  /// Called by the view only after the parent gate succeeds.
  Future<void> openUpdate() async {
    final update = state.update;
    if (update == null || state.status == UpdateStatus.opening) return;
    emit(AppUpdateState(status: UpdateStatus.opening, update: update));
    var opened = false;
    try {
      opened = await _service.openUpdate(update);
    } on Exception {
      // Keep the optional notice and offer a retry or continue playing.
    }
    if (!isClosed) {
      emit(
        AppUpdateState(
          status: opened ? UpdateStatus.ready : UpdateStatus.openFailed,
          update: update,
        ),
      );
    }
  }
}
