import '../../entities/attendance_record.dart';
import '../../entities/attendance_session.dart';
import '../../entities/enums.dart';
import '../../entities/payt_session.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/payt_session_repository.dart';

/// Saves the attendance for a session.
///
/// [markedPresentIds] is the complete set of student IDs the coach has
/// marked as present. Students previously marked present but absent from
/// this set will have their records deleted (opt-in model).
class MarkAttendanceUseCase {
  const MarkAttendanceUseCase(this._repo, this._membershipRepo, this._paytRepo);

  final AttendanceRepository _repo;
  final MembershipRepository _membershipRepo;
  final PaytSessionRepository _paytRepo;

  Future<void> call({
    required AttendanceSession session,
    required Set<String> markedPresentIds,
    required String coachProfileId,
  }) async {
    // Load existing records for this session
    final existing = await _repo.watchRecordsForSession(session.id).first;

    final existingByStudent = {for (final r in existing) r.studentId: r};

    final now = DateTime.now();
    final midnight = DateTime.utc(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
    );

    // ── Upsert records for present students ──────────────────────────────
    for (final studentId in markedPresentIds) {
      final existingRecord = existingByStudent[studentId];
      if (existingRecord != null) {
        // Already recorded — keep as-is (preserve original check-in method)
      } else {
        // Newly marked — create a coach record
        final recordId = await _repo.createRecord(
          AttendanceRecord(
            id: '',
            sessionId: session.id,
            studentId: studentId,
            disciplineId: session.disciplineId,
            sessionDate: midnight,
            checkInMethod: CheckInMethod.coach,
            checkedInByProfileId: coachProfileId,
            timestamp: now,
          ),
        );

        // Create a pending PAYT session if the student is on a PAYT plan
        final membership = await _membershipRepo.getActiveForProfile(studentId);
        if (membership != null && membership.isPayAsYouTrain) {
          await _paytRepo.create(
            PaytSession(
              id: '',
              profileId: studentId,
              disciplineId: session.disciplineId,
              sessionDate: midnight,
              attendanceRecordId: recordId,
              paymentMethod: PaymentMethod.none,
              paymentStatus: PaytPaymentStatus.pending,
              amount: membership.monthlyAmount,
              createdAt: now,
            ),
          );
        }
      }
    }

    // ── Delete records for students now unmarked ─────────────────────────
    for (final entry in existingByStudent.entries) {
      if (!markedPresentIds.contains(entry.key)) {
        await _repo.deleteRecord(entry.value.id);
        // NOTE: Per spec, if a PAYT student is unmarked after a self check-in,
        // any pending paytSessions record must be cancelled manually by admin.
        // TODO(auth-session): surface a warning flag here when auth/session is built.
      }
    }
  }
}
