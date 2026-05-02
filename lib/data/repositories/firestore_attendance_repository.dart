import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAttendanceRepository implements AttendanceRepository {
  // ── Sessions ──────────────────────────────────────────────────────────────

  @override
  Stream<List<AttendanceSession>> watchAllSessions({String? disciplineId}) {
    var query = FirestoreCollections.attendanceSessions().orderBy(
      'sessionDate',
      descending: true,
    );
    if (disciplineId != null) {
      query = query.where('disciplineId', isEqualTo: disciplineId);
    }
    return query.snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForDisciplineAndDate(
    String disciplineId,
    DateTime date,
  ) {
    final midnight = _midnight(date);
    return FirestoreCollections.attendanceSessions()
        .where('disciplineId', isEqualTo: disciplineId)
        .where('sessionDate', isEqualTo: Timestamp.fromDate(midnight))
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<AttendanceSession?> getSessionById(String sessionId) async {
    final snap = await FirestoreCollections.attendanceSessions()
        .doc(sessionId)
        .get();
    return snap.data();
  }

  @override
  Future<String> createSession(AttendanceSession session) async {
    final ref = await FirestoreCollections.attendanceSessions().add(session);
    return ref.id;
  }

  @override
  Future<List<String>> createSessionBatch(
    List<AttendanceSession> sessions,
  ) async {
    // Firestore batch writes are limited to 500 operations; 52 sessions is safe.
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final col = FirestoreCollections.attendanceSessions();
    final refs = [for (final _ in sessions) col.doc()];

    for (var i = 0; i < sessions.length; i++) {
      batch.set(refs[i], sessions[i]);
    }
    await batch.commit();
    return refs.map((r) => r.id).toList();
  }

  @override
  Future<void> updateFutureSessionsInGroup({
    required String groupId,
    required DateTime fromDate,
    String? title,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    final snap = await FirestoreCollections.attendanceSessions()
        .where('recurringGroupId', isEqualTo: groupId)
        .where(
          'sessionDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_midnight(fromDate)),
        )
        .get();

    if (snap.docs.isEmpty) return;

    final db = FirebaseFirestore.instance;
    // Split into chunks of 500 to respect Firestore batch limits.
    const chunkSize = 500;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final chunk = snap.docs.skip(i).take(chunkSize).toList();
      final batch = db.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'title': title,
          'startTime': startTime,
          'endTime': endTime,
          'notes': notes,
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> updateSingleSession({
    required String sessionId,
    String? title,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    await FirestoreCollections.attendanceSessions().doc(sessionId).update({
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes,
    });
  }

  // ── Records ───────────────────────────────────────────────────────────────

  @override
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId) {
    return FirestoreCollections.attendanceRecords()
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('studentId', isEqualTo: studentId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  ) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('studentId', isEqualTo: studentId)
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<AttendanceRecord?> getRecordForStudentAndSession(
    String studentId,
    String sessionId,
  ) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('studentId', isEqualTo: studentId)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<void> upsertRecord(AttendanceRecord record) async {
    if (record.id.isNotEmpty) {
      await FirestoreCollections.attendanceRecords().doc(record.id).set(record);
    } else {
      await FirestoreCollections.attendanceRecords().add(record);
    }
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    await FirestoreCollections.attendanceRecords().doc(recordId).delete();
  }

  @override
  Future<String> createRecord(AttendanceRecord record) async {
    final ref = await FirestoreCollections.attendanceRecords().add(record);
    return ref.id;
  }

  @override
  Future<List<String>> getNonAttendingMemberIds({
    required int withinDays,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: withinDays));
    final membershipSnap = await FirestoreCollections.memberships()
        .where('isActive', isEqualTo: true)
        .get();

    final allMemberIds = <String>{};
    for (final doc in membershipSnap.docs) {
      allMemberIds.addAll(doc.data().memberProfileIds);
    }
    if (allMemberIds.isEmpty) return [];

    final nonAttending = <String>[];
    for (final memberId in allMemberIds) {
      final recentSnap = await FirestoreCollections.attendanceRecords()
          .where('studentId', isEqualTo: memberId)
          .where(
            'sessionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
          )
          .limit(1)
          .get();
      if (recentSnap.docs.isEmpty) nonAttending.add(memberId);
    }
    return nonAttending;
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForDate(DateTime date) {
    final midnight = _midnight(date);
    return FirestoreCollections.attendanceSessions()
        .where('sessionDate', isEqualTo: Timestamp.fromDate(midnight))
        .orderBy('startTime')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(int limit) async {
    final snap = await FirestoreCollections.attendanceSessions()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where(
          'sessionDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_midnight(from)),
        )
        .where('sessionDate', isLessThan: Timestamp.fromDate(_midnight(to)))
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _midnight(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);
}
