import '../../entities/discipline.dart';
import '../../repositories/discipline_repository.dart';

class CreateDisciplineUseCase {
  const CreateDisciplineUseCase(this._repo);

  final DisciplineRepository _repo;

  /// Validates [discipline], stamps [createdAt] to now, and persists it.
  /// Returns the generated Firestore document ID.
  Future<String> call(Discipline discipline) async {
    if (discipline.name.trim().isEmpty) {
      throw ArgumentError('Discipline name must not be empty.');
    }
    if (discipline.createdByAdminId.trim().isEmpty) {
      throw ArgumentError('createdByAdminId must not be empty.');
    }

    final stamped = discipline.copyWith(
      createdAt: DateTime.now(),
    );

    return _repo.create(stamped);
  }
}
