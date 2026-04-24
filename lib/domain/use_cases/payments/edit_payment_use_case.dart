import '../../entities/enums.dart';
import '../../repositories/cash_payment_repository.dart';

/// Super-admin only: edits mutable fields on an existing CashPayment record.
///
/// Only amount, paymentMethod, paymentType and notes may be changed.
/// editedByAdminId and editedAt are set automatically by the repository.
class EditPaymentUseCase {
  const EditPaymentUseCase(this._cashRepo);

  final CashPaymentRepository _cashRepo;

  Future<void> call({
    required String id,
    required double amount,
    required PaymentMethod paymentMethod,
    required PaymentType paymentType,
    String? notes,
    required String editedByAdminId,
  }) async {
    await _cashRepo.edit(
      id,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentType: paymentType,
      notes: notes,
      editedByAdminId: editedByAdminId,
    );
  }
}
