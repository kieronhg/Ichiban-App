import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/enrollment.dart';

class EnrollmentConverter {
  EnrollmentConverter._();

  static Enrollment fromMap(String id, Map<String, dynamic> map) {
    return Enrollment(
      id: id,
      studentId: map['studentId'] as String,
      disciplineId: map['disciplineId'] as String,
      currentRankId: map['currentRankId'] as String,
      enrollmentDate: (map['enrollmentDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool,
    );
  }

  static Map<String, dynamic> toMap(Enrollment enrollment) {
    return {
      'studentId': enrollment.studentId,
      'disciplineId': enrollment.disciplineId,
      'currentRankId': enrollment.currentRankId,
      'enrollmentDate': Timestamp.fromDate(enrollment.enrollmentDate),
      'isActive': enrollment.isActive,
    };
  }
}
