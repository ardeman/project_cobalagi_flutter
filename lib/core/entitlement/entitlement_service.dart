import 'plan.dart';

/// A donation the store offers, with its price formatted by the store.
final class DonationOption {
  const DonationOption({required this.id, required this.price});

  final String id;
  final String price;
}

/// Source of truth for the unlocked [Plan]. The app is free; any donation
/// unlocks [Plan.full].
abstract interface class EntitlementService {
  /// The plan known now; may also start a background restore.
  Future<Plan> loadPlan();

  /// Plans that change later, e.g. when a donation completes.
  Stream<Plan> get changes;

  /// Donations on offer, cheapest first; empty where the store is unavailable.
  Future<List<DonationOption>> donationOptions();

  /// Starts the store's purchase flow. The result arrives on [changes].
  Future<void> donate(DonationOption option);

  /// Asks the store again for donations made earlier, e.g. after a reinstall.
  Future<void> restore();

  /// Unlocks [Plan.full] when [code] is a valid unlock code; the result also
  /// arrives on [changes]. Returns whether the code was accepted.
  Future<bool> redeem(String code);

  Future<void> dispose();
}

/// A fixed plan, for platforms without store billing (such as web) and tests.
class StaticEntitlementService implements EntitlementService {
  const StaticEntitlementService(this.plan);

  final Plan plan;

  @override
  Future<Plan> loadPlan() async => plan;

  @override
  Stream<Plan> get changes => const Stream.empty();

  @override
  Future<List<DonationOption>> donationOptions() async => const [];

  @override
  Future<void> donate(DonationOption option) async {}

  @override
  Future<void> restore() async {}

  @override
  Future<bool> redeem(String code) async => false;

  @override
  Future<void> dispose() async {}
}
