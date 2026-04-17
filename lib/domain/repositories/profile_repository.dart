import '../entities/profile.dart';
import '../entities/enums.dart';

abstract class ProfileRepository {
  /// Returns a single profile by ID, or null if not found.
  Future<Profile?> getById(String id);

  /// Returns all profiles in the system.
  Future<List<Profile>> getAll();

  /// Returns all profiles of a given type.
  Future<List<Profile>> getByType(ProfileType type);

  /// Returns all junior profiles linked to a given parent/guardian.
  Future<List<Profile>> getJuniorsForParent(String parentProfileId);

  /// Creates a new profile and returns the generated document ID.
  Future<String> create(Profile profile);

  /// Updates an existing profile.
  Future<void> update(Profile profile);

  /// Soft-deletes a profile by setting isActive to false.
  Future<void> deactivate(String id);

  /// Watches all profiles in real time.
  Stream<List<Profile>> watchAll();

  /// Watches a single profile in real time.
  Stream<Profile?> watchById(String id);
}
