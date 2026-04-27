import '../entities/enums.dart';
import '../entities/notification_log.dart';

abstract class NotificationRepository {
  /// Returns all notification logs for a profile, ordered by sentAt descending.
  Future<List<NotificationLog>> getForProfile(String profileId);

  /// Creates a notification log entry and returns the generated document ID.
  Future<String> create(NotificationLog log);

  /// Marks a push notification as read and records the read timestamp.
  Future<void> markReadAt(String id, DateTime readAt);

  /// Watches notification logs for a profile in real time.
  Stream<List<NotificationLog>> watchForProfile(String profileId);

  /// Returns all notification logs, most recent first, with optional filters.
  /// Fetches up to [limit] records (default 200).
  Future<List<NotificationLog>> getAll({
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? status,
    DateTime? from,
    DateTime? to,
    String? recipientProfileId,
    int limit,
  });

  /// Watches the count of unread deliveryFailure notifications for [adminUserId].
  Stream<int> watchUnreadFailureCount(String adminUserId);
}
