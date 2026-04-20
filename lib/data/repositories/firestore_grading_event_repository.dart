import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/grading_event.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/grading_event_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreGradingEventRepository implements GradingEventRepository {
  @override
  Future<List<GradingEvent>> getAll() async {
    final snap = await FirestoreCollections.gradingEvents()
        .orderBy('eventDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<GradingEvent>> getForDiscipline(String disciplineId) async {
    final snap = await FirestoreCollections.gradingEvents()
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('eventDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Stream<List<GradingEvent>> watchForDiscipline(String disciplineId) {
    return FirestoreCollections.gradingEvents()
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<GradingEvent>> watchAll() {
    return FirestoreCollections.gradingEvents()
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<String> create(GradingEvent event) async {
    final ref = await FirestoreCollections.gradingEvents().add(event);
    return ref.id;
  }

  @override
  Future<void> updateStatus(
    String id,
    GradingEventStatus status, {
    String? cancelledByAdminId,
    DateTime? cancelledAt,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (cancelledByAdminId != null) {
      data['cancelledByAdminId'] = cancelledByAdminId;
    }
    if (cancelledAt != null) {
      data['cancelledAt'] = Timestamp.fromDate(cancelledAt);
    }
    await FirestoreCollections.gradingEvents().doc(id).update(data);
  }
}
