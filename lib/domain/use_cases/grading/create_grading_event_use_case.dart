import '../../entities/enums.dart';
import '../../entities/grading_event.dart';
import '../../repositories/discipline_repository.dart';
import '../../repositories/grading_event_repository.dart';

class CreateGradingEventUseCase {
  const CreateGradingEventUseCase(this._repo, this._disciplineRepo);

  final GradingEventRepository _repo;
  final DisciplineRepository _disciplineRepo;

  Future<String> call({
    required String disciplineId,
    required DateTime eventDate,
    required String adminId,
    String? title,
    String? notes,
  }) async {
    // Guard: reject inactive disciplines even if the caller bypasses the UI.
    final discipline = await _disciplineRepo.getById(disciplineId);
    if (discipline == null) {
      throw ArgumentError('Discipline not found: $disciplineId');
    }
    if (!discipline.isActive) {
      throw ArgumentError(
        '${discipline.name} is inactive and cannot be used for a new grading event.',
      );
    }

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
