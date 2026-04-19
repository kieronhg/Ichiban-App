import '../../repositories/rank_repository.dart';

class DeleteRankUseCase {
  const DeleteRankUseCase(this._repo);

  final RankRepository _repo;

  /// Deletes the rank identified by [rankId] within [disciplineId].
  ///
  /// The repository will throw if any student currently holds this rank.
  Future<void> call(String disciplineId, String rankId) async {
    if (disciplineId.trim().isEmpty) {
      throw ArgumentError('Discipline ID must not be empty.');
    }
    if (rankId.trim().isEmpty) {
      throw ArgumentError('Rank ID must not be empty.');
    }
    await _repo.delete(disciplineId, rankId);
  }
}
