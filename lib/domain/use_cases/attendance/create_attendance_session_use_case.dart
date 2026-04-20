import '../../entities/attendance_record.dart';
import '../../entities/attendance_session.dart';
import '../../entities/enums.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/queued_check_in_repository.dart';

/// Result returned after creating a session.
class CreateSessionResult {
  const CreateSessionResult({
    required this.sessionId,
    required this.resolvedQueueCount,
  });

  /// The Firestore document ID of the newly created session.
  final String sessionId;

  /// Number of queued check-ins that were automatically resolved.
  final int resolvedQueueCount;
}

class CreateAttendanceSessionUseCase {
  const CreateAttendanceSessionUseCase(this._attendanceRepo, this._queueRepo);

  final AttendanceRepository _attendanceRepo;
  final QueuedCheckInRepository _queueRepo;

  Future<CreateSessionResult> call({
    required String disciplineId,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    String? notes,
    required String createdByAdminId,
  }) async {
    // ── Validation ─────────────────────────────────────────────────────────
    if (_parseTime(endTime) <= _parseTime(startTime)) {
      throw ArgumentError('End time must be after start time.');
    }

    final today = _midnight(DateTime.now());
    final date = _midnight(sessionDate);
    if (date.isAfter(today)) {
      throw ArgumentError('Session date cannot be in the future.');
    }

    // ── Write session ───────────────────────────────────────────────────────
    final session = AttendanceSession(
      id: '',
      disciplineId: disciplineId,
      sessionDate: date,
      startTime: startTime,
      endTime: endTime,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdByAdminId: createdByAdminId,
      createdAt: DateTime.now(),
    );

    final sessionId = await _attendanceRepo.createSession(session);

    // ── Auto-resolve queued check-ins (today only) ──────────────────────────
    // Edge-case per spec: past-date sessions do NOT trigger queue resolution.
    int resolvedCount = 0;
    if (date == today) {
      final pending = await _queueRepo
          .watchPendingForDisciplineAndDate(disciplineId, date)
          .first;

      final now = DateTime.now();
      for (final q in pending) {
        // Write the attendance record
        await _attendanceRepo.createRecord(
          AttendanceRecord(
            id: '',
            sessionId: sessionId,
            studentId: q.studentId,
            disciplineId: disciplineId,
            sessionDate: date,
            checkInMethod: CheckInMethod.self,
            checkedInByProfileId: q.studentId,
            timestamp: now,
          ),
        );

        // TODO(memberships): if student is PAYT, write a pending paytSessions record here.

        // Mark queued check-in resolved
        await _queueRepo.resolve(
          q.id,
          resolvedSessionId: sessionId,
          resolvedAt: now,
        );

        resolvedCount++;
      }
    }

    return CreateSessionResult(
      sessionId: sessionId,
      resolvedQueueCount: resolvedCount,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Converts "HH:mm" to minutes since midnight for comparison.
  int _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  DateTime _midnight(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);
}
