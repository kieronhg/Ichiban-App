import '../../entities/enums.dart';
import '../../repositories/admin_user_repository.dart';

class DemoteToCoachUseCase {
  const DemoteToCoachUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Demotes an owner to coach role and assigns disciplines.
  ///
  /// Throws [StateError] if:
  /// - The target is already a coach
  /// - They are the last active owner
  /// - No disciplines are assigned
  /// - An admin tries to demote themselves (pass [requestingAdminUid])
  Future<void> call({
    required String uid,
    required String requestingAdminUid,
    required List<String> assignedDisciplineIds,
  }) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    if (assignedDisciplineIds.isEmpty) {
      throw StateError('A coach must be assigned to at least one discipline');
    }
    if (uid == requestingAdminUid) {
      throw StateError('An owner cannot demote themselves');
    }

    final target = await _repo.getById(uid);
    if (target == null) throw StateError('Admin user not found: $uid');
    if (target.isCoach) {
      throw StateError('${target.fullName} is already a coach');
    }

    final activeOwnerCount = await _repo.countActiveOwners();
    if (activeOwnerCount <= 1) {
      throw StateError(
        'Cannot demote the last owner. '
        'Promote another admin to owner first.',
      );
    }

    await _repo.updateRole(
      uid,
      role: AdminRole.coach,
      assignedDisciplineIds: assignedDisciplineIds,
    );
  }
}
