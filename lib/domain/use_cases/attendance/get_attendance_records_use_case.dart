import '../../entities/attendance_record.dart';
import '../../repositories/attendance_repository.dart';

class GetAttendanceRecordsUseCase {
  const GetAttendanceRecordsUseCase(this._repo);

  final AttendanceRepository _repo;

  /// Live records for a specific session.
  Stream<List<AttendanceRecord>> watchForSession(String sessionId) =>
      _repo.watchRecordsForSession(sessionId);

  /// All records for a student, ordered by date descending.
  Future<List<AttendanceRecord>> getForStudent(String studentId) =>
      _repo.getRecordsForStudent(studentId);

  /// All records for a student in a specific discipline, ordered by date desc.
  Future<List<AttendanceRecord>> getForStudentAndDiscipline(
    String studentId,
    String disciplineId,
  ) => _repo.getRecordsForStudentAndDiscipline(studentId, disciplineId);
}
