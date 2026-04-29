import '../../entities/admin_user.dart';
import '../../entities/coach_profile.dart';
import '../../entities/enums.dart';
import '../../repositories/admin_user_repository.dart';
import '../../repositories/coach_profile_repository.dart';

class CreateAdminUserUseCase {
  const CreateAdminUserUseCase(this._repo, this._coachProfileRepo);

  final AdminUserRepository _repo;
  final CoachProfileRepository _coachProfileRepo;

  /// Writes the adminUsers Firestore document for a new admin.
  ///
  /// The Firebase Auth account is created separately by the caller:
  /// - For the first owner: via Firebase Auth createUserWithEmailAndPassword
  ///   (called directly in the setup wizard).
  /// - For coaches: via authRepository.createUserWithoutSignIn (secondary
  ///   Firebase app — called in InviteCoachScreen before this use case).
  Future<void> call({
    required String firebaseUid,
    required String email,
    required String firstName,
    required String lastName,
    required AdminRole role,
    required List<String> assignedDisciplineIds,
    required String createdByAdminId,
    String? profileId,
  }) async {
    if (firebaseUid.isEmpty) {
      throw ArgumentError('firebaseUid must not be empty');
    }
    if (email.trim().isEmpty) {
      throw ArgumentError('email must not be empty');
    }
    if (firstName.trim().isEmpty) {
      throw ArgumentError('firstName must not be empty');
    }
    if (lastName.trim().isEmpty) {
      throw ArgumentError('lastName must not be empty');
    }
    if (role == AdminRole.coach && assignedDisciplineIds.isEmpty) {
      throw StateError('A coach must be assigned to at least one discipline');
    }

    final adminUser = AdminUser(
      firebaseUid: firebaseUid,
      email: email.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      role: role,
      assignedDisciplineIds: assignedDisciplineIds,
      isActive: true,
      profileId: profileId,
      createdByAdminId: createdByAdminId,
      createdAt: DateTime.now(),
    );

    await _repo.create(adminUser);

    // Every coach gets a coachProfiles document with default compliance values.
    if (role == AdminRole.coach) {
      await _coachProfileRepo.create(
        CoachProfile(
          adminUserId: firebaseUid,
          dbs: DbsRecord.defaults,
          firstAid: FirstAidRecord.defaults,
          createdAt: adminUser.createdAt,
          createdByAdminId: createdByAdminId,
        ),
      );
    }
  }
}
