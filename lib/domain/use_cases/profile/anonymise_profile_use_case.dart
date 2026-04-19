import '../../repositories/profile_repository.dart';

class AnonymiseProfileUseCase {
  const AnonymiseProfileUseCase(this._repo);

  final ProfileRepository _repo;

  /// Anonymises the profile identified by [profileId] under the
  /// GDPR Right to Erasure.
  ///
  /// Throws [ArgumentError] if [profileId] is empty.
  /// Throws [StateError] if the profile has already been anonymised.
  Future<void> call(String profileId) async {
    if (profileId.trim().isEmpty) {
      throw ArgumentError('Profile ID must not be empty.');
    }

    final profile = await _repo.getById(profileId);
    if (profile == null) {
      throw StateError('Profile $profileId not found.');
    }
    if (profile.isAnonymised) {
      throw StateError('Profile $profileId has already been anonymised.');
    }

    await _repo.anonymise(profileId);
  }
}
