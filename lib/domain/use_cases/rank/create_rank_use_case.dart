import '../../entities/rank.dart';
import '../../repositories/rank_repository.dart';

class CreateRankUseCase {
  const CreateRankUseCase(this._repo);

  final RankRepository _repo;

  /// Validates [rank], stamps [createdAt] to now, and persists it.
  /// Returns the generated Firestore document ID.
  Future<String> call(Rank rank) async {
    if (rank.name.trim().isEmpty) {
      throw ArgumentError('Rank name must not be empty.');
    }
    if (rank.disciplineId.trim().isEmpty) {
      throw ArgumentError('Discipline ID must not be empty.');
    }
    if (rank.monCount != null && rank.monCount! < 0) {
      throw ArgumentError('monCount must be 0 or greater.');
    }
    if (rank.minAttendanceForGrading != null &&
        rank.minAttendanceForGrading! < 0) {
      throw ArgumentError('minAttendanceForGrading must be 0 or greater.');
    }

    final stamped = rank.copyWith(
      createdAt: DateTime.now(),
    );

    return _repo.create(stamped);
  }
}
