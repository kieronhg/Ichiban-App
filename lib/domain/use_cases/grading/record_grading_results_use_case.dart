import '../../entities/enums.dart';
import '../../entities/grading_record.dart';
import '../../entities/grading_event_student.dart';
import '../../repositories/grading_repository.dart';
import '../../repositories/grading_event_student_repository.dart';

class RecordGradingResultsUseCase {
  const RecordGradingResultsUseCase(this._gradingRepo, this._eventStudentRepo);

  final GradingRepository _gradingRepo;
  final GradingEventStudentRepository _eventStudentRepo;

  /// Records the outcome for a nominated student.
  ///
  /// [eventStudent] is the current [GradingEventStudent] being updated.
  /// [eventDate] is the date of the grading event (used for [GradingRecord.gradingDate]).
  ///
  /// If [outcome] = [GradingOutcome.promoted], a [GradingRecord] is also written.
  /// The Cloud Function onGradingPromotionRecorded reacts to the promoted outcome
  /// and sends the FCM push notification.
  Future<void> call({
    required GradingEventStudent eventStudent,
    required DateTime eventDate,
    required GradingOutcome outcome,
    String? rankAchievedId,
    double? gradingScore,
    required String adminId,
    String? notes,
  }) async {
    final now = DateTime.now();

    await _eventStudentRepo.recordOutcome(
      id: eventStudent.id,
      outcome: outcome,
      rankAchievedId: rankAchievedId,
      gradingScore: gradingScore,
      resultRecordedByAdminId: adminId,
      resultRecordedAt: now,
      notes: notes,
    );

    if (outcome == GradingOutcome.promoted) {
      assert(
        rankAchievedId != null,
        'rankAchievedId is required when outcome is promoted',
      );
      await _gradingRepo.create(
        GradingRecord(
          id: '',
          studentId: eventStudent.studentId,
          disciplineId: eventStudent.disciplineId,
          enrollmentId: eventStudent.enrollmentId,
          gradingEventId: eventStudent.gradingEventId,
          fromRankId: eventStudent.currentRankId,
          rankAchievedId: rankAchievedId!,
          outcome: GradingOutcome.promoted,
          gradingScore: gradingScore,
          gradingDate: eventDate,
          markedEligibleByAdminId: eventStudent.nominatedByAdminId,
          eligibilityAnnouncedDate: eventStudent.notificationSentAt,
          gradedByAdminId: adminId,
          notes: notes,
        ),
      );
    }
  }
}
