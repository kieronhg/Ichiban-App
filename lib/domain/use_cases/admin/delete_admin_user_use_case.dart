import '../../repositories/admin_user_repository.dart';

class DeleteAdminUserUseCase {
  const DeleteAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Deletes the adminUsers Firestore document.
  ///
  /// Throws [StateError] if attempting to delete the last active owner.
  /// The Firebase Auth account must be deleted separately via Cloud Function.
  /// TODO(cloud-functions): wire up Firebase Auth account deletion.
  Future<void> call({
    required String uid,
    required String deletedByAdminId,
  }) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    if (uid == deletedByAdminId) {
      throw StateError('An admin cannot delete their own account');
    }

    final activeOwnerCount = await _repo.countActiveOwners();
    final target = await _repo.getById(uid);
    if (target == null) throw StateError('Admin user not found: $uid');

    if (target.isOwner && activeOwnerCount <= 1) {
      throw StateError(
        'Cannot delete the last owner account. '
        'Promote another admin to owner first.',
      );
    }

    await _repo.delete(uid);
  }
}
