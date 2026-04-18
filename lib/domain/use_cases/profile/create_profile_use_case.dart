import '../../entities/profile.dart';
import '../../repositories/profile_repository.dart';

class CreateProfileUseCase {
  const CreateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  /// Validates [profile], stamps [registrationDate] to now, and persists it.
  /// Returns the generated Firestore document ID.
  Future<String> call(Profile profile) async {
    if (profile.firstName.trim().isEmpty) {
      throw ArgumentError('First name must not be empty.');
    }
    if (profile.lastName.trim().isEmpty) {
      throw ArgumentError('Last name must not be empty.');
    }
    if (profile.profileTypes.isEmpty) {
      throw ArgumentError('At least one profile type must be selected.');
    }

    final stamped = profile.copyWith(
      registrationDate: DateTime.now(),
    );

    return _repo.create(stamped);
  }
}
