import '../entities/coach_profile.dart';
import '../entities/enums.dart';

abstract interface class CoachProfileRepository {
  /// Fetch a single coach profile by admin UID. Returns null if not found.
  Future<CoachProfile?> getById(String adminUserId);

  /// Stream a single coach profile by admin UID. Emits null if not found.
  Stream<CoachProfile?> watchById(String adminUserId);

  /// Stream all coach profiles ordered by adminUserId.
  Stream<List<CoachProfile>> watchAll();

  /// Create a new coachProfiles document.
  Future<void> create(CoachProfile coachProfile);

  /// Update the coach's own editable personal details (qualificationsNotes only —
  /// name is stored on adminUsers and updated separately).
  Future<void> updatePersonalDetails(
    String adminUserId, {
    String? qualificationsNotes,
  });

  /// Overwrite the DBS sub-document. Used by both coach-initiated and
  /// owner-initiated updates — callers set pendingVerification accordingly.
  Future<void> updateDbs(String adminUserId, DbsRecord dbs);

  /// Overwrite the first aid sub-document.
  Future<void> updateFirstAid(String adminUserId, FirstAidRecord firstAid);

  /// Clear pendingVerification on one compliance type and record the verifier.
  Future<void> verify(
    String adminUserId, {
    required CoachComplianceType type,
    required String verifiedByAdminId,
    required DateTime verifiedAt,
  });
}
