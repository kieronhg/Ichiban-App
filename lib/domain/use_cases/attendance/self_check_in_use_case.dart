import '../../entities/attendance_record.dart';
import '../../entities/enums.dart';
import '../../entities/payt_session.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/enrollment_repository.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/payt_session_repository.dart';
import '../../repositories/rank_repository.dart';
import '../enrollment/enrol_student_use_case.dart';

/// Possible outcomes of a self check-in attempt.
enum SelfCheckInResult {
  /// Check-in recorded successfully.
  success,

  /// Student was already checked in to this session.
  alreadyCheckedIn,

  /// Student was auto-enrolled at bottom rank before check-in succeeded.
  successWithAutoEnrol,

  /// Check-in recorded, but the student's membership is lapsed or expired.
  /// The student should be advised to contact the dojo.
  successWithMembershipWarning,
}

class SelfCheckInUseCase {
  const SelfCheckInUseCase(
    this._attendanceRepo,
    this._enrollmentRepo,
    this._rankRepo,
    this._enrolStudentUseCase,
    this._membershipRepo,
    this._paytRepo,
  );

  final AttendanceRepository _attendanceRepo;
  final EnrollmentRepository _enrollmentRepo;
  final RankRepository _rankRepo;
  final EnrolStudentUseCase _enrolStudentUseCase;
  final MembershipRepository _membershipRepo;
  final PaytSessionRepository _paytRepo;

  Future<SelfCheckInResult> call({
    required String studentId,
    required String sessionId,
    required String disciplineId,
    required DateTime sessionDate,
    required DateTime studentDateOfBirth,
  }) async {
    // ── Duplicate check ──────────────────────────────────────────────────
    final existing = await _attendanceRepo.getRecordForStudentAndSession(
      studentId,
      sessionId,
    );
    if (existing != null) return SelfCheckInResult.alreadyCheckedIn;

    // ── Auto-enrolment if not enrolled ───────────────────────────────────
    final activeEnrollments = await _enrollmentRepo.getAllForStudent(studentId);
    final isEnrolled = activeEnrollments
        .where((e) => e.isActive)
        .any((e) => e.disciplineId == disciplineId);

    bool autoEnrolled = false;
    if (!isEnrolled) {
      // Fetch ranks to get the bottom rank (last in displayOrder ascending)
      final ranks = await _rankRepo.getForDiscipline(disciplineId);
      if (ranks.isEmpty) {
        throw StateError(
          'Cannot auto-enrol: no ranks found for discipline $disciplineId.',
        );
      }
      // AgeRestrictionException propagates — caller shows "speak to a coach".
      await _enrolStudentUseCase.call(
        studentId: studentId,
        disciplineId: disciplineId,
        startingRankId: ranks.last.id,
        dateOfBirth: studentDateOfBirth,
      );
      autoEnrolled = true;
    }

    // ── Write attendance record ──────────────────────────────────────────
    final midnight = DateTime.utc(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );
    final now = DateTime.now();

    final recordId = await _attendanceRepo.createRecord(
      AttendanceRecord(
        id: '',
        sessionId: sessionId,
        studentId: studentId,
        disciplineId: disciplineId,
        sessionDate: midnight,
        checkInMethod: CheckInMethod.self,
        checkedInByProfileId: studentId,
        timestamp: now,
      ),
    );

    // ── Create pending PAYT session if applicable ────────────────────────
    final membership = await _membershipRepo.getActiveForProfile(studentId);
    if (membership != null && membership.isPayAsYouTrain) {
      await _paytRepo.create(
        PaytSession(
          id: '',
          profileId: studentId,
          disciplineId: disciplineId,
          sessionDate: midnight,
          attendanceRecordId: recordId,
          paymentMethod: PaymentMethod.none,
          paymentStatus: PaytPaymentStatus.pending,
          amount: membership.monthlyAmount,
          createdAt: now,
        ),
      );
    }

    // If membership is lapsed or expired, check-in still succeeds but the
    // student sees a warning to contact the dojo.
    final membershipStatus = membership?.status;
    final hasLapsedMembership =
        membershipStatus == MembershipStatus.lapsed ||
        membershipStatus == MembershipStatus.expired;
    if (hasLapsedMembership) {
      return SelfCheckInResult.successWithMembershipWarning;
    }

    return autoEnrolled
        ? SelfCheckInResult.successWithAutoEnrol
        : SelfCheckInResult.success;
  }
}
