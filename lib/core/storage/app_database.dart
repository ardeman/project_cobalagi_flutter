import 'package:sembast/sembast.dart';

import 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart'
    as platform;

const _databaseName = 'cobalagi.db';

/// Opens the single local database. Files on native platforms, IndexedDB on web.
Future<Database> openAppDatabase() => platform.openNamedDatabase(_databaseName);
