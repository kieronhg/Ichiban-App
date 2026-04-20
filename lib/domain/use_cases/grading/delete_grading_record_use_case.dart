import '../../repositories/grading_repository.dart';

class DeleteGradingRecordUseCase {
  const DeleteGradingRecordUseCase(this._repo);

  final GradingRepository _repo;

  /// Permanently deletes a grading record.
  ///
  /// Caller must have super-admin privileges.
  /// TODO(auth): enforce super-admin guard before calling this use case.
  Future<void> call(String id) => _repo.delete(id);
}
