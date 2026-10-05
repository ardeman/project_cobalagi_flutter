import 'dart:async';

import 'package:cobalagi/core/entitlement/donation_entitlement_service.dart';
import 'package:cobalagi/core/entitlement/entitlement_service.dart';
import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/core/entitlement/purchase_store.dart';
import 'package:cobalagi/core/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

class FakeStore implements PurchaseStore {
  var available = true;
  final bought = <String>[];
  final completed = <String>[];
  var restores = 0;
  final _purchases = StreamController<List<StorePurchase>>.broadcast();

  void emit(String id, StorePurchaseStatus status, {bool complete = true}) =>
      _purchases.add([
        StorePurchase(productId: id, status: status, needsCompletion: complete),
      ]);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => [
    const StoreProduct(id: 'large', price: 'Rp 150.000', rawPrice: 150000),
    const StoreProduct(id: 'small', price: 'Rp 15.000', rawPrice: 15000),
  ].where((p) => ids.contains(p.id)).toList();

  @override
  Future<void> buy(String productId) async => bought.add(productId);

  @override
  Future<void> restore() async => restores++;

  @override
  Stream<List<StorePurchase>> get purchases => _purchases.stream;

  @override
  Future<void> complete(StorePurchase purchase) async =>
      completed.add(purchase.productId);
}

void main() {
  late FakeStore store;
  late SettingsRepository settings;
  late DonationEntitlementService service;

  setUp(() async {
    store = FakeStore();
    settings = SettingsRepository(
      await newDatabaseFactoryMemory().openDatabase('t.db'),
    );
    service = DonationEntitlementService(
      productIds: {'small', 'large'},
      store: store,
      settings: settings,
    );
  });

  tearDown(() => service.dispose());

  test('starts free and restores in the background', () async {
    expect(await service.loadPlan(), Plan.free);
    expect(store.restores, 1);
  });

  test('offers donations cheapest first', () async {
    final options = await service.donationOptions();
    expect(options.map((o) => o.price), ['Rp 15.000', 'Rp 150.000']);
  });

  test('no donations when the store is unavailable', () async {
    store.available = false;
    expect(await service.donationOptions(), isEmpty);
  });

  test('any donation unlocks the supporter plan and is remembered', () async {
    final plans = <Plan>[];
    service.changes.listen(plans.add);
    await service.donate(const DonationOption(id: 'small', price: ''));
    expect(store.bought, ['small']);

    store.emit('small', StorePurchaseStatus.purchased);
    await pumpEventQueue();
    expect(plans, [Plan.full]);
    expect(store.completed, ['small']);
    expect(await settings.loadSupporter(), isTrue);
    expect(await service.loadPlan(), Plan.full);
  });

  test('restored donations unlock too', () async {
    final plans = <Plan>[];
    service.changes.listen(plans.add);
    store.emit('large', StorePurchaseStatus.restored);
    await pumpEventQueue();
    expect(plans, [Plan.full]);
  });

  test(
    'cancelled, failed, pending and unknown purchases do not unlock',
    () async {
      final plans = <Plan>[];
      service.changes.listen(plans.add);
      store
        ..emit('small', StorePurchaseStatus.canceled, complete: false)
        ..emit('small', StorePurchaseStatus.failed)
        ..emit('small', StorePurchaseStatus.pending, complete: false)
        ..emit('other_app_item', StorePurchaseStatus.purchased);
      await pumpEventQueue();
      expect(plans, isEmpty);
      expect(await settings.loadSupporter(), isFalse);
      // Purchases still get completed so the store does not refund them.
      expect(store.completed, ['small', 'other_app_item']);
    },
  );
}
