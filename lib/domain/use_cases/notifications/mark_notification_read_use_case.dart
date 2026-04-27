import '../../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repo);

  final NotificationRepository _repo;

  Future<void> call(String notificationId) async {
    await _repo.markReadAt(notificationId, DateTime.now());
  }
}
