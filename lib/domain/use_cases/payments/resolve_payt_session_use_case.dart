import '../../entities/cash_payment.dart';
import '../../entities/enums.dart';
import '../../repositories/payt_session_repository.dart';
import '../../repositories/cash_payment_repository.dart';

/// Marks a single pending PAYT session as paid and creates the corresponding
/// CashPayment audit record.
///
/// Returns the generated CashPayment document ID.
class ResolvePaytSessionUseCase {
  const ResolvePaytSessionUseCase(this._paytRepo, this._cashRepo);

  final PaytSessionRepository _paytRepo;
  final CashPaymentRepository _cashRepo;

  Future<String> call({
    required String sessionId,
    required String profileId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String recordedByAdminId,
    String? notes,
  }) async {
    final now = DateTime.now();

    // Mark the session as paid in Firestore
    await _paytRepo.markPaid(
      sessionId,
      recordedByAdminId: recordedByAdminId,
      paymentMethod: paymentMethod,
    );

    // Write the audit record
    final cashPayment = CashPayment(
      id: '',
      profileId: profileId,
      paytSessionId: sessionId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentType: PaymentType.payt,
      recordedByAdminId: recordedByAdminId,
      recordedAt: now,
      notes: notes,
    );

    return _cashRepo.create(cashPayment);
  }
}
