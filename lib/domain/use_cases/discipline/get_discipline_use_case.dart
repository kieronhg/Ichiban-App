import '../../entities/discipline.dart';
import '../../repositories/discipline_repository.dart';

class GetDisciplineUseCase {
  const GetDisciplineUseCase(this._repo);

  final DisciplineRepository _repo;

  /// Returns a single discipline by [id], or null if not found.
  Future<Discipline?> call(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Discipline ID must not be empty.');
    }
    return _repo.getById(id);
  }
}
