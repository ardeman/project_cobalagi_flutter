import 'dart:async';

import '../settings/settings_repository.dart';
import 'entitlement_service.dart';
import 'plan.dart';
import 'purchase_store.dart';
import 'unlock_code.dart';

/// Unlocks [Plan.full] when any of [productIds] has been bought. The result is
/// cached on the device, so the plan is known offline. There is no server, so
/// purchases are trusted as the store reports them. A valid [unlockCodes]
/// code unlocks the same way, so store reviewers can see the supporter plan.
class DonationEntitlementService implements EntitlementService {
  DonationEntitlementService({
    required this.productIds,
    required PurchaseStore store,
    required SettingsRepository settings,
    this.unlockCodes = const UnlockCodes({}),
  }) : _store = store,
       _settings = settings {
    _subscription = _store.purchases.listen(_onPurchases);
  }

  final Set<String> productIds;

  /// Codes that unlock [Plan.full] without a donation (for store reviewers).
  final UnlockCodes unlockCodes;
  final PurchaseStore _store;
  final SettingsRepository _settings;
  final _changes = StreamController<Plan>.broadcast();
  late final StreamSubscription<List<StorePurchase>> _subscription;

  @override
  Stream<Plan> get changes => _changes.stream;

  @override
  Future<Plan> loadPlan() async {
    final known = await _settings.loadSupporter();
    // Picks up donations made on another install; results arrive on changes.
    if (!known && await _store.isAvailable()) unawaited(_store.restore());
    return known ? Plan.full : Plan.free;
  }

  @override
  Future<List<DonationOption>> donationOptions() async {
    if (!await _store.isAvailable()) return const [];
    final products = await _store.products(productIds)
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return [for (final p in products) DonationOption(id: p.id, price: p.price)];
  }

  @override
  Future<void> donate(DonationOption option) => _store.buy(option.id);

  @override
  Future<void> restore() async {
    if (await _store.isAvailable()) await _store.restore();
  }

  @override
  Future<bool> redeem(String code) async {
    if (!unlockCodes.accepts(code)) return false;
    await _settings.saveSupporter();
    _changes.add(Plan.full);
    return true;
  }

  Future<void> _onPurchases(List<StorePurchase> purchases) async {
    for (final purchase in purchases) {
      final ours = productIds.contains(purchase.productId);
      final owned =
          purchase.status == StorePurchaseStatus.purchased ||
          purchase.status == StorePurchaseStatus.restored;
      if (ours && owned) {
        await _settings.saveSupporter();
        _changes.add(Plan.full);
      }
      if (purchase.needsCompletion) await _store.complete(purchase);
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _changes.close();
  }
}
