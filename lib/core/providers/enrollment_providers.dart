import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enrollment.dart';
import '../../domain/use_cases/enrollment/deactivate_enrollment_use_case.dart';
import '../../domain/use_cases/enrollment/enrol_student_use_case.dart';
import '../../domain/use_cases/enrollment/get_enrollments_use_case.dart';
import '../../domain/use_cases/enrollment/reactivate_enrollment_use_case.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final getEnrollmentsUseCaseProvider = Provider<GetEnrollmentsUseCase>(
  (ref) => GetEnrollmentsUseCase(ref.watch(enrollmentRepositoryProvider)),
);

final enrolStudentUseCaseProvider = Provider<EnrolStudentUseCase>(
  (ref) => EnrolStudentUseCase(
    ref.watch(enrollmentRepositoryProvider),
    ref.watch(disciplineRepositoryProvider),
  ),
);

final reactivateEnrollmentUseCaseProvider =
    Provider<ReactivateEnrollmentUseCase>(
      (ref) =>
          ReactivateEnrollmentUseCase(ref.watch(enrollmentRepositoryProvider)),
    );

final deactivateEnrollmentUseCaseProvider =
    Provider<DeactivateEnrollmentUseCase>(
      (ref) =>
          DeactivateEnrollmentUseCase(ref.watch(enrollmentRepositoryProvider)),
    );

// ── Stream providers ───────────────────────────────────────────────────────

/// ALL enrollments (active + inactive) for a student, live.
/// Used by the Disciplines & Grading tab on the profile detail screen so
/// both active enrolments and the collapsed inactive history are visible.
final allEnrollmentsForStudentProvider =
    StreamProvider.family<List<Enrollment>, String>(
      (ref, studentId) => ref
          .watch(getEnrollmentsUseCaseProvider)
          .watchAllForStudent(studentId),
    );

/// Active enrollments only for a discipline, live.
/// Used by the Discipline Detail screen's enrolled-students section.
final enrollmentsForDisciplineProvider =
    StreamProvider.family<List<Enrollment>, String>(
      (ref, disciplineId) => ref
          .watch(getEnrollmentsUseCaseProvider)
          .watchForDiscipline(disciplineId),
    );
