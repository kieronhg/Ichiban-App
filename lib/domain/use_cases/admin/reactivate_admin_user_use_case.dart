import '../../repositories/admin_user_repository.dart';

class ReactivateAdminUserUseCase {
  const ReactivateAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  /// Re-activates a deactivated admin account.
  ///
  /// The Firebase Auth account must be re-enabled separately via Cloud Function.
  /// TODO(cloud-functions): wire up Firebase Auth account re-enable.
  Future<void> call({required String uid}) async {
    if (uid.isEmpty) throw ArgumentError('uid must not be empty');
    await _repo.reactivate(uid);
  }
}
