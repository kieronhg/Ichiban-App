import '../../domain/entities/membership_history.dart';
import '../../domain/repositories/membership_history_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreMembershipHistoryRepository
    implements MembershipHistoryRepository {
  @override
  Future<String> create(MembershipHistory record) async {
    final ref = await FirestoreCollections.membershipHistory().add(record);
    return ref.id;
  }

  @override
  Future<List<MembershipHistory>> getForMembership(String membershipId) async {
    final snap = await FirestoreCollections.membershipHistory()
        .where('membershipId', isEqualTo: membershipId)
        .orderBy('changedAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Stream<List<MembershipHistory>> watchForMembership(String membershipId) {
    return FirestoreCollections.membershipHistory()
        .where('membershipId', isEqualTo: membershipId)
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<List<MembershipHistory>> getRecent(int limit) async {
    final snap = await FirestoreCollections.membershipHistory()
        .orderBy('changedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
