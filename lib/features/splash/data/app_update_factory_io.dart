import 'dart:io';

import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:cobalagi/features/splash/data/play_app_update_service.dart';

AppUpdateService create() =>
    Platform.isAndroid ? PlayAppUpdateService() : const NoAppUpdateService();
