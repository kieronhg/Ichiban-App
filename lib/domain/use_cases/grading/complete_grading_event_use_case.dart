import '../../entities/enums.dart';
import '../../repositories/grading_event_repository.dart';

class CompleteGradingEventUseCase {
  const CompleteGradingEventUseCase(this._repo);

  final GradingEventRepository _repo;

  Future<void> call(String gradingEventId) async {
    await _repo.updateStatus(gradingEventId, GradingEventStatus.completed);
  }
}
