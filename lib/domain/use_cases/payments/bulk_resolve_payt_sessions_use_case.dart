import '../../entities/enums.dart';
import '../../repositories/payt_session_repository.dart';
import '../../repositories/cash_payment_repository.dart';
import 'resolve_payt_session_use_case.dart';

/// Resolves multiple pending PAYT sessions in a single operation, applying
/// the same payment method to all.
///
/// Returns the list of generated CashPayment document IDs, in the same order
/// as the input sessions.
class BulkResolvePaytSessionsUseCase {
  const BulkResolvePaytSessionsUseCase(this._paytRepo, this._cashRepo);

  final PaytSessionRepository _paytRepo;
  final CashPaymentRepository _cashRepo;

  Future<List<String>> call({
    required List<({String sessionId, String profileId, double amount})>
    sessions,
    required PaymentMethod paymentMethod,
    required String recordedByAdminId,
    String? notes,
  }) async {
    final resolveUseCase = ResolvePaytSessionUseCase(_paytRepo, _cashRepo);
    final ids = <String>[];

    for (final session in sessions) {
      final cashPaymentId = await resolveUseCase(
        sessionId: session.sessionId,
        profileId: session.profileId,
        amount: session.amount,
        paymentMethod: paymentMethod,
        recordedByAdminId: recordedByAdminId,
        notes: notes,
      );
      ids.add(cashPaymentId);
    }

    return ids;
  }
}
