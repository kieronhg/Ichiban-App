import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAnnouncementRepository implements AnnouncementRepository {
  @override
  Future<List<Announcement>> getAll() async {
    final snap = await FirestoreCollections.announcements()
        .orderBy('sentAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<Announcement?> getById(String id) async {
    final snap = await FirestoreCollections.announcements().doc(id).get();
    return snap.data();
  }

  @override
  Stream<List<Announcement>> watchAll() {
    return FirestoreCollections.announcements()
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
