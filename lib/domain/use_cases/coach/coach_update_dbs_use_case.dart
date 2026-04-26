import '../../entities/coach_profile.dart';
import '../../entities/enums.dart';
import '../../repositories/coach_profile_repository.dart';

class CoachUpdateDbsUseCase {
  const CoachUpdateDbsUseCase(this._repo);

  final CoachProfileRepository _repo;

  /// Coach submits updated DBS details. Saved immediately; pendingVerification
  /// set to true so the owner knows to review.
  ///
  /// TODO(notifications): send push notification to all owners after save.
  /// Type: coachComplianceSubmitted, payload: { adminUserId, complianceType: dbs }
  Future<void> call({
    required String adminUserId,
    required DbsStatus status,
    String? certificateNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    final now = DateTime.now();
    final dbs = DbsRecord(
      status: status,
      certificateNumber: certificateNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      pendingVerification: true,
      submittedByCoachAt: now,
    );
    await _repo.updateDbs(adminUserId, dbs);
  }
}
