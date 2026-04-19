import '../../entities/enrollment.dart';
import '../../repositories/enrollment_repository.dart';

class ReactivateEnrollmentUseCase {
  const ReactivateEnrollmentUseCase(this._repo);

  final EnrollmentRepository _repo;

  /// Reactivates the most recent inactive enrollment for [studentId] in
  /// [disciplineId].
  ///
  /// Sets [isActive] back to `true` and updates [enrollmentDate] to today.
  /// The student's [currentRankId] is retained from the previous enrolment.
  ///
  /// Throws [ArgumentError] if either ID is empty.
  /// Throws [StateError] if no inactive enrollment record exists for this
  /// student/discipline pair.
  ///
  /// Returns the reactivated [Enrollment].
  Future<Enrollment> call({
    required String studentId,
    required String disciplineId,
  }) async {
    if (studentId.trim().isEmpty) {
      throw ArgumentError('studentId must not be empty.');
    }
    if (disciplineId.trim().isEmpty) {
      throw ArgumentError('disciplineId must not be empty.');
    }

    final existing = await _repo.getInactiveForStudentAndDiscipline(
      studentId,
      disciplineId,
    );
    if (existing == null) {
      throw StateError(
        'No inactive enrollment found for student $studentId '
        'in discipline $disciplineId.',
      );
    }

    final today = DateTime.now();
    await _repo.reactivate(existing.id, today);

    return existing.copyWith(isActive: true, enrollmentDate: today);
  }
}
