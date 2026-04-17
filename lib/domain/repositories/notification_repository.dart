import '../entities/notification_log.dart';

abstract class NotificationRepository {
  /// Returns all notification logs for a profile, ordered by sentAt descending.
  Future<List<NotificationLog>> getForProfile(String profileId);

  /// Creates a notification log entry and returns the generated document ID.
  Future<String> create(NotificationLog log);

  /// Marks a push notification as read.
  Future<void> markRead(String id);

  /// Watches notification logs for a profile in real time.
  Stream<List<NotificationLog>> watchForProfile(String profileId);
}
