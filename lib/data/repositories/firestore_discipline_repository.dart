import '../../domain/entities/discipline.dart';
import '../../domain/repositories/discipline_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreDisciplineRepository implements DisciplineRepository {
  @override
  Future<List<Discipline>> getAll() async {
    final snap = await FirestoreCollections.disciplines().get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Discipline>> getActive() async {
    final snap = await FirestoreCollections.disciplines()
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<Discipline?> getById(String id) async {
    final snap = await FirestoreCollections.disciplines().doc(id).get();
    return snap.data();
  }

  @override
  Future<String> create(Discipline discipline) async {
    final ref = await FirestoreCollections.disciplines().add(discipline);
    return ref.id;
  }

  @override
  Future<void> update(Discipline discipline) async {
    await FirestoreCollections.disciplines()
        .doc(discipline.id)
        .set(discipline);
  }

  @override
  Stream<List<Discipline>> watchActive() {
    return FirestoreCollections.disciplines()
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
