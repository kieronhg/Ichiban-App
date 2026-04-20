import '../../entities/enums.dart';
import '../../repositories/grading_event_repository.dart';

class CancelGradingEventUseCase {
  const CancelGradingEventUseCase(this._repo);

  final GradingEventRepository _repo;

  Future<void> call({
    required String gradingEventId,
    required String adminId,
  }) async {
    await _repo.updateStatus(
      gradingEventId,
      GradingEventStatus.cancelled,
      cancelledByAdminId: adminId,
      cancelledAt: DateTime.now(),
    );
  }
}
