import '../../entities/coach_profile.dart';
import '../../repositories/coach_profile_repository.dart';

class CreateCoachProfileUseCase {
  const CreateCoachProfileUseCase(this._repo);

  final CoachProfileRepository _repo;

  Future<void> call({
    required String adminUserId,
    required String createdByAdminId,
    String? profileId,
  }) async {
    final profile = CoachProfile(
      adminUserId: adminUserId,
      profileId: profileId,
      dbs: DbsRecord.defaults,
      firstAid: FirstAidRecord.defaults,
      createdAt: DateTime.now(),
      createdByAdminId: createdByAdminId,
    );
    await _repo.create(profile);
  }
}
