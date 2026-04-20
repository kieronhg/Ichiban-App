import '../../entities/enums.dart';
import '../../entities/grading_event.dart';
import '../../repositories/grading_event_repository.dart';

class CreateGradingEventUseCase {
  const CreateGradingEventUseCase(this._repo);

  final GradingEventRepository _repo;

  Future<String> call({
    required String disciplineId,
    required DateTime eventDate,
    required String adminId,
    String? title,
    String? notes,
  }) async {
    final now = DateTime.now();
    final event = GradingEvent(
      id: '',
      disciplineId: disciplineId,
      eventDate: eventDate,
      title: title,
      status: GradingEventStatus.upcoming,
      createdByAdminId: adminId,
      createdAt: now,
      notes: notes,
    );
    return _repo.create(event);
  }
}
