import 'package:flutter/foundation.dart';

import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'in_app_purchase_store.dart';
import 'purchase_store.dart';
import 'store_rules.dart';
import 'purchased_code.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required PurchasedCodes purchasedCodes,
  required SettingsRepository settings,
}) => DonationEntitlementService(
  productIds: productIds,
  store: StoreRules.current().storeBilling(defaultTargetPlatform)
      ? InAppPurchaseStore()
      : const NoPurchaseStore(),
  settings: settings,
  unlockCodes: unlockCodes,
  purchasedCodes: purchasedCodes,
);
