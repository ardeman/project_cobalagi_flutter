import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:in_app_update/in_app_update.dart';

/// Play owns update availability, consent, downloads and installation. This
/// service never receives profiles or learning progress.
class PlayAppUpdateService implements AppUpdateService {
  PlayAppUpdateService({
    Future<AppUpdateInfo> Function()? checkForUpdate,
    Future<AppUpdateResult> Function()? immediateUpdate,
    Future<AppUpdateResult> Function()? flexibleUpdate,
    Future<void> Function()? completeFlexibleUpdate,
  }) : _checkForUpdate = checkForUpdate ?? InAppUpdate.checkForUpdate,
       _immediateUpdate = immediateUpdate ?? InAppUpdate.performImmediateUpdate,
       _flexibleUpdate = flexibleUpdate ?? InAppUpdate.startFlexibleUpdate,
       _completeFlexibleUpdate =
           completeFlexibleUpdate ?? InAppUpdate.completeFlexibleUpdate;

  final Future<AppUpdateInfo> Function() _checkForUpdate;
  final Future<AppUpdateResult> Function() _immediateUpdate;
  final Future<AppUpdateResult> Function() _flexibleUpdate;
  final Future<void> Function() _completeFlexibleUpdate;

  AvailableUpdate? _available(AppUpdateInfo info) {
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable ||
        info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress;
    final build = info.availableVersionCode;
    return available && build != null && build > 0
        ? AvailableUpdate(buildNumber: build)
        : null;
  }

  @override
  Future<AvailableUpdate?> check() async => _available(await _checkForUpdate());

  @override
  Future<bool> openUpdate(AvailableUpdate update) async {
    // Play update info can be used only once. Refresh it for each parent-led
    // retry instead of reusing the object obtained during launch.
    final info = await _checkForUpdate().timeout(const Duration(seconds: 2));
    if (_available(info) == null) return false;
    if (info.installStatus == InstallStatus.downloaded) {
      await _completeFlexibleUpdate();
      return true;
    }
    if (info.immediateUpdateAllowed) {
      final result = await _immediateUpdate();
      return result != AppUpdateResult.inAppUpdateFailed;
    }
    if (info.flexibleUpdateAllowed) {
      final result = await _flexibleUpdate();
      if (result == AppUpdateResult.success) {
        await _completeFlexibleUpdate();
      }
      return result != AppUpdateResult.inAppUpdateFailed;
    }
    return false;
  }
}
