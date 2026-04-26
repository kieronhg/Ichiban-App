import '../../repositories/admin_user_repository.dart';

class UpdateAdminUserUseCase {
  const UpdateAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  Future<void> call({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
    List<String>? assignedDisciplineIds,
    String? profileId,
  }) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    await _repo.update(
      uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      assignedDisciplineIds: assignedDisciplineIds,
      profileId: profileId,
    );
  }
}
