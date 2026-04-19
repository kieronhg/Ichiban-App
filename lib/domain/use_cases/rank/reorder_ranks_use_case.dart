import '../../repositories/rank_repository.dart';

class ReorderRanksUseCase {
  const ReorderRanksUseCase(this._repo);

  final RankRepository _repo;

  /// Batch-updates `displayOrder` for all ranks in [disciplineId].
  ///
  /// [orderedRankIds] must be the complete list of rank IDs for the discipline
  /// in the desired display order. Each rank receives a `displayOrder` equal
  /// to its position index (0-based) in the list.
  Future<void> call(String disciplineId, List<String> orderedRankIds) async {
    if (disciplineId.trim().isEmpty) {
      throw ArgumentError('Discipline ID must not be empty.');
    }
    if (orderedRankIds.isEmpty) {
      throw ArgumentError('orderedRankIds must not be empty.');
    }

    await _repo.reorder(disciplineId, orderedRankIds);
  }
}
