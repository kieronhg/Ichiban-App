import '../../entities/grading_event_student.dart';
import '../../repositories/grading_event_student_repository.dart';
import '../../repositories/membership_repository.dart';

/// Thrown when a student has no active membership and [allowWithoutMembership]
/// is false. Owners can override by retrying with [allowWithoutMembership: true].
class MissingMembershipException implements Exception {
  const MissingMembershipException(this.studentId);

  final String studentId;

  @override
  String toString() =>
      'MissingMembershipException: student $studentId has no active membership.';
}

class NominateStudentUseCase {
  const NominateStudentUseCase(this._eventStudentRepo, this._membershipRepo);

  final GradingEventStudentRepository _eventStudentRepo;
  final MembershipRepository _membershipRepo;

  /// Nominates a student for a grading event.
  ///
  /// Throws [MissingMembershipException] if the student has no active
  /// membership and [allowWithoutMembership] is false. Owners can set
  /// [allowWithoutMembership: true] to override after confirming.
  Future<String> call({
    required String gradingEventId,
    required String studentId,
    required String disciplineId,
    required String enrollmentId,
    required String currentRankId,
    required String adminId,
    bool allowWithoutMembership = false,
  }) async {
    if (!allowWithoutMembership) {
      final membership = await _membershipRepo.getActiveForProfile(studentId);
      if (membership == null) {
        throw MissingMembershipException(studentId);
      }
    }

    final record = GradingEventStudent(
      id: '',
      gradingEventId: gradingEventId,
      studentId: studentId,
      disciplineId: disciplineId,
      enrollmentId: enrollmentId,
      currentRankId: currentRankId,
      nominatedByAdminId: adminId,
      nominatedAt: DateTime.now(),
    );

    // The Cloud Function onGradingEligibilityCreated reacts to this write,
    // sends the FCM push, and updates notificationSentAt on the document.
    return _eventStudentRepo.create(record);
  }
}
