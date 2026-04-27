import '../../entities/enums.dart';
import '../../entities/notification_log.dart';
import '../../repositories/notification_repository.dart';

class GetAdminNotificationLogsUseCase {
  const GetAdminNotificationLogsUseCase(this._repo);

  final NotificationRepository _repo;

  Future<List<NotificationLog>> call({
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? status,
    DateTime? from,
    DateTime? to,
    String? recipientProfileId,
    int limit = 200,
  }) {
    return _repo.getAll(
      type: type,
      channel: channel,
      status: status,
      from: from,
      to: to,
      recipientProfileId: recipientProfileId,
      limit: limit,
    );
  }
}
