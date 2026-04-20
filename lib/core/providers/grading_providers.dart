import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/grading_event.dart';
import '../../domain/entities/grading_event_student.dart';
import '../../domain/entities/grading_record.dart';
import '../../domain/use_cases/grading/cancel_grading_event_use_case.dart';
import '../../domain/use_cases/grading/complete_grading_event_use_case.dart';
import '../../domain/use_cases/grading/create_grading_event_use_case.dart';
import '../../domain/use_cases/grading/delete_grading_record_use_case.dart';
import '../../domain/use_cases/grading/edit_grading_record_use_case.dart';
import '../../domain/use_cases/grading/get_grading_event_students_use_case.dart';
import '../../domain/use_cases/grading/get_grading_events_use_case.dart';
import '../../domain/use_cases/grading/nominate_student_use_case.dart';
import '../../domain/use_cases/grading/record_grading_results_use_case.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final createGradingEventUseCaseProvider = Provider<CreateGradingEventUseCase>(
  (ref) => CreateGradingEventUseCase(ref.watch(gradingEventRepositoryProvider)),
);

final cancelGradingEventUseCaseProvider = Provider<CancelGradingEventUseCase>(
  (ref) => CancelGradingEventUseCase(ref.watch(gradingEventRepositoryProvider)),
);

final completeGradingEventUseCaseProvider =
    Provider<CompleteGradingEventUseCase>(
      (ref) => CompleteGradingEventUseCase(
        ref.watch(gradingEventRepositoryProvider),
      ),
    );

final nominateStudentUseCaseProvider = Provider<NominateStudentUseCase>(
  (ref) => NominateStudentUseCase(
    ref.watch(gradingEventStudentRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);

final recordGradingResultsUseCaseProvider =
    Provider<RecordGradingResultsUseCase>(
      (ref) => RecordGradingResultsUseCase(
        ref.watch(gradingRepositoryProvider),
        ref.watch(gradingEventStudentRepositoryProvider),
        ref.watch(notificationRepositoryProvider),
      ),
    );

final getGradingEventsUseCaseProvider = Provider<GetGradingEventsUseCase>(
  (ref) => GetGradingEventsUseCase(ref.watch(gradingEventRepositoryProvider)),
);

final getGradingEventStudentsUseCaseProvider =
    Provider<GetGradingEventStudentsUseCase>(
      (ref) => GetGradingEventStudentsUseCase(
        ref.watch(gradingEventStudentRepositoryProvider),
      ),
    );

final editGradingRecordUseCaseProvider = Provider<EditGradingRecordUseCase>(
  (ref) => EditGradingRecordUseCase(ref.watch(gradingRepositoryProvider)),
);

final deleteGradingRecordUseCaseProvider = Provider<DeleteGradingRecordUseCase>(
  (ref) => DeleteGradingRecordUseCase(ref.watch(gradingRepositoryProvider)),
);

// ── Stream / async providers ───────────────────────────────────────────────

/// All grading events, live (most recent first).
final gradingEventListProvider = StreamProvider<List<GradingEvent>>(
  (ref) => ref.watch(getGradingEventsUseCaseProvider).watchAll(),
);

/// Grading events for a specific discipline, live.
final gradingEventsForDisciplineProvider =
    StreamProvider.family<List<GradingEvent>, String>(
      (ref, disciplineId) => ref
          .watch(getGradingEventsUseCaseProvider)
          .watchForDiscipline(disciplineId),
    );

/// Student nomination records for a specific grading event, live.
final gradingEventStudentsProvider =
    StreamProvider.family<List<GradingEventStudent>, String>(
      (ref, gradingEventId) => ref
          .watch(getGradingEventStudentsUseCaseProvider)
          .watchForEvent(gradingEventId),
    );

/// Grading records for a student, live.
final gradingRecordsForStudentProvider =
    StreamProvider.family<List<GradingRecord>, String>(
      (ref, studentId) =>
          ref.watch(gradingRepositoryProvider).watchForStudent(studentId),
    );

/// Past grading records for a student in a specific discipline (one-off).
final gradingHistoryForStudentAndDisciplineProvider =
    FutureProvider.family<List<GradingRecord>, (String, String)>((ref, args) {
      final (studentId, disciplineId) = args;
      return ref
          .watch(gradingRepositoryProvider)
          .getForStudentAndDiscipline(studentId, disciplineId);
    });
