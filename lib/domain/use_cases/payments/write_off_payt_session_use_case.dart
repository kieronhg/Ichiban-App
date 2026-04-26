import '../../repositories/payt_session_repository.dart';

/// Writes off a pending PAYT session, recording the admin and the reason.
///
/// A written-off session is considered settled — it will no longer appear in
/// the outstanding balance. No CashPayment record is created (there was no
/// actual payment).
class WriteOffPaytSessionUseCase {
  const WriteOffPaytSessionUseCase(this._paytRepo);

  final PaytSessionRepository _paytRepo;

  Future<void> call({
    required String sessionId,
    required String writtenOffByAdminId,
    required String writeOffReason,
  }) async {
    await _paytRepo.writeOff(
      sessionId,
      writtenOffByAdminId: writtenOffByAdminId,
      writeOffReason: writeOffReason,
    );
  }
}
