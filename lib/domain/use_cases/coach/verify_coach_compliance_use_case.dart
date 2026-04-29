import '../../entities/enums.dart';
import '../../repositories/coach_profile_repository.dart';

class VerifyCoachComplianceUseCase {
  const VerifyCoachComplianceUseCase(this._repo);

  final CoachProfileRepository _repo;

  /// Owner verifies a coach's pending compliance submission.
  /// Clears pendingVerification and records the verifier.
  /// Push notification is sent to the coach via the onCoachComplianceUpdated
  /// Cloud Function trigger.
  Future<void> call({
    required String adminUserId,
    required CoachComplianceType type,
    required String verifiedByAdminId,
  }) async {
    await _repo.verify(
      adminUserId,
      type: type,
      verifiedByAdminId: verifiedByAdminId,
      verifiedAt: DateTime.now(),
    );
  }
}
