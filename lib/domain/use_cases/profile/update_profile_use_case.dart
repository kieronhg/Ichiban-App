import '../../entities/profile.dart';
import '../../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  /// Validates [profile] and persists the updated version.
  Future<void> call(Profile profile) async {
    if (profile.firstName.trim().isEmpty) {
      throw ArgumentError('First name must not be empty.');
    }
    if (profile.lastName.trim().isEmpty) {
      throw ArgumentError('Last name must not be empty.');
    }
    if (profile.profileTypes.isEmpty) {
      throw ArgumentError('At least one profile type must be selected.');
    }

    await _repo.update(profile);
  }
}
