import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/queued_check_in.dart';
import '../../domain/use_cases/attendance/create_attendance_session_use_case.dart';
import '../../domain/use_cases/attendance/discard_queued_check_in_use_case.dart';
import '../../domain/use_cases/attendance/get_attendance_records_use_case.dart';
import '../../domain/use_cases/attendance/get_attendance_sessions_use_case.dart';
import '../../domain/use_cases/attendance/mark_attendance_use_case.dart';
import '../../domain/use_cases/attendance/queue_check_in_use_case.dart';
import '../../domain/use_cases/attendance/self_check_in_use_case.dart';
import 'enrollment_providers.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final createAttendanceSessionUseCaseProvider =
    Provider<CreateAttendanceSessionUseCase>(
      (ref) => CreateAttendanceSessionUseCase(
        ref.watch(attendanceRepositoryProvider),
        ref.watch(queuedCheckInRepositoryProvider),
        ref.watch(membershipRepositoryProvider),
        ref.watch(paytSessionRepositoryProvider),
      ),
    );

final getAttendanceSessionsUseCaseProvider =
    Provider<GetAttendanceSessionsUseCase>(
      (ref) =>
          GetAttendanceSessionsUseCase(ref.watch(attendanceRepositoryProvider)),
    );

final getAttendanceRecordsUseCaseProvider =
    Provider<GetAttendanceRecordsUseCase>(
      (ref) =>
          GetAttendanceRecordsUseCase(ref.watch(attendanceRepositoryProvider)),
    );

final markAttendanceUseCaseProvider = Provider<MarkAttendanceUseCase>(
  (ref) => MarkAttendanceUseCase(
    ref.watch(attendanceRepositoryProvider),
    ref.watch(membershipRepositoryProvider),
    ref.watch(paytSessionRepositoryProvider),
  ),
);

final selfCheckInUseCaseProvider = Provider<SelfCheckInUseCase>(
  (ref) => SelfCheckInUseCase(
    ref.watch(attendanceRepositoryProvider),
    ref.watch(enrollmentRepositoryProvider),
    ref.watch(rankRepositoryProvider),
    ref.watch(enrolStudentUseCaseProvider),
    ref.watch(membershipRepositoryProvider),
    ref.watch(paytSessionRepositoryProvider),
  ),
);

final queueCheckInUseCaseProvider = Provider<QueueCheckInUseCase>(
  (ref) => QueueCheckInUseCase(ref.watch(queuedCheckInRepositoryProvider)),
);

final discardQueuedCheckInUseCaseProvider =
    Provider<DiscardQueuedCheckInUseCase>(
      (ref) => DiscardQueuedCheckInUseCase(
        ref.watch(queuedCheckInRepositoryProvider),
      ),
    );

// ── Stream / async providers ───────────────────────────────────────────────

/// All sessions, optionally filtered by disciplineId (null = all disciplines).
final attendanceSessionListProvider =
    StreamProvider.family<List<AttendanceSession>, String?>(
      (ref, disciplineId) => ref
          .watch(getAttendanceSessionsUseCaseProvider)
          .watchAll(disciplineId: disciplineId),
    );

/// Live attendance records for a specific session.
final attendanceRecordsForSessionProvider =
    StreamProvider.family<List<AttendanceRecord>, String>(
      (ref, sessionId) => ref
          .watch(getAttendanceRecordsUseCaseProvider)
          .watchForSession(sessionId),
    );

/// All pending queued check-ins, live.
final pendingQueuedCheckInsProvider = StreamProvider<List<QueuedCheckIn>>(
  (ref) => ref.watch(queuedCheckInRepositoryProvider).watchPending(),
);

/// All attendance records for a student (used for profile history tab).
final attendanceHistoryForStudentProvider =
    FutureProvider.family<List<AttendanceRecord>, String>(
      (ref, studentId) => ref
          .watch(getAttendanceRecordsUseCaseProvider)
          .getForStudent(studentId),
    );

/// Today's sessions for a specific discipline (used by student check-in flow).
final todaySessionsForDisciplineProvider =
    StreamProvider.family<List<AttendanceSession>, String>((ref, disciplineId) {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      return ref
          .watch(getAttendanceSessionsUseCaseProvider)
          .watchForDisciplineAndDate(disciplineId, today);
    });
