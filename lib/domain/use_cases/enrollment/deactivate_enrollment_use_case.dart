import '../../repositories/enrollment_repository.dart';

class DeactivateEnrollmentUseCase {
  const DeactivateEnrollmentUseCase(this._repo);

  final EnrollmentRepository _repo;

  /// Soft-deactivates the enrollment identified by [enrollmentId].
  ///
  /// Sets [isActive] to `false`. Rank history and all related records are
  /// preserved. The student simply no longer appears in active enrolment
  /// lists for the discipline.
  ///
  /// Throws [ArgumentError] if [enrollmentId] is empty.
  Future<void> call(String enrollmentId) async {
    if (enrollmentId.trim().isEmpty) {
      throw ArgumentError('enrollmentId must not be empty.');
    }
    await _repo.deactivate(enrollmentId);
  }
}
