import '../../entities/coach_profile.dart';
import '../../repositories/coach_profile_repository.dart';

class CoachUpdateFirstAidUseCase {
  const CoachUpdateFirstAidUseCase(this._repo);

  final CoachProfileRepository _repo;

  /// Coach submits updated first aid details. Saved immediately;
  /// pendingVerification set to true so the owner knows to review.
  /// Push notifications are sent to owners via the onCoachComplianceUpdated
  /// Cloud Function trigger.
  Future<void> call({
    required String adminUserId,
    String? certificationName,
    String? issuingBody,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    final now = DateTime.now();
    final firstAid = FirstAidRecord(
      certificationName: certificationName,
      issuingBody: issuingBody,
      issueDate: issueDate,
      expiryDate: expiryDate,
      pendingVerification: true,
      submittedByCoachAt: now,
    );
    await _repo.updateFirstAid(adminUserId, firstAid);
  }
}
