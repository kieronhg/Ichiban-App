import '../entities/enrollment.dart';

abstract class EnrollmentRepository {
  /// Returns all active enrollments for a student.
  Future<List<Enrollment>> getForStudent(String studentId);

  /// Returns all active enrollments for a discipline.
  Future<List<Enrollment>> getForDiscipline(String disciplineId);

  /// Returns the enrollment for a specific student/discipline pair, or null.
  Future<Enrollment?> getForStudentAndDiscipline(String studentId, String disciplineId);

  /// Creates a new enrollment and returns the generated document ID.
  Future<String> create(Enrollment enrollment);

  /// Updates the currentRankId on an enrollment after a grading promotion.
  Future<void> updateCurrentRank(String enrollmentId, String rankId);

  /// Soft-deletes an enrollment by setting isActive to false.
  Future<void> deactivate(String enrollmentId);

  /// Watches all enrollments for a student in real time.
  Stream<List<Enrollment>> watchForStudent(String studentId);

  /// Watches all enrollments for a discipline in real time.
  Stream<List<Enrollment>> watchForDiscipline(String disciplineId);
}
