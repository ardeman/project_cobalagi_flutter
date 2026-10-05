/// A product as the store describes it.
final class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.price,
    required this.rawPrice,
  });

  final String id;

  /// Formatted in the store's currency, e.g. "Rp 15.000".
  final String price;
  final double rawPrice;
}

enum StorePurchaseStatus { pending, purchased, restored, failed, canceled }

final class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    required this.needsCompletion,
    this.handle,
  });

  final String productId;
  final StorePurchaseStatus status;

  /// The store must be told the purchase was delivered, or it is refunded.
  final bool needsCompletion;

  /// The platform's own purchase object, passed back to [PurchaseStore.complete].
  final Object? handle;
}

/// The small part of a billing library the app uses, so it can be faked.
abstract interface class PurchaseStore {
  Future<bool> isAvailable();

  Future<List<StoreProduct>> products(Set<String> ids);

  Future<void> buy(String productId);

  Future<void> restore();

  Stream<List<StorePurchase>> get purchases;

  Future<void> complete(StorePurchase purchase);
}
