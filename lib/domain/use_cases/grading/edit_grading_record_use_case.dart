import '../../../core/errors/app_exception.dart';
import '../../entities/grading_record.dart';
import '../../repositories/grading_repository.dart';

class EditGradingRecordUseCase {
  const EditGradingRecordUseCase(this._repo);

  final GradingRepository _repo;

  /// Updates an existing grading record.
  ///
  /// Pass [isOwner] from [isOwnerProvider]. Throws [UnauthorizedException] if
  /// the caller is not an owner.
  Future<void> call(GradingRecord record, {required bool isOwner}) {
    if (!isOwner) throw const UnauthorizedException();
    return _repo.update(record);
  }
}
