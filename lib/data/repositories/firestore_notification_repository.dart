import '../../domain/entities/enums.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/repositories/notification_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationLog>> getForProfile(String profileId) async {
    final snap = await FirestoreCollections.notificationLogs()
        .where('recipientProfileId', isEqualTo: profileId)
        .orderBy('sentAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(NotificationLog log) async {
    final ref = await FirestoreCollections.notificationLogs().add(log);
    return ref.id;
  }

  @override
  Future<void> markReadAt(String id, DateTime readAt) async {
    await FirestoreCollections.notificationLogs().doc(id).update({
      'isRead': true,
      'readAt': readAt.toUtc().toIso8601String(),
    });
  }

  @override
  Stream<List<NotificationLog>> watchForProfile(String profileId) {
    return FirestoreCollections.notificationLogs()
        .where('recipientProfileId', isEqualTo: profileId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<List<NotificationLog>> getAll({
    NotificationType? type,
    NotificationChannel? channel,
    NotificationDeliveryStatus? status,
    DateTime? from,
    DateTime? to,
    String? recipientProfileId,
    int limit = 200,
  }) async {
    var query = FirestoreCollections.notificationLogs()
        .orderBy('sentAt', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (recipientProfileId != null) {
      query = query.where('recipientProfileId', isEqualTo: recipientProfileId);
    }

    final snap = await query.get();
    var results = snap.docs.map((d) => d.data()).toList();

    // Client-side filters for fields without compound index requirements.
    if (channel != null) {
      results = results.where((l) => l.channel == channel).toList();
    }
    if (status != null) {
      results = results.where((l) => l.deliveryStatus == status).toList();
    }
    if (from != null) {
      results = results.where((l) => !l.sentAt.isBefore(from)).toList();
    }
    if (to != null) {
      results = results.where((l) => !l.sentAt.isAfter(to)).toList();
    }

    return results;
  }

  @override
  Stream<int> watchUnreadFailureCount(String adminUserId) {
    return FirestoreCollections.notificationLogs()
        .where('recipientProfileId', isEqualTo: adminUserId)
        .where('type', isEqualTo: NotificationType.deliveryFailure.name)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
