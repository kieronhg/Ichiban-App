import '../../entities/profile.dart';
import '../../entities/enums.dart';
import '../../repositories/profile_repository.dart';

class GetProfilesUseCase {
  const GetProfilesUseCase(this._repo);

  final ProfileRepository _repo;

  /// Watches all profiles in real time.
  Stream<List<Profile>> watchAll() => _repo.watchAll();

  /// Watches all profiles that include [type] in their profileTypes list.
  Stream<List<Profile>> watchByType(ProfileType type) =>
      _repo.watchAll().map(
        (profiles) =>
            profiles.where((p) => p.profileTypes.contains(type)).toList(),
      );

  /// Returns all junior profiles linked to [parentProfileId].
  Future<List<Profile>> getJuniorsForParent(String parentProfileId) =>
      _repo.getJuniorsForParent(parentProfileId);
}
