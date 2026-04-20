import '../../entities/enums.dart';
import '../../entities/queued_check_in.dart';
import '../../repositories/queued_check_in_repository.dart';

enum QueueCheckInResult {
  /// Queued check-in created successfully.
  queued,

  /// A pending queued check-in already exists for this student + discipline + date.
  alreadyQueued,
}

class QueueCheckInUseCase {
  const QueueCheckInUseCase(this._repo);

  final QueuedCheckInRepository _repo;

  Future<QueueCheckInResult> call({
    required String studentId,
    required String disciplineId,
  }) async {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    // ── Duplicate queue check ────────────────────────────────────────────
    final existing = await _repo.getPendingForStudentDisciplineAndDate(
      studentId,
      disciplineId,
      today,
    );
    if (existing != null) return QueueCheckInResult.alreadyQueued;

    // ── Write queued check-in ────────────────────────────────────────────
    await _repo.create(
      QueuedCheckIn(
        id: '',
        studentId: studentId,
        disciplineId: disciplineId,
        queuedAt: now,
        queueDate: today,
        status: QueuedCheckInStatus.pending,
      ),
    );

    return QueueCheckInResult.queued;
  }
}
