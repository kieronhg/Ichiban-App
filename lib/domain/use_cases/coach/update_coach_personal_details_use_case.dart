import '../../repositories/admin_user_repository.dart';
import '../../repositories/coach_profile_repository.dart';

class UpdateCoachPersonalDetailsUseCase {
  const UpdateCoachPersonalDetailsUseCase(
    this._coachProfileRepo,
    this._adminUserRepo,
  );

  final CoachProfileRepository _coachProfileRepo;
  final AdminUserRepository _adminUserRepo;

  /// Saves first/last name to adminUsers and qualificationsNotes to
  /// coachProfiles. No verification step — coach can edit freely.
  Future<void> call({
    required String adminUserId,
    String? firstName,
    String? lastName,
    String? qualificationsNotes,
  }) async {
    await Future.wait([
      if (firstName != null || lastName != null)
        _adminUserRepo.update(
          adminUserId,
          firstName: firstName,
          lastName: lastName,
        ),
      _coachProfileRepo.updatePersonalDetails(
        adminUserId,
        qualificationsNotes: qualificationsNotes,
      ),
    ]);
  }
}
