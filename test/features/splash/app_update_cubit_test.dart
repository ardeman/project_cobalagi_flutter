import 'dart:async';

import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUpdateService implements AppUpdateService {
  Future<AvailableUpdate?> Function() onCheck = () async => null;
  Future<bool> Function() onOpen = () async => true;
  var opened = 0;

  @override
  Future<AvailableUpdate?> check() => onCheck();

  @override
  Future<bool> openUpdate(AvailableUpdate update) {
    opened++;
    return onOpen();
  }
}

void main() {
  test('available update is offered without opening the store', () async {
    final service = FakeUpdateService()
      ..onCheck = () async => const AvailableUpdate(buildNumber: 6);
    final cubit = AppUpdateCubit(service);
    addTearDown(cubit.close);
    await cubit.check();
    expect(cubit.state.status, UpdateStatus.ready);
    expect(cubit.state.update?.buildNumber, 6);
    expect(service.opened, 0);
  });

  test('offline checks continue without an update notice', () async {
    final service = FakeUpdateService()
      ..onCheck = () async => throw Exception('offline');
    final cubit = AppUpdateCubit(service);
    addTearDown(cubit.close);
    await cubit.check();
    expect(cubit.state.status, UpdateStatus.ready);
    expect(cubit.state.update, isNull);
  });

  test(
    'a late answer never holds up play, and is offered afterwards',
    () async {
      final result = Completer<AvailableUpdate?>();
      final service = FakeUpdateService()..onCheck = () => result.future;
      final cubit = AppUpdateCubit(
        service,
        checkTimeout: const Duration(milliseconds: 1),
      );
      addTearDown(cubit.close);
      final checking = cubit.check();
      // The splash stops waiting at the timeout, with nothing to offer.
      await cubit.stream.first;
      expect(cubit.state.status, UpdateStatus.ready);
      expect(cubit.state.offered, isFalse);
      // Play answers later: the next screen offers it.
      result.complete(const AvailableUpdate(buildNumber: 6));
      await checking;
      expect(cubit.state.update?.buildNumber, 6);
      expect(cubit.state.offered, isTrue);
    },
  );

  test('continue playing hides the notice; checking again keeps it', () async {
    var asked = 0;
    final service = FakeUpdateService()
      ..onCheck = () async {
        asked++;
        return const AvailableUpdate(buildNumber: 6);
      };
    final cubit = AppUpdateCubit(service);
    addTearDown(cubit.close);
    await cubit.check();
    cubit.dismiss();
    expect(cubit.state.offered, isFalse);
    // Coming back to the app: the known update isn't asked for again.
    await cubit.check();
    expect(asked, 1);
    expect(cubit.state.offered, isFalse);
  });

  test('coming back asks again when no update was known', () async {
    AvailableUpdate? answer;
    final service = FakeUpdateService()..onCheck = () async => answer;
    final cubit = AppUpdateCubit(service);
    addTearDown(cubit.close);
    await cubit.check();
    expect(cubit.state.offered, isFalse);
    answer = const AvailableUpdate(buildNumber: 7);
    await cubit.check();
    expect(cubit.state.update?.buildNumber, 7);
  });

  test('failed store opening leaves the notice available for retry', () async {
    final service = FakeUpdateService()
      ..onCheck = (() async => const AvailableUpdate(buildNumber: 6))
      ..onOpen = () async => false;
    final cubit = AppUpdateCubit(service);
    addTearDown(cubit.close);
    await cubit.check();
    await cubit.openUpdate();
    expect(cubit.state.status, UpdateStatus.openFailed);
    expect(cubit.state.update?.buildNumber, 6);
    service.onOpen = () async => true;
    await cubit.openUpdate();
    expect(cubit.state.status, UpdateStatus.ready);
    expect(service.opened, 2);
  });

  test('closing splash before the check completes does not emit', () async {
    final result = Completer<AvailableUpdate?>();
    final service = FakeUpdateService()..onCheck = () => result.future;
    final cubit = AppUpdateCubit(service);
    final checking = cubit.check();
    await cubit.close();
    result.complete(const AvailableUpdate(buildNumber: 6));
    await checking;
    expect(cubit.state.status, UpdateStatus.checking);
  });
}
