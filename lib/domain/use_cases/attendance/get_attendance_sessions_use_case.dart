import '../../entities/attendance_session.dart';
import '../../repositories/attendance_repository.dart';

class GetAttendanceSessionsUseCase {
  const GetAttendanceSessionsUseCase(this._repo);

  final AttendanceRepository _repo;

  /// All sessions, optionally filtered to a single discipline. Most-recent first.
  Stream<List<AttendanceSession>> watchAll({String? disciplineId}) =>
      _repo.watchAllSessions(disciplineId: disciplineId);

  /// Live sessions for a discipline on a specific date (midnight UTC).
  Stream<List<AttendanceSession>> watchForDisciplineAndDate(
    String disciplineId,
    DateTime date,
  ) => _repo.watchSessionsForDisciplineAndDate(disciplineId, date);

  /// All sessions on a given date across all disciplines.
  Stream<List<AttendanceSession>> watchForDate(DateTime date) =>
      _repo.watchSessionsForDate(date);
}
