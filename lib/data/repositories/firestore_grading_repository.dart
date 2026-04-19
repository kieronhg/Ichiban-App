import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Creates an eligibility entry per student using a Firestore batch write.
  /// Note: rankAchievedId is set to empty string at this stage —
  /// it is updated to the actual rank ID when the grade is awarded in Phase 7.
  @override
  Future<void> markEligible({
    required List<String> studentIds,
    required String disciplineId,
    required DateTime gradingDate,
    required String coachId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (final studentId in studentIds) {
      final ref = FirestoreCollections.gradingRecords().doc();
      final record = GradingRecord(
        id: ref.id,
        studentId: studentId,
        disciplineId: disciplineId,
        // enrollmentId resolved by the use case layer before calling this method
        enrollmentId: '',
        // Placeholder — updated when grade is awarded
        rankAchievedId: '',
        gradingDate: gradingDate,
        markedEligibleByCoachId: coachId,
        eligibilityAnnouncedDate: now,
      );
      batch.set(ref, record);
    }

    await batch.commit();
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
