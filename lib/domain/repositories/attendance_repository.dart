import '../entities/attendance_session.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  // ── Sessions ──────────────────────────────────────────────

  /// Returns all sessions for a discipline, ordered by sessionDate descending.
  Future<List<AttendanceSession>> getSessionsForDiscipline(String disciplineId);

  /// Returns a single session by ID, or null if not found.
  Future<AttendanceSession?> getSessionById(String sessionId);

  /// Creates an attendance session and returns the generated document ID.
  Future<String> createSession(AttendanceSession session);

  /// Watches sessions for a discipline in real time.
  Stream<List<AttendanceSession>> watchSessionsForDiscipline(String disciplineId);

  // ── Records ───────────────────────────────────────────────

  /// Returns all attendance records for a session.
  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId);

  /// Returns all attendance records for a student, ordered by sessionDate descending.
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId);

  /// Returns attendance records for a student within a specific discipline.
  Future<List<AttendanceRecord>> getRecordsForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  );

  /// Returns student IDs who have an active membership but no attendance
  /// records within the past [withinDays] days.
  Future<List<String>> getNonAttendingMemberIds({required int withinDays});

  /// Creates an attendance record and returns the generated document ID.
  Future<String> createRecord(AttendanceRecord record);

  /// Returns true if a student already has a record for a given session.
  Future<bool> hasRecord(String sessionId, String studentId);

  /// Watches attendance records for a session in real time.
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId);
}
