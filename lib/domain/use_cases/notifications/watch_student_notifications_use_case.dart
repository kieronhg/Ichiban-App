import '../../entities/enums.dart';
import '../../entities/notification_log.dart';
import '../../repositories/notification_repository.dart';

/// Student-visible notification types — billing notifications are excluded
/// from the student tablet per Part 12 of the handover.
const _studentVisibleTypes = {
  NotificationType.gradingEligibility,
  NotificationType.gradingPromotion,
  NotificationType.trialExpiring,
  NotificationType.announcement,
};

class WatchStudentNotificationsUseCase {
  const WatchStudentNotificationsUseCase(this._repo);

  final NotificationRepository _repo;

  Stream<List<NotificationLog>> call(String profileId) {
    return _repo
        .watchForProfile(profileId)
        .map(
          (logs) =>
              logs.where((l) => _studentVisibleTypes.contains(l.type)).toList(),
        );
  }
}
