import '../../entities/discipline.dart';
import '../../repositories/discipline_repository.dart';

class GetDisciplinesUseCase {
  const GetDisciplinesUseCase(this._repo);

  final DisciplineRepository _repo;

  /// Watches all disciplines (active and inactive) in real time.
  /// Used by admin screens that need to display the full list.
  Stream<List<Discipline>> watchAll() => _repo.watchAll();

  /// Watches only active disciplines in real time.
  /// Used by student-facing screens and new-enrolment flows.
  Stream<List<Discipline>> watchActive() => _repo.watchActive();

  /// Returns all disciplines as a one-shot fetch.
  Future<List<Discipline>> getAll() => _repo.getAll();

  /// Returns only active disciplines as a one-shot fetch.
  Future<List<Discipline>> getActive() => _repo.getActive();
}
