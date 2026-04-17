import '../entities/membership_pricing.dart';

abstract class MembershipPricingRepository {
  /// Returns all pricing documents.
  Future<List<MembershipPricing>> getAll();

  /// Returns the pricing for a given key, or null if not found.
  Future<MembershipPricing?> getByKey(String key);

  /// Updates the price for a given key.
  Future<void> updatePrice(String key, double amount);

  /// Watches all pricing documents in real time.
  Stream<List<MembershipPricing>> watchAll();
}
