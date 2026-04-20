import '../../entities/grading_event.dart';
import '../../repositories/grading_event_repository.dart';

class GetGradingEventsUseCase {
  const GetGradingEventsUseCase(this._repo);

  final GradingEventRepository _repo;

  /// Watches all grading events, ordered by eventDate descending.
  Stream<List<GradingEvent>> watchAll() => _repo.watchAll();

  /// Watches grading events for a specific discipline.
  Stream<List<GradingEvent>> watchForDiscipline(String disciplineId) =>
      _repo.watchForDiscipline(disciplineId);

  /// One-off fetch for all events.
  Future<List<GradingEvent>> getAll() => _repo.getAll();

  /// One-off fetch for a discipline's events.
  Future<List<GradingEvent>> getForDiscipline(String disciplineId) =>
      _repo.getForDiscipline(disciplineId);
}
