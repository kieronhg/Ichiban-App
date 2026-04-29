import 'package:cloud_functions/cloud_functions.dart';

import '../../repositories/admin_user_repository.dart';

class DeleteAdminUserUseCase {
  const DeleteAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Deletes the adminUsers Firestore document and the Firebase Auth account.
  ///
  /// Throws [StateError] if attempting to delete the last active owner.
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
    await FirebaseFunctions.instance
        .httpsCallable('deleteAdminUser')
        .call<Map<String, dynamic>>({'uid': uid});
  }
}
