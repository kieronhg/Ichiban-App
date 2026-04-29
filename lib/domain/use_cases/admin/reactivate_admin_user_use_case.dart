import 'package:cloud_functions/cloud_functions.dart';

import '../../repositories/admin_user_repository.dart';

class ReactivateAdminUserUseCase {
  const ReactivateAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Re-activates a deactivated admin account and re-enables their Firebase
  /// Auth account.
  Future<void> call({required String uid}) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    await _repo.reactivate(uid);
    await FirebaseFunctions.instance
        .httpsCallable('enableAdminUser')
        .call<Map<String, dynamic>>({'uid': uid});
  }
}
