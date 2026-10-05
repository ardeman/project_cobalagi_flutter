import 'dart:io';

import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'in_app_purchase_store.dart';
import 'plan.dart';
import 'unlock_code.dart';

EntitlementService create({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required SettingsRepository settings,
}) => Platform.isAndroid || Platform.isIOS
    ? DonationEntitlementService(
        productIds: productIds,
        store: InAppPurchaseStore(),
        settings: settings,
        unlockCodes: unlockCodes,
      )
    : const StaticEntitlementService(Plan.free);
