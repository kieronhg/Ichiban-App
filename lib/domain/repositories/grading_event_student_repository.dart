import '../entities/grading_event_student.dart';
import '../entities/enums.dart';

abstract class GradingEventStudentRepository {
  /// Returns all student nomination records for a grading event.
  Future<List<GradingEventStudent>> getForEvent(String gradingEventId);

  /// Watches student nomination records for an event in real time.
  Stream<List<GradingEventStudent>> watchForEvent(String gradingEventId);

  /// Returns all nomination records for a student across all events.
  Future<List<GradingEventStudent>> getForStudent(String studentId);

  /// Creates a student nomination record and returns the generated document ID.
  Future<String> create(GradingEventStudent record);

  /// Records the outcome for a student in a grading event.
  Future<void> recordOutcome({
    required String id,
    required GradingOutcome outcome,
    String? rankAchievedId,
    double? gradingScore,
    required String resultRecordedByAdminId,
    required DateTime resultRecordedAt,
    String? notes,
  });

  /// Marks the eligibility notification as sent for a student.
  Future<void> markNotificationSent(String id, DateTime sentAt);

  /// Deletes a nomination record (only allowed before results are recorded).
  Future<void> delete(String id);

  /// Returns all records with a resultRecordedAt on or after [from].
  Future<List<GradingEventStudent>> getWithOutcomeFrom(DateTime from);
}
