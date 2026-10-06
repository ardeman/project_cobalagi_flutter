import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:cobalagi/features/splash/data/app_update_factory_io.dart'
    if (dart.library.js_interop) 'package:cobalagi/features/splash/data/app_update_factory_web.dart'
    as platform;

/// Google Play on Android; no store calls on other platforms.
AppUpdateService createAppUpdateService() => platform.create();
