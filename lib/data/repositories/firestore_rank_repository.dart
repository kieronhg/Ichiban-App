import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rank.dart';
import '../../domain/repositories/rank_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreRankRepository implements RankRepository {
  @override
  Future<List<Rank>> getForDiscipline(String disciplineId) async {
    final snap = await FirestoreCollections.ranks(
      disciplineId,
    ).orderBy('displayOrder').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<Rank?> getById(String disciplineId, String rankId) async {
    final snap = await FirestoreCollections.ranks(
      disciplineId,
    ).doc(rankId).get();
    return snap.data();
  }

  @override
  Future<String> create(Rank rank) async {
    final ref = await FirestoreCollections.ranks(rank.disciplineId).add(rank);
    return ref.id;
  }

  @override
  Future<void> update(Rank rank) async {
    await FirestoreCollections.ranks(rank.disciplineId).doc(rank.id).set(rank);
  }

  @override
  Future<void> delete(String disciplineId, String rankId) async {
    await FirestoreCollections.ranks(disciplineId).doc(rankId).delete();
  }

  @override
  Future<void> reorder(String disciplineId, List<String> orderedRankIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < orderedRankIds.length; i++) {
      final ref = FirestoreCollections.ranks(
        disciplineId,
      ).doc(orderedRankIds[i]);
      batch.update(ref, {'displayOrder': i});
    }
    await batch.commit();
  }

  @override
  Stream<List<Rank>> watchForDiscipline(String disciplineId) {
    return FirestoreCollections.ranks(disciplineId)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
