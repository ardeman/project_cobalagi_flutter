import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'purchase_store.dart';
import 'purchased_code.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required PurchasedCodes purchasedCodes,
  required SettingsRepository settings,
}) => DonationEntitlementService(
  productIds: productIds,
  store: const NoPurchaseStore(),
  settings: settings,
  unlockCodes: unlockCodes,
  purchasedCodes: purchasedCodes,
);
