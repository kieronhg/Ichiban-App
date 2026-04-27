import '../../repositories/notification_repository.dart';

class WatchUnreadFailureCountUseCase {
  const WatchUnreadFailureCountUseCase(this._repo);

  final NotificationRepository _repo;

  Stream<int> call(String adminUserId) {
    return _repo.watchUnreadFailureCount(adminUserId);
  }
}
