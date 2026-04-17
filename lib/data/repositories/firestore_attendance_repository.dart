import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreAttendanceRepository implements AttendanceRepository {
  // ── Sessions ──────────────────────────────────────────────────────────────

  @override
  Future<List<AttendanceSession>> getSessionsForDiscipline(
      String disciplineId) async {
    final snap = await FirestoreCollections.attendanceSessions()
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<AttendanceSession?> getSessionById(String sessionId) async {
    final snap =
        await FirestoreCollections.attendanceSessions().doc(sessionId).get();
    return snap.data();
  }

  @override
  Future<String> createSession(AttendanceSession session) async {
    final ref =
        await FirestoreCollections.attendanceSessions().add(session);
    return ref.id;
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForDiscipline(
      String disciplineId) {
    return FirestoreCollections.attendanceSessions()
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Records ───────────────────────────────────────────────────────────────

  @override
  Future<List<AttendanceRecord>> getRecordsForSession(
      String sessionId) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('sessionId', isEqualTo: sessionId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(
      String studentId) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('studentId', isEqualTo: studentId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudentAndDiscipline(
      String studentId, String disciplineId) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('studentId', isEqualTo: studentId)
        .where('disciplineId', isEqualTo: disciplineId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Returns studentIds who have an active membership but no attendance
  /// within the past [withinDays] days.
  /// Queries all active memberships, collects member IDs, then checks
  /// each for recent attendance records.
  @override
  Future<List<String>> getNonAttendingMemberIds(
      {required int withinDays}) async {
    final cutoff = DateTime.now().subtract(Duration(days: withinDays));

    // Get all active membership member IDs
    final membershipSnap = await FirestoreCollections.memberships()
        .where('isActive', isEqualTo: true)
        .get();

    final allMemberIds = <String>{};
    for (final doc in membershipSnap.docs) {
      allMemberIds.addAll(doc.data().memberProfileIds);
    }

    if (allMemberIds.isEmpty) return [];

    // Check recent attendance for each member
    final nonAttending = <String>[];
    for (final memberId in allMemberIds) {
      final recentSnap = await FirestoreCollections.attendanceRecords()
          .where('studentId', isEqualTo: memberId)
          .where('sessionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .limit(1)
          .get();
      if (recentSnap.docs.isEmpty) {
        nonAttending.add(memberId);
      }
    }

    return nonAttending;
  }

  @override
  Future<String> createRecord(AttendanceRecord record) async {
    final ref =
        await FirestoreCollections.attendanceRecords().add(record);
    return ref.id;
  }

  @override
  Future<bool> hasRecord(String sessionId, String studentId) async {
    final snap = await FirestoreCollections.attendanceRecords()
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId) {
    return FirestoreCollections.attendanceRecords()
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
