import '../../entities/enums.dart';
import '../../repositories/admin_user_repository.dart';

class PromoteToOwnerUseCase {
  const PromoteToOwnerUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Promotes a coach to owner role.
  ///
  /// Throws [StateError] if the target is already an owner.
  Future<void> call({required String uid}) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');

    final target = await _repo.getById(uid);
    if (target == null) throw StateError('Admin user not found: $uid');
    if (target.isOwner) {
      throw StateError('${target.fullName} is already an owner');
    }

    await _repo.updateRole(
      uid,
      role: AdminRole.owner,
      assignedDisciplineIds: [],
    );
  }
}
