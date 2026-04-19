import '../../entities/rank.dart';
import '../../repositories/rank_repository.dart';

class UpdateRankUseCase {
  const UpdateRankUseCase(this._repo);

  final RankRepository _repo;

  /// Validates [rank] and persists the updated version.
  Future<void> call(Rank rank) async {
    if (rank.name.trim().isEmpty) {
      throw ArgumentError('Rank name must not be empty.');
    }
    if (rank.monCount != null && rank.monCount! < 0) {
      throw ArgumentError('monCount must be 0 or greater.');
    }
    if (rank.minAttendanceForGrading != null &&
        rank.minAttendanceForGrading! < 0) {
      throw ArgumentError('minAttendanceForGrading must be 0 or greater.');
    }

    await _repo.update(rank);
  }
}
