import '../entities/cash_payment.dart';
import '../entities/enums.dart';

abstract class CashPaymentRepository {
  /// Returns all cash payments for a given profile.
  Future<List<CashPayment>> getForProfile(String profileId);

  /// Returns all cash payments linked to a specific membership.
  Future<List<CashPayment>> getForMembership(String membershipId);

  /// Returns all cash payments in the system, ordered by recordedAt descending.
  Future<List<CashPayment>> getAll();

  /// Creates a new cash payment audit record and returns the generated document ID.
  Future<String> create(CashPayment payment);

  /// Super-admin: edits mutable fields on an existing cash payment record.
  /// Sets editedByAdminId and editedAt automatically.
  Future<void> edit(
    String id, {
    required double amount,
    required PaymentMethod paymentMethod,
    required PaymentType paymentType,
    String? notes,
    required String editedByAdminId,
  });

  /// Watches all cash payments in the system, ordered by recordedAt descending.
  Stream<List<CashPayment>> watchAll();

  /// Watches all cash payments for a given profile, ordered by recordedAt
  /// descending.
  Stream<List<CashPayment>> watchForProfile(String profileId);

  /// Watches all cash payments linked to a specific membership.
  Stream<List<CashPayment>> watchForMembership(String membershipId);
}
