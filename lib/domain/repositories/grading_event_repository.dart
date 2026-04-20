import '../entities/grading_event.dart';
import '../entities/enums.dart';

abstract class GradingEventRepository {
  /// Returns all grading events, ordered by eventDate descending.
  Future<List<GradingEvent>> getAll();

  /// Returns all events for a specific discipline, ordered by eventDate descending.
  Future<List<GradingEvent>> getForDiscipline(String disciplineId);

  /// Watches events for a discipline in real time.
  Stream<List<GradingEvent>> watchForDiscipline(String disciplineId);

  /// Watches all events in real time.
  Stream<List<GradingEvent>> watchAll();

  /// Creates a grading event and returns the generated document ID.
  Future<String> create(GradingEvent event);

  /// Updates the status (and optionally cancelled fields) of a grading event.
  Future<void> updateStatus(
    String id,
    GradingEventStatus status, {
    String? cancelledByAdminId,
    DateTime? cancelledAt,
  });
}
