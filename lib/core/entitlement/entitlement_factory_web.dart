import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'purchase_store.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required SettingsRepository settings,
}) => DonationEntitlementService(
  productIds: productIds,
  store: const NoPurchaseStore(),
  settings: settings,
  unlockCodes: unlockCodes,
);
