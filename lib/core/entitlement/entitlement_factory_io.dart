import 'dart:io';

import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'in_app_purchase_store.dart';
import 'purchase_store.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required SettingsRepository settings,
}) => DonationEntitlementService(
  productIds: productIds,
  store: Platform.isAndroid || Platform.isIOS
      ? InAppPurchaseStore()
      : const NoPurchaseStore(),
  settings: settings,
  unlockCodes: unlockCodes,
);
