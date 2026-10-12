import 'dart:async';

import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum UpdateStatus { checking, ready, opening, openFailed }

class AppUpdateState {
  const AppUpdateState({
    required this.status,
    this.update,
    this.dismissed = false,
  });

  final UpdateStatus status;
  final AvailableUpdate? update;

  /// "Continue playing" was chosen: the notice stays away this session.
  final bool dismissed;

  /// Whether to show the notice.
  bool get offered => update != null && !dismissed;
}

/// A bounded, optional update check: unavailable stores and offline devices
/// must never stop children from playing. The splash waits [checkTimeout]
/// at most; a store that answers later (Play is often slow on a cold start)
/// still offers the update, on the next screen, for up to [lateTimeout].
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit(
    this._service, {
    this.checkTimeout = const Duration(seconds: 2),
    this.lateTimeout = const Duration(seconds: 30),
  }) : super(const AppUpdateState(status: UpdateStatus.checking));

  final AppUpdateService _service;
  final Duration checkTimeout;
  final Duration lateTimeout;
  var _checking = false;

  /// Asks the store, unless an update is already known or a check runs. Also
  /// called when the app comes back to the foreground.
  Future<void> check() async {
    if (_checking || state.update != null) return;
    _checking = true;
    final answer = _service.check();
    AvailableUpdate? update;
    var late = false;
    try {
      update = await answer.timeout(checkTimeout);
    } on TimeoutException {
      late = true;
    } on Exception {
      // Missing stores and offline devices continue to play.
    }
    if (!isClosed) {
      emit(AppUpdateState(status: UpdateStatus.ready, update: update));
    }
    if (late) {
      try {
        update = await answer.timeout(lateTimeout);
        if (update != null && !isClosed && state.update == null) {
          emit(AppUpdateState(status: UpdateStatus.ready, update: update));
        }
      } on Exception {
        // Never answered: nothing to offer this time.
      }
    }
    _checking = false;
  }

  /// "Continue playing": no notice again this session.
  void dismiss() {
    if (state.update == null) return;
    emit(
      AppUpdateState(
        status: state.status,
        update: state.update,
        dismissed: true,
      ),
    );
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
