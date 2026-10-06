import 'package:cobalagi/features/splash/data/app_update_factory.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:cobalagi/features/splash/data/play_app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

AppUpdateInfo info({
  UpdateAvailability availability = UpdateAvailability.updateAvailable,
  bool immediate = true,
  bool flexible = true,
  InstallStatus status = InstallStatus.unknown,
  int? build = 6,
}) => AppUpdateInfo(
  updateAvailability: availability,
  immediateUpdateAllowed: immediate,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: flexible,
  flexibleAllowedPreconditions: null,
  availableVersionCode: build,
  installStatus: status,
  packageName: 'com.ardeman.cobalagi',
  clientVersionStalenessDays: null,
  updatePriority: 0,
);

void main() {
  const update = AvailableUpdate(buildNumber: 6);

  test('non-Android platforms skip the Play plugin', () async {
    final service = createAppUpdateService();
    expect(service, isA<NoAppUpdateService>());
    expect(await service.check(), isNull);
  });

  test('launch check offers an update without starting it', () async {
    var started = false;
    final service = PlayAppUpdateService(
      checkForUpdate: () async => info(),
      immediateUpdate: () async {
        started = true;
        return AppUpdateResult.success;
      },
    );
    expect((await service.check())?.buildNumber, 6);
    expect(started, isFalse);
  });

  test('Play arbitrary version codes without an update are ignored', () async {
    final service = PlayAppUpdateService(
      checkForUpdate: () async =>
          info(availability: UpdateAvailability.updateNotAvailable),
    );
    expect(await service.check(), isNull);
  });

  test(
    'an unfinished immediate update is offered without resuming it',
    () async {
      final service = PlayAppUpdateService(
        checkForUpdate: () async => info(
          availability: UpdateAvailability.developerTriggeredUpdateInProgress,
        ),
      );
      expect((await service.check())?.buildNumber, 6);
    },
  );

  test('each parent retry obtains fresh Play update info', () async {
    var checked = 0;
    var opened = 0;
    final service = PlayAppUpdateService(
      checkForUpdate: () async {
        checked++;
        return info();
      },
      immediateUpdate: () async {
        opened++;
        return AppUpdateResult.userDeniedUpdate;
      },
    );
    await service.check();
    expect(await service.openUpdate(update), isTrue);
    expect(await service.openUpdate(update), isTrue);
    expect(checked, 3);
    expect(opened, 2);
  });

  test('flexible download is installed only after it succeeds', () async {
    var completed = 0;
    var result = AppUpdateResult.userDeniedUpdate;
    final service = PlayAppUpdateService(
      checkForUpdate: () async => info(immediate: false),
      flexibleUpdate: () async => result,
      completeFlexibleUpdate: () async => completed++,
    );
    expect(await service.openUpdate(update), isTrue);
    expect(completed, 0);
    result = AppUpdateResult.inAppUpdateFailed;
    expect(await service.openUpdate(update), isFalse);
    expect(completed, 0);
    result = AppUpdateResult.success;
    expect(await service.openUpdate(update), isTrue);
    expect(completed, 1);
  });

  test('downloaded update is completed after a parent requests it', () async {
    var completed = 0;
    final service = PlayAppUpdateService(
      checkForUpdate: () async => info(
        immediate: false,
        flexible: false,
        status: InstallStatus.downloaded,
      ),
      completeFlexibleUpdate: () async => completed++,
    );
    await service.check();
    expect(completed, 0);
    expect(await service.openUpdate(update), isTrue);
    expect(completed, 1);
  });

  test(
    'withdrawn updates and disallowed flows never start installation',
    () async {
      var started = false;
      var current = info(availability: UpdateAvailability.updateNotAvailable);
      final service = PlayAppUpdateService(
        checkForUpdate: () async => current,
        immediateUpdate: () async {
          started = true;
          return AppUpdateResult.success;
        },
      );
      expect(await service.openUpdate(update), isFalse);
      current = info(immediate: false, flexible: false);
      expect(await service.openUpdate(update), isFalse);
      expect(started, isFalse);
    },
  );
}
