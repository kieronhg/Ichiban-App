import '../../entities/grading_event_student.dart';
import '../../repositories/grading_event_student_repository.dart';

class GetGradingEventStudentsUseCase {
  const GetGradingEventStudentsUseCase(this._repo);

  final GradingEventStudentRepository _repo;

  /// Watches all nomination records for a grading event in real time.
  Stream<List<GradingEventStudent>> watchForEvent(String gradingEventId) =>
      _repo.watchForEvent(gradingEventId);

  /// One-off fetch of all nominations for a student.
  Future<List<GradingEventStudent>> getForStudent(String studentId) =>
      _repo.getForStudent(studentId);
}
