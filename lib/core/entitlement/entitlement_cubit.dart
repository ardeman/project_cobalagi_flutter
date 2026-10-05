import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'entitlement_service.dart';
import 'plan.dart';

class EntitlementCubit extends Cubit<Plan> {
  EntitlementCubit(this._service) : super(Plan.free);

  final EntitlementService _service;

  Future<void> load() async => emit(await _service.loadPlan());

  /// Lets developers try the full version before billing exists. Debug builds only.
  void debugOverride(Plan plan) {
    assert(kDebugMode, 'debugOverride is for debug builds only');
    if (kDebugMode) emit(plan);
  }
}
