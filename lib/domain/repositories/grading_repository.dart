import '../entities/grading_record.dart';

abstract class GradingRepository {
  /// Returns the full grading history for a student, ordered by gradingDate descending.
  Future<List<GradingRecord>> getForStudent(String studentId);

  /// Returns all grading records for a discipline, ordered by gradingDate descending.
  Future<List<GradingRecord>> getForDiscipline(String disciplineId);

  /// Returns grading records for a specific student within a discipline.
  Future<List<GradingRecord>> getForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  );

  /// Creates a grading record and returns the generated document ID.
  Future<String> create(GradingRecord record);

  /// Marks multiple students as eligible for a grading event.
  /// Creates a grading record per student and sets eligibilityAnnouncedDate to now.
  Future<void> markEligible({
    required List<String> studentIds,
    required String disciplineId,
    required DateTime gradingDate,
    required String coachId,
  });

  /// Watches grading records for a student in real time.
  Stream<List<GradingRecord>> watchForStudent(String studentId);
}
