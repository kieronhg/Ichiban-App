import '../../repositories/profile_repository.dart';

class ResetPinUseCase {
  const ResetPinUseCase(this._repo);

  final ProfileRepository _repo;

  /// Clears the PIN hash for [profileId].
  ///
  /// After this the student will see the "no PIN set" notice on the lock screen
  /// and will need an admin to assign a new PIN before they can sign in.
  Future<void> call(String profileId) => _repo.resetPin(profileId);
}
