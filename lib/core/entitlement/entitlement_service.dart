import 'plan.dart';

/// Source of truth for the unlocked [Plan].
///
/// Store billing (Google Play, App Store) implements this in Phase 5. Platforms
/// without store billing, such as web, stay on [Plan.free].
abstract interface class EntitlementService {
  Future<Plan> loadPlan();
}

class StaticEntitlementService implements EntitlementService {
  const StaticEntitlementService(this.plan);

  final Plan plan;

  @override
  Future<Plan> loadPlan() async => plan;
}
