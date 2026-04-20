import '../../domain/entities/grading_record.dart';
import '../../domain/repositories/grading_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreGradingRepository implements GradingRepository {
  @override
  Future<List<GradingRecord>> getForStudent(String studentId) async {
    final snap = await FirestoreCollections.gradingRecords()
        .where('studentId', isEqualTo: studentId)
        .orderBy('gradingDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<GradingRecord>> getForDiscipline(String disciplineId) async {
    final snap = await FirestoreCollections.gradingRecords()
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('gradingDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<GradingRecord>> getForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  ) async {
    final snap = await FirestoreCollections.gradingRecords()
        .where('studentId', isEqualTo: studentId)
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('gradingDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(GradingRecord record) async {
    final ref = await FirestoreCollections.gradingRecords().add(record);
    return ref.id;
  }

  @override
  Future<void> update(GradingRecord record) async {
    await FirestoreCollections.gradingRecords().doc(record.id).set(record);
  }

  @override
  Future<void> delete(String id) async {
    await FirestoreCollections.gradingRecords().doc(id).delete();
  }

  @override
  Stream<List<GradingRecord>> watchForStudent(String studentId) {
    return FirestoreCollections.gradingRecords()
        .where('studentId', isEqualTo: studentId)
        .orderBy('gradingDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
