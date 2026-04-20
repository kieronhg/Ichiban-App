import '../../entities/grading_record.dart';
import '../../repositories/grading_repository.dart';

class EditGradingRecordUseCase {
  const EditGradingRecordUseCase(this._repo);

  final GradingRepository _repo;

  /// Updates an existing grading record.
  ///
  /// Caller must have super-admin privileges.
  /// TODO(auth): enforce super-admin guard before calling this use case.
  Future<void> call(GradingRecord record) => _repo.update(record);
}
