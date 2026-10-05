import 'entitlement_service.dart';
import 'entitlement_factory_io.dart'
    if (dart.library.js_interop) 'entitlement_factory_web.dart'
    as platform;
import '../settings/settings_repository.dart';

/// Store donations on Android and iOS; the free plan everywhere else.
EntitlementService createEntitlementService({
  required Set<String> productIds,
  required SettingsRepository settings,
}) => platform.create(productIds: productIds, settings: settings);
