import '../../entities/discipline.dart';
import '../../repositories/discipline_repository.dart';

class UpdateDisciplineUseCase {
  const UpdateDisciplineUseCase(this._repo);

  final DisciplineRepository _repo;

  /// Validates [discipline] and persists the updated version.
  Future<void> call(Discipline discipline) async {
    if (discipline.name.trim().isEmpty) {
      throw ArgumentError('Discipline name must not be empty.');
    }

    await _repo.update(discipline);
  }
}
