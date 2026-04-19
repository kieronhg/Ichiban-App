import '../entities/discipline.dart';

abstract class DisciplineRepository {
  /// Returns all disciplines.
  Future<List<Discipline>> getAll();

  /// Returns only active disciplines.
  Future<List<Discipline>> getActive();

  /// Returns a single discipline by ID, or null if not found.
  Future<Discipline?> getById(String id);

  /// Creates a new discipline and returns the generated document ID.
  Future<String> create(Discipline discipline);

  /// Updates an existing discipline.
  Future<void> update(Discipline discipline);

  /// Watches all disciplines (active and inactive) in real time.
  Stream<List<Discipline>> watchAll();

  /// Watches active disciplines in real time.
  Stream<List<Discipline>> watchActive();
}
