import '../../../core/errors/app_exception.dart';
import '../../repositories/grading_repository.dart';

class DeleteGradingRecordUseCase {
  const DeleteGradingRecordUseCase(this._repo);

  final GradingRepository _repo;

  /// Permanently deletes a grading record.
  ///
  /// Pass [isOwner] from [isOwnerProvider]. Throws [UnauthorizedException] if
  /// the caller is not an owner.
  Future<void> call(String id, {required bool isOwner}) {
    if (!isOwner) throw const UnauthorizedException();
    return _repo.delete(id);
  }
}
