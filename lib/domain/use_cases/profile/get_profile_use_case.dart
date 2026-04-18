import '../../entities/profile.dart';
import '../../repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repo);

  final ProfileRepository _repo;

  /// Watches a single profile in real time. Emits null if not found.
  Stream<Profile?> watchById(String profileId) =>
      _repo.watchById(profileId);

  /// Fetches a single profile once. Returns null if not found.
  Future<Profile?> getById(String profileId) =>
      _repo.getById(profileId);
}
