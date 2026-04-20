import '../../entities/attendance_record.dart';
import '../../entities/attendance_session.dart';
import '../../entities/enums.dart';
import '../../repositories/attendance_repository.dart';

/// Saves the attendance for a session.
///
/// [markedPresentIds] is the complete set of student IDs the coach has
/// marked as present. Students previously marked present but absent from
/// this set will have their records deleted (opt-in model).
class MarkAttendanceUseCase {
  const MarkAttendanceUseCase(this._repo);

  final AttendanceRepository _repo;

  Future<void> call({
    required AttendanceSession session,
    required Set<String> markedPresentIds,
    required String coachProfileId,
  }) async {
    // Load existing records for this session
    final existing = await _repo.watchRecordsForSession(session.id).first;

    final existingByStudent = {for (final r in existing) r.studentId: r};

    final now = DateTime.now();

    // ── Upsert records for present students ──────────────────────────────
    for (final studentId in markedPresentIds) {
      final existing_ = existingByStudent[studentId];
      if (existing_ != null) {
        // Already recorded — keep as-is (preserve original check-in method)
      } else {
        // Newly marked — create a coach record
        await _repo.createRecord(
          AttendanceRecord(
            id: '',
            sessionId: session.id,
            studentId: studentId,
            disciplineId: session.disciplineId,
            sessionDate: session.sessionDate,
            checkInMethod: CheckInMethod.coach,
            checkedInByProfileId: coachProfileId,
            timestamp: now,
          ),
        );

        // TODO(memberships): if student is PAYT, write a pending paytSessions record here.
      }
    }

    // ── Delete records for students now unmarked ─────────────────────────
    for (final entry in existingByStudent.entries) {
      if (!markedPresentIds.contains(entry.key)) {
        await _repo.deleteRecord(entry.value.id);
        // NOTE: Per spec, if a PAYT student is unmarked after a self check-in,
        // any pending paytSessions record must be cancelled manually by admin.
        // TODO(memberships): surface a warning flag here when memberships is built.
      }
    }
  }
}
