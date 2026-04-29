import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/grading_event_student.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/grading_event_student_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreGradingEventStudentRepository
    implements GradingEventStudentRepository {
  @override
  Future<List<GradingEventStudent>> getForEvent(String gradingEventId) async {
    final snap = await FirestoreCollections.gradingEventStudents()
        .where('gradingEventId', isEqualTo: gradingEventId)
        .orderBy('nominatedAt')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Stream<List<GradingEventStudent>> watchForEvent(String gradingEventId) {
    return FirestoreCollections.gradingEventStudents()
        .where('gradingEventId', isEqualTo: gradingEventId)
        .orderBy('nominatedAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<List<GradingEventStudent>> getForStudent(String studentId) async {
    final snap = await FirestoreCollections.gradingEventStudents()
        .where('studentId', isEqualTo: studentId)
        .orderBy('nominatedAt', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(GradingEventStudent record) async {
    final ref = await FirestoreCollections.gradingEventStudents().add(record);
    return ref.id;
  }

  @override
  Future<void> recordOutcome({
    required String id,
    required GradingOutcome outcome,
    String? rankAchievedId,
    double? gradingScore,
    required String resultRecordedByAdminId,
    required DateTime resultRecordedAt,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'outcome': outcome.name,
      'rankAchievedId': rankAchievedId,
      'gradingScore': gradingScore,
      'resultRecordedByAdminId': resultRecordedByAdminId,
      'resultRecordedAt': Timestamp.fromDate(resultRecordedAt),
      'notes': notes,
    };
    await FirestoreCollections.gradingEventStudents().doc(id).update(data);
  }

  @override
  Future<void> markNotificationSent(String id, DateTime sentAt) async {
    await FirestoreCollections.gradingEventStudents().doc(id).update({
      'notificationSentAt': Timestamp.fromDate(sentAt),
    });
  }

  @override
  Future<void> delete(String id) async {
    await FirestoreCollections.gradingEventStudents().doc(id).delete();
  }

  @override
  Future<List<GradingEventStudent>> getWithOutcomeFrom(DateTime from) async {
    final snap = await FirestoreCollections.gradingEventStudents()
        .where(
          'resultRecordedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .get();
    return snap.docs
        .map((d) => d.data())
        .where((s) => s.outcome != null)
        .toList();
  }
}
