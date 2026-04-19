import '../../entities/enrollment.dart';
import '../../repositories/discipline_repository.dart';
import '../../repositories/enrollment_repository.dart';

class EnrolStudentUseCase {
  const EnrolStudentUseCase(this._enrollmentRepo, this._disciplineRepo);

  final EnrollmentRepository _enrollmentRepo;
  final DisciplineRepository _disciplineRepo;

  static const int _minimumAgeYears = 5;

  /// Creates a new enrollment record for [studentId] in [disciplineId]
  /// starting at [startingRankId].
  ///
  /// [dateOfBirth] is the student's DOB taken from their profile — used to
  /// enforce the minimum age rule.
  ///
  /// Throws [ArgumentError] if any required ID is empty.
  /// Throws [StateError] if the discipline is inactive.
  /// Throws [StateError] if the student is already actively enrolled.
  /// Throws [AgeRestrictionException] if the student is under [_minimumAgeYears].
  ///
  /// Returns the Firestore document ID of the new enrollment.
  Future<String> call({
    required String studentId,
    required String disciplineId,
    required String startingRankId,
    required DateTime dateOfBirth,
  }) async {
    if (studentId.trim().isEmpty) {
      throw ArgumentError('studentId must not be empty.');
    }
    if (disciplineId.trim().isEmpty) {
      throw ArgumentError('disciplineId must not be empty.');
    }
    if (startingRankId.trim().isEmpty) {
      throw ArgumentError('startingRankId must not be empty.');
    }

    // Age check — hard block, cannot be overridden.
    final age = ageInYears(dateOfBirth);
    if (age < _minimumAgeYears) {
      throw AgeRestrictionException(
        'This student is under the minimum age of $_minimumAgeYears '
        'and cannot be enrolled.',
      );
    }

    // Discipline must be active.
    final discipline = await _disciplineRepo.getById(disciplineId);
    if (discipline == null) {
      throw StateError('Discipline $disciplineId not found.');
    }
    if (!discipline.isActive) {
      throw StateError(
        'Cannot enrol into an inactive discipline (${discipline.name}).',
      );
    }

    // Guard against duplicate active enrollment.
    final existing = await _enrollmentRepo.getForStudentAndDiscipline(
      studentId,
      disciplineId,
    );
    if (existing != null) {
      throw StateError(
        'Student $studentId is already actively enrolled in discipline $disciplineId.',
      );
    }

    final enrollment = Enrollment(
      id: '',
      studentId: studentId,
      disciplineId: disciplineId,
      currentRankId: startingRankId,
      enrollmentDate: DateTime.now(),
      isActive: true,
    );

    return _enrollmentRepo.create(enrollment);
  }

  /// Calculates the student's age in whole years at the current date.
  /// Public so it can be reused by [CsvEnrolmentParser].
  static int ageInYears(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

/// Thrown when an enrolment attempt is blocked because the student does not
/// meet the minimum age requirement.
class AgeRestrictionException implements Exception {
  const AgeRestrictionException(this.message);
  final String message;

  @override
  String toString() => message;
}
