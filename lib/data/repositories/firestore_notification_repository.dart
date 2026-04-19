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
  Future<void> markRead(String id) async {
    await FirestoreCollections.notificationLogs().doc(id).update({
      'isRead': true,
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
}
