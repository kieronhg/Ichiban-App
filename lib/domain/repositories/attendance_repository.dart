import '../entities/attendance_session.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  // ── Sessions ──────────────────────────────────────────────

  /// All sessions, optionally filtered by discipline, ordered by date desc.
  Stream<List<AttendanceSession>> watchAllSessions({String? disciplineId});

  /// Sessions for a specific discipline on a specific date (midnight UTC).
  Stream<List<AttendanceSession>> watchSessionsForDisciplineAndDate(
    String disciplineId,
    DateTime date,
  );

  /// Returns a single session by ID, or null if not found.
  Future<AttendanceSession?> getSessionById(String sessionId);

  /// Creates an attendance session and returns the generated document ID.
  Future<String> createSession(AttendanceSession session);

  /// Batch-creates multiple sessions (used for recurring series) and returns
  /// the list of generated document IDs in the same order.
  Future<List<String>> createSessionBatch(List<AttendanceSession> sessions);

  /// Updates mutable fields (title, startTime, endTime, notes) on all sessions
  /// that share [groupId] and whose sessionDate is on or after [fromDate].
  Future<void> updateFutureSessionsInGroup({
    required String groupId,
    required DateTime fromDate,
    String? title,
    required String startTime,
    required String endTime,
    String? notes,
  });

  /// Updates mutable fields on a single session document by ID.
  Future<void> updateSingleSession({
    required String sessionId,
    String? title,
    required String startTime,
    required String endTime,
    String? notes,
  });

  // ── Records ───────────────────────────────────────────────

  /// Watches attendance records for a session in real time.
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId);

  /// Returns all attendance records for a student, ordered by date desc.
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId);

  /// Returns attendance records for a student within a specific discipline.
  Future<List<AttendanceRecord>> getRecordsForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  );

  /// Returns the attendance record for a student in a specific session,
  /// or null if none exists.
  Future<AttendanceRecord?> getRecordForStudentAndSession(
    String studentId,
    String sessionId,
  );

  /// Writes an attendance record, overwriting any existing document with the
  /// same ID (upsert semantics).
  Future<void> upsertRecord(AttendanceRecord record);

  /// Deletes an attendance record by ID.
  Future<void> deleteRecord(String recordId);

  /// Creates a new attendance record and returns the generated document ID.
  Future<String> createRecord(AttendanceRecord record);

  /// Returns student IDs who have an active membership but no attendance
  /// records within the past [withinDays] days.
  Future<List<String>> getNonAttendingMemberIds({required int withinDays});

  /// All sessions for a date (midnight UTC), across all disciplines.
  Stream<List<AttendanceSession>> watchSessionsForDate(DateTime date);

  /// Most-recent [limit] sessions, ordered by createdAt descending.
  Future<List<AttendanceSession>> getRecentSessions(int limit);

  /// All attendance records with a sessionDate in [from, to).
  Future<List<AttendanceRecord>> getRecordsForPeriod(
    DateTime from,
    DateTime to,
  );
}
