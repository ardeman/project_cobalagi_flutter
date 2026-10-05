import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_store.dart';

/// [PurchaseStore] backed by Google Play Billing / the App Store.
class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final _details = <String, ProductDetails>{};

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    for (final d in response.productDetails) {
      _details[d.id] = d;
    }
    return [
      for (final d in response.productDetails)
        StoreProduct(id: d.id, price: d.price, rawPrice: d.rawPrice),
    ];
  }

  @override
  Future<void> buy(String productId) async {
    final details = _details[productId];
    if (details == null) throw StateError('unknown product $productId');
    // Donations are one-time products; any of them unlocks the supporter plan.
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Stream<List<StorePurchase>> get purchases => _iap.purchaseStream.map(
    (list) => [
      for (final p in list)
        StorePurchase(
          productId: p.productID,
          status: switch (p.status) {
            PurchaseStatus.pending => StorePurchaseStatus.pending,
            PurchaseStatus.purchased => StorePurchaseStatus.purchased,
            PurchaseStatus.restored => StorePurchaseStatus.restored,
            PurchaseStatus.error => StorePurchaseStatus.failed,
            PurchaseStatus.canceled => StorePurchaseStatus.canceled,
          },
          needsCompletion: p.pendingCompletePurchase,
          handle: p,
        ),
    ],
  );

  @override
  Future<void> complete(StorePurchase purchase) =>
      _iap.completePurchase(purchase.handle! as PurchaseDetails);
}
