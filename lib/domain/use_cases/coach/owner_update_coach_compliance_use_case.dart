import '../../entities/coach_profile.dart';
import '../../entities/enums.dart';
import '../../repositories/coach_profile_repository.dart';

class OwnerUpdateCoachComplianceUseCase {
  const OwnerUpdateCoachComplianceUseCase(this._repo);

  final CoachProfileRepository _repo;

  /// Owner directly edits DBS details. Counts as verified — no notification sent.
  Future<void> updateDbs({
    required String adminUserId,
    required String ownerAdminId,
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
      lastUpdatedByAdminId: ownerAdminId,
      lastUpdatedAt: now,
      pendingVerification: false,
    );
    await _repo.updateDbs(adminUserId, dbs);
  }

  /// Owner directly edits first aid details. Counts as verified.
  Future<void> updateFirstAid({
    required String adminUserId,
    required String ownerAdminId,
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
      lastUpdatedByAdminId: ownerAdminId,
      lastUpdatedAt: now,
      pendingVerification: false,
    );
    await _repo.updateFirstAid(adminUserId, firstAid);
  }
}
