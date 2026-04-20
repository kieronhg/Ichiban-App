import '../entities/queued_check_in.dart';

abstract class QueuedCheckInRepository {
  /// All pending queued check-ins, live.
  Stream<List<QueuedCheckIn>> watchPending();

  /// Pending queued check-ins for a specific discipline on a specific date.
  Stream<List<QueuedCheckIn>> watchPendingForDisciplineAndDate(
    String disciplineId,
    DateTime date,
  );

  /// Returns the pending queued check-in for a student + discipline + date,
  /// or null if none exists.
  Future<QueuedCheckIn?> getPendingForStudentDisciplineAndDate(
    String studentId,
    String disciplineId,
    DateTime date,
  );

  /// Creates a new queued check-in and returns the generated document ID.
  Future<String> create(QueuedCheckIn queuedCheckIn);

  /// Marks a single queued check-in as resolved.
  Future<void> resolve(
    String id, {
    required String resolvedSessionId,
    required DateTime resolvedAt,
  });

  /// Marks a single queued check-in as discarded by an admin.
  Future<void> discard(
    String id, {
    required String discardedByAdminId,
    required DateTime discardedAt,
  });

  /// Bulk-discards all pending queued check-ins for a discipline + date.
  Future<void> discardAllForDisciplineAndDate(
    String disciplineId,
    DateTime date, {
    required String discardedByAdminId,
    required DateTime discardedAt,
  });
}
