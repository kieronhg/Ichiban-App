import '../entities/cash_payment.dart';

abstract class CashPaymentRepository {
  /// Returns all cash payments for a given profile.
  Future<List<CashPayment>> getForProfile(String profileId);

  /// Returns all cash payments linked to a specific membership.
  Future<List<CashPayment>> getForMembership(String membershipId);

  /// Returns all cash payments in the system, ordered by recordedAt descending.
  Future<List<CashPayment>> getAll();

  /// Creates a new cash payment audit record and returns the generated document ID.
  Future<String> create(CashPayment payment);
}
