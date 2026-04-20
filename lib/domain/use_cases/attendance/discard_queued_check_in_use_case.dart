import '../../repositories/queued_check_in_repository.dart';

class DiscardQueuedCheckInUseCase {
  const DiscardQueuedCheckInUseCase(this._repo);

  final QueuedCheckInRepository _repo;

  /// Discards a single queued check-in.
  Future<void> discardOne(String id, {required String adminId}) async {
    await _repo.discard(
      id,
      discardedByAdminId: adminId,
      discardedAt: DateTime.now(),
    );
  }

  /// Discards all pending queued check-ins for a discipline on a given date.
  Future<void> discardAll(
    String disciplineId,
    DateTime date, {
    required String adminId,
  }) async {
    await _repo.discardAllForDisciplineAndDate(
      disciplineId,
      date,
      discardedByAdminId: adminId,
      discardedAt: DateTime.now(),
    );
  }
}
