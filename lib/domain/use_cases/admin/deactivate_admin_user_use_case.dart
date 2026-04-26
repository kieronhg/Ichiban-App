import '../../repositories/admin_user_repository.dart';

class DeactivateAdminUserUseCase {
  const DeactivateAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Soft-deactivates an admin account.
  ///
  /// Throws [StateError] if attempting to deactivate the last active owner.
  /// The Firebase Auth account must be disabled separately via Cloud Function.
  /// TODO(cloud-functions): wire up Firebase Auth account disable.
  Future<void> call({
    required String uid,
    required String deactivatedByAdminId,
  }) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    if (uid == deactivatedByAdminId) {
      throw StateError('An admin cannot deactivate their own account');
    }

    final activeOwnerCount = await _repo.countActiveOwners();
    final target = await _repo.getById(uid);
    if (target == null) throw StateError('Admin user not found: $uid');

    if (target.isOwner && activeOwnerCount <= 1) {
      throw StateError(
        'Cannot deactivate the last active owner account. '
        'Promote another admin to owner first.',
      );
    }

    await _repo.deactivate(uid, deactivatedByAdminId: deactivatedByAdminId);
  }
}
