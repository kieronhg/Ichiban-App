import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/queued_check_in.dart';
import '../../domain/repositories/queued_check_in_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreQueuedCheckInRepository implements QueuedCheckInRepository {
  @override
  Stream<List<QueuedCheckIn>> watchPending() {
    return FirestoreCollections.queuedCheckIns()
        .where('status', isEqualTo: QueuedCheckInStatus.pending.name)
        .orderBy('queuedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<QueuedCheckIn>> watchPendingForDisciplineAndDate(
    String disciplineId,
    DateTime date,
  ) {
    final midnight = _midnight(date);
    return FirestoreCollections.queuedCheckIns()
        .where('disciplineId', isEqualTo: disciplineId)
        .where('queueDate', isEqualTo: Timestamp.fromDate(midnight))
        .where('status', isEqualTo: QueuedCheckInStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<QueuedCheckIn?> getPendingForStudentDisciplineAndDate(
    String studentId,
    String disciplineId,
    DateTime date,
  ) async {
    final midnight = _midnight(date);
    final snap = await FirestoreCollections.queuedCheckIns()
        .where('studentId', isEqualTo: studentId)
        .where('disciplineId', isEqualTo: disciplineId)
        .where('queueDate', isEqualTo: Timestamp.fromDate(midnight))
        .where('status', isEqualTo: QueuedCheckInStatus.pending.name)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<String> create(QueuedCheckIn queuedCheckIn) async {
    final ref = await FirestoreCollections.queuedCheckIns().add(queuedCheckIn);
    return ref.id;
  }

  @override
  Future<void> resolve(
    String id, {
    required String resolvedSessionId,
    required DateTime resolvedAt,
  }) async {
    await FirestoreCollections.queuedCheckIns().doc(id).update({
      'status': QueuedCheckInStatus.resolved.name,
      'resolvedSessionId': resolvedSessionId,
      'resolvedAt': Timestamp.fromDate(resolvedAt),
    });
  }

  @override
  Future<void> discard(
    String id, {
    required String discardedByAdminId,
    required DateTime discardedAt,
  }) async {
    await FirestoreCollections.queuedCheckIns().doc(id).update({
      'status': QueuedCheckInStatus.discarded.name,
      'discardedByAdminId': discardedByAdminId,
      'discardedAt': Timestamp.fromDate(discardedAt),
    });
  }

  @override
  Future<void> discardAllForDisciplineAndDate(
    String disciplineId,
    DateTime date, {
    required String discardedByAdminId,
    required DateTime discardedAt,
  }) async {
    final midnight = _midnight(date);
    final snap = await FirestoreCollections.queuedCheckIns()
        .where('disciplineId', isEqualTo: disciplineId)
        .where('queueDate', isEqualTo: Timestamp.fromDate(midnight))
        .where('status', isEqualTo: QueuedCheckInStatus.pending.name)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': QueuedCheckInStatus.discarded.name,
        'discardedByAdminId': discardedByAdminId,
        'discardedAt': Timestamp.fromDate(discardedAt),
      });
    }
    await batch.commit();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _midnight(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);
}
