import '../../entities/grading_event_student.dart';
import '../../repositories/grading_event_student_repository.dart';
import '../../repositories/membership_repository.dart';

class NominateStudentUseCase {
  const NominateStudentUseCase(this._eventStudentRepo, this._membershipRepo);

  final GradingEventStudentRepository _eventStudentRepo;
  final MembershipRepository _membershipRepo;

  Future<String> call({
    required String gradingEventId,
    required String studentId,
    required String disciplineId,
    required String enrollmentId,
    required String currentRankId,
    required String adminId,
  }) async {
    // Membership check: student must have an active or PAYT membership.
    final membership = await _membershipRepo.getActiveForProfile(studentId);
    if (membership == null) {
      throw Exception(
        'Cannot nominate: this student does not have an active membership. '
        'Please create or renew their membership first.',
        // TODO(memberships): confirm whether this should be a hard block or
        // a warning that can be overridden by an admin.
      );
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
