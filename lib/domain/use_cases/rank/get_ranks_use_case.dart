import '../../entities/rank.dart';
import '../../repositories/rank_repository.dart';

class GetRanksUseCase {
  const GetRanksUseCase(this._repo);

  final RankRepository _repo;

  /// Watches all ranks for [disciplineId] in real time, ordered by
  /// [displayOrder] ascending (lowest rank first).
  Stream<List<Rank>> watchForDiscipline(String disciplineId) =>
      _repo.watchForDiscipline(disciplineId);

  /// Returns all ranks for [disciplineId] as a one-shot fetch.
  Future<List<Rank>> getForDiscipline(String disciplineId) =>
      _repo.getForDiscipline(disciplineId);
}
