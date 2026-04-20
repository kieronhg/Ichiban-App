import '../../entities/enums.dart';
import '../../entities/grading_event_student.dart';
import '../../entities/notification_log.dart';
import '../../repositories/grading_event_student_repository.dart';
import '../../repositories/notification_repository.dart';

class NominateStudentUseCase {
  const NominateStudentUseCase(this._eventStudentRepo, this._notificationRepo);

  final GradingEventStudentRepository _eventStudentRepo;
  final NotificationRepository _notificationRepo;

  Future<String> call({
    required String gradingEventId,
    required String studentId,
    required String disciplineId,
    required String enrollmentId,
    required String currentRankId,
    required String adminId,
  }) async {
    // TODO(memberships): check student has an active membership before nominating.

    final now = DateTime.now();
    final record = GradingEventStudent(
      id: '',
      gradingEventId: gradingEventId,
      studentId: studentId,
      disciplineId: disciplineId,
      enrollmentId: enrollmentId,
      currentRankId: currentRankId,
      nominatedByAdminId: adminId,
      nominatedAt: now,
    );

    final id = await _eventStudentRepo.create(record);

    // TODO(notifications): send a real FCM push notification here.
    // For now we log the intent only.
    await _notificationRepo.create(
      NotificationLog(
        id: '',
        recipientProfileId: studentId,
        channel: NotificationChannel.push,
        type: NotificationType.gradingEligibility,
        title: 'You have been nominated for grading!',
        body: 'Your coach has nominated you for an upcoming grading event.',
        isRead: false,
        sentAt: now,
      ),
    );
    await _eventStudentRepo.markNotificationSent(id, now);

    return id;
  }
}
