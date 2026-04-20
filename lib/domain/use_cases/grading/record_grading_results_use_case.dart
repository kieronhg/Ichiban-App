import '../../entities/enums.dart';
import '../../entities/grading_record.dart';
import '../../entities/grading_event_student.dart';
import '../../entities/notification_log.dart';
import '../../repositories/grading_repository.dart';
import '../../repositories/grading_event_student_repository.dart';
import '../../repositories/notification_repository.dart';

class RecordGradingResultsUseCase {
  const RecordGradingResultsUseCase(
    this._gradingRepo,
    this._eventStudentRepo,
    this._notificationRepo,
  );

  final GradingRepository _gradingRepo;
  final GradingEventStudentRepository _eventStudentRepo;
  final NotificationRepository _notificationRepo;

  /// Records the outcome for a nominated student.
  ///
  /// [eventStudent] is the current [GradingEventStudent] being updated.
  /// [eventDate] is the date of the grading event (used for [GradingRecord.gradingDate]).
  ///
  /// If [outcome] = [GradingOutcome.promoted], a [GradingRecord] is also written.
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
      final gradingRecord = GradingRecord(
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
      );
      await _gradingRepo.create(gradingRecord);

      // TODO(notifications): send a real FCM push notification here.
      await _notificationRepo.create(
        NotificationLog(
          id: '',
          recipientProfileId: eventStudent.studentId,
          channel: NotificationChannel.push,
          type: NotificationType.gradingPromotion,
          title: 'Congratulations — you have been promoted!',
          body: 'Your new rank has been recorded. Well done!',
          isRead: false,
          sentAt: now,
        ),
      );
    }
  }
}
