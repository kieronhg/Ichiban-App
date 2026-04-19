import '../../entities/enrollment.dart';
import '../../repositories/enrollment_repository.dart';

class GetEnrollmentsUseCase {
  const GetEnrollmentsUseCase(this._repo);

  final EnrollmentRepository _repo;

  /// Streams ALL enrollments (active + inactive) for a student in real time.
  /// Used by the Disciplines & Grading tab on the profile detail screen.
  Stream<List<Enrollment>> watchAllForStudent(String studentId) =>
      _repo.watchAllForStudent(studentId);

  /// Streams only ACTIVE enrollments for a student in real time.
  Stream<List<Enrollment>> watchActiveForStudent(String studentId) =>
      _repo.watchForStudent(studentId);

  /// Streams all active enrollments for a discipline in real time.
  /// Used by the Discipline Detail screen's enrolled-students section.
  Stream<List<Enrollment>> watchForDiscipline(String disciplineId) =>
      _repo.watchForDiscipline(disciplineId);

  /// Returns all enrollments (active + inactive) for a student once.
  Future<List<Enrollment>> getAllForStudent(String studentId) =>
      _repo.getAllForStudent(studentId);
}
