import '../settings/settings_repository.dart';
import 'entitlement_service.dart';
import 'plan.dart';

EntitlementService create({
  required Set<String> productIds,
  required SettingsRepository settings,
}) => const StaticEntitlementService(Plan.free);
