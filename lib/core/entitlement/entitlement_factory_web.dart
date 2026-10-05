import '../settings/settings_repository.dart';
import 'entitlement_service.dart';
import 'plan.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required SettingsRepository settings,
}) => const StaticEntitlementService(Plan.free);
