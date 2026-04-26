import '../../entities/coach_profile.dart';
import '../../repositories/coach_profile_repository.dart';

class GetCoachProfileUseCase {
  const GetCoachProfileUseCase(this._repo);

  final CoachProfileRepository _repo;

  Future<CoachProfile?> call(String adminUserId) => _repo.getById(adminUserId);

  Stream<CoachProfile?> watch(String adminUserId) =>
      _repo.watchById(adminUserId);
}
