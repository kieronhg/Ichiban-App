import '../../repositories/profile_repository.dart';

class DeactivateProfileUseCase {
  const DeactivateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  /// Soft-deletes a profile by setting isActive to false.
  Future<void> call(String profileId) async {
    if (profileId.trim().isEmpty) {
      throw ArgumentError('Profile ID must not be empty.');
    }
    await _repo.deactivate(profileId);
  }
}
