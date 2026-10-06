/// A store or release source with a newer version available for this device.
class AvailableUpdate {
  const AvailableUpdate({required this.buildNumber});

  final int buildNumber;
}

/// Checks for updates without accessing player data. Opening an update must
/// happen only after the parent gate has been passed.
abstract interface class AppUpdateService {
  Future<AvailableUpdate?> check();
  Future<bool> openUpdate(AvailableUpdate update);
}

/// Platforms without a configured update source continue straight to play.
class NoAppUpdateService implements AppUpdateService {
  const NoAppUpdateService();

  @override
  Future<AvailableUpdate?> check() async => null;

  @override
  Future<bool> openUpdate(AvailableUpdate update) async => false;
}
