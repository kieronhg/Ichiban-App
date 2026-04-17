import '../../domain/entities/enrollment.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreEnrollmentRepository implements EnrollmentRepository {
  @override
  Future<List<Enrollment>> getForStudent(String studentId) async {
    final snap = await FirestoreCollections.enrollments()
        .where('studentId', isEqualTo: studentId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Enrollment>> getForDiscipline(String disciplineId) async {
    final snap = await FirestoreCollections.enrollments()
        .where('disciplineId', isEqualTo: disciplineId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<Enrollment?> getForStudentAndDiscipline(
      String studentId, String disciplineId) async {
    final snap = await FirestoreCollections.enrollments()
        .where('studentId', isEqualTo: studentId)
        .where('disciplineId', isEqualTo: disciplineId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<String> create(Enrollment enrollment) async {
    final ref = await FirestoreCollections.enrollments().add(enrollment);
    return ref.id;
  }

  @override
  Future<void> updateCurrentRank(String enrollmentId, String rankId) async {
    await FirestoreCollections.enrollments()
        .doc(enrollmentId)
        .update({'currentRankId': rankId});
  }

  @override
  Future<void> deactivate(String enrollmentId) async {
    await FirestoreCollections.enrollments()
        .doc(enrollmentId)
        .update({'isActive': false});
  }

  @override
  Stream<List<Enrollment>> watchForStudent(String studentId) {
    return FirestoreCollections.enrollments()
        .where('studentId', isEqualTo: studentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<Enrollment>> watchForDiscipline(String disciplineId) {
    return FirestoreCollections.enrollments()
        .where('disciplineId', isEqualTo: disciplineId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
