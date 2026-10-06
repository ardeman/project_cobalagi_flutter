import 'entitlement_service.dart';
import 'entitlement_factory_io.dart'
    if (dart.library.js_interop) 'entitlement_factory_web.dart'
    as platform;
import '../settings/settings_repository.dart';
import 'unlock_code.dart';

/// Store donations on Android and iOS; elsewhere only unlock codes.
EntitlementService createEntitlementService({
  required Set<String> productIds,
  required UnlockCodes unlockCodes,
  required SettingsRepository settings,
}) => platform.create(
  productIds: productIds,
  unlockCodes: unlockCodes,
  settings: settings,
);
