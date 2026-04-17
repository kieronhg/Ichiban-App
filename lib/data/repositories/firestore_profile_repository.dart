import '../../domain/entities/profile.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/profile_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreProfileRepository implements ProfileRepository {
  @override
  Future<Profile?> getById(String id) async {
    final snap = await FirestoreCollections.profiles().doc(id).get();
    return snap.data();
  }

  @override
  Future<List<Profile>> getAll() async {
    final snap = await FirestoreCollections.profiles().get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Profile>> getByType(ProfileType type) async {
    final snap = await FirestoreCollections.profiles()
        .where('profileType', isEqualTo: type.name)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Profile>> getJuniorsForParent(String parentProfileId) async {
    final snap = await FirestoreCollections.profiles()
        .where('parentProfileId', isEqualTo: parentProfileId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(Profile profile) async {
    final ref = await FirestoreCollections.profiles().add(profile);
    return ref.id;
  }

  @override
  Future<void> update(Profile profile) async {
    await FirestoreCollections.profiles().doc(profile.id).set(profile);
  }

  @override
  Future<void> deactivate(String id) async {
    await FirestoreCollections.profiles()
        .doc(id)
        .update({'isActive': false});
  }

  @override
  Stream<List<Profile>> watchAll() {
    return FirestoreCollections.profiles()
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<Profile?> watchById(String id) {
    return FirestoreCollections.profiles()
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }
}
