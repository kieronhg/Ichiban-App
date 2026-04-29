import 'package:cloud_functions/cloud_functions.dart';

import '../../repositories/admin_user_repository.dart';

class DeactivateAdminUserUseCase {
  const DeactivateAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Soft-deactivates an admin account and disables their Firebase Auth account.
  ///
  /// Throws [StateError] if attempting to deactivate the last active owner.
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
    await FirebaseFunctions.instance
        .httpsCallable('disableAdminUser')
        .call<Map<String, dynamic>>({'uid': uid});
  }
}
