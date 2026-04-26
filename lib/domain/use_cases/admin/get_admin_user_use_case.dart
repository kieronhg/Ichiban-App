import '../../entities/admin_user.dart';
import '../../repositories/admin_user_repository.dart';

class GetAdminUserUseCase {
  const GetAdminUserUseCase(this._repo);

  final AdminUserRepository _repo;

  Future<AdminUser?> call(String uid) => _repo.getById(uid);

  Stream<AdminUser?> watch(String uid) => _repo.watchById(uid);
}
