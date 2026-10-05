import 'dart:io';

import '../settings/settings_repository.dart';
import 'donation_entitlement_service.dart';
import 'entitlement_service.dart';
import 'in_app_purchase_store.dart';
import 'plan.dart';

EntitlementService create({
  required Set<String> productIds,
  required SettingsRepository settings,
}) => Platform.isAndroid || Platform.isIOS
    ? DonationEntitlementService(
        productIds: productIds,
        store: InAppPurchaseStore(),
        settings: settings,
      )
    : const StaticEntitlementService(Plan.free);
