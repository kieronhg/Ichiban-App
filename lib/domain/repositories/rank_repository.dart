import '../entities/rank.dart';

abstract class RankRepository {
  /// Returns all ranks for a discipline, ordered by displayOrder ascending.
  Future<List<Rank>> getForDiscipline(String disciplineId);

  /// Returns a single rank by ID within a discipline, or null if not found.
  Future<Rank?> getById(String disciplineId, String rankId);

  /// Creates a new rank within a discipline subcollection and returns its ID.
  Future<String> create(Rank rank);

  /// Updates an existing rank.
  Future<void> update(Rank rank);

  /// Deletes a rank. Only permitted if no student currently holds this rank.
  Future<void> delete(String disciplineId, String rankId);

  /// Batch-updates displayOrder for all ranks in a discipline.
  /// [orderedRankIds] is the full list of rank IDs in the new display order.
  Future<void> reorder(String disciplineId, List<String> orderedRankIds);

  /// Watches all ranks for a discipline in real time.
  Stream<List<Rank>> watchForDiscipline(String disciplineId);
}
