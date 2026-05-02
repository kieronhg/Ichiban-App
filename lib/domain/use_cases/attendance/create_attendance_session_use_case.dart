import 'package:uuid/uuid.dart';

import '../../entities/attendance_record.dart';
import '../../entities/attendance_session.dart';
import '../../entities/enums.dart';
import '../../entities/payt_session.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/payt_session_repository.dart';
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
  const CreateAttendanceSessionUseCase(
    this._attendanceRepo,
    this._queueRepo,
    this._membershipRepo,
    this._paytRepo,
  );

  final AttendanceRepository _attendanceRepo;
  final QueuedCheckInRepository _queueRepo;
  final MembershipRepository _membershipRepo;
  final PaytSessionRepository _paytRepo;

  Future<CreateSessionResult> call({
    required String disciplineId,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    String? title,
    String? notes,
    required String createdByAdminId,
    bool isRecurring = false,
  }) async {
    // ── Validation ─────────────────────────────────────────────────────────
    if (_parseTime(endTime) <= _parseTime(startTime)) {
      throw ArgumentError('End time must be after start time.');
    }

    final today = _midnight(DateTime.now());
    final date = _midnight(sessionDate);
    final cleanNotes = notes?.trim().isEmpty == true ? null : notes?.trim();
    final cleanTitle = title?.trim().isEmpty == true ? null : title?.trim();
    final now = DateTime.now();

    // ── Recurring: batch-create 52 weekly sessions ──────────────────────────
    if (isRecurring) {
      final groupId = const Uuid().v4();
      final sessions = List.generate(52, (i) {
        return AttendanceSession(
          id: '',
          title: cleanTitle,
          disciplineId: disciplineId,
          sessionDate: date.add(Duration(days: 7 * i)),
          startTime: startTime,
          endTime: endTime,
          notes: cleanNotes,
          createdByAdminId: createdByAdminId,
          createdAt: now,
          isRecurring: true,
          recurringGroupId: groupId,
        );
      });

      final ids = await _attendanceRepo.createSessionBatch(sessions);

      // Auto-resolve queued check-ins for today's session if it falls today.
      int resolvedCount = 0;
      if (date == today) {
        resolvedCount = await _resolveQueuedCheckIns(
          sessionId: ids.first,
          disciplineId: disciplineId,
          date: date,
          now: now,
        );
      }

      return CreateSessionResult(
        sessionId: ids.first,
        resolvedQueueCount: resolvedCount,
      );
    }

    // ── Single session ──────────────────────────────────────────────────────
    final session = AttendanceSession(
      id: '',
      title: cleanTitle,
      disciplineId: disciplineId,
      sessionDate: date,
      startTime: startTime,
      endTime: endTime,
      notes: cleanNotes,
      createdByAdminId: createdByAdminId,
      createdAt: now,
    );

    final sessionId = await _attendanceRepo.createSession(session);

    // Auto-resolve queued check-ins (today only).
    int resolvedCount = 0;
    if (date == today) {
      resolvedCount = await _resolveQueuedCheckIns(
        sessionId: sessionId,
        disciplineId: disciplineId,
        date: date,
        now: now,
      );
    }

    return CreateSessionResult(
      sessionId: sessionId,
      resolvedQueueCount: resolvedCount,
    );
  }

  Future<int> _resolveQueuedCheckIns({
    required String sessionId,
    required String disciplineId,
    required DateTime date,
    required DateTime now,
  }) async {
    final pending = await _queueRepo
        .watchPendingForDisciplineAndDate(disciplineId, date)
        .first;

    int count = 0;
    for (final q in pending) {
      final recordId = await _attendanceRepo.createRecord(
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

      final membership = await _membershipRepo.getActiveForProfile(q.studentId);
      if (membership != null && membership.isPayAsYouTrain) {
        await _paytRepo.create(
          PaytSession(
            id: '',
            profileId: q.studentId,
            disciplineId: disciplineId,
            sessionDate: date,
            attendanceRecordId: recordId,
            paymentMethod: PaymentMethod.none,
            paymentStatus: PaytPaymentStatus.pending,
            amount: membership.monthlyAmount,
            createdAt: now,
          ),
        );
      }

      await _queueRepo.resolve(
        q.id,
        resolvedSessionId: sessionId,
        resolvedAt: now,
      );

      count++;
    }
    return count;
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
