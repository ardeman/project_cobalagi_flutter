import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'entitlement_service.dart';
import 'plan.dart';

class EntitlementCubit extends Cubit<Plan> {
  EntitlementCubit(this.service) : super(Plan.free) {
    _changes = service.changes.listen(emit);
  }

  final EntitlementService service;
  late final StreamSubscription<Plan> _changes;

  Future<void> load() async => emit(await service.loadPlan());

  /// Lets developers try the supporter plan without paying. Debug builds only.
  void debugOverride(Plan plan) {
    assert(kDebugMode, 'debugOverride is for debug builds only');
    if (kDebugMode) emit(plan);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
