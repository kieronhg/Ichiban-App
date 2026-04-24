import '../../entities/cash_payment.dart';
import '../../entities/enums.dart';
import '../../repositories/cash_payment_repository.dart';

/// Records a standalone (non-PAYT, non-membership) cash payment for a
/// profile — e.g. merchandise, exam fees, or other ad-hoc charges.
///
/// Returns the generated CashPayment document ID.
class RecordStandalonePaymentUseCase {
  const RecordStandalonePaymentUseCase(this._cashRepo);

  final CashPaymentRepository _cashRepo;

  Future<String> call({
    required String profileId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String recordedByAdminId,
    String? notes,
  }) async {
    final payment = CashPayment(
      id: '',
      profileId: profileId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentType: PaymentType.other,
      recordedByAdminId: recordedByAdminId,
      recordedAt: DateTime.now(),
      notes: notes,
    );

    return _cashRepo.create(payment);
  }
}
